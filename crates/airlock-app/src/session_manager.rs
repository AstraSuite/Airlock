#[cxx_qt::bridge]
pub mod ffi {
    unsafe extern "C++" {
        include!("cxx-qt-lib/qstring.h");
        type QString = cxx_qt_lib::QString;
        include!("cxx-qt-lib/qstringlist.h");
        type QStringList = cxx_qt_lib::QStringList;
    }

    extern "RustQt" {
        #[qobject]
        #[qml_element]
        #[qml_singleton]
        type SessionManager = super::SessionManagerRust;

        #[qinvokable]
        fn logout(self: &SessionManager);
        #[qinvokable]
        fn suspend(self: &SessionManager);
        #[qinvokable]
        #[cxx_name = "suspendThenHibernate"]
        fn suspend_then_hibernate(self: &SessionManager);
        #[qinvokable]
        fn hibernate(self: &SessionManager);
        #[qinvokable]
        fn poweroff(self: &SessionManager);
        #[qinvokable]
        fn reboot(self: &SessionManager);
        #[qinvokable]
        #[cxx_name = "rebootToUefi"]
        fn reboot_to_uefi(self: &SessionManager);
        #[qinvokable]
        #[cxx_name = "rebootToFirmware"]
        fn reboot_to_firmware(self: &SessionManager);
        #[qinvokable]
        #[cxx_name = "canRebootToUefi"]
        fn can_reboot_to_uefi(self: &SessionManager) -> bool;
        #[qinvokable]
        fn exec(self: &SessionManager, command: QStringList) -> bool;
    }

    impl cxx_qt::Constructor<()> for SessionManager {}
}

use cxx_qt::CxxQtType;
use cxx_qt_lib::QStringList;
use std::pin::Pin;
use std::process::Command;
use zbus::blocking::Connection;
use zbus::zvariant::OwnedObjectPath;

const LOGIN_SERVICE: &str = "org.freedesktop.login1";
const LOGIN_PATH: &str = "/org/freedesktop/login1";
const LOGIN_IFACE: &str = "org.freedesktop.login1.Manager";
const SESSION_IFACE: &str = "org.freedesktop.login1.Session";

#[derive(Default)]
pub struct SessionManagerRust {
    session_path: String,
}

fn system_bus() -> Option<Connection> {
    Connection::system().ok()
}

fn call_manager_bool(method: &str, arg: bool) -> bool {
    let Some(bus) = system_bus() else { return false };
    bus.call_method(Some(LOGIN_SERVICE), LOGIN_PATH, Some(LOGIN_IFACE), method, &(arg,))
        .is_ok()
}

fn query_string_prop(method: &str) -> Option<String> {
    let bus = system_bus()?;
    let reply = bus
        .call_method(Some(LOGIN_SERVICE), LOGIN_PATH, Some(LOGIN_IFACE), method, &())
        .ok()?;
    reply.body().deserialize::<String>().ok()
}

fn query_hibernate_available() -> bool {
    matches!(query_string_prop("CanHibernate").as_deref(), Some("yes") | Some("challenge"))
}

fn run_fallback(candidates: &[&str]) {
    for cmd_str in candidates {
        let parts: Vec<&str> = cmd_str.split_whitespace().collect();
        if parts.is_empty() {
            continue;
        }
        if Command::new(parts[0]).args(&parts[1..]).spawn().is_ok() {
            return;
        }
    }
}

fn discover_session_path() -> Option<String> {
    let bus = system_bus()?;
    let reply = bus
        .call_method(Some(LOGIN_SERVICE), LOGIN_PATH, Some(LOGIN_IFACE), "GetSession", &("auto",))
        .ok()?;
    let path: OwnedObjectPath = reply.body().deserialize().ok()?;
    Some(path.to_string())
}

impl cxx_qt::Initialize for ffi::SessionManager {
    fn initialize(mut self: Pin<&mut Self>) {
        let path = discover_session_path().unwrap_or_default();
        self.as_mut().rust_mut().session_path = path;
    }
}

impl ffi::SessionManager {
    pub fn logout(&self) {
        if !self.session_path.is_empty() {
            if let Some(bus) = system_bus() {
                let _ = bus.call_method(
                    Some(LOGIN_SERVICE),
                    self.session_path.as_str(),
                    Some(SESSION_IFACE),
                    "Terminate",
                    &(),
                );
                return;
            }
        }
        run_fallback(&["loginctl terminate-user", "pkill -u $USER"]);
    }

    pub fn suspend(&self) {
        if !call_manager_bool("Suspend", true) {
            run_fallback(&["loginctl suspend", "zzz", "systemctl suspend"]);
        }
    }

    pub fn suspend_then_hibernate(&self) {
        if query_hibernate_available() {
            if !call_manager_bool("SuspendThenHibernate", true) {
                self.suspend();
            }
        } else {
            self.suspend();
        }
    }

    pub fn hibernate(&self) {
        if query_hibernate_available() {
            if !call_manager_bool("Hibernate", true) {
                run_fallback(&["loginctl hibernate", "ZZZ", "systemctl hibernate"]);
            }
        }
    }

    pub fn can_reboot_to_uefi(&self) -> bool {
        matches!(query_string_prop("CanRebootToFirmwareSetup").as_deref(), Some("yes") | Some("challenge"))
    }

    pub fn reboot_to_uefi(&self) {
        if let Some(bus) = system_bus() {
            let _ = bus.call_method(
                Some(LOGIN_SERVICE),
                LOGIN_PATH,
                Some(LOGIN_IFACE),
                "SetRebootToFirmwareSetup",
                &(true,),
            );
            if call_manager_bool("Reboot", true) {
                return;
            }
        }
        run_fallback(&[
            "systemctl reboot --firmware-setup",
            "bootctl reboot-to-firmware true",
            "efibootmgr --reboot-to-firmware",
        ]);
        self.reboot();
    }

    pub fn reboot_to_firmware(&self) {
        self.reboot_to_uefi();
    }

    pub fn poweroff(&self) {
        if !call_manager_bool("PowerOff", true) {
            run_fallback(&[
                "loginctl poweroff",
                "openrc-shutdown -p",
                "poweroff",
                "systemctl poweroff",
                "shutdown -h now",
            ]);
        }
    }

    pub fn reboot(&self) {
        if !call_manager_bool("Reboot", true) {
            run_fallback(&[
                "loginctl reboot",
                "openrc-shutdown -r",
                "reboot",
                "systemctl reboot",
                "shutdown -r now",
            ]);
        }
    }

    pub fn exec(&self, command: QStringList) -> bool {
        let parts: Vec<String> = (0..command.len())
            .map(|i| command.get(i).map(|q| q.to_string()).unwrap_or_default())
            .collect();
        if parts.is_empty() {
            return false;
        }

        let mut cmd = parts[0].clone();
        if (cmd == "systemctl" || cmd == "loginctl") && parts.len() == 2 {
            cmd = parts[1].clone();
        }
        if cmd == "loginctl" && parts.len() == 3 && parts[1] == "terminate-user" && parts[2].is_empty() {
            cmd = "logout".to_string();
        }
        let normalized: String = cmd.chars().filter(|c| *c != '-' && *c != '_').collect::<String>().to_lowercase();

        match normalized.as_str() {
            "logout" => { self.logout(); true }
            "suspend" => { self.suspend(); true }
            "suspendthenhibernate" => { self.suspend_then_hibernate(); true }
            "hibernate" => { self.hibernate(); true }
            "reboottouefi" | "reboottofirmware" | "uefi" | "firmware" | "bios" => { self.reboot_to_uefi(); true }
            "poweroff" | "shutdown" => { self.poweroff(); true }
            "reboot" => { self.reboot(); true }
            _ => false,
        }
    }
}
