BeforeAll {
    function global:Get-BcContainerServerConfiguration { param($ContainerName) $null = $ContainerName; throw 'Live call forbidden.' }
    function global:Get-BcContainerIpAddress { param($containerName) $null = $containerName; throw 'Live call forbidden.' }
    Import-Module (Join-Path $PSScriptRoot 'Lifecycle.psm1') -Force
}

Describe 'External authenticated companies probe' {
    BeforeEach {
        $script:tenants = @('default','tenant2','tenant3','tenant4') | ForEach-Object {
            [PSCustomObject]@{ Id = $_; DatabaseName = $_ }
        }
        $password = [Security.SecureString]::new()
        foreach ($character in 'test-only-marker'.ToCharArray()) { $password.AppendChar($character) }
        $script:credential = [PSCredential]::new('fixture', $password)
        Initialize-SqlResetPilot 'owned' $script:tenants 'control' '123' $TestDrive
        Complete-SqlResetPlan (Get-SqlResetPlan 'owned' 'tenant2' 'tenant2' 'default-test-template')
        Mock Get-BcContainerServerConfiguration -ModuleName Lifecycle {
            @{ ServerInstance = 'BC'; ODataServicesPort = 7048; ODataServicesSSLEnabled = 'false'; ClientServicesCredentialType = 'NavUserPassword' }
        }
        Mock Get-BcContainerIpAddress -ModuleName Lifecycle { '172.16.1.2' }
        Mock Invoke-WebRequest -ModuleName Lifecycle {
            @{ StatusCode = 200; Headers = @{ 'request-id' = @('server-correlation') }; Content = '{"value":[{"name":"My Company","id":"company-id"}]}' }
        }
        Mock Add-Content -ModuleName Lifecycle {}
        Mock Start-Sleep -ModuleName Lifecycle {}
        $script:requestNumber = 0
    }
    It 'records first-try success with explicit tenant auth and hidden HTTP retries disabled' {
        Invoke-SqlPilotCompaniesProbe 'owned' 'tenant2' $script:credential 'My Company'
        Should -Invoke Invoke-WebRequest -ModuleName Lifecycle -Times 1 -Exactly -ParameterFilter {
            $Uri -eq 'http://172.16.1.2:7048/BC/api/v2.0/companies?tenant=tenant2' -and
            $Authentication -eq 'Basic' -and $Credential.UserName -eq 'fixture' -and
            $MaximumRetryCount -eq 0 -and $MaximumRedirection -eq 0 -and $TimeoutSec -eq 20 -and
            $OperationTimeoutSeconds -eq 20 -and $SkipHttpErrorCheck
        }
        Should -Invoke Add-Content -ModuleName Lifecycle -Times 1 -Exactly -ParameterFilter {
            $Value -match '"recordType":"attempt"' -and
            $Value -match '"status":200' -and $Value -match '"passed":true' -and
            $Value -match 'server-correlation' -and $Value -notmatch 'fixture|test-only-marker'
        }
        Should -Invoke Add-Content -ModuleName Lifecycle -Times 1 -Exactly -ParameterFilter {
            $Value -match '"outcome":"first-try-success"' -and $Value -match '"retries":0' -and
            $Value -match '"attempts":1' -and $Value -match '"recovered":false'
        }
        Should -Invoke Start-Sleep -ModuleName Lifecycle -Times 0
    }
    It 'uses exactly one attempt in experiment arm <Arm> even for HTTP500' -ForEach @(
        @{ Arm = 'A' }, @{ Arm = 'B' }
    ) {
        $old = $env:BC_SQL_API_EXPERIMENT
        try {
            $env:BC_SQL_API_EXPERIMENT = $Arm
            Mock Invoke-WebRequest -ModuleName Lifecycle { @{ StatusCode = 500; Headers = @{}; Content = '' } }
            { Invoke-SqlPilotCompaniesProbe 'owned' 'tenant2' $script:credential 'My Company' } | Should -Throw '*after 1 attempt*'
            Should -Invoke Invoke-WebRequest -ModuleName Lifecycle -Times 1 -Exactly
            Should -Invoke Start-Sleep -ModuleName Lifecycle -Times 0
        } finally { $env:BC_SQL_API_EXPERIMENT = $old }
    }
    It 'bounds transient HTTP <Code> to three attempts and records each failure safely' -ForEach @(
        @{ Code = 500 }, @{ Code = 502 }, @{ Code = 503 }, @{ Code = 504 }
    ) {
        Mock Invoke-WebRequest -ModuleName Lifecycle {
            @{ StatusCode = $Code; Headers = @{}; Content = 'sensitive-response-marker' }
        }
        { Invoke-SqlPilotCompaniesProbe 'owned' 'tenant2' $script:credential 'My Company' } |
            Should -Throw '*after 3 attempt*'
        Should -Invoke Invoke-WebRequest -ModuleName Lifecycle -Times 3 -Exactly
        Should -Invoke Start-Sleep -ModuleName Lifecycle -Times 2 -Exactly -ParameterFilter { $Seconds -eq 2 }
        Should -Invoke Add-Content -ModuleName Lifecycle -Times 3 -Exactly -ParameterFilter {
            $Value -match '"recordType":"attempt"' -and $Value -match '"retryable":true' -and
            $Value -match '"startedUtc":' -and $Value -match '"completedUtc":' -and
            $Value -match '"elapsedMilliseconds":' -and $Value -match '"errorCategory":"HttpStatus"' -and
            $Value -notmatch 'sensitive-response-marker|test-only-marker'
        }
        Should -Invoke Add-Content -ModuleName Lifecycle -Times 1 -Exactly -ParameterFilter {
            $Value -match '"outcome":"failed"' -and $Value -match '"attempts":3' -and $Value -match '"retries":2'
        }
    }
    It 'does not retry permanent HTTP <Code>' -ForEach @(
        @{ Code = 301 }, @{ Code = 400 }, @{ Code = 401 }, @{ Code = 403 },
        @{ Code = 404 }, @{ Code = 408 }, @{ Code = 429 }, @{ Code = 501 }
    ) {
        Mock Invoke-WebRequest -ModuleName Lifecycle { @{ StatusCode = $Code; Headers = @{}; Content = '' } }
        { Invoke-SqlPilotCompaniesProbe 'owned' 'tenant2' $script:credential 'My Company' } | Should -Throw '*after 1 attempt*'
        Should -Invoke Invoke-WebRequest -ModuleName Lifecycle -Times 1 -Exactly
        Should -Invoke Start-Sleep -ModuleName Lifecycle -Times 0
    }
    It 'records recovered success on the third attempt and does not issue a fourth' {
        Mock Invoke-WebRequest -ModuleName Lifecycle {
            $script:requestNumber++
            if ($script:requestNumber -lt 3) { return @{ StatusCode = 503; Headers = @{}; Content = '' } }
            @{ StatusCode = 200; Headers = @{}; Content = '{"value":[{"name":"My Company","id":"company-id"}]}' }
        }
        Invoke-SqlPilotCompaniesProbe 'owned' 'tenant2' $script:credential 'My Company'
        Should -Invoke Invoke-WebRequest -ModuleName Lifecycle -Times 3 -Exactly
        Should -Invoke Start-Sleep -ModuleName Lifecycle -Times 2 -Exactly
        Should -Invoke Add-Content -ModuleName Lifecycle -Times 3 -Exactly -ParameterFilter { $Value -match '"recordType":"attempt"' }
        Should -Invoke Add-Content -ModuleName Lifecycle -Times 1 -Exactly -ParameterFilter {
            $Value -match '"outcome":"recovered"' -and $Value -match '"recovered":true' -and
            $Value -match '"attempts":3' -and $Value -match '"retries":2'
        }
    }
    It 'retries typed transport failure <Kind> and records recovery' -ForEach @(
        @{ Kind = 'timeout'; Failure = [TimeoutException]::new('sensitive-exception-marker') }
        @{ Kind = 'cancelled request timeout'; Failure = [Threading.Tasks.TaskCanceledException]::new('sensitive-exception-marker') }
        @{ Kind = 'connection'; Failure = [Net.Http.HttpRequestException]::new('sensitive-exception-marker',
            [Net.Sockets.SocketException]::new(10061)) }
        @{ Kind = 'web timeout'; Failure = [Net.WebException]::new('sensitive-exception-marker', [Net.WebExceptionStatus]::Timeout) }
    ) {
        Mock Invoke-WebRequest -ModuleName Lifecycle {
            $script:requestNumber++
            if ($script:requestNumber -eq 1) { throw $Failure }
            @{ StatusCode = 200; Headers = @{}; Content = '{"value":[{"name":"My Company","id":"company-id"}]}' }
        }
        Invoke-SqlPilotCompaniesProbe 'owned' 'tenant2' $script:credential 'My Company'
        Should -Invoke Invoke-WebRequest -ModuleName Lifecycle -Times 2 -Exactly
        Should -Invoke Start-Sleep -ModuleName Lifecycle -Times 1 -Exactly -ParameterFilter { $Seconds -eq 2 }
        Should -Invoke Add-Content -ModuleName Lifecycle -Times 1 -Exactly -ParameterFilter {
            $Value -match '"errorCategory":"ConnectionOrTimeout"' -and $Value -match '"status":null' -and
            $Value -match '"errorType":' -and $Value -notmatch 'sensitive-exception-marker|test-only-marker'
        }
        Should -Invoke Add-Content -ModuleName Lifecycle -Times 1 -Exactly -ParameterFilter {
            $Value -match '"outcome":"recovered"' -and $Value -match '"attempts":2'
        }
    }
    It 'stops repeated transport timeouts after three attempts' {
        Mock Invoke-WebRequest -ModuleName Lifecycle { throw [TimeoutException]::new('sensitive-exception-marker') }
        { Invoke-SqlPilotCompaniesProbe 'owned' 'tenant2' $script:credential 'My Company' } | Should -Throw '*after 3 attempt*'
        Should -Invoke Invoke-WebRequest -ModuleName Lifecycle -Times 3 -Exactly
        Should -Invoke Start-Sleep -ModuleName Lifecycle -Times 2 -Exactly
    }
    It 'rejects invalid JSON without another request' {
        Mock Invoke-WebRequest -ModuleName Lifecycle { @{ StatusCode = 200; Headers = @{}; Content = 'invalid-json' } }
        { Invoke-SqlPilotCompaniesProbe 'owned' 'tenant2' $script:credential 'My Company' } | Should -Throw
        Should -Invoke Invoke-WebRequest -ModuleName Lifecycle -Times 1 -Exactly
    }
    It 'rejects missing expected company without another request' {
        Mock Invoke-WebRequest -ModuleName Lifecycle {
            @{ StatusCode = 200; Headers = @{}; Content = '{"value":[{"name":"Other","id":"id"}]}' }
        }
        { Invoke-SqlPilotCompaniesProbe 'owned' 'tenant2' $script:credential 'My Company' } | Should -Throw
        Should -Invoke Invoke-WebRequest -ModuleName Lifecycle -Times 1 -Exactly
    }
    It 'redacts unknown exception text without retrying permanent failures' {
        Mock Invoke-WebRequest -ModuleName Lifecycle { throw 'sensitive-exception-marker' }
        { Invoke-SqlPilotCompaniesProbe 'owned' 'tenant2' $script:credential 'My Company' } |
            Should -Throw '*sanitized companies-probes*'
        Should -Invoke Invoke-WebRequest -ModuleName Lifecycle -Times 1 -Exactly
        Should -Invoke Add-Content -ModuleName Lifecycle -Times 1 -Exactly -ParameterFilter {
            $Value -match '"recordType":"attempt"' -and $Value -notmatch 'sensitive-exception-marker|test-only-marker'
        }
        Should -Invoke Start-Sleep -ModuleName Lifecycle -Times 0
    }
    It 'does not retry TLS authentication errors' {
        Mock Invoke-WebRequest -ModuleName Lifecycle {
            throw [Net.Http.HttpRequestException]::new('sensitive-exception-marker',
                [Security.Authentication.AuthenticationException]::new('sensitive-exception-marker'))
        }
        { Invoke-SqlPilotCompaniesProbe 'owned' 'tenant2' $script:credential 'My Company' } | Should -Throw '*after 1 attempt*'
        Should -Invoke Invoke-WebRequest -ModuleName Lifecycle -Times 1 -Exactly
        Should -Invoke Start-Sleep -ModuleName Lifecycle -Times 0
    }
    It 'refuses a foreign container, default tenant, or worker not yet restored' {
        { Invoke-SqlPilotCompaniesProbe 'foreign' 'tenant2' $script:credential 'My Company' } | Should -Throw
        { Invoke-SqlPilotCompaniesProbe 'owned' 'default' $script:credential 'My Company' } | Should -Throw
        { Invoke-SqlPilotCompaniesProbe 'owned' 'tenant3' $script:credential 'My Company' } | Should -Throw
        Should -Invoke Invoke-WebRequest -ModuleName Lifecycle -Times 0
    }
}
