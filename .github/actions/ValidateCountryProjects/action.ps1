$repoRoot = & git rev-parse --show-toplevel
$result = & "$repoRoot/eng\CI\Update-CountryProjectSettings.ps1" -Validate
if ($result -eq $false) {
    Write-Host "::error::Country project settings are out of date. Run 'eng\CI\Update-CountryProjectSettings.ps1' and commit the changes."
    exit 1
}
