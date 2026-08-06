#pragma once

#include <QString>
#include <QStringList>
#include <QJsonObject>
#include <QJsonDocument>
#include <QFile>
#include <QDir>
#include <QSettings>
#include <QDebug>

class GreeterStateHelper {
public:
    static QStringList stateFilePaths() {
        return {
            QStringLiteral("/var/cache/caelestia-greeter/state.json"),
            QStringLiteral("/var/lib/caelestia-greeter/state.json"),
            QDir::homePath() + QStringLiteral("/.cache/caelestia-greeter/state.json"),
            QDir::tempPath() + QStringLiteral("/caelestia-greeter-state.json")
        };
    }

    static QJsonObject readState() {
        for (const QString &path : stateFilePaths()) {
            QFile f(path);
            if (f.exists() && f.open(QIODevice::ReadOnly)) {
                QJsonDocument doc = QJsonDocument::fromJson(f.readAll());
                if (doc.isObject()) {
                    return doc.object();
                }
            }
        }
        return QJsonObject();
    }

    static bool writeState(const QJsonObject &obj) {
        for (const QString &path : stateFilePaths()) {
            QFileInfo fi(path);
            QDir().mkpath(fi.absolutePath());
            QFile f(path);
            if (f.open(QIODevice::WriteOnly | QIODevice::Truncate)) {
                f.write(QJsonDocument(obj).toJson(QJsonDocument::Indented));
                f.close();
                return true;
            }
        }
        return false;
    }

    static QString getLastUser() {
        QJsonObject state = readState();
        return state.value(QStringLiteral("lastUser")).toString();
    }

    static QString getLastSession(const QString &username = QString()) {
        QJsonObject state = readState();
        if (!username.isEmpty()) {
            QJsonObject userSessions = state.value(QStringLiteral("userSessions")).toObject();
            if (userSessions.contains(username)) {
                QString s = userSessions.value(username).toString();
                if (!s.isEmpty()) return s;
            }

            // Also check AccountsService user file
            QString accPath = QStringLiteral("/var/lib/AccountsService/users/") + username;
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
        return state.value(QStringLiteral("lastSession")).toString();
    }

    static void saveSession(const QString &username, const QString &sessionKey) {
        QJsonObject state = readState();
        if (!username.isEmpty()) {
            state[QStringLiteral("lastUser")] = username;
            QJsonObject userSessions = state.value(QStringLiteral("userSessions")).toObject();
            userSessions[username] = sessionKey;
            state[QStringLiteral("userSessions")] = userSessions;
        }
        state[QStringLiteral("lastSession")] = sessionKey;
        writeState(state);
    }
};
