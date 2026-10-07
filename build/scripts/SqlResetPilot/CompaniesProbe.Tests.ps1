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
    }
    It 'sends exactly one explicitly tenant-scoped preauthenticated HTTP request with retries disabled' {
        Invoke-SqlPilotCompaniesProbe 'owned' 'tenant2' $script:credential 'My Company'
        Should -Invoke Invoke-WebRequest -ModuleName Lifecycle -Times 1 -Exactly -ParameterFilter {
            $Uri -eq 'http://172.16.1.2:7048/BC/api/v2.0/companies?tenant=tenant2' -and
            $Authentication -eq 'Basic' -and $Credential.UserName -eq 'fixture' -and
            $MaximumRetryCount -eq 0 -and $MaximumRedirection -eq 0 -and $TimeoutSec -eq 60 -and $SkipHttpErrorCheck
        }
        Should -Invoke Add-Content -ModuleName Lifecycle -Times 1 -Exactly -ParameterFilter {
            $Value -match '"status":200' -and $Value -match '"passed":true' -and
            $Value -match 'server-correlation' -and $Value -notmatch 'fixture|test-only-marker'
        }
    }
    It 'treats HTTP failures as terminal without logging response content' {
        Mock Invoke-WebRequest -ModuleName Lifecycle {
            @{ StatusCode = 500; Headers = @{}; Content = 'sensitive-response-marker' }
        }
        { Invoke-SqlPilotCompaniesProbe 'owned' 'tenant2' $script:credential 'My Company' } |
            Should -Throw '*No retry*'
        Should -Invoke Invoke-WebRequest -ModuleName Lifecycle -Times 1 -Exactly
        Should -Invoke Add-Content -ModuleName Lifecycle -Times 1 -Exactly -ParameterFilter {
            $Value -match '"status":500' -and $Value -notmatch 'sensitive-response-marker|test-only-marker'
        }
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
    It 'redacts transport exception text and never retries' {
        Mock Invoke-WebRequest -ModuleName Lifecycle { throw 'sensitive-exception-marker' }
        { Invoke-SqlPilotCompaniesProbe 'owned' 'tenant2' $script:credential 'My Company' } |
            Should -Throw '*sanitized companies-probes*'
        Should -Invoke Invoke-WebRequest -ModuleName Lifecycle -Times 1 -Exactly
        Should -Invoke Add-Content -ModuleName Lifecycle -Times 1 -Exactly -ParameterFilter {
            $Value -notmatch 'sensitive-exception-marker|test-only-marker'
        }
    }
    It 'refuses a foreign container, default tenant, or worker not yet restored' {
        { Invoke-SqlPilotCompaniesProbe 'foreign' 'tenant2' $script:credential 'My Company' } | Should -Throw
        { Invoke-SqlPilotCompaniesProbe 'owned' 'default' $script:credential 'My Company' } | Should -Throw
        { Invoke-SqlPilotCompaniesProbe 'owned' 'tenant3' $script:credential 'My Company' } | Should -Throw
        Should -Invoke Invoke-WebRequest -ModuleName Lifecycle -Times 0
    }
}
