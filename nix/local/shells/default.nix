let
  inherit (inputs) l std;
in
{
  default = std.lib.dev.mkShell {
    name = "action-setup-lix";

    imports = [
      std.std.devshellProfiles.default
    ];

    nixago = l.attrValues {
      inherit (cell.settings) editorconfig githubsettings treefmt;
    };
  };
}
