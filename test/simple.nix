let
  # Pinning explicitly to 20.03 to avoid issues with an outdated cache.
  rev = "5272327b81ed355bbed5659b8d303cf2979b6953";
  nixpkgs = fetchTarball "https://github.com/NixOS/nixpkgs/archive/${rev}.tar.gz";
  pkgs = import nixpkgs {};
in with pkgs; [
  hello
]
