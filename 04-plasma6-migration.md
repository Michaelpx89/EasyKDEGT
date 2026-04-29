# Plasma 6 Migration Guide

If you're porting an SDDM theme from KDE Plasma 5 (Qt 5) to Plasma 6 (Qt 6), this document covers every breaking change you're likely to hit.

---

## Qt Import Syntax

**The biggest change.** Qt 6 QML no longer requires (or accepts) version numbers on most imports.

### Before (Qt 5 / Plasma 5)
```qml
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtGraphicalEffects 1.15
```

### After (Qt 6 / Plasma 6)
```qml
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects   // ← QtGraphicalEffects moved here
```

> You must install `qt6-5compat` (Arch) / `libqt6core5compat6` (Debian/Ubuntu) for `Qt5Compat.GraphicalEffects`.

---

## GraphicalEffects: GaussianBlur and Friends

`QtGraphicalEffects` was removed from Qt 6 core. Effects are now in `Qt5Compat.GraphicalEffects` (requires the compat package) or replaced by the new `MultiEffect`.

### Option A — Qt5Compat (easiest port)
```qml
import Qt5Compat.GraphicalEffects

GaussianBlur {
    source: backgroundImage
    radius: 32
    samples: 32
    cached: true
}
```

### Option B — MultiEffect (native Qt 6, no extra package)
```qml
import QtQuick.Effects

MultiEffect {
    source: backgroundImage
    blurEnabled: true
    blur: 1.0          // 0.0–1.0
    blurMax: 32
    blurMultiplier: 1.0
}
```

`MultiEffect` is the future-proof option. `Qt5Compat` will eventually be dropped.

---

## `Screen` Attached Property

Still works in Qt 6 when attached to an `Item` inside a `Window`. However, in SDDM the root item is not always wrapped in an explicit `Window`, so you may see warnings.

**Safe approach for SDDM:**
```qml
// Root item — Screen attached property works here
Rectangle {
    id: root
    width: Screen.width
    height: Screen.height
    // ...
}
```

For multi-monitor:
```qml
property var screens: Qt.application.screens
property var primaryScreen: screens[0]
```

---

## `PlasmaComponents` Imports

| Plasma 5 Import | Plasma 6 Replacement |
|-----------------|---------------------|
| `org.kde.plasma.components 2.0` | Removed — don't use |
| `org.kde.plasma.components 3.0` | `org.kde.plasma.components` (no version) |
| `org.kde.plasma.core 2.0` | `org.kde.plasma.plasma5support` (partial) or rewrite |
| `org.kde.kirigami 2.x` | `org.kde.kirigami` (no version) |

> **Recommendation for portable themes:** Avoid KDE-specific imports entirely. Stick to `QtQuick` and `QtQuick.Controls`. This ensures your theme works even if the user has a minimal SDDM install without full KDE Frameworks.

---

## `sddm.canShutdown` Renamed

In some SDDM 0.21+ builds, the property is `sddm.canPowerOff`, not `sddm.canShutdown`. The method is now `sddm.powerOff()` not `sddm.shutdown()`.

**Safe approach — check both:**
```qml
property bool canShutdown: typeof sddm.canPowerOff !== "undefined"
                            ? sddm.canPowerOff
                            : (typeof sddm.canShutdown !== "undefined" ? sddm.canShutdown : false)

Button {
    visible: canShutdown
    onClicked: {
        if (typeof sddm.powerOff === "function") sddm.powerOff()
        else if (typeof sddm.shutdown === "function") sddm.shutdown()
    }
}
```

Or just target SDDM ≥ 0.21 and use `canPowerOff` / `powerOff()` exclusively.

---

## Required Properties

Qt 6 enforces `required property` declarations in delegates more strictly. If your delegate reads from model roles, declare them:

### Before (Qt 5 — worked but was sloppy)
```qml
ListView {
    model: userModel
    delegate: Text {
        text: name   // "name" came from model implicitly
    }
}
```

### After (Qt 6 — must be explicit)
```qml
ListView {
    model: userModel
    delegate: Text {
        required property string name
        required property string icon
        text: name
    }
}
```

Missing `required` declarations cause runtime errors in Qt 6.

---

## `FontLoader` Status Check

The `status` property values changed enum names:

| Qt 5 | Qt 6 |
|------|------|
| `FontLoader.Ready` | `FontLoader.Ready` ✓ (same) |
| `FontLoader.Error` | `FontLoader.Error` ✓ (same) |
| `FontLoader.Loading` | `FontLoader.Loading` ✓ (same) |

No change here — listed for completeness.

---

## `anchors.fill` on Root Item

Qt 6 is stricter about anchoring the root item of a component to `parent` when the parent is set externally. If your root uses `anchors.fill: parent`, ensure this doesn't conflict with explicit `width`/`height` set by SDDM.

**Safest approach:**
```qml
// Root of Main.qml
Rectangle {
    width: Screen.width
    height: Screen.height
    // Don't use anchors.fill: parent on the root
}
```

---

## Color Values

Qt 6 is stricter about color string formats. `"#rgb"` 3-digit hex still works, but named SVG colors like `"lightblue"` may behave differently in some contexts. Prefer full `"#rrggbb"` or `"#aarrggbb"` notation for predictability.

---

## `opacity` vs `layer.enabled` + `layer.effect`

Layer-based effects require `layer.enabled: true` explicitly in Qt 6:

```qml
Image {
    id: bgImage
    layer.enabled: true
    layer.effect: MultiEffect {
        blurEnabled: true
        blur: 0.8
    }
}
```

Without `layer.enabled: true`, the effect silently does nothing.

---

## Summary Checklist

When porting a Plasma 5 SDDM theme to Plasma 6:

- [ ] Remove version numbers from all `import` statements
- [ ] Replace `QtGraphicalEffects` with `Qt5Compat.GraphicalEffects` or `QtQuick.Effects`
- [ ] Update `sddm.shutdown()` → `sddm.powerOff()` and `sddm.canShutdown` → `sddm.canPowerOff`
- [ ] Add `required property` declarations to all `ListView` / `Repeater` delegates
- [ ] Replace versioned KDE imports (`org.kde.plasma.components 3.0`) with unversioned equivalents
- [ ] Set `layer.enabled: true` on any items using `layer.effect`
- [ ] Test with `sddm-greeter-qt6 --test-mode` (not `sddm-greeter`)
