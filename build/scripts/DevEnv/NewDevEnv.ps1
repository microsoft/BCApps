using module .\AppProjectInfo.class.psm1
using module .\ALGoProjectInfo.class.psm1

<#
Creates a new dev env.
#>
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingPlainTextForPassword', '', Justification = 'local build')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '', Justification = 'local build')]
[CmdletBinding(DefaultParameterSetName = 'ProjectPaths')]
param(
    [Parameter(Mandatory = $false)]
    [string] $containerName = "BC-$(Get-Date -Format 'yyyyMMdd')",

    [Parameter(Mandatory = $false)]
    [string] $userName = 'admin',

    [Parameter(Mandatory = $false)]
    [string] $password = 'P@ssword1',

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

if (-not (Get-Module -ListAvailable -Name "BCContainerHelper")) {
    Write-Host "BCContainerHelper module not found. Installing..."
    Install-Module -Name "BCContainerHelper" -Scope CurrentUser -AllowPrerelease -Force
}

Import-Module "BCContainerHelper" -DisableNameChecking
Import-Module "$PSScriptRoot\..\EnlistmentHelperFunctions.psm1" -DisableNameChecking
Import-Module "$PSScriptRoot\NewDevEnv.psm1" -DisableNameChecking -Force

function jobInit {
    param(
        $baseFolder
    )

    return [ScriptBlock]::Create("Set-Location $baseFolder")
}

[Scriptblock] $createContainerScriptblock = {
    param(

        [string] $containerName,
        [pscredential] $credential,
        [string] $baseFolder
    )
    Import-Module "BCContainerHelper" -DisableNameChecking

    $bcArtifactUrl = Get-ConfigValue -Key "artifact" -ConfigType AL-Go

    $newContainerParams = @{
        "accept_eula" = $true
        "accept_insiderEula" = $true
        "containerName" = "$containerName"
        "artifactUrl" = $bcArtifactUrl
        "Credential" = $credential
        "auth" = "UserPassword"
        "additionalParameters" = @("--volume ""$($baseFolder):c:\sources""")
    }

    $newBCContainerScript = Join-Path $baseFolder "build\scripts\NewBcContainer.ps1" -Resolve
    . $newBCContainerScript -parameters $newContainerParams
}

$baseFolder = Get-BaseFolder
$credential = New-Object System.Management.Automation.PSCredential ($userName, $(ConvertTo-SecureString $password -AsPlainText -Force))

$createContainerJob = $null
if(-not (CheckContainerExists -containerName $containerName)) {
    $createContainerJob = Start-Job -InitializationScript $(jobInit -workinDirectory $baseFolder) -ScriptBlock $createContainerScriptblock -ArgumentList $containerName, $credential, $baseFolder | Get-Job
    Write-Host "Creating container in the background. Job ID: $($createContainerJob.Id)" -ForegroundColor Yellow
}

$projectPaths = ResolveProjectPaths -projectPaths $projectPaths -workspacePath $workspacePath -alGoProject $alGoProject -baseFolder $baseFolder
Write-Host "Resolved project paths: $($projectPaths -join [Environment]::NewLine)"

Write-Host "Building apps..." -ForegroundColor Yellow
$appFiles = @()
$packageCacheFolder = GetRootedFolder -folder $packageCacheFolder -baseFolder $baseFolder
$buildingAppsStats = Measure-Command {
    $appFiles = @()

    Write-Host "Creating compiler folder..." -ForegroundColor Yellow
    $compilerFolder = CreateCompilerFolder -packageCacheFolder $packageCacheFolder
    Write-Host "Compiler folder: $compilerFolder"

    try {
        foreach($currentProjectPath in $projectPaths) {
            Write-Host "Building app in $currentProjectPath" -ForegroundColor Yellow
            $currentAppFiles = BuildApp -appProjectFolder $currentProjectPath -compilerFolder $compilerFolder -packageCacheFolder $packageCacheFolder -baseFolder $baseFolder
            $appFiles += @($currentAppFiles)
        }
    }
    catch {
        Write-Host "Error building apps: $_" -ForegroundColor Red
        throw $_
    }
    finally {
        Write-Host "Removing compiler folder $compilerFolder" -ForegroundColor Yellow
        Remove-Item -Path $compilerFolder -Recurse -Force | Out-Null
    }

    $appFiles = $appFiles | Select-Object -Unique
}

Write-Host "Apps: $appFiles"
Write-Host "Building apps took $($buildingAppsStats.TotalSeconds) seconds"

try {
    if($createContainerJob) {
        'Waiting for container creation to finish...'
        Wait-Job -Job $createContainerJob -Timeout 1 -ErrorAction SilentlyContinue
        Receive-Job -Job $createContainerJob -Wait
    }

    Write-Host "Container $containerName created"
    Write-Host "Credential: $credential"
    Write-Host "Apps: $appFiles"
}
finally {
    if($createContainerJob) {
        Write-Host "Removing container creation job $($createContainerJob.Id)"
        Remove-Job -Job $createContainerJob -Force -ErrorAction SilentlyContinue
    }
}

Write-Host "Publishing apps..." -ForegroundColor Yellow
$publishingAppsStats = Measure-Command {
    foreach($currentAppFile in $appFiles) {
        Write-Host "Publishing $currentAppFile"
        Publish-BcContainerApp -containerName $containerName -appFile $currentAppFile -syncMode ForceSync -sync -credential $credential -skipVerification -install -useDevEndpoint
    }
}

Write-Host "Publishing apps took $($publishingAppsStats.TotalSeconds) seconds"

