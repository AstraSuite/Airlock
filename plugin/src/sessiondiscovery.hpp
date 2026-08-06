#pragma once

#include <QObject>
#include <QVariantMap>
#include <QVariantList>
#include <qqmlintegration.h>

class SessionDiscovery : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    Q_PROPERTY(QVariantList sessions READ sessions NOTIFY sessionsChanged)
    Q_PROPERTY(int defaultIndex READ defaultIndex NOTIFY defaultIndexChanged)

public:
    explicit SessionDiscovery(QObject *parent = nullptr);
    ~SessionDiscovery() override = default;

    QVariantList sessions() const { return m_sessions; }
    int defaultIndex() const { return m_defaultIndex; }

    Q_INVOKABLE void reload();
    Q_INVOKABLE void saveLastSession(const QString &username, const QString &sessionKey);
    Q_INVOKABLE int sessionIndexForUser(const QString &username);
    Q_INVOKABLE int indexOfSession(const QString &sessionKey);

signals:
    void sessionsChanged();
    void defaultIndexChanged();

private:
    void parseDirectory(const QString &dirPath, const QString &sessionType);

    QVariantList m_sessions;
    int m_defaultIndex{0};
};
