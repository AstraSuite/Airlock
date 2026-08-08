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

    Q_PROPERTY(QString activeUser READ activeUser WRITE setActiveUser NOTIFY activeUserChanged)
    Q_PROPERTY(bool use12Hour READ use12Hour WRITE setUse12Hour NOTIFY use12HourChanged)
    Q_PROPERTY(int avatarShape READ avatarShape WRITE setAvatarShape NOTIFY avatarShapeChanged)
    Q_PROPERTY(QString avatarShapeName READ avatarShapeName WRITE setAvatarShapeName NOTIFY avatarShapeNameChanged)
    Q_PROPERTY(bool lavaLampEnabled READ lavaLampEnabled WRITE setLavaLampEnabled NOTIFY lavaLampEnabledChanged)
    Q_PROPERTY(bool skipClockPage READ skipClockPage WRITE setSkipClockPage NOTIFY skipClockPageChanged)
    Q_PROPERTY(QString lastUser READ lastUser WRITE setLastUser NOTIFY lastUserChanged)
    Q_PROPERTY(QString schemeName READ schemeName WRITE setSchemeName NOTIFY schemeNameChanged)
    Q_PROPERTY(QString schemeFlavour READ schemeFlavour WRITE setSchemeFlavour NOTIFY schemeFlavourChanged)
    Q_PROPERTY(QString schemeMode READ schemeMode WRITE setSchemeMode NOTIFY schemeModeChanged)
    Q_PROPERTY(QString stateFilePath READ stateFilePath CONSTANT)

public:
    explicit GreeterState(QObject *parent = nullptr);
    ~GreeterState() override;

    static GreeterState *instance();

    static QStringList candidatePaths() {
        return {
            QStringLiteral("/var/cache/caelestia-greeter/greeter.json"),
            QStringLiteral("/var/lib/caelestia-greeter/greeter.json"),
            QDir::homePath() + QStringLiteral("/.config/caelestia/greeter.json"),
            QDir::homePath() + QStringLiteral("/.cache/caelestia-greeter/greeter.json"),
            QDir::tempPath() + QStringLiteral("/caelestia-greeter.json")
        };
    }

    QString activeUser() const { return m_activeUser; }
    Q_INVOKABLE void setActiveUser(const QString &user);

    bool use12Hour() const { return m_use12Hour; }
    void setUse12Hour(bool v);

    int avatarShape() const { return m_avatarShape; }
    void setAvatarShape(int v);

    QString avatarShapeName() const { return m_avatarShapeName; }
    void setAvatarShapeName(const QString &v);

    bool lavaLampEnabled() const { return m_lavaLampEnabled; }
    void setLavaLampEnabled(bool v);

    bool skipClockPage() const { return m_skipClockPage; }
    void setSkipClockPage(bool v);

    QString lastUser() const { return m_lastUser; }
    void setLastUser(const QString &v);

    QString schemeName() const { return m_schemeName; }
    void setSchemeName(const QString &v);

    QString schemeFlavour() const { return m_schemeFlavour; }
    void setSchemeFlavour(const QString &v);

    QString schemeMode() const { return m_schemeMode; }
    void setSchemeMode(const QString &v);

    QString stateFilePath() const;

    Q_INVOKABLE void setScheme(const QString &name, const QString &flavour, const QString &mode);
    Q_INVOKABLE void save();
    Q_INVOKABLE void reload();

    Q_INVOKABLE QString getLastSession(const QString &username = QString());
    Q_INVOKABLE void saveSession(const QString &username, const QString &sessionKey);

signals:
    void activeUserChanged();
    void use12HourChanged();
    void avatarShapeChanged();
    void avatarShapeNameChanged();
    void lavaLampEnabledChanged();
    void skipClockPageChanged();
    void lastUserChanged();
    void schemeNameChanged();
    void schemeFlavourChanged();
    void schemeModeChanged();

private:
    void loadFromDisk();
    void updateActiveUserSettings(const QString &oldUser);

    QString m_activeUser;
    bool m_use12Hour{false};
    int m_avatarShape{19}; // Default Cookie9Sided
    QString m_avatarShapeName{QStringLiteral("Cookie 9-Sided")};
    bool m_lavaLampEnabled{true};
    bool m_skipClockPage{false};
    QString m_lastUser;
    QString m_schemeName{QStringLiteral("caelestia")};
    QString m_schemeFlavour{QStringLiteral("default")};
    QString m_schemeMode{QStringLiteral("dark")};
    QJsonObject m_userSessions;
    QJsonObject m_userSettings;

    QFileSystemWatcher *m_watcher{nullptr};
    bool m_isSaving{false};

    static GreeterState *s_instance;
};

class GreeterStateHelper {
public:
    static QString getLastUser() {
        return GreeterState::instance()->lastUser();
    }

    static QString getLastSession(const QString &username = QString()) {
        return GreeterState::instance()->getLastSession(username);
    }

    static void saveSession(const QString &username, const QString &sessionKey) {
        GreeterState::instance()->saveSession(username, sessionKey);
    }
};
