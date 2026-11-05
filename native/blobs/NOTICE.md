# Vendored: Caelestia Shell's "Blobs" metaball renderer

The C++ sources and shaders in this directory (`blobgroup.*`, `blobshape.*`,
`blobrect.*`, `blobinvertedrect.*`, `blobmaterial.*`, `shaders/blob.{vert,frag}`)
are copied, unmodified, from
[caelestia-shell](https://github.com/caelestia-dots/shell)'s
`plugin/src/Caelestia/Blobs` directory.

They are vendored (rather than depending on `caelestia-shell` being installed)
so Airlock no longer needs the whole shell package just for these two QML
types (`BlobGroup`, `BlobRect`) used by the settings and scheme-picker modals'
liquid-metaball popup animation. They are compiled into Airlock's own binary
and registered under the `Astra.Airlock` QML module instead of
`Caelestia.Blobs`.

caelestia-shell is licensed under the GNU General Public License v3.0 (see
the repository root [LICENSE](../../LICENSE), which Airlock itself is also
licensed under). Copyright for this code belongs to the caelestia-dots
project and its contributors.

## Build-compatibility patches

Two small changes from upstream, needed because this is built via
`cxx-qt-build`'s plain `cpp_files`/moc integration instead of CMake's
`qt_add_qml_module` + AUTOMOC:

- `blobrect.cpp`: `std::ranges::any_of` (C++20) backported to `std::any_of`
  (C++17), since cxx-qt-build's cc::Build defaults to C++17.
- `blobshape.hpp`: forward declaration of `BlobGroup` replaced with a full
  `#include "blobgroup.hpp"`. moc's output for each header is compiled here
  as its own standalone translation unit (not folded into one
  `mocs_compilation.cpp` the way CMake's AUTOMOC does it), so the
  `Q_PROPERTY(BlobGroup* group ...)` pointer meta-type needs `BlobGroup` to
  be a complete type in that header, not just forward-declared.
- `register.cpp` (new, not upstream): `BlobGroup`/`BlobRect`/
  `BlobInvertedRect` carry `QML_ELEMENT`, but that only takes effect when
  qmltyperegistrar runs over a `qt_add_qml_module` target's own sources,
  which cxx-qt-build's `cpp_files` doesn't do. This file calls
  `qmlRegisterType` for the three manually instead; see `main.rs`.
