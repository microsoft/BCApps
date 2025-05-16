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
        if (($parameters.Value.ContainsKey("EnableAppSourceCop") -and $parameters.Value["EnableAppSourceCop"]) -or ($parameters.Value.ContainsKey("EnablePerTenantExtensionCop") -and $parameters.Value["EnablePerTenantExtensionCop"])) {
            Import-Module $PSScriptRoot\GuardingV2ExtensionsHelper.psm1

            if($appBuildMode -eq 'Clean') {
                Write-Host "Compile the app without any preprocessor symbols to generate a baseline app to use for breaking changes check"

                $tempParameters = $parameters.Value.Clone()

                # Wipe the preprocessor symbols to ensure that the baseline is generated without any preprocessor symbols
                $tempParameters["preprocessorsymbols"] = @()
                
                # Create a new folder folder for the symbols
                $newSymbolsPath = Split-Path $tempParameters["appSymbolsFolder"] -Parent
                if (-not (Test-Path $newSymbolsPath)) {
                    New-Item -Path $newSymbolsPath -ItemType Directory -Force | Out-Null
                }

                # Place the app directly in the symbols folder
                $tempParameters["appOutputFolder"] = $tempParameters["appSymbolsFolder"] # Output into the symbols folder
                $tempParameters["appSymbolsFolder"] = $newSymbolsPath # Create a new folder for symbols used for compiling the non-clean app

                # Rename the app to avoid overwriting the app that will be generated with preprocessor symbols
                $appJson = Join-Path $tempParameters["appProjectFolder"] "app.json"
                $appName = (Get-Content -Path $appJson | ConvertFrom-Json).Name
                $tempParameters["appName"] = "$($appName)_clean.app"

                # Print the content of the appSymbols folder
                Write-Host "Content of the app symbols folder:"
                Get-ChildItem -Path $tempParameters["appSymbolsFolder"] | ForEach-Object { Write-Host $_.FullName }
                # Print the content of the appOutput folder
                Write-Host "Content of the app output folder:"
                Get-ChildItem -Path $tempParameters["appOutputFolder"] | ForEach-Object { Write-Host $_.FullName }

                if($useCompilerFolder) {
                    Compile-AppWithBcCompilerFolder @tempParameters | Out-Null
                }
                else {
                    Compile-AppInBcContainer @tempParameters | Out-Null
                }

                # Remove everything in the symbols folder that isn't the baseline app (not _clean.app)
                Get-ChildItem -Path $tempParameters["appSymbolsFolder"] -Recurse -Filter *.app | Where-Object { $_.Name -ne "$($appName)_clean.app" } | ForEach-Object {
                    Remove-Item -Path $_.FullName -Force -Verbose
                }

                # Compile the clean dependencies
                if ($recompileDependencies.Count -gt 0) {
                    $recompileDependencies | ForEach-Object {
                        Build-App -App $_ -CompilationParameters ($parameters.Value.Clone())
                    }
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

            Enable-BreakingChangesCheck -AppSymbolsFolder $parameters.Value["appSymbolsFolder"] -AppProjectFolder $parameters.Value["appProjectFolder"] -BuildMode $appBuildMode | Out-Null
        }
    }
}
