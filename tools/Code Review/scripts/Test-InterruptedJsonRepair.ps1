#Requires -Version 7.0
<#
.SYNOPSIS
    Regression tests for the interrupted/contaminated agent-JSON repair paths
    in Invoke-CopilotPRReview.ps1.

.DESCRIPTION
    The Copilot CLI occasionally fragments the agent's final findings-report
    JSON when its output stream is sliced by a tool-call boundary. Two distinct
    corruption shapes have been observed in production runner logs, both of
    which caused the parser to recover ZERO findings:

      1. Bare interior fence: the model re-opens a ```json fence in the middle
         of the JSON body (no TUI marker). The balanced-brace candidate stays
         structurally complete but is syntactically invalid because of the
         spliced fence line. Repair: Remove-StructuralFences.

      2. Placeholder-marker drift: the CLI injects a
         "Placeholder to satisfy parallel tool call requirement (shell)" block
         mid-string, then resumes in a fresh fence. The original repair matched
         the literal "...parallel tool requirement" wording, which drifted
         (the CLI added "call" and a "(shell)" suffix), so the repair silently
         no-opped. Repair: Repair-InterruptedAgentJson tolerant marker regex.

    This test extracts the three parser helpers from the orchestrator script via
    the PowerShell AST (so it can never drift from the real implementation) and
    asserts that both shapes parse back to the expected findings.

.NOTES
    Standalone (no Pester dependency). Exits non-zero on any failure so it can
    gate CI.
#>
[CmdletBinding()]
param(
    [string] $ScriptPath = (Join-Path $PSScriptRoot 'Invoke-CopilotPRReview.ps1')
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (-not (Test-Path -LiteralPath $ScriptPath)) {
    throw "Orchestrator script not found at: $ScriptPath"
}

# --- Load the parser helpers from the orchestrator without running main() -----
# The orchestrator executes top-level logic on load, so we extract just the
# pure functions we need via the AST and dot-source those.
$ast = [System.Management.Automation.Language.Parser]::ParseFile($ScriptPath, [ref]$null, [ref]$null)
$wanted = 'Find-BalancedJsonCandidates', 'Remove-StructuralFences', 'Repair-InterruptedAgentJson'
$funcs = $ast.FindAll(
    { param($n) $n -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $wanted -contains $n.Name },
    $true)
foreach ($name in $wanted) {
    if ($funcs.Name -notcontains $name) { throw "Could not locate function '$name' in $ScriptPath" }
}
Invoke-Expression (($funcs | ForEach-Object { $_.Extent.Text }) -join "`n`n")

$failures = [System.Collections.Generic.List[string]]::new()
function Assert-True([bool] $Condition, [string] $Message) {
    if ($Condition) { Write-Host "  PASS  $Message" -ForegroundColor Green }
    else { Write-Host "  FAIL  $Message" -ForegroundColor Red; $script:failures.Add($Message) | Out-Null }
}

# Mirror the first-stage extraction Parse-BCQualityReport performs, then return
# the first candidate (incl. de-fenced fallbacks) that yields valid JSON.
function Get-FirstParsedReport([string] $Output) {
    $repaired = Repair-InterruptedAgentJson -Output $Output
    $stripped = [regex]::Replace($repaired, "`e\[[\d;]*[A-Za-z]", '')
    $candidates = [System.Collections.Generic.List[string]]::new()
    foreach ($m in [regex]::Matches($stripped, '```(?:json)?\s*([\s\S]*?)\s*```')) { $candidates.Add($m.Groups[1].Value) | Out-Null }
    foreach ($b in (Find-BalancedJsonCandidates -Text $stripped)) { $candidates.Add($b) | Out-Null }
    if ($candidates.Count -eq 0) { $candidates.Add($stripped.Trim()) | Out-Null }
    $defenced = [System.Collections.Generic.List[string]]::new()
    foreach ($c in $candidates) { $clean = Remove-StructuralFences -Text $c; if ($clean -ne $c) { $defenced.Add($clean) | Out-Null } }
    foreach ($c in $defenced) { $candidates.Add($c) | Out-Null }
    foreach ($c in $candidates) {
        $t = $c.Trim(); if (-not $t) { continue }
        try { return ($t | ConvertFrom-Json -ErrorAction Stop) } catch { }
    }
    return $null
}

# --- Shape 1: bare interior ```json fence spliced into the JSON body ----------
$shape1 = @'
* Read entry.md
Here is the report:
```json
{
  "skill": { "id": "al-code-review" },
  "outcome": "completed",
  "findings": [
    { "id": "k/style/a.md", "severity": "major", "message": "top-level rollup finding",
      "from-sub-skill": "al-style-review", "references": [ { "path": "k/style/a.md" } ] }
  ],
  "sub-results": [
    { "skill": { "id": "al-style-review" }, "outcome": "completed",
      "summary": { "counts": { "major": 1 } }
```json
      ,
      "findings": [ { "id": "k/style/a.md", "severity": "major", "message": "leaf finding" } ] }
  ]
}
```
'@
Write-Host "`nShape 1: bare interior fence (no marker)" -ForegroundColor Cyan
$r1 = Get-FirstParsedReport -Output $shape1
Assert-True ($null -ne $r1) 'recovers a parseable report'
if ($r1) {
    Assert-True (@($r1.findings).Count -eq 1) "top-level findings recovered (got $(@($r1.findings).Count), expected 1)"
    Assert-True (@($r1.'sub-results').Count -eq 1) "sub-results recovered (got $(@($r1.'sub-results').Count), expected 1)"
}

# --- Shape 2: drifted placeholder marker + resume fence -----------------------
$shape2 = @'
* Read entry.md
```json
{
  "skill": { "id": "al-code-review" },
  "outcome": "completed",
  "findings": [
    { "id": "k/style/a.md", "severity": "major", "message": "this line is truncated mid-emi
● Placeholder to satisfy parallel tool call requirement (shell)
  │ echo "Resuming JSON output"
  └ 2 lines
```json
    { "id": "k/style/a.md", "severity": "major", "message": "fully re-emitted finding",
      "from-sub-skill": "al-style-review", "references": [ { "path": "k/style/a.md" } ] }
  ],
  "sub-results": []
}
```
'@
Write-Host "`nShape 2: drifted placeholder marker ('parallel tool call requirement (shell)')" -ForegroundColor Cyan
$r2 = Get-FirstParsedReport -Output $shape2
Assert-True ($null -ne $r2) 'recovers a parseable report'
if ($r2) {
    Assert-True (@($r2.findings).Count -eq 1) "truncated finding repaired to a single clean finding (got $(@($r2.findings).Count), expected 1)"
    Assert-True ([string]$r2.findings[0].message -eq 'fully re-emitted finding') 'partial pre-marker line discarded; full re-emission kept'
}

# --- Guard: a clean single-fence report is unaffected -------------------------
$clean = @'
```json
{ "skill": { "id": "al-code-review" }, "outcome": "completed",
  "findings": [ { "id": "k/style/a.md", "severity": "minor", "message": "ok",
    "from-sub-skill": "al-style-review", "references": [ { "path": "k/style/a.md" } ] } ],
  "sub-results": [] }
```
'@
Write-Host "`nGuard: clean single-fence report unaffected" -ForegroundColor Cyan
$r3 = Get-FirstParsedReport -Output $clean
Assert-True ($null -ne $r3 -and @($r3.findings).Count -eq 1) 'clean report still parses to 1 finding'

# --- Guard: a fenced code sample inside a string value is preserved -----------
$stringFence = @'
```json
{ "outcome": "completed",
  "findings": [ { "id": "k/style/a.md", "severity": "minor",
    "message": "sample", "suggested-code": "```al\nprocedure Foo()\n```",
    "from-sub-skill": "al-style-review", "references": [ { "path": "k/style/a.md" } ] } ],
  "sub-results": [] }
```
'@
Write-Host "`nGuard: code fence inside a JSON string value is preserved" -ForegroundColor Cyan
$r4 = Get-FirstParsedReport -Output $stringFence
Assert-True ($null -ne $r4) 'string-internal fence report parses'
if ($r4) {
    Assert-True ([string]$r4.findings[0].'suggested-code' -like '*```al*') 'fenced code sample survived inside the string value'
}

# --- Real-artifact regression fixtures ----------------------------------------
# Captured stdout from two production runner runs that posted ZERO findings on
# the byte-identical sample diff (the regression). These are the exact bytes the
# live runner failed to parse; the patched parser must recover the full report.
#   run 26953567514: drifted placeholder marker ("parallel tool call requirement
#                    (shell)") -> 25 findings.
#   run 26956415628 (PR #47): bare interior ```json fence -> 22 findings.
# The unpatched main parser returned 0 for both (measured).
$fixtureDir = Join-Path (Split-Path -Parent $PSScriptRoot) 'tests/fixtures'
$realFixtures = @(
    @{ Run = '26953567514'; File = 'run-26953567514-al-code-review-raw.txt'; Findings = 25; SubResults = 6 },
    @{ Run = '26956415628'; File = 'run-26956415628-al-code-review-raw.txt'; Findings = 22; SubResults = 6 }
)
Write-Host "`nReal runner artifacts (regression fixtures)" -ForegroundColor Cyan
foreach ($fx in $realFixtures) {
    $path = Join-Path $fixtureDir $fx.File
    if (-not (Test-Path -LiteralPath $path)) { Assert-True $false "fixture present: $($fx.File)"; continue }
    $raw = Get-Content -LiteralPath $path -Raw
    $rep = Get-FirstParsedReport -Output $raw
    Assert-True ($null -ne $rep) "run $($fx.Run): recovers a parseable report (was 0 on unpatched parser)"
    if ($rep) {
        $fc = @($rep.findings).Count
        $sc = @($rep.'sub-results').Count
        Assert-True ($fc -eq $fx.Findings) "run $($fx.Run): top-level findings recovered (got $fc, expected $($fx.Findings))"
        Assert-True ($sc -eq $fx.SubResults) "run $($fx.Run): sub-results recovered (got $sc, expected $($fx.SubResults))"
    }
}

Write-Host ''
if ($failures.Count -gt 0) {
    Write-Host "FAILED: $($failures.Count) assertion(s) failed." -ForegroundColor Red
    exit 1
}
Write-Host 'All interrupted-JSON repair regression tests passed.' -ForegroundColor Green
exit 0
