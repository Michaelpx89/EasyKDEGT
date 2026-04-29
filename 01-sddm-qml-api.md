# SDDM QML API Reference

SDDM injects several global objects and context properties into your QML root. This document covers everything that's available to your theme at runtime.

---

## Global Context Properties

### `sddm` — The Main Interface Object

The `sddm` object is how your theme talks to the display manager. It exposes login actions, power controls, and system state.

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `sddm.hostName` | `string` | Machine hostname |
| `sddm.canPowerOff` | `bool` | System supports shutdown |
| `sddm.canReboot` | `bool` | System supports reboot |
| `sddm.canSuspend` | `bool` | System supports suspend |
| `sddm.canHibernate` | `bool` | System supports hibernate |
| `sddm.canHybridSleep` | `bool` | System supports hybrid sleep |

#### Methods

```qml
// Attempt login with given credentials
sddm.login(username: string, password: string, sessionIndex: int)

// Power actions
sddm.powerOff()
sddm.reboot()
sddm.suspend()
sddm.hibernate()
sddm.hybridSleep()
```

#### Signals

```qml
// Emitted when login succeeds (screen goes away)
sddm.loginSucceeded()

// Emitted when login fails — show an error to the user
sddm.loginFailed()
```

#### Usage Example

```qml
Connections {
    target: sddm

    function onLoginFailed() {
        errorMessage.text = "Invalid username or password"
        errorMessage.visible = true
        passwordField.text = ""
        passwordField.forceActiveFocus()
    }

    function onLoginSucceeded() {
        // Optionally show a brief success animation before SDDM transitions
    }
}

Button {
    text: "Login"
    onClicked: sddm.login(userList.selectedUser, passwordField.text, sessionModel.index)
}
```

---

### `userModel` — User List

A `ListModel`-compatible object containing accounts on the system.

#### Roles

| Role | Type | Description |
|------|------|-------------|
| `name` | `string` | Login username |
| `realName` | `string` | Display name (from `/etc/passwd` GECOS) |
| `icon` | `string` | Path to avatar image |
| `needsPassword` | `bool` | Whether the account requires a password |
| `homeDir` | `string` | Path to home directory |
| `lastSession` | `string` | Last session used by this user |

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `userModel.lastUser` | `string` | Username of the most recently logged-in user |
| `userModel.count` | `int` | Number of user accounts |

#### Usage Example

```qml
ListView {
    model: userModel
    delegate: Item {
        required property string name
        required property string realName
        required property string icon

        Image {
            source: icon !== "" ? icon : "assets/icons/default-avatar.png"
        }
        Text {
            text: realName !== "" ? realName : name
        }
    }
}
```

---

### `sessionModel` — Session List

The list of available desktop sessions (X11 and Wayland).

#### Roles

| Role | Type | Description |
|------|------|-------------|
| `name` | `string` | Session display name (e.g. "Plasma (Wayland)") |
| `exec` | `string` | Path to session executable |
| `comment` | `string` | Session description |
| `xdgSessionType` | `string` | `"x11"` or `"wayland"` |
| `isHidden` | `bool` | Whether to hide from session picker |

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `sessionModel.lastSession` | `int` | Index of last used session |
| `sessionModel.count` | `int` | Number of sessions |

#### Usage Example

```qml
ComboBox {
    id: sessionSelector
    model: sessionModel
    textRole: "name"
    currentIndex: sessionModel.lastSession

    // Pass currentIndex to sddm.login()
}

Button {
    onClicked: sddm.login(username, password, sessionSelector.currentIndex)
}
```

---

### `config` — Theme Configuration

Exposes the key-value pairs from your `theme.conf` (and `theme.conf.user` overrides).

```qml
// theme.conf:
// [General]
// background=/usr/share/wallpapers/MyWallpaper/contents/images/1920x1080.jpg
// fontSize=14

Image {
    source: config.background
}

Text {
    font.pixelSize: parseInt(config.fontSize) || 14
}
```

All values are `string` typed. Parse them yourself (`parseInt`, `parseFloat`, `===  "true"`, etc.).

---

### `primaryScreen` — Screen Geometry (Qt 6)

> ⚠️ In Qt 6 / Plasma 6, the `Screen` attached property (`Screen.width`, `Screen.height`) still works when attached to a root `Window` or `Item`. However, for multi-monitor setups you may want `Qt.application.screens`.

```qml
// Simple: attached property on the root Item
Item {
    width: Screen.width
    height: Screen.height
}

// Multi-monitor: place UI on the primary screen
Item {
    property var primary: Qt.application.screens[0]
    width: primary.width
    height: primary.height
}
```

---

## Focus and Keyboard Navigation

SDDM runs before any window manager, so keyboard focus must be managed manually.

```qml
// Set initial focus explicitly
Component.onCompleted: {
    passwordField.forceActiveFocus()
}

// Tab order between fields
TextField {
    id: usernameField
    KeyNavigation.tab: passwordField
}

TextField {
    id: passwordField
    KeyNavigation.tab: usernameField
    Keys.onReturnPressed: sddm.login(usernameField.text, text, sessionSelector.currentIndex)
    Keys.onEnterPressed: sddm.login(usernameField.text, text, sessionSelector.currentIndex)
}
```

---

## Locale and Date/Time

No special SDDM API here — use standard Qt/QML:

```qml
// Live clock
Text {
    text: Qt.formatTime(new Date(), "hh:mm")

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: parent.text = Qt.formatTime(new Date(), "hh:mm")
    }
}

Text {
    text: Qt.formatDate(new Date(), "dddd, MMMM d")
}
```

---

## What SDDM Does NOT Provide

- No networking state API
- No notification system
- No access to user's KDE config (`.config/`, `.local/share/`) — SDDM runs as its own user
- No `org.kde.plasma.*` imports unless KDE Frameworks are installed system-wide and the theme explicitly imports them
