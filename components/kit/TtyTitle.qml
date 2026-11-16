import QtQuick
import Astra.Airlock
import "../../services"
// A TTY title, printed the way KiiteShell's are: in bursts of a few
// characters, now and then stalling, as over a slow modem, with a couple of
// cells still scrambling ahead of a block cursor. Once it is all there the
// cursor keeps blinking if `cursor` is set.
StyledText {
    id: root

    property string title
    property bool cursor: false

    // Characters printed so far, and the tick counting the bursts
    property int printed: title.length
    property int tick: 0
    property bool blinkOn: true

    readonly property var bursts: [2, 1, 3, 0, 2, 3, 1, 2, 0, 3, 2, 1]
    readonly property string noise: "#$%&@*+=?<>/\\|01"

    function scrambled() {
        let out = title.slice(0, printed);
        for (let i = printed; i < Math.min(title.length, printed + 2); ++i)
            out += title[i] === " " ? " " : noise[(i * 7 + tick * 13) % noise.length];
        return out + "█";
    }

    text: printed < title.length ? scrambled() : title + (cursor ? (blinkOn ? "█" : " ") : "")
    color: Colours.palette.m3primary
    font: Tokens.font.body.medium

    onTitleChanged: {
        printed = 0;
        tick = 0;
        typeTimer.restart();
    }

    Timer {
        id: typeTimer
        interval: 66
        repeat: true
        running: root.visible && root.printed < root.title.length
        onTriggered: {
            root.printed = Math.min(root.title.length, root.printed + root.bursts[(root.tick * 7 + 3) % 12]);
            root.tick += 1;
        }
    }

    Timer {
        interval: 530
        repeat: true
        running: root.visible && root.cursor && root.printed >= root.title.length
        onTriggered: root.blinkOn = !root.blinkOn
    }
}
