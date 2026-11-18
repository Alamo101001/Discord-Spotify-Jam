# Spotify Link Router for Windows: uninstall
& {
$appName = 'Spotify Link Router'
Remove-Item 'HKCU:\Software\Classes\SpotifyLinkRouterURL' -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item 'HKCU:\Software\Clients\StartMenuInternet\SpotifyLinkRouter' -Recurse -Force -ErrorAction SilentlyContinue
Remove-ItemProperty 'HKCU:\Software\RegisteredApplications' -Name $appName -ErrorAction SilentlyContinue
Remove-Item (Join-Path $env:LOCALAPPDATA 'SpotifyLinkRouter') -Recurse -Force -ErrorAction SilentlyContinue
Write-Host 'Removed. In the Settings window that opens, pick your normal browser as the default again.'
Start-Process 'ms-settings:defaultapps'
}
