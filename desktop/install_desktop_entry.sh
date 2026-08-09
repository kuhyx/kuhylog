#!/bin/bash

# ============================================================================
# Install the kuhylog launcher icon and .desktop entry.
#
# Unlike the Chrome-wrapped apps in this family, the Linux build is a native
# GTK binary produced by `flutter build linux`, so the entry launches that
# bundle directly.
#
# Icon PNGs are pre-rendered and committed under desktop/icons/, so this
# script needs no image tooling at run time. Regenerate them with:
#   PYTHONPATH=~/testsAndMisc python3 -m python_pkg.app_icons \
#       generate --app kuhylog --linux-out desktop/icons
# ============================================================================

set -euo pipefail

SCRIPT_NAME="$(basename "$0")"
DESKTOP_DIR_SRC="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(dirname "$DESKTOP_DIR_SRC")"
readonly SCRIPT_NAME DESKTOP_DIR_SRC REPO_DIR
readonly ICON_NAME="kuhylog"
# GTK reports the GApplication id as WM_CLASS, not the binary name, so
# StartupWMClass must be APPLICATION_ID from linux/CMakeLists.txt. Verify on a
# running window with: xprop -id "$(xdotool search --class kuhylog | tail -1)" WM_CLASS
readonly WM_CLASS="dev.kuhy.kuhylog"
readonly ICON_SRC_DIR="$DESKTOP_DIR_SRC/icons"
readonly ICON_THEME_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/icons/hicolor"
readonly DESKTOP_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/applications"
# Prefer a packaged launcher; fall back to the release bundle, then the debug
# one, so a development checkout that was never installed still works.
LAUNCH_CMD="/usr/bin/kuhylog"
if [[ ! -x "$LAUNCH_CMD" ]]; then
    LAUNCH_CMD="$REPO_DIR/build/linux/x64/release/bundle/kuhylog"
fi
if [[ ! -x "$LAUNCH_CMD" ]]; then
    LAUNCH_CMD="$REPO_DIR/build/linux/x64/debug/bundle/kuhylog"
fi
readonly LAUNCH_CMD

usage() {
    echo "Usage: $SCRIPT_NAME"
    echo "Installs the $ICON_NAME icon into the hicolor theme and writes a .desktop entry."
    exit 0
}

validate_requirements() {
    if [[ ! -d "$ICON_SRC_DIR" ]]; then
        echo "Error: $ICON_SRC_DIR is missing; regenerate the icons first" >&2
        exit 1
    fi
}

ensure_theme_index() {
    # A user-local hicolor tree created from scratch has no index.theme, and
    # without it gtk-update-icon-cache refuses to build a cache ("No theme
    # index file"). Seed it from the system theme when one is available.
    local system_index="/usr/share/icons/hicolor/index.theme"
    if [[ ! -f "$ICON_THEME_DIR/index.theme" && -f "$system_index" ]]; then
        install -Dm644 "$system_index" "$ICON_THEME_DIR/index.theme"
    fi
}

install_icons() {
    local size_dir size icon
    for size_dir in "$ICON_SRC_DIR"/*/; do
        size="$(basename "$size_dir")"
        icon="$size_dir$ICON_NAME.png"
        [[ -f "$icon" ]] || continue
        install -Dm644 "$icon" \
            "$ICON_THEME_DIR/${size}x${size}/apps/$ICON_NAME.png"
    done
    # Refresh the theme cache so GTK picks the icon up without a re-login.
    # Harmless if the tool is absent: the icon still resolves, just slower.
    if command -v gtk-update-icon-cache >/dev/null; then
        gtk-update-icon-cache --quiet --force "$ICON_THEME_DIR" || true
    fi
}

install_desktop_entry() {
    mkdir -p "$DESKTOP_DIR"
    cat > "$DESKTOP_DIR/$ICON_NAME.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=kuhylog
Comment=Local-first life tracker
Exec=$LAUNCH_CMD
Icon=$ICON_NAME
Terminal=false
Categories=Utility;
StartupWMClass=$WM_CLASS
EOF
    if command -v update-desktop-database >/dev/null; then
        update-desktop-database "$DESKTOP_DIR" || true
    fi
}

main() {
    validate_requirements
    ensure_theme_index
    install_icons
    install_desktop_entry
    echo "Installed $ICON_NAME icon into $ICON_THEME_DIR"
    echo "Installed $DESKTOP_DIR/$ICON_NAME.desktop"
    if [[ ! -x "$LAUNCH_CMD" ]]; then
        echo "Note: $LAUNCH_CMD does not exist yet."
        echo "      Run 'flutter build linux --release' to build the app."
    fi
}

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            usage
            ;;
        *)
            echo "Unknown option: $1" >&2
            exit 1
            ;;
    esac
done

main "$@"
