# deadnix: skip
{ inputs, cell }:
let
  inherit (inputs) l;
  inherit (cell) packages;
in
{
  lixPackages = _: _: l.filterAttrs (name: _: name != "lix-stores") packages;

  preferRemoteFetch = self: super: super.prefer-remote-fetch self super;
}
