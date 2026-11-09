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
        #[qproperty(bool, use12_hour, READ, WRITE = set_use12_hour, NOTIFY = use12_hour_changed, cxx_name = "use12Hour")]
        #[qproperty(bool, wallpaper_enabled, READ, WRITE = set_wallpaper_enabled, NOTIFY = wallpaper_enabled_changed, cxx_name = "wallpaperEnabled")]
        #[qproperty(i32, avatar_shape, READ, WRITE = set_avatar_shape, NOTIFY = avatar_shape_changed, cxx_name = "avatarShape")]
        #[qproperty(QString, avatar_shape_name, READ, WRITE = set_avatar_shape_name, NOTIFY = avatar_shape_name_changed, cxx_name = "avatarShapeName")]
        #[qproperty(bool, lava_lamp_enabled, READ, WRITE = set_lava_lamp_enabled, NOTIFY = lava_lamp_enabled_changed, cxx_name = "lavaLampEnabled")]
        #[qproperty(bool, skip_clock_page, READ, WRITE = set_skip_clock_page, NOTIFY = skip_clock_page_changed, cxx_name = "skipClockPage")]
        #[qproperty(bool, locklike_enabled, READ, WRITE = set_locklike_enabled, NOTIFY = locklike_enabled_changed, cxx_name = "locklikeEnabled")]
        #[qproperty(QString, last_user, READ, WRITE = set_last_user, NOTIFY = last_user_changed, cxx_name = "lastUser")]
        #[qproperty(QString, scheme_name, READ, WRITE = set_scheme_name, NOTIFY = scheme_name_changed, cxx_name = "schemeName")]
        #[qproperty(QString, scheme_flavour, READ, WRITE = set_scheme_flavour, NOTIFY = scheme_flavour_changed, cxx_name = "schemeFlavour")]
        #[qproperty(QString, scheme_mode, READ, WRITE = set_scheme_mode, NOTIFY = scheme_mode_changed, cxx_name = "schemeMode")]
        #[qproperty(QString, state_file_path, READ, CONSTANT, cxx_name = "stateFilePath")]
        type GreeterState = super::GreeterStateRust;

        #[qsignal]
        #[cxx_name = "activeUserChanged"]
        fn active_user_changed(self: Pin<&mut GreeterState>);
        #[qsignal]
        #[cxx_name = "use12HourChanged"]
        fn use12_hour_changed(self: Pin<&mut GreeterState>);
        #[qsignal]
        #[cxx_name = "wallpaperEnabledChanged"]
        fn wallpaper_enabled_changed(self: Pin<&mut GreeterState>);
        #[qsignal]
        #[cxx_name = "avatarShapeChanged"]
        fn avatar_shape_changed(self: Pin<&mut GreeterState>);
        #[qsignal]
        #[cxx_name = "avatarShapeNameChanged"]
        fn avatar_shape_name_changed(self: Pin<&mut GreeterState>);
        #[qsignal]
        #[cxx_name = "lavaLampEnabledChanged"]
        fn lava_lamp_enabled_changed(self: Pin<&mut GreeterState>);
        #[qsignal]
        #[cxx_name = "skipClockPageChanged"]
        fn skip_clock_page_changed(self: Pin<&mut GreeterState>);
        #[qsignal]
        #[cxx_name = "locklikeEnabledChanged"]
        fn locklike_enabled_changed(self: Pin<&mut GreeterState>);
        #[qsignal]
        #[cxx_name = "lastUserChanged"]
        fn last_user_changed(self: Pin<&mut GreeterState>);
        #[qsignal]
        #[cxx_name = "schemeNameChanged"]
        fn scheme_name_changed(self: Pin<&mut GreeterState>);
        #[qsignal]
        #[cxx_name = "schemeFlavourChanged"]
        fn scheme_flavour_changed(self: Pin<&mut GreeterState>);
        #[qsignal]
        #[cxx_name = "schemeModeChanged"]
        fn scheme_mode_changed(self: Pin<&mut GreeterState>);

        #[cxx_name = "setActiveUser"]
        fn set_active_user(self: Pin<&mut GreeterState>, value: QString);
        #[cxx_name = "setUse12Hour"]
        fn set_use12_hour(self: Pin<&mut GreeterState>, value: bool);
        #[cxx_name = "setWallpaperEnabled"]
        fn set_wallpaper_enabled(self: Pin<&mut GreeterState>, value: bool);
        #[cxx_name = "setAvatarShape"]
        fn set_avatar_shape(self: Pin<&mut GreeterState>, value: i32);
        #[cxx_name = "setAvatarShapeName"]
        fn set_avatar_shape_name(self: Pin<&mut GreeterState>, value: QString);
        #[cxx_name = "setLavaLampEnabled"]
        fn set_lava_lamp_enabled(self: Pin<&mut GreeterState>, value: bool);
        #[cxx_name = "setSkipClockPage"]
        fn set_skip_clock_page(self: Pin<&mut GreeterState>, value: bool);
        #[cxx_name = "setLocklikeEnabled"]
        fn set_locklike_enabled(self: Pin<&mut GreeterState>, value: bool);
        #[cxx_name = "setLastUser"]
        fn set_last_user(self: Pin<&mut GreeterState>, value: QString);
        #[cxx_name = "setSchemeName"]
        fn set_scheme_name(self: Pin<&mut GreeterState>, value: QString);
        #[cxx_name = "setSchemeFlavour"]
        fn set_scheme_flavour(self: Pin<&mut GreeterState>, value: QString);
        #[cxx_name = "setSchemeMode"]
        fn set_scheme_mode(self: Pin<&mut GreeterState>, value: QString);

        #[qinvokable]
        #[cxx_name = "setScheme"]
        fn set_scheme(self: Pin<&mut GreeterState>, name: QString, flavour: QString, mode: QString);

        #[qinvokable]
        fn save(self: Pin<&mut GreeterState>);

        #[qinvokable]
        fn reload(self: Pin<&mut GreeterState>);

        #[qinvokable]
        #[cxx_name = "getLastSession"]
        fn get_last_session(self: &GreeterState, username: QString) -> QString;

        #[qinvokable]
        #[cxx_name = "saveSession"]
        fn save_session(self: Pin<&mut GreeterState>, username: QString, session_key: QString);
    }

    impl cxx_qt::Constructor<()> for GreeterState {}
}

use cxx_qt::CxxQtType;
use cxx_qt_lib::QString;
use serde_json::{json, Value};
use std::fs;
use std::path::PathBuf;
use std::pin::Pin;

fn candidate_paths() -> Vec<PathBuf> {
    let home = dirs_home();
    vec![
        PathBuf::from("/var/cache/astra-airlock/greeter.json"),
        PathBuf::from("/var/lib/astra-airlock/greeter.json"),
        home.join(".config/caelestia/greeter.json"),
        home.join(".cache/astra-airlock/greeter.json"),
        std::env::temp_dir().join("astra-airlock.json"),
    ]
}

fn dirs_home() -> PathBuf {
    std::env::var_os("HOME")
        .map(PathBuf::from)
        .unwrap_or_else(|| PathBuf::from("/"))
}

/// Whether *this process* (not just the file's owner) can actually write
/// into `dir`. `Permissions::readonly()` only reflects the owner's write
/// bit, which says nothing about our own effective access (e.g. a
/// root-owned, mode-755 directory reports "writable" even though a
/// non-root process like the `greeter` user plainly cannot write into
/// it) — so this probes with a real, immediately-removed temp file instead.
fn dir_is_writable(dir: &std::path::Path) -> bool {
    let probe = dir.join(format!(".airlock-write-test-{}", std::process::id()));
    match fs::File::create(&probe) {
        Ok(_) => {
            let _ = fs::remove_file(&probe);
            true
        }
        Err(_) => false,
    }
}

fn compute_state_file_path() -> PathBuf {
    // 1. An existing, writable file.
    for p in candidate_paths() {
        if p.exists() {
            if let Some(dir) = p.parent() {
                if dir_is_writable(dir) {
                    return p;
                }
            }
        }
    }
    // 2. A writable (or creatable) parent directory.
    for p in candidate_paths() {
        if let Some(dir) = p.parent() {
            if dir.exists() {
                if dir_is_writable(dir) {
                    return p;
                }
            } else if fs::create_dir_all(dir).is_ok() && dir_is_writable(dir) {
                return p;
            }
        }
    }
    // 3. Any existing file, read-only environment.
    for p in candidate_paths() {
        if p.exists() {
            return p;
        }
    }
    std::env::temp_dir().join("astra-airlock.json")
}

fn has_dynamic_scheme(user: &str) -> bool {
    if user.is_empty() {
        return false;
    }
    for base in ["/var/cache/astra-airlock/schemes", "/usr/share/caelestia/schemes"] {
        let p = PathBuf::from(base).join("dynamic").join(user);
        if p.join("dark.json").exists() || p.join("light.json").exists() {
            return true;
        }
    }
    false
}

pub struct GreeterStateRust {
    active_user: QString,
    use12_hour: bool,
    wallpaper_enabled: bool,
    avatar_shape: i32,
    avatar_shape_name: QString,
    lava_lamp_enabled: bool,
    skip_clock_page: bool,
    locklike_enabled: bool,
    last_user: QString,
    scheme_name: QString,
    scheme_flavour: QString,
    scheme_mode: QString,
    state_file_path: QString,
    user_sessions: Value,
    user_settings: Value,
}

impl Default for GreeterStateRust {
    fn default() -> Self {
        Self {
            active_user: QString::default(),
            use12_hour: false,
            wallpaper_enabled: true,
            avatar_shape: 19,
            avatar_shape_name: QString::from("Cookie 9-Sided"),
            lava_lamp_enabled: true,
            skip_clock_page: false,
            locklike_enabled: false,
            last_user: QString::default(),
            scheme_name: QString::from("caelestia"),
            scheme_flavour: QString::from("default"),
            scheme_mode: QString::from("dark"),
            state_file_path: QString::from(compute_state_file_path().to_string_lossy().as_ref()),
            user_sessions: json!({}),
            user_settings: json!({}),
        }
    }
}

impl cxx_qt::Initialize for ffi::GreeterState {
    fn initialize(self: Pin<&mut Self>) {
        self.load_from_disk();
    }
}

impl ffi::GreeterState {
    fn state_path(&self) -> PathBuf {
        PathBuf::from(self.state_file_path.to_string())
    }

    fn load_from_disk(mut self: Pin<&mut Self>) {
        let path = self.state_path();
        let Ok(text) = fs::read_to_string(&path) else { return };
        let Ok(root) = serde_json::from_str::<Value>(&text) else { return };

        let last_user = root.get("lastUser").and_then(Value::as_str).unwrap_or("").to_string();
        if !last_user.is_empty() {
            self.as_mut().rust_mut().last_user = QString::from(last_user.as_str());
        }
        if self.active_user.to_string().is_empty() && !self.last_user.to_string().is_empty() {
            let last = self.last_user.to_string();
            self.as_mut().rust_mut().active_user = QString::from(last.as_str());
        }
        if let Some(sessions) = root.get("userSessions") {
            self.as_mut().rust_mut().user_sessions = sessions.clone();
        }
        if let Some(settings) = root.get("userSettings") {
            self.as_mut().rust_mut().user_settings = settings.clone();
        }

        let s = root.get("settings").cloned().unwrap_or(root.clone());
        apply_settings_object(self.as_mut(), &s);

        let user_for_settings = {
            let active = self.active_user.to_string();
            if !active.is_empty() { active } else { self.last_user.to_string() }
        };
        if !user_for_settings.is_empty() {
            let found = self.user_settings.get(&user_for_settings).cloned();
            if let Some(u) = found {
                apply_settings_object(self.as_mut(), &u);
            }
        }

        let active = self.active_user.to_string();
        if !active.is_empty() && self.scheme_name.to_string().eq_ignore_ascii_case("dynamic") && !has_dynamic_scheme(&active) {
            self.as_mut().rust_mut().scheme_name = QString::from("caelestia");
            self.as_mut().rust_mut().scheme_flavour = QString::from("default");
        }

        self.as_mut().use12_hour_changed();
        self.as_mut().wallpaper_enabled_changed();
        self.as_mut().avatar_shape_changed();
        self.as_mut().avatar_shape_name_changed();
        self.as_mut().lava_lamp_enabled_changed();
        self.as_mut().skip_clock_page_changed();
        self.as_mut().locklike_enabled_changed();
        self.as_mut().last_user_changed();
        self.as_mut().scheme_name_changed();
        self.as_mut().scheme_flavour_changed();
        self.as_mut().scheme_mode_changed();
    }

    pub fn reload(self: Pin<&mut Self>) {
        self.load_from_disk();
    }

    fn current_settings_blob(&self) -> Value {
        json!({
            "use12Hour": self.use12_hour,
            "wallpaperEnabled": self.wallpaper_enabled,
            "avatarShape": self.avatar_shape,
            "avatarShapeName": self.avatar_shape_name.to_string(),
            "lavaLampEnabled": self.lava_lamp_enabled,
            "skipClockPage": self.skip_clock_page,
            "locklikeEnabled": self.locklike_enabled,
            "locklike": self.locklike_enabled,
            "schemeName": self.scheme_name.to_string(),
            "schemeFlavour": self.scheme_flavour.to_string(),
            "schemeMode": self.scheme_mode.to_string(),
        })
    }

    pub fn save(mut self: Pin<&mut Self>) {
        let active = self.active_user.to_string();
        if !active.is_empty() {
            let blob = self.current_settings_blob();
            if let Some(obj) = self.as_mut().rust_mut().user_settings.as_object_mut() {
                obj.insert(active, blob);
            }
        }

        let mut root = json!({
            "userSessions": self.user_sessions.clone(),
            "userSettings": self.user_settings.clone(),
        });
        let last_user = self.last_user.to_string();
        if !last_user.is_empty() {
            root["lastUser"] = json!(last_user);
        }

        let mut settings = self.current_settings_blob();
        settings["use12h"] = json!(self.use12_hour);

        root["settings"] = settings;

        let path = self.state_path();
        if let Some(dir) = path.parent() {
            let _ = fs::create_dir_all(dir);
        }
        if let Ok(text) = serde_json::to_string_pretty(&root) {
            if let Err(e) = fs::write(&path, text) {
                eprintln!("[astra-airlock] failed to save settings to {}: {e}", path.display());
            }
        }
    }

    pub fn set_active_user(mut self: Pin<&mut Self>, value: QString) {
        let user = value.to_string();
        if user.is_empty() || self.active_user.to_string() == user {
            return;
        }

        let prev = self.active_user.to_string();
        if !prev.is_empty() {
            let blob = self.current_settings_blob();
            if let Some(obj) = self.as_mut().rust_mut().user_settings.as_object_mut() {
                obj.insert(prev, blob);
            }
        }

        self.as_mut().rust_mut().active_user = QString::from(user.as_str());

        if let Some(u) = self.user_settings.get(&user).cloned() {
            apply_settings_object(self.as_mut(), &u);
        }

        if self.scheme_name.to_string().eq_ignore_ascii_case("dynamic") && !has_dynamic_scheme(&user) {
            self.as_mut().rust_mut().scheme_name = QString::from("caelestia");
            self.as_mut().rust_mut().scheme_flavour = QString::from("default");
        }

        if self.last_user.to_string() != user {
            self.as_mut().rust_mut().last_user = QString::from(user.as_str());
            self.as_mut().last_user_changed();
        }

        self.as_mut().active_user_changed();
        self.as_mut().use12_hour_changed();
        self.as_mut().wallpaper_enabled_changed();
        self.as_mut().avatar_shape_changed();
        self.as_mut().avatar_shape_name_changed();
        self.as_mut().lava_lamp_enabled_changed();
        self.as_mut().skip_clock_page_changed();
        self.as_mut().locklike_enabled_changed();
        self.as_mut().scheme_name_changed();
        self.as_mut().scheme_flavour_changed();
        self.as_mut().scheme_mode_changed();

        self.as_mut().save();
    }

    pub fn set_use12_hour(mut self: Pin<&mut Self>, value: bool) {
        if self.use12_hour == value { return; }
        self.as_mut().rust_mut().use12_hour = value;
        self.as_mut().use12_hour_changed();
        self.as_mut().save();
    }

    pub fn set_wallpaper_enabled(mut self: Pin<&mut Self>, value: bool) {
        if self.wallpaper_enabled == value { return; }
        self.as_mut().rust_mut().wallpaper_enabled = value;
        self.as_mut().wallpaper_enabled_changed();
        self.as_mut().save();
    }

    pub fn set_avatar_shape(mut self: Pin<&mut Self>, value: i32) {
        if self.avatar_shape == value { return; }
        self.as_mut().rust_mut().avatar_shape = value;
        self.as_mut().avatar_shape_changed();
        self.as_mut().save();
    }

    pub fn set_avatar_shape_name(mut self: Pin<&mut Self>, value: QString) {
        if self.avatar_shape_name == value { return; }
        self.as_mut().rust_mut().avatar_shape_name = value;
        self.as_mut().avatar_shape_name_changed();
        self.as_mut().save();
    }

    pub fn set_lava_lamp_enabled(mut self: Pin<&mut Self>, value: bool) {
        if self.lava_lamp_enabled == value { return; }
        self.as_mut().rust_mut().lava_lamp_enabled = value;
        self.as_mut().lava_lamp_enabled_changed();
        self.as_mut().save();
    }

    pub fn set_skip_clock_page(mut self: Pin<&mut Self>, value: bool) {
        if self.skip_clock_page == value { return; }
        self.as_mut().rust_mut().skip_clock_page = value;
        self.as_mut().skip_clock_page_changed();
        self.as_mut().save();
    }

    pub fn set_locklike_enabled(mut self: Pin<&mut Self>, value: bool) {
        if self.locklike_enabled == value { return; }
        self.as_mut().rust_mut().locklike_enabled = value;
        self.as_mut().locklike_enabled_changed();
        self.as_mut().save();
    }

    pub fn set_last_user(mut self: Pin<&mut Self>, value: QString) {
        if self.last_user == value { return; }
        self.as_mut().rust_mut().last_user = value;
        self.as_mut().last_user_changed();
        self.as_mut().save();
    }

    pub fn set_scheme_name(mut self: Pin<&mut Self>, value: QString) {
        if self.scheme_name == value { return; }
        self.as_mut().rust_mut().scheme_name = value;
        self.as_mut().scheme_name_changed();
        self.as_mut().save();
    }

    pub fn set_scheme_flavour(mut self: Pin<&mut Self>, value: QString) {
        if self.scheme_flavour == value { return; }
        self.as_mut().rust_mut().scheme_flavour = value;
        self.as_mut().scheme_flavour_changed();
        self.as_mut().save();
    }

    pub fn set_scheme_mode(mut self: Pin<&mut Self>, value: QString) {
        if self.scheme_mode == value { return; }
        self.as_mut().rust_mut().scheme_mode = value;
        self.as_mut().scheme_mode_changed();
        self.as_mut().save();
    }

    pub fn set_scheme(mut self: Pin<&mut Self>, name: QString, flavour: QString, mode: QString) {
        let mut changed = false;
        if !name.to_string().is_empty() && self.scheme_name != name {
            self.as_mut().rust_mut().scheme_name = name;
            self.as_mut().scheme_name_changed();
            changed = true;
        }
        if !flavour.to_string().is_empty() && self.scheme_flavour != flavour {
            self.as_mut().rust_mut().scheme_flavour = flavour;
            self.as_mut().scheme_flavour_changed();
            changed = true;
        }
        if !mode.to_string().is_empty() && self.scheme_mode != mode {
            self.as_mut().rust_mut().scheme_mode = mode;
            self.as_mut().scheme_mode_changed();
            changed = true;
        }
        if changed {
            self.as_mut().save();
        }
    }

    pub fn get_last_session(&self, username: QString) -> QString {
        let user = {
            let u = username.to_string();
            if u.is_empty() { self.last_user.to_string() } else { u }
        };
        if user.is_empty() {
            return QString::default();
        }
        if let Some(sess) = self.user_sessions.get(&user).and_then(Value::as_str) {
            if !sess.is_empty() {
                return QString::from(sess);
            }
        }
        // Fall back to AccountsService's per-user ini file.
        let acc_path = PathBuf::from("/var/lib/AccountsService/users").join(&user);
        if let Ok(text) = fs::read_to_string(&acc_path) {
            let mut session = String::new();
            let mut xsession = String::new();
            for line in text.lines() {
                let line = line.trim();
                if let Some(v) = line.strip_prefix("Session=") {
                    session = v.trim().to_string();
                } else if let Some(v) = line.strip_prefix("XSession=") {
                    xsession = v.trim().to_string();
                }
            }
            if !session.is_empty() {
                return QString::from(session.as_str());
            }
            if !xsession.is_empty() {
                return QString::from(xsession.as_str());
            }
        }
        QString::default()
    }

    pub fn save_session(mut self: Pin<&mut Self>, username: QString, session_key: QString) {
        let user = username.to_string();
        let key = session_key.to_string();
        if user.is_empty() || key.is_empty() {
            return;
        }
        let mut changed = false;
        if self.last_user.to_string() != user {
            self.as_mut().rust_mut().last_user = QString::from(user.as_str());
            self.as_mut().last_user_changed();
            changed = true;
        }
        let current = self.user_sessions.get(&user).and_then(Value::as_str).unwrap_or("");
        if current != key {
            if let Some(obj) = self.as_mut().rust_mut().user_sessions.as_object_mut() {
                obj.insert(user, json!(key));
            }
            changed = true;
        }
        if changed {
            self.as_mut().save();
        }
    }
}

fn apply_settings_object(mut state: Pin<&mut ffi::GreeterState>, s: &Value) {
    if let Some(v) = s.get("use12Hour").and_then(Value::as_bool).or_else(|| s.get("use12h").and_then(Value::as_bool)) {
        state.as_mut().rust_mut().use12_hour = v;
    }
    if let Some(v) = s.get("wallpaperEnabled").and_then(Value::as_bool).or_else(|| s.get("wallpaper").and_then(Value::as_bool)) {
        state.as_mut().rust_mut().wallpaper_enabled = v;
    }
    if let Some(v) = s.get("avatarShape").and_then(Value::as_i64) {
        state.as_mut().rust_mut().avatar_shape = v as i32;
    }
    if let Some(v) = s.get("avatarShapeName").and_then(Value::as_str) {
        state.as_mut().rust_mut().avatar_shape_name = QString::from(v);
    }
    if let Some(v) = s.get("lavaLampEnabled").and_then(Value::as_bool) {
        state.as_mut().rust_mut().lava_lamp_enabled = v;
    }
    if let Some(v) = s.get("skipClockPage").and_then(Value::as_bool) {
        state.as_mut().rust_mut().skip_clock_page = v;
    }
    if let Some(v) = s.get("locklikeEnabled").and_then(Value::as_bool).or_else(|| s.get("locklike").and_then(Value::as_bool)) {
        state.as_mut().rust_mut().locklike_enabled = v;
    }
    if let Some(v) = s.get("schemeName").and_then(Value::as_str) {
        state.as_mut().rust_mut().scheme_name = QString::from(v);
    }
    if let Some(v) = s.get("schemeFlavour").and_then(Value::as_str).or_else(|| s.get("flavour").and_then(Value::as_str)) {
        state.as_mut().rust_mut().scheme_flavour = QString::from(v);
    }
    if let Some(v) = s.get("schemeMode").and_then(Value::as_str).or_else(|| s.get("mode").and_then(Value::as_str)) {
        state.as_mut().rust_mut().scheme_mode = QString::from(v);
    }
}
