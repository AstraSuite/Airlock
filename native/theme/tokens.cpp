#include "tokens.hpp"
#include <cmath>
#include <QPointF>
#include <QFile>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QDir>
#include <QFontDatabase>

namespace airlock::config {

void RoundingTokens::loadJson(const QJsonObject& json) {
    if (json.contains("extraSmall")) m_extraSmall = json["extraSmall"].toInt(m_extraSmall);
    if (json.contains("small")) m_small = json["small"].toInt(m_small);
    if (json.contains("medium")) m_medium = json["medium"].toInt(m_medium);
    if (json.contains("large")) m_large = json["large"].toInt(m_large);
    if (json.contains("largeIncreased")) m_largeIncreased = json["largeIncreased"].toInt(m_largeIncreased);
    if (json.contains("extraLarge")) m_extraLarge = json["extraLarge"].toInt(m_extraLarge);
    if (json.contains("extraLargeIncreased")) m_extraLargeIncreased = json["extraLargeIncreased"].toInt(m_extraLargeIncreased);
    if (json.contains("extraExtraLarge")) m_extraExtraLarge = json["extraExtraLarge"].toInt(m_extraExtraLarge);
    if (json.contains("full")) m_full = json["full"].toInt(m_full);
    emit valuesChanged();
}

void SpacingTokens::loadJson(const QJsonObject& json) {
    if (json.contains("extraSmall")) m_extraSmall = json["extraSmall"].toInt(m_extraSmall);
    if (json.contains("small")) m_small = json["small"].toInt(m_small);
    if (json.contains("medium")) m_medium = json["medium"].toInt(m_medium);
    if (json.contains("large")) m_large = json["large"].toInt(m_large);
    if (json.contains("largeIncreased")) m_largeIncreased = json["largeIncreased"].toInt(m_largeIncreased);
    if (json.contains("extraLarge")) m_extraLarge = json["extraLarge"].toInt(m_extraLarge);
    if (json.contains("extraLargeIncreased")) m_extraLargeIncreased = json["extraLargeIncreased"].toInt(m_extraLargeIncreased);
    if (json.contains("extraExtraLarge")) m_extraExtraLarge = json["extraExtraLarge"].toInt(m_extraExtraLarge);
    emit valuesChanged();
}

void PaddingTokens::loadJson(const QJsonObject& json) {
    if (json.contains("extraSmall")) m_extraSmall = json["extraSmall"].toInt(m_extraSmall);
    if (json.contains("small")) m_small = json["small"].toInt(m_small);
    if (json.contains("medium")) m_medium = json["medium"].toInt(m_medium);
    if (json.contains("large")) m_large = json["large"].toInt(m_large);
    if (json.contains("largeIncreased")) m_largeIncreased = json["largeIncreased"].toInt(m_largeIncreased);
    if (json.contains("extraLarge")) m_extraLarge = json["extraLarge"].toInt(m_extraLarge);
    if (json.contains("extraLargeIncreased")) m_extraLargeIncreased = json["extraLargeIncreased"].toInt(m_extraLargeIncreased);
    if (json.contains("extraExtraLarge")) m_extraExtraLarge = json["extraExtraLarge"].toInt(m_extraExtraLarge);
    emit valuesChanged();
}

void AnimDurationTokens::loadJson(const QJsonObject& json) {
    if (json.contains("small")) m_small = json["small"].toInt(m_small);
    if (json.contains("normal")) m_normal = json["normal"].toInt(m_normal);
    if (json.contains("large")) m_large = json["large"].toInt(m_large);
    if (json.contains("extraLarge")) m_extraLarge = json["extraLarge"].toInt(m_extraLarge);
    if (json.contains("expressiveFastSpatial")) m_expressiveFastSpatial = json["expressiveFastSpatial"].toInt(m_expressiveFastSpatial);
    if (json.contains("expressiveDefaultSpatial")) m_expressiveDefaultSpatial = json["expressiveDefaultSpatial"].toInt(m_expressiveDefaultSpatial);
    if (json.contains("expressiveSlowSpatial")) m_expressiveSlowSpatial = json["expressiveSlowSpatial"].toInt(m_expressiveSlowSpatial);
    if (json.contains("expressiveFastEffects")) m_expressiveFastEffects = json["expressiveFastEffects"].toInt(m_expressiveFastEffects);
    if (json.contains("expressiveDefaultEffects")) m_expressiveDefaultEffects = json["expressiveDefaultEffects"].toInt(m_expressiveDefaultEffects);
    if (json.contains("expressiveSlowEffects")) m_expressiveSlowEffects = json["expressiveSlowEffects"].toInt(m_expressiveSlowEffects);
    emit valuesChanged();
}

void SizeTokens::loadJson(const QJsonObject& json) {
    if (json.contains("sidebar")) {
        auto sb = json["sidebar"].toObject();
        if (sb.contains("width")) {
            m_sidebar->set_width(sb["width"].toInt(m_sidebar->width()));
        }
    }
}

QEasingCurve AnimCurves::makeBezier(qreal p1x, qreal p1y, qreal p2x, qreal p2y) {
    QEasingCurve curve(QEasingCurve::BezierSpline);
    curve.addCubicBezierSegment(QPointF(p1x, p1y), QPointF(p2x, p2y), QPointF(1.0, 1.0));
    return curve;
}

QEasingCurve AnimCurves::parseBezierList(const QJsonArray& arr, const QEasingCurve& fallback) {
    if (arr.size() >= 4) {
        return makeBezier(arr[0].toDouble(), arr[1].toDouble(), arr[2].toDouble(), arr[3].toDouble());
    }
    return fallback;
}

AnimCurves::AnimCurves(QObject* parent)
    : QObject(parent)
    , m_durations(new AnimDurationTokens(this)) {
    m_emphasized = makeBezier(0.2, 0.0, 0.0, 1.0);
    m_emphasizedAccel = makeBezier(0.3, 0.0, 0.8, 0.15);
    m_emphasizedDecel = makeBezier(0.05, 0.7, 0.1, 1.0);
    m_standard = makeBezier(0.2, 0.0, 0.0, 1.0);
    m_standardAccel = makeBezier(0.3, 0.0, 1.0, 1.0);
    m_standardDecel = makeBezier(0.0, 0.0, 0.0, 1.0);
    m_expressiveFastSpatial = makeBezier(0.42, 1.67, 0.21, 0.9);
    m_expressiveDefaultSpatial = makeBezier(0.38, 1.21, 0.22, 1.0);
    m_expressiveSlowSpatial = makeBezier(0.39, 1.29, 0.35, 0.98);
    m_expressiveFastEffects = makeBezier(0.31, 0.94, 0.34, 1.0);
    m_expressiveDefaultEffects = makeBezier(0.34, 0.8, 0.34, 1.0);
    m_expressiveSlowEffects = makeBezier(0.34, 0.88, 0.34, 1.0);
}

void AnimCurves::loadJson(const QJsonObject& json) {
    if (json.contains("emphasized")) m_emphasized = parseBezierList(json["emphasized"].toArray(), m_emphasized);
    if (json.contains("emphasizedAccel")) m_emphasizedAccel = parseBezierList(json["emphasizedAccel"].toArray(), m_emphasizedAccel);
    if (json.contains("emphasizedDecel")) m_emphasizedDecel = parseBezierList(json["emphasizedDecel"].toArray(), m_emphasizedDecel);
    if (json.contains("standard")) m_standard = parseBezierList(json["standard"].toArray(), m_standard);
    if (json.contains("standardAccel")) m_standardAccel = parseBezierList(json["standardAccel"].toArray(), m_standardAccel);
    if (json.contains("standardDecel")) m_standardDecel = parseBezierList(json["standardDecel"].toArray(), m_standardDecel);
    if (json.contains("expressiveFastSpatial")) m_expressiveFastSpatial = parseBezierList(json["expressiveFastSpatial"].toArray(), m_expressiveFastSpatial);
    if (json.contains("expressiveDefaultSpatial")) m_expressiveDefaultSpatial = parseBezierList(json["expressiveDefaultSpatial"].toArray(), m_expressiveDefaultSpatial);
    if (json.contains("expressiveSlowSpatial")) m_expressiveSlowSpatial = parseBezierList(json["expressiveSlowSpatial"].toArray(), m_expressiveSlowSpatial);
    if (json.contains("expressiveFastEffects")) m_expressiveFastEffects = parseBezierList(json["expressiveFastEffects"].toArray(), m_expressiveFastEffects);
    if (json.contains("expressiveDefaultEffects")) m_expressiveDefaultEffects = parseBezierList(json["expressiveDefaultEffects"].toArray(), m_expressiveDefaultEffects);
    if (json.contains("expressiveSlowEffects")) m_expressiveSlowEffects = parseBezierList(json["expressiveSlowEffects"].toArray(), m_expressiveSlowEffects);
    emit curvesChanged();
}

static qreal ttyStep(qreal progress) {
    constexpr qreal steps = 4.0;
    if (progress >= 1.0)
        return 1.0;
    return qMin(1.0, (std::floor(qMax(progress, 0.0) * (steps - 1.0)) + 1.0) / steps);
}

QEasingCurve AnimCurves::s_ttyCurve() {
    QEasingCurve curve(QEasingCurve::Linear);
    curve.setCustomType(ttyStep);
    return curve;
}

void AnimCurves::setTty(bool tty) {
    if (m_tty == tty)
        return;
    m_tty = tty;
    m_durations->setTty(tty);
    emit curvesChanged();
}

// TokensSingleton
TokensSingleton::TokensSingleton(QObject* parent)
    : QObject(parent)
    , m_rounding(new RoundingTokens(this))
    , m_spacing(new SpacingTokens(this))
    , m_padding(new PaddingTokens(this))
    , m_anim(new AnimCurves(this))
    , m_font(new FontTokens(this))
    , m_sizes(new SizeTokens(this)) {
    reload();

    QString home = QDir::homePath();
    QString tokensFile = home + "/.config/caelestia/shell-tokens.json";
    QString shellFile = home + "/.config/caelestia/shell.json";

    if (QFile::exists(tokensFile)) m_watcher.addPath(tokensFile);
    if (QFile::exists(shellFile)) m_watcher.addPath(shellFile);

    connect(&m_watcher, &QFileSystemWatcher::fileChanged, this, &TokensSingleton::reload);
}

void TokensSingleton::reload() {
    QString home = QDir::homePath();
    QString tokensFile = home + "/.config/caelestia/shell-tokens.json";
    QString shellFile = home + "/.config/caelestia/shell.json";

    loadTokensFile(tokensFile);
    loadShellConfigFile(shellFile);
}

void TokensSingleton::loadTokensFile(const QString& filePath) {
    QFile file(filePath);
    if (!file.open(QIODevice::ReadOnly))
        return;

    auto doc = QJsonDocument::fromJson(file.readAll());
    if (!doc.isObject())
        return;

    auto root = doc.object();
    if (root.contains("appearance")) {
        auto app = root["appearance"].toObject();
        if (app.contains("rounding")) m_rounding->loadJson(app["rounding"].toObject());
        if (app.contains("spacing")) m_spacing->loadJson(app["spacing"].toObject());
        if (app.contains("padding")) m_padding->loadJson(app["padding"].toObject());
        if (app.contains("animDurations")) m_anim->durations()->loadJson(app["animDurations"].toObject());
        if (app.contains("curves")) m_anim->loadJson(app["curves"].toObject());
    }

    if (root.contains("sizes")) {
        m_sizes->loadJson(root["sizes"].toObject());
    }
}

void TokensSingleton::loadShellConfigFile(const QString& filePath) {
    QFile file(filePath);
    if (!file.open(QIODevice::ReadOnly))
        return;

    auto doc = QJsonDocument::fromJson(file.readAll());
    if (!doc.isObject())
        return;

    auto root = doc.object();
    if (root.contains("appearance")) {
        auto app = root["appearance"].toObject();
        if (app.contains("rounding")) {
            auto r = app["rounding"].toObject();
            if (r.contains("scale")) m_rounding->setScale(r["scale"].toDouble(1.0));
        }
        if (app.contains("spacing")) {
            auto s = app["spacing"].toObject();
            if (s.contains("scale")) m_spacing->setScale(s["scale"].toDouble(1.0));
        }
        if (app.contains("padding")) {
            auto p = app["padding"].toObject();
            if (p.contains("scale")) m_padding->setScale(p["scale"].toDouble(1.0));
        }
        if (app.contains("font")) {
            auto f = app["font"].toObject();
            if (f.contains("scale")) {
                qreal scale = f["scale"].toDouble(1.0);
                m_font->headline()->setScale(scale);
                m_font->title()->setScale(scale);
                m_font->body()->setScale(scale);
                m_font->label()->setScale(scale);
                m_font->mono()->setScale(scale);
                m_font->icon()->setScale(scale);
            }
        }
    }
}

// The monospace face TTY draws with: the one asked for when installed, else
// the first of the usual terminal faces, as KiiteShell picks it.
static QString pickMonoFace(const QString& preferred) {
    const QStringList families = QFontDatabase::families();
    const QStringList wanted = { preferred, "JetBrains Mono", "JetBrainsMono NF", "JetBrainsMono Nerd Font",
                                 "JetBrains Mono NF", "Iosevka", "DejaVu Sans Mono", "Noto Sans Mono",
                                 "Liberation Mono" };
    for (const QString& w : wanted) {
        if (!w.isEmpty() && families.contains(w))
            return w;
    }
    return QStringLiteral("monospace");
}

void TokensSingleton::setTty(bool tty, const QString& preferredMono) {
    m_tty = tty;
    m_rounding->setSquared(tty);
    m_anim->setTty(tty);
    if (tty) {
        const QString mono = pickMonoFace(preferredMono);
        m_font->setFamily(mono);
        m_font->mono()->setFamily(mono);
    } else {
        m_font->setFamily(QStringLiteral("Google Sans Flex"));
        m_font->mono()->setFamily(QStringLiteral("monospace"));
    }
}

TokensSingleton* TokensSingleton::instance() {
    static auto* s_instance = new TokensSingleton();
    return s_instance;
}

} // namespace airlock::config
