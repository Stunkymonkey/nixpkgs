{ stdenv
, lib
, callPackage
, fetchFromGitHub
, bundlerEnv
, nixosTests
, ruby_3_2
}:
let
  version = "1.2.8";
  src = fetchFromGitHub {
    owner = "docusealco";
    repo = "docuseal";
    rev = version;
    hash = "sha256-mzxePsSX0/euCOXQntrCil1xg7mcPQaYMnKijH9hArg=";
  };
  meta = with lib; {
    description = "Open source DocuSign alternative. Create, fill, and sign digital documents.";
    homepage = "https://www.docuseal.co/";
    license = licenses.agpl3Only;
    maintainers = with maintainers; [ stunkymonkey ];
    platforms = platforms.unix;
  };

  bundler = bundler.override {
    ruby = ruby_3_2;
  };
  rubyEnv = bundlerEnv {
    name = "docuseal-gems";
    ruby = ruby_3_2;
    inherit bundler;
    gemdir = ./.;
  };

  web = callPackage ./web.nix { inherit version src meta rubyEnv; };
in
stdenv.mkDerivation rec {

  pname = "docuseal";
  inherit version src meta;

  buildInputs = [ rubyEnv ];
  propagatedBuildInputs = [ rubyEnv.wrappedRuby ];

  RAILS_ENV = "production";
  BUNDLE_WITHOUT = "development:test";

  installPhase = ''
    runHook preInstall

    mkdir -p $out/public/packs
    cp -r ${src}/* $out
    cp -r ${web}/* $out/public/packs/

    bundle exec bootsnap precompile --gemfile app/ lib/

    runHook postInstall
  '';

  passthru = {
    tests = {
      docuseal-psql = nixosTests.docuseal-postgresql;
      docuseal-sqlite = nixosTests.docuseal-sqlite;
    };
    # run with: nix-shell maintainers/scripts/update.nix --argstr path docuseal
    updateScript = ./update.sh;
  };
}
