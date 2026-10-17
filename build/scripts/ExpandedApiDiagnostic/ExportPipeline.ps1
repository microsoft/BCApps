$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'Context.psm1')
$context = Get-ExpandedContext
$project = Join-Path $env:GITHUB_WORKSPACE $context.project
if (Test-Path $project) {
    foreach ($file in Get-ChildItem -LiteralPath $project -File -Recurse -Force) {
        if ($file.Extension -notin @('.xml', '.log', '.evtx') -and $file.Name -ne 'BuildOutput.txt') { continue }
        $relative = [IO.Path]::GetRelativePath($project, $file.FullName)
        $destination = Join-Path $context.output "pipeline\$relative"
        $null = New-Item -ItemType Directory -Path (Split-Path $destination -Parent) -Force
        Copy-Item -LiteralPath $file.FullName -Destination $destination
    }
}
