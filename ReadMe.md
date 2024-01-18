# PowerShell Profile

This is the repository for my `profile.ps1` file. I use it for both Windows
PowerShell 5.1 and PowerShell (Core/6+) and all PowerShell hosts (Windows
Terminal, VSCode, etc.).

I keep unified `*profile.ps1` files at a custom location: `MyPowerShell`,
sibling to the `PowerShell` and `WindowsPowerShell` folders under "My
Documents". The default profile locations have files which then dot-source files
of the same name in the `MyPowerShell` directory. The contents of all those
files are contained in `redirect.profile.ps1`.

## Features

The goal with this profile is to provide small enhancements which make for a
more pleasant terminal experience without going overboard on the level of
customization in the vein of [Oh My Posh](https://ohmyposh.dev/). If it were to
be branded, 'Default Plus' would be a good name.

**The sub-sections below are out of date, I'll fix them up eventually.**

### Aliases

- `Get-Help` is abbreviated to `gh`

### Default Parameters

- `Get-Help` has `-ShowWindow` applied to keep a cleaner terminal buffer.

### Prompt

- The major version of PowerShell is appended to 'PS' at the beginning of the
  prompt and if the terminal supports ANSI control characters, it is stylized to
  reduce visual prominence.
- If the PowerShell session is running in an Administrator context,
  `"$env:username@"` is prepended to the path as a reminder that commands will
  be run in that context.
- If the prompt will exceed half the width of the terminal, the path will be
  truncated as necessary while retaining context.
- If the terminal supports ANSI control characters, the posh-git module has been
  imported, and the current location is a Git repository, the Git status will be
  appended to the path.
  