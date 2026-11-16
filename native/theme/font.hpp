#pragma once

#include "fontbuilder.hpp"
#include <QObject>
#include <QFont>
#include <QtQmlIntegration/qqmlintegration.h>

namespace airlock::config {

class FontStyleBase;
class IconFontStyle;

class FontBuilders : public QObject {
    Q_OBJECT
    QML_ANONYMOUS

    Q_PROPERTY(airlock::config::FontBuilder extraLarge READ extraLarge NOTIFY buildersChanged FINAL)
    Q_PROPERTY(airlock::config::FontBuilder large READ large NOTIFY buildersChanged FINAL)
    Q_PROPERTY(airlock::config::FontBuilder medium READ medium NOTIFY buildersChanged FINAL)
    Q_PROPERTY(airlock::config::FontBuilder small READ small NOTIFY buildersChanged FINAL)

public:
    explicit FontBuilders(const FontStyleBase* style, QObject* parent = nullptr);

    [[nodiscard]] FontBuilder extraLarge() const;
    [[nodiscard]] FontBuilder large() const;
    [[nodiscard]] FontBuilder medium() const;
    [[nodiscard]] FontBuilder small() const;

signals:
    void buildersChanged();

protected:
    const FontStyleBase* m_style;
};

class FontStyleBase : public QObject {
    Q_OBJECT

    Q_PROPERTY(QFont extraLarge READ extraLarge NOTIFY fontsChanged FINAL)
    Q_PROPERTY(QFont large READ large NOTIFY fontsChanged FINAL)
    Q_PROPERTY(QFont medium READ medium NOTIFY fontsChanged FINAL)
    Q_PROPERTY(QFont small READ small NOTIFY fontsChanged FINAL)
    Q_PROPERTY(airlock::config::FontBuilders* builders READ builders CONSTANT FINAL)

public:
    explicit FontStyleBase(const QString& family, int smallSize, int mediumSize, int largeSize, int extraLargeSize,
                           QFont::Weight defaultWeight = QFont::Normal, QObject* parent = nullptr);

    [[nodiscard]] QFont extraLarge() const { return m_extraLarge; }
    [[nodiscard]] QFont large() const { return m_large; }
    [[nodiscard]] QFont medium() const { return m_medium; }
    [[nodiscard]] QFont small() const { return m_small; }
    [[nodiscard]] FontBuilders* builders() const { return m_builders; }

    [[nodiscard]] QString family() const { return m_family; }
    void setFamily(const QString& family);

    [[nodiscard]] qreal scale() const { return m_scale; }
    void setScale(qreal scale);

    void setSizes(int smallSize, int mediumSize, int largeSize, int extraLargeSize);

signals:
    void fontsChanged();

protected:
    void rebuild();
    QFont makeFont(int baseSize, QFont::Weight weight);

    QString m_family;
    int m_smallSize;
    int m_mediumSize;
    int m_largeSize;
    int m_extraLargeSize;
    QFont::Weight m_defaultWeight = QFont::Normal;
    qreal m_scale = 1.0;

    QFont m_small;
    QFont m_medium;
    QFont m_large;
    QFont m_extraLarge;
    FontBuilders* m_builders = nullptr;
};

class FontStyle : public FontStyleBase {
    Q_OBJECT
    QML_ANONYMOUS

public:
    explicit FontStyle(const QString& family, int smallSize, int mediumSize, int largeSize, int extraLargeSize = 24,
                       QFont::Weight defaultWeight = QFont::Normal, QObject* parent = nullptr)
        : FontStyleBase(family, smallSize, mediumSize, largeSize, extraLargeSize, defaultWeight, parent) {}
};

class IconFontStyle : public FontStyleBase {
    Q_OBJECT
    QML_ANONYMOUS

public:
    explicit IconFontStyle(const QString& family, QObject* parent = nullptr);

    Q_INVOKABLE airlock::config::FontBuilder size(int pointSize);
};

class FontTokens : public QObject {
    Q_OBJECT
    QML_ANONYMOUS

    Q_PROPERTY(airlock::config::FontStyle* headline READ headline CONSTANT FINAL)
    Q_PROPERTY(airlock::config::FontStyle* title READ title CONSTANT FINAL)
    Q_PROPERTY(airlock::config::FontStyle* body READ body CONSTANT FINAL)
    Q_PROPERTY(airlock::config::FontStyle* label READ label CONSTANT FINAL)
    Q_PROPERTY(airlock::config::FontStyle* mono READ mono CONSTANT FINAL)
    Q_PROPERTY(airlock::config::IconFontStyle* icon READ icon CONSTANT FINAL)

public:
    explicit FontTokens(QObject* parent = nullptr);

    [[nodiscard]] FontStyle* headline() const { return m_headline; }
    [[nodiscard]] FontStyle* title() const { return m_title; }
    [[nodiscard]] FontStyle* body() const { return m_body; }
    [[nodiscard]] FontStyle* label() const { return m_label; }
    [[nodiscard]] FontStyle* mono() const { return m_mono; }
    [[nodiscard]] IconFontStyle* icon() const { return m_icon; }

    void setFamily(const QString& family);
    void setIconFamily(const QString& family);

private:
    FontStyle* m_headline = nullptr;
    FontStyle* m_title = nullptr;
    FontStyle* m_body = nullptr;
    FontStyle* m_label = nullptr;
    FontStyle* m_mono = nullptr;
    IconFontStyle* m_icon = nullptr;
};

} // namespace airlock::config
