Param(
    [string] $appType,
    [ref] $compilationParams
)

if ($ENV:BuildMode -eq 'Clean') {

    # If useProjectDependencies is set to false, we need to remove the app symbols folder so we recompile everything.
    $settings = $env:Settings | ConvertFrom-Json
    if ($settings.useProjectDependencies -eq $false) {
        $symbolsFolder = $compilationParams.Value["appSymbolsFolder"]
        if (Test-Path $symbolsFolder) {
            Remove-Item -Path $symbolsFolder\* -Recurse -Force -Verbose
        }
    }

    Import-Module (Join-Path $PSScriptRoot "../../../scripts/AppExtensionsHelper.psm1" -Resolve)
    $scriptPath = Join-Path $PSScriptRoot "../../../scripts/PreCompileApp.ps1" -Resolve
    . $scriptPath -parameters $compilationParams -appType $appType -recompileDependencies (Get-ExternalDependencies)
}