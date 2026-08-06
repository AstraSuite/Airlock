#include "sessiondiscovery.hpp"
#include "greeterstate.hpp"
#include <QDir>
#include <QFileInfo>
#include <QSettings>
#include <QDebug>

SessionDiscovery::SessionDiscovery(QObject *parent)
    : QObject(parent)
{
    reload();
}

void SessionDiscovery::reload()
{
    m_sessions.clear();
    m_defaultIndex = 0;

    parseDirectory(QStringLiteral("/usr/share/wayland-sessions"), QStringLiteral("Wayland"));
    parseDirectory(QStringLiteral("/usr/share/xsessions"), QStringLiteral("X11"));

    if (m_sessions.isEmpty()) {
        // Fallback default session if no desktop files found
        QVariantMap fallback;
        fallback[QStringLiteral("name")] = QStringLiteral("Hyprland");
        fallback[QStringLiteral("exec")] = QStringLiteral("Hyprland");
        fallback[QStringLiteral("type")] = QStringLiteral("Wayland");
        fallback[QStringLiteral("key")] = QStringLiteral("hyprland");
        fallback[QStringLiteral("file")] = QStringLiteral("hyprland.desktop");
        m_sessions.append(fallback);
    }

    // Default to last used session for the last active user
    const QString lastUser = GreeterStateHelper::getLastUser();
    const QString lastSessionKey = GreeterStateHelper::getLastSession(lastUser);

    int foundIdx = -1;
    if (!lastSessionKey.isEmpty()) {
        foundIdx = indexOfSession(lastSessionKey);
    }

    if (foundIdx >= 0 && foundIdx < m_sessions.size()) {
        m_defaultIndex = foundIdx;
    } else {
        // Fallback priority: Hyprland -> First Wayland session -> Index 0
        int hyprIdx = -1;
        int firstWaylandIdx = -1;
        for (int i = 0; i < m_sessions.size(); ++i) {
            const QVariantMap item = m_sessions.at(i).toMap();
            const QString key = item.value(QStringLiteral("key")).toString().toLower();
            const QString type = item.value(QStringLiteral("type")).toString();

            if (key.contains(QStringLiteral("hyprland")) && hyprIdx == -1) {
                hyprIdx = i;
            }
            if (type == QStringLiteral("Wayland") && firstWaylandIdx == -1) {
                firstWaylandIdx = i;
            }
        }

        if (hyprIdx != -1) {
            m_defaultIndex = hyprIdx;
        } else if (firstWaylandIdx != -1) {
            m_defaultIndex = firstWaylandIdx;
        } else {
            m_defaultIndex = 0;
        }
    }

    emit sessionsChanged();
    emit defaultIndexChanged();
}

int SessionDiscovery::indexOfSession(const QString &sessionKey)
{
    if (sessionKey.isEmpty()) {
        return -1;
    }

    const QString cleanKey = sessionKey.toLower().remove(QStringLiteral(".desktop"));

    for (int i = 0; i < m_sessions.size(); ++i) {
        const QVariantMap item = m_sessions.at(i).toMap();
        const QString k = item.value(QStringLiteral("key")).toString().toLower();
        const QString f = item.value(QStringLiteral("file")).toString().toLower().remove(QStringLiteral(".desktop"));
        const QString n = item.value(QStringLiteral("name")).toString().toLower();
        const QString e = item.value(QStringLiteral("exec")).toString().toLower();

        if (k == cleanKey || f == cleanKey || n == cleanKey || e == cleanKey || k.startsWith(cleanKey)) {
            return i;
        }
    }
    return -1;
}

int SessionDiscovery::sessionIndexForUser(const QString &username)
{
    if (username.isEmpty()) {
        return m_defaultIndex;
    }

    const QString lastSessionKey = GreeterStateHelper::getLastSession(username);
    if (!lastSessionKey.isEmpty()) {
        int idx = indexOfSession(lastSessionKey);
        if (idx >= 0) {
            return idx;
        }
    }
    return m_defaultIndex;
}

void SessionDiscovery::saveLastSession(const QString &username, const QString &sessionKey)
{
    GreeterStateHelper::saveSession(username, sessionKey);
}

void SessionDiscovery::parseDirectory(const QString &dirPath, const QString &sessionType)
{
    QDir dir(dirPath);
    if (!dir.exists()) {
        return;
    }

    const QStringList fileNames = dir.entryList({QStringLiteral("*.desktop")}, QDir::Files);
    for (const QString &fileName : fileNames) {
        const QString fullPath = dir.absoluteFilePath(fileName);
        QSettings desktopFile(fullPath, QSettings::IniFormat);
        desktopFile.beginGroup(QStringLiteral("Desktop Entry"));

        if (desktopFile.value(QStringLiteral("NoDisplay"), false).toBool()) {
            continue;
        }

        QString name = desktopFile.value(QStringLiteral("Name")).toString();
        QString exec = desktopFile.value(QStringLiteral("Exec")).toString();

        if (name.isEmpty()) {
            name = QFileInfo(fileName).completeBaseName();
        }
        if (exec.isEmpty()) {
            exec = name.toLower();
        }

        QVariantMap session;
        session[QStringLiteral("name")] = name;
        session[QStringLiteral("exec")] = exec;
        session[QStringLiteral("type")] = sessionType;
        session[QStringLiteral("file")] = fileName;
        session[QStringLiteral("key")] = QFileInfo(fileName).completeBaseName().toLower();

        // Avoid exact duplicate keys
        bool duplicate = false;
        for (const QVariant &item : m_sessions) {
            if (item.toMap().value(QStringLiteral("key")) == session.value(QStringLiteral("key"))) {
                duplicate = true;
                break;
            }
        }

        if (!duplicate) {
            m_sessions.append(session);
        }
    }
}
