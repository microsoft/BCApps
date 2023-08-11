Param(
    [Parameter(Mandatory=$true)]
    [string] $currentProjectFolder,
    [Hashtable] $parameters
)

Import-Module $PSScriptRoot\EnlistmentHelperFunctions.psm1

$appBuildMode = Get-BuildMode

# $app is a variable that determines whether the current app is a normal app (not test app, for instance)
if($app)
{
    # Setup compiler features to generate captions and LCGs
    if (!$parameters.ContainsKey("Features")) {
        $parameters["Features"] = @()
    }
    $parameters["Features"] += @("generateCaptions")

    # Setup compiler features to generate LCGs for the default build mode
    if($appBuildMode -eq 'Default') {
        $parameters["Features"] += @("lcgtranslationfile")
    }

    if($appBuildMode -eq 'Translated') {
        Import-Module $PSScriptRoot\AppTranslations.psm1
        Restore-TranslationsForApp -AppProjectFolder $parameters["appProjectFolder"]
    }

    if (($parameters.ContainsKey("EnableAppSourceCop") -and $parameters["EnableAppSourceCop"]) -or ($parameters.ContainsKey("EnablePerTenantExtensionCop") -and $parameters["EnablePerTenantExtensionCop"])) {
        # Breaking changes check is enabled, so we need to generate the AppSourceCop.json file and provide the baseline app file
        
        if($appBuildMode -eq 'Clean') {
            # For the clean build mode, compile the app to generate the default app file to use as a baseline

            $defaultAppParams = $parameters.Clone()

            # No need to generate the AppSourceCop.json file for the default app file
            $defaultAppParams.Remove("EnableAppSourceCop")
            $defaultAppParams.Remove("EnablePerTenantExtensionCop")

            # Wipe the preprocessor symbols (build in default mode)
            $defaultAppParams["preProcessorSymbols"] = @()

            $defaultAppFilePath = Compile-AppInBcContainer @defaultAppParams

            $defaultAppFilePath -match "(.*)_(.*)_(.*).app$" | Out-Null
            $defaultAppVersion = $Matches[3]

            $appSymbolsFolder = $parameters["appSymbolsFolder"]
            if (-not (Test-Path $appSymbolsFolder)) {
                New-Item -ItemType Directory -Path $appSymbolsFolder | Out-Null
            }
    
            # Copy the default app file to the app symbols folder to be used as a baseline
            Copy-Item -Path $defaultAppFilePath -Destination $appSymbolsFolder | Out-Null

            # Get name of the app from app.json
            $appJson = Join-Path $parameters["appProjectFolder"] "app.json"
            $applicationName = (Get-Content -Path $appJson | ConvertFrom-Json).Name

            # Generate the AppSourceCop.json file
            Import-Module $PSScriptRoot\GuardingV2ExtensionsHelper.psm1
            Update-AppSourceCopVersion -ExtensionFolder $parameters["appProjectFolder"] -AppName $applicationName -BaselineVersion $defaultAppVersion
        }
        else {
            # Restore the baseline app and generate the AppSourceCop.json file
            Import-Module $PSScriptRoot\GuardingV2ExtensionsHelper.psm1
            Enable-BreakingChangesCheck -AppSymbolsFolder $parameters["appSymbolsFolder"] -AppProjectFolder $parameters["appProjectFolder"] -BuildMode $appBuildMode | Out-Null
        }
    }
}

$appFile = Compile-AppInBcContainer @parameters

# Determine whether the current build is a CICD build
$CICDBuild = $env:GITHUB_WORKFLOW -and ($($env:GITHUB_WORKFLOW).Trim() -eq 'CI/CD')

if($CICDBuild) {
    # Create the artifacts folder for the app to place in the package
    . $PSScriptRoot\Package\CreateAppPackageOutput.ps1 -AppProjectFolder $parameters["appProjectFolder"] -BuildMode $appBuildMode -AppFile $appFile -ALGoProjectFolder $currentProjectFolder -IsTestApp:$(!$app)
}

# Return the app file path 
$appFile