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

$skills = [ordered]@{
    'ponytail'       = 'https://raw.githubusercontent.com/DietrichGebert/ponytail/df9e89941d50419fd5bcf1de41e28097f1db49b2/skills/ponytail/SKILL.md'
    'socratic-tutor' = 'https://raw.githubusercontent.com/janestreet/agent_skills/7c6715c29548a3b39d4a9545c698ee4fd17a7213/socratic-tutor/SKILL.md'
}

$copilotHome = if ($env:COPILOT_HOME) { $env:COPILOT_HOME } else { Join-Path $HOME '.copilot' }
foreach ($name in $skills.Keys) {
    if (Test-Path -LiteralPath (Join-Path $copilotHome "skills\$name\SKILL.md") -PathType Leaf) {
        continue
    }
    if ($PSCmdlet.ShouldProcess($name, 'Install personal Copilot skill')) {
        copilot skill add $skills[$name]
        if ($LASTEXITCODE -ne 0) { throw "Failed to install Copilot skill: $name" }
    }
}
