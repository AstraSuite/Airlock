pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import M3Shapes
import "../services"

// Background shapes matching Caelestia dashboard media tab (BackgroundShapes.qml).
// Drifting Material 3 geometric shapes across screen with FrameAnimation, random velocities,
// smooth rotation, tonal palette container colors, and screen wrapping.
Item {
    id: root

    property bool blurry: false
    property bool initialized: false
    property real randomizeWidth: 0
    property real randomizeHeight: 0

    readonly property list<int> shapePool: [
        MaterialShape.Circle,
        MaterialShape.Cookie4Sided,
        MaterialShape.Cookie6Sided,
        MaterialShape.Cookie7Sided,
        MaterialShape.Cookie9Sided,
        MaterialShape.Cookie12Sided,
        MaterialShape.Sunny,
        MaterialShape.VerySunny,
        MaterialShape.SoftBurst,
        MaterialShape.Pentagon,
        MaterialShape.Gem,
        MaterialShape.Arch,
        MaterialShape.Arrow,
        MaterialShape.Pill,
        MaterialShape.Triangle,
        MaterialShape.Fan,
        MaterialShape.Oval
    ]

    property int count: 22
    property real minSize: 54
    property real maxSize: 180
    property real minSpeed: 6
    property real maxSpeed: 22
    property real minRotSpeed: -12
    property real maxRotSpeed: 12
    property list<real> lightOpacities: [0.32, 0.32, 0.10, 0.22]
    property list<real> darkOpacities: [0.18, 0.18, 0.08, 0.18]

    function rand(min: real, max: real): real {
        return min + Math.random() * (max - min);
    }

    function signedRand(min: real, max: real): real {
        return rand(min, max) * (Math.random() < 0.5 ? -1 : 1);
    }

    function randomizePositions() {
        if (width <= 0 || height <= 0)
            return;

        randomizeWidth = width;
        randomizeHeight = height;

        for (let i = 0; i < shapes.count; i++) {
            const s = shapes.itemAt(i);
            if (s) {
                s.x = rand(0, Math.max(0, width - s.implicitSize));
                s.y = rand(0, Math.max(0, height - s.implicitSize));
            }
        }
        initialized = true;
    }

    // Re-seed when the surface actually changes size. The window may map with
    // a small default size before the compositor's fullscreen configure lands,
    // which would otherwise lock every shape into a corner of the final screen.
    onWidthChanged: {
        if (width > 0 && height > 0
                && (!initialized || Math.abs(width - randomizeWidth) > 32 || Math.abs(height - randomizeHeight) > 32))
            randomizePositions();
    }

    onHeightChanged: {
        if (width > 0 && height > 0
                && (!initialized || Math.abs(width - randomizeWidth) > 32 || Math.abs(height - randomizeHeight) > 32))
            randomizePositions();
    }

    clip: true
    visible: Colours.lavaLampEnabled
    opacity: Colours.lavaLampEnabled ? 1.0 : 0.0
    Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }

    layer.enabled: root.blurry
    layer.effect: MultiEffect {
        autoPaddingEnabled: false
        blurEnabled: true
        blur: 0.85
        blurMax: 54
        blurMultiplier: 1.0
    }

    Component.onCompleted: {
        shapes.model = count;
        if (width > 0 && height > 0)
            randomizePositions();
    }

    Repeater {
        id: shapes

        onItemAdded: (index, item) => {
            if (root.width > 0 && root.height > 0) {
                item.x = root.rand(0, Math.max(0, root.width - item.implicitSize));
                item.y = root.rand(0, Math.max(0, root.height - item.implicitSize));
            }
        }

        DriftingShape {}
    }

    FrameAnimation {
        running: root.visible && root.width > 0 && root.height > 0 && Colours.lavaLampEnabled
        onTriggered: {
            const dt = frameTime;
            for (let i = 0; i < shapes.count; i++) {
                const s = shapes.itemAt(i) as DriftingShape;
                if (!s)
                    continue;

                s.x += s.vx * dt;
                s.y += s.vy * dt;
                s.rotation += s.vr * dt;

                if (s.x + s.width < -30)
                    s.x = root.width + 20;
                else if (s.x > root.width + 30)
                    s.x = -s.width - 20;

                if (s.y + s.height < -30)
                    s.y = root.height + 20;
                else if (s.y > root.height + 30)
                    s.y = -s.height - 20;
            }
        }
    }

    component DriftingShape: MaterialShape {
        id: shapeItem

        required property int index

        property real vx: root.signedRand(root.minSpeed, root.maxSpeed)
        property real vy: root.signedRand(root.minSpeed, root.maxSpeed)
        property real vr: root.rand(root.minRotSpeed, root.maxRotSpeed)
        readonly property int colourIdx: Math.floor(Math.random() * 4)

        implicitSize: root.minSize + (index / Math.max(1, root.count - 1)) * (root.maxSize - root.minSize)
        shape: root.shapePool[Math.floor(Math.random() * root.shapePool.length)]
        color: [
            Colours.palette.m3primaryContainer,
            Colours.palette.m3secondaryContainer,
            Colours.palette.m3tertiaryContainer,
            Colours.palette.m3outlineVariant
        ][colourIdx]
        opacity: Colours.light ? root.lightOpacities[colourIdx] : root.darkOpacities[colourIdx]
        rotation: root.rand(0, 360)

        Behavior on color {
            CAnim {}
        }

        Behavior on opacity {
            NumberAnimation { duration: 300 }
        }
    }
}
