#.DESCRIPTION
# Local helper function to execute a sql command and return the output as a string array
#.OUTPUTS
# []System.String. Output of SQL command
function RunSqlCommandWithOutput([string]$Server, [string]$Command, [int] $CommandTimeout = 0)
{
    $Options = @{}
    if ($CommandTimeout)
    {
        $Options["QueryTimeout"] = $CommandTimeout
    }

    Write-Host "Executing SQL query ($Server): ""$Command""" -Debug
    Invoke-Sqlcmd -Query $Command @Options
}

<#
.SYNOPSIS
Checks existance of database
.DESCRIPTION
Checks if the specified database exists on the SQL server
.OUTPUTS
Returns $true if database exists otherwise $false
#>
function Test-NavDatabase(# Name of the database to check
    [Parameter(Mandatory = $true)]
    [string]$DatabaseName,
    # Hostname of SQL server
    [string]$DatabaseServer = '.'
)
{
    $sqlCommandText = @"
        USE MASTER
        SELECT '1' FROM SYS.DATABASES WHERE NAME = '$DatabaseName'
        GO
"@

    return ((RunSqlCommandWithOutput -Server $DatabaseServer -Command $sqlCommandText) -ne $null)
}

function Set-ExtensionVersion([string]$Name, [string]$DatabaseName, [string]$Major, [string]$Minor, [string]$Publisher = 'Microsoft', [string]$TenantId = 'default', [string]$DatabaseServer = '.')
{
    if (!$Major)
    {
        throw "The `$env:BUILDVERSION is 0. Check if the environment has been configured correctly."
    }

    Write-Host "Set version $Major.$Minor.0.0 for extension $Name published by $Publisher."

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
    

    RunSqlCommandWithOutput -Command $command -Server $DatabaseServer
}

<#
.SYNOPSIS
Move the extension identified by the given name and publisher from the global scope to the tenant scope

.PARAMETER Name
The extension's name, as defined in the extension's manifest.

.PARAMETER DatabaseName
The database on which to execute the query.

.PARAMETER Publisher
The extension's publisher, as defined in the extension's manifest.

.PARAMETER TenantId
The tenant in whose scope the extension should be moved.

.PARAMETER DatabaseServer
The database server on which to run the query.

#>
function Move-ExtensionIntoDevScope([string]$Name, [string]$DatabaseName, [string]$Publisher = 'Microsoft', [string]$TenantId = 'default', [string]$DatabaseServer = '.')
{
    Write-Host "Move extension $Name published by $Publisher to the DEV scope."

    if (!$TenantId)
    {
        $TenantId = 'default' 
    }

    $command = @"
    UPDATE [$DatabaseName].[dbo].[Published Application]
    SET [Published As] = 2, [Tenant ID] = '$TenantId'
"@
    RunSqlCommandWithOutput -Command $command -Server $DatabaseServer
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

        if (-not(Test-NavDatabase -DatabaseName $DatabaseName)) {
            throw "Database $DatabaseName does not exist"
        }

        $installedApps = @(Get-NAVAppInfo -ServerInstance $server.ServerInstance)

        Write-Host "Stopping server instance $($server.ServerInstance)" -ForegroundColor Green
        Stop-NAVServerInstance -ServerInstance $server.ServerInstance

        try {
            $installedApps | ForEach-Object {
                if ($_.Scope -eq 'Global') {
                    Write-Host "Moving $($_.Name) to Dev Scope"
                    Move-ExtensionIntoDevScope -Name ($_.Name) -DatabaseName $DatabaseName
                }
                if ($_.Version -ne "$($RepoVersion.Major).$($RepoVersion.Minor).0.0") {
                    Set-ExtensionVersion -Name ($_.Name) -DatabaseName $DatabaseName -Major $RepoVersion.Major -Minor $RepoVersion.Minor
                }
            }
        } finally {
            Write-Host "Starting server instance $($server.ServerInstance)" -ForegroundColor Green
            Start-NAVServerInstance -ServerInstance $server.ServerInstance
        }

        
    } -argumentList $NewDevContainerModule,$RepoVersion -usePwsh $false
}

Export-ModuleMember -Function *-*