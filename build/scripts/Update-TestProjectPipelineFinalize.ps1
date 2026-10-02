<#
.SYNOPSIS
    Generates the success-only finalizer override for projects using shared container setup.
.DESCRIPTION
    Run with -Check to validate committed wrappers without modifying them.
#>
param(
    [string]$ProjectsPath = (Join-Path $PSScriptRoot '..\projects'),
    [switch]$Check
)

$ErrorActionPreference = 'Stop'
$wrapper = ". (Join-Path `$PSScriptRoot '../../../scripts/PipelineFinalize.ps1' -Resolve)`n"
$projects = @(Get-ChildItem -LiteralPath $ProjectsPath -Directory | Where-Object {
    Test-Path -LiteralPath (Join-Path $_.FullName '.AL-Go\NewBcContainer.ps1') -PathType Leaf
})
if ($projects.Count -eq 0) {
    throw 'No test container project overrides were found.'
}
foreach ($project in $projects) {
    $path = Join-Path $project.FullName '.AL-Go\PipelineFinalize.ps1'
    $current = if (Test-Path -LiteralPath $path -PathType Leaf) {
        [IO.File]::ReadAllText($path).Replace("`r`n", "`n")
    } else { '' }
    if ($current -ne $wrapper) {
        if ($Check) {
            throw "PipelineFinalize override is missing or outdated for $($project.Name). Run Update-TestProjectPipelineFinalize.ps1."
        }
        [IO.File]::WriteAllText($path, $wrapper, [Text.UTF8Encoding]::new($false))
    }
}
