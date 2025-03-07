let
  inherit (inputs) l;
  inherit (cell) pkgs;

  lixVersions = l.pipe pkgs.lixVersions [
    (l.filterAttrs (_name: l.isDerivation))
    (l.mapAttrs' (
      _name: drv: l.nameValuePair "${drv.pname}-${l.replaceStrings [ "." ] [ "_" ] drv.version}" drv
    ))
  ];

  mkLixStore =
    lix:
    pkgs.runCommand "mk-lix-store"
      {
        buildInputs = [
          lix
          pkgs.gnutar
          pkgs.zstd
        ];
        closureInfo = pkgs.closureInfo { rootPaths = [ lix ]; };
        fileName = "${lix.pname}-${lix.version}-${lix.system}.tar.zstd";
        inherit lix;
      }
      ''
        mkdir -p "$out" root/nix/var/{nix,gha}
        ln -s "$lix" root/nix/var/gha/lix
        cp {"$closureInfo",root/nix/var/gha}/registration
        tar -ac -C root -T "$closureInfo/store-paths" -f "$out/$fileName" nix
      '';
in
lixVersions
// rec {
  default = lix-stores;
  lix-stores =
    (pkgs.buildEnv {
      name = "lix-stores";
      paths = l.mapAttrsToList (_name: mkLixStore) lixVersions;
    }).overrideAttrs
      {
        preferLocalBuild = false;
        allowSubstitutes = true;
      };
}
