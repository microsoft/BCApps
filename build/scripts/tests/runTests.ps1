$errorActionPreference = "Stop"; $ProgressPreference = "SilentlyContinue"; Set-StrictMode -Version 2.0

$result = Invoke-Pester @(Get-ChildItem -Path (Join-Path $PSScriptRoot "*.Test.ps1")) -passthru

if ($result.FailedCount -gt 0) {
    throw "$($result.FailedCount) tests are failing"
}