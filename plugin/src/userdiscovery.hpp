#pragma once

#include <QObject>
#include <QVariantMap>
#include <QVariantList>
#include <qqmlintegration.h>

class UserDiscovery : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    Q_PROPERTY(QVariantList users READ users NOTIFY usersChanged)
    Q_PROPERTY(int defaultIndex READ defaultIndex NOTIFY defaultIndexChanged)
    Q_PROPERTY(QString currentUser READ currentUser NOTIFY currentUserChanged)

public:
    explicit UserDiscovery(QObject *parent = nullptr);
    ~UserDiscovery() override = default;

    QVariantList users() const { return m_users; }
    int defaultIndex() const { return m_defaultIndex; }
    QString currentUser() const;

    Q_INVOKABLE void reload();

signals:
    void usersChanged();
    void defaultIndexChanged();
    void currentUserChanged();

private:
    QVariantList m_users;
    int m_defaultIndex{0};
};
