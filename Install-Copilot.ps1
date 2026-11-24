[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$ManifestPath = (Join-Path $PSScriptRoot 'copilot-manifest.json')
)

$ErrorActionPreference = 'Stop'

if (-not (Get-Command copilot -ErrorAction SilentlyContinue)) {
    throw 'Copilot CLI was not found on PATH.'
}

$manifest = Get-Content -LiteralPath $ManifestPath -Raw | ConvertFrom-Json
$copilotDirectory = Join-Path $env:USERPROFILE '.copilot'
$settingsPath = Join-Path $copilotDirectory 'settings.json'

if (-not (Test-Path -LiteralPath $copilotDirectory -PathType Container)) {
    New-Item -ItemType Directory -Path $copilotDirectory -Force | Out-Null
}

$settings = [pscustomobject]@{}
if (Test-Path -LiteralPath $settingsPath -PathType Leaf) {
    $settings = Get-Content -LiteralPath $settingsPath -Raw | ConvertFrom-Json
}

if (-not $settings.extraKnownMarketplaces) {
    $settings | Add-Member -MemberType NoteProperty -Name extraKnownMarketplaces -Value ([pscustomobject]@{}) -Force
}
if (-not $settings.enabledPlugins) {
    $settings | Add-Member -MemberType NoteProperty -Name enabledPlugins -Value ([pscustomobject]@{}) -Force
}
if (-not $settings.skillDirectories) {
    $settings | Add-Member -MemberType NoteProperty -Name skillDirectories -Value @() -Force
}

$registeredMarketplaces = copilot plugin marketplace list

foreach ($marketplace in @($manifest.marketplaces)) {
    $alreadyRegistered = @($registeredMarketplaces | Where-Object { $_ -match [regex]::Escape($marketplace.name) }).Count -gt 0
    if (-not $alreadyRegistered) {
        if ($PSCmdlet.ShouldProcess($marketplace.name, 'Register Copilot plugin marketplace')) {
            & copilot plugin marketplace add $marketplace.source
        }
    }

    $settings.extraKnownMarketplaces | Add-Member `
        -MemberType NoteProperty `
        -Name $marketplace.name `
        -Value ([pscustomobject]@{
            source = [pscustomobject]@{
                source = 'github'
                repo = $marketplace.source
            }
        }) `
        -Force
}

$installedPlugins = & copilot plugin list --json | ConvertFrom-Json

foreach ($plugin in @($manifest.plugins)) {
    $alreadyInstalled = @($installedPlugins | Where-Object {
        $_.name + '@' + $_.marketplace -eq $plugin
    }).Count -gt 0

    if (-not $alreadyInstalled) {
        if ($PSCmdlet.ShouldProcess($plugin, 'Install Copilot plugin')) {
            & copilot plugin install $plugin
        }
    }

    $settings.enabledPlugins | Add-Member `
        -MemberType NoteProperty `
        -Name $plugin `
        -Value $true `
        -Force
}

$skillDirectories = [System.Collections.Generic.List[string]]@($settings.skillDirectories)
foreach ($directory in @($manifest.skillDirectories)) {
    $resolvedDirectory = [Environment]::ExpandEnvironmentVariables($directory)
    if (-not [System.IO.Path]::IsPathRooted($resolvedDirectory)) {
        $resolvedDirectory = [System.IO.Path]::GetFullPath(
            (Join-Path $PSScriptRoot $resolvedDirectory)
        )
    }

    if (-not (Test-Path -LiteralPath $resolvedDirectory -PathType Container)) {
        throw "Skill directory not found: $resolvedDirectory"
    }

    if ($skillDirectories -notcontains $resolvedDirectory) {
        $skillDirectories.Add($resolvedDirectory)
    }

    if ($PSCmdlet.ShouldProcess($resolvedDirectory, 'Register Copilot skill directory')) {
        & copilot skill add $resolvedDirectory
    }
}
$settings.skillDirectories = $skillDirectories.ToArray()

if ($PSCmdlet.ShouldProcess($settingsPath, 'Update Copilot settings')) {
    $settings | ConvertTo-Json -Depth 20 |
        Set-Content -LiteralPath $settingsPath -Encoding UTF8
    Write-Output "Updated Copilot settings: $settingsPath"
}
