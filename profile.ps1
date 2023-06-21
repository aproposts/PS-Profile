# A 'helpful' alias.
New-Alias -Name 'gh' -Value 'Get-Help'
New-Alias -Name 'mc' -Value 'Measure-Command'
New-Alias -Name 'rvdns' -Value 'Resolve-DnsName'

# Convenient default parameters.
$PSDefaultParameterValues = @{
    'Get-Help:ShowWindow' = $true
    'New-PSSession:Credential' = {Get-Secret sys}
    'Enter-PSSession:Credential' = {Get-Secret sys}
}

# PSReadline Configuration
if (Get-Module -Name PSReadLine) {
    Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
    Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
    Set-PSReadLineKeyHandler -Key Tab -Function Complete
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
        $local:modulePathArray.Insert(1,$local:currUserWinPSPath) | Out-Null
        $env:PSModulePath = $local:modulePathArray -join ';'
    }
}

function prompt {
    # Define the variables to prevent scope conflicts.
    [string] $local:psVerNoANSI = ''
    [string] $local:psVer = ''
    [string] $local:historyIdNoANSI = ''
    [string] $local:historyId = ''
    [string] $local:user = ''
    [string] $local:path = ''
    [string] $local:git = ''
    [string] $local:gitNoAnsi = ''
    [string] $local:prompt = ''

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
    } else {
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
    } else {
        $path = $executionContext.SessionState.Path.CurrentLocation.ProviderPath
    }

    # Only provide Git info if the host supports ANSI colors...
    if ($Host.UI.SupportsVirtualTerminal -and 
        # ...the posh-git moduled is loaded...
        (Get-Module 'posh-git') -and 
        # ...and we're in a repository.
        ($git = "$(Write-GitStatus (Get-GitStatus))".Trim(' '))) {
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