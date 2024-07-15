<#
    .SYNOPSIS
    Run a SQL command on the specified server
    .DESCRIPTION
    This function runs a SQL command on the specified server
    .PARAMETER Server
    The hostname of the SQL server
    .PARAMETER Command
    The SQL command to run
    .PARAMETER CommandTimeout
    The timeout for the command
#>
function RunSqlCommand()
{
    param(
        [Parameter(Mandatory = $true)]
        [string]$Server,
        [Parameter(Mandatory = $true)]
        [string]$Command,
        [Parameter(Mandatory = $false)]
        [int] $CommandTimeout = 0
    )

    $Options = @{}
    if ($CommandTimeout)
    {
        $Options["QueryTimeout"] = $CommandTimeout
    }

    Write-Verbose "Executing SQL query ($Server): ""$Command"""
    Invoke-Sqlcmd -Query $Command @Options
}

<#
    .SYNOPSIS
    Checks existance of database
    .DESCRIPTION
    Checks if the specified database exists on the SQL server
    .PARAMETER DatabaseName
    The name of the database to check
    .PARAMETER DatabaseServer
    The hostname of the SQL server
    .OUTPUTS
    Returns true if database exists otherwise false
#>
function Test-Database()
{
    param(
        [Parameter(Mandatory = $true)]
        [string]$DatabaseName,
        [Parameter(Mandatory = $false)]
        [string]$DatabaseServer = '.'
    )

    $sqlCommandText = @"
        USE MASTER
        SELECT '1' FROM SYS.DATABASES WHERE NAME = '$DatabaseName'
        GO
"@

    return ($null -ne (RunSqlCommand -Server $DatabaseServer -Command $sqlCommandText))
}

<#
    .SYNOPSIS
    Set the version of an app in the specified database
    .DESCRIPTION
    This function sets the version of an app in the specified database
    .PARAMETER Name
    The name of the app
    .PARAMETER DatabaseName
    The name of the database
    .PARAMETER Major
    The major version number
    .PARAMETER Minor
    The minor version number
    .PARAMETER Publisher
    The publisher of the app
    .PARAMETER DatabaseServer
    The hostname of the SQL server
#>
function Set-AppVersion()
{
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [Parameter(Mandatory = $true)]
        [string]$DatabaseName,
        [Parameter(Mandatory = $true)]
        [string]$Major,
        [Parameter(Mandatory = $true)]
        [string]$Minor,
        [Parameter(Mandatory = $false)]
        [string]$Publisher = 'Microsoft',
        [Parameter(Mandatory = $false)]
        [string]$DatabaseServer = '.'
    )

    Write-Host "Set version $Major.$Minor.0.0 for app $Name published by $Publisher."

    $command = @"
    UPDATE [$DatabaseName].[dbo].[Published Application]
    SET [Version Major] = $Major, [Version Minor] = $Minor, [Version Build] = 0, [Version Revision] = 0
    WHERE Name = '$Name' and Publisher = '$Publisher';

    UPDATE [$DatabaseName].[dbo].[Application Dependency]
    SET [Dependency Version Major] = $Major, [Dependency Version Minor] = $Minor, [Dependency Version Build] = 0, [Dependency Version Revision] = 0
    WHERE [Dependency Name] = '$Name' and [Dependency Publisher] = '$Publisher';

    UPDATE [$DatabaseName].[dbo].[NAV App Installed App]
    SET [Version Major] = $Major, [Version Minor] = $Minor, [Version Build] = 0, [Version Revision] = 0
    WHERE Name = '$Name' and Publisher = '$Publisher';

    UPDATE [$DatabaseName].[dbo].[`$ndo`$navappschematracking]
    SET [version] = '$Major.$Minor.0.0', [baselineversion] = '$Major.$Minor.0.0'
    WHERE [name] = '$Name' and [publisher] = '$Publisher';
"@

    RunSqlCommand -Command $command -Server $DatabaseServer
}

<#
    .SYNOPSIS
    Move the app identified by the given name and publisher from the global scope to the tenant scope

    .PARAMETER Name
    The app's name, as defined in the app's manifest.

    .PARAMETER DatabaseName
    The database on which to execute the query.

    .PARAMETER Publisher
    The app's publisher, as defined in the app's manifest.

    .PARAMETER TenantId
    The tenant in whose scope the app should be moved.

    .PARAMETER DatabaseServer
    The database server on which to run the query.
#>
function Move-AppIntoDevScope()
{
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [Parameter(Mandatory = $true)]
        [string]$DatabaseName,
        [Parameter(Mandatory = $false)]
        [string]$Publisher = 'Microsoft',
        [Parameter(Mandatory = $false)]
        [string]$TenantId = 'default',
        [Parameter(Mandatory = $false)]
        [string]$DatabaseServer = '.'
    )
    Write-Host "Move app $Name published by $Publisher to the DEV scope."

    if (!$TenantId)
    {
        $TenantId = 'default'
    }

    $command = @"
    UPDATE [$DatabaseName].[dbo].[Published Application]
    SET [Published As] = 2, [Tenant ID] = '$TenantId'
"@
    RunSqlCommand -Command $command -Server $DatabaseServer
}

<#
    .SYNOPSIS
    Setup the container for development
    .DESCRIPTION
    This function moves all installed apps to the dev scope and sets the version of the apps to the version of the repo.
    .PARAMETER ContainerName
    The name of the container to setup
    .PARAMETER RepoVersion
    The version of the repo
    .EXAMPLE
    Setup-ContainerForDevelopment -ContainerName "BC-20210101" -RepoVersion 25.0
#>
function Setup-ContainerForDevelopment() {
    param(
        [string] $ContainerName,
        [System.Version] $RepoVersion
    )

    $NewDevContainerModule = "$PSScriptRoot\NewDevContainer.psm1"
    Copy-FileToBcContainer -containerName $ContainerName -localpath $NewDevContainerModule

    Invoke-ScriptInBcContainer -containerName $ContainerName -scriptblock {
        param([string] $DevContainerModule, [System.Version] $RepoVersion, [string] $DatabaseName = "CRONUS")

        Import-Module $DevContainerModule -DisableNameChecking -Force

        $server = Get-NAVServerInstance
        Write-Host "Server: $($server.ServerInstance)" -ForegroundColor Green

        if (-not(Test-Database -DatabaseName $DatabaseName)) {
            throw "Database $DatabaseName does not exist"
        }

        $installedApps = @(Get-NAVAppInfo -ServerInstance $server.ServerInstance)

        # Check that all apps are moved to the dev scope and that the version is reset to the repo version
        # If they are, we can skip the rest of the script
        if (-not ($installedApps | Where-Object { $_.Scope -eq 'Global' })) {
            Write-Host "All apps are already in the Dev Scope" -ForegroundColor Yellow
            if (-not ($installedApps | Where-Object { $_.Version -notmatch "\d+\.\d+\.0\.0" })) {
                Write-Host "All apps are already at version $($RepoVersion).0.0" -ForegroundColor Yellow
                return
            }
        }

        Write-Host "Stopping server instance $($server.ServerInstance)" -ForegroundColor Green
        Stop-NAVServerInstance -ServerInstance $server.ServerInstance

        try {
            $installedApps | ForEach-Object {
                if ($_.Scope -eq 'Global') {
                    Write-Host "Moving $($_.Name) to Dev Scope"
                    Move-AppIntoDevScope -Name ($_.Name) -DatabaseName $DatabaseName
                }
                if ($_.Version -ne "$($RepoVersion.Major).$($RepoVersion.Minor).0.0") {
                    Set-AppVersion -Name ($_.Name) -DatabaseName $DatabaseName -Major $RepoVersion.Major -Minor $RepoVersion.Minor
                }
            }
        } finally {
            Write-Host "Starting server instance $($server.ServerInstance)" -ForegroundColor Green
            Start-NAVServerInstance -ServerInstance $server.ServerInstance
        }


    } -argumentList $NewDevContainerModule,$RepoVersion -usePwsh $false
}

Export-ModuleMember -Function Setup-ContainerForDevelopment
Export-ModuleMember -Function Test-Database
Export-ModuleMember -Function Set-AppVersion
Export-ModuleMember -Function Move-AppIntoDevScope