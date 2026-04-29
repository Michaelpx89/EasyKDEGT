// Main.qml
// Entry point for the "Glass Dark" SDDM theme.
// Targets SDDM >= 0.21 running under KDE Plasma 6 (Qt 6).
//
// Layout:
//   - Full-screen background (image or solid color) with optional blur
//   - Clock centered-top
//   - User list (horizontal, scrollable)
//   - Login panel: password field, session selector, login button
//   - Error message label
//   - Power buttons bottom-right
//
// Context properties injected by SDDM:
//   sddm, userModel, sessionModel, config

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects  // Remove if unavailable; blur will be skipped

import "components"

Rectangle {
    id: root

    // Cover the primary screen
    width: Screen.width
    height: Screen.height

    // ------------------------------------------------------------------
    // State
    // ------------------------------------------------------------------
    property string selectedUser: userModel.lastUser
    property bool loginFailed: false
    property bool passwordVisible: false

    // ------------------------------------------------------------------
    // Background
    // ------------------------------------------------------------------
    Rectangle {
        id: solidBackground
        anchors.fill: parent
        color: config.backgroundColor || "#0d1117"
        visible: backgroundImage.status !== Image.Ready
    }

    Image {
        id: backgroundImage
        anchors.fill: parent
        source: config.background || ""
        fillMode: Image.PreserveAspectCrop
        smooth: true
        visible: !blurLayer.visible
        // Keep the sharp image visible until blur is ready
    }

    // Blurred background layer
    Item {
        id: blurLayer
        anchors.fill: parent
        visible: config.blur === "true" && backgroundImage.status === Image.Ready

        // Render the image into a layer so we can blur it
        Image {
            id: blurSource
            anchors.fill: parent
            source: backgroundImage.source
            fillMode: Image.PreserveAspectCrop
            smooth: true
            layer.enabled: true

            layer.effect: GaussianBlur {
                radius: parseInt(config.blurRadius) || 48
                samples: (parseInt(config.blurRadius) || 48) * 2 + 1
                cached: true
            }
        }
    }

    // Dark vignette overlay — improves text contrast on any background
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            orientation: Gradient.Vertical
            GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, 0.45) }
            GradientStop { position: 0.5; color: Qt.rgba(0, 0, 0, 0.20) }
            GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.55) }
        }
    }

    // ------------------------------------------------------------------
    // Clock — top center
    // ------------------------------------------------------------------
    Clock {
        id: clock
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: root.height * 0.12
    }

    // ------------------------------------------------------------------
    // Center Panel — user list + login form
    // ------------------------------------------------------------------
    ColumnLayout {
        id: centerPanel
        anchors.centerIn: parent
        anchors.verticalCenterOffset: 30  // Nudge down a bit from the clock
        spacing: 32
        width: Math.min(root.width * 0.85, 640)

        // ----------------------------------------------------------------
        // User List (shown when showUserList=true)
        // ----------------------------------------------------------------
        Item {
            Layout.fillWidth: true
            implicitHeight: config.showUserList === "false" ? 0 : userListView.height
            visible: config.showUserList !== "false"
            clip: true

            ListView {
                id: userListView
                anchors.horizontalCenter: parent.horizontalCenter
                width: Math.min(contentWidth, parent.width)
                height: 140
                orientation: ListView.Horizontal
                spacing: 16
                model: userModel
                clip: true

                // Center the list when it doesn't fill the width
                leftMargin: userListView.width > userListView.contentWidth
                            ? (userListView.width - userListView.contentWidth) / 2
                            : 0

                delegate: UserDelegate {
                    isSelected: root.selectedUser === name
                    onSelected: function(username) {
                        root.selectedUser = username
                        passwordField.clear()
                        passwordField.forceActiveFocus()
                        root.loginFailed = false
                    }
                }

                ScrollIndicator.horizontal: ScrollIndicator {}
            }
        }

        // ----------------------------------------------------------------
        // Login Form Card
        // ----------------------------------------------------------------
        Rectangle {
            id: loginCard
            Layout.fillWidth: true
            implicitHeight: loginLayout.implicitHeight + 40
            radius: 16
            color: Qt.rgba(1, 1, 1, 0.07)
            border.color: Qt.rgba(1, 1, 1, 0.12)
            border.width: 1

            // Glassmorphism inner glow
            Rectangle {
                anchors.fill: parent
                anchors.margins: 1
                radius: parent.radius - 1
                color: "transparent"
                border.color: Qt.rgba(1, 1, 1, 0.05)
                border.width: 1
            }

            ColumnLayout {
                id: loginLayout
                anchors {
                    top: parent.top
                    left: parent.left
                    right: parent.right
                    margins: 24
                    topMargin: 24
                }
                spacing: 16

                // Username display (when userList is visible) or text field
                Text {
                    visible: config.showUserList !== "false"
                    Layout.fillWidth: true
                    text: root.selectedUser
                    color: "white"
                    font.pixelSize: 18
                    font.weight: Font.Light
                    horizontalAlignment: Text.AlignHCenter
                }

                TextField {
                    id: usernameField
                    visible: config.showUserList === "false"
                    Layout.fillWidth: true
                    placeholderText: "Username"
                    text: userModel.lastUser
                    color: "white"
                    placeholderTextColor: Qt.rgba(1, 1, 1, 0.4)
                    font.pixelSize: parseInt(config.fontSize) || 14
                    leftPadding: 14
                    rightPadding: 14

                    background: Rectangle {
                        color: Qt.rgba(1, 1, 1, 0.08)
                        border.color: parent.activeFocus
                                      ? (config.accentColor || "#4FC3F7")
                                      : Qt.rgba(1, 1, 1, 0.18)
                        border.width: parent.activeFocus ? 2 : 1
                        radius: 8
                        Behavior on border.color { ColorAnimation { duration: 150 } }
                    }

                    KeyNavigation.tab: passwordField
                }

                // Password field row
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    TextField {
                        id: passwordField
                        Layout.fillWidth: true
                        placeholderText: "Password"
                        echoMode: root.passwordVisible
                                  ? TextInput.Normal
                                  : TextInput.Password
                        color: "white"
                        placeholderTextColor: Qt.rgba(1, 1, 1, 0.4)
                        font.pixelSize: parseInt(config.fontSize) || 14
                        leftPadding: 14
                        rightPadding: 14

                        background: Rectangle {
                            color: Qt.rgba(1, 1, 1, 0.08)
                            border.color: root.loginFailed
                                          ? "#ef5350"
                                          : (parent.activeFocus
                                             ? (config.accentColor || "#4FC3F7")
                                             : Qt.rgba(1, 1, 1, 0.18))
                            border.width: parent.activeFocus || root.loginFailed ? 2 : 1
                            radius: 8
                            Behavior on border.color { ColorAnimation { duration: 150 } }
                        }

                        Keys.onReturnPressed: performLogin()
                        Keys.onEnterPressed: performLogin()

                        onTextChanged: {
                            if (root.loginFailed) root.loginFailed = false
                        }

                        KeyNavigation.tab: loginButton
                    }

                    // Show/hide password toggle
                    Rectangle {
                        implicitWidth: 40
                        implicitHeight: passwordField.height
                        radius: 8
                        color: showHideArea.containsMouse
                               ? Qt.rgba(1, 1, 1, 0.12)
                               : Qt.rgba(1, 1, 1, 0.06)
                        border.color: Qt.rgba(1, 1, 1, 0.15)
                        border.width: 1

                        Behavior on color { ColorAnimation { duration: 120 } }

                        Text {
                            anchors.centerIn: parent
                            text: root.passwordVisible ? "🙈" : "👁"
                            font.pixelSize: 15
                        }

                        MouseArea {
                            id: showHideArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.passwordVisible = !root.passwordVisible
                        }
                    }
                }

                // Error message
                Text {
                    id: errorLabel
                    Layout.fillWidth: true
                    visible: root.loginFailed
                    text: "Incorrect password. Please try again."
                    color: "#ef9a9a"
                    font.pixelSize: 13
                    horizontalAlignment: Text.AlignHCenter

                    // Shake animation on login failure
                    SequentialAnimation on x {
                        id: shakeAnim
                        running: false
                        NumberAnimation { to: -8;  duration: 50 }
                        NumberAnimation { to:  8;  duration: 50 }
                        NumberAnimation { to: -6;  duration: 50 }
                        NumberAnimation { to:  6;  duration: 50 }
                        NumberAnimation { to:  0;  duration: 50 }
                    }
                }

                // Login button
                Rectangle {
                    id: loginButton
                    Layout.fillWidth: true
                    implicitHeight: 44
                    radius: 10

                    property bool hovered: loginBtnArea.containsMouse
                    property bool pressed: loginBtnArea.pressed
                    property color accentColor: config.accentColor || "#4FC3F7"

                    color: pressed
                           ? Qt.darker(accentColor, 1.2)
                           : (hovered ? Qt.lighter(accentColor, 1.1) : accentColor)

                    Behavior on color { ColorAnimation { duration: 120 } }

                    scale: pressed ? 0.98 : 1.0
                    Behavior on scale { NumberAnimation { duration: 80 } }

                    Text {
                        anchors.centerIn: parent
                        text: "Sign In"
                        color: "#0d1117"
                        font.pixelSize: 15
                        font.weight: Font.Medium
                        font.letterSpacing: 0.5
                    }

                    MouseArea {
                        id: loginBtnArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: performLogin()
                    }

                    activeFocusOnTab: true
                    Keys.onReturnPressed: performLogin()
                    Keys.onEnterPressed: performLogin()
                    Keys.onSpacePressed: performLogin()
                }

                // Session selector
                SessionComboBox {
                    id: sessionSelector
                    Layout.alignment: Qt.AlignHCenter
                    visible: config.showSessionSelector !== "false"
                    Layout.bottomMargin: 0
                }
            }
        }
    }

    // ------------------------------------------------------------------
    // Power Buttons — bottom right
    // ------------------------------------------------------------------
    PowerButtons {
        anchors {
            bottom: parent.bottom
            right: parent.right
            margins: 24
        }
    }

    // ------------------------------------------------------------------
    // Hostname label — bottom left
    // ------------------------------------------------------------------
    Text {
        anchors {
            bottom: parent.bottom
            left: parent.left
            margins: 20
        }
        text: sddm.hostName
        color: "white"
        opacity: 0.35
        font.pixelSize: 12
        font.letterSpacing: 1
    }

    // ------------------------------------------------------------------
    // Login logic
    // ------------------------------------------------------------------
    function performLogin() {
        var user = config.showUserList !== "false"
                   ? root.selectedUser
                   : usernameField.text.trim()

        if (user === "" || passwordField.text === "") return

        sddm.login(user, passwordField.text, sessionSelector.sessionIndex)
    }

    // ------------------------------------------------------------------
    // SDDM signal handlers
    // ------------------------------------------------------------------
    Connections {
        target: sddm

        function onLoginSucceeded() {
            // Optional: add a fade-out animation here before SDDM transitions
            loginCard.opacity = 0
        }

        function onLoginFailed() {
            root.loginFailed = true
            passwordField.clear()
            passwordField.forceActiveFocus()
            shakeAnim.restart()
        }
    }

    // ------------------------------------------------------------------
    // Initial focus
    // ------------------------------------------------------------------
    Component.onCompleted: {
        passwordField.forceActiveFocus()
    }
}
