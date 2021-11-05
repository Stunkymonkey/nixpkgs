{ lib, buildFHSUserEnv, pname, version, src, withGui ? false, withTeensyduino ? false, gtk3 ? null }:
let
  arduino-pkgs = pkgs:
    let
      arduino-core = pkgs.callPackage ./core.nix { inherit pname version src withGui withTeensyduino gtk3; };
    in
    (with pkgs; [
      ncurses
      arduino-core
      zlib
      (python3.withPackages (p: with p; [
        pyserial
      ]))
    ]);

in
buildFHSUserEnv {
  name = "${pname}-${version}";

  targetPkgs = arduino-pkgs;
  multiPkgs = null;

  extraInstallCommands = ''
    ${lib.optionalString withGui ''
      # desktop file
      mkdir -p $out/share/applications
      cp ${src}/build/linux/dist/desktop.template $out/share/applications/arduino.desktop
      substituteInPlace $out/share/applications/arduino.desktop \
        --replace '<BINARY_LOCATION>' "$out/bin/arduino" \
        --replace '<ICON_NAME>' "$out/share/arduino/icons/128x128/apps/arduino.png"
      # icon file
      mkdir -p $out/share/arduino
      cp -r ${src}/build/shared/icons $out/share/arduino
    ''}
  '';

  runScript = "arduino";

  meta = with lib; {
    description = "Open-source electronics prototyping platform";
    homepage = "https://www.arduino.cc/";
    license = if withTeensyduino then licenses.unfreeRedistributable else licenses.gpl2;
    platforms = platforms.linux;
    maintainers = with maintainers; [ stunkymonkey ];
  };
}
