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
        Write-Host "App $appFile already exists in $appOutputFolder. Removing..."
        $appFile = (Join-Path $appOutputFolder $appFile -Resolve)
        Remove-Item -Path $appFile -Force
    } 
    
    # Create compiler folder on demand
    if(-not $compilerFolder.Value) {
        Write-Host "Creating compiler folder..." -ForegroundColor Yellow
        $compilerFolder.Value = CreateCompilerFolder -packageCacheFolder $packageCacheFolder
        Write-Host "Compiler folder: $($compilerFolder.Value)" -ForegroundColor Yellow
    }

    $appFile = Compile-AppWithBcCompilerFolder -compilerFolder $($compilerFolder.Value) -appProjectFolder "$($appInfo.AppProjectFolder)" -appOutputFolder $appOutputFolder -appSymbolsFolder $packageCacheFolder

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

    Write-Host "Creating compiler folder $packageCacheFolder" -ForegroundColor Yellow

    if (Test-Path $packageCacheFolder) {
        return $packageCacheFolder
    }

    Write-Host "Creating package cache folder $packageCacheFolder"
    New-Item -Path $packageCacheFolder -ItemType Directory | Out-Null

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

function Get-CredentialForContainer($AuthenticationType) {
    if ($AuthenticationType -eq 'Windows') {
        return Get-Credential -Message "Please enter your Windows Credentials" -UserName $env:USERNAME
    } else {
        return Get-Credential -UserName 'admin' -Message "Enter the password for the admin user"
    }
}

Export-ModuleMember -Function Resolve-ProjectPaths
Export-ModuleMember -Function Test-ContainerExists
Export-ModuleMember -Function Build-Apps
Export-ModuleMember -Function Get-CredentialForContainer