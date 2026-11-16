//! KiiteShell's on-disk state, as Airlock reads it: its generated palette
//! and its `appearance` (whether its theme is TTY, and its monospace and Nerd
//! icon faces).
//!
//! The greeter runs as the `greeter` user with HOME=/, and can't read a
//! user's 700 home directory, so `--sync` copies both into
//! /var/cache/astra-airlock/kiite/<user>/; that copy is tried first, then the
//! process's own HOME (test runs), then /home/<user>.

use serde_json::Value;
use std::collections::HashMap;
use std::fs;
use std::path::PathBuf;
use std::sync::OnceLock;

pub const SYNC_DIR: &str = "/var/cache/astra-airlock/kiite";

/// Where KiiteShell keeps each file, relative to a home directory.
pub const COLOURS_REL: &str = ".local/state/kiite/user/generated/colors.json";
pub const CONFIG_REL: &str = ".config/kiite/config.json";

/// The names the synced copies are stored under in SYNC_DIR/<user>/.
pub const COLOURS_SYNCED: &str = "colors.json";
pub const APPEARANCE_SYNCED: &str = "appearance.json";

fn candidates(user: &str, synced: &str, home_rel: &str) -> Vec<PathBuf> {
    let mut out = Vec::new();
    if !user.is_empty() {
        out.push(PathBuf::from(SYNC_DIR).join(user).join(synced));
    }
    if let Some(home) = std::env::var_os("HOME").filter(|h| !h.is_empty() && h != "/") {
        out.push(PathBuf::from(home).join(home_rel));
    }
    if !user.is_empty() {
        out.push(PathBuf::from("/home").join(user).join(home_rel));
    }
    out
}

fn read_first(user: &str, synced: &str, home_rel: &str) -> Option<String> {
    candidates(user, synced, home_rel).into_iter().find_map(|p| fs::read_to_string(p).ok())
}

/// KiiteShell's generated palette for `user`: a flat object of snake_case
/// roles to "#rrggbb".
pub fn colours(user: &str) -> Option<serde_json::Map<String, Value>> {
    let text = read_first(user, COLOURS_SYNCED, COLOURS_REL)?;
    match serde_json::from_str(&text).ok()? {
        Value::Object(map) if !map.is_empty() => Some(map),
        _ => None,
    }
}

pub struct Appearance {
    pub tty: bool,
    pub mono: String,
    pub icon_nerd: String,
}

/// `user`'s KiiteShell `appearance`. The synced copy holds only that object
/// (under the same "appearance" key), not the whole config.
pub fn appearance(user: &str) -> Option<Appearance> {
    let text = read_first(user, APPEARANCE_SYNCED, CONFIG_REL)?;
    let root: Value = serde_json::from_str(&text).ok()?;
    let appearance = root.get("appearance")?;
    let tty = appearance.get("theme").and_then(Value::as_str).is_some_and(|t| t.eq_ignore_ascii_case("tty"));
    let font = |key: &str| appearance.pointer(&format!("/fonts/{key}")).and_then(Value::as_str).unwrap_or("").to_string();
    Some(Appearance { tty, mono: font("monospace"), icon_nerd: font("iconNerd") })
}

/// Just the `appearance` object of a KiiteShell config, for `--sync` to
/// store without copying the rest of the user's config.
pub fn appearance_only(config_text: &str) -> Option<String> {
    let root: Value = serde_json::from_str(config_text).ok()?;
    let appearance = root.get("appearance")?.clone();
    serde_json::to_string_pretty(&serde_json::json!({ "appearance": appearance })).ok()
}

static NERD: OnceLock<HashMap<&'static str, char>> = OnceLock::new();

/// The Nerd Font glyph TTY draws for the Material symbol `name`, as
/// KiiteShell does. The table (`name codepoint glyph`) is KiiteShell's, by
/// way of Atlas.
pub fn nerd_glyph(name: &str) -> Option<char> {
    NERD.get_or_init(|| {
        include_str!("../../../assets/nerd_symbols.codepoints")
            .lines()
            .filter_map(|line| {
                let mut parts = line.split(' ');
                let (name, hex) = (parts.next()?, parts.next()?);
                Some((name, char::from_u32(u32::from_str_radix(hex, 16).ok()?)?))
            })
            .collect()
    })
    .get(name)
    .copied()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn maps_material_names() {
        assert_eq!(nerd_glyph("ac_unit"), Some('\u{f0717}'));
        assert_eq!(nerd_glyph("no_such_symbol"), None);
    }

    #[test]
    fn keeps_only_appearance() {
        let text = r#"{"appearance": {"theme": "tty"}, "secret": 1}"#;
        let out = appearance_only(text).unwrap();
        assert!(out.contains("tty") && !out.contains("secret"));
    }
}
