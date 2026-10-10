Import-Module (Join-Path $PSScriptRoot 'Contract.psm1')

function Get-ExpandedContext {
    Assert-ExpandedApiDispatch
    $plan = Get-ExpandedApiPlan -InventoryPath (Join-Path $PSScriptRoot 'routing-inventory.json')
    $cells = @($plan.cells | Where-Object {
        $_.country -ceq $env:BC_EXPANDED_COUNTRY -and $_.configuration.id -ceq $env:BC_EXPANDED_CONFIG
    })
    if ($cells.Count -ne 1) { throw 'Unknown expanded diagnostic cell.' }
    $lanes = @($cells[0].lanes | Where-Object id -CEQ $env:BC_EXPANDED_LANE)
    if ($lanes.Count -ne 1) { throw 'Unknown expanded diagnostic lane.' }
    @{
        cell = $cells[0]; lane = $lanes[0]; pins = $plan.pins
        project = "build\projects\Expanded $($env:BC_EXPANDED_COUNTRY) $($env:BC_EXPANDED_CONFIG) $($env:BC_EXPANDED_LANE)"
        container = "bcbuildprojectsExpanded$($env:BC_EXPANDED_COUNTRY)$($env:BC_EXPANDED_CONFIG)$($env:BC_EXPANDED_LANE)$($env:GITHUB_RUN_ID)"
        output = (Join-Path $env:GITHUB_WORKSPACE 'expanded-api-output')
    }
}

function Import-ExpandedHelper {
    param([string[]]$ConfigFiles = @(), [hashtable]$RequiredCommands = @{})
    if (-not $env:BcContainerHelperPath) { throw 'Pinned AL-Go helper path is missing.' }
    $path = (Resolve-Path (Join-Path (Split-Path $env:BcContainerHelperPath -Parent) 'BcContainerHelper.psm1') -ErrorAction Stop).Path
    $loaded = @(Get-Module BcContainerHelper -All)
    if (@($loaded | Where-Object { $_.Path -ine $path }).Count -or $loaded.Count -gt 1) {
        throw 'A different or ambiguous BCH provider is already loaded; no replacement is authorized.'
    }
    if ($loaded.Count) {
        $module = $loaded[0]
        if ((& $module { $bcContainerHelperVersion }) -cne (Get-ExpandedApiPinSet).helper) {
            throw 'Loaded helper is not the pinned diagnostic version.'
        }
        # Re-export the existing instance without Force: retain AL-Go's in-memory
        # configuration while making its commands visible beyond Context's scope.
        Import-Module -ModuleInfo $module -Global -DisableNameChecking -ErrorAction Stop
    } else {
        $module = Import-Module $path -Global -PassThru -DisableNameChecking `
            -ArgumentList @($false, $false, $ConfigFiles) -ErrorAction Stop
    }
    if ((& $module { $bcContainerHelperVersion }) -cne (Get-ExpandedApiPinSet).helper) {
        throw 'Loaded helper is not the pinned diagnostic version.'
    }
    foreach ($name in $RequiredCommands.Keys) {
        $command = Get-Command -Name $name -ErrorAction Stop
        if ($command.CommandType -ne 'Function' -or $command.Module.Path -ine $path -or
            -not $module.ExportedCommands.ContainsKey($name)) { throw "Unexpected helper command provider: $name." }
        foreach ($parameter in $RequiredCommands[$name]) {
            if (-not $command.Parameters.ContainsKey($parameter)) { throw "Missing helper parameter: $name/$parameter." }
        }
    }
}

function Write-ExpandedPhase {
    param([string]$Name, [long]$StartedTicks, [string]$StartedUtc, [bool]$Completed, [string]$Directory)
    @{
        phase = $Name; startedUtc = $StartedUtc; endedUtc = [DateTime]::UtcNow.ToString('o')
        startedTicks = $StartedTicks; endedTicks = [Diagnostics.Stopwatch]::GetTimestamp()
        frequency = [Diagnostics.Stopwatch]::Frequency; completed = $Completed
    } | ConvertTo-Json -Compress | Add-Content (Join-Path $Directory 'phases.jsonl')
}

Export-ModuleMember -Function Get-ExpandedContext, Import-ExpandedHelper, Write-ExpandedPhase
