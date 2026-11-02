param(
    [Parameter(Mandatory = $true)][string]$RepositoryRoot,
    [Parameter(Mandatory = $true)][string]$ALGoRoot,
    [Parameter(Mandatory = $true)][string]$ResultPath
)

$ErrorActionPreference = "Stop"
$env:GITHUB_WORKSPACE = $RepositoryRoot
$env:GITHUB_REPOSITORY = "microsoft/BCApps"
$env:GITHUB_REF_NAME = "spetersen-microsoft-w1-altool-verification"
$env:GITHUB_WORKFLOW = "CI/CD"
Import-Module BcContainerHelper -DisableNameChecking
. (Join-Path $ALGoRoot "Actions\AL-Go-Helper.ps1")
Import-Module (Join-Path $ALGoRoot "Actions\DetermineProjectsToBuild\DetermineProjectsToBuild.psm1") -DisableNameChecking

$results = @(
    foreach ($trigger in @("workflow_dispatch", "push", "merge_group")) {
        $env:GITHUB_EVENT_NAME = $trigger
        $settings = ReadSettings -baseFolder $RepositoryRoot -repoName "microsoft/BCApps" `
            -workflowName "CI/CD" -branchName $env:GITHUB_REF_NAME -trigger $trigger
        $env:Settings = ConvertTo-Json -InputObject $settings -Depth 99 -Compress
        $projects, $modified, $selected, $dependencies, $order = Get-ProjectsToBuild `
            -baseFolder $RepositoryRoot -buildAllProjects $true -maxBuildDepth 2
        [pscustomobject]@{
            Shell = $PSVersionTable.PSVersion.ToString()
            Trigger = $trigger
            Projects = @($projects)
            Selected = @($selected)
            Dependencies = $dependencies
            BuildOrder = @($order)
        }
    }
)
ConvertTo-Json -InputObject $results -Depth 99 | Set-Content -LiteralPath $ResultPath -Encoding UTF8
