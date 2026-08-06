#include "sessionmanager.hpp"

#include <QtDBus/QDBusConnection>
#include <QtDBus/QDBusError>
#include <QtDBus/QDBusMessage>
#include <QtDBus/QDBusPendingCall>
#include <QtDBus/QDBusPendingReply>
#include <QtDBus/QDBusPendingCallWatcher>
#include <QtDBus/QDBusReply>
#include <QProcess>
#include <QDebug>

namespace {

constexpr const char* LOGIN_SERVICE = "org.freedesktop.login1";
constexpr const char* LOGIN_PATH = "/org/freedesktop/login1";
constexpr const char* LOGIN_IFACE = "org.freedesktop.login1.Manager";
constexpr const char* SESSION_IFACE = "org.freedesktop.login1.Session";

} // namespace

SessionManager::SessionManager(QObject* parent)
    : QObject(parent)
{
    auto bus = getSystemBus();
    if (!bus) {
        return;
    }

    bus->connect(LOGIN_SERVICE, LOGIN_PATH, LOGIN_IFACE, QStringLiteral("PrepareForSleep"),
                 this, SLOT(handlePrepareForSleep(bool)));

    auto sessionMsg = QDBusMessage::createMethodCall(
        QString::fromLatin1(LOGIN_SERVICE),
        QString::fromLatin1(LOGIN_PATH),
        QString::fromLatin1(LOGIN_IFACE),
        QStringLiteral("GetSession"));
    sessionMsg.setArguments({QStringLiteral("auto")});

    const QDBusReply<QDBusObjectPath> sessionReply = bus->call(sessionMsg);
    if (sessionReply.isValid()) {
        m_sessionPath = sessionReply.value().path();
        bus->connect(LOGIN_SERVICE, m_sessionPath, SESSION_IFACE, QStringLiteral("Lock"),
                     this, SLOT(handleLockRequested()));
        bus->connect(LOGIN_SERVICE, m_sessionPath, SESSION_IFACE, QStringLiteral("Unlock"),
                     this, SLOT(handleUnlockRequested()));
    }
}

void SessionManager::runFallback(const QStringList& candidates)
{
    for (const QString& cmdStr : candidates) {
        const QStringList parts = cmdStr.split(QLatin1Char(' '), Qt::SkipEmptyParts);
        if (parts.isEmpty()) {
            continue;
        }
        if (QProcess::startDetached(parts.first(), parts.mid(1))) {
            return;
        }
    }
}

bool SessionManager::exec(const QStringList& command)
{
    if (command.isEmpty()) {
        return false;
    }

    QString cmd = command.first();
    // Alias systemctl and loginctl to raw dbus calls
    if ((cmd == QStringLiteral("systemctl") || cmd == QStringLiteral("loginctl")) && command.size() == 2) {
        cmd = command.at(1);
    }
    if (cmd == QStringLiteral("loginctl") && command.size() == 3 && command.at(1) == QStringLiteral("terminate-user") && command.at(2).isEmpty()) {
        cmd = QStringLiteral("logout");
    }

    cmd = cmd.remove(QLatin1Char('-')).remove(QLatin1Char('_')).toLower();

    if (cmd == QStringLiteral("logout")) {
        logout();
        return true;
    }
    if (cmd == QStringLiteral("suspend")) {
        suspend();
        return true;
    }
    if (cmd == QStringLiteral("suspendthenhibernate")) {
        suspendThenHibernate();
        return true;
    }
    if (cmd == QStringLiteral("hibernate")) {
        hibernate();
        return true;
    }
    if (cmd == QStringLiteral("reboottouefi") || cmd == QStringLiteral("reboottofirmware") ||
        cmd == QStringLiteral("uefi") || cmd == QStringLiteral("firmware") || cmd == QStringLiteral("bios")) {
        rebootToUefi();
        return true;
    }
    if (cmd == QStringLiteral("poweroff") || cmd == QStringLiteral("shutdown")) {
        poweroff();
        return true;
    }
    if (cmd == QStringLiteral("reboot")) {
        reboot();
        return true;
    }

    return false;
}

void SessionManager::logout()
{
    if (!m_sessionPath.isEmpty()) {
        callSession(QStringLiteral("Terminate"));
    } else {
        runFallback({
            QStringLiteral("loginctl terminate-user"),
            QStringLiteral("pkill -u $USER"),
        });
    }
}

void SessionManager::suspend()
{
    if (!callManager(QStringLiteral("Suspend"))) {
        runFallback({
            QStringLiteral("loginctl suspend"),
            QStringLiteral("zzz"),
            QStringLiteral("systemctl suspend"),
        });
    }
}

void SessionManager::suspendThenHibernate()
{
    if (queryHibernateAvailable()) {
        if (!callManager(QStringLiteral("SuspendThenHibernate"))) {
            suspend();
        }
    } else {
        suspend();
    }
}

void SessionManager::hibernate()
{
    if (queryHibernateAvailable()) {
        if (!callManager(QStringLiteral("Hibernate"))) {
            runFallback({
                QStringLiteral("loginctl hibernate"),
                QStringLiteral("ZZZ"),
                QStringLiteral("systemctl hibernate"),
            });
        }
    }
}

bool SessionManager::canRebootToUefi() const
{
    auto bus = getSystemBus();
    if (!bus) {
        return false;
    }

    auto msg = QDBusMessage::createMethodCall(
        QString::fromLatin1(LOGIN_SERVICE),
        QString::fromLatin1(LOGIN_PATH),
        QString::fromLatin1(LOGIN_IFACE),
        QStringLiteral("CanRebootToFirmwareSetup"));
    const QDBusReply<QString> reply = bus->call(msg);
    if (reply.isValid()) {
        const QString state = reply.value();
        return state == QStringLiteral("yes") || state == QStringLiteral("challenge");
    }
    return false;
}

void SessionManager::rebootToUefi()
{
    auto bus = getSystemBus();
    if (bus) {
        auto setMsg = QDBusMessage::createMethodCall(
            QString::fromLatin1(LOGIN_SERVICE),
            QString::fromLatin1(LOGIN_PATH),
            QString::fromLatin1(LOGIN_IFACE),
            QStringLiteral("SetRebootToFirmwareSetup"));
        setMsg.setArguments({true});
        bus->call(setMsg);

        if (callManager(QStringLiteral("Reboot"))) {
            return;
        }
    }

    runFallback({
        QStringLiteral("systemctl reboot --firmware-setup"),
        QStringLiteral("bootctl reboot-to-firmware true"),
        QStringLiteral("efibootmgr --reboot-to-firmware"),
    });
    reboot();
}

void SessionManager::rebootToFirmware()
{
    rebootToUefi();
}

void SessionManager::poweroff()
{
    if (!callManager(QStringLiteral("PowerOff"))) {
        runFallback({
            QStringLiteral("loginctl poweroff"),
            QStringLiteral("openrc-shutdown -p"),
            QStringLiteral("poweroff"),
            QStringLiteral("systemctl poweroff"),
            QStringLiteral("shutdown -h now"),
        });
    }
}

void SessionManager::reboot()
{
    if (!callManager(QStringLiteral("Reboot"))) {
        runFallback({
            QStringLiteral("loginctl reboot"),
            QStringLiteral("openrc-shutdown -r"),
            QStringLiteral("reboot"),
            QStringLiteral("systemctl reboot"),
            QStringLiteral("shutdown -r now"),
        });
    }
}

std::optional<QDBusConnection> SessionManager::getSystemBus() const
{
    auto bus = QDBusConnection::systemBus();
    if (!bus.isConnected()) {
        return std::nullopt;
    }
    return bus;
}

bool SessionManager::queryHibernateAvailable() const
{
    auto bus = getSystemBus();
    if (!bus) {
        return false;
    }

    auto hibernateMsg = QDBusMessage::createMethodCall(
        QString::fromLatin1(LOGIN_SERVICE),
        QString::fromLatin1(LOGIN_PATH),
        QString::fromLatin1(LOGIN_IFACE),
        QStringLiteral("CanHibernate"));
    const QDBusReply<QString> hibernateReply = bus->call(hibernateMsg);
    if (hibernateReply.isValid()) {
        const QString state = hibernateReply.value();
        return state == QStringLiteral("yes") || state == QStringLiteral("challenge");
    }
    return false;
}

bool SessionManager::call(const QString& path, const QString& iface, const QString& method, const QVariantList& args)
{
    auto bus = getSystemBus();
    if (!bus) {
        return false;
    }

    auto msg = QDBusMessage::createMethodCall(QString::fromLatin1(LOGIN_SERVICE), path, iface, method);
    msg.setArguments(args);

    auto* watcher = new QDBusPendingCallWatcher(bus->asyncCall(msg), this);
    connect(watcher, &QDBusPendingCallWatcher::finished, this, [method](QDBusPendingCallWatcher* self) {
        const QDBusPendingReply<> reply = *self;
        if (reply.isError()) {
            qWarning() << "SessionManager: Call to" << method << "failed:" << reply.error().message();
        }
        self->deleteLater();
    });
    return true;
}

bool SessionManager::callManager(const QString& method, const QVariantList& args)
{
    return call(QString::fromLatin1(LOGIN_PATH), QString::fromLatin1(LOGIN_IFACE), method, args);
}

bool SessionManager::callSession(const QString& method)
{
    if (m_sessionPath.isEmpty()) {
        return false;
    }
    return call(m_sessionPath, QString::fromLatin1(SESSION_IFACE), method);
}

void SessionManager::handlePrepareForSleep(bool sleep)
{
    if (sleep) {
        emit aboutToSleep();
    } else {
        emit resumed();
    }
}

void SessionManager::handleLockRequested()
{
    emit lockRequested();
}

void SessionManager::handleUnlockRequested()
{
    emit unlockRequested();
}
