mod cli;
mod greeter_state;
mod user_discovery;
mod session_discovery;
mod scheme_discovery;
mod session_manager;
mod greetd;
mod system_info;
mod battery;
mod quickshell_compat;

use cxx_qt_lib::{QGuiApplication, QQmlApplicationEngine, QString, QUrl};

// Vendored from caelestia-shell (native/blobs, GPLv3, see its NOTICE.md);
// registers BlobGroup/BlobRect/BlobInvertedRect into the Astra.Airlock QML
// module. Plain C linkage, not a cxx bridge, since it needs no Rust-side type.
unsafe extern "C" {
    fn registerBlobsQmlTypes();
}

fn main() {
    unsafe { registerBlobsQmlTypes() };

    // Still handles --sync/--set-wallpaper/--kiosk/monitor flags/etc; the
    // whole QML tree is now baked into this binary (see build.rs), so there
    // is no config directory to resolve for the UI itself any more.
    if let cli::Action::Exit(code) = cli::run() {
        std::process::exit(code);
    }

    let mut app = QGuiApplication::new();
    let mut engine = QQmlApplicationEngine::new();

    if engine.as_mut().is_some() {
        if let Some(engine) = engine.as_mut() {
            engine.add_import_path(&QString::from("qrc:/airlock"));
        }
        if let Some(engine) = engine.as_mut() {
            engine.load(&QUrl::from("qrc:/airlock/shell.qml"));
        }
    }

    if let Some(app) = app.as_mut() {
        app.exec();
    }
}
