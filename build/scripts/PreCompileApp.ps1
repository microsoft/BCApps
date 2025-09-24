Param(
    [ValidateSet('app', 'testApp', 'bcptApp')]
    [string] $appType = 'app',
    [ref] $parameters,
    [string[]] $recompileDependencies = @()
)

Import-Module $PSScriptRoot\EnlistmentHelperFunctions.psm1
Import-Module $PSScriptRoot\AppExtensionsHelper.psm1

$appBuildMode = Get-BuildMode

if($appType -eq 'app')
{
    # Setup compiler features to generate captions and LCGs
    if (!$parameters.Value.ContainsKey("Features")) {
        $parameters.Value["Features"] = @()
    }
    $parameters.Value["Features"] += @("generateCaptions")

    # Setup compiler features to generate LCGs for the default build mode
    if($appBuildMode -eq 'Default') {
        $parameters.Value["Features"] += @("lcgtranslationfile")
    }

    # Disable report layout generation for the app compilation to how apps are built internally
    $parameters.Value["GenerateReportLayout"] = "No"

    if($appBuildMode -eq 'Translated') {
        Import-Module $PSScriptRoot\AppTranslations.psm1
        Restore-TranslationsForApp -AppProjectFolder $parameters.Value["appProjectFolder"]
    }

    if(($appBuildMode -eq 'Clean') -and ($recompileDependencies.Count -gt 0)) {
        # In CLEAN mode we might need to recompile some of the dependencies before we can compile the app (in case the dependencies are not within the repository)
        $recompileDependencies | ForEach-Object {
            $dependenciesParameters = $parameters.Value.Clone()
            $dependenciesParameters["appOutputFolder"] = $dependenciesParameters["appSymbolsFolder"] # Output the apps into the symbols folder so we can use them for the clean build later
            Build-App -App $_ -CompilationParameters $dependenciesParameters
        }
    }

    # Restore the baseline app and generate the AppSourceCop.json file
    if($gitHubActions) {
        if (($parameters.Value.ContainsKey("EnableAppSourceCop") -and $parameters.Value["EnableAppSourceCop"]) -or ($parameters.Value.ContainsKey("EnablePerTenantExtensionCop") -and $parameters.Value["EnablePerTenantExtensionCop"])) {
            Import-Module $PSScriptRoot\GuardingV2ExtensionsHelper.psm1

            if($appBuildMode -eq 'Clean') {
                Write-Host "Compile the app without any preprocessor symbols to generate a baseline app to use for breaking changes check"

                # Create a new empty folder for the apps without preprocessor symbols
                $defaultSymbolsPath = Join-Path (Split-Path $parameters.Value["appSymbolsFolder"] -Parent) "DefaultModeSymbols"
                if (-not (Test-Path $defaultSymbolsPath)) {
                    New-Item -Path $defaultSymbolsPath -ItemType Directory -Force | Out-Null
                }

                # Recompile dependencies if needed and place them in the default symbols folder
                if ($recompileDependencies.Count -gt 0) {
                    $recompileDependencies | ForEach-Object {
                        $dependenciesParameters = $parameters.Value.Clone()
                        $dependenciesParameters["preprocessorsymbols"] = @() # Wipe the preprocessor symbols to ensure that the baseline is generated without any preprocessor symbols
                        $dependenciesParameters["appOutputFolder"] = $defaultSymbolsPath # Use the default symbols folder as appOutputFolder
                        $dependenciesParameters["appSymbolsFolder"] = $defaultSymbolsPath # Use the default symbols folder as appSymbolsFolder
                        Build-App -App $_ -CompilationParameters $dependenciesParameters
                    }
                }

                $tempParameters = $parameters.Value.Clone()
                $tempParameters["preprocessorsymbols"] = @() # Wipe the preprocessor symbols to ensure that the baseline is generated without any preprocessor symbols
                $tempParameters["appOutputFolder"] = $defaultSymbolsPath # Output the default app into the default symbols folder
                $tempParameters["appSymbolsFolder"] = $defaultSymbolsPath # Use the default symbols folder as appSymbolsFolder

                $appName = (Get-Content -Path (Join-Path $tempParameters["appProjectFolder"] "app.json" -Resolve) | ConvertFrom-Json).Name
                # If the app has already been restored to the default symbols folder, remove it before recompiling
                Get-ChildItem -Path $defaultSymbolsPath -Filter "Microsoft_$($appName)*.app" | ForEach-Object {
                    Write-Host "Removing existing app file in symbols folder: $($_.FullName)"
                    Remove-Item -Path $_.FullName -Force
                }

                if($useCompilerFolder) {
                    Compile-AppWithBcCompilerFolder @tempParameters | Out-Null
                }
                else {
                    Compile-AppInBcContainer @tempParameters | Out-Null
                }

                # Copy the the generated app to the symbols folder for the CLEAN mode build
                $appFile = Get-ChildItem -Path $tempParameters["appOutputFolder"] -Filter "Microsoft_$($appName)*.app" | Select-Object -First 1
                $location = Join-Path $parameters.Value["appSymbolsFolder"] "$($appName)_clean.app"
                Write-Host "Copying $($appFile.FullName) to $location"
                Copy-Item -Path $appFile.FullName -Destination $location -Force
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

            Enable-BreakingChangesCheck -AppSymbolsFolder $parameters.Value["appSymbolsFolder"] -AppProjectFolder $parameters.Value["appProjectFolder"] -BuildMode $appBuildMode | Out-Null
        }
    }
}
