#include "register.hpp"

#include <qqml.h>

#include "blobgroup.hpp"
#include "blobinvertedrect.hpp"
#include "blobrect.hpp"

extern "C" void registerBlobsQmlTypes() {
    qmlRegisterType<caelestia::blobs::BlobGroup>("Astra.Airlock", 1, 0, "BlobGroup");
    qmlRegisterType<caelestia::blobs::BlobRect>("Astra.Airlock", 1, 0, "BlobRect");
    qmlRegisterType<caelestia::blobs::BlobInvertedRect>("Astra.Airlock", 1, 0, "BlobInvertedRect");
}
