param([ValidateSet('Warm', 'Cold')][string]$Boundary = 'Cold', [string[]]$ConfigFiles = @())
$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'Contract.psm1')
Import-Module (Join-Path $PSScriptRoot 'Context.psm1')
Assert-ExpandedApiDispatch
$required = @{
    'Get-AppJsonFromAppFile' = @('appFile')
    'New-BcCompilerFolder' = @('containerName', 'artifactUrl', 'platformArtifactUrl')
    'Remove-BcCompilerFolder' = @('compilerFolder')
    'New-BcContainer' = @('containerName', 'useGenericImage', 'platformArtifactUrl', 'memoryLimit', 'multitenant', 'credential')
    'Test-BcContainer' = @('containerName')
    'Remove-BcContainer' = @('containerName')
    'Get-BcContainerEventLog' = @('containerName', 'doNotOpen')
    'Get-BcContainerServerConfiguration' = @('containerName')
    'Get-BcContainerAppInfo' = @('containerName', 'tenant', 'tenantSpecificProperties')
    'Invoke-ScriptInBcContainer' = @('containerName', 'useSession', 'scriptblock', 'argumentList')
    'Get-TestsFromBcContainer' = @('containerName', 'tenant', 'extensionId', 'testType', 'requiredTestIsolation', 'disabledTests')
    'Run-TestsInBcContainer' = @('containerName', 'tenant', 'testCodeunitRange', 'testRunnerCodeunitId', 'JUnitResultFileName', 'renewClientContextBetweenTests')
}
$before = Get-Module BcContainerHelper
if ($Boundary -eq 'Warm' -and -not $before) { throw 'Warm preflight requires the AL-Go-loaded helper.' }
if ($Boundary -eq 'Cold' -and $before) { throw 'Cold preflight must start without a preloaded helper.' }
Import-ExpandedHelper -ConfigFiles $ConfigFiles -RequiredCommands $required
$module = Get-Module BcContainerHelper
if ($before -and -not [object]::ReferenceEquals($before, $module)) { throw 'Warm helper instance was replaced.' }
$commands = @(foreach ($name in $required.Keys | Sort-Object) {
    # Check at the consumer scope, not only inside the loader module.
    $command = Get-Command $name -ErrorAction Stop
    if ($command.Module.Path -ine $module.Path) { throw 'Caller resolves a foreign helper command.' }
    $specialTypes = @{
        credential = 'System.Management.Automation.PSCredential'; multitenant = 'System.Management.Automation.SwitchParameter'
        doNotOpen = 'System.Management.Automation.SwitchParameter'; tenantSpecificProperties = 'System.Management.Automation.SwitchParameter'
        useSession = 'System.Boolean'; scriptblock = 'System.Management.Automation.ScriptBlock'; argumentList = 'System.Object[]'
        disabledTests = 'System.Array'; renewClientContextBetweenTests = 'System.Management.Automation.SwitchParameter'
    }
    $signature = @(foreach ($parameter in $required[$name]) {
        $expected = if ($specialTypes.ContainsKey($parameter)) { $specialTypes[$parameter] } else { 'System.String' }
        $actual = $command.Parameters[$parameter].ParameterType.FullName
        if ($actual -cne $expected) { throw "Helper parameter type changed: $name/$parameter ($actual)." }
        @{ name = $parameter; type = $actual }
    })
    @{ name = $name; provider = $command.Source; path = $command.Module.Path; signature = $signature }
})
@{ boundary = $Boundary; version = (& $module { $bcContainerHelperVersion }); modulePath = $module.Path
    sha256 = (Get-FileHash $module.Path).Hash.ToLowerInvariant(); commands = $commands
    warmInstancePreserved = [bool]$before; observedUtc = [DateTime]::UtcNow.ToString('o') } |
    ConvertTo-Json -Depth 8 | Set-Content (Join-Path $env:BC_EXPANDED_OUTPUT "helper-preflight-$Boundary.json")
