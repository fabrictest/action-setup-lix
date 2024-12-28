# deadnix: skip
{ inputs, cell }:
let
  l = pkgs.lib // builtins;

  inherit (cell) packages pkgs;
in
{
  lixPackages = _: _: l.filterAttrs (name: _: name != "lix-stores") packages;

  preferRemoteFetch = self: super: super.prefer-remote-fetch self super;
}
