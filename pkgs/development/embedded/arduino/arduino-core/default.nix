{ lib, newScope, fetchFromGitHub, withGui ? false, withTeensyduino ? false, gtk3 }:

let
  callPackage = newScope self;

  pname = (if withTeensyduino then "teensyduino" else "arduino") + lib.optionalString (!withGui) "-core";
  version = "1.8.16";

  src = fetchFromGitHub {
    owner = "arduino";
    repo = "Arduino";
    rev = version;
    sha256 = "sha256-6d+y0Lgr+h0qYpCsa/ihvSMNuAdRMNQRuxZFpkWLDvg=";
  };

  self = {
    arduino-chrootenv = callPackage ./chrootenv.nix { inherit pname version src withGui withTeensyduino gtk3; };
  };

in
self
