<#
.SYNOPSIS
    Verifies the currently used AL-Go version is approved.
#>
Param(
)

Import-Module -Name $PSScriptRoot\EnlistmentHelperFunctions.psm1

$baseFolder = Get-BaseFolder
$alGoSettingsPath = Join-Path $baseFolder '.github\AL-Go-Settings.json'

$alGoSettings = Get-Content -Path $alGoSettingsPath -Raw | ConvertFrom-Json

if(-not ($alGoSettings.PSObject.Properties.Name -contains 'templateUrl')) {
    throw "AL-Go settings file does not contain the 'templateUrl' property"
}

$alGoTemplateUrl = $alGoSettings.templateUrl
$alGoTemplate = "https://github.com/microsoft/AL-Go-PTE@(.*)"

if($alGoTemplateUrl -notmatch $alGoTemplate) {
    throw "AL-Go template URL '$alGoTemplateUrl' is not in the expected format: $alGoTemplate"
}

$branch = $Matches[1]

Write-Host "Checking if AL-Go template branch '$branch' is protected"
$protectedBranches = gh api -H "Accept: application/vnd.github+json" -H "X-GitHub-Api-Version: 2022-11-28" /repos/microsoft/AL-Go-PTE/branches | ConvertFrom-Json | Where-Object { $_.protected }

if($protectedBranches.name -notcontains $branch) {
    throw "AL-Go template branch '$branch' is not protected"
}

Write-Host "AL-Go template $alGoTemplateUrl is approved" -ForegroundColor Green
