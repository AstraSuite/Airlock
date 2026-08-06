#pragma once

#include <QObject>
#include <QString>
#include <QStringList>
#include <QJsonObject>
#include <QJsonDocument>
#include <QFile>
#include <QFileInfo>
#include <QDir>
#include <QFileSystemWatcher>
#include <QSettings>
#include <QDebug>
#include <qqmlintegration.h>

class GreeterState : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    Q_PROPERTY(bool use12Hour READ use12Hour WRITE setUse12Hour NOTIFY use12HourChanged)
    Q_PROPERTY(int avatarShape READ avatarShape WRITE setAvatarShape NOTIFY avatarShapeChanged)
    Q_PROPERTY(QString avatarShapeName READ avatarShapeName WRITE setAvatarShapeName NOTIFY avatarShapeNameChanged)
    Q_PROPERTY(bool lavaLampEnabled READ lavaLampEnabled WRITE setLavaLampEnabled NOTIFY lavaLampEnabledChanged)
    Q_PROPERTY(QString lastUser READ lastUser WRITE setLastUser NOTIFY lastUserChanged)
    Q_PROPERTY(QString stateFilePath READ stateFilePath CONSTANT)

public:
    explicit GreeterState(QObject *parent = nullptr);
    ~GreeterState() override = default;

    static QStringList candidatePaths() {
        return {
            QStringLiteral("/var/cache/caelestia-greeter/greeter.json"),
            QStringLiteral("/var/lib/caelestia-greeter/greeter.json"),
            QDir::homePath() + QStringLiteral("/.config/caelestia/greeter.json"),
            QDir::homePath() + QStringLiteral("/.cache/caelestia-greeter/greeter.json"),
            QDir::tempPath() + QStringLiteral("/caelestia-greeter.json")
        };
    }

    bool use12Hour() const { return m_use12Hour; }
    void setUse12Hour(bool v);

    int avatarShape() const { return m_avatarShape; }
    void setAvatarShape(int v);

    QString avatarShapeName() const { return m_avatarShapeName; }
    void setAvatarShapeName(const QString &v);

    bool lavaLampEnabled() const { return m_lavaLampEnabled; }
    void setLavaLampEnabled(bool v);

    QString lastUser() const { return m_lastUser; }
    void setLastUser(const QString &v);

    QString stateFilePath() const;

    Q_INVOKABLE void save();
    Q_INVOKABLE void reload();

    Q_INVOKABLE QString getLastSession(const QString &username = QString());
    Q_INVOKABLE void saveSession(const QString &username, const QString &sessionKey);

signals:
    void use12HourChanged();
    void avatarShapeChanged();
    void avatarShapeNameChanged();
    void lavaLampEnabledChanged();
    void lastUserChanged();

private:
    void loadFromDisk();
    QString findWritablePath() const;
    QString findReadablePath() const;

    bool m_use12Hour{false};
    int m_avatarShape{19}; // Default Cookie9Sided
    QString m_avatarShapeName{QStringLiteral("Cookie 9-Sided")};
    bool m_lavaLampEnabled{true};
    QString m_lastUser;
    QJsonObject m_userSessions;

    QFileSystemWatcher *m_watcher{nullptr};
    bool m_isSaving{false};
};

class GreeterStateHelper {
public:
    static QString getLastUser() {
        GreeterState s;
        return s.lastUser();
    }

    static QString getLastSession(const QString &username = QString()) {
        GreeterState s;
        return s.getLastSession(username);
    }

    static void saveSession(const QString &username, const QString &sessionKey) {
        GreeterState s;
        s.saveSession(username, sessionKey);
    }
};
