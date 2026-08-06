{
  lib,
  stdenv,
  cmake,
  ninja,
  pkg-config,
  qt6,
  quickshell,
  m3shapes,
  makeWrapper,
}:
stdenv.mkDerivation {
  pname = "caelestia-greeter";
  version = "1.0.0";

  src = ./..;

  nativeBuildInputs = [
    cmake
    ninja
    pkg-config
    qt6.wrapQtAppsHook
    makeWrapper
  ];

  buildInputs = [
    qt6.qtbase
    qt6.qtdeclarative
    qt6.qtquick3d
  ];

  cmakeFlags = [
    "-DFETCHCONTENT_SOURCE_DIR_M3SHAPES_EXTERNAL=${m3shapes}"
    "-DINSTALL_QSCONFDIR=etc/xdg/quickshell/caelestia-greeter"
  ];

  postInstall = ''
    wrapProgram $out/bin/caelestia-greeter \
      --prefix PATH : ${lib.makeBinPath [ quickshell ]} \
      --prefix QML2_IMPORT_PATH : "$out/lib/qt6/qml:$QML2_IMPORT_PATH"
  '';

  meta = with lib; {
    description = "A Quickshell frontend for greetd matching Caelestia M3 design";
    homepage = "https://github.com/dim-ghub/caelestia-greeter";
    license = licenses.mit;
    platforms = platforms.linux;
  };
}
