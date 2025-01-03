let
  inherit (inputs) nixpkgs;
in
nixpkgs.appendOverlays [ cell.overlays.preferRemoteFetch ]
