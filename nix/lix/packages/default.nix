# deadnix: skip
{ inputs, cell }:
let
  l = pkgs.lib // builtins;

  inherit (cell) pkgs;

  lixPackages = l.pipe pkgs.lixVersions [
    (l.filterAttrs (_: l.isDerivation))
    (l.mapAttrs' (
      _: lix: l.nameValuePair "${lix.pname}-${l.replaceStrings [ "." ] [ "_" ] lix.version}" lix
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
        fileName = "lix-${lix.version}-${lix.system}.tar.zst";
        inherit lix;
      }
      ''
        mkdir -p root/nix/var/{nix,action-setup-lix} "$out"
        ln -s "$lix" root/nix/var/action-setup-lix/lix
        cp {"$closureInfo",root/nix/var/action-setup-lix}/registration
        tar --auto-compress --create --directory=root --file="$out/$fileName" --files-from="$closureInfo"/store-paths nix
      '';
in
lixPackages
// {
  lix-stores =
    (pkgs.buildEnv {
      name = "lix-stores";
      paths = l.mapAttrsToList (_: mkLixStore) lixPackages;
    }).overrideAttrs
      {
        preferLocalBuild = false;
        allowSubstitutes = true;
      };
}
