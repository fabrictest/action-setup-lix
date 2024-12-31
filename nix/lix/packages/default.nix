# deadnix: skip
{ inputs, cell }:
let
  inherit (inputs) l;
  inherit (cell) pkgs;

  lixVersions = l.pipe pkgs.lixVersions [
    (l.filterAttrs (_: l.isDerivation))
    (l.mapAttrs' (
      _: lix: l.nameValuePair "${lix.pname}-${l.replaceStrings [ "." ] [ "_" ] lix.version}" lix
    ))
  ];

  mkLixStore =
    _: lix:
    pkgs.runCommand "mk-lix-store"
      {
        buildInputs = [
          lix
          pkgs.gnutar
          pkgs.zstd
        ];
        closureInfo = pkgs.closureInfo { rootPaths = [ lix ]; };
        fileName = "lix-${lix.version}-${lix.system}.tar.zstd";
        inherit lix;

        # FIXME(ttlgcc): Can we fetch this info from somewhere else?
        #  Perhaps from .config/prj_id, as we do in action.yaml?
        MY_ID = "action-setup-lix";
      }
      ''
        mkdir -p root/nix/var/{nix,"$MY_ID"} "$out"
        ln -s "$lix" root/nix/var/"$MY_ID"/lix
        cp {"$closureInfo",root/nix/var/"$MY_ID"}/registration
        tar --auto-compress --create --directory=root --file="$out/$fileName" --files-from="$closureInfo"/store-paths nix
      '';
in
lixVersions
// {
  lix-stores =
    (pkgs.buildEnv {
      name = "lix-stores";
      paths = l.mapAttrsToList mkLixStore lixVersions;
    }).overrideAttrs
      {
        preferLocalBuild = false;
        allowSubstitutes = true;
      };
}
