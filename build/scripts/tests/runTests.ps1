$errorActionPreference = "Stop"; $ProgressPreference = "SilentlyContinue"; Set-StrictMode -Version 2.0

$result = Invoke-Pester @(Get-ChildItem -Path (Join-Path $PSScriptRoot "..") -Filter "*.Test.ps1" -Recurse) -passthru

if ($result.FailedCount -gt 0) {
    throw "$($result.FailedCount) tests are failing"
}