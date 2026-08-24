#include "userdiscovery.hpp"
#include "greeterstate.hpp"
#include <QFile>
#include <QTextStream>
#include <QFileInfo>
#include <QProcessEnvironment>
#include <QDir>
#include <QDebug>

UserDiscovery::UserDiscovery(QObject *parent)
    : QObject(parent)
{
    reload();
    connect(GreeterState::instance(), &GreeterState::lastUserChanged, this, &UserDiscovery::updateDefaultIndex);
}

QString UserDiscovery::currentUser() const
{
    if (m_users.isEmpty() || m_defaultIndex < 0 || m_defaultIndex >= m_users.size()) {
        return QProcessEnvironment::systemEnvironment().value(QStringLiteral("USER"), QStringLiteral("user"));
    }
    return m_users.at(m_defaultIndex).toMap().value(QStringLiteral("username")).toString();
}

void UserDiscovery::updateDefaultIndex()
{
    if (m_users.isEmpty()) return;

    const QString lastUser = GreeterStateHelper::getLastUser();
    const QString envUser = QProcessEnvironment::systemEnvironment().value(QStringLiteral("USER"));

    int targetIdx = -1;
    if (!lastUser.isEmpty()) {
        for (int i = 0; i < m_users.size(); ++i) {
            if (m_users.at(i).toMap().value(QStringLiteral("username")).toString() == lastUser) {
                targetIdx = i;
                break;
            }
        }
    }

    if (targetIdx == -1 && !envUser.isEmpty()) {
        for (int i = 0; i < m_users.size(); ++i) {
            if (m_users.at(i).toMap().value(QStringLiteral("username")).toString() == envUser) {
                targetIdx = i;
                break;
            }
        }
    }

    if (targetIdx == -1) {
        targetIdx = 0;
    }

    if (m_defaultIndex != targetIdx) {
        m_defaultIndex = targetIdx;
        emit defaultIndexChanged();
        emit currentUserChanged();
    }
}

void UserDiscovery::reload()
{
    m_users.clear();
    m_defaultIndex = 0;

    const QString envUser = QProcessEnvironment::systemEnvironment().value(QStringLiteral("USER"));

    QFile passwdFile(QStringLiteral("/etc/passwd"));
    if (passwdFile.open(QIODevice::ReadOnly | QIODevice::Text)) {
        QTextStream in(&passwdFile);
        while (!in.atEnd()) {
            const QString line = in.readLine().trimmed();
            if (line.isEmpty() || line.startsWith(QLatin1Char('#'))) continue;

            const QStringList parts = line.split(QLatin1Char(':'));
            if (parts.size() < 7) continue;

            const QString username = parts.at(0);
            const int uid = parts.at(2).toInt();
            const QString gecos = parts.at(4);
            const QString homeDir = parts.at(5);
            const QString shell = parts.at(6);

            // Standard desktop user criteria: UID >= 1000, not nobody, valid interactive shell
            if (uid < 1000 || username == QStringLiteral("nobody") || shell.contains(QStringLiteral("nologin")) || shell.contains(QStringLiteral("false"))) {
                continue;
            }

            QString realName = gecos.split(QLatin1Char(',')).first().trimmed();
            if (realName.isEmpty()) {
                realName = username;
            }

            const QString cacheAvatar = QStringLiteral("/var/cache/astra-airlock/avatars/") + username;
            const QString avatarBase = QStringLiteral("/home/") + username;
            QString avatarPath;
            if (QFile::exists(cacheAvatar)) {
                avatarPath = QStringLiteral("file://") + cacheAvatar;
            } else if (QFile::exists(avatarBase + QStringLiteral("/.face"))) {
                avatarPath = QStringLiteral("file://") + avatarBase + QStringLiteral("/.face");
            } else if (QFile::exists(avatarBase + QStringLiteral("/.face.icon"))) {
                avatarPath = QStringLiteral("file://") + avatarBase + QStringLiteral("/.face.icon");
            } else if (QFile::exists(homeDir + QStringLiteral("/.face"))) {
                avatarPath = QStringLiteral("file://") + homeDir + QStringLiteral("/.face");
            } else if (QFile::exists(homeDir + QStringLiteral("/.face.icon"))) {
                avatarPath = QStringLiteral("file://") + homeDir + QStringLiteral("/.face.icon");
            } else if (QFile::exists(QStringLiteral("/var/lib/AccountsService/icons/") + username)) {
                avatarPath = QStringLiteral("file:///var/lib/AccountsService/icons/") + username;
            }

            QVariantMap userMap;
            userMap[QStringLiteral("username")] = username;
            userMap[QStringLiteral("realName")] = realName;
            userMap[QStringLiteral("homeDir")] = homeDir;
            userMap[QStringLiteral("avatar")] = avatarPath;
            m_users.append(userMap);
        }
    }

    if (m_users.isEmpty()) {
        const QString fallbackUser = envUser.isEmpty() ? QStringLiteral("user") : envUser;
        QVariantMap userMap;
        userMap[QStringLiteral("username")] = fallbackUser;
        userMap[QStringLiteral("realName")] = fallbackUser;
        userMap[QStringLiteral("homeDir")] = QStringLiteral("/home/") + fallbackUser;
        userMap[QStringLiteral("avatar")] = QString();
        m_users.append(userMap);
    }

    updateDefaultIndex();

    emit usersChanged();
}
