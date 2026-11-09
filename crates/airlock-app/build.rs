use cxx_qt_build::{CxxQtBuilder, QmlModule};
use std::fs;
use std::path::{Path, PathBuf};
use std::process::Command;

/// Walks `dir` (relative to the repo root) and returns every file's path
/// relative to the repo root, for embedding into the single-binary Qt
/// resource bundle (see `generate_qrc`).
fn collect_files(repo_root: &Path, dir: &str, out: &mut Vec<String>) {
    let full = repo_root.join(dir);
    let Ok(entries) = fs::read_dir(&full) else { return };
    for entry in entries.flatten() {
        let path = entry.path();
        if path.is_dir() {
            let rel = path.strip_prefix(repo_root).unwrap().to_string_lossy().replace('\\', "/");
            collect_files(repo_root, &rel, out);
        } else {
            let rel = path.strip_prefix(repo_root).unwrap().to_string_lossy().replace('\\', "/");
            out.push(rel);
        }
    }
}

/// Finds Qt's shader baker (`qsb`), used to pre-compile the vendored Blobs
/// GLSL shaders into Qt's portable `.qsb` format at build time.
fn find_qsb() -> PathBuf {
    if let Ok(path) = which_in_path("qsb") {
        return path;
    }
    for candidate in ["/usr/lib/qt6/bin/qsb", "/usr/lib/qt6/libexec/qsb", "/usr/lib64/qt6/bin/qsb"] {
        if Path::new(candidate).is_file() {
            return PathBuf::from(candidate);
        }
    }
    panic!(
        "could not find Qt's `qsb` shader baker (needed to compile the vendored Blobs shaders); \
         install it (part of qt6-shadertools) or add it to PATH"
    );
}

fn which_in_path(name: &str) -> Result<PathBuf, ()> {
    let Some(paths) = std::env::var_os("PATH") else { return Err(()) };
    for dir in std::env::split_paths(&paths) {
        let candidate = dir.join(name);
        if candidate.is_file() {
            return Ok(candidate);
        }
    }
    Err(())
}

/// Bakes `blob.vert`/`blob.frag` (vendored from caelestia-shell, see
/// `native/blobs/NOTICE.md`) into `.qsb` shader packs under `out_dir`,
/// matching the resource paths `BlobMaterialShader` expects
/// (`:/shaders/blob.{vert,frag}.qsb`).
fn bake_blob_shaders(repo_root: &Path, out_dir: &Path) -> Vec<(String, PathBuf)> {
    let qsb = find_qsb();
    let shaders_dir = repo_root.join("native/blobs/shaders");
    let mut baked = Vec::new();

    for stage in ["vert", "frag"] {
        let input = shaders_dir.join(format!("blob.{stage}"));
        let output = out_dir.join(format!("blob.{stage}.qsb"));
        let status = Command::new(&qsb)
            .args(["-b", "--glsl", "300es,330", "-o"])
            .arg(&output)
            .arg(&input)
            .status()
            .unwrap_or_else(|e| panic!("failed to run qsb on {}: {e}", input.display()));
        assert!(status.success(), "qsb failed baking {}", input.display());
        baked.push((format!("shaders/blob.{stage}.qsb"), output));
    }
    baked
}

/// Generates a Qt .qrc resource manifest embedding the whole QML tree
/// (components/, modules/, services/, shell.qml), the two bundled fonts,
/// and the baked Blobs shaders, so the final binary needs nothing on disk
/// at runtime.
fn generate_qrc(repo_root: &Path, out_dir: &Path, baked_shaders: &[(String, PathBuf)]) -> PathBuf {
    let mut files = Vec::new();
    for dir in ["components", "modules", "services"] {
        collect_files(repo_root, dir, &mut files);
    }
    files.push("shell.qml".to_string());
    for font in [
        "assets/fonts/GoogleSansFlex-VariableFont_GRAD,ROND,opsz,slnt,wdth,wght.ttf",
        "assets/fonts/TitanOne-Regular.ttf",
    ] {
        if repo_root.join(font).is_file() {
            files.push(font.to_string());
        }
    }

    let mut qrc = String::from("<!DOCTYPE RCC><RCC version=\"1.0\">\n<qresource prefix=\"/airlock\">\n");
    for f in &files {
        let abs = repo_root.join(f);
        qrc.push_str(&format!("  <file alias=\"{f}\">{}</file>\n", abs.display()));
    }
    qrc.push_str("</qresource>\n");

    // Root prefix: BlobMaterialShader hardcodes ":/shaders/blob.*.qsb" (no
    // module prefix), matching caelestia-shell's own `qt_add_shaders(PREFIX "/")`.
    qrc.push_str("<qresource prefix=\"/\">\n");
    for (alias, path) in baked_shaders {
        qrc.push_str(&format!("  <file alias=\"{alias}\">{}</file>\n", path.display()));
    }
    qrc.push_str("</qresource>\n</RCC>\n");

    let qrc_path = out_dir.join("airlock.qrc");
    fs::write(&qrc_path, qrc).expect("failed to write generated airlock.qrc");
    qrc_path
}

fn main() {
    let manifest_dir = PathBuf::from(std::env::var("CARGO_MANIFEST_DIR").unwrap());
    // crates/airlock-app -> repo root
    let repo_root = manifest_dir.parent().unwrap().parent().unwrap().to_path_buf();
    let out_dir = PathBuf::from(std::env::var("OUT_DIR").unwrap());

    let baked_shaders = bake_blob_shaders(&repo_root, &out_dir);
    let qrc_path = generate_qrc(&repo_root, &out_dir, &baked_shaders);

    println!("cargo:rerun-if-changed={}", repo_root.join("shell.qml").display());
    for dir in ["components", "modules", "services"] {
        println!("cargo:rerun-if-changed={}", repo_root.join(dir).display());
    }
    println!("cargo:rerun-if-changed={}", repo_root.join("native/blobs").display());

    let builder = CxxQtBuilder::new_qml_module(QmlModule::new("Astra.Airlock"))
        .files([
            "src/greeter_state.rs",
            "src/user_discovery.rs",
            "src/session_discovery.rs",
            "src/scheme_discovery.rs",
            "src/session_manager.rs",
            "src/greetd.rs",
            "src/system_info.rs",
            "src/battery.rs",
            "src/quickshell_compat.rs",
        ])
        .cpp_files([
            // Headers first: moc only runs on files passed here that it
            // recognises need it (Q_OBJECT), which for .cpp files that
            // #include their own header is otherwise a no-op, so the
            // headers themselves must be listed too.
            repo_root.join("native/blobs/blobgroup.hpp"),
            repo_root.join("native/blobs/blobshape.hpp"),
            repo_root.join("native/blobs/blobrect.hpp"),
            repo_root.join("native/blobs/blobinvertedrect.hpp"),
            repo_root.join("native/blobs/blobgroup.cpp"),
            repo_root.join("native/blobs/blobshape.cpp"),
            repo_root.join("native/blobs/blobrect.cpp"),
            repo_root.join("native/blobs/blobinvertedrect.cpp"),
            repo_root.join("native/blobs/blobmaterial.cpp"),
            repo_root.join("native/blobs/register.cpp"),
        ])
        .qt_module("Quick")
        .qrc(qrc_path);

    builder.build();
}
