// UserDelegate.qml
// A single entry in the user list. Shows an avatar, display name, and
// highlights when selected or hovered.

import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root

    // -----------------------------------------------------------------------
    // Required model roles — must match userModel roles
    // -----------------------------------------------------------------------
    required property string name
    required property string realName
    required property string icon
    required property bool needsPassword

    // -----------------------------------------------------------------------
    // State
    // -----------------------------------------------------------------------
    property bool isSelected: false

    // Signal emitted when the user taps/clicks this delegate
    signal selected(string username)

    // -----------------------------------------------------------------------
    // Geometry
    // -----------------------------------------------------------------------
    implicitWidth: 120
    implicitHeight: 140

    color: "transparent"
    radius: 12

    // -----------------------------------------------------------------------
    // Highlight rectangle
    // -----------------------------------------------------------------------
    Rectangle {
        anchors.fill: parent
        radius: parent.radius
        color: root.isSelected ? Qt.rgba(1, 1, 1, 0.15) : "transparent"
        border.color: root.isSelected
                      ? (config.accentColor || "#4FC3F7")
                      : "transparent"
        border.width: 2

        Behavior on color {
            ColorAnimation { duration: 150 }
        }
        Behavior on border.color {
            ColorAnimation { duration: 150 }
        }
    }

    // -----------------------------------------------------------------------
    // Hover highlight
    // -----------------------------------------------------------------------
    Rectangle {
        anchors.fill: parent
        radius: parent.radius
        color: Qt.rgba(1, 1, 1, 0.06)
        opacity: mouseArea.containsMouse && !root.isSelected ? 1 : 0

        Behavior on opacity {
            NumberAnimation { duration: 120 }
        }
    }

    // -----------------------------------------------------------------------
    // Content
    // -----------------------------------------------------------------------
    ColumnLayout {
        anchors.centerIn: parent
        spacing: 10

        // Avatar
        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            width: 72
            height: 72
            radius: 36
            color: Qt.rgba(1, 1, 1, 0.1)
            clip: true

            Image {
                anchors.fill: parent
                source: root.icon !== "" ? root.icon : ""
                fillMode: Image.PreserveAspectCrop
                visible: root.icon !== ""
                smooth: true
            }

            // Fallback initials when no avatar is set
            Text {
                anchors.centerIn: parent
                visible: root.icon === ""
                text: {
                    var displayName = root.realName !== "" ? root.realName : root.name
                    return displayName.charAt(0).toUpperCase()
                }
                color: "white"
                font.pixelSize: 28
                font.weight: Font.Light
            }
        }

        // Display name
        Text {
            Layout.alignment: Qt.AlignHCenter
            text: root.realName !== "" ? root.realName : root.name
            color: "white"
            opacity: root.isSelected ? 1.0 : 0.75
            font.pixelSize: 13
            font.weight: root.isSelected ? Font.Medium : Font.Light
            elide: Text.ElideRight
            maximumLineCount: 1

            Behavior on opacity {
                NumberAnimation { duration: 150 }
            }
        }
    }

    // -----------------------------------------------------------------------
    // Interaction
    // -----------------------------------------------------------------------
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.selected(root.name)
    }

    // Scale animation on press
    scale: mouseArea.pressed ? 0.95 : 1.0
    Behavior on scale {
        NumberAnimation { duration: 100; easing.type: Easing.OutQuad }
    }
}
