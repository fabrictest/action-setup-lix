let
  inherit (inputs) l;
in
{
  lixPackages = _: _: l.filterAttrs (name: _: name != "lix-stores") cell.packages;

  preferRemoteFetch = self: super: super.prefer-remote-fetch self super;
}
