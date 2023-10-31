# Set some aliases.
Set-Alias -Name 'gh' -Value 'Get-Help'
Set-Alias -Name 'mc' -Value 'Measure-Command'
Set-Alias -Name 'rvdns' -Value 'Resolve-DnsName'
Set-Alias -Name 'gsc' -Value 'Get-Secret'

# Convenient default parameters.
$PSDefaultParameterValues = @{
    'Get-Help:ShowWindow'               = $true
    'Get-Secret:Name'                   = 'sys'
    'New-PSSession:Credential'          = { Get-Secret }
    'Connect-SharedResource:Credential' = { Get-Secret }
}

# Add the CurrentUser Windows Powershell Scripts location to the environment path.
if ($PSVersionTable.PSEdition -eq 'Desktop' -or
    $PSVersionTable.OS -like '*Windows*'
) {
    $local:scriptPath = '{0}\WindowsPowershell\Scripts' -f [System.Environment]::GetFolderPath('MyDocuments')
    [System.Collections.ArrayList] $local:envPathArray = $env:Path -split ';'

    if ($local:scriptPath -notin $local:envPathArray) {
        $local:envPathArray.Add($scriptPath) | Out-Null
        $env:Path = $local:envPathArray -join ';'
    }
}

# Add the CurrentUser Windows Powershell module path to the new/core Powershell module path.
if ($PSVersionTable.PSEdition -eq 'Core' -and
    $PSVersionTable.OS -like '*Windows*'
) {
    [System.Collections.ArrayList] $local:modulePathArray = $env:PSModulePath.Split(';')
    $local:currUserWinPSPath = (
        '{0}\WindowsPowerShell\Modules' -f [System.Environment]::GetFolderPath('MyDocuments')
    )
    
    if (-not $modulePathArray.Contains($local:currUserWinPSPath)) {
        $local:modulePathArray.Insert(1, $local:currUserWinPSPath) | Out-Null
        $env:PSModulePath = $local:modulePathArray -join ';'
    }
}

function prompt {
    # Define the variables to prevent scope conflicts.
    $local:psVerNoANSI = [string] ''
    $local:psVer = [string] ''
    $local:historyIdNoANSI = [string] ''
    $local:historyId = [string] ''
    $local:user = [string] ''
    $local:path = [string] ''
    $local:git = [string] ''
    $local:gitNoAnsi = [string] ''
    $local:prompt = [string] ''

    # Inclue the major PSVersion in the prompt.
    $psVerNoANSI = "PS$($PSVersionTable.PSVersion.Major) "

    # Include the history ID of the current command if OutputHistory is loaded.
    if (Get-Module OutputHistory) {
        $historyIdNoANSI = " $($MyInvocation.HistoryId.ToString().PadLeft(2,'0')) "
    }

    # Stylize the PSVersion and history ID part of the prompt if the host is ANSI capable.
    if ($Host.UI.SupportsVirtualTerminal) {
        $esc = $([char]27)
        $psVer = "$esc[3m$esc[38;5;8m$psVerNoANSI$esc[0m"
        $historyId = "$esc[38;5;8m$historyIdNoANSI$esc[0m"
    }
    else {
        $psVer = $psVerNoANSI
        $historyId = $historyIdNoANSI
    }

    # Include the username in the prompt if the session is in an Admin context.
    $local:isAdmin = [Security.Principal.WindowsPrincipal]::new(
        [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
        [Security.Principal.WindowsBuiltinRole]::Administrator)
    if ($isAdmin) { $user = "$env:USERNAME@" }

    # Use ProviderPath if there's no drive defined for the location provider.
    if ($executionContext.SessionState.Path.CurrentLocation.Drive) {
        $path = $executionContext.SessionState.Path.CurrentLocation.Path
    }
    else {
        $path = $executionContext.SessionState.Path.CurrentLocation.ProviderPath
    }

    # Only provide Git info if the host supports ANSI colors...
    if ($Host.UI.SupportsVirtualTerminal -and 
        # ...the posh-git moduled is loaded...
        (Get-Module 'posh-git') -and 
        # ...and we're in a repository.
        ($git = "$(Write-GitStatus (Get-GitStatus))".Trim(' '))
    ) {
        $git = ':' + $git
        $gitNoANSI = $git -replace '\x1b\[[0-9;]*m', ''
    }

    $prompt = "$('>' * ($nestedPromptLevel + 1)) "

    # Define a function to measure the prompt length.
    function promptLength {
        $psVerNoANSI.Length + 
        $historyIdNoANSI.Length + 
        $user.Length + 
        $path.Length + 
        $gitNoANSI.Length + 
        $prompt.Length
    }

    # Set the maximum prompt length as a fraction of the console width.
    $maxLength = [uint16]($Host.UI.RawUI.BufferSize.Width * 0.5) # Use 'BufferSize' to support ISE.
    # ...or try to reserve a given amount of space.
    # $maxLength = $Host.UI.RawUI.BufferSize.Width - 80 # Use 'BufferSize' to support ISE.

    if ((promptLength) -gt $maxLength) {
        # Collapse the $Home path to '~'.
        if ($path -like "$Home*") { $path = $path.Replace($Home, '~') }

        # Use the system path delimiter.
        $dsc = [System.IO.Path]::DirectorySeparatorChar

        # Isolate the first element of the path which may contain DSC characters (as in a UNC path).
        $matchInfo = $path | Select-String -Pattern "(.*?[^\$($dsc)]+)\$($dsc)(.*)"
        [string[]] $split = $matchInfo.Matches.Groups[1]
        # Populate the rest of the array with the remaining path elements.
        $split += $matchInfo.Matches.Groups[2] -split "\$($dsc)" | Where-Object { $_ -match '\S+' }

        # Collapse parts of the path (staring with the 2nd) until the prompt is
        # short enough, or the penultimate array element has been collapsed.
        while ((promptLength) -gt $maxLength -and (++$i -lt ($split.Length - 1))) {
            $split[$i] = '..'
            $path = $split -join $dsc
        }
    }

    $psVer,
    $historyId,
    $user,
    $path,
    $git,
    $prompt -join ''

    # The default prompt function definition:
    #  "PS $($executionContext.SessionState.Path.CurrentLocation)$('>' * ($nestedPromptLevel + 1)) ";
    # .Link
    # https://go.microsoft.com/fwlink/?LinkID=225750
    # .ExternalHelp System.Management.Automation.dll-help.xml
}

# PSReadline Configuration
if (Get-Module -Name PSReadLine) {
    # Set-PSReadLineKeyHandler -Key Tab -Function Complete # Redundnat in Emacs EditMode
    Set-PSReadLineOption -EditMode Emacs
    Set-PSReadLineKeyHandler -Key @('UpArrow', 'Ctrl+p') -Function HistorySearchBackward
    Set-PSReadLineKeyHandler -Key @('DownArrow', 'Ctrl+n') -Function HistorySearchForward
    Set-PSReadLineKeyHandler -Key 'Ctrl+Spacebar' -Function SetMark
    Set-PSReadLineKeyHandler -Key 'Ctrl+/' -Function Undo
    Set-PSReadLineKeyHandler -Key 'Ctrl+?' -Function Redo

    function selectRegion {
        $string = $point = $mark = $null
        [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$string, [ref]$point)
        [Microsoft.PowerShell.PSConsoleReadLine]::ExchangePointAndMark()
        [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$string, [ref]$mark)
                
        switch ($point - $mark) {
            { $_ -gt 0 } {
                for ($i = 0; $i -lt $_; $i++ ) {
                    [Microsoft.PowerShell.PSConsoleReadLine]::SelectForwardChar()
                }
            }
            { $_ -lt 0 } {
                for ($i = 0; $i -gt $_; $i-- ) {
                    [Microsoft.PowerShell.PSConsoleReadLine]::SelectBackwardChar()
                }
            }
            default {
                throw 'No region to select.'
            }
        }
    }

    function cancelSelection {
        $string = $cursor = $null 
        [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$string, [ref]$cursor)
        
        $start = $length = $null
        [Microsoft.PowerShell.PSConsoleReadLine]::GetSelectionState([ref]$start, [ref]$length)

        switch ($cursor - $start) {
            { $_ -gt 0 } {
                for ($i = 0; $i -lt $length; $i++) {
                    [Microsoft.PowerShell.PSConsoleReadLine]::SelectBackwardChar()
                }
            }
            { $_ -le 0 } {
                for ($i = 0; $i -lt $length; $i++ ) {
                    [Microsoft.PowerShell.PSConsoleReadLine]::SelectForwardChar()
                }
            }
        }
        [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($cursor)
    }

    Set-PSReadLineKeyHandler -Key 'Ctrl+w' -ScriptBlock {
        param($key, $arg)

        try {
            selectRegion
            [Microsoft.PowerShell.PSConsoleReadLine]::Copy()
            [Microsoft.PowerShell.PSConsoleReadLine]::KillRegion()
            cancelSelection
            [Microsoft.PowerShell.PSConsoleReadLine]::SetMark()
        }
        catch {}
    } 

    Set-PSReadLineKeyHandler -Key 'Alt+w' -ScriptBlock {
        param($key, $arg)

        try {
            $string = $cursorA = $cursorB = $null 
            [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$string, [ref]$cursorA)
            selectRegion
            [Microsoft.PowerShell.PSConsoleReadLine]::Copy()
            [Microsoft.PowerShell.PSConsoleReadLine]::KillRegion()
            [Microsoft.PowerShell.PSConsoleReadLine]::SetMark()
            [Microsoft.PowerShell.PSConsoleReadLine]::Yank()
            cancelSelection
            [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$string, [ref]$cursorB)
            if ($cursorB -ne $cursorA) {
                [Microsoft.PowerShell.PSConsoleReadLine]::ExchangePointAndMark()
            }
        }
        catch {}
    }

    Set-PSReadLineKeyHandler -Key 'Ctrl+k' -ScriptBlock {
        param($key, $arg)

        try {
            [Microsoft.PowerShell.PSConsoleReadLine]::SetMark()
            [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition([int32]::MaxValue)
            selectRegion
            [Microsoft.PowerShell.PSConsoleReadLine]::Copy()
            [Microsoft.PowerShell.PSConsoleReadLine]::KillRegion()
        }
        catch {}
    }
}