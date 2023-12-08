using module .\AppProjectInfo.class.psm1
using module .\ALGoProjectInfo.class.psm1

<#
Creates a new dev env.
#>
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingPlainTextForPassword', '', Justification = 'local build')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '', Justification = 'local build')]
param(
    [Parameter(Mandatory = $false)]
    [string] $containerName = "BC-$(Get-Date -Format 'yyyyMMdd')",

    [Parameter(Mandatory = $false)]
    [string] $userName = 'admin',

    [Parameter(Mandatory = $false)]
    [string] $password = 'P@ssword1',

    [Parameter(Mandatory = $true)]
    [string[]] $projectPaths,

    [Parameter(Mandatory = $false)]
    [string] $packageCacheFolder = ".artifactsCache"
)

function InstallBCContainerHelper {
    if (-not (Get-Module -ListAvailable -Name "BCContainerHelper")) {
        Write-Host "BCContainerHelper module not found. Installing..."
        Install-Module -Name "BCContainerHelper" -Scope CurrentUser -AllowPrerelease -Force
    }

    Import-Module "BCContainerHelper"
}

function CreateBCContainer {
    param(
        [Parameter(Mandatory = $true)]
        [string] $containerName
    )

    $containerExist = $null -ne $(docker ps -q -f name="$containerName")

    if ($containerExist) {
        Write-Host "Container $containerName already exists."
        return
    }

    Write-Host "Creating container $containerName"

    $bcArtifactUrl = Get-ConfigValue -Key "artifact" -ConfigType AL-Go

    $newContainerParams = @{
        "accept_eula" = $true
        "accept_insiderEula" = $true
        "containerName" = "BC-$(Get-Date -Format 'yyyyMMdd')"
        "artifactUrl" = $bcArtifactUrl
        "Credential" = $script:credential
        "auth" = "UserPassword"
        "additionalParameters" = @("--volume ""$($script:baseFolder):c:\sources""")
    }

    $newBCContainerScript = Join-Path $script:baseFolder "build\scripts\NewBcContainer.ps1" -Resolve
    . $newBCContainerScript -parameters $newContainerParams
}

function CreateCompilerFolder {
    param(
        [Parameter(Mandatory = $true)]
        [string] $packageCacheFolder
    )
    $bcArtifactUrl = Get-ConfigValue -Key "artifact" -ConfigType AL-Go

    if(-not (Test-Path -Path $packageCacheFolder)) {
        Write-Host "Creating package cache folder $packageCacheFolder"
        New-Item -Path $packageCacheFolder -ItemType Directory | Out-Null
    }

    return New-BcCompilerFolder -artifactUrl $bcArtifactUrl -cacheFolder $packageCacheFolder
}

function GetAllApps {
    if($script:apps) {
        return $script:apps
    }

    # Get all AL-Go projects
    $alGoProjects = [ALGoProjectInfo]::FindAll($script:baseFolder)

    $appInfos = @()

    foreach($alGoProject in $alGoProjects) {
        $appFolders = $alGoProject.GetAppFolders($true)

        foreach($appFolder in $appFolders) {
            $appInfo = [AppProjectInfo]::Get($appFolder, 'app')
            $appInfos += $appInfo
        }

        $testAppFolders = $alGoProject.GetAppFolders($true)

        foreach($testAppFolder in $testAppFolders) {
            $testAppInfo = [AppProjectInfo]::Get($testAppFolder, 'test')
            $appInfos += $testAppInfo
        }
    }

    $script:apps = $appInfos
    return $script:apps
}

function ResolveFolder {
    param(
        [Parameter(Mandatory = $true)]
        [string] $folder
    )

    if([System.IO.Path]::IsPathRooted($folder)) {
        return $folder
    }

    return Join-Path $script:baseFolder $folder
}

function BuildApp {
    param(
        [Parameter(Mandatory = $true)]
        [string] $appProjectFolder,

        [Parameter(Mandatory = $true)]
        [string] $packageCacheFolder
    )

    $appProjectFolder = ResolveFolder -folder $appProjectFolder

    $appInfo = [AppProjectInfo]::Get($appProjectFolder)
    $appFile = $appInfo.GetAppFileName()

    if(Test-Path (Join-Path $packageCacheFolder $appFile)) {
        Write-Host "App $appFile already exists in $packageCacheFolder. Skipping..."
        return
    }

    $allAppInfos = GetAllApps

    # Build dependencies
    foreach($dependency in $appInfo.AppJson.dependencies) {
        $dependencyAppInfo = $allAppInfos | Where-Object { $_.Id -eq $dependency.id }
        BuildApp -appProjectFolder $dependencyAppInfo.AppProjectFolder -packageCacheFolder $packageCacheFolder | Out-Null
    }

    $compilerFolder = CreateCompilerFolder -packageCacheFolder $packageCacheFolder

    try {
        $appFile = Compile-AppWithBcCompilerFolder -compilerFolder $compilerFolder -appProjectFolder "$($appInfo.AppProjectFolder)" -appOutputFolder $packageCacheFolder -CopyAppToSymbolsFolder -appSymbolsFolder $packageCacheFolder
    }
    finally {
        Remove-Item -Path $compilerFolder -Recurse -Force | Out-Null
    }

    return $appFile
}

function PublishApp {
    param(
        [Parameter(Mandatory = $true)]
        [string] $appFile,

        [Parameter(Mandatory = $true)]
        [string] $containerName
    )

    Publish-BcContainerApp -containerName $containerName -appFile $appFile -syncMode ForceSync -credential $script:credential -skipVerification -install
}

$errorActionPreference = "Stop"; $ProgressPreference = "SilentlyContinue"; Set-StrictMode -Version 2.0
Import-Module "$PSScriptRoot\..\EnlistmentHelperFunctions.psm1"

$script:apps = @()
[pscredential] $script:credential = New-Object System.Management.Automation.PSCredential ($userName, $(ConvertTo-SecureString $password -AsPlainText -Force))
$script:baseFolder = Get-BaseFolder
$script:packageCacheFolder = ResolveFolder -folder $packageCacheFolder

Write-Host "Loading BCContainerHelper module"
InstallBCContainerHelper

Write-Host "Creating container $containerName"
CreateBCContainer -containerName $containerName

foreach($currentProjectPath in $projectPaths) {
    Write-Host "Building app in $currentProjectPath"
    $appFile = BuildApp -appProjectFolder $currentProjectPath -packageCacheFolder $script:packageCacheFolder

    Write-Host "Publishing app $appFile to $containerName"
    PublishApp -appFile $appFile -containerName $containerName
}
