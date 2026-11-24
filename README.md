# Windows terminal dotfiles

This repository contains my Windows PowerShell prompt and personal Copilot skills.

## Install on a new dev box

Install Git, PowerShell, and GitHub Copilot CLI (with `copilot skill add`), then run:

```powershell
git clone https://github.com/chilledMINT/win-dotfiles.git
Set-Location .\win-dotfiles
.\Install-Dotfiles.ps1
```

The installer copies the profile to the current PowerShell host's user profile
path. If a profile already exists there, it is backed up before being replaced.
Restart PowerShell to use the new prompt.

The installer also restores `ponytail` and `socratic-tutor` from pinned upstream
revisions. Existing personal copies are left alone. Run `copilot skill list` to
see them. Built-in and Agency-managed plugins are not part of these dotfiles.
