# Theme Structure

A complete breakdown of every file in an SDDM theme directory.

---

## Directory Layout

```
my-theme/
├── metadata.desktop          # Required — theme identity
├── theme.conf                # Required — default config values
├── theme.conf.user           # Optional — user overrides (gitignore!)
├── Main.qml                  # Required — entry point
├── preview.png               # Recommended — 200×150 px thumbnail
├── LICENSE                   # Recommended
├── README.md                 # Recommended
├── components/               # Convention — reusable QML components
│   ├── UserDelegate.qml
│   ├── SessionComboBox.qml
│   ├── Clock.qml
│   └── PowerButtons.qml
└── assets/                   # Convention — images, fonts, icons
    ├── background.jpg
    ├── fonts/
    └── icons/
```

Only `metadata.desktop`, `theme.conf`, and `Main.qml` are strictly required. Structure everything else however you want — SDDM doesn't care about directory names beyond the root files.

---

## `metadata.desktop`

Standard XDG desktop entry that SDDM reads for theme metadata.

```ini
[SddmGreeterTheme]
Name=My Theme
Description=A dark glass login theme for KDE Plasma 6
Author=Your Name
AuthorEmail=you@example.com
License=MIT
Type=sddm-theme
Version=1.0.0
Website=https://github.com/yourname/my-theme
ScreenShot=preview.png
MainScript=Main.qml
ConfigFile=theme.conf
TranslationsDirectory=translations
```

**Key fields:**

| Field | Purpose |
|-------|---------|
| `Name` | Display name in SDDM KCM |
| `ScreenShot` | Path to preview image (relative to theme root) |
| `MainScript` | QML entry point (default: `Main.qml`) |
| `ConfigFile` | Config file path (default: `theme.conf`) |

---

## `theme.conf`

INI-format file providing default values that your QML reads through the `config` context property.

```ini
[General]
# Path to background image. Supports absolute paths and relative paths from theme root.
background=assets/background.jpg

# Blur background (true/false)
blur=true

# Font size for UI elements
fontSize=14

# Show user list or just a username text field
showUserList=true

# Accent color (used in QML as config.accentColor)
accentColor=#4FC3F7

# Show seconds in the clock
showSeconds=false
```

**All values are strings in QML.** Parse them explicitly:

```qml
property bool blurEnabled: config.blur === "true"
property int baseFontSize: parseInt(config.fontSize) || 14
property color accent: config.accentColor || "#4FC3F7"
```

### `theme.conf.user`

Same format as `theme.conf`. Values here override `theme.conf`. This is how KDE System Settings writes per-user theme customizations. **Add this to `.gitignore`** — it's a machine-specific file.

---

## `Main.qml`

The entry point SDDM loads. Must be a `Rectangle`, `Item`, or `Window` at the root level.

**Minimum viable Main.qml:**

```qml
import QtQuick
import QtQuick.Controls

Rectangle {
    width: Screen.width
    height: Screen.height
    color: "#1a1a2e"

    TextField {
        id: passwordField
        anchors.centerIn: parent
        placeholderText: "Password"
        echoMode: TextInput.Password
        Keys.onReturnPressed: sddm.login(userModel.lastUser, text, sessionModel.lastSession)
    }

    Component.onCompleted: passwordField.forceActiveFocus()

    Connections {
        target: sddm
        function onLoginFailed() {
            passwordField.clear()
            passwordField.forceActiveFocus()
        }
    }
}
```

**Root item tips:**
- Always set `width`/`height` to cover the screen
- SDDM stretches your root item to fill the display — you don't need a `Window`
- If you want per-screen positioning in multi-monitor setups, use `Qt.application.screens`

---

## Component Files

QML components in the `components/` folder are referenced with relative paths:

```qml
// In Main.qml
import "components"

Clock {
    anchors.top: parent.top
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.topMargin: 48
}
```

---

## `preview.png`

- **Size**: 200×150 px (KDE System Settings expects this ratio)
- **Format**: PNG or JPEG
- Keep it under 100 KB
- Should represent what the theme actually looks like at login

---

## Asset Paths

Reference assets from QML using paths relative to the **theme directory**:

```qml
// Works — relative to theme root
Image { source: "assets/background.jpg" }

// Also works — absolute
Image { source: "/usr/share/sddm/themes/my-theme/assets/background.jpg" }

// Avoid — Qt.resolvedUrl is useful but unnecessary for static assets
```

---

## Custom Fonts

Bundle fonts inside your theme and register them at startup:

```qml
// In Main.qml, before any Text elements use the font
FontLoader {
    id: customFont
    source: "assets/fonts/MyFont-Regular.ttf"
}

Text {
    font.family: customFont.name
}
```

> If the font fails to load, QML silently falls back to the system default. Always check `customFont.status === FontLoader.Ready` before using it.
