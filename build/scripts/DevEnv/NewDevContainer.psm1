#.DESCRIPTION
# Local helper function to execute a sql command and return the output as a string array
#.OUTPUTS
# []System.String. Output of SQL command
function RunSqlCommandWithOutput([string]$Server, [string]$Command, [int] $CommandTimeout = 0)
{
    # Wait for SQL Service Running
    <#$SQLService = Get-Service "MSSQLSERVER"

    if (!$SQLService)
    {
        throw "No MSSQLSERVER service found"
    }
    if ($SQLService.Status -notin 'Running', 'StartPending')
    {
        Write-Host "WARNING: SQL server is not running. Start MSSQLSERVER service"
        $SQLService.Start()
    }
    $SQLService.WaitForStatus('Running', '00:05:00')#>

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

function SetExtensionVersion([string]$Name, [string]$DatabaseName, [string]$Publisher = 'Microsoft', [string]$TenantId = 'default', [string]$DatabaseServer = '.')
{
    $Major = "25" #$env:BUILDVERSION;
    if (!$Major)
    {
        throw "The `$env:BUILDVERSION is 0. Check if the environment has been configured correctly."
    }
    $Minor = "0" #$env:BUILDVERSIONMINOR;

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

    SetExtensionVersion -Name $Name -DatabaseName $DatabaseName -Publisher $Publisher -TenantId $TenantId -DatabaseServer $DatabaseServer
}

function Get-AppFolders() {
    Import-Module "$PSScriptRoot\..\EnlistmentHelperFunctions.psm1" -DisableNameChecking
    $appFolders = Get-ChildItem (Get-BaseFolder) -Directory -Recurse | Where-Object { Test-Path (Join-Path $_.FullName app.json) } | ForEach-Object { return $_.FullName }
    return $appFolders
}

function Configure-ALProject(
    [Parameter(Mandatory = $true)]
    [string]$ProjectFolder,
    [Parameter(Mandatory = $true)]
    [string]$CountryCode,
    [hashtable]$LaunchSettings = @{ },
    [hashtable]$ProjectSettings = @{ }
)
{
    if (!(Test-Path (Join-Path $ProjectFolder "app.json")))
    {
        throw "Could not find an 'app.json' file in $ProjectFolder. Are you sure this is an AL project?"
    }

    $vsCodeFolder = Join-Path $ProjectFolder ".vscode"
    if (!(Test-Path $vsCodeFolder))
    {
        New-Item -ItemType Directory -Path $vsCodeFolder | Out-Null
    }

    SetupProjectSettings $vsCodeFolder -CountryCode $CountryCode -ProjectSettings $ProjectSettings -ResetConfiguration:$ResetConfiguration
    SetupLaunchSettings $vsCodeFolder -CountryCode $CountryCode -LaunchSettings $LaunchSettings -ResetConfiguration:$ResetConfiguration
}

Export-ModuleMember -Function *-*