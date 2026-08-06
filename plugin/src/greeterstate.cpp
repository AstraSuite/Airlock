#include "greeterstate.hpp"
#include <QFileInfo>
#include <QDir>
#include <QFile>
#include <QJsonDocument>
#include <QJsonObject>
#include <QSettings>
#include <QDebug>

GreeterState::GreeterState(QObject *parent)
    : QObject(parent)
    , m_watcher(new QFileSystemWatcher(this))
{
    loadFromDisk();

    const QString path = findReadablePath();
    if (!path.isEmpty() && QFile::exists(path)) {
        m_watcher->addPath(path);
    }

    connect(m_watcher, &QFileSystemWatcher::fileChanged, this, [this](const QString &changedPath) {
        if (!m_isSaving) {
            reload();
        }
        if (QFile::exists(changedPath) && !m_watcher->files().contains(changedPath)) {
            m_watcher->addPath(changedPath);
        }
    });
}

QString GreeterState::findReadablePath() const
{
    for (const QString &p : candidatePaths()) {
        if (QFile::exists(p)) {
            return p;
        }
    }
    return QString();
}

QString GreeterState::findWritablePath() const
{
    for (const QString &p : candidatePaths()) {
        QFileInfo fi(p);
        QDir dir = fi.dir();
        if (dir.exists()) {
            QFileInfo dirFi(dir.absolutePath());
            if (dirFi.isWritable()) {
                return p;
            }
        } else {
            // Try creating the directory
            if (dir.mkpath(QStringLiteral("."))) {
                QFileInfo dirFi(dir.absolutePath());
                if (dirFi.isWritable()) {
                    return p;
                }
            }
        }
    }
    return QDir::tempPath() + QStringLiteral("/caelestia-greeter.json");
}

QString GreeterState::stateFilePath() const
{
    const QString readable = findReadablePath();
    return readable.isEmpty() ? findWritablePath() : readable;
}

void GreeterState::loadFromDisk()
{
    const QString path = findReadablePath();
    if (path.isEmpty()) return;

    QFile f(path);
    if (!f.open(QIODevice::ReadOnly)) return;

    QJsonDocument doc = QJsonDocument::fromJson(f.readAll());
    if (!doc.isObject()) return;

    QJsonObject root = doc.object();

    if (root.contains(QStringLiteral("lastUser"))) {
        m_lastUser = root.value(QStringLiteral("lastUser")).toString();
    }
    if (root.contains(QStringLiteral("userSessions"))) {
        m_userSessions = root.value(QStringLiteral("userSessions")).toObject();
    }

    QJsonObject s = root.contains(QStringLiteral("settings"))
        ? root.value(QStringLiteral("settings")).toObject()
        : root;

    if (s.contains(QStringLiteral("use12Hour"))) {
        m_use12Hour = s.value(QStringLiteral("use12Hour")).toBool(m_use12Hour);
    } else if (s.contains(QStringLiteral("use12h"))) {
        m_use12Hour = s.value(QStringLiteral("use12h")).toBool(m_use12Hour);
    }

    if (s.contains(QStringLiteral("avatarShape"))) {
        m_avatarShape = s.value(QStringLiteral("avatarShape")).toInt(m_avatarShape);
    }
    if (s.contains(QStringLiteral("avatarShapeName"))) {
        m_avatarShapeName = s.value(QStringLiteral("avatarShapeName")).toString(m_avatarShapeName);
    }
    if (s.contains(QStringLiteral("lavaLampEnabled"))) {
        m_lavaLampEnabled = s.value(QStringLiteral("lavaLampEnabled")).toBool(m_lavaLampEnabled);
    }
}

void GreeterState::save()
{
    m_isSaving = true;
    const QString targetPath = findWritablePath();

    QJsonObject root;
    if (!m_lastUser.isEmpty()) {
        root[QStringLiteral("lastUser")] = m_lastUser;
    }
    root[QStringLiteral("userSessions")] = m_userSessions;

    QJsonObject s;
    s[QStringLiteral("use12Hour")] = m_use12Hour;
    s[QStringLiteral("use12h")] = m_use12Hour;
    s[QStringLiteral("avatarShape")] = m_avatarShape;
    s[QStringLiteral("avatarShapeName")] = m_avatarShapeName;
    s[QStringLiteral("lavaLampEnabled")] = m_lavaLampEnabled;

    root[QStringLiteral("settings")] = s;

    QFileInfo fi(targetPath);
    QDir().mkpath(fi.absolutePath());

    QFile f(targetPath);
    if (f.open(QIODevice::WriteOnly | QIODevice::Truncate)) {
        f.write(QJsonDocument(root).toJson(QJsonDocument::Indented));
        f.close();
    }

    if (m_watcher && !m_watcher->files().contains(targetPath) && QFile::exists(targetPath)) {
        m_watcher->addPath(targetPath);
    }

    m_isSaving = false;
}

void GreeterState::reload()
{
    loadFromDisk();
    emit use12HourChanged();
    emit avatarShapeChanged();
    emit avatarShapeNameChanged();
    emit lavaLampEnabledChanged();
    emit lastUserChanged();
}

void GreeterState::setUse12Hour(bool v)
{
    if (m_use12Hour == v) return;
    m_use12Hour = v;
    emit use12HourChanged();
    save();
}

void GreeterState::setAvatarShape(int v)
{
    if (m_avatarShape == v) return;
    m_avatarShape = v;
    emit avatarShapeChanged();
    save();
}

void GreeterState::setAvatarShapeName(const QString &v)
{
    if (m_avatarShapeName == v) return;
    m_avatarShapeName = v;
    emit avatarShapeNameChanged();
    save();
}

void GreeterState::setLavaLampEnabled(bool v)
{
    if (m_lavaLampEnabled == v) return;
    m_lavaLampEnabled = v;
    emit lavaLampEnabledChanged();
    save();
}

void GreeterState::setLastUser(const QString &v)
{
    if (m_lastUser == v) return;
    m_lastUser = v;
    emit lastUserChanged();
    save();
}

QString GreeterState::getLastSession(const QString &username)
{
    if (!username.isEmpty()) {
        if (m_userSessions.contains(username)) {
            const QString sess = m_userSessions.value(username).toString();
            if (!sess.isEmpty()) return sess;
        }

        // Check AccountsService
        const QString accPath = QStringLiteral("/var/lib/AccountsService/users/") + username;
        if (QFile::exists(accPath)) {
            QSettings accSettings(accPath, QSettings::IniFormat);
            accSettings.beginGroup(QStringLiteral("User"));
            QString sess = accSettings.value(QStringLiteral("Session")).toString();
            if (sess.isEmpty()) {
                sess = accSettings.value(QStringLiteral("XSession")).toString();
            }
            if (!sess.isEmpty()) return sess;
        }
    }
    return QString();
}

void GreeterState::saveSession(const QString &username, const QString &sessionKey)
{
    if (!username.isEmpty()) {
        m_lastUser = username;
        m_userSessions[username] = sessionKey;
        emit lastUserChanged();
    }
    save();
}
