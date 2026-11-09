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
        #[qproperty(QString, os_name, READ, NOTIFY = os_name_changed, cxx_name = "osName")]
        #[qproperty(QString, os_pretty_name, READ, NOTIFY = os_pretty_name_changed, cxx_name = "osPrettyName")]
        #[qproperty(QString, wm_name, READ, CONSTANT, cxx_name = "wmName")]
        #[qproperty(QString, user_name, READ, CONSTANT, cxx_name = "userName")]
        #[qproperty(QString, uptime_str, READ, NOTIFY = uptime_str_changed, cxx_name = "uptimeStr")]
        #[qproperty(i32, cpu_percent, READ, NOTIFY = cpu_percent_changed, cxx_name = "cpuPercent")]
        #[qproperty(i32, cpu_temp, READ, NOTIFY = cpu_temp_changed, cxx_name = "cpuTemp")]
        #[qproperty(i32, mem_percent, READ, NOTIFY = mem_percent_changed, cxx_name = "memPercent")]
        #[qproperty(i32, disk_percent, READ, CONSTANT, cxx_name = "diskPercent")]
        type SystemInfo = super::SystemInfoRust;

        #[qsignal]
        #[cxx_name = "osNameChanged"]
        fn os_name_changed(self: Pin<&mut SystemInfo>);
        #[qsignal]
        #[cxx_name = "osPrettyNameChanged"]
        fn os_pretty_name_changed(self: Pin<&mut SystemInfo>);
        #[qsignal]
        #[cxx_name = "uptimeStrChanged"]
        fn uptime_str_changed(self: Pin<&mut SystemInfo>);
        #[qsignal]
        #[cxx_name = "cpuPercentChanged"]
        fn cpu_percent_changed(self: Pin<&mut SystemInfo>);
        #[qsignal]
        #[cxx_name = "cpuTempChanged"]
        fn cpu_temp_changed(self: Pin<&mut SystemInfo>);
        #[qsignal]
        #[cxx_name = "memPercentChanged"]
        fn mem_percent_changed(self: Pin<&mut SystemInfo>);

        /// Called periodically by a QML Timer (replaces the old FileView/Timer combo).
        #[qinvokable]
        fn refresh(self: Pin<&mut SystemInfo>);
    }

    impl cxx_qt::Constructor<()> for SystemInfo {}
}

use cxx_qt::CxxQtType;
use cxx_qt_lib::QString;
use std::fs;
use std::pin::Pin;

pub struct SystemInfoRust {
    os_name: QString,
    os_pretty_name: QString,
    wm_name: QString,
    user_name: QString,
    uptime_str: QString,
    cpu_percent: i32,
    cpu_temp: i32,
    mem_percent: i32,
    disk_percent: i32,
    prev_cpu: (u64, u64),
}

impl Default for SystemInfoRust {
    fn default() -> Self {
        Self {
            os_name: QString::from("Artix Linux"),
            os_pretty_name: QString::from("Artix Linux"),
            wm_name: QString::from(
                std::env::var("XDG_CURRENT_DESKTOP")
                    .or_else(|_| std::env::var("XDG_SESSION_DESKTOP"))
                    .unwrap_or_else(|_| "Hyprland".to_string())
                    .as_str(),
            ),
            user_name: QString::from(std::env::var("USER").unwrap_or_else(|_| "dim".to_string()).as_str()),
            uptime_str: QString::from("0 minutes"),
            cpu_percent: 11,
            cpu_temp: 62,
            mem_percent: 24,
            disk_percent: 48,
            prev_cpu: (0, 0),
        }
    }
}

fn read_os_release() -> Option<(String, String)> {
    let text = fs::read_to_string("/etc/os-release").ok()?;
    let find = |key: &str| -> Option<String> {
        text.lines()
            .find(|l| l.starts_with(&format!("{key}=")))
            .and_then(|l| l.split('=').nth(1))
            .map(|v| v.trim_matches('"').to_string())
    };
    let name = find("NAME").unwrap_or_default();
    let pretty = find("PRETTY_NAME").unwrap_or_else(|| name.clone());
    Some((name, pretty))
}

fn format_uptime(seconds: u64) -> String {
    let days = seconds / 86400;
    let hours = (seconds % 86400) / 3600;
    let minutes = (seconds % 3600) / 60;

    let mut parts = Vec::new();
    if days > 0 {
        parts.push(format!("{days} day{}", if days == 1 { "" } else { "s" }));
    }
    if hours > 0 {
        parts.push(format!("{hours} hour{}", if hours == 1 { "" } else { "s" }));
    }
    if minutes > 0 || parts.is_empty() {
        parts.push(format!("{minutes} minute{}", if minutes == 1 { "" } else { "s" }));
    }
    parts.join(", ")
}

fn read_uptime() -> Option<u64> {
    let text = fs::read_to_string("/proc/uptime").ok()?;
    text.split_whitespace().next()?.parse::<f64>().ok().map(|v| v as u64)
}

fn read_mem_percent() -> Option<i32> {
    let text = fs::read_to_string("/proc/meminfo").ok()?;
    let mut total = None;
    let mut avail = None;
    for line in text.lines() {
        if let Some(rest) = line.strip_prefix("MemTotal:") {
            total = rest.trim().split_whitespace().next()?.parse::<i64>().ok();
        } else if let Some(rest) = line.strip_prefix("MemAvailable:") {
            avail = rest.trim().split_whitespace().next()?.parse::<i64>().ok();
        }
    }
    let (total, avail) = (total?, avail?);
    if total <= 0 {
        return None;
    }
    Some((((total - avail) as f64 / total as f64) * 100.0).round() as i32)
}

fn read_cpu_totals() -> Option<(u64, u64)> {
    let text = fs::read_to_string("/proc/stat").ok()?;
    let line = text.lines().find(|l| l.starts_with("cpu "))?;
    let nums: Vec<u64> = line.split_whitespace().skip(1).filter_map(|s| s.parse().ok()).collect();
    if nums.len() < 7 {
        return None;
    }
    let (user, nice, sys, idle, iowait, irq, softirq) = (nums[0], nums[1], nums[2], nums[3], nums[4], nums[5], nums[6]);
    let total = user + nice + sys + idle + iowait + irq + softirq;
    let active = user + nice + sys + irq + softirq;
    Some((total, active))
}

fn read_cpu_temp() -> Option<i32> {
    for path in [
        "/sys/class/hwmon/hwmon4/temp1_input",
        "/sys/class/thermal/thermal_zone0/temp",
    ] {
        if let Ok(text) = fs::read_to_string(path) {
            if let Ok(t) = text.trim().parse::<i64>() {
                if t > 0 {
                    return Some((if t > 1000 { t / 1000 } else { t }) as i32);
                }
            }
        }
    }
    None
}

impl cxx_qt::Initialize for ffi::SystemInfo {
    fn initialize(self: Pin<&mut Self>) {
        self.refresh();
    }
}

impl ffi::SystemInfo {
    pub fn refresh(mut self: Pin<&mut Self>) {
        if let Some((name, pretty)) = read_os_release() {
            self.as_mut().rust_mut().os_name = QString::from(name.as_str());
            self.as_mut().rust_mut().os_pretty_name = QString::from(pretty.as_str());
            self.as_mut().os_name_changed();
            self.as_mut().os_pretty_name_changed();
        }

        if let Some(secs) = read_uptime() {
            let s = format_uptime(secs);
            self.as_mut().rust_mut().uptime_str = QString::from(s.as_str());
            self.as_mut().uptime_str_changed();
        }

        if let Some(mem) = read_mem_percent() {
            self.as_mut().rust_mut().mem_percent = mem.clamp(0, 100);
            self.as_mut().mem_percent_changed();
        }

        if let Some((total, active)) = read_cpu_totals() {
            let (prev_total, prev_active) = self.prev_cpu;
            if prev_total > 0 && total > prev_total {
                let diff_total = total - prev_total;
                let diff_active = active.saturating_sub(prev_active);
                let pct = ((diff_active as f64 / diff_total as f64) * 100.0).round() as i32;
                self.as_mut().rust_mut().cpu_percent = pct.clamp(0, 100);
                self.as_mut().cpu_percent_changed();
            }
            self.as_mut().rust_mut().prev_cpu = (total, active);
        }

        if let Some(temp) = read_cpu_temp() {
            self.as_mut().rust_mut().cpu_temp = temp;
            self.as_mut().cpu_temp_changed();
        }
    }
}
