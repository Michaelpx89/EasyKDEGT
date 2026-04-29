// PowerButtons.qml
// Shutdown / Reboot / Suspend buttons. Each button is shown only if
// SDDM reports that the action is available AND the theme config
// includes it in the powerButtons list.

import QtQuick
import QtQuick.Layouts

RowLayout {
    id: root

    spacing: 8

    // Parse which buttons to show from theme.conf
    // Expected format: "shutdown,reboot,suspend"
    property var enabledButtons: {
        var val = config.powerButtons || "shutdown,reboot,suspend"
        if (val === "all") return ["shutdown", "reboot", "suspend", "hibernate"]
        if (val === "none") return []
        return val.split(",").map(function(s) { return s.trim() })
    }

    function buttonEnabled(name) {
        return enabledButtons.indexOf(name) !== -1
    }

    // -----------------------------------------------------------------------
    // Shutdown
    // -----------------------------------------------------------------------
    PowerButton {
        visible: root.buttonEnabled("shutdown") && sddm.canPowerOff
        icon: "⏻"
        label: "Shut Down"
        onActivated: sddm.powerOff()
    }

    // -----------------------------------------------------------------------
    // Reboot
    // -----------------------------------------------------------------------
    PowerButton {
        visible: root.buttonEnabled("reboot") && sddm.canReboot
        icon: "↺"
        label: "Restart"
        onActivated: sddm.reboot()
    }

    // -----------------------------------------------------------------------
    // Suspend
    // -----------------------------------------------------------------------
    PowerButton {
        visible: root.buttonEnabled("suspend") && sddm.canSuspend
        icon: "⏾"
        label: "Suspend"
        onActivated: sddm.suspend()
    }

    // -----------------------------------------------------------------------
    // Hibernate
    // -----------------------------------------------------------------------
    PowerButton {
        visible: root.buttonEnabled("hibernate") && sddm.canHibernate
        icon: "❄"
        label: "Hibernate"
        onActivated: sddm.hibernate()
    }
}

// ---------------------------------------------------------------------------
// PowerButton — internal component
// ---------------------------------------------------------------------------
component PowerButton: Rectangle {
    id: btn

    signal activated()

    property string icon: ""
    property string label: ""

    implicitWidth: 44
    implicitHeight: 44
    radius: 22
    color: ma.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(1, 1, 1, 0.06)
    border.color: Qt.rgba(1, 1, 1, 0.15)
    border.width: 1

    Behavior on color { ColorAnimation { duration: 120 } }

    // Icon
    Text {
        anchors.centerIn: parent
        text: btn.icon
        color: "white"
        opacity: 0.8
        font.pixelSize: 18
    }

    // Tooltip on hover
    Rectangle {
        visible: ma.containsMouse
        anchors.bottom: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottomMargin: 6
        width: tipText.implicitWidth + 16
        height: 24
        radius: 4
        color: "#1e2433"
        border.color: Qt.rgba(1, 1, 1, 0.15)
        border.width: 1

        Text {
            id: tipText
            anchors.centerIn: parent
            text: btn.label
            color: "white"
            font.pixelSize: 11
        }
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: btn.activated()
    }

    scale: ma.pressed ? 0.9 : 1.0
    Behavior on scale { NumberAnimation { duration: 80 } }
}
