// Replaces `Quickshell.Services.UPower` for BatteryState.qml. The original QML
// read a nested `UPower.displayDevice.{isPresent,ready,percentage,state}`; since
// nesting a QObject behind a property is extra complexity cxx-qt doesn't need
// here, this exposes the display battery's fields flat instead (BatteryState.qml
// is edited to match, same as it already special-cases its own test mode).

#[cxx_qt::bridge]
pub mod ffi {
    extern "RustQt" {
        #[qobject]
        #[qml_element]
        #[qml_singleton]
        #[qproperty(bool, present, READ, NOTIFY)]
        #[qproperty(bool, ready, READ, NOTIFY)]
        #[qproperty(f64, percentage, READ, NOTIFY)]
        #[qproperty(bool, charging, READ, NOTIFY)]
        type Battery = super::BatteryRust;

        #[qinvokable]
        fn refresh(self: Pin<&mut Battery>);
    }

    impl cxx_qt::Constructor<()> for Battery {}
}

use cxx_qt::CxxQtType;
use std::pin::Pin;
use zbus::blocking::Connection;
use zbus::zvariant::OwnedObjectPath;

const UPOWER_SERVICE: &str = "org.freedesktop.UPower";
const UPOWER_PATH: &str = "/org/freedesktop/UPower";
const UPOWER_IFACE: &str = "org.freedesktop.UPower";
const DEVICE_IFACE: &str = "org.freedesktop.UPower.Device";
const PROPS_IFACE: &str = "org.freedesktop.DBus.Properties";

// org.freedesktop.UPower.Device's State enum.
const STATE_CHARGING: u32 = 1;
const STATE_FULLY_CHARGED: u32 = 4;
const STATE_PENDING_CHARGE: u32 = 5;

#[derive(Default)]
pub struct BatteryRust {
    present: bool,
    ready: bool,
    percentage: f64,
    charging: bool,
}

fn display_device_path() -> Option<OwnedObjectPath> {
    let bus = Connection::system().ok()?;
    let reply = bus
        .call_method(Some(UPOWER_SERVICE), UPOWER_PATH, Some(UPOWER_IFACE), "GetDisplayDevice", &())
        .ok()?;
    reply.body().deserialize().ok()
}

fn get_prop<T>(bus: &Connection, path: &str, prop: &str) -> Option<T>
where
    T: TryFrom<zbus::zvariant::OwnedValue>,
{
    let reply = bus
        .call_method(Some(UPOWER_SERVICE), path, Some(PROPS_IFACE), "Get", &(DEVICE_IFACE, prop))
        .ok()?;
    let variant: zbus::zvariant::OwnedValue = reply.body().deserialize().ok()?;
    T::try_from(variant).ok()
}

impl cxx_qt::Initialize for ffi::Battery {
    fn initialize(self: Pin<&mut Self>) {
        self.refresh();
    }
}

impl ffi::Battery {
    pub fn refresh(mut self: Pin<&mut Self>) {
        let Some(bus) = Connection::system().ok() else { return };
        let Some(path) = display_device_path() else { return };
        let path_str = path.to_string();

        let is_present: bool = get_prop(&bus, &path_str, "IsPresent").unwrap_or(false);
        let state: u32 = get_prop(&bus, &path_str, "State").unwrap_or(0);
        let percentage: f64 = get_prop(&bus, &path_str, "Percentage").unwrap_or(0.0);

        let charging = matches!(state, STATE_CHARGING | STATE_FULLY_CHARGED | STATE_PENDING_CHARGE);

        let mut rust = self.as_mut().rust_mut();
        rust.present = is_present;
        rust.ready = true;
        rust.percentage = percentage;
        rust.charging = charging;

        self.as_mut().present_changed();
        self.as_mut().ready_changed();
        self.as_mut().percentage_changed();
        self.as_mut().charging_changed();
    }
}
