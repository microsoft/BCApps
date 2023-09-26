Param(
    [Parameter(Mandatory=$true)]
    [string] $currentProjectFolder,
    [ValidateSet('app', 'testApp', 'bcptApp')]
    [string] $appType = 'app',
    [ref] $parameters
)

Import-Module $PSScriptRoot\EnlistmentHelperFunctions.psm1

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

                function New-TemporaryDirectory {
                    $parent = [System.IO.Path]::GetTempPath()
                    [string] $name = [System.Guid]::NewGuid()
                    New-Item -ItemType Directory -Path (Join-Path $parent $name)
                }

                # Place the app directly in the symbols folder
                $tempParameters["appOutputFolder"] = $(New-TemporaryDirectory).FullName

                $appFile = Compile-AppWithBcCompilerFolder @tempParameters | Out-Null

                Copy-Item -Path $appFile -Destination $parameters.Value["appSymbolsFolder"] -Force | Out-Null
            }

            Enable-BreakingChangesCheck -AppSymbolsFolder $parameters.Value["appSymbolsFolder"] -AppProjectFolder $parameters.Value["appProjectFolder"] -BuildMode $appBuildMode | Out-Null
        }
    }
}
