pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import M3Shapes
import Astra.Airlock
import "../components"

// Colours and theme state are managed directly via GreeterState and SchemeDiscovery.
// Scheme, flavour, and mode are persisted directly in greeter.json.
// All palette colours are loaded directly from system scheme files in 0ms without CLI subprocesses.
Item {
    id: root

    // TTY is dark only.
    readonly property bool light: _mode === "light" && !tty
    property string _mode: GreeterState.schemeMode || "dark"
    property string schemeName: GreeterState.schemeName || "caelestia"
    property string flavour: GreeterState.schemeFlavour || "default"
    property string variant: "tonalspot"
    property string currentUser: UserDiscovery.currentUser || ""

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

    // Sync with UserDiscovery changes for per-user settings and dynamic scheme crossfading
    Connections {
        target: UserDiscovery
        function onCurrentUserChanged() {
            const user = UserDiscovery.currentUser;
            if (user && user.length > 0) {
                GreeterState.activeUser = user;
                SchemeDiscovery.activeUser = user;
                TtyMode.activeUser = user;
            }
            root.schemeName = GreeterState.schemeName;
            root.flavour = GreeterState.schemeFlavour;
            root._mode = GreeterState.schemeMode;
            root.use12Hour = GreeterState.use12Hour;
            root.wallpaperEnabled = GreeterState.wallpaperEnabled;
            root.lavaLampEnabled = GreeterState.lavaLampEnabled;
            root.skipClockPage = GreeterState.skipClockPage;
            root.locklikeEnabled = GreeterState.locklikeEnabled;
            root.avatarShape = GreeterState.avatarShape;
            root.avatarShapeName = GreeterState.avatarShapeName;
            root.reloadColours();
        }
    }

    // --- TTY look, as Atlas and KiiteShell draw it ---------------------------
    // uiStyle: 0 follows the user's KiiteShell theme, 1 Material 3, 2 TTY;
    // --tty forces it on.
    readonly property int style: GreeterState.uiStyle
    readonly property bool tty: TtyMode.forced || (style === 0 ? TtyMode.kiiteTty : style === 2)
    readonly property bool kiiteAvailable: TtyMode.kiiteAvailable
    // The Nerd face TTY draws icons in; empty outside TTY or without one.
    property string nerdFamily: ""

    function setStyle(value) {
        GreeterState.uiStyle = value;
    }

    // The Nerd glyph for Material symbol `name`; "" outside TTY, without a
    // Nerd face, or for a symbol the table has none for.
    function nerdGlyph(name) {
        return nerdFamily.length > 0 ? TtyMode.nerdGlyph(name) : "";
    }

    onTtyChanged: _applyTty()
    Connections {
        target: TtyMode
        function onAppearanceChanged() {
            if (root.tty)
                root._applyTty();
        }
    }

    function _applyTty() {
        Tokens.setTty(tty, TtyMode.mono);
        nerdFamily = tty ? _pickNerdFace([TtyMode.iconNerd, TtyMode.mono]) : "";
        _paint();
    }

    // The face KiiteShell would pick: the Mono build of a preferred face
    // (X NF -> X NFM), then any Mono Nerd face, then any Nerd face. Mono
    // faces keep every glyph one cell wide.
    function _pickNerdFace(preferred) {
        const families = Qt.fontFamilies();
        const known = n => families.indexOf(n) >= 0;
        for (const p of preferred) {
            if (!p)
                continue;
            let mono = "";
            if (p.endsWith(" NF"))
                mono = p.slice(0, -3) + " NFM";
            else if (p.endsWith(" Nerd Font"))
                mono = p + " Mono";
            if (mono && known(mono))
                return mono;
            if ((p.endsWith(" NFM") || p.endsWith("Nerd Font Mono")) && known(p))
                return p;
        }
        if (known("Symbols Nerd Font Mono"))
            return "Symbols Nerd Font Mono";
        const anyMono = families.find(n => n.endsWith(" NFM") || n.endsWith("Nerd Font Mono"));
        if (anyMono)
            return anyMono;
        if (known("Symbols Nerd Font"))
            return "Symbols Nerd Font";
        return families.find(n => n.indexOf("Nerd Font") >= 0 || n.endsWith(" NF")) || "";
    }

    // TTY's neutrals, from KiiteShell's `look::ink`.
    readonly property var _ink: ({
        ground: "#0b0e0d", raised: "#0f1312", row: "#16211f", tab: "#1f2a28",
        border: "#2f3a37", text: "#cfd8d5", bright: "#e7eeec", variant: "#9aa6a2",
        dim: "#7d8a86", error: "#e5838a", black: "#000000"
    })

    // `c` laid over the TTY ground at `alpha`.
    function _tint(c, alpha) {
        const a = Qt.color(c), g = Qt.color(_ink.ground);
        return Qt.rgba(g.r + (a.r - g.r) * alpha, g.g + (a.g - g.g) * alpha, g.b + (a.b - g.b) * alpha, 1);
    }

    // The scheme's palette as TTY shows it: accents stay, surfaces flatten
    // to one ground that borders, not tones, divide (KiiteShell's tty_palette).
    function _ttyColour(name) {
        const b = _base;
        switch (name) {
        case "m3primary": case "m3surfaceTint": case "m3onPrimaryContainer":
        case "m3onSecondaryContainer": case "m3inversePrimary":
            return b.m3primary;
        case "m3secondary": return b.m3secondary;
        case "m3tertiary": case "m3onTertiaryContainer": return b.m3tertiary;
        case "m3success": case "m3onSuccessContainer": return b.m3success;
        case "m3onPrimary": case "m3onSecondary": case "m3onTertiary":
        case "m3onError": case "m3onSuccess":
            return _ink.ground;
        case "m3primaryContainer": return _tint(b.m3primary, 0.18);
        case "m3secondaryContainer": case "m3surfaceBright": return _ink.tab;
        case "m3tertiaryContainer": return _tint(b.m3tertiary, 0.18);
        case "m3successContainer": return _tint(b.m3success, 0.18);
        case "m3error": case "m3onErrorContainer": return _ink.error;
        case "m3errorContainer": return _tint(_ink.error, 0.2);
        case "m3onBackground": case "m3onSurface": return _ink.text;
        case "m3surfaceVariant": case "m3surfaceContainerHighest": return _ink.row;
        case "m3onSurfaceVariant": return _ink.variant;
        case "m3outline": return _ink.dim;
        case "m3outlineVariant": return _ink.border;
        case "m3surfaceContainerHigh": case "m3inverseSurface": return _ink.raised;
        case "m3inverseOnSurface": return _ink.bright;
        case "m3shadow": case "m3scrim": return _ink.black;
        }
        if (name.startsWith("term"))
            return b[name];
        return _ink.ground;
    }

    // The scheme's own colours, by palette property name; the palette shows
    // them as they are, or flattened under TTY.
    property var _base: ({})

    function _paint() {
        if (highContrast)
            return;
        for (const name of Object.keys(_base))
            root.palette[name] = tty ? _ttyColour(name) : _base[name];
    }

    // Accessibility and Quick Actions state
    property bool oskActive: false
    property bool highContrast: false
    property bool largeText: false
    property bool touchAssist: false
    property real fontScale: largeText ? 1.25 : 1.0

    onHighContrastChanged: {
        if (highContrast) {
            root.palette.m3background = "#000000";
            root.palette.m3surface = "#050707";
            root.palette.m3surfaceContainerLowest = "#000000";
            root.palette.m3surfaceContainerLow = "#0a0e0e";
            root.palette.m3surfaceContainer = "#101616";
            root.palette.m3surfaceContainerHigh = "#182222";
            root.palette.m3surfaceContainerHighest = "#202c2c";
            root.palette.m3onSurface = "#ffffff";
            root.palette.m3onBackground = "#ffffff";
            root.palette.m3outline = "#ffffff";
            root.palette.m3primary = "#50e6ff";
            root.palette.m3onPrimary = "#000000";
            root.palette.m3secondary = "#70f5d5";
            root.palette.m3onSecondary = "#000000";
        } else {
            reloadColours();
        }
    }

    // Greeter-specific persisted settings
    property bool use12Hour: GreeterState.use12Hour
    property bool lavaLampEnabled: GreeterState.lavaLampEnabled
    property bool wallpaperEnabled: GreeterState.wallpaperEnabled
    property bool skipClockPage: GreeterState.skipClockPage
    property bool locklikeEnabled: GreeterState.locklikeEnabled
    property int avatarShape: GreeterState.avatarShape
    property string avatarShapeName: GreeterState.avatarShapeName

    onLocklikeEnabledChanged: {
        if (GreeterState.locklikeEnabled !== locklikeEnabled)
            GreeterState.locklikeEnabled = locklikeEnabled;
    }

    onSkipClockPageChanged: {
        if (GreeterState.skipClockPage !== skipClockPage)
            GreeterState.skipClockPage = skipClockPage;
    }

    onUse12HourChanged: {
        if (GreeterState.use12Hour !== use12Hour)
            GreeterState.use12Hour = use12Hour;
    }

    onWallpaperEnabledChanged: {
        if (GreeterState.wallpaperEnabled !== wallpaperEnabled)
            GreeterState.wallpaperEnabled = wallpaperEnabled;
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
        property color m3inverseSurface:          "#dce8e6"; Behavior on m3inverseSurface { CAnim {} }
        property color m3inverseOnSurface:        "#2b3231"; Behavior on m3inverseOnSurface { CAnim {} }
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

        // Terminal ANSI palette swatches matching Caelestia
        property color term0: "#353434"; Behavior on term0 { CAnim {} }
        property color term1: "#fa746f"; Behavior on term1 { CAnim {} }
        property color term2: "#9bd0cc"; Behavior on term2 { CAnim {} }
        property color term3: "#f5d082"; Behavior on term3 { CAnim {} }
        property color term4: "#80ced7"; Behavior on term4 { CAnim {} }
        property color term5: "#d5efff"; Behavior on term5 { CAnim {} }
        property color term6: "#a9c5c2"; Behavior on term6 { CAnim {} }
        property color term7: "#dce8e6"; Behavior on term7 { CAnim {} }
        property color term8: "#b39e9e"; Behavior on term8 { CAnim {} }
        property color term9: "#ff80a3"; Behavior on term9 { CAnim {} }
        property color term10: "#ffd3d0"; Behavior on term10 { CAnim {} }
        property color term11: "#fff1f0"; Behavior on term11 { CAnim {} }
        property color term12: "#dcbc93"; Behavior on term12 { CAnim {} }
        property color term13: "#f9a8c2"; Behavior on term13 { CAnim {} }
        property color term14: "#ffd1c0"; Behavior on term14 { CAnim {} }
        property color term15: "#ffffff"; Behavior on term15 { CAnim {} }
    }

    function _applyColoursMap(coloursMap) {
        if (!coloursMap) return;
        const base = Object.assign({}, _base);
        for (const [name, rawHex] of Object.entries(coloursMap)) {
            const hex = String(rawHex).replace(/^#+/, "");
            const prop = "m3" + name.charAt(0).toUpperCase() + name.slice(1);
            const direct = "m3" + name;
            if (root.palette[direct] !== undefined) {
                base[direct] = "#" + hex;
            } else if (root.palette[prop] !== undefined) {
                base[prop] = "#" + hex;
            } else if (root.palette[name] !== undefined) {
                base[name] = "#" + hex;
            }
        }
        _base = base;
        _paint();
    }

    function reloadColours() {
        let targetFlavour = root.flavour;
        if (root.schemeName === "dynamic") {
            targetFlavour = UserDiscovery.currentUser || root.flavour;
        }
        const fastColours = JSON.parse(SchemeDiscovery.getSchemeColours(root.schemeName, targetFlavour, root._mode));
        if (fastColours && Object.keys(fastColours).length > 0) {
            _applyColoursMap(fastColours);
        }
    }

    property bool isPreviewing: false
    property string previewSchemeName: ""
    property string previewFlavour: ""

    function previewScheme(name, flavour) {
        if (!name || !flavour) {
            stopPreview();
            return;
        }
        if (name === root.schemeName && flavour === root.flavour && name !== "dynamic") {
            stopPreview();
            return;
        }
        root.isPreviewing = true;
        root.previewSchemeName = name;
        root.previewFlavour = flavour;

        let targetFlavour = flavour;
        if (name === "dynamic") {
            targetFlavour = UserDiscovery.currentUser || flavour;
        }

        const fastColours = JSON.parse(SchemeDiscovery.getSchemeColours(name, targetFlavour, root._mode));
        if (fastColours && Object.keys(fastColours).length > 0) {
            _applyColoursMap(fastColours);
        }
    }

    function stopPreview() {
        if (!root.isPreviewing) return;
        root.isPreviewing = false;
        root.previewSchemeName = "";
        root.previewFlavour = "";
        reloadColours();
    }

    function setMode(newMode) {
        root._mode = newMode;
        GreeterState.schemeMode = newMode;
        reloadColours();
    }

    function setScheme(name, flavour, mode) {
        root.isPreviewing = false;
        root.previewSchemeName = "";
        root.previewFlavour = "";

        const targetMode = (mode && mode.length > 0) ? mode : (root._mode || "dark");
        root.schemeName = name;
        root.flavour = flavour;
        root._mode = targetMode;

        GreeterState.setScheme(name, flavour, targetMode);
        reloadColours();
    }

    // Every palette colour, so TTY can flatten the defaults as well as a
    // loaded scheme's.
    readonly property var _paletteNames: ["m3background", "m3onBackground", "m3surface", "m3surfaceDim", "m3surfaceBright", "m3surfaceContainerLowest", "m3surfaceContainerLow", "m3surfaceContainer", "m3surfaceContainerHigh", "m3surfaceContainerHighest", "m3onSurface", "m3surfaceVariant", "m3onSurfaceVariant", "m3outline", "m3outlineVariant", "m3shadow", "m3scrim", "m3surfaceTint", "m3primary", "m3onPrimary", "m3primaryContainer", "m3onPrimaryContainer", "m3inversePrimary", "m3secondary", "m3onSecondary", "m3secondaryContainer", "m3onSecondaryContainer", "m3tertiary", "m3onTertiary", "m3tertiaryContainer", "m3onTertiaryContainer", "m3error", "m3onError", "m3errorContainer", "m3onErrorContainer", "m3success", "m3onSuccess", "m3successContainer", "m3onSuccessContainer", "m3inverseSurface", "m3inverseOnSurface"]

    Component.onCompleted: {
        const base = {};
        for (const name of _paletteNames)
            if (root.palette[name] !== undefined)
                base[name] = String(root.palette[name]);
        _base = base;

        const user = UserDiscovery.currentUser;
        if (user && user.length > 0) {
            GreeterState.activeUser = user;
            SchemeDiscovery.activeUser = user;
            TtyMode.activeUser = user;
        }
        reloadColours();
        if (tty)
            _applyTty();
    }

    // All surfaces opaque (tPalette aliases palette)
    readonly property M3Palette tPalette: root.palette
}
