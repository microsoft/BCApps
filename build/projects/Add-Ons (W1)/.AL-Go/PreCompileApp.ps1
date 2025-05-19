Param(
    [string] $appType,
    [ref] $compilationParams
)

if ($ENV:BuildMode -eq 'Clean') {
    Import-Module (Join-Path $PSScriptRoot "../../../scripts/AppExtensionsHelper.psm1" -Resolve)
    $scriptPath = Join-Path $PSScriptRoot "../../../scripts/PreCompileApp.ps1" -Resolve
    . $scriptPath -parameters $compilationParams -appType $appType -recompileDependencies (Get-ExternalDependencies)
}