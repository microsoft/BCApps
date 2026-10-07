Set-StrictMode -Version 2
Import-Module (Join-Path $PSScriptRoot 'TenantCount.psm1')
$script:pilot = $null

function Initialize-SqlResetPilot {
    param([string]$ContainerName, [array]$TenantInfo, [string]$Arm, [string]$RunId, [string]$OutputDirectory,
        [int]$TenantCount = 0)
    if ($Arm -notin @('control', 'fresh') -or $RunId -notmatch '^\d{1,20}$') { throw 'Invalid pilot identity.' }
    if ($TenantCount) {
        if (-not (Test-SqlTenantExperiment) -or $TenantCount -ne [int]$env:BC_SQL_TENANT_COUNT -or
            $ContainerName -ne (Get-SqlTenantContainerName) -or $Arm -ne 'control' -or
            $RunId -ne $env:GITHUB_RUN_ID) { throw 'Default-worker reset requires the exact diagnostic identity.' }
        $expected = if ($TenantCount -eq 1) { @('default') } else { @('default', 'tenant2') }
        if ($TenantInfo.Count -ne $TenantCount -or @($TenantInfo.Id | Sort-Object -Unique).Count -ne $TenantCount -or
            @($TenantInfo | Where-Object { $_.Id -notin $expected -or $_.DatabaseName -ne $_.Id }).Count -gt 0) {
            throw 'Unexpected diagnostic worker mapping.'
        }
        $workers = @{}
        foreach ($info in $TenantInfo) {
            $workers[$info.Id] = @{ Info = $info; Generation = 0; Owned = @($info.Id); Used = @($info.Id) }
        }
        $script:pilot = @{
            Container = $ContainerName; Arm = $Arm; RunId = $RunId; Workers = $workers
            OutputDirectory = $OutputDirectory; TenantCount = $TenantCount; TemplateIdentity = $null
        }
        return
    }
    if ($TenantInfo.Count -ne 4 -or @($TenantInfo.Id | Sort-Object -Unique).Count -ne 4) {
        throw 'Pilot requires exactly default and three distinct workers.'
    }
    $workers = @{}
    foreach ($id in @('tenant2', 'tenant3', 'tenant4')) {
        $info = @($TenantInfo | Where-Object Id -eq $id)
        if ($info.Count -ne 1 -or $info[0].DatabaseName -ne $id) { throw 'Unexpected initial owned worker mapping.' }
        $workers[$id] = @{ Info = $info[0]; Generation = 0; Owned = @($id); Used = @($id) }
    }
    $source = @($TenantInfo | Where-Object Id -eq 'default')
    if ($source.Count -ne 1 -or $source[0].DatabaseName -ne 'default') { throw 'Unexpected protected source mapping.' }
    $script:pilot = @{
        Container = $ContainerName; Arm = $Arm; RunId = $RunId; Workers = $workers
        OutputDirectory = $OutputDirectory; TenantCount = 0; TemplateIdentity = $null
    }
}

function Get-SqlResetPlan {
    param([string]$ContainerName, [string]$Tenant, [string]$DatabaseName, [string]$TemplateDatabaseName)
    if (-not $script:pilot -or $ContainerName -ne $script:pilot.Container -or
        -not $script:pilot.Workers.ContainsKey($Tenant)) { throw 'Unowned container or tenant.' }
    $worker = $script:pilot.Workers[$Tenant]
    if ($script:pilot.TenantCount) {
        if (-not (Test-SqlTenantExperiment) -or $DatabaseName -ne $Tenant -or
            $TemplateDatabaseName -ne 'default-test-template' -or -not $script:pilot.TemplateIdentity) {
            throw 'Detached read-only template required before any diagnostic worker reset.'
        }
        return [PSCustomObject]@{
            Tenant = $Tenant; Previous = $DatabaseName; Destination = $DatabaseName
            Template = $TemplateDatabaseName; Generation = $worker.Generation + 1
            TemplateIdentity = $script:pilot.TemplateIdentity; TenantCount = $script:pilot.TenantCount
        }
    }
    if ($DatabaseName -ne $worker.Info.DatabaseName -or $DatabaseName -notin $worker.Owned -or
        $TemplateDatabaseName -notin @('default', 'default-test-template') -or
        $DatabaseName -in @('default', 'default-test-template', 'app') -or
        $DatabaseName -eq $TemplateDatabaseName) { throw 'Unsafe or stale database mapping.' }
    $generation = $worker.Generation + 1
    $destination = if ($script:pilot.Arm -eq 'fresh') { "${Tenant}_r$($script:pilot.RunId)_g$generation" } else { $DatabaseName }
    if ($destination -notmatch '^tenant[234](?:_r\d{1,20}_g\d+)?$' -or $destination.Length -gt 64 -or
        ($script:pilot.Arm -eq 'fresh' -and $destination -in $worker.Used)) { throw 'Unsafe or reused destination.' }
    [PSCustomObject]@{
        Tenant = $Tenant; Previous = $DatabaseName; Destination = $destination
        Template = $TemplateDatabaseName; Generation = $generation
    }
}

function Complete-SqlResetPlan {
    param($Plan)
    $worker = $script:pilot.Workers[$Plan.Tenant]
    $worker.Info.DatabaseName = $Plan.Destination
    $worker.Generation = $Plan.Generation
    $worker.Owned = @($worker.Owned | Where-Object { $_ -ne $Plan.Previous }) + @($Plan.Destination)
    $worker.Used += $Plan.Destination
}

function Protect-SqlPilotTemplate {
    param([string]$ContainerName, [string]$TemplateDatabaseName)
    if (-not $script:pilot -or -not $script:pilot.TenantCount -or
        $ContainerName -ne $script:pilot.Container -or $TemplateDatabaseName -ne 'default-test-template' -or
        $script:pilot.TemplateIdentity -or -not (Test-SqlTenantExperiment)) { throw 'Unsafe template protection request.' }
    $identity = Invoke-ScriptInBcContainer -containerName $ContainerName -useSession $false -scriptblock {
        if (@(Get-NAVTenant -ServerInstance $ServerInstance | Where-Object DatabaseName -eq 'default-test-template').Count) {
            throw 'Template must remain detached.'
        }
        $connection = New-Object System.Data.SqlClient.SqlConnection 'Server=.\SQLEXPRESS;Database=master;Integrated Security=True;TrustServerCertificate=True'
        try {
            $connection.Open()
            $command = $connection.CreateCommand()
            $command.CommandTimeout = 60
            $command.CommandText = 'ALTER DATABASE [default-test-template] SET READ_ONLY WITH NO_WAIT; SELECT CONVERT(nvarchar(36),service_broker_guid) FROM sys.databases WHERE name = ''default-test-template'' AND is_read_only = 1'
            $identity = [string]$command.ExecuteScalar()
            if (-not $identity) { throw 'Read-only detached template identity missing.' }
            $identity
        } finally { $connection.Dispose() }
    }
    if ([string]$identity -notmatch '^[0-9a-fA-F-]{36}$') { throw 'Invalid frozen template identity.' }
    $script:pilot.TemplateIdentity = [string]$identity
    @{ utc = [DateTime]::UtcNow.ToString('o'); database = $TemplateDatabaseName; detached = $true
        readOnly = $true; serviceBrokerGuid = $identity; frozenBeforeDiscovery = $true } |
        ConvertTo-Json | Set-Content (Join-Path $script:pilot.OutputDirectory 'template.json')
}

function Invoke-SqlPilotReset {
    param([string]$ContainerName, [string]$Tenant, [string]$DatabaseName, [string]$TemplateDatabaseName)
    $plan = Get-SqlResetPlan $ContainerName $Tenant $DatabaseName $TemplateDatabaseName
    $trace = Join-Path $script:pilot.OutputDirectory 'reset-timeline.jsonl'
    @{ phase = 'reset-start'; utc = [DateTime]::UtcNow.ToString('o'); arm = $script:pilot.Arm; plan = $plan } |
        ConvertTo-Json -Depth 5 -Compress | Add-Content $trace
    try {
        $result = Invoke-ScriptInBcContainer -containerName $ContainerName -useSession $false -scriptblock {
            param($plan)
            $ErrorActionPreference = 'Stop'
            $stopwatch = [Diagnostics.Stopwatch]::StartNew()
            $mounted = Get-NAVTenant -ServerInstance $ServerInstance -Tenant $plan.Tenant
            $localServers = @('.', 'localhost', $env:COMPUTERNAME, '.\SQLEXPRESS', 'localhost\SQLEXPRESS', "$env:COMPUTERNAME\SQLEXPRESS")
            if ($mounted.DatabaseName -ne $plan.Previous -or $mounted.DatabaseServer -notin $localServers) {
                throw 'Actual mounted mapping differs from the owned local SQL mapping.'
            }
            if ($plan.Destination -ne $plan.Previous -and (Test-NAVDatabase -DatabaseName $plan.Destination)) {
                throw 'Fresh database destination already exists; refusing to overwrite it.'
            }
            function Read-PilotIdentity($name) {
                $connection = New-Object System.Data.SqlClient.SqlConnection 'Server=.\SQLEXPRESS;Database=master;Integrated Security=True;TrustServerCertificate=True'
                try {
                    $connection.Open()
                    $command = $connection.CreateCommand()
                    $command.CommandText = 'SELECT name, database_id, create_date, service_broker_guid FROM sys.databases WHERE name = @name'
                    $null = $command.Parameters.AddWithValue('@name', $name)
                    $reader = $command.ExecuteReader()
                    if (-not $reader.Read()) { throw 'Owned SQL database identity is missing.' }
                    @{ name = [string]$reader[0]; databaseId = [int]$reader[1]; created = [string]$reader[2]; serviceBrokerGuid = [string]$reader[3] }
                } finally { $connection.Dispose() }
            }
            $detached = $plan.PSObject.Properties['TenantCount'] -and $plan.TenantCount -gt 0
            function Assert-DetachedTemplate {
                if ($plan.Template -ne 'default-test-template' -or $plan.Destination -notin @('default', 'tenant2') -or
                    $plan.Destination -eq $plan.Template -or
                    @(Get-NAVTenant -ServerInstance $ServerInstance | Where-Object DatabaseName -eq $plan.Template).Count) {
                    throw 'Unsafe detached-template reset.'
                }
                $connection = New-Object System.Data.SqlClient.SqlConnection 'Server=.\SQLEXPRESS;Database=master;Integrated Security=True;TrustServerCertificate=True'
                try {
                    $connection.Open()
                    $command = $connection.CreateCommand()
                    $command.CommandText = 'SELECT CONVERT(nvarchar(36),service_broker_guid) FROM sys.databases WHERE name = ''default-test-template'' AND is_read_only = 1'
                    if ([string]$command.ExecuteScalar() -ne $plan.TemplateIdentity) { throw 'Frozen template identity/read-only state changed.' }
                } finally { $connection.Dispose() }
            }
            if ($detached) {
                if (@(Get-NAVTenant -ServerInstance $ServerInstance).Count -ne $plan.TenantCount) { throw 'Mounted tenant count changed.' }
                Assert-DetachedTemplate
            }
            $before = Read-PilotIdentity $plan.Previous
            $started = [DateTime]::UtcNow.ToString('o')
            Dismount-NAVTenant -ServerInstance $ServerInstance -Tenant $plan.Tenant -Force | Out-Null
            if (Test-NAVDatabase -DatabaseName $plan.Previous) {
                Remove-NAVDatabase -DatabaseName $plan.Previous | Out-Null
            }
            Copy-NAVDatabase -SourceDatabaseName $plan.Template -DestinationDatabaseName $plan.Destination -DatabaseServer '.' | Out-Null
            if ($detached) {
                Assert-DetachedTemplate
                # RESTORE inherits READ_ONLY from the immutable source; only the owned worker becomes writable.
                $connection = New-Object System.Data.SqlClient.SqlConnection 'Server=.\SQLEXPRESS;Database=master;Integrated Security=True;TrustServerCertificate=True'
                try {
                    $connection.Open()
                    $command = $connection.CreateCommand()
                    $command.CommandText = "ALTER DATABASE [$($plan.Destination)] SET READ_WRITE WITH NO_WAIT"
                    $null = $command.ExecuteNonQuery()
                } finally { $connection.Dispose() }
            }
            Mount-NAVTenant -ServerInstance $ServerInstance -Id $plan.Tenant -DatabaseServer '.' `
                -DatabaseName $plan.Destination -OverwriteTenantIdInDatabase -Force | Out-Null
            while ((Get-NAVTenant -ServerInstance $ServerInstance -Tenant $plan.Tenant).State -eq 'Mounting') {
                if ($stopwatch.Elapsed.TotalSeconds -ge 300) { throw 'Tenant mount exceeded baseline 300-second bound.' }
                Start-Sleep -Milliseconds 250
            }
            $mounted = Get-NAVTenant -ServerInstance $ServerInstance -Tenant $plan.Tenant
            if ($mounted.State -notin @('Operational', 'OperationalWithWarnings') -or $mounted.DatabaseName -ne $plan.Destination) {
                throw 'Mounted state or mapping differs from the expected new generation.'
            }
            @{
                startedUtc = $started; completedUtc = [DateTime]::UtcNow.ToString('o')
                elapsedMilliseconds = $stopwatch.ElapsedMilliseconds
                before = $before; after = (Read-PilotIdentity $plan.Destination)
                databaseServer = [string]$mounted.DatabaseServer; state = [string]$mounted.State
                detailedState = [string]$mounted.DetailedState; forceRefresh = $false
                nst = @(Get-Process 'Microsoft.Dynamics.Nav.Server' | ForEach-Object {
                    @{ pid = $_.Id; version = $_.FileVersion }
                })
            }
        } -argumentList $plan
        Complete-SqlResetPlan $plan
        @{ phase = 'reset-complete'; utc = [DateTime]::UtcNow.ToString('o'); plan = $plan; observation = $result } |
            ConvertTo-Json -Depth 8 -Compress | Add-Content $trace
    } catch {
        # Do not log exception text: SQL/provider diagnostics can contain connection information.
        @{ phase = 'reset-failed'; utc = [DateTime]::UtcNow.ToString('o'); plan = $plan; errorType = $_.Exception.GetType().FullName } |
            ConvertTo-Json -Depth 5 -Compress | Add-Content $trace
        throw
    }
}

function Select-SqlPilotPrefix {
    param([array]$WorkItems)
    $ids = @(139700,139702,139703,139706,139725,139726,139732,139739,139742,139745,139802,139803,139806,139826,139832,139854,139972,139780,148315,148318,148343)
    if ($WorkItems.Count -lt $ids.Count) { throw 'Discovery returned an incomplete pilot prefix.' }
    for ($i = 0; $i -lt $ids.Count; $i++) {
        if ([int]$WorkItems[$i].CodeunitId -ne $ids[$i]) { throw "Original W1 discovery order differs at position $i." }
    }
    @($WorkItems | Select-Object -First $ids.Count)
}

<#
.SYNOPSIS
    Makes one authenticated companies request from the host after an owned worker restore.
.DESCRIPTION
    Uses the disposable container's existing password credential and private API endpoint.
    No retries, redirects, response bodies, passwords or authorization headers are logged.
#>
function Invoke-SqlPilotCompaniesProbe {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingAllowUnencryptedAuthentication', '',
        Justification = 'Preserves the existing disposable-container Basic authentication over its private Docker address.')]
    [CmdletBinding()]
    param(
        [string]$ContainerName, [string]$Tenant,
        [Parameter(Mandatory)][PSCredential]$Credential,
        [Parameter(Mandatory)][string]$CompanyName
    )
    if (-not $script:pilot -or $ContainerName -ne $script:pilot.Container -or
        -not $script:pilot.Workers.ContainsKey($Tenant) -or
        $script:pilot.Workers[$Tenant].Generation -lt 1) {
        throw 'Companies probe requires an owned, freshly restored worker.'
    }
    $trace = Join-Path $script:pilot.OutputDirectory 'companies-probes.jsonl'
    $observation = @{
        tenant = $Tenant; generation = $script:pilot.Workers[$Tenant].Generation
        startedUtc = [DateTime]::UtcNow.ToString('o'); status = $null; passed = $false
        clientRequestId = [guid]::NewGuid().ToString(); serverRequestId = $null
        uri = $null; retries = 0
    }
    $clock = [Diagnostics.Stopwatch]::StartNew()
    try {
        # Match BCH's direct container API address, without its request wrapper or auth negotiation.
        $config = Get-BcContainerServerConfiguration -ContainerName $ContainerName
        $ip = Get-BcContainerIpAddress -containerName $ContainerName
        $parsedIp = $null
        if (-not [Net.IPAddress]::TryParse($ip, [ref]$parsedIp) -or
            $config.ServerInstance -notmatch '^[a-zA-Z0-9_-]+$' -or
            $config.ClientServicesCredentialType -notin @('NavUserPassword', 'UserPassword')) {
            throw 'Unexpected container API configuration.'
        }
        $scheme = if ($config.ODataServicesSSLEnabled -eq 'true') { 'https' } else { 'http' }
        $uri = [UriBuilder]::new($scheme, $ip, [int]$config.ODataServicesPort,
            "$($config.ServerInstance)/api/v2.0/companies", "?tenant=$Tenant").Uri.AbsoluteUri
        $observation.uri = $uri
        $response = Invoke-WebRequest -Uri $uri -Method Get -Authentication Basic -Credential $Credential `
            -AllowUnencryptedAuthentication -SkipCertificateCheck -SkipHttpErrorCheck -MaximumRedirection 0 `
            -MaximumRetryCount 0 -TimeoutSec 60 -ErrorAction Stop `
            -Headers @{ Accept = 'application/json'; 'client-request-id' = $observation.clientRequestId }
        $observation.status = [int]$response.StatusCode
        foreach ($key in @('request-id', 'x-ms-request-id')) {
            $value = [string]($response.Headers[$key] | Select-Object -First 1)
            if ($value -match '^[a-zA-Z0-9._:-]{1,128}$') { $observation.serverRequestId = $value; break }
        }
        if ($response.StatusCode -ne 200) { throw 'Companies probe returned non-200 status.' }
        $body = $response.Content | ConvertFrom-Json -ErrorAction Stop
        if (-not $body.PSObject.Properties['value'] -or
            @($body.value | Where-Object { $_.name -eq $CompanyName -and $_.id }).Count -ne 1) {
            throw 'Companies probe did not return exactly one expected company.'
        }
        $observation.passed = $true
    } catch {
        $observation.errorType = $_.Exception.GetType().FullName
        # HTTP exception details can contain authentication material; never emit the original error.
        throw "Companies probe failed for $Tenant; see sanitized companies-probes.jsonl. No retry was attempted."
    } finally {
        $observation.completedUtc = [DateTime]::UtcNow.ToString('o')
        $observation.elapsedMilliseconds = $clock.ElapsedMilliseconds
        $observation | ConvertTo-Json -Compress | Add-Content $trace
    }
}

Export-ModuleMember -Function Initialize-SqlResetPilot, Get-SqlResetPlan, Complete-SqlResetPlan, Invoke-SqlPilotReset, Select-SqlPilotPrefix, Invoke-SqlPilotCompaniesProbe, Protect-SqlPilotTemplate
