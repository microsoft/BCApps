Param(
    [Hashtable]$parameters
)

Import-Module $PSScriptRoot\AppExtensionsHelper.psm1

function Invoke-ContosoDemoTool() {
    param(
        [string]$ContainerName,
        [string]$CompanyName = (Get-NavDefaultCompanyName),
        [switch]$SetupData = $false,
        [string]$DemodataApp = "Contoso Coffee Demo Dataset"
    )
    Install-AppsInContainer -ContainerName $ContainerName -Apps @($DemodataApp)
    
    Write-Host "Initializing company in container $ContainerName"
    Invoke-NavContainerCodeunit -Codeunitid 2 -containerName $ContainerName -CompanyName $CompanyName

    if ($SetupData) {
        Write-Host "Setting up demo data in container $ContainerName"
        Invoke-NavContainerCodeunit -Codeunitid 2 -containerName $ContainerName -CompanyName $CompanyName -MethodName "CreateSetupDemoData"
    } else {
        Write-Host "Importing configuration package"
        Invoke-NavContainerCodeunit -CodeunitId 5193 -containerName $containerName -CompanyName $CompanyName -MethodName "CreateAllDemoData"
        Invoke-NavContainerCodeunit -CodeunitId 5140 -containerName $containerName -CompanyName $CompanyName -MethodName "DeleteWarehouseEmployee"
    }

    Invoke-NavContainerCodeunit -CodeunitId 5691 -containerName $ContainerName -CompanyName $CompanyName
}

function Get-NavDefaultCompanyName
{
    return "CRONUS International Ltd."
}

Invoke-ContosoDemoTool -ContainerName $parameters.ContainerName