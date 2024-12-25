# deadnix: skip
{ inputs, cell }:
let
  l = cell.pkgs.lib // builtins;
in
{
  lixPackages = _: _: l.filterAttrs (name: _: name != "lix-stores") cell.packages;

  preferRemoteFetch = self: super: super.prefer-remote-fetch self super;
}
