#!/bin/bash
# Install the Spotify link router for the current user (no sudo needed).
# Spotify web links and Jam invites then open in the Spotify app; every other link
# keeps opening in the browser you use now.
set -eu
here=$(cd "$(dirname "$0")" && pwd)
BIN=$HOME/.local/bin
APPS=${XDG_DATA_HOME:-$HOME/.local/share}/applications
CONFDIR=${XDG_CONFIG_HOME:-$HOME/.config}/link-router
DESKTOP=link-router.desktop

for tool in xdg-mime gio python3 curl; do
    command -v "$tool" >/dev/null || { echo "Missing '$tool'. Install it and run this again."; exit 1; }
done
if [ "$(xdg-mime query default x-scheme-handler/spotify)" = "" ]; then
    echo "The Spotify app doesn't seem to be installed (nothing handles spotify: links)."
    echo "Install Spotify first, then run this again."
    exit 1
fi

mkdir -p "$BIN" "$APPS" "$CONFDIR"

# Remember the current browser, unless the router is already the default (a re-run)
current=$(xdg-mime query default x-scheme-handler/https)
if [ -n "$current" ] && [ "$current" != "$DESKTOP" ]; then
    found=""
    IFS=: read -ra sysdirs <<< "${XDG_DATA_DIRS:-/usr/local/share:/usr/share}"
    for d in "${XDG_DATA_HOME:-$HOME/.local/share}" "${sysdirs[@]}" /var/lib/snapd/desktop \
             /var/lib/flatpak/exports/share "$HOME/.local/share/flatpak/exports/share"; do
        [ -f "$d/applications/$current" ] && { found="$d/applications/$current"; break; }
    done
    if [ -n "$found" ]; then
        echo "$found" > "$CONFDIR/browser"
        echo "Other links will keep opening with: $current"
    else
        echo "Could not find $current; other links will open in Firefox."
    fi
fi

# Back up your link settings once
mime=${XDG_CONFIG_HOME:-$HOME/.config}/mimeapps.list
[ -f "$mime" ] && [ ! -f "$CONFDIR/mimeapps.list.before-install" ] && cp -p "$mime" "$CONFDIR/mimeapps.list.before-install"

install -m 755 "$here/link-router" "$BIN/link-router"
cat > "$APPS/$DESKTOP" <<EOF
[Desktop Entry]
Type=Application
Name=Link Router (Spotify links to the app)
Comment=Opens Spotify links in the Spotify app and every other link in your normal browser
Exec=$BIN/link-router %u
Terminal=false
NoDisplay=true
MimeType=x-scheme-handler/http;x-scheme-handler/https;
EOF
command -v update-desktop-database >/dev/null && update-desktop-database "$APPS" 2>/dev/null || true
xdg-mime default "$DESKTOP" x-scheme-handler/http x-scheme-handler/https

echo "Installed. Test it with:"
echo "  xdg-open https://open.spotify.com/playlist/37i9dQZF1DXcBWIGoYBM5M"
