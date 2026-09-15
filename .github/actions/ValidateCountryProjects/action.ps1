$repoRoot = & git rev-parse --show-toplevel
$result = & "$repoRoot/build/scripts/Update-CountryProjectSettings.ps1" -Validate
if ($result -eq $false) {
    Write-Host "::error::Country project settings are out of date. Run 'build/scripts/Update-CountryProjectSettings.ps1' and commit the changes."
    exit 1
}
