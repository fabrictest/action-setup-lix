let
  inherit (inputs) l;
in
_self: _super: l.filterAttrs (name: _drv: name != "lix-stores") cell.packages
