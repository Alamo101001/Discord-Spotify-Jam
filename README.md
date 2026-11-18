# Discord-Spotify-Jam

Click a Spotify link or a Jam invite in Discord (or any app) and it opens in the **Spotify app**, not your browser. Every other link still opens in your normal browser.

## Download

| System | Download | What's inside |
| --- | --- | --- |
| **Windows 10 / 11** | [Spotify-Link-Router-Windows.zip](https://github.com/Alamo101001/Discord-Spotify-Jam/releases/latest/download/Spotify-Link-Router-Windows.zip) | Double-click installer and uninstaller |
| **Linux** | [Spotify-Link-Router-Linux.tar.gz](https://github.com/Alamo101001/Discord-Spotify-Jam/releases/latest/download/Spotify-Link-Router-Linux.tar.gz) | `install.sh`, `uninstall.sh`, the router |

You need the Spotify desktop app installed first. Neither version needs admin rights, and both change settings only for your own account.

## Install on Windows

1. Download the Windows zip, right-click it, and choose **Extract All**.
2. Double-click **Install Spotify Link Router.cmd**.
3. If Windows shows **"Windows protected your PC"**, click **More info**, then **Run anyway**. Windows shows this for any downloaded script.
4. Settings opens at **Default apps**. Set **HTTP** and **HTTPS** to **Spotify Link Router**. Windows doesn't let installers change your default browser, so this click is yours.
5. Test it: press **Windows key + R**, paste `https://open.spotify.com/playlist/37i9dQZF1DXcBWIGoYBM5M`, and press Enter. Spotify should open the playlist.

To remove it, double-click **Uninstall Spotify Link Router.cmd**, then set HTTP and HTTPS back to your browser in the Settings window that opens.

Prefer PowerShell? [windows/install.ps1](windows/install.ps1) is exactly what the `.cmd` runs. Paste it into Windows PowerShell.

## Install on Linux

```bash
tar -xzf Spotify-Link-Router-Linux.tar.gz
cd Spotify-Link-Router-Linux
./install.sh
```

Test it with `xdg-open https://open.spotify.com/playlist/37i9dQZF1DXcBWIGoYBM5M`. To remove it, run `./uninstall.sh`.

Needs `xdg-mime`, `gio`, `python3`, and `curl`, which most desktop distros include.

## How it works

The router registers as your default handler for web links. When a link comes in:

- **`open.spotify.com/...`** links become Spotify app links (`spotify:track:...`, `spotify:socialsession:...` for Jams) and open in the app.
- **`spotify.link/...`** short links are followed to their `open.spotify.com` address first.
- **Everything else**, or anything it can't convert, goes straight to the browser you had before installing.

Each version keeps a log of what it did with every link: `%LOCALAPPDATA%\SpotifyLinkRouter\router.log` on Windows, `~/.cache/link-router.log` on Linux.

## Status

| | Linux | Windows |
| --- | --- | --- |
| Tracks, albums, playlists | Working | Logic tested, not yet run on Windows |
| Jam invites | Working | Logic tested, not yet run on Windows |
| Install and uninstall | Working | Not yet run on Windows |

The Windows scripts were syntax-checked and their link handling tested with PowerShell 7 on Linux. If you try them on Windows, please open an issue saying whether they worked.

## Troubleshooting

| Problem | Fix |
| --- | --- |
| Spotify links still open in the browser | Check HTTP and HTTPS are set to the router. Links clicked inside a web page stay in the browser; only links opened from other apps go through the router. |
| A black window flashes briefly (Windows) | Normal. That's the router starting. |
| Antivirus warns about a hidden PowerShell script | The router runs PowerShell without a window, which some tools flag. All its files are in `%LOCALAPPDATA%\SpotifyLinkRouter`. |
| You changed browsers after installing | Uninstall, set the new browser as default, and install again. |

## For maintainers

The `.cmd` files are generated. Edit `windows/install.ps1` or `windows/uninstall.ps1`, then run `tools/build.sh`, which rebuilds the `.cmd` files and the download packages in `dist/`. Attach the two files in `dist/` to a new GitHub Release.
