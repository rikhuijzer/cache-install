# cache-install

This actions allows caching of installations from the Nix package manager to improve workflow execution time. 

[![][tests-img]][tests-url]

Installing packages via the Nix package manager is generally quite quick.
However, sometimes the packages take a long time to compile or to download from their original sources.
For example, this occurs with R packages and LaTeX.
This GitHub Action speeds up the installation by simply caching the Nix store and the symlinks to the packages in the store.
So, the installed packages are restored from the cache by copying back `/nix/store`, the symlinks to `/nix/store/*`, and some paths for the PATH environment variable.
The cache uses the GitHub cache action: <https://github.com/actions/cache/>.

## Example workflow

```
name: latex

on: push

jobs:
  build:
    runs-on: ubuntu-latest

    steps:
    - uses: actions/checkout@v2

    - name: Install LaTeX
      uses: nix-actions/cache-install@v1.0.3
      with:
        key: nix-${{ hashFiles('latex.nix') }}
        nix_file: 'latex.nix'

    - name: Build LaTeX
      run: latexmk -f -pdf example.tex
```

where the file `latex.nix` contains

```
let
  # Pinning explicitly to 20.03.
  rev = "5272327b81ed355bbed5659b8d303cf2979b6953";
  nixpkgs = fetchTarball "https://github.com/NixOS/nixpkgs/archive/${rev}.tar.gz";
  pkgs = import nixpkgs {};
  myTex = with pkgs; texlive.combine {
    inherit (texlive) scheme-medium pdfcrop;
  };
in [
  myTex
]
```

[tests-img]: https://github.com/nix-actions/cache-install/workflows/test/badge.svg
[tests-url]: https://github.com/nix-actions/cache-install/actions
