Param(
    [string] $appType,
    [ref] $compilationParams
)

if ($ENV:BuildMode -eq 'Clean') {
    Import-Module (Join-Path $PSScriptRoot "../../../scripts/AppExtensionsHelper.psm1" -Resolve)
    $scriptPath = Join-Path $PSScriptRoot "../../../scripts/PreCompileApp.ps1" -Resolve

    $symbolsPath = Join-Path $compilationParams.Value["compilerFolder"] 'symbols'
    if (Test-Path $symbolsPath) {
        # Remove all .app files except System.app in the symbols folder from the compiler folder
        # This is to ensure that we don't end up using any of those apps as dependencies in the clean build
        $appFiles = Get-ChildItem -Path $symbolsPath -Filter *.app -Recurse | Where-Object { $_.Name -ne 'System.app' }
        foreach ($appFile in $appFiles) {
            Remove-Item -Path $appFile.FullName -Force
        }
    }

    . $scriptPath -parameters $compilationParams -appType $appType -recompileDependencies (Get-ExternalDependencies)
}