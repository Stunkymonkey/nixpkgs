{ lib
, stdenv
, fetchurl
, bzip2
, freetype
, graphviz
, ghostscript
, libjpeg
, libpng
, libtiff
, libxml2
, zlib
, libtool
, xz
, libX11
, libwebp
, quantumdepth ? 8
, fixDarwinDylibNames
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
    "--with-perl"
    "--with-quantum-depth=${toString quantumdepth}"
    "--with-gslib=yes"
    "--with-threads"
  ];

  buildInputs =
    [
      bzip2
      freetype
      ghostscript
      graphviz
      libjpeg
      libpng
      libtiff
      libX11
      libxml2
      zlib
      libtool
      libwebp
    ];

  nativeBuildInputs = [ xz ]
    ++ lib.optional stdenv.hostPlatform.isDarwin fixDarwinDylibNames;

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
  };
}
