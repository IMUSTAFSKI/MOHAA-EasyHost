param(
    [switch]$NoMenu,
    [switch]$RegenerateConfig
)
#ParamStating In
$ErrorActionPreference = "Stop"
$RunnerVersion = "1.0.2"
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
$PlayerConfigPath = Join-Path $GameDir "main\configs\unnamedsoldier.cfg"
$AutoexecPath = Join-Path $GameDir "main\autoexec.cfg"
$AllowedHostingGuideUrl = "https://github.com/IMUSTAFSKI/MOHAA-EasyHost/blob/main/Hosting%20Methods.md"
$OpenMohaaGuideUrl = "https://github.com/openmoh/openmohaa/blob/main/docs/markdown/03-configuration/02-configuration-server.md"
$AllowedServerExeNames = @("MOHAA_server.exe", "moh_spearhead_server.exe", "moh_Breakthrough_server.exe", "omohaaded.exe")
$AllowedGameExeNames = @("MOHAA.exe", "moh_spearhead.exe", "moh_breakthrough.exe", "launch_openmohaa_base.exe", "launch_openmohaa_spearhead.exe", "launch_openmohaa_breakthrough.exe", "openmohaa.exe")
$script:LastFriendCommand = ""
#Server Config Settings will be placed in the main (dir)
function Get-GameProfiles {
    @(
        [pscustomobject]@{
            Id = "original-aa"; Label = "Original Allied Assault"; Engine = "Original MOHAA"; Expansion = "Allied Assault"
            GameExeName = "MOHAA.exe"; ServerExeName = "MOHAA_server.exe"; ConfigDir = "main"; OpenMoHAA = $false
            ClientArgs = @(); ServerArgs = @(); Modes = @("ffa", "team", "objective", "roundbased")
        }
        [pscustomobject]@{
            Id = "original-sh"; Label = "Original Spearhead"; Engine = "Original MOHAA"; Expansion = "Spearhead"
            GameExeName = "moh_spearhead.exe"; ServerExeName = "moh_spearhead_server.exe"; ConfigDir = "mainta"; OpenMoHAA = $false
            ClientArgs = @(); ServerArgs = @(); Modes = @("ffa", "team", "objective", "roundbased", "tow")
        }
        [pscustomobject]@{
            Id = "original-bt"; Label = "Original Breakthrough"; Engine = "Original MOHAA"; Expansion = "Breakthrough"
            GameExeName = "moh_breakthrough.exe"; ServerExeName = "moh_Breakthrough_server.exe"; ConfigDir = "maintt"; OpenMoHAA = $false
            ClientArgs = @(); ServerArgs = @(); Modes = @("ffa", "team", "objective", "roundbased", "liberation")
        }
        [pscustomobject]@{
            Id = "openmohaa-aa"; Label = "OpenMoHAA Allied Assault"; Engine = "OpenMoHAA"; Expansion = "Allied Assault"
            GameExeName = "openmohaa.exe"; ServerExeName = "omohaaded.exe"; ConfigDir = "main"; OpenMoHAA = $true
            ClientArgs = @(); ServerArgs = @(); Modes = @("ffa", "team", "objective", "roundbased")
        }
        [pscustomobject]@{
            Id = "openmohaa-sh"; Label = "OpenMoHAA Spearhead"; Engine = "OpenMoHAA"; Expansion = "Spearhead"
            GameExeName = "openmohaa.exe"; ServerExeName = "omohaaded.exe"; ConfigDir = "mainta"; OpenMoHAA = $true
            ClientArgs = @("+set", "fs_game", "mainta"); ServerArgs = @("+set", "fs_game", "mainta"); Modes = @("ffa", "team", "objective", "roundbased", "tow")
        }
        [pscustomobject]@{
            Id = "openmohaa-bt"; Label = "OpenMoHAA Breakthrough"; Engine = "OpenMoHAA"; Expansion = "Breakthrough"
            GameExeName = "openmohaa.exe"; ServerExeName = "omohaaded.exe"; ConfigDir = "maintt"; OpenMoHAA = $true
            ClientArgs = @("+set", "fs_game", "maintt"); ServerArgs = @("+set", "fs_game", "maintt"); Modes = @("ffa", "team", "objective", "roundbased", "liberation")
        }
    )
}

function Get-GameProfile([string]$ProfileId) {
    $profiles = @(Get-GameProfiles)
    $profile = $profiles | Where-Object { $_.Id -eq $ProfileId } | Select-Object -First 1
    if ($profile) { return $profile }
    return ($profiles | Where-Object { $_.Id -eq "original-aa" } | Select-Object -First 1)
}

function Get-SelectedProfile($Settings) {
    $profileId = if ($Settings.PSObject.Properties.Name -contains "ProfileId") { $Settings.ProfileId } else { $Settings.SelectedGame }
    Get-GameProfile $profileId
}

function Get-GeneratedConfigPath($Settings) {
    $profile = Get-SelectedProfile $Settings
    Join-Path $GameDir (Join-Path $profile.ConfigDir $GeneratedConfigName)
}

function Get-ProfileDisplayName($Settings) {
    (Get-SelectedProfile $Settings).Label
}

function Get-DefaultSettings {
    [pscustomobject]@{
        ServerName = "IMUSTAFSKI standard server"
        Password = ""
        ProfileId = "original-aa"
        SelectedGame = "original-aa"
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
        ServerExeName = "MOHAA_server.exe"
        GameExeName = "MOHAA.exe"
        SvGameSpy = 1
        SvMaxRate = 10000
        SvMinRate = 0
        SvMinPing = 0
        SvMaxPing = 0
        SvPrivateClients = 0
        SvPrivatePassword = ""
        RconPassword = ""
        SvFloodProtect = 1
        TeamDamage = 0
        AdvancedCvars = [pscustomobject]@{}
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
    if ($Url -in @($AllowedHostingGuideUrl, $OpenMohaaGuideUrl)) { return $Url }
    return $AllowedHostingGuideUrl
}

function Get-SafeMapRotation($Settings) {
    $preset = Get-MatchModePreset $Settings.MatchMode $Settings
    $allowedMaps = @($preset.Maps)
    $maps = @($Settings.MapRotation | ForEach-Object { "$_".Trim() } | Where-Object { $_ -and ($_ -match '^[A-Za-z0-9_\-/]+$') })
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

    if ($Settings.SelectedGame -eq "mohaa") { $Settings.SelectedGame = "original-aa" }
    if ($Settings.ProfileId -eq "mohaa") { $Settings.ProfileId = "original-aa" }
    if ($Settings.SelectedGame -and -not $Settings.ProfileId) { $Settings.ProfileId = $Settings.SelectedGame }
    $profile = Get-SelectedProfile $Settings
    $Settings.ProfileId = $profile.Id
    $Settings.SelectedGame = $profile.Id
    if ($Settings.HostingMode -notin @("direct", "tunnel", "local")) { $Settings.HostingMode = "tunnel" }
    if ($Settings.MatchMode -notin @($profile.Modes)) {
        $gameTypeForMode = Get-ClampedInt $Settings.GameType 1 1 4
        $Settings.MatchMode = switch ($gameTypeForMode) {
            2 { "team" }
            3 { "roundbased" }
            4 { "objective" }
            default { "ffa" }
        }
    }

    $Settings.ServerName = Get-SafeText $Settings.ServerName 64
    if (-not $Settings.ServerName) { $Settings.ServerName = $defaults.ServerName }
    $Settings.Password = Get-SafeText $Settings.Password 64
    $Settings.HostingGuideUrl = Get-SafeGuideUrl $Settings.HostingGuideUrl
    $Settings.ServerExeName = Get-SafeExeName $profile.ServerExeName $AllowedServerExeNames $defaults.ServerExeName
    $Settings.GameExeName = Get-SafeExeName $profile.GameExeName $AllowedGameExeNames $defaults.GameExeName

    $Settings.TimeLimit = Get-ClampedInt $Settings.TimeLimit $defaults.TimeLimit 1 180
    $Settings.MaxPlayers = Get-ClampedInt $Settings.MaxPlayers $defaults.MaxPlayers 1 64
    $Settings.Port = Get-ClampedInt $Settings.Port $defaults.Port 1024 65535
    $Settings.Cheats = Get-ClampedInt $Settings.Cheats $defaults.Cheats 0 1
    $Settings.PlayerSpeed = Get-ClampedInt $Settings.PlayerSpeed $defaults.PlayerSpeed 100 1000
    $Settings.Gravity = Get-ClampedInt $Settings.Gravity $defaults.Gravity 100 2000
    $Settings.Knockback = Get-ClampedInt $Settings.Knockback $defaults.Knockback 0 5000
    $Settings.WeaponRespawn = Get-ClampedInt $Settings.WeaponRespawn $defaults.WeaponRespawn 0 120
    $Settings.SvGameSpy = Get-ClampedInt $Settings.SvGameSpy $defaults.SvGameSpy 0 1
    $Settings.SvMaxRate = Get-ClampedInt $Settings.SvMaxRate $defaults.SvMaxRate 0 25000
    $Settings.SvMinRate = Get-ClampedInt $Settings.SvMinRate $defaults.SvMinRate 0 25000
    $Settings.SvMinPing = Get-ClampedInt $Settings.SvMinPing $defaults.SvMinPing 0 999
    $Settings.SvMaxPing = Get-ClampedInt $Settings.SvMaxPing $defaults.SvMaxPing 0 999
    $Settings.SvPrivateClients = Get-ClampedInt $Settings.SvPrivateClients $defaults.SvPrivateClients 0 $Settings.MaxPlayers
    $Settings.SvPrivatePassword = Get-SafeText $Settings.SvPrivatePassword 64
    $Settings.RconPassword = Get-SafeText $Settings.RconPassword 64
    $Settings.SvFloodProtect = Get-ClampedInt $Settings.SvFloodProtect $defaults.SvFloodProtect 0 1
    $Settings.TeamDamage = Get-ClampedInt $Settings.TeamDamage $defaults.TeamDamage 0 3
    if ($null -eq $Settings.AdvancedCvars) { $Settings.AdvancedCvars = [pscustomobject]@{} }
    $Settings.AdvancedCvars = ConvertTo-AdvancedCvarObject $Settings.AdvancedCvars
    $Settings.GameType = (Get-MatchModePreset $Settings.MatchMode $Settings).GameType
    $Settings.MapRotation = Get-SafeMapRotation $Settings
    return $Settings
}

function Get-MatchModePreset([string]$Mode, $Settings = $null) {
    $profile = if ($Settings) { Get-SelectedProfile $Settings } else { Get-GameProfile "original-aa" }
    if ($Mode -notin @($profile.Modes)) { $Mode = "ffa" }
    switch ($Mode) {
        "tow" {
            [pscustomobject]@{
                Key = "tow"
                Label = "Tug-of-War"
                GameType = 5
                Maps = @("tow/tow_stadt", "tow/tow_kasserine", "tow/tow_holland", "tow/tow_anzio")
            }
        }
        "liberation" {
            [pscustomobject]@{
                Key = "liberation"
                Label = "Liberation"
                GameType = 6
                Maps = @("dm/mp_bahnhof_dm", "dm/mp_brest_dm", "dm/mp_gewitter_dm", "dm/mp_holland_dm", "dm/mp_stadt_dm")
            }
        }
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
                GameType = 4
                Maps = @("obj/obj_team1", "obj/obj_team2", "obj/obj_team3", "obj/obj_team4")
            }
        }
        "roundbased" {
            [pscustomobject]@{
                Key = "roundbased"
                Label = "Roundbased"
                GameType = 3
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
    $preset = Get-MatchModePreset $Mode $Settings
    $Settings.MatchMode = $preset.Key
    $Settings.GameType = $preset.GameType
    $Settings.MapRotation = @($preset.Maps)
}

function Get-MatchModeLabel($Settings) {
    (Get-MatchModePreset $Settings.MatchMode $Settings).Label
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

function ConvertTo-AdvancedCvarObject($Value) {
    $result = [ordered]@{}
    if ($null -ne $Value) {
        foreach ($property in $Value.PSObject.Properties) {
            $name = Get-SafeCvarName $property.Name
            if ($name) {
                $result[$name] = Get-SafeText "$($property.Value)" 256
            }
        }
    }
    return [pscustomobject]$result
}

function Get-SafeCvarName([string]$Name) {
    if ($null -eq $Name) { return "" }
    $clean = $Name.Trim()
    if ($clean -match '^[A-Za-z0-9_\.]+$') { return $clean }
    return ""
}

function Get-CvarValue($Settings, [string]$Name) {
    if ($Settings.AdvancedCvars -and ($Settings.AdvancedCvars.PSObject.Properties.Name -contains $Name)) {
        return "$($Settings.AdvancedCvars.$Name)"
    }
    return $null
}

function Set-AdvancedCvar($Settings, [string]$Name, [string]$Value) {
    $safeName = Get-SafeCvarName $Name
    if (-not $safeName) { return $false }
    $safeValue = Get-SafeText $Value 256
    if ($null -eq $Settings.AdvancedCvars) { $Settings.AdvancedCvars = [pscustomobject]@{} }
    $Settings.AdvancedCvars | Add-Member -NotePropertyName $safeName -NotePropertyValue $safeValue -Force
    return $true
}

function Remove-AdvancedCvar($Settings, [string]$Name) {
    $safeName = Get-SafeCvarName $Name
    if (-not $safeName -or -not $Settings.AdvancedCvars) { return $false }
    if ($Settings.AdvancedCvars.PSObject.Properties.Name -contains $safeName) {
        $Settings.AdvancedCvars.PSObject.Properties.Remove($safeName)
        return $true
    }
    return $false
}

function Get-PrimaryMap($Settings) {
    @($Settings.MapRotation)[0]
}

function Get-MapList($Settings) {
    (@($Settings.MapRotation) -join " ")
}

function Write-ServerConfig($Settings, [switch]$Force) {
    $generatedConfigPath = Get-GeneratedConfigPath $Settings
    if ((Test-Path $generatedConfigPath) -and -not $Force) {
        $existing = Get-Content -Raw -LiteralPath $generatedConfigPath -ErrorAction SilentlyContinue
        if ($existing -match "Generated by IMUSTAFSKI Server Runner" -and $existing -match "Profile:" -and $existing -match "sv_gamespy") {
            return "Existing"
        }
    }

    $profile = Get-SelectedProfile $Settings
    $configDir = Split-Path -Parent $generatedConfigPath
    if (-not (Test-Path $configDir)) {
        New-Item -ItemType Directory -Path $configDir -Force | Out-Null
    }

    $safeServerName = Escape-CfgValue $Settings.ServerName
    $safePassword = Escape-CfgValue $Settings.Password
    $safeMapList = Escape-CfgValue (Get-MapList $Settings)
    $safePrimaryMap = Escape-CfgValue (Get-PrimaryMap $Settings)
    $safePrivatePassword = Escape-CfgValue $Settings.SvPrivatePassword
    $safeRconPassword = Escape-CfgValue $Settings.RconPassword
    $advancedLines = @()
    foreach ($property in ($Settings.AdvancedCvars.PSObject.Properties | Sort-Object Name)) {
        $name = Get-SafeCvarName $property.Name
        if ($name -and $name -notin @("sv_hostname", "sv_maxclients", "sv_maxClients", "net_port", "g_gametype", "timelimit", "g_password", "sv_maplist")) {
            $value = Escape-CfgValue "$($property.Value)"
            $advancedLines += "seta $name `"$value`""
        }
    }
    $advancedBlock = if ($advancedLines.Count -gt 0) { "`r`n// Advanced cvars from runner settings`r`n$($advancedLines -join "`r`n")" } else { "" }

    $cfg = @"
// Generated by IMUSTAFSKI Server Runner.
// Use Server Settings inside the launcher, then Apply to rebuild this file.
// Profile: $($profile.Label)

seta sv_hostname "$safeServerName"
seta sv_maxclients "$($Settings.MaxPlayers)"
seta sv_maxRate "$($Settings.SvMaxRate)"
seta sv_minRate "$($Settings.SvMinRate)"
seta sv_minPing "$($Settings.SvMinPing)"
seta sv_maxPing "$($Settings.SvMaxPing)"
seta sv_privateClients "$($Settings.SvPrivateClients)"
seta sv_privatePassword "$safePrivatePassword"
seta rconpassword "$safeRconPassword"
seta sv_floodprotect "$($Settings.SvFloodProtect)"
seta sv_gamespy "$($Settings.SvGameSpy)"
seta sv_timeout "120"
seta sv_precache "1"
seta sv_fps "30"
seta sv_reconnectlimit "3"
seta sv_chatter "1"
seta logfile "2"
seta net_noipx "1"
seta sv_cheats "$($Settings.Cheats)"
# :)    :)  ;0
// 1=Deathmatch, 2=Team match, 3=Roundbased, 4=Objective, 5=Tug-of-War, 6=Liberation
seta g_gametype "$($Settings.GameType)"
seta timelimit "$($Settings.TimeLimit)"
seta fraglimit "0"
seta g_password "$safePassword"
seta g_teamdamage "$($Settings.TeamDamage)"

// Gameplay tuning
seta g_speed "$($Settings.PlayerSpeed)"
seta g_gravity "$($Settings.Gravity)"
seta g_knockback "$($Settings.Knockback)"
seta g_weaponRespawn "$($Settings.WeaponRespawn)"

// Multiple maps rotate after the timelimit. One map stays on that map.
seta sv_maplist "$safeMapList"
$advancedBlock
map $safePrimaryMap
"@

    if ((Test-Path $generatedConfigPath) -and $Force) {
        $stamp = Get-Date -Format "yyyyMMdd-HHmmss"
        Copy-Item -LiteralPath $generatedConfigPath -Destination "$generatedConfigPath.$stamp.bak" -Force
    }
    Set-Content -LiteralPath $generatedConfigPath -Value $cfg -Encoding ASCII
    return "Generated"
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

function Get-ShortcutTarget([string]$Path) {
    if (-not (Test-Path $Path)) { return "" }
    try {
        $shell = New-Object -ComObject WScript.Shell
        $shortcut = $shell.CreateShortcut($Path)
        return $shortcut.TargetPath
    } catch {
        return ""
    }
}

function Get-PlayitExecutablePath {
    $candidates = @()
    $pathCommand = Get-Command "playit.exe" -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($pathCommand) { $candidates += $pathCommand.Source }
    $candidates += "C:\Program Files\playit_gg\bin\playit.exe"
    $shortcutTarget = Get-ShortcutTarget (Join-Path $GameDir "Playit.gg.lnk")
    if ($shortcutTarget) { $candidates += $shortcutTarget }

    foreach ($candidate in ($candidates | Where-Object { $_ } | Select-Object -Unique)) {
        if (Test-Path $candidate) { return $candidate }
    }
    return ""
}

function Get-PlayitTunnelInfo($Settings) {
    $playitPath = Get-PlayitExecutablePath
    if (-not $playitPath) {
        return [pscustomobject]@{
            Tool = "playit.gg"
            State = "Missing"
            Address = ""
            Command = ""
            Detail = "playit.gg was not detected."
        }
    }

    try {
        $status = (& $playitPath status 2>&1 | Out-String).Trim()
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

        $running = Get-Process -Name "playit", "playit-cli" -ErrorAction SilentlyContinue | Select-Object -First 1
        if (($status -match "not running") -or (-not $running -and $status -notmatch "tunnel|agent|connected|running")) {
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

function Get-ProcessCommandLine([int]$ProcessId) {
    try {
        $wmi = Get-WmiObject Win32_Process -Filter "ProcessId = $ProcessId" -ErrorAction SilentlyContinue
        if ($wmi -and $wmi.CommandLine) { return $wmi.CommandLine }
    } catch {}
    return ""
}

function Get-ProfileFsGame($Profile) {
    $serverArgs = @($Profile.ServerArgs)
    for ($i = 0; $i -lt $serverArgs.Count; $i++) {
        if ($serverArgs[$i] -eq "fs_game" -and ($i + 1) -lt $serverArgs.Count) {
            return $serverArgs[$i + 1]
        }
    }
    return ""
}
#OpenMoHAA profiles share omohaaded.exe so we match by exe path only here
function Get-ServerProcessesByExe($Settings) {
    $profile = Get-SelectedProfile $Settings
    $serverExeName = Get-SafeExeName $profile.ServerExeName $AllowedServerExeNames "MOHAA_server.exe"
    $serverPath = Join-Path $GameDir $serverExeName
    $exeName = [IO.Path]::GetFileNameWithoutExtension($serverExeName)
    @(Get-Process -Name $exeName -ErrorAction SilentlyContinue | Where-Object {
        try { $_.Path -eq $serverPath } catch { $false }
    })
}
#Profile-aware: for OpenMoHAA, checks fs_game in command line to tell AA/SH/BT apart
function Get-ServerProcess($Settings) {
    $profile = Get-SelectedProfile $Settings
    $candidates = @(Get-ServerProcessesByExe $Settings)
    if ($candidates.Count -eq 0) { return @() }
    # Original game profiles have unique server exes, no further filtering needed
    if (-not $profile.OpenMoHAA) { return $candidates }
    # OpenMoHAA profiles share omohaaded.exe, distinguish by fs_game in command line
    $fsGame = Get-ProfileFsGame $profile
    @($candidates | Where-Object {
        $cmdLine = Get-ProcessCommandLine $_.Id
        if ($fsGame) {
            # SH or BT: command line must contain fs_game with the matching value
            $cmdLine -match "fs_game\s+$([regex]::Escape($fsGame))"
        } else {
            # AA: command line must NOT contain fs_game mainta or maintt
            $cmdLine -notmatch 'fs_game\s+(mainta|maintt)'
        }
    })
}

function Start-Server($Settings, [switch]$ForceConfig) {
    $profile = Get-SelectedProfile $Settings
    $serverExeName = Get-SafeExeName $profile.ServerExeName $AllowedServerExeNames "MOHAA_server.exe"
    $serverExe = Join-Path $GameDir $serverExeName
    if (-not (Test-Path $serverExe)) {
        throw "Missing server executable: $serverExe"
    }

    $configState = Write-ServerConfig $Settings -Force:$ForceConfig
    $running = @(Get-ServerProcess $Settings)
    if ($running.Count -gt 0) {
        return [pscustomobject]@{
            Process = $running | Select-Object -First 1
            ConfigState = $configState
        }
    }
    # Stop any stale server processes using the same exe but a different profile
    $stale = @(Get-ServerProcessesByExe $Settings)
    if ($stale.Count -gt 0) {
        $stale | ForEach-Object {
            $_.CloseMainWindow() | Out-Null
            Start-Sleep -Milliseconds 800
            if (-not $_.HasExited) {
                Stop-Process -Id $_.Id -Force
            }
        }
    }
    #Setting the exe ending in Properties
    $args = @($profile.ServerArgs) + @(
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
#Stops all instances of the server exe regardless of profile (handles shared omohaaded.exe)
function Stop-Server($Settings) {
    $running = @(Get-ServerProcessesByExe $Settings)
    if ($running.Count -eq 0) { return }
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
    $profile = Get-SelectedProfile $Settings
    $connection = Get-ConnectionInfo $Settings
    $status = if ($Process -and -not $Process.HasExited) { "Running, PID $($Process.Id)" } else { "Not running" }
    $statusColor = if ($status -like "Running*") { [ConsoleColor]::Green } else { [ConsoleColor]::Red }
    $rotationLabel = if (@($Settings.MapRotation).Count -gt 1) { "$(Get-PrimaryMap $Settings) + $(@($Settings.MapRotation).Count - 1) queued" } else { Get-PrimaryMap $Settings }

    Clear-Host
    Write-Host ""
    Write-Host "  IMUSTAFSKI Server Runner" -ForegroundColor Cyan
    Write-Host "  =====================================" -ForegroundColor DarkCyan
    Write-LabelValue "Status" $status $statusColor
    Write-LabelValue "Name" $Settings.ServerName Cyan
    Write-LabelValue "Game" $profile.Label Gray
    Write-LabelValue "Hosting" (Get-HostingModeLabel $Settings.HostingMode) Cyan
    Write-LabelValue "Mode" (Get-MatchModeLabel $Settings) Gray
    Write-LabelValue "Map queue" $rotationLabel Gray
    Write-LabelValue "Time limit" "$($Settings.TimeLimit) minutes" Gray
    Write-LabelValue "Port" "UDP $($Settings.Port)" Gray
    Write-LabelValue "Gameplay" "speed $($Settings.PlayerSpeed), gravity $($Settings.Gravity), cheats $($Settings.Cheats)" Gray
    Write-Host ""
    Write-Host "  COPY / SEND" -ForegroundColor Yellow
    Write-Host "  --------------------" -ForegroundColor DarkYellow
    Write-Host "  Host:   $($connection.HostCommand)" -ForegroundColor Green
    Write-Host "  LAN:    $(if ($connection.VpnCommand) { $connection.VpnCommand } else { 'not detected' })" -ForegroundColor Gray
    Write-Host "  Public: $(if ($connection.PublicCommand) { $connection.PublicCommand } else { 'not detected' })" -ForegroundColor Gray
    Write-Host "  Playit: $(if ($connection.PlayitCommand) { $connection.PlayitCommand } else { 'not detected' })" -ForegroundColor Gray
    Write-Host ""
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
    Write-Host "  In MOHAA/OpenMoHAA press ~, type the connect command, then press Enter." -ForegroundColor DarkGray
    Write-Host "  Use Network Details for all detected LAN, ZeroTier, and playit.gg addresses." -ForegroundColor DarkGray
    if ($Message) {
        Write-Host ""
        Write-Host "  $Message" -ForegroundColor Magenta
    }
}

function Show-NetworkDetails($Settings) {
    $profile = Get-SelectedProfile $Settings
    $connection = Get-ConnectionInfo $Settings
    Clear-Host
    Write-Host ""
    Write-Host "  NETWORK DETAILS" -ForegroundColor Cyan
    Write-Host "  =====================================" -ForegroundColor DarkCyan
    Write-LabelValue "Hosting" (Get-HostingModeLabel $Settings.HostingMode) Cyan
    Write-LabelValue "Profile" $profile.Label Gray
    Write-LabelValue "Port" "UDP $($Settings.Port)" Gray
    Write-LabelValue "Host" $connection.HostCommand Green
    Write-LabelValue "LAN" $(if ($connection.VpnCommand) { $connection.VpnCommand } else { "not detected" }) $(if ($connection.VpnCommand) { [ConsoleColor]::Gray } else { [ConsoleColor]::DarkYellow })
    Write-LabelValue "Public" $(if ($connection.PublicCommand) { $connection.PublicCommand } else { "not detected" }) $(if ($connection.PublicCommand) { [ConsoleColor]::Yellow } else { [ConsoleColor]::DarkYellow })
    Write-LabelValue "Playit.gg" $(if ($connection.PlayitCommand) { $connection.PlayitCommand } else { "not detected" }) $(if ($connection.PlayitCommand) { [ConsoleColor]::Yellow } else { [ConsoleColor]::DarkYellow })
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
    $profile = Get-SelectedProfile $Settings
    $gameExeName = Get-SafeExeName $profile.GameExeName $AllowedGameExeNames "MOHAA.exe"
    if ($profile.Id -eq "openmohaa-aa" -and -not (Test-Path (Join-Path $GameDir $gameExeName)) -and (Test-Path (Join-Path $GameDir "openmohaa.exe"))) {
        $gameExeName = "openmohaa.exe"
    }
    $gameExe = Join-Path $GameDir $gameExeName
    if (-not (Test-Path $gameExe)) {
        return "Missing game executable: $gameExe"
    }
    try {
        if ($profile.ClientArgs -and @($profile.ClientArgs).Count -gt 0) {
            [void](Start-Process -FilePath $gameExe -ArgumentList @($profile.ClientArgs) -WorkingDirectory $GameDir -ErrorAction Stop)
        } else {
            [void](Start-Process -FilePath $gameExe -WorkingDirectory $GameDir -ErrorAction Stop)
        }
        return "$($profile.Label) launched."
    } catch {
        return "Failed to launch game: $($_.Exception.Message)"
    }
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

#screen settings
function Show-SettingsScreen($Draft, [string]$Message = "") {
    $profile = Get-SelectedProfile $Draft
    Clear-Host
    Write-Host ""
    Write-Host "  SERVER SETTINGS" -ForegroundColor Cyan
    Write-Host "  =====================================" -ForegroundColor DarkCyan
    Write-LabelValue "Profile" $profile.Label Cyan
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
    Write-LabelValue "GameSpy" "$($Draft.SvGameSpy)" Gray
    Write-LabelValue "Rate" "max $($Draft.SvMaxRate), min $($Draft.SvMinRate)" Gray
    Write-LabelValue "Ping" "min $($Draft.SvMinPing), max $($Draft.SvMaxPing)" Gray
    Write-LabelValue "Private" "$($Draft.SvPrivateClients) slots" Gray
    Write-LabelValue "RCON" $(if ($Draft.RconPassword) { "(set)" } else { "(none)" }) Gray
    Write-LabelValue "Flood" "$($Draft.SvFloodProtect)" Gray
    Write-LabelValue "Team dmg" "$($Draft.TeamDamage)" Gray
    Write-LabelValue "Advanced" "$(@($Draft.AdvancedCvars.PSObject.Properties).Count) cvars" Gray
    Write-Host ""
    Write-Host "  Map rotation note: one map stays there; multiple maps rotate after the timelimit." -ForegroundColor DarkGray
    Write-Host "  Gameplay values apply after Apply rebuilds config and restarts the server." -ForegroundColor DarkGray
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

function Read-CfgCvars([string]$Path) {
    $result = [ordered]@{}
    if (-not (Test-Path $Path)) { return [pscustomobject]$result }
    foreach ($line in (Get-Content -LiteralPath $Path -ErrorAction SilentlyContinue)) {
        $match = [regex]::Match($line, '^\s*(?:set|seta)\s+([A-Za-z0-9_\.]+)\s+(.+?)\s*(?://.*)?$')
        if ($match.Success) {
            $name = Get-SafeCvarName $match.Groups[1].Value
            $value = $match.Groups[2].Value.Trim()
            if ($value.StartsWith('"') -and $value.EndsWith('"') -and $value.Length -ge 2) {
                $value = $value.Substring(1, $value.Length - 2)
            }
            if ($name) { $result[$name] = Get-SafeText $value 256 }
        }
    }
    return [pscustomobject]$result
}

function Import-AdvancedCvars($Draft, [string]$Path) {
    $cvars = Read-CfgCvars $Path
    $count = 0
    foreach ($property in $cvars.PSObject.Properties) {
        if (Set-AdvancedCvar $Draft $property.Name "$($property.Value)") { $count++ }
    }
    return $count
}

function Show-AdvancedCvarScreen($Draft, [string]$Message = "") {
    $profile = Get-SelectedProfile $Draft
    Clear-Host
    Write-Host ""
    Write-Host "  ADVANCED SERVER CVARS" -ForegroundColor Cyan
    Write-Host "  =====================================" -ForegroundColor DarkCyan
    Write-LabelValue "Profile" $profile.Label Gray
    Write-LabelValue "Generated" "$($profile.ConfigDir)\$GeneratedConfigName" Gray
    Write-LabelValue "Source cfg" "$($profile.ConfigDir)\server.cfg" Gray
    Write-Host ""
    if ($Draft.AdvancedCvars -and @($Draft.AdvancedCvars.PSObject.Properties).Count -gt 0) {
        $Draft.AdvancedCvars.PSObject.Properties | Sort-Object Name | ForEach-Object {
            Write-Host ("  {0,-24} {1}" -f $_.Name, $_.Value) -ForegroundColor Gray
        }
    } else {
        Write-Host "  No advanced cvars yet." -ForegroundColor DarkYellow
    }
    Write-Host ""
    Write-Host "  Advanced cvars are written only to the runner-generated config." -ForegroundColor DarkGray
    Write-Host "  Core values like sv_hostname, g_gametype, timelimit, and sv_maplist stay controlled by the normal menu." -ForegroundColor DarkGray
    if ($Message) {
        Write-Host ""
        Write-Host "  $Message" -ForegroundColor Magenta
    }
}

function Edit-AdvancedCvarsTui($CurrentSettings) {
    $draft = Normalize-Settings (Copy-Settings $CurrentSettings)
    $message = ""
    while ($true) {
        Show-AdvancedCvarScreen $draft $message
        $items = @(
            [pscustomobject]@{ Label = "[A] Add or edit cvar"; Hotkey = "A"; Action = "Add" }
            [pscustomobject]@{ Label = "[D] Delete cvar"; Hotkey = "D"; Action = "Delete" }
            [pscustomobject]@{ Label = "[I] Import from selected profile server.cfg"; Hotkey = "I"; Action = "ImportProfile" }
            [pscustomobject]@{ Label = "[G] Import from generated config"; Hotkey = "G"; Action = "ImportGenerated" }
            [pscustomobject]@{ Label = "[R] Reset advanced cvars"; Hotkey = "R"; Action = "Reset" }
            [pscustomobject]@{ Label = "[S] Save advanced cvars"; Hotkey = "S"; Action = "Save" }
            [pscustomobject]@{ Label = "[C] Cancel"; Hotkey = "C"; Action = "Cancel" }
        )
        $action = Invoke-ArrowMenu $items "Advanced cvars: edit power-user set/seta values, then Save."
        switch ($action) {
            "Add" {
                $name = Read-SettingText "Cvar name" ""
                $safeName = Get-SafeCvarName $name
                if (-not $safeName) {
                    $message = "Invalid cvar name. Use letters, numbers, underscore, or dot."
                } else {
                    $current = Get-CvarValue $draft $safeName
                    $value = Read-SettingText "Value for $safeName" $(if ($null -ne $current) { $current } else { "" })
                    [void](Set-AdvancedCvar $draft $safeName $value)
                    $message = "$safeName updated in draft."
                }
            }
            "Delete" {
                $name = Read-SettingText "Cvar name to delete" ""
                if (Remove-AdvancedCvar $draft $name) { $message = "$name removed from draft." } else { $message = "Cvar was not found." }
            }
            "ImportProfile" {
                $profile = Get-SelectedProfile $draft
                $path = Join-Path $GameDir (Join-Path $profile.ConfigDir "server.cfg")
                $count = Import-AdvancedCvars $draft $path
                $message = "Imported $count cvars from $($profile.ConfigDir)\server.cfg."
            }
            "ImportGenerated" {
                $path = Get-GeneratedConfigPath $draft
                $count = Import-AdvancedCvars $draft $path
                $message = "Imported $count cvars from generated config."
            }
            "Reset" {
                $draft.AdvancedCvars = [pscustomobject]@{}
                $message = "Advanced cvars reset in draft."
            }
            "Save" { return [pscustomobject]@{ Applied = $true; Settings = (Normalize-Settings $draft) } }
            "Cancel" { return [pscustomobject]@{ Applied = $false; Settings = $CurrentSettings } }
        }
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
            [pscustomobject]@{ Label = "[I] Server browser / GameSpy"; Hotkey = "I"; Action = "GameSpy" }
            [pscustomobject]@{ Label = "[U] Rate limits"; Hotkey = "U"; Action = "Rates" }
            [pscustomobject]@{ Label = "[L] Ping limits"; Hotkey = "L"; Action = "Pings" }
            [pscustomobject]@{ Label = "[Z] Private slots/password"; Hotkey = "Z"; Action = "Private" }
            [pscustomobject]@{ Label = "[J] RCON password"; Hotkey = "J"; Action = "Rcon" }
            [pscustomobject]@{ Label = "[D] Flood protect"; Hotkey = "D"; Action = "Flood" }
            [pscustomobject]@{ Label = "[Q] Team damage"; Hotkey = "Q"; Action = "TeamDamage" }
            [pscustomobject]@{ Label = "[C] Advanced cvars"; Hotkey = "C"; Action = "Advanced" }
            [pscustomobject]@{ Label = "[A] Apply and restart"; Hotkey = "A"; Action = "Apply" }
            [pscustomobject]@{ Label = "[B] Cancel"; Hotkey = "B"; Action = "Cancel" }
        )

        $action = Invoke-ArrowMenu $items "Settings: arrows + Enter, then A to apply or C to cancel."
        switch ($action) {
            "Name" { $draft.ServerName = Read-SettingText "Server name" $draft.ServerName; $message = "Server name updated in draft." }
            "Password" { $draft.Password = Read-SettingText "Password, blank means no password" $draft.Password; $message = "Password updated in draft." }
            "MatchMode" {
                $profile = Get-SelectedProfile $draft
                $modeItems = @()
                $modeIndex = 1
                foreach ($modeKey in @($profile.Modes)) {
                    $preset = Get-MatchModePreset $modeKey $draft
                    $modeItems += [pscustomobject]@{ Label = "[$modeIndex] $($preset.Label)"; Hotkey = "$modeIndex"; Action = $modeKey }
                    $modeIndex++
                }
                $mode = Invoke-ArrowMenu $modeItems "Choose a match mode for $($profile.Label)."
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
            "GameSpy" { $draft.SvGameSpy = Invoke-ToggleSelector "Server browser / GameSpy" $draft.SvGameSpy "On" "Off"; $message = "Server browser visibility updated in draft." }
            "Rates" {
                $draft.SvMaxRate = Read-SettingInt "sv_maxRate, 0 means unlimited" $draft.SvMaxRate 0 25000
                $draft.SvMinRate = Read-SettingInt "sv_minRate, 0 means no minimum" $draft.SvMinRate 0 25000
                $message = "Rate limits updated in draft."
            }
            "Pings" {
                $draft.SvMinPing = Read-SettingInt "sv_minPing, 0 means no minimum" $draft.SvMinPing 0 999
                $draft.SvMaxPing = Read-SettingInt "sv_maxPing, 0 means no maximum" $draft.SvMaxPing 0 999
                $message = "Ping limits updated in draft."
            }
            "Private" {
                $draft.SvPrivateClients = Read-SettingInt "Reserved private slots" $draft.SvPrivateClients 0 $draft.MaxPlayers
                $draft.SvPrivatePassword = Read-SettingText "Private slot password, blank means none" $draft.SvPrivatePassword
                $message = "Private slot settings updated in draft."
            }
            "Rcon" { $draft.RconPassword = Read-SettingText "RCON password, blank disables remote admin password" $draft.RconPassword; $message = "RCON password updated in draft." }
            "Flood" { $draft.SvFloodProtect = Invoke-ToggleSelector "Flood protect" $draft.SvFloodProtect "On" "Off"; $message = "Flood protect updated in draft." }
            "TeamDamage" { $draft.TeamDamage = Invoke-VisualSlider "Team damage: 0 off, 1 friendly, 2 reflect, 3 both" $draft.TeamDamage 0 3 1 1 ""; $message = "Team damage updated in draft." }
            "Advanced" {
                $advanced = Edit-AdvancedCvarsTui $draft
                if ($advanced.Applied) {
                    $draft.AdvancedCvars = $advanced.Settings.AdvancedCvars
                    $message = "Advanced cvars updated in draft."
                } else {
                    $message = "Advanced cvars canceled."
                }
            }
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
        Write-Host "  Choose original MOHAA or OpenMoHAA. OpenMoHAA provides modern rendering and extra compatibility." -ForegroundColor Gray
        if ($message) {
            Write-Host ""
            Write-Host "  $message" -ForegroundColor Yellow
        }

        $items = @()
        $index = 1
        foreach ($profile in Get-GameProfiles) {
            $serverPath = Join-Path $GameDir $profile.ServerExeName
            $gamePath = Join-Path $GameDir $profile.GameExeName
            $state = if ((Test-Path $serverPath) -and (Test-Path $gamePath)) { "ready" } elseif (Test-Path $serverPath) { "server only" } else { "missing server exe" }
            $items += [pscustomobject]@{ Label = "[$index] $($profile.Label) - $state"; Hotkey = "$index"; Action = $profile.Id }
            $index++
        }

        $choice = Invoke-ArrowMenu $items "Select a game profile."
        $profile = Get-GameProfile $choice
        $Settings.ProfileId = $profile.Id
        $Settings.SelectedGame = $profile.Id
        $Settings.ServerExeName = $profile.ServerExeName
        $Settings.GameExeName = $profile.GameExeName
        if ($Settings.MatchMode -notin @($profile.Modes)) {
            Set-MatchModePreset $Settings "ffa"
        } else {
            Set-MatchModePreset $Settings $Settings.MatchMode
        }
        return "$($profile.Label) selected."
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
    $profile = Get-SelectedProfile $settings
    $isRunning = (Get-ServerProcess $settings).Count -gt 0
    
    $menu = @(
        [pscustomobject]@{ Label = "[G] Open $($profile.Label)"; Hotkey = "G"; Action = "Game" }
        [pscustomobject]@{ Label = "[C] Copy friend command"; Hotkey = "C"; Action = "Copy" }
        [pscustomobject]@{ Label = "[E] Server settings"; Hotkey = "E"; Action = "Settings" }
        [pscustomobject]@{ Label = "[N] Network details"; Hotkey = "N"; Action = "Network" }
        [pscustomobject]@{ Label = "[H] How to host"; Hotkey = "H"; Action = "Help" }
    )

    if ($isRunning) {
        $menu += [pscustomobject]@{ Label = "[R] Restart server"; Hotkey = "R"; Action = "Restart" }
        $menu += [pscustomobject]@{ Label = "[S] Stop server"; Hotkey = "S"; Action = "Stop" }
    } else {
        $menu += [pscustomobject]@{ Label = "[S] Start server"; Hotkey = "S"; Action = "Start" }
    }
    
    $menu += [pscustomobject]@{ Label = "[M] Change game"; Hotkey = "M"; Action = "ChangeGame" }
    $menu += [pscustomobject]@{ Label = "[Q] Quit launcher"; Hotkey = "Q"; Action = "Quit" }

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
        "Restart" {
            Stop-Server $settings
            $startResult = Start-Server $settings
            $process = $startResult.Process
            $configState = $startResult.ConfigState
            $message = "Server restarted."
        }
        "Start" {
            $startResult = Start-Server $settings -ForceConfig
            $process = $startResult.Process
            $configState = $startResult.ConfigState
            $message = "Server started."
        }
        "Stop" {
            Stop-Server $settings
            $process = $null
            $message = "Server stopped." 
        }
        "ChangeGame" {
            Stop-Server $settings
            $msg = Show-GameSelector $settings
            Save-Settings $settings
            $startResult = Start-Server $settings -ForceConfig
            $process = $startResult.Process
            $configState = $startResult.ConfigState
            $message = "$msg New server started."
        }
        "Quit" {
            Clear-Host
            Write-Host ""
            Write-Host "  IMUSTAFSKI Server Runner closed." -ForegroundColor Cyan
            Write-Host "  Server process is unchanged. Use Stop server before Quit if you want to stop hosting." -ForegroundColor DarkGray
            exit 0
        }
    }

    Show-Dashboard $settings (Get-ServerProcess $settings | Select-Object -First 1) $configState $message
}
