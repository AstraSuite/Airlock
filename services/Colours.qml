pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import M3Shapes
import Caelestia.Greeter
import "../components"

// Colours and theme state are managed directly via GreeterState and SchemeDiscovery.
// Scheme, flavour, and mode are persisted directly in greeter.json.
// All palette colours are loaded directly from system scheme files in 0ms without CLI subprocesses.
Singleton {
    id: root

    readonly property bool light: _mode === "light"
    property string _mode: GreeterState.schemeMode || "dark"
    property string schemeName: GreeterState.schemeName || "caelestia"
    property string flavour: GreeterState.schemeFlavour || "default"
    property string variant: "tonalspot"

    // Sync with GreeterState changes (e.g. from file reloads)
    Connections {
        target: GreeterState
        function onSchemeNameChanged() {
            root.schemeName = GreeterState.schemeName;
            root.reloadColours();
        }
        function onSchemeFlavourChanged() {
            root.flavour = GreeterState.schemeFlavour;
            root.reloadColours();
        }
        function onSchemeModeChanged() {
            root._mode = GreeterState.schemeMode;
            root.reloadColours();
        }
    }

    // Greeter-specific persisted settings
    property bool use12Hour: GreeterState.use12Hour
    property bool lavaLampEnabled: GreeterState.lavaLampEnabled
    property int avatarShape: GreeterState.avatarShape
    property string avatarShapeName: GreeterState.avatarShapeName

    onUse12HourChanged: {
        if (GreeterState.use12Hour !== use12Hour)
            GreeterState.use12Hour = use12Hour;
    }
    onLavaLampEnabledChanged: {
        if (GreeterState.lavaLampEnabled !== lavaLampEnabled)
            GreeterState.lavaLampEnabled = lavaLampEnabled;
    }
    onAvatarShapeChanged: {
        if (GreeterState.avatarShape !== avatarShape)
            GreeterState.avatarShape = avatarShape;
    }
    onAvatarShapeNameChanged: {
        if (GreeterState.avatarShapeName !== avatarShapeName)
            GreeterState.avatarShapeName = avatarShapeName;
    }

    // Full M3 palette matching caelestia-shell M3Palette with unified CAnim easing
    readonly property M3Palette palette: M3Palette {}

    component M3Palette: QtObject {
        property color m3background:              "#0a0f0f"; Behavior on m3background { CAnim {} }
        property color m3onBackground:            "#dce8e6"; Behavior on m3onBackground { CAnim {} }
        property color m3surface:                 "#0a0f0f"; Behavior on m3surface { CAnim {} }
        property color m3surfaceDim:              "#0a0f0f"; Behavior on m3surfaceDim { CAnim {} }
        property color m3surfaceBright:           "#242e2d"; Behavior on m3surfaceBright { CAnim {} }
        property color m3surfaceContainerLowest:  "#000000"; Behavior on m3surfaceContainerLowest { CAnim {} }
        property color m3surfaceContainerLow:     "#0e1514"; Behavior on m3surfaceContainerLow { CAnim {} }
        property color m3surfaceContainer:        "#131b1a"; Behavior on m3surfaceContainer { CAnim {} }
        property color m3surfaceContainerHigh:    "#192120"; Behavior on m3surfaceContainerHigh { CAnim {} }
        property color m3surfaceContainerHighest: "#1d2827"; Behavior on m3surfaceContainerHighest { CAnim {} }
        property color m3onSurface:               "#dce8e6"; Behavior on m3onSurface { CAnim {} }
        property color m3surfaceVariant:          "#1d2827"; Behavior on m3surfaceVariant { CAnim {} }
        property color m3onSurfaceVariant:        "#a2adac"; Behavior on m3onSurfaceVariant { CAnim {} }
        property color m3outline:                 "#6d7876"; Behavior on m3outline { CAnim {} }
        property color m3outlineVariant:          "#3f4a49"; Behavior on m3outlineVariant { CAnim {} }
        property color m3shadow:                  "#000000"; Behavior on m3shadow { CAnim {} }
        property color m3scrim:                   "#000000"; Behavior on m3scrim { CAnim {} }
        property color m3surfaceTint:             "#9bd0cc"; Behavior on m3surfaceTint { CAnim {} }
        property color m3primary:                 "#9bd0cc"; Behavior on m3primary { CAnim {} }
        property color m3onPrimary:               "#0d4845"; Behavior on m3onPrimary { CAnim {} }
        property color m3primaryContainer:        "#255b58"; Behavior on m3primaryContainer { CAnim {} }
        property color m3onPrimaryContainer:      "#b8ede9"; Behavior on m3onPrimaryContainer { CAnim {} }
        property color m3inversePrimary:          "#336764"; Behavior on m3inversePrimary { CAnim {} }
        property color m3secondary:               "#b0ccc9"; Behavior on m3secondary { CAnim {} }
        property color m3onSecondary:             "#2c4543"; Behavior on m3onSecondary { CAnim {} }
        property color m3secondaryContainer:      "#27403e"; Behavior on m3secondaryContainer { CAnim {} }
        property color m3onSecondaryContainer:    "#a9c5c2"; Behavior on m3onSecondaryContainer { CAnim {} }
        property color m3tertiary:                "#d5efff"; Behavior on m3tertiary { CAnim {} }
        property color m3onTertiary:              "#2e5c72"; Behavior on m3onTertiary { CAnim {} }
        property color m3tertiaryContainer:       "#b6e3fe"; Behavior on m3tertiaryContainer { CAnim {} }
        property color m3onTertiaryContainer:     "#255369"; Behavior on m3onTertiaryContainer { CAnim {} }
        property color m3error:                   "#fa746f"; Behavior on m3error { CAnim {} }
        property color m3onError:                 "#490006"; Behavior on m3onError { CAnim {} }
        property color m3errorContainer:          "#871f21"; Behavior on m3errorContainer { CAnim {} }
        property color m3onErrorContainer:        "#ff9993"; Behavior on m3onErrorContainer { CAnim {} }
        property color m3success:                 "#B5CCBA"; Behavior on m3success { CAnim {} }
        property color m3onSuccess:               "#213528"; Behavior on m3onSuccess { CAnim {} }
        property color m3successContainer:        "#374B3E"; Behavior on m3successContainer { CAnim {} }
        property color m3onSuccessContainer:      "#D1E9D6"; Behavior on m3onSuccessContainer { CAnim {} }
    }

    function _applyColoursMap(coloursMap) {
        if (!coloursMap) return;
        for (const [name, rawHex] of Object.entries(coloursMap)) {
            const hex = String(rawHex).replace(/^#+/, "");
            const prop = "m3" + name.charAt(0).toUpperCase() + name.slice(1);
            const direct = "m3" + name;
            if (direct in root.palette || root.palette[direct] !== undefined) {
                root.palette[direct] = "#" + hex;
            } else if (prop in root.palette || root.palette[prop] !== undefined) {
                root.palette[prop] = "#" + hex;
            }
        }
    }

    function reloadColours() {
        const fastColours = SchemeDiscovery.getSchemeColours(root.schemeName, root.flavour, root._mode);
        if (fastColours && Object.keys(fastColours).length > 0) {
            _applyColoursMap(fastColours);
        }
    }

    function setMode(newMode) {
        root._mode = newMode;
        GreeterState.schemeMode = newMode;
        reloadColours();
    }

    function setScheme(name, flavour, mode) {
        const targetMode = (mode && mode.length > 0) ? mode : (root._mode || "dark");
        root.schemeName = name;
        root.flavour = flavour;
        root._mode = targetMode;

        GreeterState.setScheme(name, flavour, targetMode);
        reloadColours();
    }

    Component.onCompleted: {
        reloadColours();
    }

    // All surfaces opaque (tPalette aliases palette)
    readonly property M3Palette tPalette: root.palette
}
