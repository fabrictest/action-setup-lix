{
  description = "Install Lix faster than you can refresh a GitHub Actions workflow page";

  inputs = {
    devshell = {
      url = "github:numtide/devshell";
      inputs = {
        nixpkgs.follows = "nixpkgs";
      };
    };

    flake-utils = {
      url = "github:numtide/flake-utils";
      inputs = {
        systems.follows = "systems";
      };
    };

    nixago = {
      url = "github:nix-community/nixago";
      inputs = {
        nixago-exts.follows = "std/blank";
        nixpkgs.follows = "nixpkgs";
        flake-utils.follows = "flake-utils";
      };
    };

    nixpkgs = {
      url = "github:NixOS/nixpkgs/nixos-24.11";
    };

    std = {
      url = "github:divnix/std";
      inputs = {
        devshell.follows = "devshell";
        lib.follows = "nixpkgs";
        nixago.follows = "nixago";
        nixpkgs.follows = "nixpkgs";
      };
    };

    systems = {
      url = "github:nix-systems/default";
    };
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
          (std.blockTypes.nixago "settings")
          (std.blockTypes.devshells "shells")
          (std.blockTypes.functions "overlays")
          (std.blockTypes.installables "packages")
          (std.blockTypes.pkgs "pkgs")
        ];
      }
      {
        overlays.lixPackages = std.harvest self [
          "lix"
          "overlays"
          "lixPackages"
        ];

        packages = std.harvest self [
          "lix"
          "packages"
        ];
      };

  nixConfig = {
    # We set some dummy Nix config here so we can use it for verification in our
    # CI test
    stalled-download-timeout = 333; # default 300
  };
}
