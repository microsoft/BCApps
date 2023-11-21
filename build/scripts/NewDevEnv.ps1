<#
    Creates a new dev env.
#>
param(
    [Parameter(Mandatory = $false)]
    [string] $containerName = "BC-$(Get-Date -Format 'yyyyMMdd-HHmm')",
    [Parameter(Mandatory = $false)]
    [pscredential] $credential = $null,
    [switch] $accept_insiderEula
)

$errorActionPreference = "Stop"; $ProgressPreference = "SilentlyContinue"; Set-StrictMode -Version 2.0

Import-Module "$PSScriptRoot/EnlistmentHelperFunctions.psm1"
$bcArtifact = Get-ConfigValue -Key "artifact" -ConfigType AL-Go


Write-Host
