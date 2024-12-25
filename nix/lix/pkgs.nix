{ inputs, cell }:
let
  inherit (inputs) nixpkgs;
  inherit (cell) overlays;
in
nixpkgs.appendOverlays [ overlays.preferRemoteFetch ]
