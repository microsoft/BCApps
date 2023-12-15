using module .\AppProjectInfo.class.psm1
using module .\ALGoProjectInfo.class.psm1

Import-Module "BCContainerHelper" -DisableNameChecking
Import-Module "$PSScriptRoot\..\EnlistmentHelperFunctions.psm1" -DisableNameChecking

$script:allApps = @()
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

<#
    .Synopsis
    Creates a BC container from based on the specified artifact URL in the AL-Go settings.
    If the container already exists, it will be reused.
    .Parameter containerName
    The name of the container.
    .Parameter credential
    The credential to use for the container.
    .Parameter backgroundJob
    If specified, the container will be created in the background.
    .Outputs
    The job that creates the container if the backgroundJob switch is specified.
#>
function Create-BCContainer {
    param (
        [Parameter(Mandatory = $true)]
        [string] $containerName,
        [Parameter(Mandatory = $true)]
        [pscredential] $credential,
        [switch] $backgroundJob
    )

    if(Test-ContainerExists -containerName $containerName) {
        Write-Host "Container $containerName already exists" -ForegroundColor Yellow
        return
    }

    $baseFolder = Get-BaseFolder

    $bcArtifactUrl = Get-ConfigValue -Key "artifact" -ConfigType AL-Go
    if($backgroundJob) {
        [Scriptblock] $createContainerScriptblock = {
            param(
                [Parameter(Mandatory = $true)]
                [string] $containerName,
                [Parameter(Mandatory = $true)]
                [pscredential] $credential,
                [Parameter(Mandatory = $true)]
                [string] $bcArtifactUrl,
                [Parameter(Mandatory = $true)]
                [string] $baseFolder
            )
            Import-Module "BCContainerHelper" -DisableNameChecking

            $newContainerParams = @{
                "accept_eula" = $true
                "accept_insiderEula" = $true
                "containerName" = $containerName
                "artifactUrl" = $bcArtifactUrl
                "Credential" = $credential
                "auth" = "UserPassword"
                "additionalParameters" = @("--volume ""$($baseFolder):c:\sources""")
            }

            $creatingContainerStats = Measure-Command {
                $newBCContainerScript = Join-Path $baseFolder "build\scripts\NewBcContainer.ps1" -Resolve
                . $newBCContainerScript -parameters $newContainerParams
            }

            Write-Host "Creating container $containerName took $($creatingContainerStats.TotalSeconds) seconds"
        }

        # Set the current location to the base folder
        function jobInit {
            param(
                $baseFolder
            )

            return [ScriptBlock]::Create("Set-Location $baseFolder")
        }

        $createContainerJob = $null
        $createContainerJob = Start-Job -InitializationScript $(jobInit -baseFolder $baseFolder) -ScriptBlock $createContainerScriptblock -ArgumentList $containerName, $credential, $bcArtifactUrl, $baseFolder | Get-Job
        Write-Host "Creating container $containerName from artifact URL $bcArtifactUrl in the background. Job ID: $($createContainerJob.Id)" -ForegroundColor Yellow

        return $createContainerJob
    } else {
        $createContainerScriptblock.Invoke($containerName, $credential, $bcArtifactUrl, $baseFolder)
    }
}

<#
    .Synopsis
    Resolves the project paths to AL app project folders.
    .Parameter projectPaths
    The project paths to resolve. May contain wildcards.
    .Parameter workspacePath
    The path to the workspace file. The workspace file contains a list of folders that contain AL projects.
    .Parameter alGoProject
    The path to the AL-Go project.
    .Parameter baseFolder
    The base folder where the AL projects are located.
    .Outputs
    The resolved project paths as an array of strings. The paths are absolute and unique.
#>
function Resolve-ProjectPaths {
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

<#
    .Synopsis
    Checks if a container with the specified name exists.
#>
function Test-ContainerExists {
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
    The folder where the compiler is located. If not specified, the compiler folder will be created on demand.

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
        [ref] $compilerFolder,
        [Parameter(Mandatory = $true)]
        [string] $packageCacheFolder,
        [Parameter(Mandatory = $true)]
        [string] $baseFolder
    )

    $appFiles = @()
    $allAppInfos = GetAllApps -baseFolder $baseFolder
    $appOutputFolder = $packageCacheFolder
    $appInfo = [AppProjectInfo]::Get($appProjectFolder)

    # Build dependencies
    foreach($dependency in $appInfo.AppJson.dependencies) {
        Write-Host "Building dependency: $($dependency.id)" -ForegroundColor Yellow
        $dependencyAppInfo = $allAppInfos | Where-Object { $_.Id -eq $dependency.id }
        $dependencyAppFile = BuildApp -appProjectFolder $($dependencyAppInfo.AppProjectFolder) -compilerFolder $compilerFolder -packageCacheFolder $packageCacheFolder -baseFolder $baseFolder

        $appFiles += @($dependencyAppFile)
    }

    $appProjectFolder = GetRootedFolder -folder $appProjectFolder -baseFolder $baseFolder

    $appFile = $appInfo.GetAppFileName()

    if((Test-Path (Join-Path $appOutputFolder $appFile)) -and (-not $rebuild)) {
        Write-Host "App $appFile already exists in $appOutputFolder. Skipping..."
        $appFile = (Join-Path $appOutputFolder $appFile -Resolve)
    } else {
        # Create compiler folder on demand
        if(-not $compilerFolder.Value) {
            Write-Host "Creating compiler folder..." -ForegroundColor Yellow
            $compilerFolder.Value = CreateCompilerFolder -packageCacheFolder $packageCacheFolder
            Write-Host "Compiler folder: $($compilerFolder.Value)" -ForegroundColor Yellow
        }

        $appFile = Compile-AppWithBcCompilerFolder -compilerFolder $($compilerFolder.Value) -appProjectFolder "$($appInfo.AppProjectFolder)" -appOutputFolder $appOutputFolder -appSymbolsFolder $packageCacheFolder
    }

    $appFiles += $appFile

    return $appFiles
}

<#
    .Synopsis
    Builds all apps in the specified project paths.
    .Parameter projectPaths
    The project paths to use for the build.
    .Parameter packageCacheFolder
    The folder for the packagecache.
    .Outputs
    The app files that were built. The paths are absolute and unique.
#>
function Build-Apps {
    param (
        $projectPaths,
        $packageCacheFolder
    )
    $appFiles = @()
    $baseFolder = Get-BaseFolder
    $packageCacheFolder = GetRootedFolder -folder $packageCacheFolder -baseFolder $baseFolder

    # Compiler folder will be created on demand
    $compilerFolder = ''

    try {
        foreach($currentProjectPath in $projectPaths) {
            Write-Host "Building app in $currentProjectPath" -ForegroundColor Yellow
            $currentAppFiles = BuildApp -appProjectFolder $currentProjectPath -compilerFolder ([ref]$compilerFolder) -packageCacheFolder $packageCacheFolder -baseFolder $baseFolder
            $appFiles += @($currentAppFiles)
        }
    }
    catch {
        Write-Host "Error building apps: $_" -ForegroundColor Red
        throw $_
    }
    finally {
        if ($compilerFolder) {
            Write-Host "Removing compiler folder $compilerFolder" -ForegroundColor Yellow
            Remove-Item -Path $compilerFolder -Recurse -Force | Out-Null
        }
    }

    $appFiles = $appFiles | Select-Object -Unique

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

Export-ModuleMember -Function Create-BCContainer
Export-ModuleMember -Function Resolve-ProjectPaths
Export-ModuleMember -Function Test-ContainerExists
Export-ModuleMember -Function Build-Apps