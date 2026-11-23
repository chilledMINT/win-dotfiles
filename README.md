# Windows terminal dotfiles

This repository contains the PowerShell profile used on my Windows machines.

## Install on a new dev box

Install Git and PowerShell, then run:

```powershell
git clone https://github.com/chilledMINT/win-dotfiles.git
Set-Location .\win-dotfiles
.\Install-Dotfiles.ps1
```

The installer copies the profile to the current PowerShell host's user profile
path. If a profile already exists there, it is backed up before being replaced.
Restart PowerShell to use the new prompt.
