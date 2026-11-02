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
        #[qproperty(QString, schemes_json, READ, NOTIFY = schemes_json_changed, cxx_name = "schemesJson")]
        #[qproperty(QString, active_user, READ, WRITE = set_active_user, NOTIFY = active_user_changed, cxx_name = "activeUser")]
        type SchemeDiscovery = super::SchemeDiscoveryRust;

        #[qsignal]
        #[cxx_name = "schemesJsonChanged"]
        fn schemes_json_changed(self: Pin<&mut SchemeDiscovery>);
        #[qsignal]
        #[cxx_name = "activeUserChanged"]
        fn active_user_changed(self: Pin<&mut SchemeDiscovery>);

        #[qinvokable]
        fn reload(self: Pin<&mut SchemeDiscovery>);

        #[qinvokable]
        #[cxx_name = "hasDynamicScheme"]
        fn has_dynamic_scheme(self: &SchemeDiscovery, user: QString) -> bool;

        /// Returns a JSON object of colour-name -> "#rrggbb", or "{}" if not found.
        #[qinvokable]
        #[cxx_name = "getSchemeColours"]
        fn get_scheme_colours(self: &SchemeDiscovery, name: QString, flavour: QString, mode: QString) -> QString;
    }

    extern "RustQt" {
        #[cxx_name = "setActiveUser"]
        fn set_active_user(self: Pin<&mut SchemeDiscovery>, value: QString);
    }

    impl cxx_qt::Constructor<()> for SchemeDiscovery {}
}

use cxx_qt::CxxQtType;
use cxx_qt_lib::QString;
use serde_json::{json, Map, Value};
use std::fs;
use std::path::{Path, PathBuf};
use std::pin::Pin;

pub struct SchemeDiscoveryRust {
    schemes_json: QString,
    active_user: QString,
}

impl Default for SchemeDiscoveryRust {
    fn default() -> Self {
        Self {
            schemes_json: QString::from("[]"),
            active_user: QString::default(),
        }
    }
}

fn scheme_search_paths() -> Vec<PathBuf> {
    let mut paths = Vec::new();
    if let Ok(entries) = fs::read_dir("/usr/lib") {
        for entry in entries.flatten() {
            let name = entry.file_name().to_string_lossy().to_string();
            if name.starts_with("python3") {
                paths.push(entry.path().join("site-packages/caelestia/data/schemes"));
            }
        }
    }
    paths.push(PathBuf::from("/usr/share/caelestia/schemes"));
    paths.push(PathBuf::from("/usr/local/share/caelestia/schemes"));
    paths.push(PathBuf::from("/var/cache/astra-airlock/schemes"));
    paths
}

/// KiiteShell's own generated-palette file: a flat, snake_case JSON object
/// (see kiiteshell-theme/src/wallpaper.rs: sync_desktop_color_scheme()).
fn kiite_generated_colours_path() -> Option<PathBuf> {
    let home = std::env::var_os("HOME").map(PathBuf::from)?;
    Some(home.join(".local/state/kiite/user/generated/colors.json"))
}

fn snake_to_m3_camel(key: &str) -> String {
    let mut out = String::with_capacity(key.len() + 2);
    out.push('m');
    let mut cap_next = true;
    for ch in key.chars() {
        if ch == '_' {
            cap_next = true;
            continue;
        }
        if cap_next {
            out.extend(ch.to_uppercase());
            cap_next = false;
        } else {
            out.push(ch);
        }
    }
    out
}

/// KiiteShell colours only apply as the "kiite" scheme name, any mode/flavour.
fn kiite_scheme_colours() -> Option<Map<String, Value>> {
    let path = kiite_generated_colours_path()?;
    let text = fs::read_to_string(path).ok()?;
    let raw: Map<String, Value> = serde_json::from_str(&text).ok()?;

    let mut out = Map::new();
    for (k, v) in raw {
        let Some(hex) = v.as_str() else { continue };
        let hex = hex.trim_start_matches('#');
        out.insert(snake_to_m3_camel(&k), json!(format!("#{hex}")));
    }
    if out.is_empty() {
        None
    } else {
        Some(out)
    }
}

fn normalize_colour_map(mut map: Map<String, Value>) -> Map<String, Value> {
    for (_, v) in map.iter_mut() {
        if let Some(s) = v.as_str() {
            if !s.starts_with('#') {
                *v = json!(format!("#{s}"));
            }
        }
    }
    map
}

fn read_colours_from_dir(dir: &Path, mode: &str) -> Option<Map<String, Value>> {
    let txt_path = dir.join(format!("{mode}.txt"));
    let json_path = dir.join(format!("{mode}.json"));

    if txt_path.exists() {
        if let Ok(text) = fs::read_to_string(&txt_path) {
            let mut map = Map::new();
            for line in text.lines() {
                let line = line.trim();
                if line.is_empty() || line.starts_with('#') {
                    continue;
                }
                if let Some(idx) = line.find(' ') {
                    let k = line[..idx].trim().to_string();
                    let mut v = line[idx + 1..].trim().to_string();
                    if !v.starts_with('#') {
                        v = format!("#{v}");
                    }
                    map.insert(k, json!(v));
                }
            }
            if !map.is_empty() {
                return Some(map);
            }
        }
    }

    if json_path.exists() {
        if let Ok(text) = fs::read_to_string(&json_path) {
            if let Ok(doc) = serde_json::from_str::<Value>(&text) {
                let obj = doc.get("colours").cloned().unwrap_or(doc);
                if let Value::Object(map) = obj {
                    let map = normalize_colour_map(map);
                    if !map.is_empty() {
                        return Some(map);
                    }
                }
            }
        }
    }

    None
}

fn get_scheme_colours_impl(name: &str, flavour: &str, mode: &str) -> Map<String, Value> {
    if name.eq_ignore_ascii_case("kiite") {
        return kiite_scheme_colours().unwrap_or_default();
    }

    let mode = if mode.is_empty() { "dark" } else { mode };
    let is_dynamic = name.eq_ignore_ascii_case("dynamic");

    for base in scheme_search_paths() {
        let mut candidates: Vec<PathBuf> = Vec::new();
        if !flavour.is_empty() {
            candidates.push(base.join(name).join(flavour));
        }
        if is_dynamic && (flavour.is_empty() || flavour == "default") {
            let dyn_dir = base.join("dynamic");
            if let Ok(entries) = fs::read_dir(&dyn_dir) {
                for entry in entries.flatten() {
                    if entry.path().is_dir() {
                        candidates.push(entry.path());
                    }
                }
            }
        }

        for dir in candidates {
            if let Some(colours) = read_colours_from_dir(&dir, mode) {
                return colours;
            }
        }
    }

    if is_dynamic {
        return get_scheme_colours_impl("caelestia", "default", mode);
    }

    Map::new()
}

fn has_dynamic_scheme_impl(user: &str) -> bool {
    if user.is_empty() {
        return false;
    }
    for base in scheme_search_paths() {
        let dir = base.join("dynamic").join(user);
        if dir.join("dark.json").exists() || dir.join("light.json").exists()
            || dir.join("dark.txt").exists() || dir.join("light.txt").exists() {
            return true;
        }
    }
    false
}

fn discover_schemes(active_user: &str) -> Vec<Value> {
    let mut out = Vec::new();
    let mut seen = std::collections::HashSet::new();

    for base in scheme_search_paths() {
        let Ok(scheme_dirs) = fs::read_dir(&base) else { continue };
        for scheme_entry in scheme_dirs.flatten() {
            if !scheme_entry.path().is_dir() {
                continue;
            }
            let scheme_name = scheme_entry.file_name().to_string_lossy().to_string();
            let is_dynamic = scheme_name.eq_ignore_ascii_case("dynamic");

            if is_dynamic {
                if !active_user.is_empty() && !has_dynamic_scheme_impl(active_user) {
                    continue;
                }
            }

            let Ok(flavour_dirs) = fs::read_dir(scheme_entry.path()) else { continue };
            for flavour_entry in flavour_dirs.flatten() {
                if !flavour_entry.path().is_dir() {
                    continue;
                }
                let flavour_name = flavour_entry.file_name().to_string_lossy().to_string();
                let key = if is_dynamic { "dynamic:default".to_string() } else { format!("{scheme_name}:{flavour_name}") };
                if seen.contains(&key) {
                    continue;
                }

                let target_flavour = if is_dynamic {
                    if !active_user.is_empty() { active_user.to_string() } else { flavour_name.clone() }
                } else {
                    flavour_name.clone()
                };

                let mut colours = get_scheme_colours_impl(&scheme_name, &target_flavour, "dark");
                if colours.is_empty() {
                    colours = get_scheme_colours_impl(&scheme_name, &target_flavour, "light");
                }
                if colours.is_empty() {
                    continue;
                }
                seen.insert(key);

                let display_name = if is_dynamic {
                    "Dynamic".to_string()
                } else {
                    let mut c = scheme_name.chars();
                    match c.next() {
                        Some(f) => f.to_uppercase().collect::<String>() + c.as_str(),
                        None => scheme_name.clone(),
                    }
                };

                out.push(json!({
                    "name": if is_dynamic { "dynamic" } else { &scheme_name },
                    "flavour": if is_dynamic { "default" } else { &flavour_name },
                    "displayName": display_name,
                    "colours": colours,
                }));
            }
        }
    }

    // KiiteShell's own generated palette, if present, is listed as the "kiite" scheme.
    if let Some(colours) = kiite_scheme_colours() {
        out.push(json!({
            "name": "kiite",
            "flavour": "default",
            "displayName": "Kiite",
            "colours": colours,
        }));
    }

    out.sort_by(|a, b| {
        let ka = format!("{}{}", a["name"].as_str().unwrap_or(""), a["flavour"].as_str().unwrap_or(""));
        let kb = format!("{}{}", b["name"].as_str().unwrap_or(""), b["flavour"].as_str().unwrap_or(""));
        ka.cmp(&kb)
    });

    out
}

impl cxx_qt::Initialize for ffi::SchemeDiscovery {
    fn initialize(self: Pin<&mut Self>) {
        self.reload();
    }
}

impl ffi::SchemeDiscovery {
    pub fn reload(mut self: Pin<&mut Self>) {
        let active_user = self.active_user.to_string();
        let schemes = discover_schemes(&active_user);
        let json = QString::from(serde_json::to_string(&schemes).unwrap_or_else(|_| "[]".to_string()).as_str());
        self.as_mut().rust_mut().schemes_json = json;
        self.as_mut().schemes_json_changed();
    }

    pub fn set_active_user(mut self: Pin<&mut Self>, value: QString) {
        if self.active_user == value {
            return;
        }
        self.as_mut().rust_mut().active_user = value;
        self.as_mut().active_user_changed();
        self.as_mut().reload();
    }

    pub fn has_dynamic_scheme(&self, user: QString) -> bool {
        has_dynamic_scheme_impl(&user.to_string())
    }

    pub fn get_scheme_colours(&self, name: QString, flavour: QString, mode: QString) -> QString {
        let colours = get_scheme_colours_impl(&name.to_string(), &flavour.to_string(), &mode.to_string());
        QString::from(serde_json::to_string(&colours).unwrap_or_else(|_| "{}".to_string()).as_str())
    }
}
