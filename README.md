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
