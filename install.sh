#!/bin/bash
# ── Hyprtk ISO Creator GUI installer ──────────────────────────────────────
# Installs the GTK front end for the Hyprtk ISO builder. The builder itself is
# the bash script at the repo root; this only installs the GUI (and its pkexec
# helper) that drives it.
#
# The app builds a venv with system site-packages (so it can see the distro's
# PyGObject + GTK 4), pip-installs python/ into it, links the launchers into
# ~/.local/bin, records the checkout path (so the installed app can find
# hyprtk-iso-builder.sh + its assets), and drops a desktop entry + icon.
#
#   bash install.sh
#
# Env: HYPRTK_ISO_VENV (default ~/.local/share/hyprtk-iso-creator/venv), PYTHON.
# ──────────────────────────────────────────────────────────────────────────

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PY="${PYTHON:-python3}"
VENV="${HYPRTK_ISO_VENV:-$HOME/.local/share/hyprtk-iso-creator/venv}"
BIN="$HOME/.local/bin"
APPS="$HOME/.local/share/applications"
STATE="$HOME/.local/share/hyprtk-iso-creator"
ICON="$STATE/hyprtk-iso-creator.svg"

echo ":: installing hyprtk-iso-creator (GUI) into $VENV"

"$PY" -m venv --system-site-packages "$VENV"
"$VENV/bin/pip" install --quiet --upgrade pip
"$VENV/bin/pip" install --quiet "$SCRIPT_DIR/python"

mkdir -p "$BIN" "$APPS" "$STATE"
ln -sf "$VENV/bin/hyprtk-iso-creator" "$BIN/hyprtk-iso-creator"
ln -sf "$VENV/bin/hyprtk-iso-creator-helper" "$BIN/hyprtk-iso-creator-helper"

# Record the checkout so an installed console script can locate the builder.
printf '%s\n' "$SCRIPT_DIR" > "$STATE/root"

# The compositor session's PATH does not include ~/.local/bin (SDDM starts
# Hyprland without it), so write the entry with absolute Exec/Icon paths.
install -Dm644 "$SCRIPT_DIR/python/data/hyprtk-iso-creator.svg" "$ICON"
_tmp="$(mktemp)"
sed -e "s|^Exec=.*|Exec=$BIN/hyprtk-iso-creator|" \
    -e "s|^Icon=.*|Icon=$ICON|" \
    "$SCRIPT_DIR/python/data/hyprtk-iso-creator.desktop" > "$_tmp"
install -Dm644 "$_tmp" "$APPS/hyprtk-iso-creator.desktop"
rm -f "$_tmp"
command -v update-desktop-database >/dev/null 2>&1 && update-desktop-database "$APPS" >/dev/null 2>&1 || true

echo ":: hyprtk-iso-creator installed — launch it with 'hyprtk-iso-creator', or from the app menu"
