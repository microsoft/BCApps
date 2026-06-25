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

Reset-AlPackageCache -PackageCachePath $parameters.Value["PackageCachePath"] -PreserveNames $preserveNames

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
                $tempParameters["OutFolder"] = $tempParameters["PackageCachePath"] # Output the baseline app into the package cache folder

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

            Enable-BreakingChangesCheckForWorkspace -AppSymbolsFolder $parameters.Value["PackageCachePath"] -WorkspaceFile $parameters.Value["WorkspaceFile"] -BuildMode $appBuildMode -CountryCode $countryCode | Out-Null
        }
    }
}
