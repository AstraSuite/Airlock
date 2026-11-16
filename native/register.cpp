#include "register.hpp"

#include <QQmlEngine>
#include <qqml.h>

#include "blobs/blobgroup.hpp"
#include "blobs/blobinvertedrect.hpp"
#include "blobs/blobrect.hpp"
#include "theme/tokens.hpp"

extern "C" void registerNativeQmlTypes() {
    qmlRegisterType<caelestia::blobs::BlobGroup>("Astra.Airlock", 1, 0, "BlobGroup");
    qmlRegisterType<caelestia::blobs::BlobRect>("Astra.Airlock", 1, 0, "BlobRect");
    qmlRegisterType<caelestia::blobs::BlobInvertedRect>("Astra.Airlock", 1, 0, "BlobInvertedRect");

    auto* tokens = airlock::config::TokensSingleton::instance();
    QQmlEngine::setObjectOwnership(tokens, QQmlEngine::CppOwnership);
    qmlRegisterSingletonInstance("Astra.Airlock", 1, 0, "Tokens", tokens);
}
