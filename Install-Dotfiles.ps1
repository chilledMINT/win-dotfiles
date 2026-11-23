[CmdletBinding(SupportsShouldProcess)]
param()

$ErrorActionPreference = 'Stop'

$sourceProfile = Join-Path $PSScriptRoot 'profiles\Microsoft.PowerShell_profile.ps1'
if (-not (Test-Path -LiteralPath $sourceProfile -PathType Leaf)) {
    throw "PowerShell profile not found: $sourceProfile"
}

$targetProfile = $PROFILE.CurrentUserCurrentHost
$targetDirectory = Split-Path -Parent $targetProfile

if (-not (Test-Path -LiteralPath $targetDirectory -PathType Container)) {
    New-Item -ItemType Directory -Path $targetDirectory -Force | Out-Null
}

if ($PSCmdlet.ShouldProcess($targetProfile, 'Install PowerShell profile')) {
    if (Test-Path -LiteralPath $targetProfile -PathType Leaf) {
        $backupPath = "$targetProfile.bak-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
        Copy-Item -LiteralPath $targetProfile -Destination $backupPath
        Write-Output "Backed up existing profile to: $backupPath"
    }

    Copy-Item -LiteralPath $sourceProfile -Destination $targetProfile -Force
    Write-Output "Installed PowerShell profile to: $targetProfile"
}
