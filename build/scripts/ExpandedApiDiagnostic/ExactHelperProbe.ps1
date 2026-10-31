param(
    [Parameter(Mandatory)][string]$HelperModulePath,
    [Parameter(Mandatory)][string]$FixtureRoot,
    [Parameter(Mandatory)][string]$AppArchivePath,
    [Parameter(Mandatory)][string]$ExpectedArchiveSha256,
    [Parameter(Mandatory)][string]$CachedAlExtensionPath
)
$ErrorActionPreference = 'Stop'
if (Get-Module BcContainerHelper -All) { throw 'Run this probe in a fresh pwsh -NoProfile process.' }
if (Test-Path $FixtureRoot) { throw 'Probe fixture must be a new, explicitly authorized directory.' }
$FixtureRoot = [IO.Path]::GetFullPath($FixtureRoot)
if (-not $FixtureRoot.StartsWith(([IO.Path]::GetFullPath((Get-Location).Path).TrimEnd('\') + '\'), [StringComparison]::OrdinalIgnoreCase)) {
    throw 'Probe fixture must be below the working directory, not a system or remote location.'
}
$hostRoot = Join-Path $FixtureRoot 'helper-host'
$output = Join-Path $FixtureRoot 'expanded-api-output'
$null = New-Item -ItemType Directory -Path (Join-Path $hostRoot 'Extensions'), $output -Force
$config = Join-Path $FixtureRoot 'helper-config.json'
@{ hostHelperFolder = $hostRoot; containerHelperFolder = $hostRoot; UseVolumes = $false
    bcartifactsCacheFolder = (Join-Path $FixtureRoot 'artifacts'); bcNuGetCacheFolder = (Join-Path $FixtureRoot 'nuget')
    MicrosoftTelemetryConnectionString = ''; PartnerTelemetryConnectionString = ''
    SendExtendedTelemetryToMicrosoft = $false; useWinRmSession = 'never' } | ConvertTo-Json | Set-Content $config
$env:BcContainerHelperPath = $HelperModulePath
$env:GITHUB_WORKSPACE = $FixtureRoot
$env:BC_EXPANDED_OUTPUT = $output
$env:GITHUB_REPOSITORY = 'microsoft/BCApps'
$env:GITHUB_REF = 'refs/heads/features/653393-expanded-api-helper-scope'
$env:GITHUB_EVENT_NAME = 'workflow_dispatch'
$env:GITHUB_RUN_ATTEMPT = '1'
$env:GITHUB_RUN_ID = '900000000000'
$env:BC_EXPANDED_COUNTRY = 'W1'
& (Join-Path $PSScriptRoot 'HelperPreflight.ps1') -Boundary Cold -ConfigFiles @($config)
$module = Get-Module BcContainerHelper
$configuration = & $module { $bcContainerHelperConfig }
if ($configuration.hostHelperFolder -ne $hostRoot -or $configuration.MicrosoftTelemetryConnectionString -or
    $configuration.PartnerTelemetryConnectionString) { throw 'Local isolated helper configuration was not honored.' }
$configuration.ExpandedScopeSentinel = 'preserve-warm-state'
& (Join-Path $PSScriptRoot 'HelperPreflight.ps1') -Boundary Warm
if (-not [object]::ReferenceEquals($module, (Get-Module BcContainerHelper)) -or
    -not [object]::ReferenceEquals($configuration, (& $module { $bcContainerHelperConfig })) -or
    $configuration.ExpandedScopeSentinel -ne 'preserve-warm-state') { throw 'Warm import reset the existing AL-Go-style configuration.' }
Import-Module (Join-Path $PSScriptRoot 'Producer.psm1')
$producer = Get-Module Producer
$siblingCommands = @(& $producer {
    foreach ($name in @('Get-TestsFromBcContainer', 'Run-TestsInBcContainer', 'Get-BcContainerServerConfiguration')) {
        $command = Get-Command $name -ErrorAction Stop
        @{ name = $name; providerPath = $command.Module.Path }
    }
})
if (@($siblingCommands | Where-Object providerPath -NE $module.Path).Count) { throw 'Producer module cannot resolve the same actual helper provider.' }

if ((Get-FileHash $AppArchivePath).Hash.ToLowerInvariant() -cne $ExpectedArchiveSha256) { throw 'Cached app archive differs from parent-verified digest.' }
$archive = [IO.Compression.ZipFile]::OpenRead($AppArchivePath)
try {
    $entries = @($archive.Entries | Where-Object { $_.FullName -match '^Microsoft_Test Runner_[^\\/]+\.app$' })
    if ($entries.Count -ne 1) { throw 'Exactly one cached compiled Test Runner package is required.' }
    $app = Join-Path $FixtureRoot $entries[0].Name
    [IO.Compression.ZipFileExtensions]::ExtractToFile($entries[0], $app)
} finally { $archive.Dispose() }
# Get-AppJsonFromAppFile uses the helper's AL-language cache. Point only this
# process's cache to an existing reader; do not download latest or compile AL.
$toolRoot = Join-Path $FixtureRoot 'cached-reader'
$null = New-Item -ItemType Directory $toolRoot
$link = Join-Path $toolRoot 'extension'
$null = New-Item -ItemType Junction -Path $link -Target (Resolve-Path $CachedAlExtensionPath).Path
try {
    & $module { param($path) $script:AlLanguageExtenssionPath = @($path, $path) } $toolRoot
    $metadata = Get-AppJsonFromAppFile -appFile $app
    if ($metadata.id -ne '23de40a6-dfe8-4f80-80db-d70f83ce8caf' -or $metadata.name -ne 'Test Runner') { throw 'Real package metadata mismatch.' }
    $tool = Join-Path $CachedAlExtensionPath 'bin\win32\altool.exe'
    $readerHash = (Get-FileHash $tool).Hash.ToLowerInvariant()
} finally {
    (Get-Item -LiteralPath $link).Delete()
}

$name = "bcbuildprojectsExpandedBuildW1$($env:GITHUB_RUN_ID)compiler"
$parameters = @{ containerName = $name; artifactUrl = 'https://bcinsider-fvh2ekdjecfjd6gk.b02.azurefd.net/sandbox/30.0.55683.0/w1'; vsixFile = '' }
& (Join-Path $PSScriptRoot 'Compiler.ps1') -Phase Before -Parameters $parameters
$receipt = Get-Content (Join-Path $output 'compiler-ownership.json') -Raw | ConvertFrom-Json
if ($receipt.folder -ne (Join-Path $hostRoot "compiler\$name")) { throw 'Local fixture ownership mismatch.' }
$null = New-Item -ItemType Directory -Path $receipt.folder
Set-Content (Join-Path $receipt.folder 'probe-owned.txt') 'Only this explicit local fixture is authorized for cleanup.'
& (Join-Path $PSScriptRoot 'Compiler.ps1') -Phase Cleanup
$cleanup = Get-Content (Join-Path $output 'compiler-cleanup.json') -Raw | ConvertFrom-Json
if (-not $cleanup.absenceVerified -or $cleanup.compilerRemaining -ne $false -or (Test-Path $receipt.folder)) { throw 'Real local compiler cleanup failed.' }
@{
    exactVersion = (& $module { $bcContainerHelperVersion }); modulePath = $module.Path
    coldCallerCommandsResolved = $true; warmModuleAndConfigurationPreserved = $true
    producerModuleCommands = $siblingCommands
    reader = @{ path = $tool; sha256 = $readerHash; downloaded = $false; operation = 'GetPackageManifest only' }
    package = @{ sourceArchiveSha256 = $ExpectedArchiveSha256; file = $app; sha256 = (Get-FileHash $app).Hash.ToLowerInvariant(); metadata = $metadata }
    cleanup = $cleanup; remoteCompilerCleanup = 'UNKNOWN; not inspected or changed'
    ALCompiled = $false; NSTOrDockerInvoked = $false
} | ConvertTo-Json -Depth 15 | Set-Content (Join-Path $FixtureRoot 'exact-helper-result.json')
