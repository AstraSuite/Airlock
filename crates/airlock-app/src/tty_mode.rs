//! TtyMode: what Colours needs from Rust to draw the TTY look, as Atlas and
//! KiiteShell draw it: whether the active user's KiiteShell theme is TTY
//! (for the "Follow KiiteShell" style), its fonts, whether `--tty` forced
//! it, and the Nerd glyph table. Colours (QML) decides from these and the
//! user's `uiStyle` whether TTY is on.

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
        #[qproperty(QString, active_user, READ, WRITE = set_active_user, NOTIFY = active_user_changed, cxx_name = "activeUser")]
        #[qproperty(bool, kiite_tty, READ, NOTIFY = appearance_changed, cxx_name = "kiiteTty")]
        #[qproperty(bool, kiite_available, READ, NOTIFY = appearance_changed, cxx_name = "kiiteAvailable")]
        #[qproperty(QString, mono, READ, NOTIFY = appearance_changed)]
        #[qproperty(QString, icon_nerd, READ, NOTIFY = appearance_changed, cxx_name = "iconNerd")]
        #[qproperty(bool, forced, READ, CONSTANT)]
        type TtyMode = super::TtyModeRust;

        #[qsignal]
        #[cxx_name = "activeUserChanged"]
        fn active_user_changed(self: Pin<&mut TtyMode>);
        #[qsignal]
        #[cxx_name = "appearanceChanged"]
        fn appearance_changed(self: Pin<&mut TtyMode>);

        #[cxx_name = "setActiveUser"]
        fn set_active_user(self: Pin<&mut TtyMode>, value: QString);

        #[qinvokable]
        fn reload(self: Pin<&mut TtyMode>);

        /// The Nerd glyph for the Material symbol `name`, or "" if the
        /// table has none.
        #[qinvokable]
        #[cxx_name = "nerdGlyph"]
        fn nerd_glyph(self: &TtyMode, name: &QString) -> QString;
    }

    impl cxx_qt::Constructor<()> for TtyMode {}
}

use crate::kiite;
use cxx_qt::CxxQtType;
use cxx_qt_lib::QString;
use std::pin::Pin;

pub struct TtyModeRust {
    active_user: QString,
    kiite_tty: bool,
    kiite_available: bool,
    mono: QString,
    icon_nerd: QString,
    forced: bool,
}

impl Default for TtyModeRust {
    fn default() -> Self {
        Self {
            active_user: QString::default(),
            kiite_tty: false,
            kiite_available: false,
            mono: QString::default(),
            icon_nerd: QString::default(),
            forced: crate::cli::force_tty(),
        }
    }
}

impl cxx_qt::Initialize for ffi::TtyMode {
    fn initialize(self: Pin<&mut Self>) {
        self.reload();
    }
}

impl ffi::TtyMode {
    pub fn set_active_user(mut self: Pin<&mut Self>, value: QString) {
        if self.active_user == value {
            return;
        }
        self.as_mut().rust_mut().active_user = value;
        self.as_mut().active_user_changed();
        self.reload();
    }

    pub fn reload(mut self: Pin<&mut Self>) {
        let appearance = kiite::appearance(&self.active_user.to_string());
        let mut rust = self.as_mut().rust_mut();
        rust.kiite_available = appearance.is_some();
        let a = appearance.unwrap_or(kiite::Appearance { tty: false, mono: String::new(), icon_nerd: String::new() });
        rust.kiite_tty = a.tty;
        rust.mono = QString::from(a.mono.as_str());
        rust.icon_nerd = QString::from(a.icon_nerd.as_str());
        self.as_mut().appearance_changed();
    }

    pub fn nerd_glyph(&self, name: &QString) -> QString {
        kiite::nerd_glyph(&name.to_string()).map(|c| QString::from(c.to_string().as_str())).unwrap_or_default()
    }
}
