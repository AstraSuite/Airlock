#include "font.hpp"

namespace airlock::config {

// FontBuilders
FontBuilders::FontBuilders(const FontStyleBase* style, QObject* parent)
    : QObject(parent)
    , m_style(style) {
    connect(style, &FontStyleBase::fontsChanged, this, &FontBuilders::buildersChanged);
}

FontBuilder FontBuilders::extraLarge() const {
    return FontBuilder(m_style->extraLarge());
}

FontBuilder FontBuilders::large() const {
    return FontBuilder(m_style->large());
}

FontBuilder FontBuilders::medium() const {
    return FontBuilder(m_style->medium());
}

FontBuilder FontBuilders::small() const {
    return FontBuilder(m_style->small());
}

// FontStyleBase
FontStyleBase::FontStyleBase(const QString& family, int smallSize, int mediumSize, int largeSize, int extraLargeSize,
                             QFont::Weight defaultWeight, QObject* parent)
    : QObject(parent)
    , m_family(family)
    , m_smallSize(smallSize)
    , m_mediumSize(mediumSize)
    , m_largeSize(largeSize)
    , m_extraLargeSize(extraLargeSize)
    , m_defaultWeight(defaultWeight)
    , m_builders(new FontBuilders(this, this)) {
    rebuild();
}

void FontStyleBase::setFamily(const QString& family) {
    if (m_family != family) {
        m_family = family;
        rebuild();
    }
}

void FontStyleBase::setScale(qreal scale) {
    if (!qFuzzyCompare(m_scale + 1.0, scale + 1.0)) {
        m_scale = scale;
        rebuild();
    }
}

void FontStyleBase::setSizes(int smallSize, int mediumSize, int largeSize, int extraLargeSize) {
    m_smallSize = smallSize;
    m_mediumSize = mediumSize;
    m_largeSize = largeSize;
    m_extraLargeSize = extraLargeSize;
    rebuild();
}

QFont FontStyleBase::makeFont(int baseSize, QFont::Weight weight) {
    QFont f;
    if (!m_family.isEmpty()) {
        f.setFamily(m_family);
    }
    const int scaledSize = static_cast<int>(baseSize * m_scale);
    const int cappedSize = scaledSize > 0 ? scaledSize : 1;
    f.setPointSize(cappedSize);
    f.setVariableAxis("opsz", static_cast<float>(cappedSize));
    f.setWeight(weight);
    f.setVariableAxis("wght", static_cast<float>(f.weight()));
    if (m_family.contains("Google", Qt::CaseInsensitive)) {
        f.setVariableAxis("ROND", 25.0f);
    }
    return f;
}

void FontStyleBase::rebuild() {
    m_small = makeFont(m_smallSize, m_defaultWeight);
    m_medium = makeFont(m_mediumSize, m_defaultWeight);
    m_large = makeFont(m_largeSize, m_defaultWeight);
    m_extraLarge = makeFont(m_extraLargeSize, m_defaultWeight);

    emit fontsChanged();
}

// IconFontStyle
IconFontStyle::IconFontStyle(const QString& family, QObject* parent)
    : FontStyleBase(family, 15, 18, 24, 36, QFont::Normal, parent) {}

FontBuilder IconFontStyle::size(int pointSize) {
    return FontBuilder(m_small).size(pointSize);
}

// FontTokens
FontTokens::FontTokens(QObject* parent)
    : QObject(parent)
    , m_headline(new FontStyle("Google Sans Flex", 24, 28, 32, 36, QFont::Medium, this))
    , m_title(new FontStyle("Google Sans Flex", 14, 16, 22, 24, QFont::Medium, this))
    , m_body(new FontStyle("Google Sans Flex", 12, 14, 16, 18, QFont::Normal, this))
    , m_label(new FontStyle("Google Sans Flex", 11, 12, 14, 16, QFont::Medium, this))
    , m_mono(new FontStyle("monospace", 12, 14, 16, 18, QFont::Normal, this))
    , m_icon(new IconFontStyle("Material Symbols Rounded", this)) {}

void FontTokens::setFamily(const QString& family) {
    m_headline->setFamily(family);
    m_title->setFamily(family);
    m_body->setFamily(family);
    m_label->setFamily(family);
}

void FontTokens::setIconFamily(const QString& family) {
    m_icon->setFamily(family);
}

} // namespace airlock::config
