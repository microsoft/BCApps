[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Justification = 'Fresh-process offline network trap must count missed mocks across module boundaries; removed in finally.')]
param(
    [Parameter(Mandatory)][string]$PinnedALGoSource,
    [Parameter(Mandatory)][string]$RegistryFile,
    [Parameter(Mandatory)][string]$RegistryArchive,
    [Parameter(Mandatory)][string]$ResultPath,
    [string[]]$TestNames = @()
)
$ErrorActionPreference = 'Stop'
if (Get-Command Invoke-RestMethod, Invoke-WebRequest | Where-Object CommandType -NE Cmdlet) {
    throw 'Run offline validation in a fresh PowerShell process without existing HTTP function overrides.'
}
$global:ExpandedOfflineNetworkAttempts = [Collections.Generic.List[string]]::new()
# A missed mock must fail locally, never reach a remote API. These are process-local.
function global:Invoke-RestMethod {
    param($Uri, $Headers, $Method, $Body)
    $null = $Headers, $Body
    $global:ExpandedOfflineNetworkAttempts.Add("$Method $Uri")
    throw "Network forbidden in offline validation: $Method $Uri"
}
function global:Invoke-WebRequest {
    param($Uri, $Headers, $OutFile, $Method, $Body)
    $null = $Headers, $OutFile, $Body
    $global:ExpandedOfflineNetworkAttempts.Add("$Method $Uri")
    throw "Network forbidden in offline validation: $Method $Uri"
}
$saved = @{}
foreach ($key in @('BC_EXPANDED_ALGO_SOURCE','BC_EXPANDED_REUSE_REGISTRY','BC_EXPANDED_REUSE_ZIP')) {
    $saved[$key] = [Environment]::GetEnvironmentVariable($key)
}
try {
    $env:BC_EXPANDED_ALGO_SOURCE = (Resolve-Path $PinnedALGoSource).Path
    $env:BC_EXPANDED_REUSE_REGISTRY = (Resolve-Path $RegistryFile).Path
    $env:BC_EXPANDED_REUSE_ZIP = (Resolve-Path $RegistryArchive).Path
    Import-Module Pester -RequiredVersion 6.1.0
    $configuration = New-PesterConfiguration
    $configuration.Run.Path = if ($TestNames.Count) {
        @($TestNames | ForEach-Object { Join-Path $PSScriptRoot "$_.Tests.ps1" })
    } else { $PSScriptRoot }
    $configuration.Run.PassThru = $true
    $configuration.TestDrive.Enabled = $false
    $configuration.TestRegistry.Enabled = $false
    $configuration.Output.Verbosity = 'None'
    $result = Invoke-Pester -Configuration $configuration
    $summary = @{
        total = $result.TotalCount; passed = $result.PassedCount; failed = $result.FailedCount
        failedBlocks = $result.FailedBlocksCount; skipped = $result.SkippedCount
        blockedNetworkAttempts = @($global:ExpandedOfflineNetworkAttempts)
        pinnedALGo = '91b96c2b294be6f823277dafe6f03350abfb9d23'
        failures = @($result.Failed | ForEach-Object {
            @{ name = $_.ExpandedName; error = ($_.ErrorRecord.Exception.Message -join ';') }
        })
        blockErrors = @($result.FailedBlocks | ForEach-Object { $_.ErrorRecord.Exception.Message })
    }
    $summary | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $ResultPath -Encoding UTF8
    $summary | ConvertTo-Json -Depth 10
    if ($result.FailedCount -or $result.FailedBlocksCount -or $global:ExpandedOfflineNetworkAttempts.Count) {
        throw 'Offline validation failed; see result file.'
    }
} finally {
    foreach ($key in $saved.Keys) { [Environment]::SetEnvironmentVariable($key, $saved[$key]) }
    Remove-Item Function:\Invoke-RestMethod, Function:\Invoke-WebRequest
    Remove-Variable ExpandedOfflineNetworkAttempts -Scope Global
}
