#pragma once

#include <QObject>
#include <QVariantMap>
#include <QVariantList>
#include <qqmlintegration.h>

class SchemeDiscovery : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    Q_PROPERTY(QVariantList schemes READ schemes NOTIFY schemesChanged)
    Q_PROPERTY(QString activeUser READ activeUser WRITE setActiveUser NOTIFY activeUserChanged)

public:
    explicit SchemeDiscovery(QObject *parent = nullptr);
    ~SchemeDiscovery() override = default;

    QVariantList schemes() const { return m_schemes; }
    QString activeUser() const { return m_activeUser; }
    Q_INVOKABLE void setActiveUser(const QString &user);

    Q_INVOKABLE bool hasDynamicScheme(const QString &user) const;
    Q_INVOKABLE void reload();
    Q_INVOKABLE QVariantMap getSchemeColours(const QString &name, const QString &flavour, const QString &mode);

signals:
    void schemesChanged();
    void activeUserChanged();

private:
    QStringList schemeSearchPaths() const;
    QVariantList m_schemes;
    QString m_activeUser;
};
