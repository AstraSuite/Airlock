#include "schemediscovery.hpp"
#include <QDir>
#include <QFile>
#include <QTextStream>
#include <QJsonDocument>
#include <QJsonObject>
#include <QFileInfo>
#include <QDebug>

SchemeDiscovery::SchemeDiscovery(QObject *parent)
    : QObject(parent)
{
    reload();
}

QStringList SchemeDiscovery::schemeSearchPaths() const
{
    QStringList paths;

    // Search python site-packages directories for caelestia data
    QDir pyDir(QStringLiteral("/usr/lib"));
    const QStringList pyEntries = pyDir.entryList({QStringLiteral("python3*")}, QDir::Dirs);
    for (const QString &py : pyEntries) {
        paths.append(QStringLiteral("/usr/lib/") + py + QStringLiteral("/site-packages/caelestia/data/schemes"));
    }

    paths.append(QStringLiteral("/usr/share/caelestia/schemes"));
    paths.append(QStringLiteral("/usr/local/share/caelestia/schemes"));
    paths.append(QDir::homePath() + QStringLiteral("/.local/share/caelestia/schemes"));
    paths.append(QDir::homePath() + QStringLiteral("/.config/caelestia/schemes"));
    return paths;
}

QVariantMap SchemeDiscovery::getSchemeColours(const QString &name, const QString &flavour, const QString &mode)
{
    QVariantMap result;
    const QString targetMode = mode.isEmpty() ? QStringLiteral("dark") : mode.toLower();

    for (const QString &basePath : schemeSearchPaths()) {
        const QString dirPath = basePath + QStringLiteral("/") + name + QStringLiteral("/") + flavour;
        const QString txtPath = dirPath + QStringLiteral("/") + targetMode + QStringLiteral(".txt");
        const QString jsonPath = dirPath + QStringLiteral("/") + targetMode + QStringLiteral(".json");

        if (QFile::exists(txtPath)) {
            QFile f(txtPath);
            if (f.open(QIODevice::ReadOnly | QIODevice::Text)) {
                QTextStream in(&f);
                while (!in.atEnd()) {
                    const QString line = in.readLine().trimmed();
                    if (line.isEmpty() || line.startsWith(QLatin1Char('#'))) continue;
                    const auto spaceIdx = line.indexOf(QLatin1Char(' '));
                    if (spaceIdx > 0) {
                        const QString k = line.left(spaceIdx).trimmed();
                        const QString v = line.mid(spaceIdx + 1).trimmed();
                        result[k] = v;
                    }
                }
                if (!result.isEmpty()) return result;
            }
        }

        if (QFile::exists(jsonPath)) {
            QFile f(jsonPath);
            if (f.open(QIODevice::ReadOnly)) {
                QJsonDocument doc = QJsonDocument::fromJson(f.readAll());
                if (doc.isObject()) {
                    QJsonObject obj = doc.object();
                    if (obj.contains(QStringLiteral("colours"))) {
                        obj = obj.value(QStringLiteral("colours")).toObject();
                    }
                    for (auto it = obj.begin(); it != obj.end(); ++it) {
                        result[it.key()] = it.value().toVariant();
                    }
                    if (!result.isEmpty()) return result;
                }
            }
        }
    }

    return result;
}

void SchemeDiscovery::reload()
{
    m_schemes.clear();

    QSet<QString> seenKeys;

    for (const QString &basePath : schemeSearchPaths()) {
        QDir baseDir(basePath);
        if (!baseDir.exists()) continue;

        const QStringList schemeDirs = baseDir.entryList(QDir::Dirs | QDir::NoDotAndDotDot);
        for (const QString &sName : schemeDirs) {
            QDir sDir(baseDir.absoluteFilePath(sName));
            const QStringList flavourDirs = sDir.entryList(QDir::Dirs | QDir::NoDotAndDotDot);
            for (const QString &fName : flavourDirs) {
                const QString key = sName + QStringLiteral(":") + fName;
                if (seenKeys.contains(key)) continue;

                QVariantMap colours = getSchemeColours(sName, fName, QStringLiteral("dark"));
                if (colours.isEmpty()) {
                    colours = getSchemeColours(sName, fName, QStringLiteral("light"));
                }

                if (!colours.isEmpty()) {
                    seenKeys.insert(key);

                    QVariantMap item;
                    item[QStringLiteral("name")] = sName;
                    item[QStringLiteral("flavour")] = fName;

                    // Pretty name
                    QString displayName = sName;
                    if (!displayName.isEmpty()) {
                        displayName[0] = displayName[0].toUpper();
                    }
                    item[QStringLiteral("displayName")] = displayName;
                    item[QStringLiteral("colours")] = colours;

                    m_schemes.append(item);
                }
            }
        }
    }

    emit schemesChanged();
}
