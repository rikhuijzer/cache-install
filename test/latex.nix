let
  # Pinning explicitly to 20.03.
  rev = "5272327b81ed355bbed5659b8d303cf2979b6953";
  nixpkgs = fetchTarball "https://github.com/NixOS/nixpkgs/archive/${rev}.tar.gz";
  pkgs = import nixpkgs {};
  myTex = with pkgs; texlive.combine {
    inherit (texlive) scheme-minimal pdfcrop;
  };
in [
  myTex
]
