New-Alias -Name 'gh' -Value 'Get-Help'

$PSDefaultParameterValues.Add('Get-Help:ShowWindow', $true)
$PSDefaultParameterValues.Add('Out-Default:OutVariable', 'LastOut')
$PSDefaultParameterValues.Add('Format-Table:AutoSize', $true)

function prompt {
    # Set the maximum prompt length as a fraction of the console width.
    $maxLength = [uint16]($host.UI.RawUI.WindowSize.Width * 0.45)
    # ...or try to reserve a given amount of space.
    # $maxLength = $host.UI.RawUI.WindowSize.Width - 80

    # Define the parts of the prompt string.
    $psVer = "PS$($PSVersionTable.PSVersion.Major) "
    $path = $executionContext.SessionState.Path.CurrentLocation.Path
    $prompt = "$('>' * ($nestedPromptLevel + 1)) "

    # Define a function to measure the prompt length.
    function promptLength {
        $psVer.Length + $path.Length + $prompt.Length
    }

    if ((promptLength) -gt $maxLength) {
        # Collapse the $home path to '~'.
        if ($path -like "$home*") { $path = $path.Replace($home, '~') }

        # Use the system path delimiter.
        $dsc = [System.IO.Path]::DirectorySeparatorChar

        # Split the path into an array and filter out empty elements.
        [string[]] $split = $path -split "\$($dsc)" | Where-Object { $_ -match '\S+' }

        # Collapse parts of the path (staring with the 2nd) until the prompt is
        # short enough or the penultimate array element has been collapsed.
        while ((promptLength) -gt $maxLength -and (++$i -lt ($split.Length - 1))) {
            $split[$i] = '..'
            $path = $split -join $dsc
        }
    }

    $psVer, $path, $prompt -join ''

    # The default prompt function definition:
    #  "PS $($executionContext.SessionState.Path.CurrentLocation)$('>' * ($nestedPromptLevel + 1)) ";
    # .Link
    # https://go.microsoft.com/fwlink/?LinkID=225750
    # .ExternalHelp System.Management.Automation.dll-help.xml
}