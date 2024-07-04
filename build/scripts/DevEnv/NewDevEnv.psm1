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

function Create-BCContainer {
    param(
        [string] $ContainerName,
        [string] $Authentication,
        [PSCredential] $Credential,
        [switch] $backgroundJob
    )
    $baseFolder = (Get-BaseFolderForPath -Path $PSScriptRoot)

    [Scriptblock] $createContainerScriptblock = {
        param(
            [string] $baseFolder,
            [string] $ContainerName,
            [string] $Authentication,
            [PSCredential] $Credential
        )
        Set-Location $baseFolder

        Import-Module "$baseFolder\build\scripts\EnlistmentHelperFunctions.psm1" -DisableNameChecking
        Import-Module "$baseFolder\build\scripts\DevEnv\NewDevContainer.psm1" -DisableNameChecking
        Import-Module BcContainerHelper

        # Get artifactUrl from branch
        $artifactUrl = Get-ConfigValue -Key "artifact" -ConfigType AL-Go

        # Create a new container with a single tenant
        $bcContainerHelperConfig.sandboxContainersAreMultitenantByDefault = $false
        New-BcContainer -artifactUrl $artifactUrl -accept_eula -accept_insiderEula -containerName $ContainerName -auth $Authentication -Credential $Credential -includeAL -additionalParameters @("--volume ""$($baseFolder):c:\sources""")

        # Move all installed apps to the dev scope
        # By default, the container is created with the global scope. We need to move all installed apps to the dev scope.
        Setup-ContainerForDevelopment -ContainerName $ContainerName -RepoVersion (Get-ConfigValue -Key "repoVersion" -ConfigType AL-Go)
    }

    if ($backgroundJob)
    {
        $createContainerJob = Start-Job -ScriptBlock $createContainerScriptblock -ArgumentList $baseFolder, $ContainerName, $Authentication, $credential | Get-Job
        return $createContainerJob
    }
    else
    {
        Invoke-Command -ScriptBlock $createContainerScriptblock -ArgumentList $baseFolder, $ContainerName, $Authentication, $credential
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

        [Parameter(Mandatory = $false)]
        [string] $baseFolder = (Get-BaseFolder)
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
        [string] $baseFolder,
        [Parameter(Mandatory = $false)]
        [switch] $rebuild
    )

    $appFiles = @()
    $allAppInfos = GetAllApps -baseFolder $baseFolder
    $appOutputFolder = $packageCacheFolder
    $appInfo = [AppProjectInfo]::Get($appProjectFolder)
    $appFileName = $appInfo.GetAppFileName()
    $appFilePath = Join-Path $appOutputFolder $appFileName

    # Build dependencies
    foreach($dependency in $appInfo.AppJson.dependencies) {
        Write-Host "Building dependency: $($dependency.id)" -ForegroundColor Yellow
        $dependencyAppInfo = $allAppInfos | Where-Object { $_.Id -eq $dependency.id }
        $dependencyAppFile = BuildApp -appProjectFolder $($dependencyAppInfo.AppProjectFolder) -compilerFolder $compilerFolder -packageCacheFolder $packageCacheFolder -baseFolder $baseFolder

        $appFiles += @($dependencyAppFile)
    }

    $appProjectFolder = GetRootedFolder -folder $appProjectFolder -baseFolder $baseFolder

    # If we are rebuilding, remove the app file if it already exists
    if ($rebuild -and (Test-Path $appFilePath)) {
        Write-Host "App $appFileName already exists in $appOutputFolder. Removing and rebuilding..." -ForegroundColor Yellow
        Remove-Item -Path $appFilePath -Force
    }

    if(Test-Path $appFilePath) {
        Write-Host "App $appFileName already exists in $appOutputFolder. Skipping..."
    } else {
        # Create compiler folder on demand
        if(-not $compilerFolder.Value) {
            Write-Host "Creating compiler folder..." -ForegroundColor Yellow
            $compilerFolder.Value = CreateCompilerFolder -packageCacheFolder $packageCacheFolder
            Write-Host "Compiler folder: $($compilerFolder.Value)" -ForegroundColor Yellow
        }

        $appFile = Compile-AppWithBcCompilerFolder -compilerFolder $($compilerFolder.Value) -appProjectFolder "$($appInfo.AppProjectFolder)" -appOutputFolder $appOutputFolder -appSymbolsFolder $packageCacheFolder
        $appFiles += $appFile
    }

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
        $packageCacheFolder,
        [switch] $rebuild
    )
    $appFiles = @()
    $baseFolder = Get-BaseFolder
    $packageCacheFolder = GetRootedFolder -folder $packageCacheFolder -baseFolder $baseFolder

    # Compiler folder will be created on demand
    $compilerFolder = ''

    try {
        foreach($currentProjectPath in $projectPaths) {
            Write-Host "Building app in $currentProjectPath" -ForegroundColor Yellow
            $currentAppFiles = BuildApp -appProjectFolder $currentProjectPath -compilerFolder ([ref]$compilerFolder) -packageCacheFolder $packageCacheFolder -baseFolder $baseFolder -rebuild:$rebuild
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
    Publishes apps to a container.

    .Parameter ContainerName
    The name of the container to publish the app to.

    .Parameter AppFiles
    The paths to the app files to publish.

    .Parameter Credential
    The credential to use when publishing the app.
#>
function Publish-Apps() {
    param(
        [Parameter(Mandatory = $true)]
        [string] $ContainerName,
        [Parameter(Mandatory = $true)]
        [string[]] $AppFiles,
        [Parameter(Mandatory = $true)]
        [PSCredential] $Credential
    )
    $appPublishResults = @() # Array of hashtables with the results of the app publishing
    foreach($appFile in $AppFiles) {
        try {
            Publish-BcContainerApp -containerName $ContainerName -appFile $appFile -credential $Credential -syncMode ForceSync -sync -skipVerification -install -useDevEndpoint -dependencyPublishingOption ignore
            $appPublishResults += @{ "AppFile" = $appFile; "Success" = $true }
        } catch {
            Write-Error "Failed to publish app $appFile : $_"
            $appPublishResults += @{ "AppFile" = $appFile; "Success" = $false}
        }
    }
    return $appPublishResults
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

    # If the compiler folder already exists, return it
    $compilerFolder = Join-Path $packageCacheFolder "CompilerFolder"
    if (Test-Path $compilerFolder) {
        return $compilerFolder
    }

    # Create the package cache folder if it does not exist
    if (-not (Test-Path $packageCacheFolder)) {
        New-Item -Path $packageCacheFolder -ItemType Directory | Out-Null
    }

    # Create compiler folder using the AL-Go artifact URL
    $bcArtifactUrl = Get-ConfigValue -Key "artifact" -ConfigType AL-Go
    Write-Host "Creating compiler folder $compilerFolder" -ForegroundColor Yellow
    New-BcCompilerFolder -artifactUrl $bcArtifactUrl -cacheFolder $compilerFolder | Out-Null
    return $compilerFolder
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
    Gets the credential to use for a container.

    .Description
    This function gets the credential to use for a container. The credential is used to authenticate with the container.

    .Parameter AuthenticationType
    The authentication type to use. Can be 'Windows' or 'NavUserPassword'.

    .Outputs
    The credential to use for the container.
#>
function Get-CredentialForContainer($AuthenticationType) {
    if ($AuthenticationType -eq 'Windows') {
        return Get-Credential -Message "Please enter your Windows Credentials" -UserName $env:USERNAME
    } elseif($AuthenticationType -eq 'UserPassword') {
        return Get-Credential -UserName 'admin' -Message "Enter the password for the admin user"
    } else {
        throw "Invalid authentication type: $AuthenticationType"
    }
}

<#
    .Synopsis
    Installs the AL extension in VSCode.

    .Parameter ContainerName
    The name of the container for which to install the extension.

    .Parameter Force
    If specified, the extension will be installed even there is a newer version already installed.
#>
function Install-ALExtension([string] $ContainerName, [switch] $Force) {
    if (-not (Get-Command code -ErrorAction SilentlyContinue)) {
        Write-Host "VSCode is not installed or 'code' is not in the PATH. See https://code.visualstudio.com/docs/setup/windows for installation instructions." -ForegroundColor Red
        return
    }

    Write-Host "Installing VSCode extension..." -ForegroundColor Magenta
    # Kill VSCode to avoid issues with the extension installation
    Stop-Process -Name code -Force -ErrorAction SilentlyContinue

    $vsixPath = Get-ChildItem "$($bcContainerHelperConfig.containerHelperFolder)\Extensions\$ContainerName\*.vsix" | Select-Object -ExpandProperty FullName
    if ($Force) {
        code --install-extension $vsixPath --force
    } else {
        code --install-extension $vsixPath
    }
    Write-Host "VSCode extension installed." -ForegroundColor Magenta
}

Export-ModuleMember -Function Create-BCContainer
Export-ModuleMember -Function Resolve-ProjectPaths
Export-ModuleMember -Function Build-Apps
Export-ModuleMember -Function Publish-Apps
Export-ModuleMember -Function Test-ContainerExists
Export-ModuleMember -Function Get-CredentialForContainer
Export-ModuleMember -Function Install-ALExtension