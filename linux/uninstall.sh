#!/bin/bash
# Remove the Spotify link router and give web links back to your normal browser.
set -u
APPS=${XDG_DATA_HOME:-$HOME/.local/share}/applications
CONFDIR=${XDG_CONFIG_HOME:-$HOME/.config}/link-router

browser=$(basename "$(cat "$CONFDIR/browser" 2>/dev/null)" 2>/dev/null)
[ -n "$browser" ] || browser=firefox_firefox.desktop
xdg-mime default "$browser" x-scheme-handler/http x-scheme-handler/https

rm -f "$HOME/.local/bin/link-router" "$APPS/link-router.desktop"
command -v update-desktop-database >/dev/null && update-desktop-database "$APPS" 2>/dev/null
rm -rf "$CONFDIR"
echo "Removed. Web links open with $browser again."
