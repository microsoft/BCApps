<#
Creates a new dev env.
#>
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingConvertToSecureStringWithPlainText', '', Justification = 'local build')]
param(
    [Parameter(Mandatory = $false)]
    [string] $containerName = "BC-$(Get-Date -Format 'yyyyMMdd')",

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
$containerExist = $null -ne $(docker ps -q -f name="$containerName")

if (-not $containerExist) {
    Write-Host "Creating container $containerName"

    $bcArtifactUrl = Get-ConfigValue -Key "artifact" -ConfigType AL-Go
    $credential = New-Object -TypeName pscredential -ArgumentList $userName, $password

    $newContainerParams = @{
        "accept_eula" = $true
        "accept_insiderEula" = $true
        "containerName" = "BC-$(Get-Date -Format 'yyyyMMdd')"
        "artifactUrl" = $bcArtifactUrl
        "Credential" = $credential
        "auth" = "UserPassword"
        "additionalParameters" = @("--volume ""$(Get-BaseFolder):c:\sources""")
    }

    New-BcContainer @newContainerParams
}

$projects | ForEach-Object {
    $currentProject = $_

    if(-not (Test-Path -Path (Join-Path $currentProject 'app.json'))) {
        Write-Host "app.json not found in $currentProject. Skipping..."
        return
    }

    $compilationParameters = @{
        "containerName" = $containerName
        "tenant" = $tenant
        "credential" = $credential
        "appFile" = $appFile
        "skipVerification" = $true
        "sync" = $true
        "install" = $true
        "useDevEndpoint" = $useDevEndpoint
    }

    Write-Host "Adding $currentProject to $containerName"
    Compile-AppInBcContainer -containerName $containerName -projectPath $currentProject
}
Write-Host
