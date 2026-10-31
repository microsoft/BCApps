param([ValidateSet('Before', 'Cleanup')][string]$Phase, [hashtable]$Parameters)
$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'Contract.psm1')
Import-Module (Join-Path $PSScriptRoot 'Context.psm1')
Assert-ExpandedApiDispatch
Import-ExpandedHelper
$directory = Join-Path $env:GITHUB_WORKSPACE 'expanded-api-output'
$receiptPath = Join-Path $directory 'compiler-ownership.json'
$expected = "bcbuildprojectsExpandedBuild$($env:BC_EXPANDED_COUNTRY)$($env:GITHUB_RUN_ID)compiler"
if ($Phase -eq 'Before') {
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
} elseif (Test-Path $receiptPath) {
    $receipt = Get-Content $receiptPath -Raw | ConvertFrom-Json
    if ($receipt.run -ne $env:GITHUB_RUN_ID -or $receipt.name -ne $expected -or
        (Split-Path $receipt.folder -Leaf) -ne $expected) { throw 'Unowned compiler cleanup.' }
    if (Test-Path $receipt.folder) { Remove-BcCompilerFolder -compilerFolder $receipt.folder }
    $remaining = Test-Path $receipt.folder
    @{ compilerRemaining = $remaining; folder = $receipt.folder; run = $receipt.run } |
        ConvertTo-Json | Set-Content (Join-Path $directory 'compiler-cleanup.json')
    if ($remaining) { throw 'Compiler cleanup did not complete.' }
}
