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

# Clean the package cache on the first invocation, keeping only System.app
$cache = $parameters.Value["PackageCachePath"]
$cacheCleanedMarker = Join-Path $cache ".cache_cleaned"
if (-not (Test-Path $cacheCleanedMarker)) {
    Write-Host "First invocation: cleaning package cache at $cache (keeping System.app)"
    Get-ChildItem -Path $cache -File | Where-Object { $_.Name -ne 'System.app' } | Remove-Item -Force
    New-Item -ItemType File -Path $cacheCleanedMarker | Out-Null
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
