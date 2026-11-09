{
  lib,
  stdenv,
  rustPlatform,
  cmake,
  ninja,
  pkg-config,
  qt6,
  m3shapes,
  wlr-randr,
}:
let
  # M3Shapes is a small standalone QML plugin (Astra Airlock no longer
  # vendors or links against caelestia-shell at all; see
  # native/blobs/NOTICE.md for the parts that *are* vendored). Built the
  # same way Airlock's own QML module used to be, from the `m3shapes` flake
  # input's source. This isn't verified against m3shapes's actual
  # CMakeLists.txt (no Nix available in the environment this was written
  # in to build-test it) — if its install layout differs, adjust here.
  m3shapesQml = stdenv.mkDerivation {
    pname = "m3shapes-qml";
    version = "unstable";
    src = m3shapes;

    nativeBuildInputs = [
      cmake
      ninja
      pkg-config
      qt6.wrapQtAppsHook
    ];
    buildInputs = [
      qt6.qtbase
      qt6.qtdeclarative
    ];
  };
in
rustPlatform.buildRustPackage {
  pname = "astra-airlock";
  version = "0-unstable-2025-01-15";

  src = ./..;

  cargoLock = {
    lockFile = ../Cargo.lock;
  };

  nativeBuildInputs = [
    pkg-config
    qt6.qtshadertools # provides `qsb`, used to bake the vendored Blobs shaders
    qt6.wrapQtAppsHook
  ];

  buildInputs = [
    qt6.qtbase
    qt6.qtdeclarative
  ];

  # cxx-qt-build needs `qmake` on PATH to find Qt.
  QMAKE = "${qt6.qtbase}/bin/qmake";

  postFixup = ''
    wrapProgram $out/bin/astra-airlock \
      --prefix PATH : ${lib.makeBinPath [ wlr-randr ]} \
      --prefix QML2_IMPORT_PATH : "${m3shapesQml}/lib/qt6/qml"
  '';

  meta = with lib; {
    description = "A Rust/Qt6 frontend for greetd matching Caelestia's M3 design";
    homepage = "https://github.com/AstraSuite/Airlock";
    license = licenses.gpl3Only;
    platforms = platforms.linux;
  };
}
