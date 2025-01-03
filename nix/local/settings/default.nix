{ inputs, cell }:
let
  inherit (inputs) l;
  inherit (inputs.std) lib std;
  inherit (cell) pkgs;
in
rec {

  # https://editorconfig.org
  editorconfig = lib.dev.mkNixago lib.cfg.editorconfig {
    data = {
      root = true;

      "*" = {
        charset = "utf-8";
        end_of_line = "lf";
        indent_size = 8;
        indent_style = "tab";
        insert_final_newline = true;
        trim_trailing_whitespace = true;
      };

      "{*.diff,*.patch,flake.lock}" = {
        end_of_line = "unset";
        indent_size = "unset";
        indent_style = "unset";
        insert_final_newline = "unset";
        trim_trailing_whitespace = "unset";
      };

      "*.json" = {
        indent_size = 2;
        indent_style = "space";
      };

      "*.md" = {
        indent_size = 2;
        indent_style = "space";
        trim_trailing_whitespace = false;
      };

      "*.nix" = {
        indent_size = 2;
        indent_style = "space";
      };

      "*.yaml" = {
        indent_size = 2;
        indent_style = "space";
      };
    };
  };

  githubsettings = lib.dev.mkNixago lib.cfg.githubsettings {
    data = {

      bypass_actors = [ ];

      repository =
        let
          name = "action-setup-lix";
        in
        {
          inherit name;
          description = "Install Lix on GitHub Actions faster than you can refresh your browser";
          homepage = "https://github.com/fabrictest/${name}";
          topics = "github-actions, lix, nix";
          visibility = "public";
          security_and_analysis = null;
          has_issues = true;
          has_projects = false;
          has_wiki = false;
          is_template = false;
          default_branch = "main";
          allow_squash_merge = true;
          allow_merge_commit = false;
          allow_rebase_merge = false;
          allow_auto_merge = true;
          delete_branch_on_merge = true;
          allow_update_branch = false;
          squash_merge_commit_title = "PR_TITLE";
          squash_merge_commit_message = "PR_BODY";
          merge_commit_title = "PR_TITLE";
          merge_commit_message = "PR_BODY";
          enable_automated_security_fixes = true;
          enable_vulnerability_alerts = true;
        };

      # labels = [ ];

      rulesets = [
        {
          name = "Prevent tampering with the default branch";
          target = "branch";
          enforcement = "enabled";
          conditions = {
            ref_name = {
              include = [ "~DEFAULT_BRANCH" ];
              exclude = [ ];
            };
          };
          rules = [
            { type = "deletion"; }
            { type = "non_fast_forward"; }
            {
              type = "pull_request";
              parameters = {
                require_code_owner_review = true;
                require_last_pull_approval = true;
                dismiss_stale_reviews_on_push = true;
                required_approving_review_count = 1;
                required_review_thread_resolution = true;
              };
            }
            { type = "required_linear_history"; }
            {
              type = "required_status_checks";
              parameters = {
                required_status_checks = [
                  # TODO(ttlgcc): Gather integration IDs and configure the required status checks.
                  #  See: https://docs.github.com/en/rest/repos/rules?apiVersion=2022-11-28#update-a-repository-ruleset
                ];
                strict_required_status_checks_policy = true;
              };

            }
          ];
        }
        {
          name = "Prevent tampering with the release tags";
          target = "tag";
          enforcement = "enabled";
          conditions = {
            ref_name = {
              include = [ "~ALL" ];
              exclude = [ ];
            };
          };
          rules = [
            { type = "deletion"; }
            { type = "non_fast_forward"; }
            {
              type = "tag_name_pattern";
              parameters = {
                name = "Tags follow the SemVer convention";
                negate = false;
                operator = "regex";
                pattern = ''^v?(0|[1-9]\\d*)\\.(0|[1-9]\\d*)\\.(0|[1-9]\\d*)(?:-((?:0|[1-9]\\d*|\\d*[a-zA-Z-][0-9a-zA-Z-]*)(?:\\.(?:0|[1-9]\\d*|\\d*[a-zA-Z-][0-9a-zA-Z-]*))*))?(?:\\+([0-9a-zA-Z-]+(?:\\.[0-9a-zA-Z-]+)*))?''$'';
              };
            }
          ];
        }
      ];
    };
  };

  # https://git.peppe.rs/languages/statix/about/
  statix = lib.dev.mkNixago {
    output = "statix.toml";

    packages = [ pkgs.statix ];

    data = {
      disabled = [ ];
      ignore = [ ".direnv" ];
    };
  };

  # https://treefmt.com
  treefmt = lib.dev.mkNixago lib.cfg.treefmt {

    # NOTE(ttlgcc): Whenever in doubt about how to fix tool conflicts,
    #  follow this simple rule:
    #
    #     Format, then lint.

    # FIXME(ttlgcc): Separate settings per ecosystem.

    data = {
      global = {
        excludes = [
          "nix/*/sources/generated.*"
          "*.diff"
          "*.patch"
          "*.txt"
          "*flake.lock"
        ];
      };

      # All files
      formatter = {

        # https://waterlan.home.xs4all.nl/dos2unix.html
        dos2unix = {
          command =
            let
              dos2unix = l.getExe' pkgs.dos2unix "dos2unix";
              options = l.cli.toGNUCommandLine { } {
                add-eol = true;
                keepdate = true;
              };

              # NOTE(ttlgcc): Running `dos2unix` by itself will give lots of
              #  "operation not permitted" errors.  Allowing dos2unix to use
              #  temporary files solves this issue.
              dos2unix' = pkgs.writeShellScriptBin "dos2unix-newfile" ''
                printf %s\\n "''$@" |
                  xargs -I{} -- printf ' --newfile "%s" "%s"' {} {} |
                  xargs -- '${dos2unix}' ${l.toString options}
              '';
            in
            l.getExe dos2unix';
          includes = [ "*" ];
          priority = -10;
        };

        # https://github.com/google/keep-sorted
        keep-sorted = {
          command = l.getExe pkgs.keep-sorted;
          includes = [ "*" ];
          priority = 10;
        };
      };

      # JSON
      formatter = {

        # https://github.com/caarlos0/jsonfmt
        jsonfmt = {
          command = l.getExe pkgs.jsonfmt;
          options = l.cli.toGNUCommandLine { } {
            w = true;
          };
          includes = [ "*.json" ];
          excludes = [ "*release-please-manifest.json" ];
        };
      };

      # Markdown
      formatter = {

        # https://zimbatm.github.io/mdsh/
        mdsh = {
          command = l.getExe pkgs.mdsh;
          options = l.cli.toGNUCommandLine { } {
            inputs = true;
          };
          includes = [ "README.md" ];
          priority = -1;
        };

        # https://mdformat.readthedocs.io
        # FIXME(ttlgcc): Install plugins.
        mdformat = {
          command = l.getExe pkgs.python3Packages.mdformat;
          includes = [ "*.md" ];
          excludes = [ "CHANGELOG.md" ];
        };
      };

      # Nix
      formatter = {

        # https://github.com/astro/deadnix
        deadnix = {
          command = l.getExe pkgs.deadnix;
          options = l.cli.toGNUCommandLine { } {
            edit = true;
          };
          includes = [ "*.nix" ];
          priority = -1;
        };

        # https://github.com/NixOS/nixfmt
        nixfmt = {
          command = l.getExe pkgs.nixfmt-rfc-style;
          includes = [ "*.nix" ];
        };

        # https://git.peppe.rs/languages/statix/about/
        statix = {
          command =
            let

              # NOTE(ttlgcc): statix doesn't support fixing multiple files at once,
              #  so we're fixing them one by one.
              statix-fix = pkgs.writeShellScriptBin "statix-fix" ''
                for file in "''$@"
                do
                  '${l.getExe pkgs.statix}' fix --config '${statix.configFile}' "''$file"
                done
              '';
            in
            l.getExe statix-fix;
          includes = [ "*.nix" ];
          priority = 1;
        };
      };

      # Ruby
      formatter = {

        # https://docs.rubocop.org
        rubocop = {
          command = l.getExe pkgs.rubocop;
          includes = [ "*Brewfile" ];
        };
      };

      # Bash, Sh
      formatter = {

        # https://www.shellcheck.net/wiki/Home
        shellcheck = {
          command = l.getExe pkgs.shellcheck;
          includes = [
            "*.bash"
            "*.sh"
            # direnv
            "*.envrc"
            "*.envrc.*"
          ];
          priority = 1;
        };

        # https://github.com/mvdan/sh#shfmt
        shfmt = {
          command = l.getExe pkgs.shfmt;
          options = l.cli.toGNUCommandLine { } {
            simplify = true;
            write = true;
          };
          includes = [
            "*.bash"
            "*.sh"
            # direnv
            "*.envrc"
            "*.envrc.*"
          ];
        };
      };

      # YAML
      formatter = {
        # https://github.com/google/yamlfmt/
        yamlfmt = {
          command = l.getExe pkgs.yamlfmt;
          options = l.cli.toGNUCommandLine { } {
            conf = yamlfmt.configFile;
          };
          includes = [ "*.yaml" ];

          excludes = [
            # FIXME(ttlgcc): We're not formatting files committed by release-please just yet.
            #  We must find a way to trigger a workflow that formats the code right after
            #  release-please creates/changes the release PR.
            ".github/settings.ya?ml"
          ];
        };
      };
    };
  };

  # https://github.com/google/yamlfmt/
  yamlfmt = lib.dev.mkNixago {
    output = "yamlfmt.yaml";
    packages = [ pkgs.yamlfmt ];
    data = {
      line_ending = "lf";
      gitignore_excludes = true;
      formatter = {
        type = "basic";
        include_document_start = true;
        scan_folded_as_literal = true;
        trim_trailing_whitespace = true;
        eof_newline = true;
      };
    };
  };
}
