Describe 'Web service key provider source contracts (not runtime proofs)' {
    BeforeAll {
        $root = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
        $script:provider = Get-Content (Join-Path $root 'src\Layers\W1\Tests\TestLibraries\MicrosoftTestAuthProvider.Codeunit.al') -Raw
        $script:tests = Get-Content (Join-Path $root 'src\Layers\W1\Tests\Misc\WebServiceKeyAuthTests.Codeunit.al') -Raw
    }

    It 'has no password-file or Key Vault dependency' {
        $script:provider | Should -Not -Match 'ApiTestPassword|AzureKeyVault|NavServerUserPassword|MockAzure'
    }

    It 'keeps SaaS and Windows guards before explicit NavUserPassword detection' {
        $script:provider | Should -Match '(?s)if EnvironmentInfo\.IsSaaSInfrastructure\(\) then\s+exit;.*if SecurityGroup\.IsWindowsAuthentication\(\) then\s+exit;.*if not IdentityManagement\.IsUserNamePasswordAuthentication\(\) then\s+Error\(UnsupportedAuthenticationErr\)'
    }

    It 'rejects a failed read before assigning any returned text as a password' {
        $script:provider | Should -Match '(?s)if not UserAccountHelper\.TryGetWebServicesKey\(UserSecurityId\(\), WebServiceKey, ExpiryDate\) then begin\s+Clear\(WebServiceKey\);\s+Error\(KeyRetrievalFailedErr\);\s+end;\s+Password := WebServiceKey;\s+Clear\(WebServiceKey\)'
    }

    It 'rechecks absence after taking the user lock before provisioning' {
        $script:provider | Should -Match '(?s)if Password\.IsEmpty\(\) then begin.*CurrentUser\.LockTable\(\);.*CurrentUser\.Get\(UserSecurityId\(\)\);.*Password := ReadAuthenticationPassword\(ExpiryDate\);.*if Password\.IsEmpty\(\) then begin.*IdentityManagement\.CreateWebServicesKey'
    }

    It 'does not commit, rotate expired keys, elevate permissions or use a global credential cache' {
        $script:provider | Should -Not -Match '(?im)^\s*(Commit\s*\(|Permissions\s*=|InherentPermissions\s*=|SingleInstance\s*=)'
        $script:provider | Should -Not -Match 'CreateWebServicesKeyNoExpiry|ClearWebServicesKey|CachedAuthenticationPassword'
        $script:provider | Should -Match 'ExpiryDate <= CurrentDateTime\(\)'
        $script:provider | Should -Match 'Error\(ExpiredKeyErr\)'
        $script:provider | Should -Match 'CurrentDateTime\(\) \+ 24 \* 60 \* 60 \* 1000'
    }

    It 'isolates credential mutation to newly created fixture users and cleans up before assertions' {
        $script:tests | Should -Match 'LibraryPermissions\.CreateUser\(FixtureUser, UserName, false\)'
        $script:tests | Should -Not -Match 'CreateWebServicesKey\(UserSecurityId\('
        ([regex]::Matches($script:tests, 'DeleteFixture\(\);\s+Commit\(\);')).Count | Should -Be 7
        $script:tests | Should -Not -Match '\bDotNet\b'
        $script:tests | Should -Match 'TenantWebService\.Get\(TenantWebService\."Object Type"::Codeunit, ServiceName\)'
        $script:tests | Should -Match 'GetUrl\(ClientType::SOAP, CompanyName\(\), ObjectType::Codeunit, Codeunit::"Web Service Key Auth Probe", TenantWebService\)'
    }
}
