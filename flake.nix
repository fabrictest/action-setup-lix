{
  description = "Install Lix faster than you can refresh a GitHub Actions workflow page";

  inputs = {
    # region Flake URLs
    devshell.url = "github:numtide/devshell";
    flake-utils.url = "github:numtide/flake-utils";
    nixago.url = "github:nix-community/nixago";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    std.url = "github:divnix/std";
    systems.url = "github:nix-systems/default";
    # endregion

    # region `follows` declarations
    devshell.inputs = {
      nixpkgs.follows = "nixpkgs";
    };
    flake-utils.inputs = {
      systems.follows = "systems";
    };
    nixago.inputs = {
      nixago-exts.follows = "std/blank";
      nixpkgs.follows = "nixpkgs";
      flake-utils.follows = "flake-utils";
    };
    std.inputs = {
      devshell.follows = "devshell";
      lib.follows = "nixpkgs";
      nixago.follows = "nixago";
      nixpkgs.follows = "nixpkgs";
    };
    # endregion
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      std,
      systems,
      ...
    }:
    std.growOn
      {
        systems = import systems;

        inputs = inputs // {
          l = nixpkgs.lib // builtins;
        };

        cellsFrom = ./nix;

        cellBlocks = [
          (std.blockTypes.devshells "shells")
          (std.blockTypes.functions "lib")
          (std.blockTypes.functions "overlays")
          (std.blockTypes.installables "packages")
          (std.blockTypes.nixago "settings")
          (std.blockTypes.pkgs "pkgs")
        ];
      }
      {
        overlays.lixPackages = std.harvest self [
          "lix"
          "overlays"
          "packages"
        ];

        packages = std.harvest self [
          "lix"
          "packages"
        ];

        devShells = std.harvest self [
          "local"
          "shells"
        ];
      };
}
