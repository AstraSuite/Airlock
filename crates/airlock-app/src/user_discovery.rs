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
        #[qproperty(QString, users_json, READ, NOTIFY = users_changed, cxx_name = "usersJson")]
        #[qproperty(i32, default_index, READ, NOTIFY = default_index_changed, cxx_name = "defaultIndex")]
        #[qproperty(QString, current_user, READ, NOTIFY = current_user_changed, cxx_name = "currentUser")]
        type UserDiscovery = super::UserDiscoveryRust;

        #[qsignal]
        #[cxx_name = "usersChanged"]
        fn users_changed(self: Pin<&mut UserDiscovery>);
        #[qsignal]
        #[cxx_name = "defaultIndexChanged"]
        fn default_index_changed(self: Pin<&mut UserDiscovery>);
        #[qsignal]
        #[cxx_name = "currentUserChanged"]
        fn current_user_changed(self: Pin<&mut UserDiscovery>);

        #[qinvokable]
        fn reload(self: Pin<&mut UserDiscovery>);

        #[qinvokable]
        #[cxx_name = "updateDefaultIndex"]
        fn update_default_index(self: Pin<&mut UserDiscovery>);

        /// Called by QML (Connections on GreeterState.lastUserChanged) since Rust
        /// QObjects can't directly observe each other's signals across bridges.
        #[qinvokable]
        #[cxx_name = "setLastUserHint"]
        fn set_last_user_hint(self: Pin<&mut UserDiscovery>, last_user: QString);
    }

    impl cxx_qt::Constructor<()> for UserDiscovery {}
}

use cxx_qt::CxxQtType;
use cxx_qt_lib::QString;
use serde_json::json;
use std::fs;
use std::path::Path;
use std::pin::Pin;

pub struct UserEntry {
    pub username: String,
    pub real_name: String,
    pub home_dir: String,
    pub avatar: String,
}

pub struct UserDiscoveryRust {
    users: Vec<UserEntry>,
    users_json: QString,
    default_index: i32,
    current_user: QString,
    last_user_hint: String,
}

impl Default for UserDiscoveryRust {
    fn default() -> Self {
        Self {
            users: Vec::new(),
            users_json: QString::from("[]"),
            default_index: 0,
            current_user: QString::default(),
            last_user_hint: String::new(),
        }
    }
}

fn env_user() -> String {
    std::env::var("USER").unwrap_or_default()
}

fn resolve_avatar(username: &str, home_dir: &str) -> String {
    let cache_avatar = format!("/var/cache/astra-airlock/avatars/{username}");
    if Path::new(&cache_avatar).exists() {
        return format!("file://{cache_avatar}");
    }
    for base in [format!("/home/{username}"), home_dir.to_string()] {
        for name in [".face", ".face.icon"] {
            let p = format!("{base}/{name}");
            if Path::new(&p).exists() {
                return format!("file://{p}");
            }
        }
    }
    let accounts_icon = format!("/var/lib/AccountsService/icons/{username}");
    if Path::new(&accounts_icon).exists() {
        return format!("file:///var/lib/AccountsService/icons/{username}");
    }
    String::new()
}

fn parse_passwd() -> Vec<UserEntry> {
    let mut users = Vec::new();
    let Ok(text) = fs::read_to_string("/etc/passwd") else { return users };
    for line in text.lines() {
        let line = line.trim();
        if line.is_empty() || line.starts_with('#') {
            continue;
        }
        let parts: Vec<&str> = line.split(':').collect();
        if parts.len() < 7 {
            continue;
        }
        let username = parts[0];
        let uid: i64 = parts[2].parse().unwrap_or(-1);
        let gecos = parts[4];
        let home_dir = parts[5];
        let shell = parts[6];

        if uid < 1000 || username == "nobody" || shell.contains("nologin") || shell.contains("false") {
            continue;
        }

        let real_name = gecos.split(',').next().unwrap_or("").trim();
        let real_name = if real_name.is_empty() { username } else { real_name };

        users.push(UserEntry {
            username: username.to_string(),
            real_name: real_name.to_string(),
            home_dir: home_dir.to_string(),
            avatar: resolve_avatar(username, home_dir),
        });
    }
    users
}

fn users_to_json(users: &[UserEntry]) -> QString {
    let arr: Vec<_> = users
        .iter()
        .map(|u| {
            json!({
                "username": u.username,
                "realName": u.real_name,
                "homeDir": u.home_dir,
                "avatar": u.avatar,
            })
        })
        .collect();
    QString::from(serde_json::to_string(&arr).unwrap_or_else(|_| "[]".to_string()).as_str())
}

impl cxx_qt::Initialize for ffi::UserDiscovery {
    fn initialize(self: Pin<&mut Self>) {
        self.reload();
    }
}

impl ffi::UserDiscovery {
    pub fn reload(mut self: Pin<&mut Self>) {
        let mut users = parse_passwd();
        if users.is_empty() {
            let fallback = {
                let e = env_user();
                if e.is_empty() { "user".to_string() } else { e }
            };
            users.push(UserEntry {
                username: fallback.clone(),
                real_name: fallback.clone(),
                home_dir: format!("/home/{fallback}"),
                avatar: String::new(),
            });
        }

        let json = users_to_json(&users);
        {
            let mut rust = self.as_mut().rust_mut();
            rust.users = users;
            rust.users_json = json;
            rust.default_index = 0;
        }
        self.as_mut().users_changed();
        self.as_mut().update_default_index();
    }

    pub fn set_last_user_hint(mut self: Pin<&mut Self>, last_user: QString) {
        self.as_mut().rust_mut().last_user_hint = last_user.to_string();
        self.update_default_index();
    }

    pub fn update_default_index(mut self: Pin<&mut Self>) {
        if self.users.is_empty() {
            return;
        }
        let last_user = self.last_user_hint.clone();
        let env = env_user();

        let mut target: i32 = -1;
        if !last_user.is_empty() {
            target = self.users.iter().position(|u| u.username == last_user).map(|i| i as i32).unwrap_or(-1);
        }
        if target == -1 && !env.is_empty() {
            target = self.users.iter().position(|u| u.username == env).map(|i| i as i32).unwrap_or(-1);
        }
        if target == -1 {
            target = 0;
        }

        if self.default_index != target {
            let username = self.users[target as usize].username.clone();
            let mut rust = self.as_mut().rust_mut();
            rust.default_index = target;
            rust.current_user = QString::from(username.as_str());
            self.as_mut().default_index_changed();
            self.as_mut().current_user_changed();
        }
    }
}
