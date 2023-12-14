using module .\AppProjectInfo.class.psm1
using module .\ALGoProjectInfo.class.psm1

Import-Module "BCContainerHelper" -DisableNameChecking
Import-Module "$PSScriptRoot\..\EnlistmentHelperFunctions.psm1" -DisableNameChecking

$script:allApp = @()
function GetRootedFolder {
    param(
        [Parameter(Mandatory = $true)]
        [string] $folder,
        [Parameter(Mandatory = $true)]
        [string] $baseFolder
    )

    if(-not [System.IO.Path]::IsPathRooted($folder)) {
        $folder = Join-Path $baseFolder $folder
    }

    return $folder
}

function ResolveProjectPaths {
    param(
        [Parameter(Mandatory = $false)]
        [string[]] $projectPaths,

        [Parameter(Mandatory = $false)]
        [string] $workspacePath,

        [Parameter(Mandatory = $false)]
        [string] $alGoProject,

        [Parameter(Mandatory = $true)]
        [string] $baseFolder
    )

    $result = @()

    if($projectPaths) {
        foreach($projectPath in $projectPaths) {
            $projectPath = GetRootedFolder -folder $projectPath -baseFolder $baseFolder

            # Each project path can contain a wildcard
            $projectPath = Resolve-Path -Path $projectPath
            $result += @($projectPath | Where-Object { [AppProjectInfo]::IsAppProjectFolder($_.Path) } | Select-Object -ExpandProperty Path )
        }
    }

    if($workspacePath) {
        $workspacePath = GetRootedFolder -folder $workspacePath -baseFolder $baseFolder

        $workspace = Get-Content -Path $workspacePath -Raw | ConvertFrom-Json
        $workspaceParentPath = Split-Path -Path $workspacePath -Parent

        # Folders in the workspace are relative to the folder where the workspace file is located
        $result += @($workspace.folders | ForEach-Object { GetRootedFolder -folder $($_.path) -baseFolder $workspaceParentPath } | Where-Object { [AppProjectInfo]::IsAppProjectFolder($_) }) | ForEach-Object { Resolve-Path -Path $_ } | Select-Object -ExpandProperty Path
    }

    if($alGoProject) {
        $alGoProject = GetRootedFolder -folder $alGoProject -baseFolder $baseFolder
        $alGoProjectInfo = [ALGoProjectInfo]::Get($alGoProject)

        $result += @($alGoProjectInfo.GetAppFolders($true))
        $result += @($alGoProjectInfo.GetTestFolders($true))
    }

    return $result | Select-Object -Unique
}

function CheckContainerExists {
    param (
        $containerName
    )
    return ($null -ne $(docker ps -q -f name="$containerName"))
}

<#
    .Synopsis
    Builds an app.

    .Parameter appProjectFolder
    The folder of the app project.

    .Parameter compilerFolder
    The folder where the compiler is located.

    .Parameter packageCacheFolder
    The folder for the packagecache.

    .Parameter baseFolder
    The base folder where the AL-Go projects are located.
#>
function BuildApp {
    param(
        [Parameter(Mandatory = $true)]
        [string] $appProjectFolder,

        [Parameter(Mandatory = $true)]
        [string] $compilerFolder,

        [Parameter(Mandatory = $true)]
        [string] $packageCacheFolder,

        [Parameter(Mandatory = $true)]
        [string] $baseFolder
    )

    $appFiles = @()

    $appProjectFolder = GetRootedFolder -folder $appProjectFolder -baseFolder $baseFolder

    $appInfo = [AppProjectInfo]::Get($appProjectFolder)
    $appFile = $appInfo.GetAppFileName()

    $allAppInfos = GetAllApps -baseFolder $baseFolder

    # Build dependencies
    foreach($dependency in $appInfo.AppJson.dependencies) {
        Write-Host "Building dependency: $($dependency.id)" -ForegroundColor Yellow
        $dependencyAppInfo = $allAppInfos | Where-Object { $_.Id -eq $dependency.id }
        $dependencyAppFile = BuildApp -appProjectFolder $($dependencyAppInfo.AppProjectFolder) -compilerFolder $compilerFolder -packageCacheFolder $packageCacheFolder -baseFolder $baseFolder

        Write-Host "Adding dependency $dependencyAppFile to app files"
        $appFiles += @($dependencyAppFile)
    }

    if(Test-Path (Join-Path $packageCacheFolder $appFile)) {
        Write-Host "App $appFile already exists in $packageCacheFolder. Skipping..."
        $appFile = (Join-Path $packageCacheFolder $appFile -Resolve)
    } else {
        $appFile = Compile-AppWithBcCompilerFolder -compilerFolder $compilerFolder -appProjectFolder "$($appInfo.AppProjectFolder)" -appOutputFolder "$packageCacheFolder" -appSymbolsFolder $packageCacheFolder -CopyAppToSymbolsFolder
    }

    Write-Host "Adding app $appFile to app files"
    $appFiles += $appFile

    return $appFiles
}

<#
    .Synopsis
    Creates a compiler folder.

    .Parameter packageCacheFolder
    The folder for the packagecache.
#>
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

<#
    .Synopsis
    Gets all apps from AL-Go projects in the base folder.

    .Parameter baseFolder
    The base folder where the AL-Go projects are located.
#>
function GetAllApps {
    param(
        [Parameter(Mandatory = $true)]
        [string] $baseFolder
    )
    if(-not $($script:allApps)) {
        # Get all AL-Go projects
        $alGoProjects = [ALGoProjectInfo]::FindAll($baseFolder)

        $appInfos = @()

        # Collect all apps from AL-Go projects
        foreach($alGoProject in $alGoProjects) {
            $appFolders = $alGoProject.GetAppFolders($true)
            foreach($appFolder in $appFolders) {
                $appInfo = [AppProjectInfo]::Get($appFolder, 'app')

                if($appInfos.Id -notcontains $appInfo.Id) {
                    $appInfos += $appInfo
                }
            }

            $testAppFolders = $alGoProject.GetTestFolders($true)
            foreach($testAppFolder in $testAppFolders) {
                $testAppInfo = [AppProjectInfo]::Get($testAppFolder, 'test')

                if($appInfos.Id -notcontains $testAppInfo.Id) {
                    $appInfos += $testAppInfo
                }
            }
        }

        $script:allApps = $appInfos
    }

    return $script:allApps
}