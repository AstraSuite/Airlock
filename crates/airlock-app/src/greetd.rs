// Reimplements Quickshell's `Quickshell.Services.Greetd` / `GreetdState` QML API
// (see /usr/lib/qt6/qml/Quickshell/Services/Greetd/quickshell-service-greetd.qmltypes)
// against the real greetd IPC protocol, now that Quickshell itself is gone.
// `Center.qml` / `LocklikePanel.qml` already bypass this entirely in test mode
// (`!Greetd.available`), so only the real-socket path needs implementing here.

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
        #[qproperty(bool, available, READ, CONSTANT)]
        #[qproperty(i32, state, READ, NOTIFY)]
        #[qproperty(QString, user, READ, NOTIFY)]
        type Greetd = super::GreetdRust;

        #[qsignal]
        #[cxx_name = "authMessage"]
        fn auth_message(self: Pin<&mut Greetd>, message: QString, error: bool, response_required: bool, echo_response: bool);
        #[qsignal]
        #[cxx_name = "authFailure"]
        fn auth_failure(self: Pin<&mut Greetd>, message: QString);
        #[qsignal]
        #[cxx_name = "readyToLaunch"]
        fn ready_to_launch(self: Pin<&mut Greetd>);
        #[qsignal]
        fn launched(self: Pin<&mut Greetd>);
        #[qsignal]
        fn error(self: Pin<&mut Greetd>, error: QString);

        #[qinvokable]
        #[cxx_name = "createSession"]
        fn create_session(self: Pin<&mut Greetd>, user: QString);
        #[qinvokable]
        #[cxx_name = "cancelSession"]
        fn cancel_session(self: Pin<&mut Greetd>);
        #[qinvokable]
        fn respond(self: Pin<&mut Greetd>, response: QString);
        #[qinvokable]
        fn launch(self: Pin<&mut Greetd>, command: QStringList);
    }

    impl cxx_qt::Constructor<()> for Greetd {}
    impl cxx_qt::Threading for Greetd {}

    extern "RustQt" {
        #[qobject]
        #[qml_element]
        #[qml_singleton]
        #[qproperty(i32, inactive, READ, CONSTANT)]
        #[qproperty(i32, authenticating, READ, CONSTANT)]
        #[qproperty(i32, ready_to_launch, READ, CONSTANT, cxx_name = "readyToLaunch")]
        #[qproperty(i32, launching, READ, CONSTANT)]
        #[qproperty(i32, launched, READ, CONSTANT)]
        type GreetdState = super::GreetdStateRust;
    }
}

use cxx_qt::{CxxQtType, Threading};
use cxx_qt_lib::{QString, QStringList};
use std::io::{Read, Write};
use std::os::unix::net::UnixStream;
use std::pin::Pin;

pub const STATE_INACTIVE: i32 = 0;
pub const STATE_AUTHENTICATING: i32 = 1;
pub const STATE_READY_TO_LAUNCH: i32 = 2;
pub const STATE_LAUNCHING: i32 = 3;
pub const STATE_LAUNCHED: i32 = 4;

pub struct GreetdRust {
    available: bool,
    state: i32,
    user: QString,
    write_half: Option<UnixStream>,
}

impl Default for GreetdRust {
    fn default() -> Self {
        Self {
            available: false,
            state: STATE_INACTIVE,
            user: QString::default(),
            write_half: None,
        }
    }
}

pub struct GreetdStateRust {
    inactive: i32,
    authenticating: i32,
    ready_to_launch: i32,
    launching: i32,
    launched: i32,
}

impl Default for GreetdStateRust {
    fn default() -> Self {
        Self {
            inactive: STATE_INACTIVE,
            authenticating: STATE_AUTHENTICATING,
            ready_to_launch: STATE_READY_TO_LAUNCH,
            launching: STATE_LAUNCHING,
            launched: STATE_LAUNCHED,
        }
    }
}

fn write_frame(stream: &mut UnixStream, value: &serde_json::Value) -> std::io::Result<()> {
    let payload = serde_json::to_vec(value)?;
    let len = payload.len() as u32;
    stream.write_all(&len.to_ne_bytes())?;
    stream.write_all(&payload)?;
    stream.flush()
}

fn read_frame(stream: &mut UnixStream) -> std::io::Result<serde_json::Value> {
    let mut len_buf = [0u8; 4];
    stream.read_exact(&mut len_buf)?;
    let len = u32::from_ne_bytes(len_buf) as usize;
    let mut payload = vec![0u8; len];
    stream.read_exact(&mut payload)?;
    serde_json::from_slice(&payload).map_err(|e| std::io::Error::new(std::io::ErrorKind::InvalidData, e))
}

fn spawn_reader(mut read_half: UnixStream, qt_thread: cxx_qt::CxxQtThread<ffi::Greetd>) {
    std::thread::spawn(move || loop {
        let msg = match read_frame(&mut read_half) {
            Ok(m) => m,
            Err(_) => break,
        };
        let msg_type = msg.get("type").and_then(|v| v.as_str()).unwrap_or("").to_string();

        let queued = match msg_type.as_str() {
            "success" => qt_thread.queue(|mut state: Pin<&mut ffi::Greetd>| {
                if state.state == STATE_AUTHENTICATING {
                    state.as_mut().rust_mut().state = STATE_READY_TO_LAUNCH;
                    state.as_mut().state_changed();
                    state.as_mut().ready_to_launch();
                } else {
                    state.as_mut().rust_mut().state = STATE_LAUNCHED;
                    state.as_mut().state_changed();
                    state.as_mut().launched();
                }
            }),
            "auth_message" => {
                let message = msg.get("auth_message").and_then(|v| v.as_str()).unwrap_or("").to_string();
                let kind = msg.get("auth_message_type").and_then(|v| v.as_str()).unwrap_or("").to_string();
                qt_thread.queue(move |mut state: Pin<&mut ffi::Greetd>| {
                    let (is_error, response_required, echo_response) = match kind.as_str() {
                        "visible" => (false, true, true),
                        "secret" => (false, true, false),
                        "error" => (true, false, false),
                        _ => (false, false, false),
                    };
                    state.as_mut().auth_message(QString::from(message.as_str()), is_error, response_required, echo_response);
                })
            }
            "error" => {
                let description = msg.get("description").and_then(|v| v.as_str()).unwrap_or("Authentication failed").to_string();
                qt_thread.queue(move |mut state: Pin<&mut ffi::Greetd>| {
                    state.as_mut().rust_mut().state = STATE_INACTIVE;
                    state.as_mut().state_changed();
                    state.as_mut().auth_failure(QString::from(description.as_str()));
                })
            }
            _ => Ok(()),
        };

        if queued.is_err() {
            break;
        }
    });
}

impl cxx_qt::Initialize for ffi::Greetd {
    fn initialize(self: Pin<&mut Self>) {
        let Ok(sock_path) = std::env::var("GREETD_SOCK") else {
            return;
        };
        if sock_path.is_empty() {
            return;
        }
        let Ok(stream) = UnixStream::connect(&sock_path) else {
            return;
        };
        let Ok(read_half) = stream.try_clone() else {
            return;
        };

        let qt_thread = self.qt_thread();
        {
            let mut rust = self.rust_mut();
            rust.available = true;
            rust.write_half = Some(stream);
        }

        spawn_reader(read_half, qt_thread);
    }
}

impl ffi::Greetd {
    pub fn create_session(mut self: Pin<&mut Self>, user: QString) {
        self.as_mut().rust_mut().user = user.clone();
        self.as_mut().rust_mut().state = STATE_AUTHENTICATING;
        self.as_mut().user_changed();
        self.as_mut().state_changed();

        let payload = serde_json::json!({ "type": "create_session", "username": user.to_string() });
        if let Some(stream) = self.as_mut().rust_mut().write_half.as_mut() {
            let _ = write_frame(stream, &payload);
        }
    }

    pub fn cancel_session(mut self: Pin<&mut Self>) {
        let payload = serde_json::json!({ "type": "cancel_session" });
        if let Some(stream) = self.as_mut().rust_mut().write_half.as_mut() {
            let _ = write_frame(stream, &payload);
        }
        self.as_mut().rust_mut().state = STATE_INACTIVE;
        self.as_mut().state_changed();
    }

    pub fn respond(mut self: Pin<&mut Self>, response: QString) {
        let payload = serde_json::json!({ "type": "post_auth_message_response", "response": response.to_string() });
        if let Some(stream) = self.as_mut().rust_mut().write_half.as_mut() {
            let _ = write_frame(stream, &payload);
        }
    }

    pub fn launch(mut self: Pin<&mut Self>, command: QStringList) {
        let cmd: Vec<String> = (0..command.len())
            .map(|i| command.get(i).map(|q| q.to_string()).unwrap_or_default())
            .filter(|s| !s.is_empty())
            .collect();

        self.as_mut().rust_mut().state = STATE_LAUNCHING;
        self.as_mut().state_changed();

        let payload = serde_json::json!({ "type": "start_session", "cmd": cmd, "env": [] });
        if let Some(stream) = self.as_mut().rust_mut().write_half.as_mut() {
            let _ = write_frame(stream, &payload);
        }
    }
}
