#pragma once

#include <QObject>
#include <QString>
#include <QStringList>
#include <QVariantList>
#include <QtDBus/QDBusConnection>
#include <qqmlintegration.h>
#include <optional>

class SessionManager : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

public:
    explicit SessionManager(QObject* parent = nullptr);
    ~SessionManager() override = default;

    Q_INVOKABLE void logout();
    Q_INVOKABLE void suspend();
    Q_INVOKABLE void suspendThenHibernate();
    Q_INVOKABLE void hibernate();
    Q_INVOKABLE void poweroff();
    Q_INVOKABLE void reboot();
    Q_INVOKABLE void rebootToUefi();
    Q_INVOKABLE void rebootToFirmware();
    Q_INVOKABLE bool canRebootToUefi() const;

    Q_INVOKABLE bool exec(const QStringList& command);

signals:
    void aboutToSleep();
    void resumed();
    void lockRequested();
    void unlockRequested();

private slots:
    void handlePrepareForSleep(bool sleep);
    void handleLockRequested();
    void handleUnlockRequested();

private:
    [[nodiscard]] std::optional<QDBusConnection> getSystemBus() const;
    [[nodiscard]] bool queryHibernateAvailable() const;
    bool call(const QString& path, const QString& iface, const QString& method, const QVariantList& args = {});
    bool callManager(const QString& method, const QVariantList& args = {true});
    bool callSession(const QString& method);
    void runFallback(const QStringList& candidates);

    QString m_sessionPath;
};
