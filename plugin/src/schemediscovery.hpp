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

public:
    explicit SchemeDiscovery(QObject *parent = nullptr);
    ~SchemeDiscovery() override = default;

    QVariantList schemes() const { return m_schemes; }

    Q_INVOKABLE void reload();
    Q_INVOKABLE QVariantMap getSchemeColours(const QString &name, const QString &flavour, const QString &mode);

signals:
    void schemesChanged();

private:
    QStringList schemeSearchPaths() const;
    QVariantList m_schemes;
};
