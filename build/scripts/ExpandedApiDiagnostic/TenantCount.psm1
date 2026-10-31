Import-Module (Join-Path $PSScriptRoot 'Context.psm1')

function Test-SqlTenantExperiment {
    try {
        $context = Get-ExpandedContext
        return ($env:BC_SQL_TENANT_COUNT -ceq [string]$context.cell.configuration.mounts.Count -and
            $env:BC_SQL_PILOT_ARM -ceq 'control' -and $env:BC_SQL_API_EXPERIMENT -ceq 'control')
    } catch { return $false }
}

function Get-SqlTenantContainerName {
    (Get-ExpandedContext).container
}

Export-ModuleMember -Function Test-SqlTenantExperiment, Get-SqlTenantContainerName
