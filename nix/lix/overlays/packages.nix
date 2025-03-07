let
  inherit (inputs) l;

  isLix = name: _drv: l.match "^lix-[0-9_]+$" name != null;
in
_self: _super: l.filterAttrs isLix cell.packages
