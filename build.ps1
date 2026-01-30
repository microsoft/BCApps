<#
    .Synopsis
        Build script for AL-Go projects
    .Description
        This script will run localDevEnv.ps1 in the specified AL-Go project
    .Parameter ALGoProject
        The name of the AL-Go project
    .Parameter AutoFill
        If specified, the script will generate a random password and use that for the credential
    .Example
        .\build.ps1 -ALGoProject "System Application"
        .\build.ps1 -ALGoProject "Test Stability Tools" -AutoFill
#>
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '', Justification = 'local build')]
param
(
    [Parameter(Mandatory=$true)]
    [string] $ALGoProject,
    [switch] $AutoFill
)

$ErrorActionPreference = "Stop"

if (-not (Get-Module -ListAvailable -Name "BCContainerHelper")) {
    Write-Host "BCContainerHelper module not found. Installing..."
    Install-Module -Name "BCContainerHelper" -Scope CurrentUser -AllowPrerelease -Force
}

if ($AutoFill) {
    Add-Type -AssemblyName System.Web

    [securestring] $securePassword = ConvertTo-SecureString -String $([System.Web.Security.Membership]::GeneratePassword(20, 5)) -AsPlainText -Force
    $credential = New-Object -TypeName pscredential -ArgumentList admin, $securePassword
    $licenseFileUrl = 'none'
    $containerName = "bcserver"
    $auth = "UserPassword"
}

$scriptPath = Join-Path $PSScriptRoot "build\projects\$ALGoProject\.AL-Go\localDevEnv.ps1" -Resolve
& $scriptPath -containerName $containerName -auth $auth -credential $credential -licenseFileUrl $licenseFileUrl

if ($LASTEXITCODE -ne 0) {
    throw "Failed to build"
}