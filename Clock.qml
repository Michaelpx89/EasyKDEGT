// Clock.qml
// Live clock with configurable time and date format.
// Reads timeFormat and dateFormat from the theme config object passed via the
// `config` context property, or falls back to hard-coded defaults.

import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: root

    spacing: 4

    // Public API — override these or rely on theme config
    property string timeFormat: config.timeFormat || "hh:mm"
    property string dateFormat: config.dateFormat || "dddd, MMMM d"

    // -----------------------------------------------------------------------
    // Time Label
    // -----------------------------------------------------------------------
    Text {
        id: timeLabel
        Layout.alignment: Qt.AlignHCenter
        text: Qt.formatTime(currentTime, root.timeFormat)
        color: "white"
        font.pixelSize: 72
        font.weight: Font.Light
        font.letterSpacing: -2
        renderType: Text.NativeRendering

        // Shadow for legibility on any background
        layer.enabled: true
        layer.effect: null  // Replace with a drop shadow effect if desired
    }

    // -----------------------------------------------------------------------
    // Date Label
    // -----------------------------------------------------------------------
    Text {
        id: dateLabel
        Layout.alignment: Qt.AlignHCenter
        text: Qt.formatDate(currentTime, root.dateFormat)
        color: "white"
        opacity: 0.75
        font.pixelSize: 18
        font.weight: Font.Light
        font.letterSpacing: 1
        renderType: Text.NativeRendering
    }

    // -----------------------------------------------------------------------
    // Timer — updates both labels every second
    // -----------------------------------------------------------------------
    property date currentTime: new Date()

    Timer {
        id: clockTimer
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.currentTime = new Date()
    }
}
