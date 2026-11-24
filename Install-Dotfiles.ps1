[CmdletBinding(SupportsShouldProcess)]
param()

$ErrorActionPreference = 'Stop'

$sourceProfile = Join-Path $PSScriptRoot 'profiles\Microsoft.PowerShell_profile.ps1'
if (-not (Test-Path -LiteralPath $sourceProfile -PathType Leaf)) {
    throw "PowerShell profile not found: $sourceProfile"
}

$appearancePath = Join-Path $PSScriptRoot 'terminal\appearance.json'
if (-not (Test-Path -LiteralPath $appearancePath -PathType Leaf)) {
    throw "Windows Terminal appearance settings not found: $appearancePath"
}

$terminalSettingsCandidates = @(
    (Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json'),
    (Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.WindowsTerminalPreview_8wekyb3d8bbwe\LocalState\settings.json'),
    (Join-Path $env:LOCALAPPDATA 'Microsoft\Windows Terminal\settings.json')
)
$terminalSettingsPath = $terminalSettingsCandidates |
    Where-Object { Test-Path -LiteralPath $_ -PathType Leaf } |
    Select-Object -First 1
if (-not $terminalSettingsPath) {
    throw 'Windows Terminal settings.json was not found. Install Windows Terminal before applying its appearance settings.'
}

function Remove-JsonCommentsAndTrailingCommas {
    param([string]$Json)

    $withoutComments = [System.Text.StringBuilder]::new()
    $inString = $false
    $escaped = $false
    for ($i = 0; $i -lt $Json.Length; $i++) {
        $character = $Json[$i]
        if ($inString) {
            [void]$withoutComments.Append($character)
            if ($escaped) {
                $escaped = $false
            }
            elseif ($character -eq '\') {
                $escaped = $true
            }
            elseif ($character -eq '"') {
                $inString = $false
            }
            continue
        }

        if ($character -eq '"') {
            $inString = $true
            [void]$withoutComments.Append($character)
        }
        elseif ($character -eq '/' -and $i + 1 -lt $Json.Length -and $Json[$i + 1] -eq '/') {
            while ($i -lt $Json.Length -and $Json[$i] -ne "`n" -and $Json[$i] -ne "`r") {
                $i++
            }
            if ($i -lt $Json.Length) {
                [void]$withoutComments.Append($Json[$i])
            }
        }
        elseif ($character -eq '/' -and $i + 1 -lt $Json.Length -and $Json[$i + 1] -eq '*') {
            $i += 2
            while ($i + 1 -lt $Json.Length -and -not ($Json[$i] -eq '*' -and $Json[$i + 1] -eq '/')) {
                $i++
            }
            if ($i + 1 -ge $Json.Length) {
                throw 'Windows Terminal settings contain an unterminated block comment.'
            }
            $i++
            [void]$withoutComments.Append(' ')
        }
        else {
            [void]$withoutComments.Append($character)
        }
    }

    $source = $withoutComments.ToString()
    $result = [System.Text.StringBuilder]::new()
    $inString = $false
    $escaped = $false
    for ($i = 0; $i -lt $source.Length; $i++) {
        $character = $source[$i]
        if ($inString) {
            [void]$result.Append($character)
            if ($escaped) {
                $escaped = $false
            }
            elseif ($character -eq '\') {
                $escaped = $true
            }
            elseif ($character -eq '"') {
                $inString = $false
            }
            continue
        }

        if ($character -eq '"') {
            $inString = $true
            [void]$result.Append($character)
        }
        elseif ($character -eq ',') {
            $next = $i + 1
            while ($next -lt $source.Length -and [char]::IsWhiteSpace($source[$next])) {
                $next++
            }
            if ($next -ge $source.Length -or ($source[$next] -ne '}' -and $source[$next] -ne ']')) {
                [void]$result.Append($character)
            }
        }
        else {
            [void]$result.Append($character)
        }
    }

    $result.ToString()
}

$appearance = Get-Content -LiteralPath $appearancePath -Raw | ConvertFrom-Json
$terminalSettings = Get-Content -LiteralPath $terminalSettingsPath -Raw |
    ForEach-Object { Remove-JsonCommentsAndTrailingCommas $_ } |
    ConvertFrom-Json

if (-not $terminalSettings.profiles) {
    $terminalSettings | Add-Member -MemberType NoteProperty -Name profiles -Value ([pscustomobject]@{}) -Force
}
if (-not $terminalSettings.profiles.defaults) {
    $terminalSettings.profiles | Add-Member -MemberType NoteProperty -Name defaults -Value ([pscustomobject]@{}) -Force
}
$defaults = $terminalSettings.profiles.defaults
$defaults | Add-Member -MemberType NoteProperty -Name colorScheme -Value $appearance.colorScheme.name -Force
if (-not $defaults.font) {
    $defaults | Add-Member -MemberType NoteProperty -Name font -Value ([pscustomobject]@{})
}
$defaults.font | Add-Member -MemberType NoteProperty -Name face -Value $appearance.fontFace -Force

$schemes = @($terminalSettings.schemes | Where-Object { $_.name -ne $appearance.colorScheme.name })
$terminalSettings | Add-Member -MemberType NoteProperty -Name schemes -Value (@($schemes) + @($appearance.colorScheme)) -Force
$updatedSettings = $terminalSettings | ConvertTo-Json -Depth 100

$targetProfile = $PROFILE.CurrentUserCurrentHost
$targetDirectory = Split-Path -Parent $targetProfile

if ($PSCmdlet.ShouldProcess($targetProfile, 'Install PowerShell profile')) {
    if (-not (Test-Path -LiteralPath $targetDirectory -PathType Container)) {
        New-Item -ItemType Directory -Path $targetDirectory -Force | Out-Null
    }

    if (Test-Path -LiteralPath $targetProfile -PathType Leaf) {
        $backupPath = "$targetProfile.bak-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
        Copy-Item -LiteralPath $targetProfile -Destination $backupPath
        Write-Output "Backed up existing profile to: $backupPath"
    }

    Copy-Item -LiteralPath $sourceProfile -Destination $targetProfile -Force
    Write-Output "Installed PowerShell profile to: $targetProfile"
}

if ($PSCmdlet.ShouldProcess($terminalSettingsPath, 'Apply Windows Terminal appearance')) {
    $backupPath = "$terminalSettingsPath.bak-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    Copy-Item -LiteralPath $terminalSettingsPath -Destination $backupPath
    Set-Content -LiteralPath $terminalSettingsPath -Value $updatedSettings -Encoding UTF8
    Write-Output "Backed up Windows Terminal settings to: $backupPath"
    Write-Output "Applied Windows Terminal appearance to: $terminalSettingsPath"
}

$copilotInstaller = Join-Path $PSScriptRoot 'Install-Copilot.ps1'
if ($PSCmdlet.ShouldProcess($copilotInstaller, 'Install Copilot skills and plugins')) {
    & $copilotInstaller
}
