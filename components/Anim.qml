pragma ComponentBehavior: Bound

import QtQuick

// Smooth number animation, self-contained, matching Caelestia design tokens
NumberAnimation {
    enum Type {
        StandardSmall = 0,
        Standard,
        StandardLarge,
        FastSpatial,
        DefaultSpatial,
        SlowSpatial,
        FastEffects,
        DefaultEffects,
        SlowEffects
    }

    property int type: Anim.DefaultSpatial

    duration: {
        if (type === Anim.FastSpatial || type === Anim.FastEffects)
            return 150;
        if (type === Anim.SlowSpatial || type === Anim.SlowEffects)
            return 500;
        if (type === Anim.StandardSmall)
            return 100;
        if (type === Anim.StandardLarge)
            return 400;
        return 250;
    }

    easing.type: {
        if (type === Anim.FastSpatial || type === Anim.DefaultSpatial || type === Anim.SlowSpatial)
            return Easing.OutCubic;
        if (type === Anim.FastEffects || type === Anim.DefaultEffects || type === Anim.SlowEffects)
            return Easing.InOutQuad;
        return Easing.OutQuad;
    }
}
