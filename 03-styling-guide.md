# Styling Guide

Practical patterns for colors, typography, animations, and glass effects in SDDM themes.

---

## Color Patterns

### CSS-style color constants
```qml
// Define palette in root or a singleton
QtObject {
    id: palette

    readonly property color bg:          "#0d1117"
    readonly property color surface:     Qt.rgba(1, 1, 1, 0.07)
    readonly property color surfaceHigh: Qt.rgba(1, 1, 1, 0.12)
    readonly property color border:      Qt.rgba(1, 1, 1, 0.14)
    readonly property color textPrimary: "#ffffff"
    readonly property color textMuted:   Qt.rgba(1, 1, 1, 0.60)
    readonly property color accent:      "#4FC3F7"
    readonly property color error:       "#ef5350"
}
```

### Dynamic accent from theme.conf
```qml
property color accentColor: Qt.color(config.accentColor || "#4FC3F7")
```

> Use `Qt.color()` to safely convert a string to a `color` type. Falls back without crashing if the string is invalid.

---

## Glassmorphism Card

The canonical frosted-glass panel:

```qml
Rectangle {
    color: Qt.rgba(1, 1, 1, 0.07)      // Low-opacity white fill
    border.color: Qt.rgba(1, 1, 1, 0.14)
    border.width: 1
    radius: 16

    // Inner highlight (top edge glow)
    Rectangle {
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
        }
        height: 1
        color: Qt.rgba(1, 1, 1, 0.18)
        radius: parent.radius
    }
}
```

---

## Input Field Styling

Override `background` and `contentItem` of `TextField`:

```qml
TextField {
    id: field

    background: Rectangle {
        color: Qt.rgba(1, 1, 1, 0.08)
        border.color: field.activeFocus ? accentColor : Qt.rgba(1, 1, 1, 0.18)
        border.width: field.activeFocus ? 2 : 1
        radius: 8

        Behavior on border.color { ColorAnimation { duration: 150 } }
        Behavior on border.width { NumberAnimation { duration: 100 } }
    }

    color: "white"
    placeholderTextColor: Qt.rgba(1, 1, 1, 0.4)
    font.pixelSize: 14
    leftPadding: 14
    rightPadding: 14
    verticalAlignment: TextInput.AlignVCenter
}
```

---

## Typography

QML `Text` has no external stylesheet — set font properties per-element or via a shared style object.

```qml
// Style object in root
QtObject {
    id: typography
    readonly property int display:   72
    readonly property int heading:   24
    readonly property int body:      14
    readonly property int caption:   12
    readonly property int mono:      13

    readonly property int weightLight:   Font.Light     // 300
    readonly property int weightNormal:  Font.Normal    // 400
    readonly property int weightMedium:  Font.Medium    // 500
}

// Usage
Text {
    font.pixelSize: typography.display
    font.weight: typography.weightLight
    font.letterSpacing: -2
}
```

### Loading custom fonts

```qml
FontLoader {
    id: bodyFont
    source: "assets/fonts/Inter-Light.ttf"
    onStatusChanged: {
        if (status === FontLoader.Error)
            console.warn("Failed to load custom font, falling back to system default")
    }
}

Text {
    font.family: bodyFont.status === FontLoader.Ready
                 ? bodyFont.name
                 : "sans-serif"
}
```

---

## Transitions and Animations

### Hover state on a button
```qml
Rectangle {
    id: btn
    property bool hovered: false

    color: hovered ? Qt.rgba(1, 1, 1, 0.15) : Qt.rgba(1, 1, 1, 0.07)
    Behavior on color { ColorAnimation { duration: 120 } }

    scale: mouseArea.pressed ? 0.96 : 1.0
    Behavior on scale { NumberAnimation { duration: 80; easing.type: Easing.OutQuad } }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        onEntered: btn.hovered = true
        onExited: btn.hovered = false
    }
}
```

### Fade in on load
```qml
Rectangle {
    id: panel
    opacity: 0

    Component.onCompleted: fadeIn.start()

    NumberAnimation {
        id: fadeIn
        target: panel
        property: "opacity"
        to: 1
        duration: 600
        easing.type: Easing.OutCubic
    }
}
```

### Slide up on load (with stagger)
```qml
Column {
    Repeater {
        model: ["item1", "item2", "item3"]
        delegate: Rectangle {
            required property int index
            opacity: 0
            y: 20

            Component.onCompleted: {
                anim.start()
            }

            ParallelAnimation {
                id: anim
                // Stagger each item by 80ms
                PauseAnimation { duration: index * 80 }

                SequentialAnimation {
                    PauseAnimation { duration: index * 80 }
                    ParallelAnimation {
                        NumberAnimation {
                            target: parent; property: "opacity"
                            to: 1; duration: 400; easing.type: Easing.OutCubic
                        }
                        NumberAnimation {
                            target: parent; property: "y"
                            to: 0; duration: 400; easing.type: Easing.OutCubic
                        }
                    }
                }
            }
        }
    }
}
```

---

## Blur Effect

### With `Qt5Compat.GraphicalEffects` (classic, widely supported)

```qml
import Qt5Compat.GraphicalEffects

Image {
    id: bg
    anchors.fill: parent
    source: config.background
    fillMode: Image.PreserveAspectCrop
    layer.enabled: true
    layer.effect: GaussianBlur {
        radius: 48
        samples: 97   // Must be odd: (radius * 2) + 1
        cached: true
    }
}
```

### With `QtQuick.Effects` (native Qt 6, no extra package)

```qml
import QtQuick.Effects

Image {
    id: bg
    source: config.background
    fillMode: Image.PreserveAspectCrop
    layer.enabled: true
    layer.effect: MultiEffect {
        blurEnabled: true
        blur: 0.8          // 0.0–1.0
        blurMax: 48
    }
}
```

> Prefer `MultiEffect` for new themes. `Qt5Compat` is being phased out.

---

## Handling Missing Avatar Icons

```qml
Image {
    id: avatar
    source: modelData.icon || ""
    visible: status === Image.Ready

    onStatusChanged: {
        if (status === Image.Error || source === "")
            console.log("No avatar for user:", modelData.name)
    }
}

// Fallback initials circle
Rectangle {
    visible: avatar.status !== Image.Ready
    width: avatar.width
    height: avatar.height
    radius: width / 2
    color: Qt.rgba(1, 1, 1, 0.15)

    Text {
        anchors.centerIn: parent
        text: modelData.realName
              ? modelData.realName.charAt(0).toUpperCase()
              : modelData.name.charAt(0).toUpperCase()
        color: "white"
        font.pixelSize: parent.width * 0.4
        font.weight: Font.Light
    }
}
```
