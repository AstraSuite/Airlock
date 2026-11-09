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
        #[qproperty(QString, sessions_json, READ, NOTIFY = sessions_json_changed, cxx_name = "sessionsJson")]
        #[qproperty(i32, default_index, READ, NOTIFY = default_index_changed, cxx_name = "defaultIndex")]
        type SessionDiscovery = super::SessionDiscoveryRust;

        #[qsignal]
        #[cxx_name = "sessionsJsonChanged"]
        fn sessions_json_changed(self: Pin<&mut SessionDiscovery>);
        #[qsignal]
        #[cxx_name = "defaultIndexChanged"]
        fn default_index_changed(self: Pin<&mut SessionDiscovery>);

        #[qinvokable]
        fn reload(self: Pin<&mut SessionDiscovery>);

        #[qinvokable]
        #[cxx_name = "updateDefaultIndex"]
        fn update_default_index(self: Pin<&mut SessionDiscovery>);

        /// Called by QML (Connections on GreeterState.lastUserChanged).
        #[qinvokable]
        #[cxx_name = "setLastUserHint"]
        fn set_last_user_hint(self: Pin<&mut SessionDiscovery>, last_user: QString);

        #[qinvokable]
        #[cxx_name = "saveLastSession"]
        fn save_last_session(self: Pin<&mut SessionDiscovery>, username: QString, session_key: QString);

        #[qinvokable]
        #[cxx_name = "sessionIndexForUser"]
        fn session_index_for_user(self: &SessionDiscovery, username: QString) -> i32;

        #[qinvokable]
        #[cxx_name = "indexOfSession"]
        fn index_of_session(self: &SessionDiscovery, session_key: QString) -> i32;
    }

    impl cxx_qt::Constructor<()> for SessionDiscovery {}
}

use cxx_qt::CxxQtType;
use cxx_qt_lib::QString;
use serde_json::json;
use std::fs;
use std::pin::Pin;

#[derive(Clone)]
pub struct SessionEntry {
    pub name: String,
    pub exec: String,
    pub session_type: String,
    pub file: String,
    pub key: String,
}

pub struct SessionDiscoveryRust {
    sessions: Vec<SessionEntry>,
    sessions_json: QString,
    default_index: i32,
    last_user_hint: String,
}

impl Default for SessionDiscoveryRust {
    fn default() -> Self {
        Self {
            sessions: Vec::new(),
            sessions_json: QString::from("[]"),
            default_index: 0,
            last_user_hint: String::new(),
        }
    }
}

fn parse_directory(dir_path: &str, session_type: &str, out: &mut Vec<SessionEntry>) {
    let Ok(entries) = fs::read_dir(dir_path) else { return };
    for entry in entries.flatten() {
        let path = entry.path();
        if path.extension().and_then(|e| e.to_str()) != Some("desktop") {
            continue;
        }
        let Ok(text) = fs::read_to_string(&path) else { continue };
        let mut name = String::new();
        let mut exec = String::new();
        let mut no_display = false;
        let mut in_entry = false;
        for line in text.lines() {
            let line = line.trim();
            if line.starts_with('[') {
                in_entry = line == "[Desktop Entry]";
                continue;
            }
            if !in_entry {
                continue;
            }
            if let Some(v) = line.strip_prefix("Name=") {
                if name.is_empty() {
                    name = v.trim().to_string();
                }
            } else if let Some(v) = line.strip_prefix("Exec=") {
                if exec.is_empty() {
                    exec = v.trim().to_string();
                }
            } else if let Some(v) = line.strip_prefix("NoDisplay=") {
                no_display = v.trim().eq_ignore_ascii_case("true");
            }
        }
        if no_display {
            continue;
        }

        let file_name = path.file_name().unwrap_or_default().to_string_lossy().to_string();
        let stem = path.file_stem().unwrap_or_default().to_string_lossy().to_string();
        if name.is_empty() {
            name = stem.clone();
        }
        if exec.is_empty() {
            exec = name.to_lowercase();
        }
        let key = stem.to_lowercase();

        if out.iter().any(|s| s.key == key) {
            continue;
        }

        out.push(SessionEntry {
            name,
            exec,
            session_type: session_type.to_string(),
            file: file_name,
            key,
        });
    }
}

fn sessions_to_json(sessions: &[SessionEntry]) -> QString {
    let arr: Vec<_> = sessions
        .iter()
        .map(|s| {
            json!({
                "name": s.name,
                "exec": s.exec,
                "type": s.session_type,
                "file": s.file,
                "key": s.key,
            })
        })
        .collect();
    QString::from(serde_json::to_string(&arr).unwrap_or_else(|_| "[]".to_string()).as_str())
}

/// The same candidate paths GreeterState checks for its own settings file
/// (kept in sync manually since they're separate cxx-qt QObjects with no
/// direct reference to each other).
fn greeter_state_file_candidates() -> Vec<std::path::PathBuf> {
    let home = std::env::var_os("HOME").map(std::path::PathBuf::from).unwrap_or_else(|| std::path::PathBuf::from("/"));
    vec![
        std::path::PathBuf::from("/var/cache/astra-airlock/greeter.json"),
        std::path::PathBuf::from("/var/lib/astra-airlock/greeter.json"),
        home.join(".config/caelestia/greeter.json"),
        home.join(".cache/astra-airlock/greeter.json"),
        std::env::temp_dir().join("astra-airlock.json"),
    ]
}

/// Airlock's own remembered last session for `user` (saved via
/// `GreeterState.saveSession`), checked before the AccountsService fallback
/// below — matches the original C++ GreeterState::getLastSession, which
/// checked its own `userSessions` map first and AccountsService second.
fn saved_session_for_user(user: &str) -> Option<String> {
    if user.is_empty() {
        return None;
    }
    for path in greeter_state_file_candidates() {
        let Ok(text) = fs::read_to_string(&path) else { continue };
        let Ok(doc) = serde_json::from_str::<serde_json::Value>(&text) else { continue };
        if let Some(sess) = doc.get("userSessions").and_then(|m| m.get(user)).and_then(|v| v.as_str()) {
            if !sess.is_empty() {
                return Some(sess.to_string());
            }
        }
    }
    None
}

fn last_session_for_user(user: &str) -> String {
    if user.is_empty() {
        return String::new();
    }
    if let Some(saved) = saved_session_for_user(user) {
        return saved;
    }
    let acc_path = format!("/var/lib/AccountsService/users/{user}");
    if let Ok(text) = fs::read_to_string(&acc_path) {
        for line in text.lines() {
            let line = line.trim();
            if let Some(v) = line.strip_prefix("Session=") {
                if !v.trim().is_empty() {
                    return v.trim().to_string();
                }
            }
        }
        for line in text.lines() {
            let line = line.trim();
            if let Some(v) = line.strip_prefix("XSession=") {
                if !v.trim().is_empty() {
                    return v.trim().to_string();
                }
            }
        }
    }
    String::new()
}

impl cxx_qt::Initialize for ffi::SessionDiscovery {
    fn initialize(self: Pin<&mut Self>) {
        self.reload();
    }
}

impl ffi::SessionDiscovery {
    fn index_of_session_str(&self, session_key: &str) -> i32 {
        if session_key.is_empty() {
            return -1;
        }
        let clean = session_key.to_lowercase().replace(".desktop", "");
        let clean = clean.trim();

        for (i, s) in self.sessions.iter().enumerate() {
            let f = s.file.to_lowercase().replace(".desktop", "");
            if s.key == clean || f == clean || s.name.to_lowercase() == clean || s.exec.to_lowercase() == clean {
                return i as i32;
            }
        }
        for (i, s) in self.sessions.iter().enumerate() {
            let f = s.file.to_lowercase().replace(".desktop", "");
            if s.key.starts_with(clean) || f.starts_with(clean) || s.name.to_lowercase().contains(clean) {
                return i as i32;
            }
        }
        -1
    }

    pub fn index_of_session(&self, session_key: QString) -> i32 {
        self.index_of_session_str(&session_key.to_string())
    }

    pub fn session_index_for_user(&self, username: QString) -> i32 {
        let user = username.to_string();
        if user.is_empty() {
            return self.default_index;
        }
        let last = last_session_for_user(&user);
        if !last.is_empty() {
            let idx = self.index_of_session_str(&last);
            if idx >= 0 {
                return idx;
            }
        }
        self.default_index
    }

    pub fn save_last_session(self: Pin<&mut Self>, username: QString, session_key: QString) {
        // Persistence now lives in GreeterState; QML calls GreeterState.saveSession
        // directly, this invokable only exists to mirror the original API shape.
        let _ = (username, session_key);
        let _ = self;
    }

    pub fn set_last_user_hint(mut self: Pin<&mut Self>, last_user: QString) {
        self.as_mut().rust_mut().last_user_hint = last_user.to_string();
        self.update_default_index();
    }

    pub fn reload(mut self: Pin<&mut Self>) {
        let mut sessions = Vec::new();
        parse_directory("/usr/share/wayland-sessions", "Wayland", &mut sessions);
        parse_directory("/usr/share/xsessions", "X11", &mut sessions);

        if sessions.is_empty() {
            sessions.push(SessionEntry {
                name: "Hyprland".to_string(),
                exec: "Hyprland".to_string(),
                session_type: "Wayland".to_string(),
                file: "hyprland.desktop".to_string(),
                key: "hyprland".to_string(),
            });
        }

        let json = sessions_to_json(&sessions);
        {
            let mut rust = self.as_mut().rust_mut();
            rust.sessions = sessions;
            rust.sessions_json = json;
            rust.default_index = 0;
        }
        self.as_mut().sessions_json_changed();
        self.as_mut().update_default_index();
    }

    pub fn update_default_index(mut self: Pin<&mut Self>) {
        if self.sessions.is_empty() {
            return;
        }

        let last_key = last_session_for_user(&self.last_user_hint);
        let mut target = -1;
        if !last_key.is_empty() {
            target = self.index_of_session_str(&last_key);
        }

        if target < 0 {
            let mut hypr_idx = -1i32;
            let mut wayland_idx = -1i32;
            for (i, s) in self.sessions.iter().enumerate() {
                if s.key.contains("hyprland") && hypr_idx == -1 {
                    hypr_idx = i as i32;
                }
                if s.session_type == "Wayland" && wayland_idx == -1 {
                    wayland_idx = i as i32;
                }
            }
            target = if hypr_idx != -1 { hypr_idx } else if wayland_idx != -1 { wayland_idx } else { 0 };
        }

        if self.default_index != target {
            self.as_mut().rust_mut().default_index = target;
            self.as_mut().default_index_changed();
        }
    }
}

