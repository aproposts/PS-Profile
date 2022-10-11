# A 'helpful' alias.
New-Alias -Name 'gh' -Value 'Get-Help'

# Convenient default parameters.
$PSDefaultParameterValues.Add('Get-Help:ShowWindow', $true)
$PSDefaultParameterValues.Add('Format-Table:AutoSize', $true)

# Copy default output into a variable.
$PSDefaultParameterValues.Add('Out-Default:OutVariable', 'LastOut')

function prompt {

    # Inclue the major PSVersion in the prompt.
    $psVerNoANSI = "PS$($PSVersionTable.PSVersion.Major) "
    # Stylize the PSVersion part of the prompt if the host is ANSI capable.
    if ($Host.UI.SupportsVirtualTerminal) {
        $esc = $([char]27)
        $psVer = "$esc[3m$esc[38;5;8m$psVerNoANSI$esc[0m"
    } else { $psVer = $psVerNoANSI }

    # Include the username in the prompt if the session is in an Admin context.
    $isAdmin = [Security.Principal.WindowsPrincipal]::new(
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
        $psVerNoANSI.Length + $user.Length + $path.Length + $gitNoANSI.Length + $prompt.Length
    }

    # Set the maximum prompt length as a fraction of the console width.
    $maxLength = [uint16]($host.UI.RawUI.BufferSize.Width * 0.5) # Use 'BufferSize' to support ISE.
    # ...or try to reserve a given amount of space.
    # $maxLength = $host.UI.RawUI.BufferSize.Width - 80 # Use 'BufferSize' to support ISE.

    if ((promptLength) -gt $maxLength) {
        # Collapse the $home path to '~'.
        if ($path -like "$home*") { $path = $path.Replace($home, '~') }

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

    $psVer, $user, $path, $git, $prompt -join ''

    # The default prompt function definition:
    #  "PS $($executionContext.SessionState.Path.CurrentLocation)$('>' * ($nestedPromptLevel + 1)) ";
    # .Link
    # https://go.microsoft.com/fwlink/?LinkID=225750
    # .ExternalHelp System.Management.Automation.dll-help.xml
}