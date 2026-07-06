Param(
    [ValidateSet('app', 'testApp', 'bcptApp')]
    [string] $appType = 'app',
    [ref] $parameters,
    [string[]] $recompileDependencies = @(),
    [switch] $GDLDevelopment,
    [string] $countryCode = "W1"
)

Import-Module $PSScriptRoot\EnlistmentHelperFunctions.psm1
Import-Module $PSScriptRoot\AppExtensionsHelper.psm1

function Get-IncrementalBuildBaselineAppNames {
    <#
    .SYNOPSIS
        Returns the file names of baseline .app files staged by AL-Go for incremental builds.
    .DESCRIPTION
        When incremental builds are active in 'modifiedApps' mode, AL-Go places baseline
        apps in <BuildArtifactsFolder>\Apps and <BuildArtifactsFolder>\TestApps before
        the per-app compile step. Returns the .app file names (not full paths) found in
        those folders, or an empty array if neither folder exists or contains .app files.
    #>
    param(
        [Parameter(Mandatory)]
        [string] $BuildArtifactsFolder
    )

    Write-Host "PreCompileApp: looking for baseline apps under '$BuildArtifactsFolder'"

    $names = @()
    foreach ($sub in @('Apps', 'TestApps')) {
        $baselineFolder = Join-Path $BuildArtifactsFolder $sub
        if (-not (Test-Path $baselineFolder)) {
            Write-Host "PreCompileApp: baseline folder '$baselineFolder' does not exist; skipping"
            continue
        }
        $baselineApps = @(Get-ChildItem -Path $baselineFolder -Filter '*.app' -File -ErrorAction SilentlyContinue | ForEach-Object { $_.Name })
        if ($baselineApps.Count -eq 0) {
            Write-Host "PreCompileApp: baseline folder '$baselineFolder' exists but contains no .app files"
        }
        else {
            Write-Host "PreCompileApp: found $($baselineApps.Count) baseline app(s) in '$baselineFolder':"
            $baselineApps | ForEach-Object { Write-Host "  - $_" }
            $names += $baselineApps
        }
    }

    return $names
}

function Reset-AlPackageCache {
    <#
    .SYNOPSIS
        Removes all files from the AL package cache except a given preserve list, once per cache.
    .DESCRIPTION
        Writes a marker file inside the cache after cleaning so subsequent invocations for the
        same cache become no-ops. Preserves the files whose names are listed in PreserveNames
        (compared by file name only).
    #>
    param(
        [Parameter(Mandatory)]
        [string] $PackageCachePath,
        [string[]] $PreserveNames = @('System.app')
    )

    $cacheCleanedMarker = Join-Path $PackageCachePath ".cache_cleaned"
    if (Test-Path $cacheCleanedMarker) {
        return
    }

    $PreserveNames = @($PreserveNames | Sort-Object -Unique)

    Write-Host "PreCompileApp: cleaning package cache at $PackageCachePath. Preserving $($PreserveNames.Count) file(s):"
    $PreserveNames | ForEach-Object { Write-Host "  - $_" }

    $filesToRemove = @(Get-ChildItem -Path $PackageCachePath -File | Where-Object { $PreserveNames -notcontains $_.Name })
    if ($filesToRemove.Count -eq 0) {
        Write-Host "PreCompileApp: no files to remove from package cache"
    }
    else {
        Write-Host "PreCompileApp: removing $($filesToRemove.Count) file(s) from package cache:"
        $filesToRemove | ForEach-Object { Write-Host "  - $($_.Name)" }
        $filesToRemove | Remove-Item -Force
    }

    New-Item -ItemType File -Path $cacheCleanedMarker | Out-Null
}

function Get-GitHubWorkflowArtifacts {
    param(
        [Parameter(Mandatory)]
        [string] $WorkflowRunId,

        [Parameter(Mandatory)]
        [hashtable] $Headers
    )

    $apiUrl = if ($env:GITHUB_API_URL) { $env:GITHUB_API_URL } else { 'https://api.github.com' }
    $artifacts = @()
    $page = 1

    do {
        $artifactsUrl = "$apiUrl/repos/$env:GITHUB_REPOSITORY/actions/runs/$WorkflowRunId/artifacts?per_page=100&page=$page"
        $response = Invoke-CommandWithRetry -ScriptBlock { Invoke-RestMethod -Uri $artifactsUrl -Headers $Headers -TimeoutSec 300 }
        $artifacts += @($response.artifacts)
        $page++
    } while ($response.artifacts.Count -eq 100)

    return $artifacts
}

function Copy-DefaultAppsArtifactToBaselineCache {
    param(
        [Parameter(Mandatory)]
        [string] $PackageCachePath,

        [Parameter(Mandatory)]
        [string] $Project,

        [string[]] $CurrentBuildBaselineAppNames = @()
    )

    $buildMode = if ($env:BuildMode) { $env:BuildMode } else { $env:_buildMode }
    $baselineWorkflowRunId = if ($env:BaselineWorkflowRunId) { $env:BaselineWorkflowRunId } else { $env:_baselineWorkflowRunId }
    if ($buildMode -ne 'Clean' -or -not $baselineWorkflowRunId -or $baselineWorkflowRunId -eq '0') {
        return $PackageCachePath
    }

    if (-not $CurrentBuildBaselineAppNames) {
        Write-Host "PreCompileApp: no incremental baseline apps were staged; using the existing package cache for baseline compilation"
        return $PackageCachePath
    }

    $githubToken = if ($env:_token) { $env:_token } else { $env:GITHUB_TOKEN }
    if (-not $githubToken) {
        throw "GitHub token is required to download the Default Apps artifact for CLEAN baseline compilation."
    }

    if (-not $env:GITHUB_REPOSITORY) {
        throw "GITHUB_REPOSITORY is required to download the Default Apps artifact for CLEAN baseline compilation."
    }

    $baselinePackageCachePath = Join-Path (Split-Path $PackageCachePath -Parent) 'symbols-baseline'
    $baselineCacheReadyMarker = Join-Path $baselinePackageCachePath '.default_apps_downloaded'
    if (Test-Path $baselineCacheReadyMarker) {
        return $baselinePackageCachePath
    }

    New-Item -ItemType Directory -Path $baselinePackageCachePath -Force | Out-Null

    $systemAppPath = Join-Path $PackageCachePath 'System.app'
    if (Test-Path $systemAppPath) {
        Copy-Item -Path $systemAppPath -Destination $baselinePackageCachePath -Force -ErrorAction Stop
    }
    else {
        throw "System.app was not found in package cache '$PackageCachePath'."
    }

    $headers = @{
        Authorization = "Bearer $githubToken"
        Accept = 'application/vnd.github+json'
        'X-GitHub-Api-Version' = '2022-11-28'
    }

    $artifactProjectName = $Project.Replace('\', '_').Replace('/', '_')
    Write-Host "PreCompileApp: downloading Default Apps artifact for '$artifactProjectName' from baseline workflow run $baselineWorkflowRunId into '$baselinePackageCachePath'"

    $artifactNamePattern = "$artifactProjectName-*-Apps-*"
    $artifacts = @(Get-GitHubWorkflowArtifacts -WorkflowRunId $baselineWorkflowRunId -Headers $headers |
        Where-Object { $_.name -like $artifactNamePattern })

    if ($artifacts.Count -eq 0) {
        throw "Could not find Default Apps artifact matching '$artifactNamePattern' in baseline workflow run $baselineWorkflowRunId."
    }

    if ($artifacts.Count -gt 1) {
        throw "Found multiple Default Apps artifacts matching '$artifactNamePattern' in baseline workflow run ${baselineWorkflowRunId}: $($artifacts.Name -join ', ')"
    }

    $artifact = $artifacts[0]

    $tempFolder = Join-Path ([System.IO.Path]::GetTempPath()) ([System.Guid]::NewGuid().ToString())
    New-Item -ItemType Directory -Path $tempFolder | Out-Null

    try {
        $zipPath = Join-Path $tempFolder 'default-apps.zip'
        Invoke-CommandWithRetry -ScriptBlock { Invoke-WebRequest -Uri $artifact.archive_download_url -Headers $headers -OutFile $zipPath -TimeoutSec 600 } | Out-Null
        Expand-Archive -Path $zipPath -DestinationPath $tempFolder -Force

        $downloadedApps = @(Get-ChildItem -Path $tempFolder -Recurse -Filter '*.app' -File | Where-Object { $CurrentBuildBaselineAppNames -contains $_.Name })
        if ($downloadedApps.Count -eq 0) {
            throw "Default Apps artifact '$($artifact.name)' did not contain any of the staged baseline app dependencies."
        }

        $downloadedApps | Copy-Item -Destination $baselinePackageCachePath -Force -ErrorAction Stop
        Write-Host "PreCompileApp: copied $($downloadedApps.Count) Default app(s) into baseline package cache"
    }
    finally {
        Remove-Item -Path $tempFolder -Recurse -Force -ErrorAction SilentlyContinue
    }

    New-Item -ItemType File -Path $baselineCacheReadyMarker -Force | Out-Null
    return $baselinePackageCachePath
}

# Clean the package cache on the first invocation, keeping only System.app and any
# baseline apps that AL-Go downloaded for incremental builds. When incremental builds
# are active, AL-Go populates <projectFolder>\.buildartifacts\Apps and \TestApps with
# baseline apps before invoking this script and then copies them into the package cache.
# Those files must be preserved so the workspace compile can resolve dependencies that
# are not in the modified-apps workspace.
$preserveNames = @('System.app')
$outFolder = $parameters.Value["OutFolder"]
if (-not $outFolder) {
    Write-Host "::Warning::PreCompileApp: OutFolder is not set in compilation parameters; cannot locate baseline apps from .buildartifacts. Only System.app will be preserved."
}
else {
    $preserveNames += Get-IncrementalBuildBaselineAppNames -BuildArtifactsFolder (Split-Path -Path $outFolder -Parent)
}

$packageCachePath = $parameters.Value["PackageCachePath"]
if ($packageCachePath) {
    Reset-AlPackageCache -PackageCachePath $packageCachePath -PreserveNames $preserveNames
} else {
    Write-Host "::Warning::PreCompileApp: PackageCachePath is not set in compilation parameters; skipping package cache reset."
}

if($GDLDevelopment) {
    Import-Module $PSScriptRoot\GDLDevelopment\GDLDevelopment.psm1

    New-GDLView -CountryCode $countryCode -skipSetupDevelopmentSettings
    $WorkspaceFilePath = $parameters.Value["WorkspaceFile"]
    $workspace = Get-Content -Path $WorkspaceFilePath -Raw | ConvertFrom-Json
    $projects = $workspace.folders
    foreach ($project in $projects) {
        # The view folder for GDL Development is under 'Views\<country>': this is the folder that contains the app project for compilation for the specified country
        # replace '\Layers\W1' with '\Views\$countryCode' in the appProjectFolder path
        $project.path = $project.path.Replace("\Layers\W1", "\Views\$countryCode") # TODO: make it a bit smarter
        Write-Host "Updated project path for GDL Development: $($project.path)"
    }
    # Save the updated workspace file
    $workspace | ConvertTo-Json -Depth 10 | Set-Content -Path $WorkspaceFilePath
}

$appBuildMode = Get-BuildMode

if($appType -eq 'app')
{
    # Restore the baseline app and generate the AppSourceCop.json file
    $analyzersEnabled = $parameters.Value.ContainsKey("Analyzers") -and @($parameters.Value["Analyzers"]).Count -gt 0

    if($ENV:CI) {
        if ($analyzersEnabled) {
            Write-Host "Analyzers are enabled. Setting up the baseline app and analyzers for breaking changes check."
            Import-Module $PSScriptRoot\GuardingV2ExtensionsHelper.psm1

            if($appBuildMode -eq 'Clean') {
                Write-Host "Compile the app without any preprocessor symbols to generate a baseline app to use for breaking changes check"

                $tempParameters = $parameters.Value.Clone()
                $tempParameters["PreprocessorSymbols"] = @() # Wipe the preprocessor symbols to ensure that the baseline is generated without any preprocessor symbols
                $incrementalBaselineAppNames = @()
                if ($outFolder) {
                    $baselineAppsFolder = Join-Path (Split-Path -Path $outFolder -Parent) 'Apps'
                    if (Test-Path $baselineAppsFolder) {
                        $incrementalBaselineAppNames = @(Get-ChildItem -Path $baselineAppsFolder -Filter '*.app' -File | ForEach-Object { $_.Name })
                    }
                }

                $project = if ($env:_project) { $env:_project } else { $env:ALGoProject }
                if (-not $project) {
                    throw "Project name is required (neither _project nor ALGoProject is set) to locate the Default Apps artifact for CLEAN baseline compilation."
                }
                $tempParameters["PackageCachePath"] = Copy-DefaultAppsArtifactToBaselineCache `
                    -PackageCachePath $parameters.Value["PackageCachePath"] `
                    -Project $project `
                    -CurrentBuildBaselineAppNames $incrementalBaselineAppNames
                $tempParameters["OutFolder"] = $parameters.Value["PackageCachePath"] # Output the baseline app into the package cache folder used by the breaking changes check

                $baselineAppFiles = CompileAppsInWorkspace @tempParameters

                # Rename baseline apps to end with _clean.app
                foreach ($appFile in $baselineAppFiles) {
                    $appFileItem = Get-Item $appFile
                    Rename-Item -Path $appFile -NewName ($appFileItem.Name.Replace(".app", "_clean.app"))
                }
            }

            if($appBuildMode -eq 'Strict') {
                if (!(Test-IsStrictModeEnabled)) {
                    Write-Host "::Warning:: Strict mode is not enabled for this branch. Exiting without enabling the strict mode breaking changes check."
                    return
                } else {
                    Write-Host "Enabling minor release ruleset for strict mode breaking changes check"
                    $parameters.Value["ruleset"] = Get-RulesetPath -Name "minorrelease.ruleset.json"
                }
            }

            if ($parameters.Value["PackageCachePath"]) {
                Enable-BreakingChangesCheckForWorkspace -AppSymbolsFolder $parameters.Value["PackageCachePath"] -WorkspaceFile $parameters.Value["WorkspaceFile"] -BuildMode $appBuildMode -CountryCode $countryCode | Out-Null
            } else {
                Write-Host "::Warning::PreCompileApp: PackageCachePath is not set; skipping breaking changes check."
            }
        }
    }
}
