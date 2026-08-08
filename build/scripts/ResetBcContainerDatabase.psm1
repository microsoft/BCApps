<#
.SYNOPSIS
    Resets a multitenant Business Central container's application database to an empty state
    in a single bulk operation.

.DESCRIPTION
    Drops and recreates the application database, which removes every published app at once, and
    rebuilds the minimum required to hand the container to AL-Go for publishing the repository apps:
      - re-imports the developer license,
      - re-publishes the System Application (needed for the SUPER permission set),
      - creates a SUPER user,
      - restores multitenancy with a fresh, empty 'default' tenant.

    This replaces the previous approach of uninstalling ~150 pre-installed apps one by one. That
    loop cost ~19 minutes per job because every host-side UnInstall/Unpublish call is a separate
    in-container session (~8 s of overhead each), regardless of whether it also cleans schema.
    Dropping the application database removes all apps in one operation instead (~4 minutes).

.PARAMETER ContainerName
    Name of the multitenant BC container to reset.

.PARAMETER Credential
    Credential used to create the SUPER user in the rebuilt database.

.PARAMETER LicenseFile
    Path to the developer license (.bclicense) to import into the rebuilt application database.
    Recreating the database drops the license that was imported when the container was created.

.NOTES
    Only supports multitenant containers. The System Application is re-published from the container's
    own currently-published copy, so this does not depend on the System Application being present on
    disk (BCApps overrides the platform artifact, which strips it from C:\Applications).
#>
function Reset-BcContainerApplicationDatabase {
    param(
        [Parameter(Mandatory)] [string] $ContainerName,
        [Parameter(Mandatory)] [pscredential] $Credential,
        [Parameter(Mandatory)] [string] $LicenseFile
    )

    $customConfig = Get-BcContainerServerConfiguration -ContainerName $ContainerName
    if ($customConfig.Multitenant -ne 'True') {
        throw "Reset-BcContainerApplicationDatabase only supports multitenant containers."
    }

    # The System Application provides the SUPER permission set (BCApps runs with
    # UsePermissionSetsFromExtensions=true), without which no usable admin user can be created.
    # Extract it from the container's currently-published copy BEFORE dropping the database - this
    # is the only source that survives BCApps' platform override.
    $sysAppInfo = Get-BcContainerAppInfo -containerName $ContainerName | Where-Object { $_.Name -eq 'System Application' } | Select-Object -First 1
    if (-not $sysAppInfo) { throw "System Application is not published in container '$ContainerName'; cannot reset." }
    $sysAppFile = Join-Path ([System.IO.Path]::GetTempPath()) "sysapp_$ContainerName.app"
    if (Test-Path $sysAppFile) { Remove-Item $sysAppFile -Force }
    Get-BcContainerApp -containerName $ContainerName -appName $sysAppInfo.Name -publisher $sysAppInfo.Publisher -appVersion $sysAppInfo.Version -appFile $sysAppFile -credential $Credential
    if (-not (Test-Path $sysAppFile)) { throw "Failed to extract System Application from container '$ContainerName'." }
    Write-Host "Extracted System Application to '$sysAppFile'"

    # Bulk database rebuild in a single in-container session.
    Invoke-ScriptInBcContainer -containerName $ContainerName -useSession $false -usePwsh $false -scriptblock {
        Param($databaseName, $databaseServer, $databaseInstance)

        $databaseServerInstance = $databaseServer
        if ($databaseInstance) { $databaseServerInstance += "\$databaseInstance" }

        Write-Host "Stopping service tier"
        Set-NavServerInstance -ServerInstance $ServerInstance -stop

        # Preserve applicationfamily (used by the platform); the recreated database must keep it.
        $dbproperties = Invoke-Sqlcmd -ServerInstance $databaseServerInstance -Query "SELECT [applicationfamily] FROM [$databaseName].[dbo].[`$ndo`$dbproperty]"

        Write-Host "Dropping application database '$databaseName' and tenant databases"
        Remove-NavDatabase -databasename $databaseName -databaseserver $databaseServer -databaseInstance $databaseInstance

        # Rebuild as a single-tenant database named 'tenant'; switch back to multitenant afterwards.
        Set-NavServerConfiguration -ServerInstance $ServerInstance -KeyName "Multitenant" -KeyValue "False" -WarningAction SilentlyContinue
        Set-NavServerConfiguration -ServerInstance $ServerInstance -KeyName "DatabaseName" -KeyValue "tenant" -WarningAction SilentlyContinue
        Remove-NavDatabase -databasename "tenant" -databaseserver $databaseServer -databaseInstance $databaseInstance
        Remove-NavDatabase -databasename "default" -databaseserver $databaseServer -databaseInstance $databaseInstance

        Write-Host "Creating new empty application database 'tenant'"
        New-NAVApplicationDatabase -DatabaseServer $databaseServerInstance -DatabaseName "tenant" | Out-Null
        Invoke-Sqlcmd -ServerInstance $databaseServerInstance -Query "UPDATE [tenant].[dbo].[`$ndo`$dbproperty] SET [applicationfamily] = '$($dbproperties.applicationfamily)'"

        Write-Host "Starting service tier"
        Set-NavServerInstance -ServerInstance $ServerInstance -start
        Sync-NavTenant -ServerInstance $ServerInstance -Force

    } -argumentList $customConfig.DatabaseName, $customConfig.DatabaseServer, $customConfig.DatabaseInstance

    Write-Host "Re-importing license"
    Import-BcContainerLicense -containerName $ContainerName -licenseFile $LicenseFile

    Write-Host "Publishing System Application"
    Publish-BcContainerApp -containerName $ContainerName -appFile $sysAppFile -skipVerification -sync -install

    Write-Host "Creating SUPER user"
    New-BcContainerBcUser -containerName $ContainerName -Credential $Credential -PermissionSetId SUPER -ChangePasswordAtNextLogOn:$false

    # Switch back to multitenant: split the application from the tenant, copy to a fresh 'default' tenant.
    # -usePwsh $false forces Windows PowerShell 5.1: this block calls Invoke-Sqlcmd and SMO-based
    # Export-/Copy-NavDatabase, which fail to load the SQL SMO assemblies under the container's pwsh7.
    Invoke-ScriptInBcContainer -containerName $ContainerName -useSession $false -usePwsh $false -scriptblock { Param($databaseName, $databaseServer, $databaseInstance)
        $databaseServerInstance = $databaseServer
        if ($databaseInstance) { $databaseServerInstance += "\$databaseInstance" }

        Write-Host "Switching to multitenancy"
        Set-NavServerInstance -ServerInstance $ServerInstance -stop
        Set-NavServerConfiguration -ServerInstance $ServerInstance -KeyName "DatabaseName" -KeyValue "$databaseName" -WarningAction SilentlyContinue
        Invoke-sqlcmd -serverinstance $databaseServerInstance -Database "tenant" -query 'CREATE USER "NT AUTHORITY\SYSTEM" FOR LOGIN "NT AUTHORITY\SYSTEM";'
        Export-NAVApplication -DatabaseServer $databaseServer -DatabaseInstance $databaseInstance -DatabaseName "tenant" -DestinationDatabaseName $databaseName -Force -ServiceAccount 'NT AUTHORITY\SYSTEM' | Out-Null
        Write-Host "Removing application from tenant template"
        Remove-NAVApplication -DatabaseServer $databaseServer -DatabaseInstance $databaseInstance -DatabaseName "tenant" -Force | Out-Null
        Set-NavServerConfiguration -ServerInstance $ServerInstance -KeyName "Multitenant" -KeyValue "True" -WarningAction SilentlyContinue
        Set-NavServerInstance -ServerInstance $ServerInstance -start
        Write-Host "Copying tenant template to default tenant"
        Copy-NavDatabase -SourceDatabaseName "tenant" -DestinationDatabaseName "default"
        Write-Host "Mounting default tenant"
        # -allowAppDatabaseWrite is required so demo-data generation (DemoTool) can insert records such
        # as Media into the application database; without it the tenant mounts read-only against the app DB.
        Mount-NavDatabase -ServerInstance $ServerInstance -TenantId "default" -DatabaseName "default" -allowAppDatabaseWrite
    } -argumentList $customConfig.DatabaseName, $customConfig.DatabaseServer, $customConfig.DatabaseInstance
}

Export-ModuleMember -Function Reset-BcContainerApplicationDatabase
