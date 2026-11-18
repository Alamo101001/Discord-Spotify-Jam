#!/bin/bash
# Rebuild the double-click .cmd files from the .ps1 sources, then the download packages in dist/.
#   tools/build.sh
set -eu
cd "$(dirname "$0")/.."

# A .cmd is a short batch header plus the PowerShell script; the header runs everything after #PSSTART.
make_cmd() { # $1=ps1 source  $2=output .cmd  $3=window title
    { printf '%s\r\n' '@echo off' "title $3" 'set "SLR_SELF=%~f0"' \
        "powershell.exe -NoProfile -ExecutionPolicy Bypass -Command \"\$s = [IO.File]::ReadAllText(\$env:SLR_SELF); \$i = \$s.IndexOf('#PS' + 'START'); Invoke-Expression \$s.Substring(\$i)\"" \
        'echo.' 'pause' 'exit /b' '' '#PSSTART'
      sed 's/\r$//; s/$/\r/' "$1"; } > "$2"
}
make_cmd windows/install.ps1   "windows/Install Spotify Link Router.cmd"   "Spotify Link Router - Install"
make_cmd windows/uninstall.ps1 "windows/Uninstall Spotify Link Router.cmd" "Spotify Link Router - Uninstall"

rm -rf dist && mkdir -p dist/stage/Spotify-Link-Router-Windows dist/stage/Spotify-Link-Router-Linux
cp windows/*.cmd dist/stage/Spotify-Link-Router-Windows/
cp linux/link-router linux/install.sh linux/uninstall.sh dist/stage/Spotify-Link-Router-Linux/
chmod 755 dist/stage/Spotify-Link-Router-Linux/*

python3 -I - <<'EOF'
import os, zipfile
src = "dist/stage/Spotify-Link-Router-Windows"
with zipfile.ZipFile("dist/Spotify-Link-Router-Windows.zip", "w", zipfile.ZIP_DEFLATED) as z:
    for f in sorted(os.listdir(src)):
        z.write(os.path.join(src, f), f)
EOF
tar -czf dist/Spotify-Link-Router-Linux.tar.gz --owner=0 --group=0 --numeric-owner -C dist/stage Spotify-Link-Router-Linux
rm -rf dist/stage
ls -l dist
