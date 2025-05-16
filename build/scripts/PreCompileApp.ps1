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

    if($appBuildMode -eq 'Translated') {
        Import-Module $PSScriptRoot\AppTranslations.psm1
        Restore-TranslationsForApp -AppProjectFolder $parameters.Value["appProjectFolder"]
    }

    # Restore the baseline app and generate the AppSourceCop.json file
    if($gitHubActions) {
        if($appBuildMode -eq 'Clean') {
            # Compile the clean dependencies
            if ($recompileDependencies.Count -gt 0) {
                $recompileDependencies | ForEach-Object {
                    Build-App -App $_ -CompilationParameters ($parameters.Value.Clone())
                }
            }
        }

        if (($parameters.Value.ContainsKey("EnableAppSourceCop") -and $parameters.Value["EnableAppSourceCop"]) -or ($parameters.Value.ContainsKey("EnablePerTenantExtensionCop") -and $parameters.Value["EnablePerTenantExtensionCop"])) {
            Import-Module $PSScriptRoot\GuardingV2ExtensionsHelper.psm1

            if($appBuildMode -eq 'Clean') {
                Write-Host "Compile the app without any preprocessor symbols to generate a baseline app to use for breaking changes check"

                $tempParameters = $parameters.Value.Clone()

                # Wipe the preprocessor symbols to ensure that the baseline is generated without any preprocessor symbols
                $tempParameters["preprocessorsymbols"] = @()
                
                # Create a new folder folder for the symbols
                $defaultSymbolsPath = Join-Path (Split-Path $tempParameters["appSymbolsFolder"] -Parent) "DefaultSymbols"
                if (-not (Test-Path $defaultSymbolsPath)) {
                    New-Item -Path $defaultSymbolsPath -ItemType Directory -Force | Out-Null
                }

                if ($recompileDependencies.Count -gt 0) {
                    $recompileDependencies | ForEach-Object {
                        Build-App -App $_ -CompilationParameters $tempParameters -OutputFolder $defaultSymbolsPath
                    }
                }

                $tempParameters["appSymbolsFolder"] = $defaultSymbolsPath

                if($useCompilerFolder) {
                    Compile-AppWithBcCompilerFolder @tempParameters | Out-Null
                }
                else {
                    Compile-AppInBcContainer @tempParameters | Out-Null
                }

                # Copy the generated app to the symbols folder
                $appFile = Join-Path $tempParameters["appOutputFolder"] $tempParameters["appName"]
                $location = Join-Path $parameters.Value["appSymbolsFolder"] "$($tempParameters["appName"])_clean.app"
                Write-Host "Copying $appFile to $location"
                Copy-Item -Path $appFile -Destination $location -Force -Verbose
                # Remove the app file from the output folder
                Write-Host "Removing $appFile from the output folder"
                Remove-Item -Path $appFile -Force -Verbose

                # Print the content of the symbols folder
                Write-Host "Content of the symbols folder:"
                Get-ChildItem -Path $parameters.Value["appSymbolsFolder"] -Recurse -Filter *.app | ForEach-Object {
                    Write-Host $_.FullName
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

            #Enable-BreakingChangesCheck -AppSymbolsFolder $parameters.Value["appSymbolsFolder"] -AppProjectFolder $parameters.Value["appProjectFolder"] -BuildMode $appBuildMode | Out-Null
        }
    }
}
