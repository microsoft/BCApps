Describe 'API test authentication source contracts' {
    BeforeAll {
        $script:root = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
        $libraryRoot = Join-Path $script:root 'src\Layers\W1\Tests\TestLibraries'
        $script:provider = Get-Content (Join-Path $libraryRoot 'MicrosoftTestAuthProvider.Codeunit.al') -Raw
        $script:graph = Get-Content (Join-Path $libraryRoot 'LibraryGraphMgt.Codeunit.al') -Raw
        $script:authentication = Get-Content (Join-Path $libraryRoot 'APITestAuthentication.Enum.al') -Raw
        $script:context = Get-Content (Join-Path $libraryRoot 'APITestAuthContext.Codeunit.al') -Raw
        $script:container = Get-Content (Join-Path $script:root 'build\scripts\NewBcContainer.ps1') -Raw
    }

    It 'defaults only unresolved library instances to Microsoft authentication' {
        $script:graph | Should -Match '(?s)local procedure GetAuthenticationProvider\(\).*?if not AuthenticationProviderResolved then begin\s+Authentication := Authentication::"Microsoft Test Environment";'
        $script:graph | Should -Match '(?s)procedure SetAuthenticationProvider\(.*?Authentication := NewAuthentication;\s+AuthenticationProvider := Authentication;\s+AuthenticationProviderResolved := true;'
    }

    It 'preserves explicit None and unknown enum fallback semantics' {
        $script:authentication | Should -Match '(?s)value\(0; None\).*?Implementation = "API Test Auth Provider" = "No API Test Auth Provider";'
        $script:authentication | Should -Match 'DefaultImplementation = "API Test Auth Provider" = "No API Test Auth Provider";'
        $script:authentication | Should -Match 'Extensible = true;'
    }

    It 'preserves custom provider instance state on repeated selection' {
        $script:graph | Should -Match '(?s)if AuthenticationProviderResolved and \(Authentication = NewAuthentication\) then\s+exit;'
    }

    It 'retains ambient credentials and the final customization event after authentication' {
        $script:graph | Should -Match '(?s)SetUseDefaultCredentials\(true\);\s+ApplyAuthentication\(HttpWebRequestMgt\);\s+OnAfterInitializeWebRequestWithURL\(HttpWebRequestMgt\);'
    }

    It 'configures keys only on premises with exact username-password authentication' {
        $script:provider | Should -Match '(?s)if EnvironmentInfo.IsSaaSInfrastructure\(\) then\s+exit;\s+if not IdentityManagement.IsUserNamePasswordAuthentication\(\) then\s+exit;\s+Authentication.SetBasicAuthentication\(UserId\(\), GetWebServiceKey\(\)\);'
    }

    It 'reuses current-user keys and serializes missing-key creation with a recheck' {
        $script:provider | Should -Match '(?s)local procedure EnsureWebServiceKey.*?CurrentUser.LockTable\(\);\s+CurrentUser.Get\(UserSecurityId\(\)\);\s+WebServiceKey := ReadWebServiceKey\(ExpiryDate\);\s+if WebServiceKey.IsEmpty\(\) then begin'
        $script:provider | Should -Match 'CreateWebServicesKey\(UserSecurityId\(\), ExpiryDate\)'
        $script:provider | Should -Not -Match 'CreateWebServicesKeyNoExpiry|ClearWebServicesKey'
    }

    It 'prepares the current test user in the independent runner transaction before fixtures' {
        $script:provider | Should -Match '\[EventSubscriber\(ObjectType::Codeunit, Codeunit::"Test Runner - Mgt", ''OnBeforeTestMethodRun'''
        $script:provider | Should -Match '(?s)local procedure PrepareTestUserWebServiceKey.*?if Skip or EnvironmentInfo.IsSaaSInfrastructure\(\) then\s+exit;.*?if not IdentityManagement.IsUserNamePasswordAuthentication\(\) then\s+exit;.*?EnsureWebServiceKey\(\);'
        $script:provider | Should -Match 'using System.TestTools.TestRunner;'
        $manifest = Get-Content (Join-Path $script:root 'src\Layers\W1\Tests\TestLibraries\app.json') -Raw | ConvertFrom-Json
        @($manifest.dependencies | Where-Object id -eq '23de40a6-dfe8-4f80-80db-d70f83ce8caf').Count | Should -Be 1
    }

    It 'rejects missing-key creation during caller writes before entering isolation' {
        $script:provider | Should -Match '(?s)WebServiceKey := ReadWebServiceKey\(ExpiryDate\);\s+if WebServiceKey.IsEmpty\(\) then begin\s+if Database.IsInWriteTransaction\(\) then\s+Error\(KeyCreationInWriteTransactionErr\);.*?OnCreateWebServiceKey\(KeyCreationSucceeded\);'
        $requestPath = [regex]::Match($script:provider, '(?s)local procedure GetWebServiceKey\(\).*?(?=\s+\[InternalEvent)').Value
        $requestPath | Should -Not -Match 'LockTable|CreateWebServicesKey\('
    }

    It 'uses a platform-owned isolated subscriber transaction without explicit commits' {
        $script:provider | Should -Match '(?s)\[InternalEvent\(false, true\)\]\s+local procedure OnCreateWebServiceKey'
        $script:provider | Should -Match '\[EventSubscriber\(ObjectType::Codeunit, Codeunit::"Microsoft Test Auth Provider", ''OnCreateWebServiceKey'''
        $script:provider | Should -Match '(?s)\[CommitBehavior\(CommitBehavior::Error\)\]\s+local procedure CreateWebServiceKeyIsolated'
    }

    It 'rereads persisted credentials after isolation instead of trusting rollback-surviving event output' {
        $script:provider | Should -Match '(?s)OnCreateWebServiceKey\(KeyCreationSucceeded\);\s+if not KeyCreationSucceeded then\s+Error\(KeyCreationFailedErr\);.*?WebServiceKey := ReadWebServiceKey\(ExpiryDate\);'
        $script:provider | Should -Match 'local procedure OnCreateWebServiceKey\(var Succeeded: Boolean\)'
        $script:provider | Should -Not -Match 'OnCreateWebServiceKey\([^)]*SecretText'
    }

    It 'creates bounded keys and rejects expired or empty credentials' {
        $script:provider | Should -Match 'ExpiryDate := CurrentDateTime\(\) \+ 24 \* 60 \* 60 \* 1000;'
        $script:provider | Should -Match '(?s)if WebServiceKey.IsEmpty\(\) then\s+Error\(EmptyKeyErr\);'
        $script:provider | Should -Match '(?s)if \(ExpiryDate <> 0DT\) and \(ExpiryDate <= CurrentDateTime\(\)\) then\s+Error\(ExpiredKeyErr\);'
    }

    It 'checks fresh error state for both value-returning identity getters' {
        $script:provider | Should -Match '(?s)ClearLastError\(\);\s+WebServiceKey := IdentityManagement.GetWebServicesKey\(UserSecurityId\(\)\);\s+if GetLastErrorText\(\) <>'
        $script:provider | Should -Match '(?s)ClearLastError\(\);\s+ExpiryDate := IdentityManagement.GetWebServiceExpiryDate\(UserSecurityId\(\)\);\s+if GetLastErrorText\(\) <>'
    }

    It 'does not cache, log, or hand off plaintext credentials' {
        $script:provider | Should -Not -Match 'Cached|ApiTestPassword|KeyVault|PasswordFile|Message\(|LogMessage\(|Session.Log'
        $script:provider | Should -Match '(?s)\[NonDebuggable\]\s+local procedure ReadWebServiceKey'
        $script:provider | Should -Match 'SecretWebServiceKey: SecretText;'
        $script:provider | Should -Match 'Clear\(WebServiceKey\);'
        $script:context | Should -Match 'BasicPassword: SecretText;'
    }

    It 'does not commit the caller transaction while configuring a request' {
        $script:provider | Should -Not -Match '(?i)\bCommit\s*\('
        $requestPath = [regex]::Match($script:graph, '(?s)procedure InitializeWebRequestWithURL\(.*?(?=    procedure PatchToWebServiceAndCheckResponseCode)').Value
        $requestPath | Should -Not -BeNullOrEmpty
        $requestPath | Should -Not -Match '(?i)\bCommit\s*\('
    }

    It 'retains container credentials for NST provisioning without an API password file' {
        $script:container | Should -Match 'New-BcContainer @parameters'
        $script:container | Should -Not -Match 'ApiTestCredential|ApiTestPassword'
        Test-Path (Join-Path $script:root 'build\scripts\ApiTestCredential.psm1') | Should -BeFalse
        Test-Path (Join-Path $script:root 'build\scripts\Remove-ApiTestPassword.ps1') | Should -BeFalse
        Test-Path (Join-Path $script:root 'build\scripts\PipelineFinalize.ps1') | Should -BeFalse
        @(Get-ChildItem (Join-Path $script:root 'build\projects') -Filter PipelineFinalize.ps1 -Recurse).Count | Should -Be 0
    }

    It 'keeps HTTP regression coverage on the default and instance-reset paths without explicit uptake' {
        $tests = Get-Content (Join-Path $script:root 'src\Layers\W1\Tests\Misc\APITestAuthProviderTests.Codeunit.al') -Raw
        $tests | Should -Match 'procedure DefaultAuthenticationRespectsServerAuthMode'
        $tests | Should -Match '(?s)\[TransactionModel\(TransactionModel::None\)\]\s+procedure DefaultAuthenticationRespectsServerAuthMode'
        $tests | Should -Match 'Clear\(LibraryGraphMgt\);'
        $tests | Should -Not -Match '"Microsoft Test Environment"'
        $tests | Should -Match 'SetAuthenticationProvider\(Enum::"API Test Authentication"::None\)'
        $tests | Should -Match 'RequiredTestIsolation = Disabled;'
        Test-Path (Join-Path $script:root 'src\Layers\W1\Tests\Misc\APITestAuthHTTPTests.Codeunit.al') | Should -BeFalse
    }

    It 'retains a per-test license-safe date helper independent of authentication' {
        $script:graph | Should -Match '(?s)procedure SetLicenseSafeWorkDate\(\)\s+begin\s+WorkDate := DMY2Date\(15, 11, Date2DMY\(Today, 3\)\);'
        $script:provider | Should -Not -Match 'WorkDate|SetLicenseSafeWorkDate'
    }
}
