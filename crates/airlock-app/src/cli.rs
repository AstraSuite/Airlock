// Port of the old `launcher/main.cpp` C++ shim's CLI surface, minus the parts
// that only made sense when handing off to the `quickshell` binary (we are
// the shell now, so there is no `quickshell -p <dir> ...` exec at the end).

use std::fs;
use std::path::{Path, PathBuf};
use std::process::Command;

pub enum Action {
    /// Proceed to launch the greeter UI, having set up the environment.
    /// The whole QML tree is baked into the binary (see build.rs), so there
    /// is no config directory to resolve or pass along here any more.
    Launch,
    /// A subcommand already ran to completion; exit with this code.
    Exit(i32),
}

fn is_file(p: &str) -> bool {
    Path::new(p).is_file()
}

fn current_user() -> String {
    if let Ok(sudo) = std::env::var("SUDO_USER") {
        if !sudo.is_empty() {
            return sudo;
        }
    }
    std::env::var("USER").unwrap_or_else(|_| "user".to_string())
}

fn expand_path(path: &str, home: &str) -> String {
    let mut path = if path == "~" {
        home.to_string()
    } else if let Some(rest) = path.strip_prefix("~/") {
        format!("{home}/{rest}")
    } else {
        path.to_string()
    };

    loop {
        let Some(dollar) = path.find('$') else { break };
        let rest = &path[dollar + 1..];
        let (name, consumed) = if rest.starts_with('{') {
            match rest.find('}') {
                Some(close) => (&rest[1..close], close + 1),
                None => break,
            }
        } else {
            let end = rest.find(|c: char| !c.is_alphanumeric() && c != '_').unwrap_or(rest.len());
            if end == 0 {
                break;
            }
            (&rest[..end], end)
        };
        let value = std::env::var(name).unwrap_or_default();
        path.replace_range(dollar..dollar + 1 + consumed, &value);
    }
    path
}

fn home_for_user(user: &str) -> String {
    if let Ok(sudo) = std::env::var("SUDO_USER") {
        if !sudo.is_empty() {
            if let Some(dir) = lookup_home_dir(&sudo) {
                return dir;
            }
        }
    }
    std::env::var("HOME").unwrap_or_else(|_| format!("/home/{user}"))
}

fn lookup_home_dir(user: &str) -> Option<String> {
    let text = fs::read_to_string("/etc/passwd").ok()?;
    for line in text.lines() {
        let parts: Vec<&str> = line.split(':').collect();
        if parts.len() >= 6 && parts[0] == user {
            return Some(parts[5].to_string());
        }
    }
    None
}

fn copy_into_store(source: &str, dest_dir: &str, user: &str, quiet: bool, label: &str) -> i32 {
    if !is_file(source) {
        eprintln!("astra-airlock: '{source}' is not a readable regular file");
        return 1;
    }
    if fs::create_dir_all(dest_dir).is_err() {
        eprintln!("astra-airlock: could not create '{dest_dir}'");
        return 1;
    }
    let dest = format!("{dest_dir}/{user}");
    if fs::copy(source, &dest).is_err() {
        eprintln!("astra-airlock: could not write '{dest}'");
        return 1;
    }
    let _ = fs::set_permissions(&dest, std::os::unix::fs::PermissionsExt::from_mode(0o644));
    if !quiet {
        println!("astra-airlock: set {label} for '{user}' from '{source}'");
    }
    0
}

fn set_wallpaper(source: &str, user: &str) -> i32 {
    if source.is_empty() {
        eprintln!("astra-airlock: --set-wallpaper requires a file path");
        return 1;
    }
    let home = home_for_user(user);
    let expanded = expand_path(source, &home);
    copy_into_store(&expanded, "/var/cache/astra-airlock/wallpapers", user, false, "wallpaper")
}

fn set_pfp(source: &str, user: &str) -> i32 {
    if source.is_empty() {
        eprintln!("astra-airlock: --set-pfp requires a file path");
        return 1;
    }
    let home = home_for_user(user);
    let expanded = expand_path(source, &home);
    copy_into_store(&expanded, "/var/cache/astra-airlock/avatars", user, false, "profile picture")
}

fn sync_scheme() -> i32 {
    let (user, home) = if let Some(sudo) = std::env::var("SUDO_USER").ok().filter(|s| !s.is_empty()) {
        let home = lookup_home_dir(&sudo).unwrap_or_else(|| format!("/home/{sudo}"));
        (sudo, home)
    } else if let Some(u) = std::env::var("USER").ok().filter(|s| !s.is_empty()) {
        let home = std::env::var("HOME").unwrap_or_else(|_| format!("/home/{u}"));
        (u, home)
    } else {
        ("default".to_string(), "/root".to_string())
    };

    let cache_home = format!("{home}/.cache");
    let config_home = format!("{home}/.config");

    let py_script = r#"import json, sys
try:
    from caelestia.utils.scheme import get_scheme
    s = get_scheme()
    print(json.dumps({"name": s.name, "flavour": s.flavour, "mode": s.mode, "colours": s.colours}))
except Exception:
    sys.exit(1)
"#;

    let output = Command::new("env")
        .arg(format!("HOME={home}"))
        .arg(format!("USER={user}"))
        .arg(format!("XDG_CACHE_HOME={cache_home}"))
        .arg(format!("XDG_CONFIG_HOME={config_home}"))
        .arg("python3")
        .arg("-c")
        .arg(py_script)
        .output();

    let Ok(output) = output else {
        eprintln!("astra-airlock: error: failed to retrieve current scheme from caelestia for user '{user}'");
        return 1;
    };
    let json_output = String::from_utf8_lossy(&output.stdout).trim().to_string();
    if !output.status.success() || json_output.is_empty() {
        eprintln!("astra-airlock: error: failed to retrieve current scheme from caelestia for user '{user}'");
        return 1;
    }

    let dynamic_dir = format!("/var/cache/astra-airlock/schemes/dynamic/{user}");
    if fs::create_dir_all(&dynamic_dir).is_err() {
        eprintln!("astra-airlock: error: could not create '{dynamic_dir}'");
        return 1;
    }
    for mode in ["dark", "light"] {
        let path = format!("{dynamic_dir}/{mode}.json");
        if fs::write(&path, &json_output).is_err() {
            eprintln!("astra-airlock: error: could not open dynamic scheme files for writing");
            return 1;
        }
        let _ = fs::set_permissions(&path, std::os::unix::fs::PermissionsExt::from_mode(0o644));
    }
    println!("astra-airlock: synced dynamic scheme for user '{user}' to {dynamic_dir}/");

    let wallpaper_source = format!("{home}/.local/state/caelestia/wallpaper/current");
    if is_file(&wallpaper_source) && copy_into_store(&wallpaper_source, "/var/cache/astra-airlock/wallpapers", &user, true, "wallpaper") == 0 {
        println!("astra-airlock: synced wallpaper for user '{user}'");
    }

    0
}

fn find_asset_path(filename: &str, exe_dir: &Path) -> Option<PathBuf> {
    let candidates = [
        format!("/etc/xdg/quickshell/astra-airlock/assets/{filename}"),
        format!("./assets/{filename}"),
        format!("../assets/{filename}"),
        format!("/usr/share/astra-airlock/assets/{filename}"),
        format!("/usr/local/share/astra-airlock/assets/{filename}"),
        exe_dir.join("assets").join(filename).to_string_lossy().to_string(),
        exe_dir.join("../assets").join(filename).to_string_lossy().to_string(),
    ];
    candidates.into_iter().map(PathBuf::from).find(|p| p.is_file())
}

fn configure_kiosk(compositor: &str, exe_dir: &Path) -> i32 {
    let comp = compositor.to_lowercase();
    if comp != "cage" && comp != "hyprland" {
        eprintln!("astra-airlock: unknown kiosk compositor '{compositor}' (choose 'cage' or 'hyprland')");
        return 1;
    }

    let greetd_dir = "/etc/greetd";
    if fs::create_dir_all(greetd_dir).is_err() {
        eprintln!("astra-airlock: could not create '{greetd_dir}' (try running with sudo)");
        return 1;
    }
    let toml_path = format!("{greetd_dir}/config.toml");

    let Some(template_path) = find_asset_path("greetd.toml.example", exe_dir) else {
        eprintln!("astra-airlock: could not find asset file 'greetd.toml.example'");
        return 1;
    };
    let Ok(mut toml_content) = fs::read_to_string(&template_path) else {
        eprintln!("astra-airlock: could not open '{}' for reading", template_path.display());
        return 1;
    };

    if comp == "hyprland" {
        if let Some(cmd_pos) = toml_content.find("command = ") {
            let end_line = toml_content[cmd_pos..].find('\n').map(|i| cmd_pos + i).unwrap_or(toml_content.len());
            toml_content.replace_range(
                cmd_pos..end_line,
                "command = \"start-hyprland -- -c /etc/greetd/hyprland.lua >/dev/null 2>&1\"",
            );
        }
    }

    if fs::write(&toml_path, &toml_content).is_err() {
        eprintln!("astra-airlock: could not write '{toml_path}' (try running with sudo)");
        return 1;
    }
    let _ = fs::set_permissions(&toml_path, std::os::unix::fs::PermissionsExt::from_mode(0o644));

    if comp == "cage" {
        println!("astra-airlock: configured greetd for Cage kiosk ({toml_path})");
        return 0;
    }

    let Some(lua_template) = find_asset_path("hyprland.lua.example", exe_dir) else {
        eprintln!("astra-airlock: could not find asset file 'hyprland.lua.example'");
        return 1;
    };
    let Ok(lua_content) = fs::read_to_string(&lua_template) else {
        eprintln!("astra-airlock: could not open '{}' for reading", lua_template.display());
        return 1;
    };
    let lua_path = format!("{greetd_dir}/hyprland.lua");
    if fs::write(&lua_path, &lua_content).is_err() {
        eprintln!("astra-airlock: could not write '{lua_path}' (try running with sudo)");
        return 1;
    }
    let _ = fs::set_permissions(&lua_path, std::os::unix::fs::PermissionsExt::from_mode(0o644));

    println!("astra-airlock: configured greetd for Hyprland ({toml_path} and {lua_path})");
    0
}

fn hypr_position_to_wlr(pos: &str) -> String {
    pos.replace('x', ",")
}

fn hypr_transform_to_wlr(transform: i32) -> &'static str {
    const NAMES: [&str; 8] = ["normal", "90", "180", "270", "flipped", "flipped-90", "flipped-180", "flipped-270"];
    NAMES.get(transform as usize).copied().unwrap_or("normal")
}

fn format_mode_flag(mode: &str) -> Vec<String> {
    if mode == "preferred" || mode == "auto" {
        return vec!["--preferred".to_string()];
    }
    if mode.contains('@') {
        let mut m = mode.to_string();
        if !m.to_lowercase().contains("hz") {
            m.push_str("Hz");
        }
        return vec!["--custom-mode".to_string(), m];
    }
    vec!["--mode".to_string(), mode.to_string()]
}

#[allow(clippy::too_many_arguments)]
fn append_monitor_group(
    groups: &mut Vec<String>,
    name: &str,
    disabled: bool,
    mode: &str,
    position: &str,
    scale: &str,
    transform: i32,
) {
    if name.is_empty() {
        return;
    }
    let mut group = format!("--output {name}");
    if disabled {
        group.push_str(" --off");
    } else {
        if !mode.is_empty() {
            group.push(' ');
            group.push_str(&format_mode_flag(mode).join(" "));
        }
        if !position.is_empty() && position != "auto" {
            group.push_str(&format!(" --pos {}", hypr_position_to_wlr(position)));
        }
        if !scale.is_empty() && scale != "auto" {
            group.push_str(&format!(" --scale {scale}"));
        }
        if transform != 0 {
            group.push_str(&format!(" --transform {}", hypr_transform_to_wlr(transform)));
        }
    }
    groups.push(group);
}

fn convert_file(path: &str) -> i32 {
    let Ok(content) = fs::read_to_string(path) else {
        eprintln!("astra-airlock: could not open file '{path}'");
        return 1;
    };

    let mut groups = Vec::new();

    let block_re = regex::Regex::new(r"(?s)hl\.monitor\s*\(\s*\{(.*?)\}\s*\)").unwrap();
    let pair_re = regex::Regex::new(r#"([a-zA-Z_][a-zA-Z0-9_]*)\s*=\s*("[^"]*"|[^,\s][^,]*)"#).unwrap();

    for block in block_re.captures_iter(&content) {
        let body = &block[1];
        let mut output = String::new();
        let mut disabled = false;
        let mut mode = String::new();
        let mut position = String::new();
        let mut scale = String::new();
        let mut transform = 0;

        for pair in pair_re.captures_iter(body) {
            let key = &pair[1];
            let value = pair[2].trim().trim_matches('"').to_string();
            match key {
                "output" => output = value,
                "disabled" => disabled = value == "true",
                "mode" => mode = value,
                "position" => position = value,
                "scale" => scale = value,
                "transform" => transform = value.parse().unwrap_or(0),
                _ => {}
            }
        }
        append_monitor_group(&mut groups, &output, disabled, &mode, &position, &scale, transform);
    }

    for line in content.lines() {
        let Some(rest) = line.trim_start().strip_prefix("monitor") else { continue };
        let Some(rest) = rest.trim_start().strip_prefix('=') else { continue };
        let fields: Vec<String> = rest.split(',').map(|s| s.trim().to_string()).collect();
        if fields.is_empty() || fields[0].is_empty() {
            continue;
        }
        let name = fields[0].clone();
        let mut disabled = false;
        let mut mode = String::new();
        let mut position = String::new();
        let mut scale = String::new();
        let mut transform = 0;

        let mut i = 1;
        while i < fields.len() {
            let field = fields[i].trim();
            if field.is_empty() || field == "auto" {
                i += 1;
                continue;
            }
            if field == "disable" || field == "disabled" {
                disabled = true;
            } else if field == "preferred" {
                mode = "preferred".to_string();
            } else if i == 1 {
                mode = field.to_string();
            } else if i == 2 {
                position = field.to_string();
            } else if i == 3 {
                scale = field.to_string();
            } else if field == "transform" && i + 1 < fields.len() {
                i += 1;
                transform = fields[i].trim().parse().unwrap_or(0);
            }
            i += 1;
        }
        append_monitor_group(&mut groups, &name, disabled, &mode, &position, &scale, transform);
    }

    if groups.is_empty() {
        eprintln!("astra-airlock: no monitor configurations found in '{path}'");
        return 1;
    }

    print!("astra-airlock");
    for group in groups {
        print!(" {group}");
    }
    println!();
    0
}

fn print_version() {
    println!("astra-airlock {}", env!("CARGO_PKG_VERSION"));

    let greetd_ver = Command::new("sh")
        .arg("-c")
        .arg("pacman -Q greetd 2>/dev/null | head -n 1 || dpkg-query -W -f='${Package} ${Version}\\n' greetd 2>/dev/null || rpm -q greetd 2>/dev/null || greetd --version 2>&1 || true")
        .output()
        .ok()
        .map(|o| String::from_utf8_lossy(&o.stdout).lines().next().unwrap_or("").trim().to_string())
        .filter(|s| !s.is_empty())
        .unwrap_or_else(|| "greetd version unknown".to_string());
    println!("{greetd_ver}");
}

fn print_usage() {
    print!(
        "usage: astra-airlock [monitor options...]\n\
\n\
Monitor options (applied to the running compositor via wlr-randr):\n\
\n\
  --only NAME              disable every connected output except NAME\n\
                           (repeatable to keep several outputs)\n\
\n\
  --output NAME            target the named output; every following output\n\
                           option applies to it until the next --output\n\
\n\
  --on | --off | --toggle  enable / disable / toggle the current output\n\
  --mode WxH[@RATE]        set the current output mode (e.g. 1920x1080@144)\n\
  --custom-mode WxH[@RATE] set custom mode with exact refresh rate\n\
  --preferred              use the output's preferred mode\n\
\n\
  --pos X,Y                set the output position in the global layout\n\
  --left-of NAME           place the current output left of NAME\n\
  --right-of NAME          place the current output right of NAME\n\
  --above NAME             place the current output above NAME\n\
  --below NAME             place the current output below NAME\n\
\n\
  --transform TRANSFORM    normal|90|180|270|flipped|flipped-90|flipped-180|flipped-270\n\
  --scale FACTOR           set the output scaling factor\n\
\n\
  --adaptive-sync MODE     enabled|disabled\n\
\n\
Other modes:\n\
\n\
  --version | -v           display version of astra-airlock and greetd\n\
\n\
  --kiosk COMPOSITOR | -k COMPOSITOR\n\
                           configure greetd (/etc/greetd/config.toml) for\n\
                           the specified kiosk compositor ('cage' or 'hyprland');\n\
                           run with sudo.\n\
\n\
  --sync | -s              grab the active user's current Caelestia scheme\n\
                           and save it as the 'dynamic' scheme in the greeter's\n\
                           cache (/var/cache/astra-airlock/schemes/dynamic/<user>/);\n\
                           run with sudo.\n\
\n\
  --set-pfp FILE           copy FILE into the shared avatar store\n\
                           (/var/cache/astra-airlock/avatars/<user>)\n\
                           as the profile picture for the current user;\n\
                           run with sudo. ~ and $VAR are expanded.\n\
\n\
  --set-wallpaper FILE     copy FILE into the shared wallpaper store\n\
                           (/var/cache/astra-airlock/wallpapers/<user>)\n\
                           as the wallpaper for the current user;\n\
                           run with sudo. ~ and $VAR are expanded.\n\
\n\
  --convert FILE | -c FILE read monitor configurations from a Hyprland\n\
                           config (plain `monitor =` lines or Lua\n\
                           `hl.monitor({{ ... }})` blocks) and print the\n\
                           equivalent astra-airlock flags\n\
"
    );
}

fn list_outputs() -> Vec<String> {
    for _ in 0..12 {
        if let Ok(output) = Command::new("sh").arg("-c").arg("wlr-randr 2>/dev/null").output() {
            let text = String::from_utf8_lossy(&output.stdout);
            let names: Vec<String> = text
                .lines()
                .filter(|l| !l.starts_with(' ') && !l.starts_with('\t') && !l.trim().is_empty())
                .filter_map(|l| l.split_whitespace().next().map(str::to_string))
                .collect();
            if !names.is_empty() {
                return names;
            }
        }
        std::thread::sleep(std::time::Duration::from_millis(200));
    }
    Vec::new()
}

fn command_available(name: &str) -> bool {
    std::env::var_os("PATH")
        .map(|paths| {
            std::env::split_paths(&paths).any(|dir| dir.join(name).is_file())
        })
        .unwrap_or(false)
}

fn apply_randr(args: &[String]) -> bool {
    if args.is_empty() {
        return true;
    }
    for attempt in 0..15 {
        if Command::new("wlr-randr").args(args).status().map(|s| s.success()).unwrap_or(false) {
            return true;
        }
        if attempt < 14 {
            std::thread::sleep(std::time::Duration::from_millis(150));
        }
    }

    // Fallback: strip refresh-rate suffixes down to plain resolutions.
    let fallback: Vec<String> = {
        let mut out = Vec::new();
        let mut i = 0;
        while i < args.len() {
            if (args[i] == "--mode" || args[i] == "--custom-mode") && i + 1 < args.len() {
                let m = args[i + 1].split('@').next().unwrap_or(&args[i + 1]).to_string();
                out.push("--mode".to_string());
                out.push(m);
                i += 2;
            } else {
                out.push(args[i].clone());
                i += 1;
            }
        }
        out
    };
    Command::new("wlr-randr").args(&fallback).status().map(|s| s.success()).unwrap_or(false)
}

fn ensure_xkb_config() {
    if std::env::var("XKB_DEFAULT_LAYOUT").map(|v| !v.is_empty()).unwrap_or(false) {
        return;
    }
    for path in ["/etc/vconsole.conf", "/etc/default/keyboard"] {
        let Ok(text) = fs::read_to_string(path) else { continue };
        for line in text.lines() {
            if let Some(rest) = line.strip_prefix("KEYMAP=").or_else(|| line.strip_prefix("XKBLAYOUT=")) {
                let layout = rest.trim().trim_matches('"');
                if !layout.is_empty() {
                    std::env::set_var("XKB_DEFAULT_LAYOUT", layout);
                    return;
                }
            }
        }
    }
}

/// Parses CLI args, runs any one-shot subcommand, applies monitor layout, and
/// returns whether to launch the greeter UI.
pub fn run() -> Action {
    if std::env::var("QT_QPA_PLATFORM").map(|v| v.is_empty()).unwrap_or(true) {
        std::env::set_var("QT_QPA_PLATFORM", "wayland");
    }
    ensure_xkb_config();

    let exe_dir = std::env::current_exe()
        .ok()
        .and_then(|p| p.parent().map(Path::to_path_buf))
        .unwrap_or_else(|| PathBuf::from("."));

    let args: Vec<String> = std::env::args().skip(1).collect();
    let mut randr_args: Vec<String> = Vec::new();
    let mut only_keep: Vec<String> = Vec::new();
    let mut have_randr = false;
    let mut cur_output = String::new();

    let mut i = 0;
    while i < args.len() {
        let arg = args[i].as_str();
        let mut take_value = || -> String {
            i += 1;
            args.get(i).cloned().unwrap_or_else(|| {
                eprintln!("astra-airlock: option '{arg}' requires an argument");
                std::process::exit(1);
            })
        };

        match arg {
            "--help" | "-h" => {
                print_usage();
                return Action::Exit(0);
            }
            "--version" | "-v" => {
                print_version();
                return Action::Exit(0);
            }
            "--sync" | "-s" => return Action::Exit(sync_scheme()),
            "--kiosk" | "-k" => {
                let v = take_value();
                return Action::Exit(configure_kiosk(&v, &exe_dir));
            }
            "--set-pfp" => {
                let v = take_value();
                return Action::Exit(set_pfp(&v, &current_user()));
            }
            "--set-wallpaper" => {
                let v = take_value();
                return Action::Exit(set_wallpaper(&v, &current_user()));
            }
            "--convert" | "-c" => {
                let v = take_value();
                return Action::Exit(convert_file(&v));
            }
            "--only" => {
                only_keep.push(take_value());
                have_randr = true;
            }
            "--output" => {
                cur_output = take_value();
                randr_args.push("--output".to_string());
                randr_args.push(cur_output.clone());
                have_randr = true;
            }
            "--on" | "--off" | "--toggle" | "--preferred" => {
                if cur_output.is_empty() {
                    eprintln!("astra-airlock: option '{arg}' used before --output");
                    return Action::Exit(1);
                }
                randr_args.push(arg.to_string());
                have_randr = true;
            }
            "--mode" | "--custom-mode" | "--pos" | "--left-of" | "--right-of" | "--above" | "--below"
            | "--transform" | "--scale" | "--adaptive-sync" => {
                if cur_output.is_empty() {
                    eprintln!("astra-airlock: option '{arg}' used before --output");
                    return Action::Exit(1);
                }
                randr_args.push(arg.to_string());
                randr_args.push(take_value());
                have_randr = true;
            }
            _ => {
                eprintln!("astra-airlock: ignoring unrecognised argument '{arg}'");
            }
        }
        i += 1;
    }

    if !only_keep.is_empty() {
        if !command_available("wlr-randr") {
            eprintln!("astra-airlock: wlr-randr is required for '--only' but was not found in PATH");
            return Action::Exit(1);
        }
        let outputs = list_outputs();
        if outputs.is_empty() {
            eprintln!("astra-airlock: warning: could not query connected outputs");
        } else {
            for name in outputs {
                if !only_keep.contains(&name) {
                    randr_args.push("--output".to_string());
                    randr_args.push(name);
                    randr_args.push("--off".to_string());
                }
            }
        }
    }

    if have_randr {
        if !command_available("wlr-randr") {
            eprintln!("astra-airlock: wlr-randr is required but was not found in PATH");
            return Action::Exit(1);
        }
        apply_randr(&randr_args);
    }

    Action::Launch
}
