<#
    .SYNOPSIS
    Creates a new development environment with a new container, sets up vscode for development against the container, and optionally builds and publishes apps.
    .DESCRIPTION
    This script creates a new development environment with a new container, sets up vscode for development against the container, and optionally builds and publishes apps.
    .PARAMETER ContainerName
    The name of the container to create. The default value is "BC-$(Get-Date -Format 'yyyyMMdd')".
    .PARAMETER Authentication
    The authentication type to use when creating the container. The default value is "UserPassword".
    .PARAMETER SkipVsCodeSetup
    If specified, vscode will not be set up for development against the container.
    .PARAMETER ProjectPaths
    The paths to the AL projects to build and publish. This parameter is mutually exclusive with the WorkspacePath and AlGoProject parameters.
    .PARAMETER WorkspacePath
    The path to the workspace containing the AL projects to build and publish. This parameter is mutually exclusive with the ProjectPaths and AlGoProject parameters.
    .PARAMETER AlGoProject
    The name of the AL-Go project to build and publish. This parameter is mutually exclusive with the ProjectPaths and WorkspacePath parameters.
    .PARAMETER RebuildApps
    If specified, the apps will be force rebuilt before publishing even if they exist.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string] $ContainerName = "BC-$(Get-Date -Format 'yyyyMMdd')",
    [Parameter(Mandatory = $false)]
    [ValidateSet('UserPassword')]
    [string] $Authentication = "UserPassword",
    [Parameter(Mandatory = $false)]
    [switch] $SkipVsCodeSetup,
    [Parameter(Mandatory = $false)]
    [string[]] $ProjectPaths,
    [Parameter(Mandatory = $false)]
    [string] $WorkspacePath,
    [Parameter(Mandatory = $false)]
    [string] $AlGoProject,
    [Parameter(Mandatory = $false)]
    [switch] $RebuildApps
)

Import-Module "$PSScriptRoot\..\EnlistmentHelperFunctions.psm1" -DisableNameChecking
Import-Module "$PSScriptRoot\ALDev.psm1" -DisableNameChecking
Import-Module "$PSScriptRoot\NewDevEnv.psm1" -DisableNameChecking
Import-Module BcContainerHelper

$baseFolder = (Get-BaseFolderForPath -Path $PSScriptRoot)
Push-Location $baseFolder

try {
    $credential = Get-CredentialForContainer -AuthenticationType $Authentication

    # Create the container if it does not exist already
    $ContainerExists = Test-ContainerExists -ContainerName $ContainerName
    if (-not $ContainerExists)
    {
        Write-Host "Creating container $ContainerName..." -ForegroundColor Yellow
        $createContainerJob = Create-BCContainer -ContainerName $ContainerName -Authentication $Authentication -Credential $credential -backgroundJob
    }

    # Build the apps
    if ($ProjectPaths -or $WorkspacePath -or $AlGoProject)
    {
        # Resolve AL project paths
        $ProjectPaths = Resolve-ProjectPaths -ProjectPaths $ProjectPaths -WorkspacePath $WorkspacePath -AlGoProject $AlGoProject

        # Build apps
        Write-Host "Building apps..." -ForegroundColor Yellow
        $buildAppFiles = Build-Apps -ProjectPaths $ProjectPaths -packageCacheFolder (Get-ArtifactsCacheFolder -ContainerName $ContainerName) -rebuild:$RebuildApps
    }

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

    # Publish apps
    if ($buildAppFiles) {
        Write-Host "Publishing apps..." -ForegroundColor Yellow
        $appPublishingResults = Publish-Apps -ContainerName $ContainerName -AppFiles $buildAppFiles -Credential $credential
    }

    # Set up vscode for development against the container (i.e. set up launch.json and settings.json)
    if (-not $SkipVsCodeSetup)
    {
        Write-Host "Configuring vscode for development against the container..."
        Configure-ALProjectsInPath -ContainerName $ContainerName -Authentication $Authentication
        Install-ALExtension -ContainerName $ContainerName
    }
}
finally {
    Pop-Location

    # Output results
    if ($createContainerJob) {
        if ($createContainerJob.State -eq 'Failed') {
            Write-Host "Container $ContainerName failed to be created." -ForegroundColor Red
        } else {
            Write-Host "Container $ContainerName created successfully. You can access the webclient by going to http://$ContainerName/BC/ in your browser" -ForegroundColor Green
        }
    } else {
        Write-Host "Skipped creating container as it already exists. You can access the webclient by going to http://$ContainerName/BC/ in your browser" -ForegroundColor Yellow
    }

    if ($buildAppFiles) {
        # Output the app files that were built. One per line
        Write-Host "Apps built successfully:" -ForegroundColor Green
        $buildAppFiles | ForEach-Object { Write-Host $_ -ForegroundColor Green }
    } else {
        Write-Host "Skipped building apps." -ForegroundColor Yellow
    }

    if ($appPublishingResults) {
        # Output the app files that were published. One per line
        if ($appPublishingResults | Where-Object { $_.Success }) {
            Write-Host "Apps published successfully:" -ForegroundColor Green
            $appPublishingResults | Where-Object { $_.Success } | ForEach-Object { Write-Host $_.AppFile -ForegroundColor Green }
        }

        if ($appPublishingResults | Where-Object { -not $_.Success }) {
            Write-Host "Apps failed to publish:" -ForegroundColor Red
            $appPublishingResults | Where-Object { -not $_.Success } | ForEach-Object { Write-Host $_.AppFile -ForegroundColor Red }
        }
    } else {
        Write-Host "Skipped publishing apps." -ForegroundColor Yellow
    }
}