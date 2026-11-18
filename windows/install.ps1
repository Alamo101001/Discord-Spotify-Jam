# Spotify Link Router for Windows: install (current user only, no admin needed)
# Spotify web links and Jam invites open in the Spotify app; every other link opens in your normal browser.
& {
$ErrorActionPreference = 'Stop'
$appName = 'Spotify Link Router'
$dir = Join-Path $env:LOCALAPPDATA 'SpotifyLinkRouter'

# 1. The Spotify app must be installed (it registers spotify: links)
if (-not (Test-Path 'Registry::HKEY_CLASSES_ROOT\spotify')) {
    Write-Warning 'The Spotify app is not installed. Install it from spotify.com/download or the Microsoft Store, then run this again.'
    return
}
New-Item -ItemType Directory -Force -Path $dir | Out-Null

# 2. Remember the current browser so non-Spotify links keep going there
$browserFile = Join-Path $dir 'browser.txt'
$progId = $null
foreach ($k in 'UserChoiceLatest', 'UserChoice') {
    $p = "HKCU:\Software\Microsoft\Windows\Shell\Associations\UrlAssociations\https\$k"
    $v = (Get-ItemProperty -Path $p -ErrorAction SilentlyContinue).ProgId
    if ($v) { $progId = $v; break }
}
if ($progId -and $progId -ne 'SpotifyLinkRouterURL') {
    $cmd = (Get-ItemProperty -Path "Registry::HKEY_CLASSES_ROOT\$progId\shell\open\command" -ErrorAction SilentlyContinue).'(default)'
    if ($cmd) { Set-Content -Path $browserFile -Value $cmd }
}
if (Test-Path $browserFile) { Write-Host "Other links will keep opening in: $(Get-Content $browserFile -Raw)" }
else { Write-Host 'Could not detect your browser, so other links will open in Microsoft Edge.' }

# 3. The router itself
$router = @'
param([string]$Url)
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$dir = Split-Path -Parent $MyInvocation.MyCommand.Path
$log = Join-Path $dir 'router.log'
function Log($m) { Add-Content -Path $log -Value ("{0} {1}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $m) }

function Open-Browser([string]$u) {
    Log "browser: $u"
    $cmdFile = Join-Path $dir 'browser.txt'
    if (Test-Path $cmdFile) {
        $cmd = (Get-Content $cmdFile -Raw).Trim()
        $exe = $null; $rest = ''
        if ($cmd -match '^\s*"([^"]+)"\s*(.*)$') { $exe = $Matches[1]; $rest = $Matches[2] }
        elseif ($cmd -match '^\s*(\S+)\s*(.*)$') { $exe = $Matches[1]; $rest = $Matches[2] }
        if ($exe -and (Test-Path $exe)) {
            if (-not $u) { Start-Process -FilePath $exe; return }
            if ($rest -match '%1') { $argLine = $rest.Replace('%1', $u) } else { $argLine = ($rest + ' "' + $u + '"').Trim() }
            Start-Process -FilePath $exe -ArgumentList $argLine
            return
        }
    }
    Start-Process ('microsoft-edge:' + $u)
}

function To-SpotifyUri([string]$u) {
    try { $uri = [Uri]$u } catch { return $null }
    if ($uri.Host -ne 'open.spotify.com') { return $null }
    $parts = @($uri.AbsolutePath.Split('/') | Where-Object { $_ })
    if ($parts.Count -gt 0 -and $parts[0] -like 'intl-*') { $parts = @($parts | Select-Object -Skip 1) }
    if ($parts.Count -gt 0 -and $parts[0] -eq 'embed') { $parts = @($parts | Select-Object -Skip 1) }
    if ($parts.Count -lt 2) { return $null }
    return 'spotify:' + ($parts -join ':')
}

function Resolve-Short([string]$u) {
    try {
        $r = Invoke-WebRequest -Uri $u -UseBasicParsing -MaximumRedirection 10 -TimeoutSec 8
        $final = $r.BaseResponse.ResponseUri.AbsoluteUri
        if ($final -like 'https://open.spotify.com/*') { return $final }
        $m = [regex]::Match($r.Content, 'https://open\.spotify\.com/[A-Za-z0-9_/?=&.\-]+')
        if ($m.Success) { return $m.Value }
    } catch { Log "could not resolve $u : $($_.Exception.Message)" }
    return $null
}

if (-not $Url) { Open-Browser ''; return }
$target = $Url
if ($target -match '^https?://(spotify\.link|spotify\.app\.link)/') {
    $long = Resolve-Short $target
    if (-not $long) { Open-Browser $Url; return }
    $target = $long
}
$sp = To-SpotifyUri ($target -replace '^http://', 'https://')
if ($sp) {
    try { Log "spotify: $Url -> $sp"; Start-Process $sp; return }
    catch { Log "spotify failed: $($_.Exception.Message)" }
}
Open-Browser $Url
'@
$routerPath = Join-Path $dir 'router.ps1'
Set-Content -Path $routerPath -Value $router -Encoding UTF8

# 4. Register it as a browser choice for this user (HKCU only)
function Set-Reg($path, $n, $value) {
    if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
    if ($n -eq '') { Set-Item -Path $path -Value $value }
    else { New-ItemProperty -Path $path -Name $n -Value $value -PropertyType String -Force | Out-Null }
}
$run = "conhost.exe --headless powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$routerPath`""
$icon = (Get-ItemProperty -Path 'Registry::HKEY_CLASSES_ROOT\spotify\DefaultIcon' -ErrorAction SilentlyContinue).'(default)'
if (-not $icon) { $icon = "$env:SystemRoot\System32\shell32.dll,0" }

$cls = 'HKCU:\Software\Classes\SpotifyLinkRouterURL'
Set-Reg $cls '' 'Spotify Link Router URL'
Set-Reg $cls 'URL Protocol' ''
Set-Reg "$cls\DefaultIcon" '' $icon
Set-Reg "$cls\shell\open\command" '' "$run `"%1`""

$app = 'HKCU:\Software\Clients\StartMenuInternet\SpotifyLinkRouter'
Set-Reg $app '' $appName
Set-Reg "$app\DefaultIcon" '' $icon
Set-Reg "$app\shell\open\command" '' $run
Set-Reg "$app\Capabilities" 'ApplicationName' $appName
Set-Reg "$app\Capabilities" 'ApplicationDescription' 'Opens Spotify links in the Spotify app and everything else in your normal browser.'
Set-Reg "$app\Capabilities" 'ApplicationIcon' $icon
Set-Reg "$app\Capabilities\URLAssociations" 'http' 'SpotifyLinkRouterURL'
Set-Reg "$app\Capabilities\URLAssociations" 'https' 'SpotifyLinkRouterURL'
Set-Reg 'HKCU:\Software\RegisteredApplications' $appName 'Software\Clients\StartMenuInternet\SpotifyLinkRouter\Capabilities'

# 5. Windows only lets you pick the default yourself
Write-Host ''
Write-Host "Installed. In the Settings window that opens, set HTTP and HTTPS to '$appName'."
Start-Process "ms-settings:defaultapps?registeredAppUser=$([uri]::EscapeDataString($appName))"
}
