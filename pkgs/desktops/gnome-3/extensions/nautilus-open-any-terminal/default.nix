{ lib, python3Packages, fetchFromGitHub, gnome3, glib, gtk3, python38Packages, wrapGAppsHook }:

python3Packages.buildPythonPackage rec {
  pname = "nautilus-open-any-terminal";
  version = "0.2.10";

  src = fetchFromGitHub {
    owner = "Stunkymonkey";
    repo = "nautilus-open-any-terminal";
    rev = "${version}";
    sha256 = "1h6kigiga9mqi96b7pq28i5p51l9w561f7q7x3yc68aparm51pxz";
  };

  nativeBuildInputs = [
    gnome3.gobject-introspection
    gnome3.nautilus
    gnome3.nautilus-python
    glib
    gtk3
    python38Packages.pygobject3
    wrapGAppsHook
  ];

  makeFlags = [ "INSTALLBASE=${placeholder "out"}/share/gnome-shell/extensions" ];

  doCheck = false; # fails, because settings are not found

  postInstall = ''
    ${glib.dev}/bin/glib-compile-schemas $out/share/glib-2.0/schemas
  '';

  uuid = "nautilus-open-any-terminal@Stunkymonkey.github.io";

  meta = with lib; {
    description = "extension for nautilus, which adds an context-entry for opening other editor then `gnome-terminal`.";
    license = licenses.gpl3;
    maintainers = with maintainers; [ stunkymonkey ];
    homepage = "https://github.com/Stunkymonkey/nautilus-open-any-terminal";
  };
}
