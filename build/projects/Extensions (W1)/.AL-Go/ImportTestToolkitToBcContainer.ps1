[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'parameters', Justification = 'The parameter is not used, but it''s script needs to match this format')]
Param(
    [hashtable] $parameters
)

$scriptPath = Join-Path $PSScriptRoot "../../../scripts/ImportTestToolkitToBcContainer.ps1" -Resolve
. $scriptPath -parameters $parameters