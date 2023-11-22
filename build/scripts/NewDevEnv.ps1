<#
    Creates a new dev env.
#>
param(
    [Parameter(Mandatory = $false)]
    [string] $containerName = "BC-$(Get-Date -Format 'yyyyMMdd-HHmm')",

    [Parameter(Mandatory = $false)]
    [string] $userName = 'admin',

    [Parameter(Mandatory = $false)]
    [securestring] $password = 'P@ssword1',

    [Parameter(Mandatory = $true)]
    [string[]] $projects
)

$errorActionPreference = "Stop"; $ProgressPreference = "SilentlyContinue"; Set-StrictMode -Version 2.0
Import-Module "$PSScriptRoot/EnlistmentHelperFunctions.psm1"

if (-not (Get-Module -ListAvailable -Name "BCContainerHelper")) {
    Write-Host "BCContainerHelper module not found. Installing..."
    Install-Module -Name "BCContainerHelper" -Scope CurrentUser -AllowPrerelease -Force
}

$bcArtifactUrl = Get-ConfigValue -Key "artifact" -ConfigType AL-Go

[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', Justification = 'local build')]
$credential = New-Object -TypeName pscredential -ArgumentList $userName, $password

New-BcContainer `
    -accept_eula `
    -containerName 'test' `
    -artifactUrl $bcArtifactUrl `
    -accept_insiderEula `
    -auth UserPassword `
    -Credential $credential

$projects | ForEach-Object {
    $currentProject = $_

    if(Test-Pa)
}
Write-Host
