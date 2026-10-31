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
    if (-not (Get-Module BcContainerHelper)) {
        if (-not $env:BcContainerHelperPath) { throw 'Pinned AL-Go helper path is missing.' }
        Import-Module (Join-Path (Split-Path $env:BcContainerHelperPath -Parent) 'BcContainerHelper.psm1') -ErrorAction Stop
    }
    $module = Get-Module BcContainerHelper
    if ((& $module { $bcContainerHelperVersion }) -cne (Get-ExpandedApiPinSet).helper) {
        throw 'Loaded helper is not the pinned diagnostic version.'
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
