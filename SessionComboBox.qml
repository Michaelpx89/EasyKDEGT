// SessionComboBox.qml
// A compact session selector that wraps QtQuick.Controls ComboBox and
// reads from SDDM's sessionModel context property.

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ComboBox {
    id: root

    // Expose the selected index for use in sddm.login()
    property int sessionIndex: currentIndex

    model: sessionModel
    textRole: "name"
    currentIndex: sessionModel.lastSession

    implicitWidth: 220
    implicitHeight: 36

    // -----------------------------------------------------------------------
    // Custom styling
    // -----------------------------------------------------------------------
    contentItem: RowLayout {
        spacing: 8
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 8

        Text {
            Layout.fillWidth: true
            text: root.displayText
            color: "white"
            font.pixelSize: 13
            elide: Text.ElideRight
            verticalAlignment: Text.AlignVCenter
        }

        Text {
            text: "▾"
            color: Qt.rgba(1, 1, 1, 0.6)
            font.pixelSize: 11
        }
    }

    background: Rectangle {
        color: Qt.rgba(1, 1, 1, 0.08)
        border.color: root.activeFocus
                      ? (config.accentColor || "#4FC3F7")
                      : Qt.rgba(1, 1, 1, 0.2)
        border.width: root.activeFocus ? 2 : 1
        radius: 8

        Behavior on border.color {
            ColorAnimation { duration: 150 }
        }
    }

    // -----------------------------------------------------------------------
    // Popup (dropdown list)
    // -----------------------------------------------------------------------
    popup: Popup {
        y: root.height + 4
        width: root.width
        implicitHeight: contentItem.implicitHeight
        padding: 0

        background: Rectangle {
            color: "#1e2433"
            border.color: Qt.rgba(1, 1, 1, 0.15)
            border.width: 1
            radius: 8
            layer.enabled: true
        }

        contentItem: ListView {
            implicitHeight: contentHeight
            model: root.popup.visible ? root.delegateModel : null
            clip: true
            currentIndex: root.highlightedIndex
            ScrollIndicator.vertical: ScrollIndicator {}
        }
    }

    // -----------------------------------------------------------------------
    // Delegate (each item in the dropdown)
    // -----------------------------------------------------------------------
    delegate: ItemDelegate {
        required property string name
        required property int index

        width: root.width
        height: 36

        contentItem: Text {
            text: name
            color: "white"
            font.pixelSize: 13
            verticalAlignment: Text.AlignVCenter
            leftPadding: 12
        }

        background: Rectangle {
            color: hovered ? Qt.rgba(1, 1, 1, 0.1) : "transparent"
            radius: 6
        }

        highlighted: root.highlightedIndex === index
    }
}
