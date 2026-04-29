#!/usr/bin/env bash
# test-theme.sh — Launch an SDDM theme in test mode without logging out.
# Usage: ./scripts/test-theme.sh [theme-name-or-path]

set -euo pipefail

THEME_ARG="${1:-}"
SYSTEM_THEMES_DIR="/usr/share/sddm/themes"
LOCAL_THEMES_DIR="${HOME}/.local/share/sddm/themes"

# Find sddm-greeter-qt6
GREETER=""
for candidate in \
    "sddm-greeter-qt6" \
    "/usr/lib/sddm/sddm-greeter-qt6" \
    "/usr/libexec/sddm/sddm-greeter-qt6" \
    "/usr/lib64/sddm/sddm-greeter-qt6"; do
    if command -v "$candidate" &>/dev/null 2>&1; then
        GREETER="$candidate"
        break
    elif [ -x "$candidate" ]; then
        GREETER="$candidate"
        break
    fi
done

if [ -z "$GREETER" ]; then
    echo "Error: sddm-greeter-qt6 not found."
    echo "Make sure sddm is installed and the greeter binary is in your PATH."
    echo ""
    echo "Try: pacman -Ql sddm | grep greeter"
    echo "  or: dpkg -L sddm | grep greeter"
    exit 1
fi

echo "Using greeter: $GREETER"

# Resolve theme path
resolve_theme() {
    local arg="$1"

    # If it's an absolute or relative path that exists, use it directly
    if [ -d "$arg" ]; then
        echo "$(realpath "$arg")"
        return 0
    fi

    # Look in system themes dir
    if [ -d "${SYSTEM_THEMES_DIR}/${arg}" ]; then
        echo "${SYSTEM_THEMES_DIR}/${arg}"
        return 0
    fi

    # Look in local themes dir
    if [ -d "${LOCAL_THEMES_DIR}/${arg}" ]; then
        echo "${LOCAL_THEMES_DIR}/${arg}"
        return 0
    fi

    # Look relative to the repo root (this script's parent directory)
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    REPO_ROOT="$(dirname "$SCRIPT_DIR")"
    if [ -d "${REPO_ROOT}/${arg}" ]; then
        echo "${REPO_ROOT}/${arg}"
        return 0
    fi

    return 1
}

if [ -z "$THEME_ARG" ]; then
    # No argument — list available themes
    echo ""
    echo "Usage: $0 [theme-name-or-path]"
    echo ""
    echo "Available themes in ${SYSTEM_THEMES_DIR}:"
    if [ -d "$SYSTEM_THEMES_DIR" ]; then
        ls "$SYSTEM_THEMES_DIR" 2>/dev/null || echo "  (none)"
    else
        echo "  (directory not found)"
    fi
    echo ""
    echo "Available themes in ${LOCAL_THEMES_DIR}:"
    if [ -d "$LOCAL_THEMES_DIR" ]; then
        ls "$LOCAL_THEMES_DIR" 2>/dev/null || echo "  (none)"
    else
        echo "  (directory not found)"
    fi
    echo ""
    echo "Themes in this repo:"
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    REPO_ROOT="$(dirname "$SCRIPT_DIR")"
    for d in "$REPO_ROOT"/*/; do
        if [ -f "${d}metadata.desktop" ]; then
            echo "  $(basename "$d")"
        fi
    done
    exit 0
fi

THEME_PATH="$(resolve_theme "$THEME_ARG")" || {
    echo "Error: Theme '${THEME_ARG}' not found."
    echo "Checked:"
    echo "  ${THEME_ARG} (relative/absolute path)"
    echo "  ${SYSTEM_THEMES_DIR}/${THEME_ARG}"
    echo "  ${LOCAL_THEMES_DIR}/${THEME_ARG}"
    exit 1
}

# Validate theme directory
if [ ! -f "${THEME_PATH}/metadata.desktop" ]; then
    echo "Warning: ${THEME_PATH}/metadata.desktop not found — may not be a valid SDDM theme."
fi

if [ ! -f "${THEME_PATH}/Main.qml" ]; then
    echo "Error: ${THEME_PATH}/Main.qml not found. Cannot launch theme."
    exit 1
fi

echo "Launching theme: $THEME_PATH"
echo "Press Ctrl+C or close the window to exit."
echo ""

exec "$GREETER" --test-mode --theme "$THEME_PATH"
