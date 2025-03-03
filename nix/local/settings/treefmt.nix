# https://treefmt.com
let
  inherit (inputs) l std;
  inherit (cell) pkgs;
in
std.lib.dev.mkNixago std.lib.cfg.treefmt {

  data = {
    global = {
      excludes = [
        "*.diff"
        "*.patch"
      ];
    };

    # NOTE(eff): We assign priorities according to the rule of thumb:
    # "format, then lint".

    # *
    formatter = {

      # https://github.com/google/keep-sorted
      keep-sorted = {
        command = l.getExe pkgs.keep-sorted;
        includes = [ "*" ];
        priority = 10;
      };
    };

    # Bash
    formatter = {

      # https://www.shellcheck.net/wiki/Home
      shellcheck = {
        command = l.getExe pkgs.shellcheck;
        includes = [
          "*.bash"
          "*.envrc"
          "*.envrc.*"
          "*.sh"
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
          "*.envrc"
          "*.envrc.*"
          "*.sh"
        ];
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
      # FIXME(eff): Install plugins.
      mdformat = {
        command = l.getExe pkgs.python3Packages.mdformat;
        includes = [ "*.md" ];
        priority = 0;
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
      statix =
        let
          inherit (cell.settings.statix) __passthru configFile;
          command = l.getExe (l.head __passthru.packages);
          options = l.cli.toGNUCommandLine { } {
            config = configFile;
          };

          # NOTE(eff): statix doesn't support fixing multiple files at once, so we fix them one by one.
          statix-fix = pkgs.writeShellScriptBin "statix-fix" ''
            for file in "''$@"
            do
              ${command} fix ${l.toString options} "''$file"
            done
          '';
        in
        {
          command = l.getExe statix-fix;
          includes = [ "*.nix" ];
          priority = 1;
        };
    };

    # Ruby
    formatter = {

      # https://docs.rubocop.org
      rubocop = {
        command = l.getExe pkgs.rubocop;
        options = l.cli.toGNUCommandLine { } {
          auto-correct-all = true;
        };
        includes = [
          "*Brewfile"
        ];
      };
    };

    # YAML
    formatter = {

      # https://github.com/google/yamlfmt/
      yamlfmt =
        let
          inherit (cell.settings.yamlfmt) __passthru configFile;
        in
        {
          command = l.getExe (l.head __passthru.packages);
          options = l.cli.toGNUCommandLine { } {
            conf = configFile;
          };
          includes = [
            "*.yaml"
            "*.yml"
          ];
        };
    };
  };
}
