Param(
    [string] $appType,
    [ref] $compilationParams
)

if ($ENV:BuildMode -eq 'Clean') {
    $externalDependencies = (Get-Content (Join-Path $PSScriptRoot "customSettings.json" -Resolve) | ConvertFrom-Json).ExternalAppDependencies
    $settings = Get-Content (Join-Path $PSScriptRoot "settings.json" -Resolve) | ConvertFrom-Json

    if ($settings.useProjectDependencies -eq $false) {
        # Remove everything in the app symbols folder so we recompile everything. 
        $symbolsFolder = $compilationParams.Value["appSymbolsFolder"]
        if (Test-Path $symbolsFolder) {
            Remove-Item -Path $symbolsFolder\* -Recurse -Force -Verbose
        }
    }

    $scriptPath = Join-Path $PSScriptRoot "../../../scripts/PreCompileApp.ps1" -Resolve
    . $scriptPath -parameters $compilationParams -appType $appType -recompileDependencies $externalDependencies
}