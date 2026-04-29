# SDDM Theme Development for KDE Plasma 6

A complete reference guide and working example for building custom SDDM login themes targeting KDE Plasma 6 (Qt 6 / QML 2+).

---

## Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Theme Structure](#theme-structure)
- [Documentation](#documentation)
- [Example Theme](#example-theme)
- [Testing & Installation](#testing--installation)
- [Plasma 6 Migration Notes](#plasma-6-migration-notes)
- [Contributing](#contributing)

---

## Overview

SDDM (Simple Desktop Display Manager) uses **QML** to render its login screen. Themes are self-contained directories of QML files, assets, and a metadata file. KDE Plasma 6 ships with SDDM backed by **Qt 6**, which introduces several breaking changes from Plasma 5 themes.

This repo covers:
- Full theme directory structure
- QML APIs exposed by SDDM
- A production-quality example theme (`example-theme/`)
- Plasma 6–specific gotchas and migration tips
- A test script for iterating without logging out

---

## Prerequisites

| Tool | Purpose |
|------|---------|
| `sddm` ≥ 0.21 | Display manager (ships with Plasma 6) |
| `qt6-declarative` | QML runtime |
| `qt6-quickcontrols2` | QtQuick.Controls |
| `kwin` / `kf6-*` | Optional KDE components |
| `sddm-kcm` | KDE System Settings module for SDDM |

Check your SDDM version:
```bash
sddm --version
```

---

## Quick Start

```bash
# 1. Clone this repo
git clone https://github.com/yourname/sddm-plasma6-theme-guide
cd sddm-plasma6-theme-guide

# 2. Copy the example theme to the SDDM themes directory
sudo cp -r example-theme /usr/share/sddm/themes/my-theme

# 3. Test it without logging out
./scripts/test-theme.sh my-theme

# 4. Set it as the active theme via System Settings
#    Settings → Colors & Themes → Login Screen (SDDM)
#    — or —
sudo bash -c 'echo -e "[Theme]\nCurrent=my-theme" > /etc/sddm.conf.d/theme.conf'
```

---

## Theme Structure

```
my-theme/
├── metadata.desktop          # Theme name, author, description
├── theme.conf                # Default configuration values
├── theme.conf.user           # User overrides (gitignore this)
├── Main.qml                  # Entry point — SDDM loads this
├── preview.png               # 200×150 thumbnail for SDDM KCM
├── components/
│   ├── UserDelegate.qml      # Per-user avatar/button
│   ├── SessionComboBox.qml   # Session selector dropdown
│   ├── Clock.qml             # Date/time display
│   └── PowerButtons.qml      # Shutdown / Reboot / Suspend
└── assets/
    ├── background.jpg        # Default background
    └── icons/                # Custom icon assets
```

> **Rule of thumb:** `Main.qml` is the only required file. Everything else is convention.

---

## Documentation

| File | Contents |
|------|---------|
| [docs/01-sddm-qml-api.md](docs/01-sddm-qml-api.md) | Full SDDM QML object reference |
| [docs/02-theme-structure.md](docs/02-theme-structure.md) | File-by-file breakdown |
| [docs/03-styling-guide.md](docs/03-styling-guide.md) | Fonts, colors, animations |
| [docs/04-plasma6-migration.md](docs/04-plasma6-migration.md) | Qt5 → Qt6 breaking changes |
| [docs/05-testing-workflow.md](docs/05-testing-workflow.md) | Iterate fast without rebooting |

---

## Example Theme

`example-theme/` is a fully functional dark-glass theme demonstrating:
- Clock with live time updates
- User list with avatar support
- Password field with show/hide toggle
- Session selector
- Power menu (shutdown / reboot / suspend)
- Multi-monitor awareness
- `theme.conf` customization surface

---

## Testing & Installation

### Live Test (no logout required)

```bash
./scripts/test-theme.sh example-theme
```

This runs `sddm-greeter-qt6 --test-mode --theme /path/to/theme` in a window.

### System Install

```bash
sudo cp -r example-theme /usr/share/sddm/themes/example-theme
# Then pick it in System Settings → Login Screen (SDDM)
```

### Per-user install (no sudo)

```bash
mkdir -p ~/.local/share/sddm/themes
cp -r example-theme ~/.local/share/sddm/themes/
```

> Note: Per-user themes may not load depending on your SDDM configuration. System-wide is safer.

---

## Plasma 6 Migration Notes

See [docs/04-plasma6-migration.md](docs/04-plasma6-migration.md) for the full breakdown. Key points:

- **Qt imports**: Drop version numbers. `import QtQuick 2.15` → `import QtQuick`
- **QtQuick.Controls**: Use `import QtQuick.Controls` (no version suffix)
- **`Screen` object**: Now `Qt.application.screens[0]` — the `Screen` attached property still works inside `Item`s
- **`sddm.canPowerOff`** replaces `sddm.canShutdown` in some builds — check both
- **KeyNavigation**: Focus handling is stricter in Qt 6; be explicit with `KeyNavigation.tab`
- **`PlasmaComponents3`**: Requires `plasma-framework` / `kf6-plasma`; avoid if you want a portable theme

---

## Contributing

PRs welcome! Especially for:
- Additional component examples (virtual keyboard, language selector)
- Accessibility improvements
- HiDPI / fractional scaling fixes

Please test against SDDM ≥ 0.21 before submitting.

---

## License

MIT. See [LICENSE](LICENSE).
