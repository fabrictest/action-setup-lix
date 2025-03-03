let
  inherit (inputs) l std;
  inherit (cell.lib) prj;
in
{
  default = std.lib.dev.mkShell {

    name = prj.id;

    imports = [
      std.std.devshellProfiles.default
    ];

    nixago = l.attrValues {
      inherit (cell.settings) editorconfig githubsettings treefmt;
    };
  };
}
