using module .\AppProjectInfo.class.psm1
using module .\ALGoProjectInfo.class.psm1

<#
    .Synopsis
        Creates a docker-based development environment for AL apps.
    .Parameter containerName
        The name of the container to use. The container will be created if it does not exist.
    .Parameter userName
        The user name to use for the container.
    .Parameter password
        The password to use for the container.
    .Parameter projectPaths
        The paths of the AL projects to build. May contain wildcards.
    .Parameter workspacePath
        The path of the workspace to build. The workspace file must be in JSON format.
    .Parameter alGoProject
        The path of the AL-Go project to build.
    .Parameter packageCacheFolder
        The folder to store the built artifacts.
#>
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingPlainTextForPassword', '', Justification = 'local build')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '', Justification = 'local build')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'packageCacheFolder', Justification = 'false-postiive, used in Measure-Command')]
[CmdletBinding(DefaultParameterSetName = 'ProjectPaths')]
param(
    [Parameter(Mandatory = $false)]
    [string] $containerName = "BC-$(Get-Date -Format 'yyyyMMdd')",

    [Parameter(Mandatory = $false)]
    [string] $userName = 'admin',

    [Parameter(Mandatory = $true)]
    [string] $password,

    [Parameter(Mandatory = $true, ParameterSetName = 'ProjectPaths')]
    [string[]] $projectPaths,

    [Parameter(Mandatory = $true, ParameterSetName = 'WorkspacePath')]
    [string] $workspacePath,

    [Parameter(Mandatory = $true, ParameterSetName = 'ALGoProject')]
    [string] $alGoProject,

    [Parameter(Mandatory = $false)]
    [string] $packageCacheFolder = ".artifactsCache"
)

$errorActionPreference = "Stop"; $ProgressPreference = "SilentlyContinue"; Set-StrictMode -Version 2.0

# Install BCContainerHelper module if not already installed
if (-not (Get-Module -ListAvailable -Name "BCContainerHelper")) {
    Write-Host "BCContainerHelper module not found. Installing..."
    Install-Module -Name "BCContainerHelper" -Scope CurrentUser -AllowPrerelease -Force
}

Import-Module "BCContainerHelper" -DisableNameChecking
Import-Module "$PSScriptRoot\..\EnlistmentHelperFunctions.psm1" -DisableNameChecking
Import-Module "$PSScriptRoot\NewDevEnv.psm1" -DisableNameChecking

$baseFolder = Get-BaseFolder

# Create BC container
$credential = New-Object System.Management.Automation.PSCredential ($userName, $(ConvertTo-SecureString $password -AsPlainText -Force))
$createContainerJob = Create-BCContainer -containerName $containerName -credential $credential -backgroundJob

# Resolve AL project paths
$projectPaths = Resolve-ProjectPaths -projectPaths $projectPaths -workspacePath $workspacePath -alGoProject $alGoProject -baseFolder $baseFolder
Write-Host "Resolved project paths: $($projectPaths -join [Environment]::NewLine)"

# Build apps
$appFiles = @()
$buildingAppsStats = Measure-Command {
    Write-Host "Building apps..." -ForegroundColor Yellow
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '', Justification = 'false-postiive')]
    $appFiles = Build-Apps -projectPaths $projectPaths -packageCacheFolder $packageCacheFolder
}

Write-Host "Building apps took $($buildingAppsStats.TotalSeconds) seconds"
Write-Host "App files: $($appFiles -join [Environment]::NewLine)" -ForegroundColor Green

# Wait for container creation to finish
if($createContainerJob) {
    Write-Host 'Waiting for container creation to finish...' -ForegroundColor Yellow
    Wait-Job -Job $createContainerJob -Timeout 1
    Receive-Job -Job $createContainerJob -Wait -AutoRemoveJob

    if($createContainerJob.State -eq 'Failed'){
        Write-Output "Creating container failed:"
        throw $($createContainerJob.ChildJobs | ForEach-Object { $_.JobStateInfo.Reason.Message } | Out-String)
    }
}

if(Test-ContainerExists -containerName $containerName) {
    Write-Host "Container $containerName is available" -ForegroundColor Green
} else {
    throw "Container $containerName not available. Check if the container was created successfully and is running."
}


# Publish apps
Write-Host "Publishing apps..." -ForegroundColor Yellow
$publishingAppsStats = Measure-Command {
    foreach($currentAppFile in $appFiles) {
        Publish-BcContainerApp -containerName $containerName -appFile $currentAppFile -syncMode ForceSync -sync -credential $credential -skipVerification -install -useDevEndpoint -replacePackageId
    }
}

Write-Host "Publishing apps took $($publishingAppsStats.TotalSeconds) seconds"

