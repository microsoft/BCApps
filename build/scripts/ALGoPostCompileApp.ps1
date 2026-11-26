Param(
    [string[]] $appFiles,
    [string] $appType,
    [hashtable] $compilationParams
)

if ($appType -ne 'app' -or $env:BC_APPLICATION_API_VALIDATION -ne 'true') { return }

if (-not $env:GITHUB_WORKSPACE) { throw 'GITHUB_WORKSPACE is required for aggregate API validation.' }
Import-Module (Join-Path $env:GITHUB_WORKSPACE 'build\scripts\ApplicationApiValidation.psm1' -Resolve)
Complete-ApplicationApiValidation -CompilationParameters $compilationParams -AppFiles $appFiles
