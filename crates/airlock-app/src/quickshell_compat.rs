// A tiny stand-in for the one Quickshell API still referenced in QML after the
// Quickshell dependency itself is gone: `Quickshell.env(name)` in SystemInfo.qml.
// Named `Quickshell` (not `QuickshellCompat`) so that single call site needs no edit.

#[cxx_qt::bridge]
pub mod ffi {
    unsafe extern "C++" {
        include!("cxx-qt-lib/qstring.h");
        type QString = cxx_qt_lib::QString;
    }

    extern "RustQt" {
        #[qobject]
        #[qml_element]
        #[qml_singleton]
        type Quickshell = super::QuickshellRust;

        #[qinvokable]
        fn env(self: &Quickshell, name: QString) -> QString;
    }
}

use cxx_qt_lib::QString;

#[derive(Default)]
pub struct QuickshellRust;

impl ffi::Quickshell {
    pub fn env(&self, name: QString) -> QString {
        QString::from(std::env::var(name.to_string()).unwrap_or_default().as_str())
    }
}
