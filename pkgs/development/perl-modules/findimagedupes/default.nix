{ lib, stdenv, fetchFromGitHub, makeWrapper, perlPackages, PerlGMagick, DBFile, FileMimeInfo, FileBaseDir, FileTemp, MIMEBase64, PodUsage }:

stdenv.mkDerivation rec {
  pname = "findimagedupes";
  version = "2.19.1";

  src = fetchFromGitHub {
    owner = "jhnc";
    repo = "${pname}";
    rev = "${version}";
    sha256 = "19hchaxzzq7kwrcnm3m2zyigq38kdc9l0jp6pz6cm9hfxna58518";
  };

  nativeBuildInputs = with perlPackages; [ makeWrapper PodMarkdown ];

  propagatedBuildInputs = with perlPackages; [ perl ];

  preBuild = ''
    sed -i -e "s:DIRECTORY => '/usr/local/lib/findimagedupes':DIRECTORY => '/tmp':" findimagedupes
  '';

  buildPhase = "
    pod2man findimagedupes > findimagedupes.1
  ";

  installPhase = ''
    install -D -m 755 findimagedupes $out/bin/findimagedupes
    wrapProgram $out/bin/findimagedupes --set PERL5LIB ${with perlPackages; makeFullPerlPath [ DBFile FileMimeInfo FileBaseDir FileTemp MIMEBase64 PerlGMagick PodUsage ]}
    install -D -m 644 findimagedupes.1 $out/share/man/man1/findimagedupes.1
  '';

  meta = with lib; {
    homepage = "http://www.jhnc.org/findimagedupes/";
    description = "Finds visually similar or duplicate images";
    license = licenses.gpl3;
    maintainers = with maintainers; [ stunkymonkey dschrempf ];
  };
}
