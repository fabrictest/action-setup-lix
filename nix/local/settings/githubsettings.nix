# https://github.com/apps/settings
let
  inherit (inputs) std;
in
std.lib.dev.mkNixago std.lib.cfg.githubsettings {
  data = {

    # bypass_actors = [ ];

    repository =
      let
        name = "action-setup-lix";
      in
      {
        inherit name;
        description = "Install Lix faster than you can refresh a GitHub Actions workflow page";
        homepage = "https://github.com/fabrictest/${name}";
        topics = "github-actions,lix,nix";
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
        allow_update_branch = true;
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
        enforcement = "active";
        conditions = {
          ref_name = {
            include = [ "~DEFAULT_BRANCH" ];
            exclude = [];
          };
        };
        rules = [
          { type = "deletion"; }
          # { type = "non_fast_forward"; }
            { type = "required_linear_history"; }
            {
              type = "pull_request";
              parameters = {
                require_code_owner_review = true;
              };
            }
        ];
      }
      /*
        {
            {
              type = "pull_request";
              parameters = {
                allowed_merge_methods = [ "SQUASH" ];
                dismiss_stale_reviews_on_push = true;
                require_code_owner_review = true;
                require_last_pull_approval = true;
                required_approving_review_count = 1;
                required_review_thread_resolution = true;
              };
            }
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
              exclude = [];
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
                pattern = ''^v?(0|[1-9]\\d*)\\.(0|[1-9]\\d*)\\.(0|[1-9]\\d*)(?:-((?:0|[1-9]\\d*|\\d*[a-zA-Z-][0-9a-zA-Z-]*)(?:\\.(?:0|[1-9]\\d*|\\d*[a-zA-Z-][0-9a-zA-Z-]*))*))?(?:\\+([0-9a-zA-Z-]+(?:\\.[0-9a-zA-Z-]+)*))?$'';
              };
            }
          ];
        }
      */
    ];
  };
}
