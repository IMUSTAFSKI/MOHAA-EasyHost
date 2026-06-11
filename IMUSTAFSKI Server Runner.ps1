param(
    [switch]$NoMenu,
    [switch]$RegenerateConfig
)
#ParamStating In
$ErrorActionPreference = "Stop"
$RunnerVersion = "1.0.1"
$RunnerGitHubUrl = "https://github.com/IMUSTAFSKI/MOHAA-EasyHost"
$RunnerRawScriptUrl = "https://raw.githubusercontent.com/IMUSTAFSKI/MOHAA-EasyHost/main/IMUSTAFSKI%20Server%20Runner.ps1"
#Oh Dear we gonna start
#                       :)
$GameDir = $PSScriptRoot
$SettingsPath = Join-Path $GameDir "imustafski-runner-settings.json"
$LegacySettingsPaths = @(
    (Join-Path $GameDir "moh-server-settings.json")
)
$GeneratedConfigName = "imustafski-server.cfg"
$GeneratedConfigPath = Join-Path $GameDir "main\$GeneratedConfigName"
$PlayerConfigPath = Join-Path $GameDir "main\configs\unnamedsoldier.cfg"
$AutoexecPath = Join-Path $GameDir "main\autoexec.cfg"
$AllowedHostingGuideUrl = "https://github.com/IMUSTAFSKI/MOHAA-EasyHost/blob/main/Hosting%20Methods.md"
$AllowedServerExeNames = @("MOHAA_server.exe")
$AllowedGameExeNames = @("MOHAA.exe")
$script:LastFriendCommand = ""
#Server Config Settings will be placed in the main (dir)
function Get-DefaultSettings {
    [pscustomobject]@{
        ServerName = "IMUSTAFSKI standard server"
        Password = ""
        SelectedGame = "mohaa"
        HostingMode = "tunnel"
        MatchMode = "ffa"
        HostingGuideUrl = $AllowedHostingGuideUrl
        MapRotation = @("dm/mohdm6") #changeable via the tui(done)
        TimeLimit = 20 #in minutes will be explained later in the tui(done)
        MaxPlayers = 8
        Port = 12203 #default(changeable) tui
        GameType = 1
        Cheats = 0
        PlayerSpeed = 320
        Gravity = 800
        Knockback = 1000
        WeaponRespawn = 5
        ResolutionWidth = 1920
        ResolutionHeight = 1080
        Fullscreen = 1
        ColorBits = 32
        TextureBits = 32
        TextureCompression = 0
        PicMip = 0
        TextureMode = "gl_linear_mipmap_linear"
        FastSky = 0
        ConsoleEnabled = 1
        DeveloperMode = 0
        Fov = 90
        ServerExeName = "MOHAA_server.exe"
        GameExeName = "MOHAA.exe"
    }
}
# All settings now can be edited through the tui directly not via editing the powershell so now the project is just maybe if you can learn somthing :) if you are a normal user just run the powershell script in the main game folder
function Get-ClampedInt($Value, [int]$Default, [int]$Min, [int]$Max) {
    $parsed = 0
    if (-not [int]::TryParse("$Value", [ref]$parsed)) { $parsed = $Default }
    if ($parsed -lt $Min) { return $Min }
    if ($parsed -gt $Max) { return $Max }
    return $parsed
}

function Get-SafeText([string]$Value, [int]$MaxLength) {
    if ($null -eq $Value) { return "" }
    $clean = [regex]::Replace($Value, '[\x00-\x1F\x7F]', '').Trim()
    if ($clean.Length -gt $MaxLength) { return $clean.Substring(0, $MaxLength) }
    return $clean
}

function Get-SafeExeName([string]$ExeName, [string[]]$AllowedNames, [string]$DefaultName) {
    $name = [IO.Path]::GetFileName($ExeName)
    if ($name -in $AllowedNames) { return $name }
    return $DefaultName
}

function Get-SafeGuideUrl([string]$Url) {
    if ($Url -eq $AllowedHostingGuideUrl) { return $Url }
    return $AllowedHostingGuideUrl
}

function Get-SafeMapRotation($Settings) {
    $preset = Get-MatchModePreset $Settings.MatchMode
    $allowedMaps = @($preset.Maps)
    $maps = @($Settings.MapRotation | ForEach-Object { "$_".Trim() } | Where-Object { $_ -and ($_ -in $allowedMaps) })
    if ($maps.Count -eq 0) { $maps = @($allowedMaps[0]) }
    return $maps
}

function Normalize-Settings($Settings) {
    $defaults = Get-DefaultSettings
    foreach ($property in $defaults.PSObject.Properties.Name) {
        if (-not ($Settings.PSObject.Properties.Name -contains $property) -or $null -eq $Settings.$property) {
            $Settings | Add-Member -NotePropertyName $property -NotePropertyValue $defaults.$property -Force
        }
    }

    if ($Settings.SelectedGame -notin @("mohaa")) { $Settings.SelectedGame = "mohaa" }
    if ($Settings.HostingMode -notin @("direct", "tunnel", "local")) { $Settings.HostingMode = "tunnel" }
    if ($Settings.MatchMode -notin @("ffa", "team", "objective", "roundbased")) {
        $gameTypeForMode = Get-ClampedInt $Settings.GameType 1 1 4
        $Settings.MatchMode = switch ($gameTypeForMode) {
            2 { "team" }
            3 { "objective" }
            4 { "roundbased" }
            default { "ffa" }
        }
    }

    $Settings.ServerName = Get-SafeText $Settings.ServerName 64
    if (-not $Settings.ServerName) { $Settings.ServerName = $defaults.ServerName }
    $Settings.Password = Get-SafeText $Settings.Password 64
    $Settings.HostingGuideUrl = Get-SafeGuideUrl $Settings.HostingGuideUrl
    $Settings.ServerExeName = Get-SafeExeName $Settings.ServerExeName $AllowedServerExeNames $defaults.ServerExeName
    $Settings.GameExeName = Get-SafeExeName $Settings.GameExeName $AllowedGameExeNames $defaults.GameExeName

    $Settings.TimeLimit = Get-ClampedInt $Settings.TimeLimit $defaults.TimeLimit 1 180
    $Settings.MaxPlayers = Get-ClampedInt $Settings.MaxPlayers $defaults.MaxPlayers 1 64
    $Settings.Port = Get-ClampedInt $Settings.Port $defaults.Port 1024 65535
    $Settings.Cheats = Get-ClampedInt $Settings.Cheats $defaults.Cheats 0 1
    $Settings.PlayerSpeed = Get-ClampedInt $Settings.PlayerSpeed $defaults.PlayerSpeed 100 1000
    $Settings.Gravity = Get-ClampedInt $Settings.Gravity $defaults.Gravity 100 2000
    $Settings.Knockback = Get-ClampedInt $Settings.Knockback $defaults.Knockback 0 5000
    $Settings.WeaponRespawn = Get-ClampedInt $Settings.WeaponRespawn $defaults.WeaponRespawn 0 120
    $Settings.ResolutionWidth = Get-ClampedInt $Settings.ResolutionWidth $defaults.ResolutionWidth 640 7680
    $Settings.ResolutionHeight = Get-ClampedInt $Settings.ResolutionHeight $defaults.ResolutionHeight 480 4320
    $Settings.Fullscreen = Get-ClampedInt $Settings.Fullscreen $defaults.Fullscreen 0 1
    $Settings.ColorBits = if ((Get-ClampedInt $Settings.ColorBits $defaults.ColorBits 16 32) -lt 24) { 16 } else { 32 }
    $Settings.TextureBits = if ((Get-ClampedInt $Settings.TextureBits $defaults.TextureBits 16 32) -lt 24) { 16 } else { 32 }
    $Settings.TextureCompression = Get-ClampedInt $Settings.TextureCompression $defaults.TextureCompression 0 1
    $Settings.PicMip = Get-ClampedInt $Settings.PicMip $defaults.PicMip 0 5
    $Settings.FastSky = Get-ClampedInt $Settings.FastSky $defaults.FastSky 0 1
    $Settings.ConsoleEnabled = Get-ClampedInt $Settings.ConsoleEnabled $defaults.ConsoleEnabled 0 1
    $Settings.DeveloperMode = Get-ClampedInt $Settings.DeveloperMode $defaults.DeveloperMode 0 1
    $Settings.Fov = Get-ClampedInt $Settings.Fov $defaults.Fov 80 120
    if ($Settings.TextureMode -notin @("gl_linear_mipmap_linear", "gl_linear_mipmap_nearest", "gl_nearest_mipmap_linear", "gl_nearest_mipmap_nearest")) {
        $Settings.TextureMode = $defaults.TextureMode
    }
    $Settings.GameType = (Get-MatchModePreset $Settings.MatchMode).GameType
    $Settings.MapRotation = Get-SafeMapRotation $Settings
    return $Settings
}

function Get-MatchModePreset([string]$Mode) {
    switch ($Mode) {
        "team" {
            [pscustomobject]@{
                Key = "team"
                Label = "Team Match"
                GameType = 2
                Maps = @("dm/mohdm1", "dm/mohdm2", "dm/mohdm3", "dm/mohdm4", "dm/mohdm5", "dm/mohdm6", "dm/mohdm7")
            }
        }
        "objective" {
            [pscustomobject]@{
                Key = "objective"
                Label = "Objective"
                GameType = 3
                Maps = @("obj/obj_team1", "obj/obj_team2", "obj/obj_team3", "obj/obj_team4")
            }
        }
        "roundbased" {
            [pscustomobject]@{
                Key = "roundbased"
                Label = "Roundbased"
                GameType = 4
                Maps = @("dm/mohdm1", "dm/mohdm2", "dm/mohdm3", "dm/mohdm4", "dm/mohdm5", "dm/mohdm6", "dm/mohdm7")
            }
        }
        default {
            [pscustomobject]@{
                Key = "ffa"
                Label = "Free-for-All"
                GameType = 1
                Maps = @("dm/mohdm1", "dm/mohdm2", "dm/mohdm3", "dm/mohdm4", "dm/mohdm5", "dm/mohdm6", "dm/mohdm7")
            }
        }
    }
}

function Set-MatchModePreset($Settings, [string]$Mode) {
    $preset = Get-MatchModePreset $Mode
    $Settings.MatchMode = $preset.Key
    $Settings.GameType = $preset.GameType
    $Settings.MapRotation = @($preset.Maps)
}

function Get-MatchModeLabel($Settings) {
    (Get-MatchModePreset $Settings.MatchMode).Label
}

function Read-Settings {
    if (-not (Test-Path $SettingsPath)) {
        $legacy = $LegacySettingsPaths | Where-Object { Test-Path $_ } | Select-Object -First 1
        if ($legacy) {
            Copy-Item -LiteralPath $legacy -Destination $SettingsPath -Force
        }
    }

    if (-not (Test-Path $SettingsPath)) {
        $settings = Get-DefaultSettings
        Save-Settings $settings
        return $settings
    }

    try {
        $settings = Normalize-Settings (Get-Content -Raw $SettingsPath | ConvertFrom-Json)
        Save-Settings $settings
        return $settings
    } catch {
        $backup = "$SettingsPath.broken"
        Move-Item -LiteralPath $SettingsPath -Destination $backup -Force
        $settings = Get-DefaultSettings
        Save-Settings $settings
        return $settings
    }
}
# ;)
function Save-Settings($Settings) {
    $Settings | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $SettingsPath -Encoding ASCII
}

function Copy-Settings($Settings) {
    $Settings | ConvertTo-Json -Depth 5 | ConvertFrom-Json
}

function Escape-CfgValue([string]$Value) {
    if ($null -eq $Value) { return "" }
    return ($Value -replace '\\', '\\' -replace '"', '\"')
}

function Get-PrimaryMap($Settings) {
    @($Settings.MapRotation)[0]
}

function Get-MapList($Settings) {
    (@($Settings.MapRotation) -join " ")
}

function Write-ServerConfig($Settings, [switch]$Force) {
    if ((Test-Path $GeneratedConfigPath) -and -not $Force) {
        return "Existing"
    }

    $safeServerName = Escape-CfgValue $Settings.ServerName
    $safePassword = Escape-CfgValue $Settings.Password
    $safeMapList = Escape-CfgValue (Get-MapList $Settings)
    $safePrimaryMap = Escape-CfgValue (Get-PrimaryMap $Settings)

    $cfg = @"
// Generated by IMUSTAFSKI Server Runner.
// Use Server Settings inside the launcher, then Apply to rebuild this file.

seta sv_hostname "$safeServerName"
seta sv_maxclients "$($Settings.MaxPlayers)"
seta sv_maxRate "10000"
seta sv_timeout "120"
seta sv_precache "1"
seta sv_fps "30"
seta sv_reconnectlimit "3"
seta sv_chatter "1"
seta logfile "2"
seta net_noipx "1"
seta sv_cheats "$($Settings.Cheats)"
# :)    :)  ;0
// 1=Deathmatch, 2=Team match, 3=Objective, 4=Roundbased
seta g_gametype "$($Settings.GameType)"
seta timelimit "$($Settings.TimeLimit)"
seta fraglimit "0"
seta g_password "$safePassword"

// Gameplay tuning
seta g_speed "$($Settings.PlayerSpeed)"
seta g_gravity "$($Settings.Gravity)"
seta g_knockback "$($Settings.Knockback)"
seta g_weaponRespawn "$($Settings.WeaponRespawn)"

// Multiple maps rotate after the timelimit. One map stays on that map.
seta sv_maplist "$safeMapList"
map $safePrimaryMap
"@

    Set-Content -LiteralPath $GeneratedConfigPath -Value $cfg -Encoding ASCII
    return "Generated"
}

function Set-CfgValue([string]$Path, [string]$Name, [string]$Value) {
    if (-not (Test-Path $Path)) {
        New-Item -ItemType File -Path $Path -Force | Out-Null
    }

    $lines = @(Get-Content -LiteralPath $Path -ErrorAction SilentlyContinue)
    $escapedName = [regex]::Escape($Name)
    $replacement = "seta $Name `"$Value`""
    $found = $false

    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match "^\s*seta\s+$escapedName\s+") {
            $lines[$i] = $replacement
            $found = $true
        }
    }

    if (-not $found) {
        $lines += $replacement
    }

    Set-Content -LiteralPath $Path -Value $lines -Encoding ASCII
}

function Backup-PlayerConfig {
    if ((Test-Path $PlayerConfigPath) -and -not (Test-Path "$PlayerConfigPath.imustafski-backup")) {
        Copy-Item -LiteralPath $PlayerConfigPath -Destination "$PlayerConfigPath.imustafski-backup" -Force
    }
}
#Game settings direct in the tui
function Apply-GameSettings($Settings) {
    Backup-PlayerConfig

    $values = [ordered]@{
        r_mode = "-1"
        r_customwidth = "$($Settings.ResolutionWidth)"
        r_customheight = "$($Settings.ResolutionHeight)"
        r_fullscreen = "$($Settings.Fullscreen)"
        r_colorbits = "$($Settings.ColorBits)"
        r_texturebits = "$($Settings.TextureBits)"
        r_ext_compressed_textures = "$($Settings.TextureCompression)"
        r_picmip = "$($Settings.PicMip)"
        r_textureMode = "$($Settings.TextureMode)"
        r_fastsky = "$($Settings.FastSky)"
        ui_console = "$($Settings.ConsoleEnabled)"
        developer = "$($Settings.DeveloperMode)"
        cg_fov = "$($Settings.Fov)"
    }

    foreach ($item in $values.GetEnumerator()) {
        Set-CfgValue $PlayerConfigPath $item.Key $item.Value
        Set-CfgValue $AutoexecPath $item.Key $item.Value
    }

    return "Game settings applied to main\configs\unnamedsoldier.cfg and main\autoexec.cfg."
}

function Compare-VersionText([string]$Left, [string]$Right) {
    try {
        return ([version]$Left).CompareTo([version]$Right)
    } catch {
        return [string]::Compare($Left, $Right, $true)
    }
}

function Get-RunnerUpdateStatus {
    try {
        $remoteScript = Invoke-RestMethod -Uri $RunnerRawScriptUrl -TimeoutSec 4
        $remoteText = $remoteScript.ToString()
        $match = [regex]::Match($remoteText, '\$RunnerVersion\s*=\s*["'']([^"'']+)["'']')
        if (-not $match.Success) {
            return [pscustomobject]@{
                State = "Unavailable"
                Message = "Update check unavailable: remote version marker was not found."
                LatestVersion = ""
            }
        }

        $latest = $match.Groups[1].Value
        if ((Compare-VersionText $latest $RunnerVersion) -gt 0) {
            return [pscustomobject]@{
                State = "UpdateAvailable"
                Message = "Update available: current $RunnerVersion, latest $latest. Hosting will continue normally. $RunnerGitHubUrl"
                LatestVersion = $latest
            }
        }

        return [pscustomobject]@{
            State = "Current"
            Message = "Runner is up to date."
            LatestVersion = $latest
        }
    } catch {
        return [pscustomobject]@{
            State = "Unavailable"
            Message = "Update check unavailable. Hosting will continue normally."
            LatestVersion = ""
        }
    }
}

function Get-ZeroTierTunnelInfo($Settings) {
    $ipconfig = ""
    try {
        $ipconfig = (ipconfig | Out-String)
    } catch {
        return $null
    }

    $ipMatch = [regex]::Match($ipconfig, "ZeroTier[\s\S]*?IPv4 Address[^\r\n:]*:\s*([0-9]{1,3}(?:\.[0-9]{1,3}){3})")
    if ($ipMatch.Success) {
        $ip = $ipMatch.Groups[1].Value
        return [pscustomobject]@{
            Tool = "ZeroTier"
            State = "Detected"
            Address = $ip
            Command = "connect ${ip}:$($Settings.Port)"
            Detail = "ZeroTier adapter detected by ipconfig."
        }
    }

    return $null
}

function Get-PlayitTunnelInfo($Settings) {
    $playitCommand = Get-Command "playit.exe" -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $playitCommand) {
        return [pscustomobject]@{
            Tool = "playit.gg"
            State = "Missing"
            Address = ""
            Command = ""
            Detail = "playit.gg was not detected."
        }
    }

    try {
        $status = (& $playitCommand.Source status 2>&1 | Out-String).Trim()
        $hostPortMatch = [regex]::Match($status, "([a-zA-Z0-9.-]+\.(?:playit\.gg|ply\.gg|joinmc\.link|gl\.at|at\.ply\.gg|localhost|[a-zA-Z]{2,})[:/][0-9]{2,5})")
        if (-not $hostPortMatch.Success) {
            $hostPortMatch = [regex]::Match($status, "([a-zA-Z0-9.-]+:[0-9]{2,5})")
        }

        if ($hostPortMatch.Success) {
            $address = $hostPortMatch.Groups[1].Value.TrimEnd("/")
            return [pscustomobject]@{
                Tool = "playit.gg"
                State = "Detected"
                Address = $address
                Command = "connect $address"
                Detail = "playit.gg tunnel detected from status output."
            }
        }

        if ($status -match "not running") {
            return [pscustomobject]@{
                Tool = "playit.gg"
                State = "Stopped"
                Address = ""
                Command = ""
                Detail = "playit.gg installed, service not running."
            }
        }

        return [pscustomobject]@{
            Tool = "playit.gg"
            State = "Installed"
            Address = ""
            Command = ""
            Detail = "playit.gg installed, but no tunnel address was found in status output."
        }
    } catch {
        return [pscustomobject]@{
            Tool = "playit.gg"
            State = "Unavailable"
            Address = ""
            Command = ""
            Detail = "playit.gg status could not be read."
        }
    }
}

function Get-TunnelInfo($Settings) {
    $items = @()
    $zeroTier = Get-ZeroTierTunnelInfo $Settings
    if ($zeroTier) { $items += $zeroTier }
    $items += Get-PlayitTunnelInfo $Settings
    return @($items)
}

function Get-ServerProcess($Settings) {
    $serverExeName = Get-SafeExeName $Settings.ServerExeName $AllowedServerExeNames "MOHAA_server.exe"
    $serverPath = Join-Path $GameDir $serverExeName
    $exeName = [IO.Path]::GetFileNameWithoutExtension($serverExeName)
    Get-Process -Name $exeName -ErrorAction SilentlyContinue | Where-Object {
        try { $_.Path -eq $serverPath } catch { $false }
    }
}

function Start-Server($Settings, [switch]$ForceConfig) {
    $serverExeName = Get-SafeExeName $Settings.ServerExeName $AllowedServerExeNames "MOHAA_server.exe"
    $serverExe = Join-Path $GameDir $serverExeName
    if (-not (Test-Path $serverExe)) {
        throw "Missing server executable: $serverExe"
    }

    $configState = Write-ServerConfig $Settings -Force:$ForceConfig
    $running = Get-ServerProcess $Settings
    if ($running) {
        return [pscustomobject]@{
            Process = $running | Select-Object -First 1
            ConfigState = $configState
        }
    }
    #Setting the exe ending in Properties
    $args = @(
        "+set", "dedicated", "2",
        "+set", "net_port", "$($Settings.Port)",
        "+set", "net_noipx", "1",
        "+exec", $GeneratedConfigName
    )

    [void](Start-Process -FilePath $serverExe -ArgumentList $args -WorkingDirectory $GameDir -PassThru)
    Start-Sleep -Seconds 2

    return [pscustomobject]@{
        Process = Get-ServerProcess $Settings | Select-Object -First 1
        ConfigState = $configState
    }
}

function Stop-Server($Settings) {
    $running = Get-ServerProcess $Settings
    if (-not $running) { return }
    $running | ForEach-Object {
        $_.CloseMainWindow() | Out-Null
        Start-Sleep -Milliseconds 800
        if (-not $_.HasExited) {
            Stop-Process -Id $_.Id -Force
        }
    }
}
                        #As shown it will get the LocalIP
function Get-LocalIPv4Addresses {
    try {
        return Get-NetIPAddress -AddressFamily IPv4 -ErrorAction Stop |
            Where-Object {
                $_.IPAddress -ne "127.0.0.1" -and
                $_.IPAddress -notlike "169.254.*" -and
                $_.PrefixOrigin -ne "WellKnown"
            } |
            Sort-Object InterfaceAlias, IPAddress |
            Select-Object InterfaceAlias, IPAddress
    } catch {
        return [System.Net.Dns]::GetHostAddresses($env:COMPUTERNAME) |
            Where-Object { $_.AddressFamily -eq "InterNetwork" -and $_.IPAddressToString -ne "127.0.0.1" } |
            ForEach-Object { [pscustomobject]@{ InterfaceAlias = "Network"; IPAddress = $_.IPAddressToString } }
    }
}
                        #Here you can set any service to inspect the ip address that you want   
function Get-PublicIP {
    $services = @(
        "https://api.ipify.org",
        "https://ifconfig.me/ip",
        "https://icanhazip.com"
    )

    foreach ($service in $services) {
        try {
            $ip = (Invoke-RestMethod -Uri $service -TimeoutSec 4).ToString().Trim()
            if ($ip -match '^\d{1,3}(\.\d{1,3}){3}$') {
                return $ip
            }
        } catch {
        }
    }
    return $null
}
 #done fetching
function Test-LocalServerBinding($Settings, $Process) {
    if (-not $Process) {
        return $false
    }

    try {
        $pattern = "^\s*UDP\s+\S+:$($Settings.Port)\s+\*:\*\s+$($Process.Id)\s*$"
        return [bool](netstat -ano -p udp | Select-String -Pattern $pattern)
    } catch {
        return $false
    }
}

function Test-LocalServer($Settings, $Process) {
    if (Test-LocalServerBinding $Settings $Process) {
        return "OK - listening on UDP 0.0.0.0:$($Settings.Port)"
    }
    return "WARN - process is running, but UDP $($Settings.Port) was not detected"
}

function Get-ConnectionInfo($Settings) {
    $publicIp = Get-PublicIP #SetUp the IP that is given from the service 
    $localIps = @(Get-LocalIPv4Addresses) #setting the LocalIP for the hoster
    $tunnels = @(Get-TunnelInfo $Settings)
    $publicCommand = if ($publicIp) { "connect ${publicIp}:$($Settings.Port)" } else { "" }
    $vpnCommand = if ($localIps.Count -gt 0) { "connect $($localIps[0].IPAddress):$($Settings.Port)" } else { "" }
    $zeroTierCommand = ($tunnels | Where-Object { $_.Tool -eq "ZeroTier" -and $_.Command } | Select-Object -First 1).Command
    $playitCommand = ($tunnels | Where-Object { $_.Tool -eq "playit.gg" -and $_.Command } | Select-Object -First 1).Command
    $friendCommand = switch ($Settings.HostingMode) {
        "direct" { $publicCommand }
        "local" { "connect 127.0.0.1:$($Settings.Port)" }
        default {
            if ($zeroTierCommand) { $zeroTierCommand }
            elseif ($playitCommand) { $playitCommand }
            elseif ($vpnCommand) { $vpnCommand }
            else { $publicCommand }
        }
    }
    $script:LastFriendCommand = $friendCommand

    [pscustomobject]@{
        PublicIP = $publicIp
        LocalIPs = $localIps
        Tunnels = $tunnels
        PublicCommand = $publicCommand
        VpnCommand = $vpnCommand
        ZeroTierCommand = $zeroTierCommand
        PlayitCommand = $playitCommand
        FriendCommand = $friendCommand
        HostCommand = "connect 127.0.0.1:$($Settings.Port)"
    }
}

function Write-LabelValue([string]$Label, [string]$Value, [ConsoleColor]$Color = [ConsoleColor]::Gray) {
    Write-Host ("  {0,-13}" -f $Label) -NoNewline -ForegroundColor DarkGray
    Write-Host $Value -ForegroundColor $Color
}

function Get-HostingModeLabel([string]$Mode) {
    switch ($Mode) {
        "direct" { "Direct UDP" }
        "local" { "Local / LAN" }
        default { "VPN / Tunnel" }
    }
}

function Open-HostingGuide($Settings) {
    $url = Get-SafeGuideUrl $Settings.HostingGuideUrl
    try {
        Start-Process -FilePath $url
        return "Opened hosting guide: $url"
    } catch {
        try {
            Set-Clipboard -Value $url
            return "Could not open browser. Hosting guide copied: $url"
        } catch {
            return "Could not open browser. Open this manually: $url"
        }
    }
}
# TUI
function Show-Dashboard($Settings, $Process, $ConfigState, [string]$Message = "") {
    $connection = Get-ConnectionInfo $Settings
    $status = if ($Process -and -not $Process.HasExited) { "Running, PID $($Process.Id)" } else { "Not running" }
    $test = if ($Process -and -not $Process.HasExited) { Test-LocalServer $Settings $Process } else { "Not tested" }
    $statusColor = if ($status -like "Running*") { [ConsoleColor]::Green } else { [ConsoleColor]::Red }
    $testColor = if ($test -like "OK*") { [ConsoleColor]::Green } else { [ConsoleColor]::Yellow }
    $rotationLabel = if (@($Settings.MapRotation).Count -gt 1) { "$(Get-PrimaryMap $Settings) + $(@($Settings.MapRotation).Count - 1) queued" } else { Get-PrimaryMap $Settings }

    Clear-Host
    Write-Host ""
    Write-Host "  IMUSTAFSKI Server Runner" -ForegroundColor Cyan
    Write-Host "  =====================================" -ForegroundColor DarkCyan
    Write-LabelValue "Status" $status $statusColor
    Write-LabelValue "Name" $Settings.ServerName Cyan
    Write-LabelValue "Game" "Medal of Honor: Allied Assault" Gray
    Write-LabelValue "Hosting" (Get-HostingModeLabel $Settings.HostingMode) Cyan
    Write-LabelValue "Mode" (Get-MatchModeLabel $Settings) Gray
    Write-LabelValue "Map queue" $rotationLabel Gray
    Write-LabelValue "Time limit" "$($Settings.TimeLimit) minutes" Gray
    Write-LabelValue "Port" "UDP $($Settings.Port)" Gray
    Write-LabelValue "Gameplay" "speed $($Settings.PlayerSpeed), gravity $($Settings.Gravity), cheats $($Settings.Cheats)" Gray
    Write-LabelValue "Game video" "$($Settings.ResolutionWidth)x$($Settings.ResolutionHeight), textures $($Settings.TextureBits)-bit" Gray
    Write-LabelValue "Test" $test $testColor
    Write-LabelValue "Config" "$GeneratedConfigName ($ConfigState)" DarkGray
    Write-Host ""
    Write-Host "  COPY / SEND" -ForegroundColor Yellow
    Write-Host "  --------------------" -ForegroundColor DarkYellow
    switch ($Settings.HostingMode) {
        "direct" {
            Write-Host "  Friend command for direct internet hosting:" -ForegroundColor DarkGray
            if ($connection.PublicCommand) {
                Write-Host "  $($connection.PublicCommand)" -ForegroundColor Yellow
            } else {
                Write-Host "  Public IP was not detected. Check internet or use VPN/Tunnel hosting." -ForegroundColor Yellow
            }
            Write-Host "  Requires UDP $($Settings.Port) forwarded to this PC." -ForegroundColor DarkGray
        }
        "local" {
            Write-Host "  Host command on this PC:" -ForegroundColor DarkGray
            Write-Host "  $($connection.HostCommand)" -ForegroundColor Yellow
            if ($connection.VpnCommand) {
                Write-Host "  LAN command for another PC on the same network:" -ForegroundColor DarkGray
                Write-Host "  $($connection.VpnCommand)" -ForegroundColor Gray
            }
        }
        default {
            Write-Host "  Friend command for VPN/Tunnel hosting:" -ForegroundColor DarkGray
            if ($connection.FriendCommand) {
                Write-Host "  $($connection.FriendCommand)" -ForegroundColor Yellow
            } else {
                Write-Host "  No tunnel or LAN/VPN IP detected yet. Open Network Details after starting ZeroTier/playit.gg." -ForegroundColor Yellow
            }
            Write-Host "  ZeroTier is preferred when detected; playit.gg appears in Network Details." -ForegroundColor DarkGray
        }
    }
    Write-Host ""
    Write-Host "  HOST CONNECTS WITH" -ForegroundColor Green
    Write-Host "  $($connection.HostCommand)" -ForegroundColor Green
    Write-Host ""
    Write-Host "  In MOHAA press ~, type the connect command, then press Enter." -ForegroundColor DarkGray
    Write-Host "  Use Network Details for all detected LAN, ZeroTier, and playit.gg addresses." -ForegroundColor DarkGray
    if ($Message) {
        Write-Host ""
        Write-Host "  $Message" -ForegroundColor Magenta
    }
}

function Show-NetworkDetails($Settings) {
    $connection = Get-ConnectionInfo $Settings
    Clear-Host
    Write-Host ""
    Write-Host "  NETWORK DETAILS" -ForegroundColor Cyan
    Write-Host "  =====================================" -ForegroundColor DarkCyan
    Write-LabelValue "Hosting" (Get-HostingModeLabel $Settings.HostingMode) Cyan
    Write-LabelValue "Port" "UDP $($Settings.Port)" Gray
    Write-LabelValue "Host" $connection.HostCommand Green
    Write-LabelValue "Public" $(if ($connection.PublicCommand) { $connection.PublicCommand } else { "not detected" }) $(if ($connection.PublicCommand) { [ConsoleColor]::Yellow } else { [ConsoleColor]::DarkYellow })
    Write-Host ""
    Write-Host "  TUNNELS" -ForegroundColor Cyan
    if ($connection.Tunnels.Count -gt 0) {
        $connection.Tunnels | ForEach-Object {
            $line = if ($_.Command) { "$($_.Tool): $($_.Command) - $($_.Detail)" } else { "$($_.Tool): $($_.Detail)" }
            Write-Host "  $line" -ForegroundColor Gray
        }
    } else {
        Write-Host "  No tunnel adapters or tools detected." -ForegroundColor Yellow
    }
    Write-Host ""
    Write-Host "  LAN / VPN ADAPTERS" -ForegroundColor Cyan
    if ($connection.LocalIPs.Count -gt 0) {
        $connection.LocalIPs | ForEach-Object {
            Write-Host ("  connect {0}:{1}    {2}" -f $_.IPAddress, $Settings.Port, $_.InterfaceAlias) -ForegroundColor Gray
        }
    } else {
        Write-Host "  No LAN/VPN IPv4 address detected." -ForegroundColor Yellow
    }
    Write-Host ""
    Write-Host "  Hosting guide: $($Settings.HostingGuideUrl)" -ForegroundColor DarkGray
    Write-Host ""
    Read-Host "  Press Enter to return"
    return "Network details closed."
}
# Game Opening Direct from the TUI
function Open-Game($Settings) {
    $gameExeName = Get-SafeExeName $Settings.GameExeName $AllowedGameExeNames "MOHAA.exe"
    $gameExe = Join-Path $GameDir $gameExeName
    if (-not (Test-Path $gameExe)) {
        return "Missing game executable: $gameExe"
    }
    Start-Process -FilePath $gameExe -WorkingDirectory $GameDir
    return "MOHAA launched."
}
#clipboard direct tui
function Copy-FriendCommand {
    if (-not $script:LastFriendCommand) {
        return "No friend command is available yet."
    }

    try {
        Set-Clipboard -Value $script:LastFriendCommand
        return "Copied to clipboard: $script:LastFriendCommand"
    } catch {
        return "Copy failed. Send this manually: $script:LastFriendCommand"
    }
}
#stuff I Guess
function Invoke-ArrowMenu($Items, [string]$Hint = "Use Up/Down arrows, Enter to choose. Hotkeys also work.") {
    $selected = 0
    while ($true) {
        Write-Host ""
        Write-Host "  $Hint" -ForegroundColor DarkGray
        for ($i = 0; $i -lt $Items.Count; $i++) {
            $prefix = if ($i -eq $selected) { "> " } else { "  " }
            $color = if ($i -eq $selected) { [ConsoleColor]::Black } else { [ConsoleColor]::Gray }
            $background = if ($i -eq $selected) { [ConsoleColor]::Cyan } else { [ConsoleColor]::Black }
            Write-Host ("  {0}{1}" -f $prefix, $Items[$i].Label) -ForegroundColor $color -BackgroundColor $background
        }

        $key = [Console]::ReadKey($true)
        switch ($key.Key) {
            "UpArrow" {
                if ($selected -gt 0) { $selected-- } else { $selected = $Items.Count - 1 }
            }
            "DownArrow" {
                if ($selected -lt ($Items.Count - 1)) { $selected++ } else { $selected = 0 }
            }
            "Enter" {
                return $Items[$selected].Action
            }
            default {
                $match = $Items | Where-Object { $_.Hotkey -eq $key.KeyChar.ToString().ToUpperInvariant() } | Select-Object -First 1
                if ($match) { return $match.Action }
            }
        }

        [Console]::SetCursorPosition(0, [Console]::CursorTop - ($Items.Count + 2))
    }
}

function Read-SettingText([string]$Prompt, [string]$CurrentValue) {
    Write-Host ""
    Write-Host "  $Prompt" -ForegroundColor Cyan
    Write-Host "  Current: $CurrentValue" -ForegroundColor DarkGray
    $value = Read-Host "  New value, blank keeps current"
    if ([string]::IsNullOrWhiteSpace($value)) { return $CurrentValue }
    return $value.Trim()
}

function Read-SettingInt([string]$Prompt, [int]$CurrentValue, [int]$Min, [int]$Max) {
    while ($true) {
        $value = Read-SettingText $Prompt "$CurrentValue"
        $parsed = 0
        if ([int]::TryParse($value, [ref]$parsed) -and $parsed -ge $Min -and $parsed -le $Max) {
            return $parsed
        }
        Write-Host "  Enter a number from $Min to $Max." -ForegroundColor Yellow
    }
}

function Get-SliderBar([int]$Value, [int]$Min, [int]$Max, [int]$Width = 32) {
    $safeValue = Get-ClampedInt $Value $Min $Min $Max
    $range = $Max - $Min
    $position = if ($range -le 0) { 0 } else { [int][Math]::Round((($safeValue - $Min) / $range) * ($Width - 1)) }
    $left = if ($position -gt 0) { "-" * $position } else { "" }
    $rightLength = ($Width - 1) - $position
    $right = if ($rightLength -gt 0) { "-" * $rightLength } else { "" }
    return "[$left|$right]"
}

function Invoke-VisualSlider(
    [string]$Title,
    [int]$CurrentValue,
    [int]$Min,
    [int]$Max,
    [int]$Step = 1,
    [int]$LargeStep = 0,
    [string]$Unit = ""
) {
    $original = Get-ClampedInt $CurrentValue $Min $Min $Max
    $value = $original
    if ($LargeStep -le 0) { $LargeStep = [Math]::Max($Step * 5, 1) }

    while ($true) {
        Clear-Host
        Write-Host ""
        Write-Host "  $Title" -ForegroundColor Cyan
        Write-Host "  =====================================" -ForegroundColor DarkCyan
        Write-Host ""
        Write-Host ("  {0,-5} {1} {2,5}" -f $Min, (Get-SliderBar $value $Min $Max), $Max) -ForegroundColor Gray
        $unitLabel = if ($Unit) { " $Unit" } else { "" }
        Write-Host ""
        Write-Host "  Current: $value$unitLabel" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "  Left/Right = adjust   PageUp/PageDown = bigger step" -ForegroundColor DarkGray
        Write-Host "  Home/End = min/max    Enter = apply   Esc = cancel" -ForegroundColor DarkGray

        $key = [Console]::ReadKey($true)
        switch ($key.Key) {
            "LeftArrow" { $value = Get-ClampedInt ($value - $Step) $original $Min $Max }
            "RightArrow" { $value = Get-ClampedInt ($value + $Step) $original $Min $Max }
            "PageDown" { $value = Get-ClampedInt ($value - $LargeStep) $original $Min $Max }
            "PageUp" { $value = Get-ClampedInt ($value + $LargeStep) $original $Min $Max }
            "Home" { $value = $Min }
            "End" { $value = $Max }
            "Enter" { return $value }
            "Escape" { return $original }
        }
    }
}

function Invoke-ToggleSelector([string]$Title, [int]$CurrentValue, [string]$OnLabel = "On", [string]$OffLabel = "Off") {
    Clear-Host
    Write-Host ""
    Write-Host "  $Title" -ForegroundColor Cyan
    Write-Host "  Current: $(if ($CurrentValue -eq 1) { $OnLabel } else { $OffLabel })" -ForegroundColor DarkGray
    $items = @(
        [pscustomobject]@{ Label = "[1] $OnLabel"; Hotkey = "1"; Action = 1 }
        [pscustomobject]@{ Label = "[0] $OffLabel"; Hotkey = "0"; Action = 0 }
    )
    return [int](Invoke-ArrowMenu $items "Choose with arrows, Enter, or hotkey.")
}

function Invoke-TextureBitsSelector([int]$CurrentValue) {
    Clear-Host
    Write-Host ""
    Write-Host "  Texture quality bits" -ForegroundColor Cyan
    Write-Host "  Current: $CurrentValue" -ForegroundColor DarkGray
    $items = @(
        [pscustomobject]@{ Label = "[3] 32-bit, recommended"; Hotkey = "3"; Action = 32 }
        [pscustomobject]@{ Label = "[1] 16-bit, compatibility"; Hotkey = "1"; Action = 16 }
    )
    return [int](Invoke-ArrowMenu $items "Choose texture quality.")
}

function Invoke-ResolutionSelector($Draft) {
    Clear-Host
    Write-Host ""
    Write-Host "  Resolution" -ForegroundColor Cyan
    Write-Host "  Current: $($Draft.ResolutionWidth)x$($Draft.ResolutionHeight)" -ForegroundColor DarkGray
    $items = @(
        [pscustomobject]@{ Label = "[1] 720p 1280x720"; Hotkey = "1"; Action = "720" }
        [pscustomobject]@{ Label = "[2] 1080p 1920x1080"; Hotkey = "2"; Action = "1080" }
        [pscustomobject]@{ Label = "[3] 1440p 2560x1440"; Hotkey = "3"; Action = "1440" }
        [pscustomobject]@{ Label = "[4] 4K 3840x2160"; Hotkey = "4"; Action = "4k" }
        [pscustomobject]@{ Label = "[C] Custom"; Hotkey = "C"; Action = "custom" }
        [pscustomobject]@{ Label = "[B] Back"; Hotkey = "B"; Action = "cancel" }
    )
    $choice = Invoke-ArrowMenu $items "Choose a preset, or Custom for exact values."
    switch ($choice) {
        "720" { return [pscustomobject]@{ Width = 1280; Height = 720; Label = "720p preset selected." } }
        "1080" { return [pscustomobject]@{ Width = 1920; Height = 1080; Label = "1080p preset selected." } }
        "1440" { return [pscustomobject]@{ Width = 2560; Height = 1440; Label = "1440p preset selected." } }
        "4k" { return [pscustomobject]@{ Width = 3840; Height = 2160; Label = "4K preset selected." } }
        "custom" {
            $width = Read-SettingInt "Resolution width" $Draft.ResolutionWidth 640 7680
            $height = Read-SettingInt "Resolution height" $Draft.ResolutionHeight 480 4320
            return [pscustomobject]@{ Width = $width; Height = $height; Label = "Custom resolution selected." }
        }
        default { return $null }
    }
}
#screen settings
function Show-SettingsScreen($Draft, [string]$Message = "") {
    Clear-Host
    Write-Host ""
    Write-Host "  SERVER SETTINGS" -ForegroundColor Cyan
    Write-Host "  =====================================" -ForegroundColor DarkCyan
    Write-LabelValue "Name" $Draft.ServerName Cyan
    Write-LabelValue "Password" $(if ($Draft.Password) { "(set)" } else { "(none)" }) Gray
    Write-LabelValue "Mode" (Get-MatchModeLabel $Draft) Gray
    Write-LabelValue "Maps" (Get-MapList $Draft) Gray
    Write-LabelValue "Rotation" $(if (@($Draft.MapRotation).Count -gt 1) { "Rotates after timelimit" } else { "Single map, stays on same map" }) Gray
    Write-LabelValue "Time limit" "$($Draft.TimeLimit) minutes" Gray
    Write-LabelValue "Players" "$($Draft.MaxPlayers)" Gray
    Write-LabelValue "Port" "UDP $($Draft.Port)" Gray
    Write-LabelValue "Cheats" "$($Draft.Cheats)" Gray
    Write-LabelValue "Speed" "$($Draft.PlayerSpeed)" Gray
    Write-LabelValue "Gravity" "$($Draft.Gravity)" Gray
    Write-LabelValue "Knockback" "$($Draft.Knockback)" Gray
    Write-LabelValue "Respawn" "$($Draft.WeaponRespawn) sec weapons" Gray
    Write-Host ""
    Write-Host "  Map rotation note: one map stays there; multiple maps rotate after the timelimit." -ForegroundColor DarkGray
    Write-Host "  Gameplay values apply after Apply rebuilds config and restarts the server." -ForegroundColor DarkGray
    if ($Message) {
        Write-Host ""
        Write-Host "  $Message" -ForegroundColor Magenta
    }
}
# inside game settings
function Show-GameSettingsScreen($Draft, [string]$Message = "") {
    Clear-Host
    Write-Host ""
    Write-Host "  GAME SETTINGS" -ForegroundColor Cyan
    Write-Host "  =====================================" -ForegroundColor DarkCyan
    Write-LabelValue "Resolution" "$($Draft.ResolutionWidth)x$($Draft.ResolutionHeight)" Cyan
    Write-LabelValue "Fullscreen" "$($Draft.Fullscreen)" Gray
    Write-LabelValue "Color bits" "$($Draft.ColorBits)" Gray
    Write-LabelValue "Texture bits" "$($Draft.TextureBits)" Gray
    Write-LabelValue "Compression" "$($Draft.TextureCompression)" Gray
    Write-LabelValue "Texture mode" "$($Draft.TextureMode)" Gray
    Write-LabelValue "Picmip" "$($Draft.PicMip)" Gray
    Write-LabelValue "Fast sky" "$($Draft.FastSky)" Gray
    Write-LabelValue "Console" "$($Draft.ConsoleEnabled)" Gray
    Write-LabelValue "Developer" "$($Draft.DeveloperMode)" Gray
    Write-LabelValue "FOV cvar" "$($Draft.Fov)" Gray
    Write-Host ""
    Write-Host "  Widescreen uses r_mode -1 plus custom width/height." -ForegroundColor DarkGray
    Write-Host "  Sky/texture cleanup uses safe config toggles only; no DLL hex patching." -ForegroundColor DarkGray
    Write-Host "  If the game is open, restart MOHAA after applying video settings." -ForegroundColor DarkGray
    if ($Message) {
        Write-Host ""
        Write-Host "  $Message" -ForegroundColor Magenta
    }
}
# Map settings and rotation
function Edit-MapRotation($Draft) {
    Clear-Host
    Write-Host ""
    Write-Host "  MAP QUEUE" -ForegroundColor Cyan
    Write-Host "  Enter maps separated by commas." -ForegroundColor DarkGray
    Write-Host "  Example: dm/mohdm6, dm/mohdm7, dm/mohdm1" -ForegroundColor DarkGray
    Write-Host "  Current: $(Get-MapList $Draft)" -ForegroundColor Gray
    $value = Read-Host "  New map queue, blank keeps current"
    if (-not [string]::IsNullOrWhiteSpace($value)) {
        $maps = @($value.Split(",") | ForEach-Object { $_.Trim() } | Where-Object { $_ })
        if ($maps.Count -gt 0) { $Draft.MapRotation = $maps }
    }
}

function Edit-SettingsTui($CurrentSettings) {
    $draft = Normalize-Settings (Copy-Settings $CurrentSettings)
    $message = ""

    while ($true) {
        Show-SettingsScreen $draft $message
        $items = @(
            [pscustomobject]@{ Label = "[N] Server name"; Hotkey = "N"; Action = "Name" }
            [pscustomobject]@{ Label = "[P] Password"; Hotkey = "P"; Action = "Password" }
            [pscustomobject]@{ Label = "[Y] Match mode preset"; Hotkey = "Y"; Action = "MatchMode" }
            [pscustomobject]@{ Label = "[M] Map queue / rotation"; Hotkey = "M"; Action = "Maps" }
            [pscustomobject]@{ Label = "[T] Time limit"; Hotkey = "T"; Action = "Time" }
            [pscustomobject]@{ Label = "[X] Max players"; Hotkey = "X"; Action = "Players" }
            [pscustomobject]@{ Label = "[O] Port"; Hotkey = "O"; Action = "Port" }
            [pscustomobject]@{ Label = "[H] Cheats toggle"; Hotkey = "H"; Action = "Cheats" }
            [pscustomobject]@{ Label = "[F] Player speed"; Hotkey = "F"; Action = "Speed" }
            [pscustomobject]@{ Label = "[G] Gravity"; Hotkey = "G"; Action = "Gravity" }
            [pscustomobject]@{ Label = "[K] Knockback"; Hotkey = "K"; Action = "Knockback" }
            [pscustomobject]@{ Label = "[W] Weapon respawn"; Hotkey = "W"; Action = "Respawn" }
            [pscustomobject]@{ Label = "[A] Apply and restart"; Hotkey = "A"; Action = "Apply" }
            [pscustomobject]@{ Label = "[C] Cancel"; Hotkey = "C"; Action = "Cancel" }
        )

        $action = Invoke-ArrowMenu $items "Settings: arrows + Enter, then A to apply or C to cancel."
        switch ($action) {
            "Name" { $draft.ServerName = Read-SettingText "Server name" $draft.ServerName; $message = "Server name updated in draft." }
            "Password" { $draft.Password = Read-SettingText "Password, blank means no password" $draft.Password; $message = "Password updated in draft." }
            "MatchMode" {
                $modeItems = @(
                    [pscustomobject]@{ Label = "[1] Free-for-All"; Hotkey = "1"; Action = "ffa" }
                    [pscustomobject]@{ Label = "[2] Team Match"; Hotkey = "2"; Action = "team" }
                    [pscustomobject]@{ Label = "[3] Objective"; Hotkey = "3"; Action = "objective" }
                    [pscustomobject]@{ Label = "[4] Roundbased"; Hotkey = "4"; Action = "roundbased" }
                )
                $mode = Invoke-ArrowMenu $modeItems "Choose Allied Assault match mode preset."
                Set-MatchModePreset $draft $mode
                $message = "$(Get-MatchModeLabel $draft) preset applied in draft."
            }
            "Maps" { Edit-MapRotation $draft; $message = "Map queue updated in draft." }
            "Time" { $draft.TimeLimit = Invoke-VisualSlider "Time limit" $draft.TimeLimit 1 180 1 5 "minutes"; $message = "Time limit updated in draft." }
            "Players" { $draft.MaxPlayers = Invoke-VisualSlider "Max players" $draft.MaxPlayers 1 64 1 4 "players"; $message = "Max players updated in draft." }
            "Port" { $draft.Port = Read-SettingInt "UDP port" $draft.Port 1024 65535; $message = "Port updated in draft." }
            "Cheats" { $draft.Cheats = Invoke-ToggleSelector "Cheats" $draft.Cheats "On" "Off"; $message = "Cheats updated in draft." }
            "Speed" { $draft.PlayerSpeed = Invoke-VisualSlider "Player speed" $draft.PlayerSpeed 100 1000 10 50 ""; $message = "Player speed updated in draft." }
            "Gravity" { $draft.Gravity = Invoke-VisualSlider "Gravity" $draft.Gravity 100 2000 25 100 ""; $message = "Gravity updated in draft." }
            "Knockback" { $draft.Knockback = Invoke-VisualSlider "Knockback" $draft.Knockback 0 5000 100 500 ""; $message = "Knockback updated in draft." }
            "Respawn" { $draft.WeaponRespawn = Invoke-VisualSlider "Weapon respawn" $draft.WeaponRespawn 0 120 1 5 "seconds"; $message = "Weapon respawn updated in draft." }
            "Apply" { return [pscustomobject]@{ Applied = $true; Settings = (Normalize-Settings $draft) } }
            "Cancel" { return [pscustomobject]@{ Applied = $false; Settings = $CurrentSettings } }
        }
    }
}

function Edit-GameSettingsTui($CurrentSettings) {
    $draft = Normalize-Settings (Copy-Settings $CurrentSettings)
    $message = ""

    while ($true) {
        Show-GameSettingsScreen $draft $message
        $items = @(
            [pscustomobject]@{ Label = "[R] Resolution preset"; Hotkey = "R"; Action = "Resolution" }
            [pscustomobject]@{ Label = "[F] Fullscreen toggle"; Hotkey = "F"; Action = "Fullscreen" }
            [pscustomobject]@{ Label = "[T] Texture quality bits"; Hotkey = "T"; Action = "TextureBits" }
            [pscustomobject]@{ Label = "[X] Texture compression toggle"; Hotkey = "X"; Action = "Compression" }
            [pscustomobject]@{ Label = "[Q] Texture sharpness slider"; Hotkey = "Q"; Action = "PicMip" }
            [pscustomobject]@{ Label = "[S] Skybox cleanup preset"; Hotkey = "S"; Action = "SkyFix" }
            [pscustomobject]@{ Label = "[V] FOV slider"; Hotkey = "V"; Action = "Fov" }
            [pscustomobject]@{ Label = "[A] Apply game settings"; Hotkey = "A"; Action = "Apply" }
            [pscustomobject]@{ Label = "[C] Cancel"; Hotkey = "C"; Action = "Cancel" }
        )
        #Presets Going in (Make it easier for the user)
        $action = Invoke-ArrowMenu $items "Game settings: arrows + Enter, then A to apply or C to cancel."
        switch ($action) {
            "Resolution" {
                $resolution = Invoke-ResolutionSelector $draft
                if ($resolution) {
                    $draft.ResolutionWidth = $resolution.Width
                    $draft.ResolutionHeight = $resolution.Height
                    $draft.Fullscreen = 1
                    $draft.ColorBits = 32
                    $draft.TextureBits = 32
                    $message = $resolution.Label
                } else {
                    $message = "Resolution unchanged."
                }
            }
            "Fullscreen" { $draft.Fullscreen = Invoke-ToggleSelector "Fullscreen" $draft.Fullscreen "On" "Off"; $message = "Fullscreen updated in draft." }
            "TextureBits" { $draft.TextureBits = Invoke-TextureBitsSelector $draft.TextureBits; $message = "Texture bits updated in draft." }
            "Compression" { $draft.TextureCompression = Invoke-ToggleSelector "Texture compression" $draft.TextureCompression "On" "Off"; $message = "Texture compression updated in draft." }
            "PicMip" { $draft.PicMip = Invoke-VisualSlider "Texture sharpness / picmip" $draft.PicMip 0 5 1 1 ""; $message = "Picmip updated in draft." }
            "SkyFix" {
                $draft.FastSky = 0
                $draft.TextureCompression = 0
                $draft.TextureBits = 32
                $draft.ColorBits = 32
                $draft.PicMip = 0
                $draft.TextureMode = "gl_linear_mipmap_linear"
                $message = "Skybox cleanup preset selected: fast sky off, compression off, 32-bit textures."
            }
            "Fov" { $draft.Fov = Invoke-VisualSlider "FOV" $draft.Fov 80 120 1 5 ""; $message = "FOV cvar updated in draft." }
            "Apply" { return [pscustomobject]@{ Applied = $true; Settings = (Normalize-Settings $draft) } }
            "Cancel" { return [pscustomobject]@{ Applied = $false; Settings = $CurrentSettings } }
        }
    }
}

function Show-GameSelector($Settings) {
    $message = ""
    while ($true) {
        Clear-Host
        Write-Host ""
        Write-Host "  CHOOSE GAME TO HOST" -ForegroundColor Cyan
        Write-Host "  =====================================" -ForegroundColor DarkCyan
        Write-Host "  Current support: Medal of Honor: Allied Assault" -ForegroundColor Gray
        if ($message) {
            Write-Host ""
            Write-Host "  $message" -ForegroundColor Yellow
        }

        $items = @(
            [pscustomobject]@{ Label = "[1] Medal of Honor: Allied Assault"; Hotkey = "1"; Action = "mohaa" }
            [pscustomobject]@{ Label = "[2] Spearhead - Coming soon"; Hotkey = "2"; Action = "spearhead" }
            [pscustomobject]@{ Label = "[3] Breakthrough - Coming soon"; Hotkey = "3"; Action = "breakthrough" }
        )

        $choice = Invoke-ArrowMenu $items "Select a game. Unsupported games return here."
        if ($choice -eq "mohaa") {
            $Settings.SelectedGame = "mohaa"
            return "Medal of Honor: Allied Assault selected."
        }

        $message = "That game is installed but not supported by this runner yet."
    }
}

function Show-HostingSelector($Settings) {
    Clear-Host
    Write-Host ""
    Write-Host "  CHOOSE HOSTING METHOD" -ForegroundColor Cyan
    Write-Host "  =====================================" -ForegroundColor DarkCyan
    Write-Host "  Recommended when port forwarding fails: VPN/Tunnel." -ForegroundColor Gray
    Write-Host "  Direct hosting only works when your router supports UDP port forwarding." -ForegroundColor DarkGray

    $items = @(
        [pscustomobject]@{ Label = "[T] VPN/Tunnel hosting - ZeroTier or playit.gg recommended"; Hotkey = "T"; Action = "tunnel" }
        [pscustomobject]@{ Label = "[D] Direct hosting - requires router UDP port forwarding"; Hotkey = "D"; Action = "direct" }
        [pscustomobject]@{ Label = "[L] Local only - this PC / LAN testing"; Hotkey = "L"; Action = "local" }
    )

    $choice = Invoke-ArrowMenu $items "Select hosting method."
    $Settings.HostingMode = $choice
    switch ($choice) {
        "direct" { return "Direct hosting selected. UDP port forwarding is required." }
        "local" { return "Local-only hosting selected." }
        default { return "VPN/Tunnel hosting selected. ZeroTier/playit.gg scan enabled." }
    }
}

$settings = Read-Settings
$updateStatus = Get-RunnerUpdateStatus
if (-not $NoMenu) {
    $startupMessages = @()
    if ($updateStatus.State -eq "UpdateAvailable") { $startupMessages += $updateStatus.Message }
    $startupMessages += Show-GameSelector $settings
    $startupMessages += Show-HostingSelector $settings
    Save-Settings $settings
}
$startResult = Start-Server $settings -ForceConfig:$RegenerateConfig
$process = $startResult.Process
$configState = $startResult.ConfigState

$initialMessage = if ($NoMenu -and $updateStatus.State -eq "UpdateAvailable") { $updateStatus.Message } else { ($startupMessages -join " ") }
Show-Dashboard $settings $process $configState $initialMessage

if ($NoMenu) {
    exit 0
}

$message = ""
while ($true) {
    $menu = @(
        [pscustomobject]@{ Label = "[G] Open MOHAA"; Hotkey = "G"; Action = "Game" }
        [pscustomobject]@{ Label = "[C] Copy friend command"; Hotkey = "C"; Action = "Copy" }
        [pscustomobject]@{ Label = "[E] Server settings"; Hotkey = "E"; Action = "Settings" }
        [pscustomobject]@{ Label = "[V] Game settings"; Hotkey = "V"; Action = "GameSettings" }
        [pscustomobject]@{ Label = "[N] Network details"; Hotkey = "N"; Action = "Network" }
        [pscustomobject]@{ Label = "[H] How to host"; Hotkey = "H"; Action = "Help" }
        [pscustomobject]@{ Label = "[R] Restart server"; Hotkey = "R"; Action = "Restart" }
        [pscustomobject]@{ Label = "[B] Rebuild config"; Hotkey = "B"; Action = "Build" }
        [pscustomobject]@{ Label = "[S] Stop server"; Hotkey = "S"; Action = "Stop" }
        [pscustomobject]@{ Label = "[Q] Quit launcher"; Hotkey = "Q"; Action = "Quit" }
    )

    $action = Invoke-ArrowMenu $menu
    switch ($action) {
        "Game" { $message = Open-Game $settings }
        "Copy" { $message = Copy-FriendCommand }
        "Network" { $message = Show-NetworkDetails $settings }
        "Help" { $message = Open-HostingGuide $settings }
        "Settings" {
            $result = Edit-SettingsTui $settings
            if ($result.Applied) {
                $settings = $result.Settings
                Save-Settings $settings
                Stop-Server $settings
                $startResult = Start-Server $settings -ForceConfig
                $process = $startResult.Process
                $configState = $startResult.ConfigState
                $message = "Settings applied, config rebuilt, server restarted."
            } else {
                $message = "Settings canceled. No changes applied."
            }
        }
        "GameSettings" {
            $result = Edit-GameSettingsTui $settings
            if ($result.Applied) {
                $settings = $result.Settings
                Save-Settings $settings
                $message = Apply-GameSettings $settings
            } else {
                $message = "Game settings canceled. No changes applied."
            }
        }
        "Restart" {
            Stop-Server $settings
            $startResult = Start-Server $settings
            $process = $startResult.Process
            $configState = $startResult.ConfigState
            $message = "Server restarted."
        }
        "Build" {
            Stop-Server $settings
            $startResult = Start-Server $settings -ForceConfig
            $process = $startResult.Process
            $configState = $startResult.ConfigState
            $message = "Config rebuilt and server restarted." 
        }
        "Stop" {
            Stop-Server $settings
            $process = $null
            $message = "Server stopped." #Stoping the MOHAA_server
        }
        "Quit" {
            Clear-Host
            Write-Host ""
            Write-Host "  IMUSTAFSKI Server Runner closed." -ForegroundColor Cyan
            Write-Host "  Server process is unchanged. Use Stop server before Quit if you want to stop hosting." -ForegroundColor DarkGray
            exit 0
        } #Quiting Existing from the terminal at all not to the cmd main
    }

    Show-Dashboard $settings (Get-ServerProcess $settings | Select-Object -First 1) $configState $message
}
