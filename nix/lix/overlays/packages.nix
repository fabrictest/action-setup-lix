let
  inherit (inputs) l;
in
_: _: l.filterAttrs (name: _: name != "lix-stores") cell.packages
