$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'Contract.psm1') -Force
Assert-ExpandedApiDispatch
$proof = Get-Content (Join-Path $PSScriptRoot 'source-overlay.json') -Raw | ConvertFrom-Json
$patch = Join-Path $PSScriptRoot 'source-overlay.patch'
if ((Get-FileHash -LiteralPath $patch).Hash.ToLowerInvariant() -cne $proof.overlaySha256) {
    throw 'Diagnostic source overlay digest mismatch.'
}
git merge-base --is-ancestor $proof.base HEAD
if ($LASTEXITCODE -ne 0) { throw 'The merged external revert must remain an ancestor.' }
git diff --exit-code $proof.base HEAD -- src
if ($LASTEXITCODE -ne 0) { throw 'Source changed since reviewed post-revert base; re-review rather than overwrite it.' }
git diff --exit-code HEAD
if ($LASTEXITCODE -ne 0) { throw 'StageSource requires a clean, dedicated CI checkout.' }
git apply --check --index $patch
if ($LASTEXITCODE -ne 0) { throw 'Source overlay does not apply exactly; no conflict resolution or fallback is allowed.' }
git apply --index $patch
if ($LASTEXITCODE -ne 0) { throw 'Source overlay application failed.' }
$tree = git write-tree
if ($LASTEXITCODE -ne 0) { throw 'Cannot resolve compiled source tree.' }
$sourceTree = git rev-parse "${tree}:src"
if ($LASTEXITCODE -ne 0 -or $sourceTree -cne $proof.sourceTree) { throw 'Composed AL source differs from reviewed overlay.' }
@{
    sourceHead = $env:GITHUB_SHA; sourceTree = $sourceTree; overlaySha256 = $proof.overlaySha256
    sourceBase = $proof.base; runId = $env:GITHUB_RUN_ID; attempt = 1; compiled = $false
} | ConvertTo-Json
