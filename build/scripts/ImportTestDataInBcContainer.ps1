Param(
    [Hashtable]$parameters
)

Import-Module $PSScriptRoot\AppExtensionsHelper.psm1
Import-Module $PSScriptRoot\EnlistmentHelperFunctions.psm1

function Invoke-ContosoDemoTool() {
    param(
        [string]$ContainerName,
        [string]$CompanyName = (Get-TestCompanyName),
        [switch]$SetupData
    )
    Write-Host "Initializing company in container $ContainerName"
    Invoke-NavContainerCodeunit -Codeunitid 2 -containerName $ContainerName -CompanyName $CompanyName

    if ($SetupData) {
        Write-Host "Generating Setup Demo Data in container $ContainerName"
        Invoke-NavContainerCodeunit -Codeunitid 5193 -containerName $ContainerName -CompanyName $CompanyName -MethodName "CreateSetupDemoData"
    } else {
        Write-Host "Generating All Demo Data in container $ContainerName"
        Invoke-NavContainerCodeunit -CodeunitId 5193 -containerName $containerName -CompanyName $CompanyName -MethodName "CreateAllDemoData"
        Invoke-NavContainerCodeunit -CodeunitId 5140 -containerName $containerName -CompanyName $CompanyName -MethodName "DeleteWarehouseEmployee"
    }

    Invoke-NavContainerCodeunit -CodeunitId 5691 -containerName $ContainerName -CompanyName $CompanyName
}

function Invoke-LegacyDemoDataTool() {
    param(
        [string]$ContainerName,
        [string]$CompanyName = (Get-TestCompanyName)
    )
    # Get the repoversion
    $repoVersion = Get-ConfigValue -ConfigType "AL-GO" -Key "RepoVersion"
    $DemoDataType = "EXTENDED"

    # Allow access to configuration packages
    Set-BcContainerServerConfiguration -ContainerName $ContainerName -keyName EnforceUserPathForAlFileOperations -keyValue $false
    Restart-BcContainerServiceTier -ContainerName $ContainerName
    Start-Sleep -Seconds 10

    Write-Host "Initializing company"
    Invoke-NavContainerCodeunit -Codeunitid 2 -containerName $ContainerName -CompanyName $CompanyName

    Write-Host "Importing configuration package"
    # TODO: For now we get the demo data from the configuration package. Later we need to generate this via the demo data tool
    Invoke-NavContainerCodeunit -Codeunitid 8620 -containerName $ContainerName -CompanyName $CompanyName -MethodName "ImportAndApplyRapidStartPackage" -Argument "C:\ConfigurationPackages\NAV$($repoVersion).W1.ENU.$($DemoDataType).rapidstart"
}

function Get-TestCompanyName() {
    $companyName = Get-ALGoSetting -Key "companyName"
    if ([string]::IsNullOrEmpty($companyName)) {
        return "CRONUS International Ltd." # Fallback in case no company name is specified in settings
    } else {
        return $companyName
    }
}

function Invoke-DemoDataGeneration
{
    param(
        [Parameter(Mandatory=$true)]
        [string]$ContainerName,
        [Parameter(Mandatory=$true)]
        [ValidateSet("UnitTest","IntegrationTest","Uncategorized","Legacy")]
        [string]$TestType
    )
    if ($TestType -eq "UnitTest") {
        New-TestCompany -ContainerName $ContainerName -CompanyName (Get-TestCompanyName)
        Write-Host "UnitTest shouldn't have dependency on any Demo Data, skipping demo data generation"
        return
    } elseif( $TestType -eq "IntegrationTest" ) {
        New-TestCompany -ContainerName $ContainerName -CompanyName (Get-TestCompanyName)
        Write-Host "Proceeding with demo data generation (SetupData) as test type is set to IntegrationTest"
        Invoke-ContosoDemoTool -ContainerName $ContainerName -SetupData
    } elseif( $TestType -eq "Uncategorized" ) {
        New-TestCompany -ContainerName $ContainerName -CompanyName (Get-TestCompanyName) -EvaluationCompany
        Write-Host "Proceeding with full demo data generation as test type is set to Uncategorized"
        Invoke-ContosoDemoTool -ContainerName $ContainerName
    } elseif ( $TestType -eq "Legacy" ) {
        New-TestCompany -ContainerName $ContainerName -CompanyName (Get-TestCompanyName)
        Write-Host "Proceeding with full demo data generation as test type is set to Legacy"
        Invoke-LegacyDemoDataTool -ContainerName $ContainerName
    }
    else {
        throw "Unknown test type $TestType."
    }

}

function New-TestCompany() {
    param(
        [Parameter(Mandatory=$true)]
        [string]$ContainerName,
        [Parameter(Mandatory=$true)]
        [string]$CompanyName,
        [Parameter(Mandatory=$false)]
        [switch]$EvaluationCompany
    )

    # Delete existing companies in the container
    $existingCompanies = Get-CompanyInBcContainer -containerName $ContainerName
    foreach ($company in $existingCompanies) {
        Write-Host "Deleting company $($company.CompanyName) in container $ContainerName"
        Remove-CompanyInBcContainer -containerName $ContainerName -companyName $company.CompanyName
    }

    Write-Host "Creating new test company in container $ContainerName"
    New-CompanyInBcContainer -containerName $ContainerName -companyName $CompanyName -evaluationCompany:$EvaluationCompany
}

# Log all the installed apps
foreach ($app in (Get-BcContainerAppInfo -containerName $ContainerName -tenantSpecificProperties -sort DependenciesLast)) {
    Write-Host "App: $($app.Name) ($($app.Version)) - Scope: $($app.Scope) - $($app.IsInstalled) / $($app.IsPublished)"
}

try {
    Invoke-DemoDataGeneration -ContainerName $parameters.ContainerName -TestType (Get-ALGoSetting -Key "testType")
} catch {
    Write-Host "An error occurred during demo data generation: $($_.Exception.Message)"
    Write-Host "Trying again..."
    Invoke-DemoDataGeneration -ContainerName $parameters.ContainerName -TestType (Get-ALGoSetting -Key "testType")
}