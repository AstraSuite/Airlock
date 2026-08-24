#include "schemediscovery.hpp"
#include <QDir>
#include <QFile>
#include <QTextStream>
#include <QJsonDocument>
#include <QJsonObject>
#include <QFileInfo>
#include <QSet>
#include <algorithm>
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
    paths.append(QStringLiteral("/var/cache/astra-airlock/schemes"));
    return paths;
}

QVariantMap SchemeDiscovery::getSchemeColours(const QString &name, const QString &flavour, const QString &mode)
{
    QVariantMap result;
    if (name.isEmpty()) {
        return result;
    }

    const QString targetMode = mode.isEmpty() ? QStringLiteral("dark") : mode.toLower();
    const bool isDynamic = (name.compare(QStringLiteral("dynamic"), Qt::CaseInsensitive) == 0);

    for (const QString &basePath : schemeSearchPaths()) {
        // Try specific flavour path
        QStringList candidates;
        if (!flavour.isEmpty()) {
            candidates.append(basePath + QStringLiteral("/") + name + QStringLiteral("/") + flavour);
        }

        // If sName is dynamic and no specific user flavour was passed (or passed default),
        // search for any available user subfolder in dynamic/
        if (isDynamic && (flavour.isEmpty() || flavour == QStringLiteral("default"))) {
            QDir dynDir(basePath + QStringLiteral("/dynamic"));
            if (dynDir.exists()) {
                const QStringList userDirs = dynDir.entryList(QDir::Dirs | QDir::NoDotAndDotDot);
                for (const QString &uDir : userDirs) {
                    const QString cand = dynDir.absoluteFilePath(uDir);
                    if (!candidates.contains(cand)) {
                        candidates.append(cand);
                    }
                }
            }
        }

        for (const QString &dirPath : candidates) {
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
                            QString v = line.mid(spaceIdx + 1).trimmed();
                            if (!v.startsWith(QLatin1Char('#'))) {
                                v.prepend(QLatin1Char('#'));
                            }
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
                            QString v = it.value().toString();
                            if (!v.isEmpty() && !v.startsWith(QLatin1Char('#'))) {
                                v.prepend(QLatin1Char('#'));
                            }
                            result[it.key()] = v;
                        }
                        if (!result.isEmpty()) return result;
                    }
                }
            }
        }
    }

    // Fallback to default caelestia scheme if dynamic scheme for this specific user was not found
    if (isDynamic && result.isEmpty()) {
        return getSchemeColours(QStringLiteral("caelestia"), QStringLiteral("default"), targetMode);
    }

    return result;
}

void SchemeDiscovery::setActiveUser(const QString &user)
{
    if (m_activeUser != user) {
        m_activeUser = user;
        emit activeUserChanged();
        reload();
    }
}

bool SchemeDiscovery::hasDynamicScheme(const QString &user) const
{
    if (user.isEmpty()) return false;
    for (const QString &basePath : schemeSearchPaths()) {
        const QString dirPath = basePath + QStringLiteral("/dynamic/") + user;
        if (QFile::exists(dirPath + QStringLiteral("/dark.json")) ||
            QFile::exists(dirPath + QStringLiteral("/light.json")) ||
            QFile::exists(dirPath + QStringLiteral("/dark.txt")) ||
            QFile::exists(dirPath + QStringLiteral("/light.txt"))) {
            return true;
        }
    }
    return false;
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
            const bool isDynamic = (sName.compare(QStringLiteral("dynamic"), Qt::CaseInsensitive) == 0);

            if (isDynamic) {
                // If an activeUser is set, only include Dynamic scheme if activeUser has a dynamic scheme on disk
                if (!m_activeUser.isEmpty() && !hasDynamicScheme(m_activeUser)) {
                    continue;
                }
            }

            QDir sDir(baseDir.absoluteFilePath(sName));
            const QStringList flavourDirs = sDir.entryList(QDir::Dirs | QDir::NoDotAndDotDot);
            for (const QString &fName : flavourDirs) {
                const QString key = isDynamic ? QStringLiteral("dynamic:default") : (sName + QStringLiteral(":") + fName);
                if (seenKeys.contains(key)) continue;

                const QString targetFlavour = isDynamic ? (!m_activeUser.isEmpty() ? m_activeUser : fName) : fName;
                QVariantMap colours = getSchemeColours(sName, targetFlavour, QStringLiteral("dark"));
                if (colours.isEmpty()) {
                    colours = getSchemeColours(sName, targetFlavour, QStringLiteral("light"));
                }

                if (!colours.isEmpty()) {
                    seenKeys.insert(key);

                    QVariantMap item;
                    item[QStringLiteral("name")] = isDynamic ? QStringLiteral("dynamic") : sName;
                    item[QStringLiteral("flavour")] = isDynamic ? QStringLiteral("default") : fName;
                    item[QStringLiteral("displayName")] = isDynamic ? QStringLiteral("Dynamic") : (sName.isEmpty() ? sName : (sName[0].toUpper() + sName.mid(1)));
                    item[QStringLiteral("colours")] = colours;

                    m_schemes.append(item);
                }
            }
        }
    }

    // Sort schemes alphabetically by name + flavour
    std::sort(m_schemes.begin(), m_schemes.end(), [](const QVariant &a, const QVariant &b) {
        const QVariantMap ma = a.toMap();
        const QVariantMap mb = b.toMap();
        const QString ka = ma.value(QStringLiteral("name")).toString() + ma.value(QStringLiteral("flavour")).toString();
        const QString kb = mb.value(QStringLiteral("name")).toString() + mb.value(QStringLiteral("flavour")).toString();
        return ka.localeAwareCompare(kb) < 0;
    });

    emit schemesChanged();
}
