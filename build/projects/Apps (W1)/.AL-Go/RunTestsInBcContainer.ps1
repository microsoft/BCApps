Param(
    [Hashtable]$parameters
)

try {
$script = Join-Path $PSScriptRoot "../../../scripts/RunTestsInBcContainer.ps1" -Resolve
. $script -parameters $parameters
} catch {
    Write-Host "-Failed-"
}
