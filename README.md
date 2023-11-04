# Cache install Nix packages

This actions allows caching of installations done via the [Nix package manager](https://nixos.org) to improve workflow execution time. 

[![][tests-img]][tests-url]

Installing packages via the Nix package manager is generally quite quick.
However, sometimes the packages take a long time to compile or to download from their original sources.
For example, this occurs with R packages and LaTeX which are downloaded from respectively `CRAN` and `math.utah.edu`.
This GitHub Action speeds up the installation by simply caching the Nix store and the symlinks to the packages in the store in the [GitHub Actions cache](https://github.com/actions/cache).
So, the installed packages are restored from the cache by copying back `/nix/store`, the symlinks to `/nix/store/*` and some paths for the PATH environment variable.

## Inputs

- `key` - An explicit key for restoring and saving the cache.
- `restore-keys` - An ordered list of keys to use for restoring the cache if no cache hit occurred for key.
- `nix_version` - Nix version, defaults to `nixos-unstable`.
- `nix_file` - Nix file, defaults to `default.nix`.
- `nix_install_url` - Install URL for the Nix package manager; obtain newest via https://nixos.org/nix/install.

## Outputs

- `cache-hit` - A boolean value to indicate an exact match was found for the primary key.

## Example workflow

```yml
name: latex

on: push

jobs:
  build:
    runs-on: ubuntu-latest

    steps:
    - uses: actions/checkout@v4

    - name: Cache install Nix packages
      uses: rikhuijzer/cache-install@v1
      with:
        key: nix-${{ hashFiles('mypackages.nix') }}
        nix_file: 'mypackages.nix'

    - name: Calculate some things
      run: julia -e 'using MyPackage; MyPackage.calculate()'

    - name: Build LaTeX
      run: latexmk -f -pdf example.tex

    - name: Build website
      run: hugo --gc --minify
```

where the file `mypackages.nix` contains

```nix
let
  # Pinning explicitly to 20.03.
  rev = "5272327b81ed355bbed5659b8d303cf2979b6953";
  nixpkgs = fetchTarball "https://github.com/NixOS/nixpkgs/archive/${rev}.tar.gz";
  pkgs = import nixpkgs {};
  myTex = with pkgs; texlive.combine {
    inherit (texlive) scheme-medium pdfcrop;
  };
in with pkgs; [
  hugo
  julia
  myTex
]
```

[tests-img]: https://github.com/rikhuijzer/cache-install/workflows/test/badge.svg
[tests-url]: https://github.com/rikhuijzer/cache-install/actions
