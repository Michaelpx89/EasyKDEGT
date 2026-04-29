# Testing Workflow

Iterating on an SDDM theme without constantly rebooting or logging out.

---

## Test Mode

SDDM ships with a `--test-mode` flag that renders your theme inside a regular window. In Plasma 6, the binary is `sddm-greeter-qt6`.

```bash
# Basic test
sddm-greeter-qt6 --test-mode --theme /usr/share/sddm/themes/my-theme

# Test from a local path (no install needed)
sddm-greeter-qt6 --test-mode --theme /home/yourname/dev/my-theme
```

> **Note:** Test mode doesn't have a real SDDM daemon behind it, so `sddm.login()` will appear to do nothing (no actual authentication). Signals like `loginFailed` can be triggered by some builds by typing a wrong password and pressing Enter.

---

## The `test-theme.sh` Script

This repo includes a helper script at `scripts/test-theme.sh`:

```bash
./scripts/test-theme.sh [theme-directory-or-name]

# Examples:
./scripts/test-theme.sh example-theme
./scripts/test-theme.sh /home/yourname/dev/my-theme
./scripts/test-theme.sh my-installed-theme   # looks in /usr/share/sddm/themes/
```

---

## QML Syntax Errors

QML errors print to stderr. Run test mode from a terminal to see them:

```bash
sddm-greeter-qt6 --test-mode --theme ./my-theme 2>&1 | grep -E "(error|Error|warning|Warning)"
```

Common errors and fixes:

| Error | Cause | Fix |
|-------|-------|-----|
| `module "QtGraphicalEffects" is not installed` | Old Qt5 import | Change to `Qt5Compat.GraphicalEffects` |
| `Cannot assign to non-existent property "canShutdown"` | Old SDDM API | Use `canPowerOff` |
| `Required property ... was not initialised` | Missing `required` in delegate | Add `required property <type> <name>` |
| `Unable to assign [undefined] to QString` | `config.key` not in `theme.conf` | Add the key to `theme.conf` with a default |

---

## Live Reload

QML doesn't hot-reload in SDDM test mode. You need to close and relaunch the greeter for changes to take effect.

**Workflow tip:** Keep a terminal with this command in your shell history:

```bash
sddm-greeter-qt6 --test-mode --theme /path/to/my-theme
```

Then `Ctrl+C`, edit, `Up Arrow`, `Enter`. Fast enough for rapid iteration.

---

## Testing Without sddm-greeter-qt6

If `sddm-greeter-qt6` is not available (some distros package it differently):

```bash
# Arch Linux
which sddm-greeter-qt6   # usually /usr/lib/sddm/sddm-greeter-qt6

# If not found, try:
/usr/lib/sddm/sddm-greeter-qt6 --test-mode --theme ./my-theme

# Or check your SDDM package for the binary location:
pacman -Ql sddm | grep greeter
dpkg -L sddm | grep greeter
```

---

## Testing on a Second Virtual Console

For realistic testing (actual auth, real session transitions):

1. Switch to a VT: `Ctrl+Alt+F3`
2. Log in as root (or sudo user)
3. `systemctl restart sddm` — this reloads the config and theme
4. Switch back: `Ctrl+Alt+F1` (or F2, depends on your setup)

This is faster than a full reboot and tests the real auth path.

---

## QML Debugging with `console.log`

SDDM routes QML's `console.log` to its journal log:

```qml
Component.onCompleted: {
    console.log("Theme loaded. Screen size:", Screen.width, "x", Screen.height)
    console.log("User count:", userModel.count)
    console.log("Last user:", userModel.lastUser)
    console.log("Sessions:", sessionModel.count)
}
```

View the output:

```bash
journalctl -u sddm -f
# or for test mode:
sddm-greeter-qt6 --test-mode --theme ./my-theme 2>&1
```

---

## Multi-Monitor Testing

Test mode runs on your current display, but you can simulate screen dimensions:

```qml
// Temporarily override for testing:
Rectangle {
    width: 2560   // Simulate 1440p
    height: 1440
    // ...
}
```

For real multi-monitor testing, you need to test at the actual SDDM level (VT method above).

---

## Packaging Your Theme

When you're ready to distribute:

```bash
# Create a clean archive (excludes git files and user config)
cd /path/to/my-theme-parent
tar --exclude='.git' \
    --exclude='theme.conf.user' \
    --exclude='*.swp' \
    --exclude='node_modules' \
    -czf my-theme-v1.0.0.tar.gz my-theme/

# Verify contents
tar -tzf my-theme-v1.0.0.tar.gz
```

**KDE Store submission:** Upload to [store.kde.org](https://store.kde.org) under the SDDM Login Themes category. Users can install directly from System Settings → Login Screen → Get New SDDM Themes.
