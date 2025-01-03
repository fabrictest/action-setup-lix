# https://editorconfig.org
let
  inherit (inputs) std;
in
std.lib.dev.mkNixago std.lib.cfg.editorconfig {
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

    "{*.yaml,*.yml}" = {
      indent_size = 2;
      indent_style = "space";
    };
  };
}
