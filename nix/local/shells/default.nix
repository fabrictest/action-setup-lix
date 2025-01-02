{ inputs, cell }:
let
  inherit (inputs.std) lib std;
  inherit (cell) settings;
in
{
  default = lib.dev.mkShell {
    name = "action-setup-lix";

    imports = [ std.devshellProfiles.default ];

    nixago = [
      settings.editorconfig
      settings.githubsettings
      settings.treefmt
    ];
  };
}
