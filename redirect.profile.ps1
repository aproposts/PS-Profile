. (& { 
    $joinPathSplat = @{
        Path = & {
            $joinPathSplat = @{
                Path = [Environment]::GetFolderPath('MyDocuments')
                ChildPath = 'MyPowerShell'
            }
            Join-Path @joinPathSplat
        }
        ChildPath = Split-Path -Leaf $PSCommandPath
    }
    Join-Path @joinPathSplat
})