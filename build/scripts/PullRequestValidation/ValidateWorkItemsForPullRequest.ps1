using module .\PRValidator.class.psm1

param(
    [Parameter(Mandatory = $true)]
    [string] $PullRequestNumber,
    [Parameter(Mandatory = $true)]
    [string] $Repository
    )

# Set error action
$ErrorActionPreference = "Stop"

Write-Host "Validating PR $PullRequestNumber"

$prValidator = [PRValidator]::new($PullRequestNumber, $Repository)
$prValidator.ValidateIssues()

Write-Host "PR $PullRequestNumber validated successfully"
