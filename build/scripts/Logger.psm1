# This is temporarily needed as the GDL files were copied from NAV and uses the logger module from there. This should eventually be replaced.

<#
.SYNOPSIS
Writes output to log, automatically adding date and time.
.DESCRIPTION
Writes a message and timestamp to the host as well as the 'verbose.log' file.
Defaults to the Logs folder under INETROOT, or the repository root when INETROOT is unset.
#>
function Write-Log
(
    [Parameter(ValueFromPipeline=$true,Position=0)]
    [PSObject] $Message,
    [string] $ForegroundColor = 'Gray',
    [switch] $Warning,
    [switch] $IsError,
    [switch] $NoVerbose,
    [string] $LogFolder,
    [string] $LogFile = "verbose.log",
    [string] $Prefix = "",
    [switch] $SkipLineHeader
)
{
    Begin {
        if (-not $LogFolder) {
            $logRoot = if ($env:INETROOT) { $env:INETROOT } else { Join-Path $PSScriptRoot "../.." }
            $LogFolder = Join-Path $logRoot "Logs"
        }
        if( -not [System.IO.Directory]::Exists($LogFolder))
        {
            New-Item -Type Directory -Path $LogFolder -Force | Out-Null
        }
        $LogPath = Join-Path $LogFolder $LogFile

        $mutex = New-Object System.Threading.Mutex($false, 'EnlistLoggerMutex')

        $Debug = $PSBoundParameters['Debug']
        if($Warning)
        {
            $ForegroundColor = 'Yellow'
        }
        if($IsError)
        {
            $ForegroundColor = 'Red'
        }
    }

    Process {
        try
        {
            [bool] $Locked = $mutex.WaitOne(5 * 1000)
            $LineHeading = "[$(Get-Date -Format "yyyy-MM-dd HH:mm:ss")]"

            $Message | Out-String -Stream |
            % {
                if ($SkipLineHeader)
                {
                    $LogLine = "$Prefix$_"
                }
                else
                {
                    $LogLine = "$LineHeading $Prefix$_"
                }

                # First line holds time-stamp consecutive lines are marked
                $LineHeading = "---------------------"

                if(!$NoVerbose -and $Locked)
                {
                    $LogLine | Out-File $LogPath -Append -Encoding ASCII
                }

                $uiSupported = $Host.UI.RawUI.BufferSize

                if(!$Debug -and $uiSupported)
                {
                    Write-Host "$LogLine" -ForegroundColor $ForegroundColor
                }
            }
       }
       finally
       {
            if ($Locked)
            {
                $mutex.ReleaseMutex()
            }
       }

    }
    End {
        $mutex.Dispose()

        if($IsError)
        {
            throw "An error was logged."
        }
    }
}

Export-ModuleMember -Function "*-*"
