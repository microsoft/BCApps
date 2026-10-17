param([hashtable]$Parameters)
$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'Context.psm1')
$context = Get-ExpandedContext
Import-ExpandedHelper -RequiredCommands @{
    'New-BcContainer' = @('containerName', 'useGenericImage', 'platformArtifactUrl')
    'Test-BcContainer' = @('containerName')
}
if ($Parameters.containerName -ne $context.container -or (Test-BcContainer -containerName $context.container)) {
    throw 'Container is not the unique, absent lane-owned destination.'
}
$settings = $env:Settings | ConvertFrom-Json
if ($settings.companyName -cne $context.lane.settings.company -or
    $settings.testType -cne $context.lane.settings.testType -or
    $settings.numberOfTenantsForTesting -ne $context.cell.configuration.mounts.Count -or
    $settings.enableCleanTestCodeunitExecution -ne $true -or
    $settings.enableTaskScheduler -ne $context.lane.settings.taskScheduler -or
    $Parameters.auth -notin @('UserPassword', 'NavUserPassword') -or -not $Parameters.credential) {
    throw 'Effective lane setup/authentication differs from the declared experiment.'
}
$Parameters.useGenericImage = $context.pins.image
$Parameters.memoryLimit = '16G'
$Parameters.multitenant = $true
@{ run = $env:GITHUB_RUN_ID; sourceHead = $env:GITHUB_SHA; identity = $context.cell.identity
    lane = $context.lane.id; container = $context.container; createdUtc = [DateTime]::UtcNow.ToString('o') } |
    ConvertTo-Json | Set-Content (Join-Path $context.output 'ownership.json')
# Existing password-file provisioning and server configuration are retained.
. (Join-Path $PSScriptRoot '..\NewBcContainer.ps1') -parameters $Parameters
$inspect = @(docker inspect $context.container | ConvertFrom-Json)[0]
if ($LASTEXITCODE -ne 0 -or $inspect.HostConfig.Memory -ne $context.pins.memoryBytes) { throw 'Actual Docker memory differs.' }
$base = @(docker image inspect $context.pins.image | ConvertFrom-Json)[0]
if ($LASTEXITCODE -ne 0) { throw 'Pinned generic image is not available for actual-layer proof.' }
$actual = @(docker image inspect $inspect.Image | ConvertFrom-Json)[0]
if ($LASTEXITCODE -ne 0 -or $actual.RootFS.Layers.Count -lt $base.RootFS.Layers.Count) { throw 'Actual image layers missing.' }
for ($i = 0; $i -lt $base.RootFS.Layers.Count; $i++) {
    if ($base.RootFS.Layers[$i] -cne $actual.RootFS.Layers[$i]) { throw 'Container was not built on the pinned image layers.' }
}
@{ container = $context.container; actualContainerImageId = $inspect.Image
    verifiedGenericImage = $context.pins.image; genericImageId = $base.Id
    memoryBytes = $inspect.HostConfig.Memory; nanoCpus = $inspect.HostConfig.NanoCpus
    cpuCount = $inspect.HostConfig.CpuCount; cpuPercent = $inspect.HostConfig.CpuPercent
    host = $env:COMPUTERNAME; runner = $env:RUNNER_NAME; genericLayerPrefixVerified = $true } |
    ConvertTo-Json -Depth 8 | Set-Content (Join-Path $context.output 'docker.json')
Import-Module (Join-Path $PSScriptRoot 'TenantResources.psm1')
Get-SqlTenantResourceSample -ContainerName $context.container -Phase container-created |
    ConvertTo-Json -Depth 12 | Set-Content (Join-Path $context.output 'container-setup-resource.json')
