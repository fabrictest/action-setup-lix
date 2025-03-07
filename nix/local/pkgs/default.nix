let
  inherit (inputs) nixpkgs;
in
nixpkgs.appendOverlays [
  (self: super: super.prefer-remote-fetch self super)
]
