# Select changed apps and their dependents

`Get-AffectedWorkspaceApps` in `build\scripts\BuildOptimization.psm1` accepts a
complete, resolved AL workspace and changed app IDs. It returns the changed apps
plus every in-workspace app that transitively depends on them, including test apps.
It does not change CI/test dispatch or compile anything.

## Usage

Use PowerShell 7. The workspace must include unchanged apps and tests as well as
changed apps; otherwise omitted dependents cannot be discovered. Use one country
context at a time, with the appropriate resolved localized projects rather than
multiple versions of the same app.

If needed, Microsoft's AL Development Tools CLI can create the workspace from
explicit project roots. For example, from the BCApps repository root:

```powershell
$project = Resolve-Path '.\build\projects\Apps DK'
$settings = Get-Content (Join-Path $project '.AL-Go\settings.json') -Raw | ConvertFrom-Json
$folders = @($settings.appFolders) + @($settings.testFolders)
$folders = @($folders | ForEach-Object {
    $path = (Resolve-Path (Join-Path $project $_) -ErrorAction Stop).Path
    [System.IO.Path]::GetRelativePath((Get-Location).Path, $path)
} | Sort-Object -Unique)

$workspace = Join-Path $env:TEMP 'apps-dk.code-workspace'
al workspace create $workspace @folders
if ($LASTEXITCODE -ne 0) { throw 'AL workspace creation failed.' }

Import-Module .\build\scripts\BuildOptimization.psm1
$apps = @(Get-AffectedWorkspaceApps -WorkspaceFile $workspace `
    -ChangedAppIds @('e1d97edc-c239-46b4-8d84-6368bdf67c8b'))
$apps | Format-Table Id, Name, Path
```

The helper itself does not require ALTool. It reads workspace JSON and app
manifests, not the Markdown produced by `al workspace map`.

## Contract

- Each result has `Id` (normalized GUID), `Name`, and `Path` (absolute project
  directory). Results are deduplicated and sorted by app ID, not build order.
- For `A depends on B`, changing B includes A, not the other way around. A changed
  leaf does not pull in its dependencies.
- Both `dependencies[]` and `application` declarations contribute edges. An
  `application` declaration refers to the in-workspace Application app
  (`c1335042-3002-4257-bf8a-75c898ccb1b8`), not directly to Base Application.
- External dependency IDs are reported in a warning and are not traversed.
  Include all relevant in-repo dependency bridges in the workspace.
- Workspace folder paths are relative to the workspace file. Repeated references
  to the same project directory are harmless; distinct directories sharing an app
  ID are rejected rather than choosing a localization arbitrarily.
- Unknown/invalid changed IDs, unreadable manifests, and malformed graph fields
  are terminating errors. Inputs are validated before any result is emitted.
- Empty changed input returns no apps. Cycles, diamonds, duplicate changed IDs,
  and overlapping changed sets are supported.

This is the declared transitive-dependent closure within the workspace, not a
guarantee of complete regression coverage.

## Focused tests

```powershell
Invoke-Pester -Path .\build\scripts\tests\AffectedWorkspaceApps.Test.ps1 -Output Detailed
```
