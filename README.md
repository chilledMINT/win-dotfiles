# Windows terminal dotfiles

This repository contains the PowerShell profile and Windows Terminal appearance
used on my Windows machines.

## Install on a new dev box

Install Git and PowerShell, then run:

```powershell
git clone https://github.com/chilledMINT/win-dotfiles.git
Set-Location .\win-dotfiles
.\Install-Dotfiles.ps1
```

The installer copies the profile to the current PowerShell host's user profile
path and applies the Catppuccin Frappe color scheme with the JetBrains Mono font
as the Windows Terminal default appearance. Existing profile and Terminal
settings are backed up before being changed. Terminal JSON comments and
formatting may be normalized. Restart PowerShell and Windows Terminal to use
the updated settings.

## Copilot skills and plugins

`copilot-manifest.json` defines the Copilot marketplaces, plugins, and skill
directories provisioned on a dev box. Add new plugins or repositories to that
manifest, then run:

```powershell
.\Install-Copilot.ps1
```

The script registers missing marketplaces, installs missing plugins, enables
the listed plugins, and merges skill directories into
`~\.copilot\settings.json` without replacing other Copilot settings.

`Install-Dotfiles.ps1` also runs `Install-Copilot.ps1`, so one dev-box
bootstrap command provisions the terminal, Copilot plugins, marketplaces, and
skill directories.
