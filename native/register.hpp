#pragma once

// Registers Airlock's native (C++) QML types into Astra.Airlock: the vendored
// Blobs renderer (see blobs/NOTICE.md) and the Tokens singleton (theme/,
// adapted from Atlas).
//
// They are built through cxx-qt-build's cpp_files, which runs moc but not
// qmltyperegistrar, so QML_ELEMENT/QML_SINGLETON in their headers never take
// effect; registration is done by hand instead, called from main.rs over
// plain C linkage. Must run once, before the engine loads any QML.
extern "C" void registerNativeQmlTypes();
