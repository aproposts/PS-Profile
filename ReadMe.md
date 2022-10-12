# PowerShell Profile

This is the repository for my `profile.ps1` file. I use it for both Windows
PowerShell 5.1 and PowerShell (Core) 7.2 and all PowerShell hosts (Windows
Terminal, VSCode, etc.).

I keep one copy at the PowerShell (Core) 7.2
`$PROFILE.CurrentUserAllHosts` location (`~\Documents\Powershell\profile.ps1`)
and have stub `profile.ps1` files for Windows PowerShell and
other users which dot-source this profile.

## Features

The goal with this profile is to small enhancements to make for a more pleasant
terminal experience without going overboard on the level of customization. If it
were to be branded, 'Default Plus' would be a good name.

### Aliases

- `Get-Help` is abbreviated to `gh`

### Default Parameters

- `Get-Help` has `-ShowWindow` applied to keep a cleaner terminal buffer.
- `Format-Table` has `-AutoSize` applied for nicer presentation of table data in
  the terminal.
- `Out-Default` writes to the variable `$LastOut`, which can be useful when you
  forget to assign output to a variable. If you wish to copy the contents of
  $LastOut to a new variable, you'll need to copy the *value* of `$LastOut` in
  the following manner:
  ```ps
  $newVariable = $LastOut.Clone()
  ```

### Prompt

- The major version of PowerShell is appended to 'PS' at the beginning of the
  prompt and if the terminal supports ANSI control characters, it is stylized to
  reduce visual prominence.
- If the PowerShell session is running in an Administrator context,
  `$env:username@` is prepended to the path as a reminder that commands will be
  run in that context.
- If the prompt will exceed half the width of the terminal, the path will be
  truncated while retaining context.
- If the terminal supports ANSI control characters, the posh-git module has been
  imported, and the current location is a Git repository, the Git status will be
  appended to the path.