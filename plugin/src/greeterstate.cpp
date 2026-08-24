#include "greeterstate.hpp"
#include <QFileInfo>
#include <QDir>
#include <QFile>
#include <QJsonDocument>
#include <QJsonObject>
#include <QSettings>
#include <QDebug>

GreeterState *GreeterState::s_instance = nullptr;

GreeterState *GreeterState::instance()
{
    if (!s_instance) {
        s_instance = new GreeterState();
    }
    return s_instance;
}

GreeterState::GreeterState(QObject *parent)
    : QObject(parent)
    , m_watcher(new QFileSystemWatcher(this))
{
    if (!s_instance) {
        s_instance = this;
    }

    loadFromDisk();

    const QString path = stateFilePath();
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

GreeterState::~GreeterState()
{
    if (s_instance == this) {
        s_instance = nullptr;
    }
}

QString GreeterState::stateFilePath() const
{
    // 1. Look for existing writable candidate files
    for (const QString &p : candidatePaths()) {
        QFileInfo fi(p);
        if (fi.exists() && fi.isWritable()) {
            return p;
        }
    }
    // 2. Look for writable candidate directory to create new file
    for (const QString &p : candidatePaths()) {
        QFileInfo fi(p);
        QDir dir = fi.dir();
        if (dir.exists()) {
            QFileInfo dirFi(dir.absolutePath());
            if (dirFi.isWritable()) {
                return p;
            }
        } else if (dir.mkpath(QStringLiteral("."))) {
            QFileInfo dirFi(dir.absolutePath());
            if (dirFi.isWritable()) {
                return p;
            }
        }
    }
    // 3. Fallback to existing readable file if read-only environment
    for (const QString &p : candidatePaths()) {
        if (QFile::exists(p)) {
            return p;
        }
    }
    return QDir::tempPath() + QStringLiteral("/astra-airlock.json");
}

void GreeterState::setActiveUser(const QString &user)
{
    if (user.isEmpty() || m_activeUser == user) return;

    if (!m_activeUser.isEmpty()) {
        QJsonObject cur;
        cur[QStringLiteral("use12Hour")] = m_use12Hour;
        cur[QStringLiteral("avatarShape")] = m_avatarShape;
        cur[QStringLiteral("avatarShapeName")] = m_avatarShapeName;
        cur[QStringLiteral("lavaLampEnabled")] = m_lavaLampEnabled;
        cur[QStringLiteral("skipClockPage")] = m_skipClockPage;
        cur[QStringLiteral("schemeName")] = m_schemeName;
        cur[QStringLiteral("schemeFlavour")] = m_schemeFlavour;
        cur[QStringLiteral("schemeMode")] = m_schemeMode;
        m_userSettings[m_activeUser] = cur;
    }

    m_activeUser = user;

    if (m_userSettings.contains(user)) {
        QJsonObject u = m_userSettings.value(user).toObject();
        if (u.contains(QStringLiteral("use12Hour"))) m_use12Hour = u.value(QStringLiteral("use12Hour")).toBool(m_use12Hour);
        if (u.contains(QStringLiteral("avatarShape"))) m_avatarShape = u.value(QStringLiteral("avatarShape")).toInt(m_avatarShape);
        if (u.contains(QStringLiteral("avatarShapeName"))) m_avatarShapeName = u.value(QStringLiteral("avatarShapeName")).toString(m_avatarShapeName);
        if (u.contains(QStringLiteral("lavaLampEnabled"))) m_lavaLampEnabled = u.value(QStringLiteral("lavaLampEnabled")).toBool(m_lavaLampEnabled);
        if (u.contains(QStringLiteral("skipClockPage"))) m_skipClockPage = u.value(QStringLiteral("skipClockPage")).toBool(m_skipClockPage);
        if (u.contains(QStringLiteral("schemeName"))) m_schemeName = u.value(QStringLiteral("schemeName")).toString(m_schemeName);
        if (u.contains(QStringLiteral("schemeFlavour"))) m_schemeFlavour = u.value(QStringLiteral("schemeFlavour")).toString(m_schemeFlavour);
        if (u.contains(QStringLiteral("schemeMode"))) m_schemeMode = u.value(QStringLiteral("schemeMode")).toString(m_schemeMode);
    }

    // Fallback if dynamic scheme is selected but user has no dynamic scheme on disk
    if (m_schemeName.compare(QStringLiteral("dynamic"), Qt::CaseInsensitive) == 0) {
        bool hasDyn = false;
        for (const QString &basePath : {QStringLiteral("/var/cache/astra-airlock/schemes"), QStringLiteral("/usr/share/caelestia/schemes")}) {
            const QString p = basePath + QStringLiteral("/dynamic/") + user;
            if (QFile::exists(p + QStringLiteral("/dark.json")) || QFile::exists(p + QStringLiteral("/light.json"))) {
                hasDyn = true;
                break;
            }
        }
        if (!hasDyn) {
            m_schemeName = QStringLiteral("caelestia");
            m_schemeFlavour = QStringLiteral("default");
        }
    }

    emit activeUserChanged();
    emit use12HourChanged();
    emit avatarShapeChanged();
    emit avatarShapeNameChanged();
    emit lavaLampEnabledChanged();
    emit skipClockPageChanged();
    emit schemeNameChanged();
    emit schemeFlavourChanged();
    emit schemeModeChanged();

    save();
}

void GreeterState::loadFromDisk()
{
    const QString path = stateFilePath();
    if (path.isEmpty()) return;

    QFile f(path);
    if (!f.open(QIODevice::ReadOnly)) return;

    QJsonDocument doc = QJsonDocument::fromJson(f.readAll());
    if (!doc.isObject()) return;

    QJsonObject root = doc.object();

    if (root.contains(QStringLiteral("lastUser"))) {
        m_lastUser = root.value(QStringLiteral("lastUser")).toString();
    }
    if (m_activeUser.isEmpty() && !m_lastUser.isEmpty()) {
        m_activeUser = m_lastUser;
    }
    if (root.contains(QStringLiteral("userSessions"))) {
        m_userSessions = root.value(QStringLiteral("userSessions")).toObject();
    }
    if (root.contains(QStringLiteral("userSettings"))) {
        m_userSettings = root.value(QStringLiteral("userSettings")).toObject();
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
    if (s.contains(QStringLiteral("skipClockPage"))) {
        m_skipClockPage = s.value(QStringLiteral("skipClockPage")).toBool(m_skipClockPage);
    }

    if (s.contains(QStringLiteral("schemeName"))) {
        m_schemeName = s.value(QStringLiteral("schemeName")).toString(m_schemeName);
    }
    if (s.contains(QStringLiteral("schemeFlavour"))) {
        m_schemeFlavour = s.value(QStringLiteral("schemeFlavour")).toString(m_schemeFlavour);
    } else if (s.contains(QStringLiteral("flavour"))) {
        m_schemeFlavour = s.value(QStringLiteral("flavour")).toString(m_schemeFlavour);
    }
    if (s.contains(QStringLiteral("schemeMode"))) {
        m_schemeMode = s.value(QStringLiteral("schemeMode")).toString(m_schemeMode);
    } else if (s.contains(QStringLiteral("mode"))) {
        m_schemeMode = s.value(QStringLiteral("mode")).toString(m_schemeMode);
    }

    if (!m_activeUser.isEmpty() && m_userSettings.contains(m_activeUser)) {
        QJsonObject u = m_userSettings.value(m_activeUser).toObject();
        if (u.contains(QStringLiteral("use12Hour"))) m_use12Hour = u.value(QStringLiteral("use12Hour")).toBool(m_use12Hour);
        if (u.contains(QStringLiteral("avatarShape"))) m_avatarShape = u.value(QStringLiteral("avatarShape")).toInt(m_avatarShape);
        if (u.contains(QStringLiteral("avatarShapeName"))) m_avatarShapeName = u.value(QStringLiteral("avatarShapeName")).toString(m_avatarShapeName);
        if (u.contains(QStringLiteral("lavaLampEnabled"))) m_lavaLampEnabled = u.value(QStringLiteral("lavaLampEnabled")).toBool(m_lavaLampEnabled);
        if (u.contains(QStringLiteral("skipClockPage"))) m_skipClockPage = u.value(QStringLiteral("skipClockPage")).toBool(m_skipClockPage);
        if (u.contains(QStringLiteral("schemeName"))) m_schemeName = u.value(QStringLiteral("schemeName")).toString(m_schemeName);
        if (u.contains(QStringLiteral("schemeFlavour"))) m_schemeFlavour = u.value(QStringLiteral("schemeFlavour")).toString(m_schemeFlavour);
        if (u.contains(QStringLiteral("schemeMode"))) m_schemeMode = u.value(QStringLiteral("schemeMode")).toString(m_schemeMode);
    }

    // Fallback if dynamic scheme is selected but active user has no dynamic scheme on disk
    if (!m_activeUser.isEmpty() && m_schemeName.compare(QStringLiteral("dynamic"), Qt::CaseInsensitive) == 0) {
        bool hasDyn = false;
        for (const QString &basePath : {QStringLiteral("/var/cache/astra-airlock/schemes"), QStringLiteral("/usr/share/caelestia/schemes")}) {
            const QString p = basePath + QStringLiteral("/dynamic/") + m_activeUser;
            if (QFile::exists(p + QStringLiteral("/dark.json")) || QFile::exists(p + QStringLiteral("/light.json"))) {
                hasDyn = true;
                break;
            }
        }
        if (!hasDyn) {
            m_schemeName = QStringLiteral("caelestia");
            m_schemeFlavour = QStringLiteral("default");
        }
    }
}

void GreeterState::save()
{
    m_isSaving = true;
    const QString targetPath = stateFilePath();

    if (!m_activeUser.isEmpty()) {
        QJsonObject cur;
        cur[QStringLiteral("use12Hour")] = m_use12Hour;
        cur[QStringLiteral("avatarShape")] = m_avatarShape;
        cur[QStringLiteral("avatarShapeName")] = m_avatarShapeName;
        cur[QStringLiteral("lavaLampEnabled")] = m_lavaLampEnabled;
        cur[QStringLiteral("skipClockPage")] = m_skipClockPage;
        cur[QStringLiteral("schemeName")] = m_schemeName;
        cur[QStringLiteral("schemeFlavour")] = m_schemeFlavour;
        cur[QStringLiteral("schemeMode")] = m_schemeMode;
        m_userSettings[m_activeUser] = cur;
    }

    QJsonObject root;
    if (!m_lastUser.isEmpty()) {
        root[QStringLiteral("lastUser")] = m_lastUser;
    }
    root[QStringLiteral("userSessions")] = m_userSessions;
    root[QStringLiteral("userSettings")] = m_userSettings;

    QJsonObject s;
    s[QStringLiteral("use12Hour")] = m_use12Hour;
    s[QStringLiteral("use12h")] = m_use12Hour;
    s[QStringLiteral("avatarShape")] = m_avatarShape;
    s[QStringLiteral("avatarShapeName")] = m_avatarShapeName;
    s[QStringLiteral("lavaLampEnabled")] = m_lavaLampEnabled;
    s[QStringLiteral("skipClockPage")] = m_skipClockPage;
    s[QStringLiteral("schemeName")] = m_schemeName;
    s[QStringLiteral("schemeFlavour")] = m_schemeFlavour;
    s[QStringLiteral("schemeMode")] = m_schemeMode;

    root[QStringLiteral("settings")] = s;

    QFileInfo fi(targetPath);
    QDir().mkpath(fi.absolutePath());

    QFile f(targetPath);
    if (f.open(QIODevice::WriteOnly | QIODevice::Truncate)) {
        f.write(QJsonDocument(root).toJson(QJsonDocument::Indented));
        f.flush();
        f.close();
        QFile::setPermissions(targetPath, QFileDevice::ReadOwner | QFileDevice::WriteOwner | QFileDevice::ReadGroup | QFileDevice::ReadOther);
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
    emit skipClockPageChanged();
    emit lastUserChanged();
    emit schemeNameChanged();
    emit schemeFlavourChanged();
    emit schemeModeChanged();
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

void GreeterState::setSkipClockPage(bool v)
{
    if (m_skipClockPage == v) return;
    m_skipClockPage = v;
    emit skipClockPageChanged();
    save();
}

void GreeterState::setLastUser(const QString &v)
{
    if (m_lastUser == v) return;
    m_lastUser = v;
    emit lastUserChanged();
    save();
}

void GreeterState::setSchemeName(const QString &v)
{
    if (m_schemeName == v) return;
    m_schemeName = v;
    emit schemeNameChanged();
    save();
}

void GreeterState::setSchemeFlavour(const QString &v)
{
    if (m_schemeFlavour == v) return;
    m_schemeFlavour = v;
    emit schemeFlavourChanged();
    save();
}

void GreeterState::setSchemeMode(const QString &v)
{
    if (m_schemeMode == v) return;
    m_schemeMode = v;
    emit schemeModeChanged();
    save();
}

void GreeterState::setScheme(const QString &name, const QString &flavour, const QString &mode)
{
    bool changed = false;
    if (!name.isEmpty() && m_schemeName != name) {
        m_schemeName = name;
        emit schemeNameChanged();
        changed = true;
    }
    if (!flavour.isEmpty() && m_schemeFlavour != flavour) {
        m_schemeFlavour = flavour;
        emit schemeFlavourChanged();
        changed = true;
    }
    if (!mode.isEmpty() && m_schemeMode != mode) {
        m_schemeMode = mode;
        emit schemeModeChanged();
        changed = true;
    }
    if (changed) {
        save();
    }
}

QString GreeterState::getLastSession(const QString &username)
{
    const QString user = username.isEmpty() ? m_lastUser : username;
    if (!user.isEmpty()) {
        if (m_userSessions.contains(user)) {
            const QString sess = m_userSessions.value(user).toString();
            if (!sess.isEmpty()) return sess;
        }

        // Check AccountsService
        const QString accPath = QStringLiteral("/var/lib/AccountsService/users/") + user;
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
    if (username.isEmpty() || sessionKey.isEmpty()) {
        return;
    }
    bool changed = false;
    if (m_lastUser != username) {
        m_lastUser = username;
        emit lastUserChanged();
        changed = true;
    }
    if (m_userSessions.value(username).toString() != sessionKey) {
        m_userSessions[username] = sessionKey;
        changed = true;
    }
    if (changed) {
        save();
    }
}
