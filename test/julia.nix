let
  # Pinning explicitly to 20.03 to avoid issues with an outdated cache.
  rev = "5272327b81ed355bbed5659b8d303cf2979b6953";
  nixpkgs = fetchTarball "https://github.com/NixOS/nixpkgs/archive/${rev}.tar.gz";
  pkgs = import nixpkgs { 
    inherit config; 
  };

  config = {
    allowBroken = true;
  };

  papajaBuildInputs = with pkgs.rPackages; [
    afex
    base64enc
    beeswarm
    bookdown
    broom
    knitr
    rlang
    rmarkdown
    rmdfiltr
    yaml
  ];
  papaja = with pkgs.rPackages; buildRPackage {
    name = "papaja";
    src = pkgs.fetchFromGitHub {
      owner = "crsh";
      repo = "papaja";
      rev = "b0a224a5e67e1afff084c46c2854ac6f82b12179";
      sha256 = "14pxnlgg7pzazpyx0hbv9mlvqdylylpb7p4yhh4w2wlcw6sn3rwj";
    };
    # Do not add propagatedBuildInputs = papajaBuildInputs since
    # it might cause a buffer overflow when calling `devtools::document`.
    nativeBuildInputs = papajaBuildInputs;
  };
  my-r-packages = with pkgs.rPackages; [
    ggplot2
  ];
  R-with-my-packages = pkgs.rWrapper.override{
    packages = my-r-packages;
  };

  julia_15 = pkgs.stdenv.mkDerivation {
    name = "julia_15";
    src = pkgs.fetchurl {
      url = "https://julialang-s3.julialang.org/bin/linux/x64/1.5/julia-1.5.2-linux-x86_64.tar.gz";
      sha256 = "0c26b11qy4csws6vvi27lsl0nmqszaf7lk1ya0jrg8zgvkx099vd";
    };
    installPhase = ''
      mkdir $out
      cp -R * $out/

      # Patch for https://github.com/JuliaInterop/RCall.jl/issues/339.

      echo "patching $out"
      cp -L ${pkgs.stdenv.cc.cc.lib}/lib/libstdc++.so.6 $out/lib/julia/
    '';
    dontStrip = true;
    ldLibraryPath = with pkgs; stdenv.lib.makeLibraryPath [
      stdenv.cc.cc
      zlib
      glib
      xorg.libXi
      xorg.libxcb
      xorg.libXrender
      xorg.libX11
      xorg.libSM
      xorg.libICE
      xorg.libXext
      dbus
      fontconfig
      freetype
      libGL
    ];
  };
  targetPkgs = pkgs: with pkgs; [
    autoconf
    curl
    gnumake
    utillinux
    m4
    gperf
    unzip
    stdenv.cc
    clang
    binutils
    which
    gmp
    libxml2
    cmake

    fontconfig
    openssl
    which
    ncurses
    gtk2-x11
    atk
    gdk_pixbuf
    cairo
    xorg.libX11
    xorg.xorgproto
    xorg.libXcursor
    xorg.libXrandr
    xorg.libXext
    xorg.libSM
    xorg.libICE
    xorg.libX11
    xorg.libXrandr
    xorg.libXdamage
    xorg.libXrender
    xorg.libXfixes
    xorg.libXcomposite
    xorg.libXcursor
    xorg.libxcb
    xorg.libXi
    xorg.libXScrnSaver
    xorg.libXtst
    xorg.libXt
    xorg.libXxf86vm
    xorg.libXinerama
    nspr
    pdf2svg

    # Nvidia note: may need to change cudnn to match cudatoolkit version
    # cudatoolkit_10_0
    # cudnn_cudatoolkit_10_0
    # linuxPackages.nvidia_x11

    julia_15

    # Arpack.jl
    arpack
    gfortran.cc
    (pkgs.runCommand "openblas64_" {} ''
    mkdir -p "$out"/lib/
    ln -s ${openblasCompat}/lib/libopenblas.so "$out"/lib/libopenblas64_.so.0
    '')

    # Cairo.jl
    cairo
    gettext
    pango.out
    glib.out
    # Gtk.jl
    gtk3
    gtk2
    fontconfig
    gdk_pixbuf
    # GR.jl # Runs even without Xrender and Xext, but cannot save files, so those are required
    qt4
    glfw
    freetype

    conda

    #misc
    xorg.libXxf86vm
    xorg.libSM
    xorg.libXtst
    libpng
    expat
    gnome2.GConf
    nss

  ];

  env_vars = ''
    export EXTRA_CCFLAGS="-I/usr/include"

    # Points RCall to `libR.so`.
    export LD_LIBRARY_PATH="${pkgs.R}/lib/R/lib:$LD_LIBRARY_PATH"
    # Ensure that RCall uses the same R version as used by `libR.so`.
    # export R_HOME="${pkgs.R}/bin"

    # This does not add dependencies (recursively)!
    # Leaving the code since it was an interesting approach.
    # export R_LIBS_USER="$<removed open curly bracket here>
    #  (lib.concatMapStringsSep ":" (path: path + "/library") my-r-packages)
    # }"
    # export R_LIBS_USER=$R_LIBS_USER:$(R -e 'paste(.libPaths(), collapse=":")')

    # This seems to run after nixos-rebuild-switch, so R knows all the packages.
    # Do not set `R_LIBS_USER` since `using RCall` will overwrite it.
    LIBRARIES=$(Rscript -e 'paste(.libPaths(), collapse=":")')
    export R_LIBS_SITE="$(echo $LIBRARIES | cut -c6- | rev | cut -c2- | rev)"
  '';
  extraOutputsToInstall = ["man" "dev"];
  multiPkgs = pkgs: with pkgs; [ zlib ];

  julia-debug = pkgs.buildFHSUserEnv {
    targetPkgs = targetPkgs;
    name = "julia-debug"; # Name used to start this UserEnv
    multiPkgs = multiPkgs;
    runScript = "bash";
    extraOutputsToInstall = extraOutputsToInstall;
    profile = env_vars;
  };

  julia-fhs = pkgs.buildFHSUserEnv {
    targetPkgs = targetPkgs;
    name = "julia"; # Name used to start this UserEnv
    multiPkgs = multiPkgs;
    runScript = "julia";
    extraOutputsToInstall = extraOutputsToInstall;
    profile = env_vars;
  };
in with pkgs; [
  julia-fhs
  R-with-my-packages
]
