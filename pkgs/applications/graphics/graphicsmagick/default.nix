{
  lib
, bzip2
, fetchurl
, fixDarwinDylibNames
, freetype
, ghostscript
, graphviz
, libX11
, libjpeg
, libpng
, libtiff
, libtool
, libwebp
, libxml2
, perl
, quantumdepth ? 8
, stdenv
, xz
, zlib
}:

stdenv.mkDerivation rec {
  pname = "graphicsmagick";
  version = "1.3.36";

  src = fetchurl {
    url = "mirror://sourceforge/graphicsmagick/GraphicsMagick-${version}.tar.xz";
    sha256 = "0ilg6fkppb4avzais1dvi3qf6ln7v3mzj7gjm83w7pwwfpg3ynsx";
  };

  patches = [
    ./disable-popen.patch
  ];

  outputs = [ "out" "dev" ];

  enableParallelBuilding = true;

  configureFlags = [
    "--enable-shared"
    "--with-frozenpaths"
    "--with-modules"
    "--with-perl=${perl}/bin/perl"
    "--with-quantum-depth=${toString quantumdepth}"
  ];

  nativeBuildInputs = [ xz ]
    ++ lib.optional stdenv.hostPlatform.isDarwin fixDarwinDylibNames;

  buildInputs =
    [
      bzip2
      freetype
      ghostscript
      graphviz
      libX11
      libjpeg
      libpng
      libtiff
      libtool
      libwebp
      libxml2
      perl
      zlib
    ];

  postBuild = ''
    # PerMagick needs to be built separately.
    cd PerlMagick
    # However, it does not find the GraphicsMagick library (-lGraphicsMagick).
    ${perl}/bin/perl Makefile.PL
    make
  '';

  postInstall = ''
    sed -i 's/-ltiff.*'\'/\'/ $out/bin/*

    moveToOutput "PerlMagick" "$dev" # why not doing anything?
    mv "PerlMagick" "$dev"
    #moveToOutput "magick" "$dev" # why not doing anything?
    #mv "magick/*" "$dev/include/GraphicsMagick/"

    moveToOutput "bin/*-config" "$dev"
    moveToOutput "lib/libGraphicsMagick.so.*" "$dev" # includes configure params
    moveToOutput "lib/GraphicsMagick-*/config*" "$dev" # includes configure params
  '';

  meta = {
    homepage = "http://www.graphicsmagick.org";
    description = "Swiss army knife of image processing";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
    maintainers = with maintainers; [ stunkymonkey, dschrempf ];
  };
}
