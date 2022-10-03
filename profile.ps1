New-Alias -Name 'gh' -Value 'Get-Help'

$PSDefaultParameterValues.Add('Get-Help:ShowWindow', $true)
$PSDefaultParameterValues.Add('Out-Default:OutVariable', 'LastOut')

function prompt {
    # Set the maximum path length as a fraction of the console width...
    # $maxLength = [uint16]($host.UI.RawUI.WindowSize.Width / 4)
    # ...or try reserve a number of characters.
    $maxLength = $host.UI.RawUI.WindowSize.Width - 88

    $location = $executionContext.SessionState.Path.CurrentLocation.Path

    if ($location.Length -gt $maxLength) {
        # Collapse the $home path to '~'.
        if ($location -like "$home*") { $location = $location.Replace($home, '~') }

        # Use the system path delimiter.
        $dsc = [System.IO.Path]::DirectorySeparatorChar

        # Split the path into an array and filter out empty elements.
        [string[]] $split = $location -split "\$($dsc)" | Where-Object { $_ -match '\S+' }

        if ($split.Length -gt 1) {
            # Build the path string from the current location up.
            do {
                $buildPath = $split[--$i], $buildPath -join $dsc
            } 
            while (
                ($buildPath.Length + $split[$i - 1].Length + 1) -lt ($maxLength - $split[0].Length) -and 
                ($split.Length - 1) -gt [Math]::Abs($i)
            )
            $buildPath = $buildPath.Trim($dsc)
        }

        # Always include the first element of the array.
        $location = $split[0] 
        if (($split.Length - 1) -gt [Math]::Abs($i)) { $location += "$dsc.." }
        $location = $location, $buildPath -join $dsc
    }

    # Include the major PS version.
    $ver = $PSVersionTable.PSVersion.Major

    "PS$ver $location$('>' * ($nestedPromptLevel + 1)) "

    # The default prompt function definition:
    #  "PS $($executionContext.SessionState.Path.CurrentLocation)$('>' * ($nestedPromptLevel + 1)) ";
    # .Link
    # https://go.microsoft.com/fwlink/?LinkID=225750
    # .ExternalHelp System.Management.Automation.dll-help.xml
}