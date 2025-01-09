# https://github.com/apps/settings
let
  inherit (inputs) l std;
in
std.lib.dev.mkNixago std.lib.cfg.githubsettings {
  data = {

    repository = {
      name = "action-setup-lix";
      description = "Install Lix faster than you can refresh a GitHub Actions workflow page";
      homepage = "https://github.com/fabrictest/action-setup-lix";
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
        target = "branch";
        name = "Prevent tampering with default branch";
        enforcement = "active";
        conditions.ref_name.include = [ "~DEFAULT_BRANCH" ];
        rules = [
          { type = "deletion"; }
          { type = "non_fast_forward"; }
          { type = "required_linear_history"; }
        ];
      }
      {
        target = "branch";
        name = "Require PRs to pass the quality bar";
        enforcement = "active";
        conditions.ref_name.include = [ "~DEFAULT_BRANCH" ];
        rules = [
          {
            type = "merge_queue";
            parameters = {
              merge_method = "SQUASH";
              max_entries_to_build = 5;
              min_entries_to_merge = 1;
              max_entries_to_merge = 5;
              min_entries_to_merge_wait_minutes = 5;
              grouping_strategy = "ALLGREEN";
              check_response_timeout_minutes = 60;
            };
          }
          {
            type = "pull_request";
            parameters = {
              required_approving_review_count = 1;
              dismiss_stale_reviews_on_push = true;
              require_code_owner_review = true;
              require_last_push_approval = true;
              required_review_thread_resolution = true;
              automatic_copilot_code_review_enabled = true;
              allowed_merge_methods = [ "squash" ];
            };
          }
          {
            type = "required_status_checks";
            parameters = {
              strict_required_status_checks_policy = false;
              required_status_checks =
                let
                  context = l.cartesianProduct {
                    workflow = [
                      "Test"
                    ];
                    job = [
                      "Examples"
                      "With Cachix"
                    ];
                    lix-version = [
                      "2.90.0"
                      "2.91.1"
                    ]; # TODO(ttlgcc): Get versions from `lix` cell.
                    runs-on = [
                      "macos-13"
                      "macos-15"
                      "ubuntu-24.04"
                    ];
                  };
                in
                l.cartesianProduct {
                  context = l.map (c: "${c.workflow} / ${c.job} (${c.lix-version}, ${c.runs-on})") context;
                  integration_id = [ 15368 ]; # GitHub Actions
                };
            };
          }
        ];
      }

      {
        target = "tag";
        name = "Prevent deletion of release tags";
        enforcement = "active";
        conditions.ref_name.include = [ "refs/tags/v*" ];
        rules = [
          { type = "deletion"; }
        ];
      }
      {
        target = "tag";
        name = "Prevent tampering with release tags";
        enforcement = "active";
        conditions.ref_name.include = [ "refs/tags/v*.*.*" ];
        rules = [
          { type = "non_fast_forward"; }
          { type = "update"; }
        ];
      }
    ];
  };
}
