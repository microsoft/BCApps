param([ValidateSet('Before', 'Cleanup')][string]$Phase, [hashtable]$Parameters)
$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'Contract.psm1')
Import-Module (Join-Path $PSScriptRoot 'Context.psm1')
Assert-ExpandedApiDispatch
$directory = Join-Path $env:GITHUB_WORKSPACE 'expanded-api-output'
$receiptPath = Join-Path $directory 'compiler-ownership.json'
$expected = "bcbuildprojectsExpandedBuild$($env:BC_EXPANDED_COUNTRY)$($env:GITHUB_RUN_ID)compiler"
if ($Phase -eq 'Before') {
    Import-ExpandedHelper -RequiredCommands @{ 'New-BcCompilerFolder' = @('containerName', 'platformArtifactUrl'); 'Remove-BcCompilerFolder' = @('compilerFolder') }
    if ($Parameters.containerName -ne $expected) { throw 'Unexpected compiler identity.' }
    $pins = Get-ExpandedApiPinSet
    $artifact = "https://bcinsider-fvh2ekdjecfjd6gk.b02.azurefd.net/sandbox/$($pins.application)/$($env:BC_EXPANDED_COUNTRY.ToLowerInvariant())"
    if ($Parameters.artifactUrl -cne $artifact -or $Parameters.vsixFile) { throw 'Compiler artifact or VSIX override differs from the exact pin.' }
    $helper = Get-Module BcContainerHelper
    $root = & $helper { $bcContainerHelperConfig.hostHelperFolder }
    $folder = Join-Path $root "compiler\$expected"
    if (Test-Path $folder) { throw 'Compiler destination already exists; no replacement allowed.' }
    $Parameters.platformArtifactUrl = "https://bcinsider-fvh2ekdjecfjd6gk.b02.azurefd.net/platform/$((Get-ExpandedApiPinSet).platform)/platform"
    @{ run = $env:GITHUB_RUN_ID; name = $expected; folder = $folder } |
        ConvertTo-Json | Set-Content $receiptPath
} else {
    $status = @{ run = $env:GITHUB_RUN_ID; name = $expected; folder = $null
        ownershipValidated = $false; removalAttempted = $false; absenceVerified = $false
        compilerRemaining = $null; failureType = $null }
    $failure = $null
    try {
        if (-not (Test-Path $receiptPath)) { throw 'No compiler ownership receipt; no deletion authorized.' }
        $receipt = Get-Content $receiptPath -Raw | ConvertFrom-Json
        $status.folder = $receipt.folder
        if ($receipt.run -ne $env:GITHUB_RUN_ID -or $receipt.name -ne $expected -or
            (Split-Path $receipt.folder -Leaf) -ne $expected) { throw 'Unowned compiler cleanup.' }
        Import-ExpandedHelper -RequiredCommands @{ 'Remove-BcCompilerFolder' = @('compilerFolder') }
        $helper = Get-Module BcContainerHelper
        $root = & $helper { $bcContainerHelperConfig.hostHelperFolder }
        $owned = [IO.Path]::GetFullPath((Join-Path $root "compiler\$expected"))
        if ([IO.Path]::GetFullPath($receipt.folder) -ine $owned) { throw 'Compiler ownership path differs from the exact helper destination.' }
        if ((Test-Path $owned) -and ((Get-Item $owned).Attributes -band [IO.FileAttributes]::ReparsePoint)) {
            throw 'Compiler destination is a reparse point; deletion refused.'
        }
        $status.ownershipValidated = $true
        if (Test-Path $owned) {
            $status.removalAttempted = $true
            Remove-BcCompilerFolder -compilerFolder $owned
        }
        $status.compilerRemaining = Test-Path $owned
        $status.absenceVerified = -not $status.compilerRemaining
        if ($status.compilerRemaining) { throw 'Compiler cleanup did not complete.' }
    } catch {
        $failure = $_
        $status.failureType = $_.Exception.GetType().FullName
    } finally {
        try {
            $status | ConvertTo-Json | Set-Content (Join-Path $directory 'compiler-cleanup.json') -ErrorAction Stop
        } catch {
            if ($failure) { Write-Warning 'Could not persist failed compiler cleanup receipt; original failure retained.' } else { throw }
        }
    }
    if ($failure) { throw $failure }
}
