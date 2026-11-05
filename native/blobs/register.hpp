#pragma once

// Manually registers the vendored Blobs types (see NOTICE.md) into QML.
//
// They carry QML_ELEMENT in their headers (as in upstream caelestia-shell),
// but that macro only takes effect when qmltyperegistrar runs over the file
// as part of building a qt_add_qml_module target's own sources; cxx-qt-build
// compiling them as plain extra C++ files (CxxQtBuilder::cpp_files) does not
// run that pass, so qmlRegisterType is used instead, called from Rust (see
// main.rs) via plain C linkage rather than a cxx bridge. Must be called once,
// before the QML engine loads anything that imports Astra.Airlock.
extern "C" void registerBlobsQmlTypes();
