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
  symlinkJoin,
  writeShellScriptBin,
  material-symbols,
}:
let
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
    cmakeFlags = [
      "-DINSTALL_QMLDIR=lib/qt6/qml"
    ];
  };

  qtCombined = symlinkJoin {
    name = "qt6-combined";
    paths = [
      qt6.qtbase
      qt6.qtdeclarative
      qt6.qtshadertools
    ];
  };

  qmakeWrapper = writeShellScriptBin "qmake" ''
    if [ "$1" = "-query" ]; then
      case "$2" in
        QT_INSTALL_LIBS|QT_HOST_LIBS) echo "${qtCombined}/lib"; exit 0 ;;
        QT_INSTALL_HEADERS|QT_HOST_HEADERS) echo "${qtCombined}/include"; exit 0 ;;
        QT_INSTALL_PREFIX|QT_HOST_PREFIX) echo "${qtCombined}"; exit 0 ;;
        QT_INSTALL_PLUGINS|QT_HOST_PLUGINS) echo "${qtCombined}/lib/qt-6/plugins"; exit 0 ;;
        QT_INSTALL_LIBEXECS|QT_HOST_LIBEXECS|QT_INSTALL_LIBEXECS/get|QT_HOST_LIBEXECS/get) echo "${qtCombined}/libexec"; exit 0 ;;
        QT_INSTALL_BINS|QT_HOST_BINS|QT_INSTALL_BINS/get|QT_HOST_BINS/get) echo "${qtCombined}/bin"; exit 0 ;;
      esac
    fi
    exec ${qt6.qtbase}/bin/qmake "$@"
  '';
in
rustPlatform.buildRustPackage {
  pname = "astra-airlock";
  version = "2.1.0";

  src = ./..;

  cargoLock = {
    lockFile = ../Cargo.lock;
  };

  nativeBuildInputs = [
    pkg-config
    qt6.qtshadertools
    qt6.wrapQtAppsHook
  ];

  buildInputs = [
    qt6.qtbase
    qt6.qtdeclarative
    qt6.qtshadertools
  ];

  preBuild = ''
    mkdir -p .qmake-bin
    ln -sf "${qmakeWrapper}/bin/qmake" .qmake-bin/qmake
    ln -sf "${qmakeWrapper}/bin/qmake" .qmake-bin/qmake6
    export PATH="$(pwd)/.qmake-bin:$PATH"
    export QMAKE="$(pwd)/.qmake-bin/qmake"
    export QT_INSTALL_LIBS="${qtCombined}/lib"
    export QT_INSTALL_HEADERS="${qtCombined}/include"
    export QT_INSTALL_PREFIX="${qtCombined}"
    export QT_HOST_LIBEXECS="${qtCombined}/libexec"
    export QT_INSTALL_LIBEXECS="${qtCombined}/libexec"
  '';

  postPatch = ''
    cp "${material-symbols}/share/fonts/truetype/MaterialSymbolsRounded[FILL,GRAD,opsz,wght].ttf" \
      assets/fonts/MaterialSymbolsRounded.ttf
  '';

  postFixup = ''
    wrapProgram $out/bin/astra-airlock \
      --prefix PATH : ${lib.makeBinPath [ wlr-randr ]} \
      --prefix QML2_IMPORT_PATH : "${m3shapesQml}/lib/qt6/qml" \
      --prefix LD_LIBRARY_PATH : "${m3shapesQml}/lib/qt6/qml/M3Shapes"
  '';

  meta = with lib; {
    description = "A Rust/Qt6 frontend for greetd matching Caelestia's M3 design";
    homepage = "https://github.com/AstraSuite/Airlock";
    license = licenses.gpl3Only;
    platforms = platforms.linux;
  };
}
