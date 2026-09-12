namespace Microsoft.FabricExport;

using Microsoft.Utilities;
using System.Fabric;
using System.Reflection;

codeunit 140012 "Test FAB Platform"
{
    Subtype = Test;
    TestPermissions = Restrictive;

    var
        Assert: Codeunit "Assert";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        PlatformTestSub: Codeunit "Fabric Platform Test Sub";
        LookupState: Codeunit "Fabric Platform Lookup State";
        IsInitialized: Boolean;
        ExpectedMessages: List of [Text];
        EnableRequestedMsg: Label 'Enable was requested. The platform runs asynchronously; open Export Summary to follow progress.';
        StartRequestedMsg: Label 'Start was requested. The platform runs asynchronously; open Export Summary to follow progress.';
        StopRequestedMsg: Label 'Stop was requested. The platform runs asynchronously; open Export Summary to follow progress.';
        DisableRequestedMsg: Label 'Disable was requested. The platform runs asynchronously; open Export Summary to follow progress.';
        TestConnectionSuccessMsg: Label 'Connection to Microsoft Fabric succeeded.';

    local procedure Initialize()
    var
        TenantFabricSetup: Record "Tenant Fabric Setup";
        TenantFabricTables: Record "Tenant Fabric Tables";
        TenantFabricCompanies: Record "Tenant Fabric Companies";
        FabricTableClaim: Record "Fabric Table Claim";
    begin
        TenantFabricTables.DeleteAll(false);
        TenantFabricSetup.DeleteAll(false);
        TenantFabricCompanies.DeleteAll(false);
        FabricTableClaim.DeleteAll(false);
        PlatformTestSub.Reset();
        LookupState.ClearFabricApiToken();
        if IsInitialized then
            exit;
        IsInitialized := true;
    end;

    [Test]
    procedure EnsureSetupCreatesPlatformRecord()
    var
        TenantFabricSetup: Record "Tenant Fabric Setup";
        FabricPlatformMgt: Codeunit "Fabric Platform Mgt";
    begin
        //[SCENARIO] The adapter reads/creates the platform setup singleton (Story 1)
        //[GIVEN] Initialize
        Initialize();
        //[GIVEN] Lower permissions
        LibraryLowerPermissions.SetOutsideO365Scope();
        LibraryLowerPermissions.AddPermissionSet('Fabric Exp Admin');

        //[WHEN] EnsureSetup is called
        FabricPlatformMgt.EnsureSetup(TenantFabricSetup);

        //[THEN] Exactly one platform setup record exists
        Assert.AreEqual(1, TenantFabricSetup.Count(), 'Expected exactly one Tenant Fabric Setup record.');
    end;

    [Test]
    procedure AddTableWritesPlatformSystemTable()
    var
        TenantFabricTables: Record "Tenant Fabric Tables";
        FabricPlatformMgt: Codeunit "Fabric Platform Mgt";
    begin
        //[SCENARIO] Adding a valid table writes directly to Tenant Fabric Tables (Story 2)
        //[GIVEN] Initialize
        Initialize();
        //[GIVEN] Lower permissions
        LibraryLowerPermissions.SetOutsideO365Scope();
        LibraryLowerPermissions.AddPermissionSet('Fabric Exp Admin');

        //[WHEN] A valid table is added
        FabricPlatformMgt.AddTable(Database::"Tenant Fabric Setup");

        //[THEN] The row exists in the platform table
        Assert.IsTrue(TenantFabricTables.Get(Database::"Tenant Fabric Setup"), 'Expected the added table row in Tenant Fabric Tables.');
    end;

    [Test]
    procedure AddTableRejectedAtLimit()
    var
        TenantFabricTables: Record "Tenant Fabric Tables";
        FabricPlatformMgt: Codeunit "Fabric Platform Mgt";
        i: Integer;
    begin
        //[SCENARIO] The 500-table platform limit is enforced (Story 2)
        //[GIVEN] Initialize
        Initialize();
        //[GIVEN] 500 table rows already exist
        for i := 1 to FabricPlatformMgt.MaxTableCount() do begin
            TenantFabricTables.Init();
            TenantFabricTables."Table ID" := i;
            TenantFabricTables.Insert(false);
        end;
        //[GIVEN] Lower permissions
        LibraryLowerPermissions.SetOutsideO365Scope();
        LibraryLowerPermissions.AddPermissionSet('Fabric Exp Admin');

        //[WHEN] Another table add is attempted
        asserterror FabricPlatformMgt.CheckCanAddTable();

        //[THEN] The operation is rejected
        Assert.ExpectedError('maximum');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure EnableUsesSeamWithoutCallingPlatform()
    var
        FabricPlatformMgt: Codeunit "Fabric Platform Mgt";
        FabricPrivacyNotice: Codeunit "Fabric Privacy Notice";
    begin
        //[SCENARIO] Enable routes through the lifecycle seam (Story 3)
        //[GIVEN] Initialize
        Initialize();
        //[GIVEN] The lifecycle subscriber is bound so no real ADF call happens
        BindSubscription(PlatformTestSub);
        //[GIVEN] The privacy notice is approved so the mandatory consent gate passes
        FabricPrivacyNotice.Approve();
        //[GIVEN] Lower permissions
        LibraryLowerPermissions.SetOutsideO365Scope();
        LibraryLowerPermissions.AddPermissionSet('Fabric Exp Admin');
        //[GIVEN] Expected requested-action notification
        ExpectedMessages.Add(EnableRequestedMsg);

        //[WHEN] Enable is requested
        FabricPlatformMgt.EnableExport();

        //[THEN] The seam fired and the real platform call was bypassed
        Assert.IsTrue(PlatformTestSub.WasEnableCalled(), 'Expected the enable seam to fire.');
        UnbindSubscription(PlatformTestSub);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure StartStopDisableUseSeam()
    var
        FabricPlatformMgt: Codeunit "Fabric Platform Mgt";
        FabricPrivacyNotice: Codeunit "Fabric Privacy Notice";
    begin
        //[SCENARIO] Start, Stop, and Disable route through the lifecycle seam (Stories 4-5)
        //[GIVEN] Initialize
        Initialize();
        //[GIVEN] The lifecycle subscriber is bound
        BindSubscription(PlatformTestSub);
        //[GIVEN] The privacy notice is approved so Start's mandatory consent gate passes
        FabricPrivacyNotice.Approve();
        //[GIVEN] Lower permissions
        LibraryLowerPermissions.SetOutsideO365Scope();
        LibraryLowerPermissions.AddPermissionSet('Fabric Exp Admin');
        //[GIVEN] Expected requested-action notifications, in call order
        ExpectedMessages.Add(StartRequestedMsg);
        ExpectedMessages.Add(StopRequestedMsg);
        ExpectedMessages.Add(DisableRequestedMsg);

        //[WHEN] Start, Stop, and Disable are requested
        FabricPlatformMgt.StartExport();
        FabricPlatformMgt.StopExport();
        FabricPlatformMgt.DisableExport();

        //[THEN] All three seams fired
        Assert.IsTrue(PlatformTestSub.WasStartCalled(), 'Expected the start seam to fire.');
        Assert.IsTrue(PlatformTestSub.WasStopCalled(), 'Expected the stop seam to fire.');
        Assert.IsTrue(PlatformTestSub.WasDisableCalled(), 'Expected the disable seam to fire.');
        UnbindSubscription(PlatformTestSub);
    end;

    [Test]
    procedure AddTableFailsForInvalidTableId()
    var
        FabricPlatformMgt: Codeunit "Fabric Platform Mgt";
    begin
        //[SCENARIO] Adding a non-existent table ID is rejected (Story 2)
        //[GIVEN] Initialize
        Initialize();
        //[GIVEN] Lower permissions
        LibraryLowerPermissions.SetOutsideO365Scope();
        LibraryLowerPermissions.AddPermissionSet('Fabric Exp Admin');

        //[WHEN] A non-existent table ID is added
        asserterror FabricPlatformMgt.AddTable(999999);

        //[THEN] The operation is rejected
        Assert.ExpectedError('does not exist');
    end;

    [Test]
    procedure AddTableFailsWhenAlreadySelected()
    var
        TenantFabricTables: Record "Tenant Fabric Tables";
        FabricPlatformMgt: Codeunit "Fabric Platform Mgt";
    begin
        //[SCENARIO] Adding an already-selected table is rejected (Story 2)
        //[GIVEN] Initialize
        Initialize();
        //[GIVEN] The table is already present in the platform table
        TenantFabricTables.Init();
        TenantFabricTables."Table ID" := Database::"Tenant Fabric Setup";
        TenantFabricTables.Insert(false);
        //[GIVEN] Lower permissions
        LibraryLowerPermissions.SetOutsideO365Scope();
        LibraryLowerPermissions.AddPermissionSet('Fabric Exp Admin');

        //[WHEN] The same table is added again
        asserterror FabricPlatformMgt.AddTable(Database::"Tenant Fabric Setup");

        //[THEN] The operation is rejected
        Assert.ExpectedError('already selected');
    end;

    [Test]
    procedure AddTablesBatchAddsAllTables()
    var
        AllObjWithCaption: Record AllObjWithCaption;
        TenantFabricTables: Record "Tenant Fabric Tables";
        FabricPlatformMgt: Codeunit "Fabric Platform Mgt";
    begin
        //[SCENARIO] AddTables adds every table in a set in one call (Story 2)
        //[GIVEN] Initialize
        Initialize();
        //[GIVEN] A set of two valid, not-yet-selected tables
        AllObjWithCaption.SetRange("Object Type", AllObjWithCaption."Object Type"::Table);
        AllObjWithCaption.SetFilter("Object ID", '%1|%2', Database::"Tenant Fabric Companies", Database::"Tenant Fabric Table Fields");
        //[GIVEN] Lower permissions
        LibraryLowerPermissions.SetOutsideO365Scope();
        LibraryLowerPermissions.AddPermissionSet('Fabric Exp Admin');

        //[WHEN] The set is added in one call
        FabricPlatformMgt.AddTables(AllObjWithCaption);

        //[THEN] Both tables exist in the platform table
        Assert.IsTrue(TenantFabricTables.Get(Database::"Tenant Fabric Companies"), 'Expected Tenant Fabric Companies table to be added.');
        Assert.IsTrue(TenantFabricTables.Get(Database::"Tenant Fabric Table Fields"), 'Expected Tenant Fabric Table Fields table to be added.');
    end;

    [Test]
    procedure HasSetupReturnsFalseBeforeSetupExists()
    var
        FabricPlatformMgt: Codeunit "Fabric Platform Mgt";
        HasSetupResult: Boolean;
    begin
        //[SCENARIO] HasSetup reports false before the setup singleton is created (Story 1)
        //[GIVEN] Initialize
        Initialize();
        //[GIVEN] Lower permissions
        LibraryLowerPermissions.SetOutsideO365Scope();
        LibraryLowerPermissions.AddPermissionSet('Fabric Exp Admin');

        //[WHEN] HasSetup is queried
        HasSetupResult := FabricPlatformMgt.HasSetup();

        //[THEN] It reports false
        Assert.IsFalse(HasSetupResult, 'Expected HasSetup to be false before any setup exists.');
    end;

    [Test]
    procedure HasSetupReturnsTrueAfterEnsureSetup()
    var
        TenantFabricSetup: Record "Tenant Fabric Setup";
        FabricPlatformMgt: Codeunit "Fabric Platform Mgt";
        HasSetupResult: Boolean;
    begin
        //[SCENARIO] HasSetup reports true once the setup singleton exists (Story 1)
        //[GIVEN] Initialize
        Initialize();
        //[GIVEN] The setup singleton already exists
        FabricPlatformMgt.EnsureSetup(TenantFabricSetup);
        //[GIVEN] Lower permissions
        LibraryLowerPermissions.SetOutsideO365Scope();
        LibraryLowerPermissions.AddPermissionSet('Fabric Exp Admin');

        //[WHEN] HasSetup is queried
        HasSetupResult := FabricPlatformMgt.HasSetup();

        //[THEN] It reports true
        Assert.IsTrue(HasSetupResult, 'Expected HasSetup to be true after EnsureSetup has run.');
    end;

    [Test]
    procedure AddCompanyAddsExistingCompany()
    var
        TenantFabricCompanies: Record "Tenant Fabric Companies";
        FabricPlatformMgt: Codeunit "Fabric Platform Mgt";
    begin
        //[SCENARIO] Adding the current company registers it for export
        //[GIVEN] Initialize
        Initialize();
        //[GIVEN] Lower permissions
        LibraryLowerPermissions.SetOutsideO365Scope();
        LibraryLowerPermissions.AddPermissionSet('Fabric Exp Admin');

        //[WHEN] The current company is added
        FabricPlatformMgt.AddCompany(CopyStr(CompanyName(), 1, 30));

        //[THEN] The company exists and is enabled in the platform table
        Assert.IsTrue(TenantFabricCompanies.Get(CompanyName()), 'Expected the company row to exist.');
        Assert.IsTrue(TenantFabricCompanies.Enabled, 'Expected the company to be enabled.');
    end;

    [Test]
    procedure AddCompanyFailsForInvalidCompany()
    var
        FabricPlatformMgt: Codeunit "Fabric Platform Mgt";
    begin
        //[SCENARIO] Adding a company that does not exist is rejected
        //[GIVEN] Initialize
        Initialize();
        //[GIVEN] Lower permissions
        LibraryLowerPermissions.SetOutsideO365Scope();
        LibraryLowerPermissions.AddPermissionSet('Fabric Exp Admin');

        //[WHEN] A non-existent company is added
        asserterror FabricPlatformMgt.AddCompany('NO SUCH COMPANY');

        //[THEN] The operation is rejected
        Assert.ExpectedError('does not exist');
    end;

    [Test]
    procedure AddCompanyFailsWhenAlreadySelected()
    var
        TenantFabricCompanies: Record "Tenant Fabric Companies";
        FabricPlatformMgt: Codeunit "Fabric Platform Mgt";
    begin
        //[SCENARIO] Adding an already-selected company is rejected
        //[GIVEN] Initialize
        Initialize();
        //[GIVEN] The current company is already selected
        TenantFabricCompanies.Init();
        TenantFabricCompanies."Company Name" := CopyStr(CompanyName(), 1, MaxStrLen(TenantFabricCompanies."Company Name"));
        TenantFabricCompanies.Insert(false);
        //[GIVEN] Lower permissions
        LibraryLowerPermissions.SetOutsideO365Scope();
        LibraryLowerPermissions.AddPermissionSet('Fabric Exp Admin');

        //[WHEN] The same company is added again
        asserterror FabricPlatformMgt.AddCompany(CopyStr(CompanyName(), 1, 30));

        //[THEN] The operation is rejected
        Assert.ExpectedError('already selected');
    end;

    [Test]
    procedure EnableExportFailsWithoutClientId()
    var
        FabricPlatformMgt: Codeunit "Fabric Platform Mgt";
        CredMgt: Codeunit "Fabric Platform Credential Mgt";
    begin
        //[SCENARIO] Enable is rejected when no Client ID has been configured
        //[GIVEN] Initialize
        Initialize();
        //[GIVEN] No client ID configured
        CredMgt.SetClientId('');
        //[GIVEN] Lower permissions
        LibraryLowerPermissions.SetOutsideO365Scope();
        LibraryLowerPermissions.AddPermissionSet('Fabric Exp Admin');

        //[WHEN] Enable is requested without the lifecycle seam bound
        asserterror FabricPlatformMgt.EnableExport();

        //[THEN] The missing client ID is reported
        Assert.ExpectedError('Client ID');
    end;

    [Test]
    procedure EnableExportFailsForInvalidClientIdFormat()
    var
        FabricPlatformMgt: Codeunit "Fabric Platform Mgt";
        CredMgt: Codeunit "Fabric Platform Credential Mgt";
    begin
        //[SCENARIO] Enable is rejected when the configured Client ID is not a valid GUID
        //[GIVEN] Initialize
        Initialize();
        //[GIVEN] A non-GUID client ID is configured
        CredMgt.SetClientId('not-a-guid');
        //[GIVEN] Lower permissions
        LibraryLowerPermissions.SetOutsideO365Scope();
        LibraryLowerPermissions.AddPermissionSet('Fabric Exp Admin');

        //[WHEN] Enable is requested without the lifecycle seam bound
        asserterror FabricPlatformMgt.EnableExport();

        //[THEN] The invalid GUID is reported
        Assert.ExpectedError('valid GUID');
    end;

    [Test]
    procedure EnableExportFailsWithoutClientSecret()
    var
        FabricPlatformMgt: Codeunit "Fabric Platform Mgt";
        CredMgt: Codeunit "Fabric Platform Credential Mgt";
    begin
        //[SCENARIO] Enable is rejected when no Client Secret has been configured
        //[GIVEN] Initialize
        Initialize();
        //[GIVEN] A valid Client ID but no Client Secret configured
        CredMgt.SetClientId('11111111-1111-1111-1111-111111111111');
        //[GIVEN] Lower permissions
        LibraryLowerPermissions.SetOutsideO365Scope();
        LibraryLowerPermissions.AddPermissionSet('Fabric Exp Admin');

        //[WHEN] Enable is requested without the lifecycle seam bound
        asserterror FabricPlatformMgt.EnableExport();

        //[THEN] The missing client secret is reported
        Assert.ExpectedError('Client Secret');
    end;

    [Test]
    procedure LookupStateReturnsCachedTokenWhileValid()
    var
        Token: SecretText;
        CachedToken: SecretText;
    begin
        //[SCENARIO] The cached token is returned while it has not expired
        //[GIVEN] Initialize
        Initialize();
        //[GIVEN] A token value to cache
        Token := SecretStrSubstNo('sample-token');
        //[GIVEN] Lower permissions
        LibraryLowerPermissions.SetOutsideO365Scope();
        LibraryLowerPermissions.AddPermissionSet('Fabric Exp Admin');

        //[WHEN] The token is cached with a long TTL
        LookupState.SetFabricApiToken(Token, 3600);

        //[THEN] The token is reported as present and is returned non-empty
        Assert.IsTrue(LookupState.HasFabricApiToken(), 'Expected the cached token to be reported as present.');
        CachedToken := LookupState.GetFabricApiToken();
        Assert.IsFalse(CachedToken.IsEmpty(), 'Expected the cached token to be returned.');
    end;

    [Test]
    procedure LookupStateReportsNoTokenAfterShortTtlElapses()
    var
        Token: SecretText;
    begin
        //[SCENARIO] A token cached with a TTL at or below the safety margin is immediately treated as expired
        //[GIVEN] Initialize
        Initialize();
        //[GIVEN] A token value to cache
        Token := SecretStrSubstNo('sample-token');
        //[GIVEN] Lower permissions
        LibraryLowerPermissions.SetOutsideO365Scope();
        LibraryLowerPermissions.AddPermissionSet('Fabric Exp Admin');

        //[WHEN] The token is cached with a 30-second TTL (below the 60-second safety margin)
        LookupState.SetFabricApiToken(Token, 30);

        //[THEN] The token is reported as not present
        Assert.IsFalse(LookupState.HasFabricApiToken(), 'Expected a token cached below the safety margin to be treated as expired.');
    end;

    [Test]
    procedure LookupStateClearRemovesCachedToken()
    var
        Token: SecretText;
    begin
        //[SCENARIO] Clearing the cache removes a previously cached token
        //[GIVEN] Initialize
        Initialize();
        //[GIVEN] A token is already cached
        Token := SecretStrSubstNo('sample-token');
        LookupState.SetFabricApiToken(Token, 3600);
        //[GIVEN] Lower permissions
        LibraryLowerPermissions.SetOutsideO365Scope();
        LibraryLowerPermissions.AddPermissionSet('Fabric Exp Admin');

        //[WHEN] The cache is cleared
        LookupState.ClearFabricApiToken();

        //[THEN] No token is reported as present
        Assert.IsFalse(LookupState.HasFabricApiToken(), 'Expected no token to be present after clearing the cache.');
    end;

    [Test]
    procedure CredentialMgtClientIdRoundTrips()
    var
        CredMgt: Codeunit "Fabric Platform Credential Mgt";
    begin
        //[SCENARIO] A Client ID stored through Credential Mgt is returned unchanged
        //[GIVEN] Initialize
        Initialize();
        //[GIVEN] Lower permissions
        LibraryLowerPermissions.SetOutsideO365Scope();
        LibraryLowerPermissions.AddPermissionSet('Fabric Exp Admin');

        //[WHEN] A client ID is stored
        CredMgt.SetClientId('11111111-1111-1111-1111-111111111111');

        //[THEN] The same client ID is returned
        Assert.AreEqual('11111111-1111-1111-1111-111111111111', CredMgt.GetClientId(), 'Expected the stored client ID to be returned.');
    end;

    [Test]
    procedure CredentialMgtPrincipalIdRoundTrips()
    var
        CredMgt: Codeunit "Fabric Platform Credential Mgt";
    begin
        //[SCENARIO] A Principal ID stored through Credential Mgt is returned unchanged
        //[GIVEN] Initialize
        Initialize();
        //[GIVEN] Lower permissions
        LibraryLowerPermissions.SetOutsideO365Scope();
        LibraryLowerPermissions.AddPermissionSet('Fabric Exp Admin');

        //[WHEN] A principal ID is stored
        CredMgt.SetPrincipalId('22222222-2222-2222-2222-222222222222');

        //[THEN] The same principal ID is returned
        Assert.AreEqual('22222222-2222-2222-2222-222222222222', CredMgt.GetPrincipalId(), 'Expected the stored principal ID to be returned.');
    end;

    [Test]
    procedure CredentialMgtOpenMirroringDatabaseNameRoundTrips()
    var
        CredMgt: Codeunit "Fabric Platform Credential Mgt";
    begin
        //[SCENARIO] An Open Mirroring database name stored through Credential Mgt is returned unchanged
        //[GIVEN] Initialize
        Initialize();
        //[GIVEN] Lower permissions
        LibraryLowerPermissions.SetOutsideO365Scope();
        LibraryLowerPermissions.AddPermissionSet('Fabric Exp Admin');

        //[WHEN] A database name is stored
        CredMgt.SetOpenMirroringDatabaseName('SalesMirror');

        //[THEN] The same database name is returned
        Assert.AreEqual('SalesMirror', CredMgt.GetOpenMirroringDatabaseName(), 'Expected the stored database name to be returned.');
    end;

    [Test]
    procedure CredentialMgtClientSecretIsNotSetByDefault()
    var
        CredMgt: Codeunit "Fabric Platform Credential Mgt";
        IsSet: Boolean;
    begin
        //[SCENARIO] IsClientSecretSet reports false when no secret has been stored
        //[GIVEN] Initialize
        Initialize();
        //[GIVEN] Lower permissions
        LibraryLowerPermissions.SetOutsideO365Scope();
        LibraryLowerPermissions.AddPermissionSet('Fabric Exp Admin');

        //[WHEN] IsClientSecretSet is queried
        IsSet := CredMgt.IsClientSecretSet();

        //[THEN] It reports false
        Assert.IsFalse(IsSet, 'Expected no client secret to be set by default.');
    end;

    [Test]
    procedure CredentialMgtSetClientSecretFailsWithoutEncryption()
    var
        CredMgt: Codeunit "Fabric Platform Credential Mgt";
        Secret: SecretText;
    begin
        //[SCENARIO] Storing a Client Secret is rejected when encryption is not enabled
        //[GIVEN] Initialize
        Initialize();
        //[GIVEN] A secret value to store
        Secret := SecretStrSubstNo('super-secret-value');
        //[GIVEN] Lower permissions
        LibraryLowerPermissions.SetOutsideO365Scope();
        LibraryLowerPermissions.AddPermissionSet('Fabric Exp Admin');

        //[WHEN] The secret is stored without encryption enabled
        asserterror CredMgt.SetClientSecret(Secret);

        //[THEN] The operation is rejected
        Assert.ExpectedError('encryption');
    end;

    [Test]
    procedure CredentialMgtClearTokenCacheClearsLookupState()
    var
        CredMgt: Codeunit "Fabric Platform Credential Mgt";
        Token: SecretText;
    begin
        //[SCENARIO] ClearTokenCache clears the cached Fabric API token
        //[GIVEN] Initialize
        Initialize();
        //[GIVEN] A token is already cached
        Token := SecretStrSubstNo('sample-token');
        LookupState.SetFabricApiToken(Token, 3600);
        //[GIVEN] Lower permissions
        LibraryLowerPermissions.SetOutsideO365Scope();
        LibraryLowerPermissions.AddPermissionSet('Fabric Exp Admin');

        //[WHEN] ClearTokenCache is called
        CredMgt.ClearTokenCache();

        //[THEN] No token is reported as present
        Assert.IsFalse(LookupState.HasFabricApiToken(), 'Expected the token cache to be cleared.');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure TestConnectionUsesSeamWithoutCallingPlatform()
    var
        FabricPlatformMgt: Codeunit "Fabric Platform Mgt";
    begin
        //[SCENARIO] TestConnection routes through the lifecycle seam
        //[GIVEN] Initialize
        Initialize();
        //[GIVEN] The lifecycle subscriber is bound so no real Fabric probe happens
        BindSubscription(PlatformTestSub);
        //[GIVEN] Lower permissions
        LibraryLowerPermissions.SetOutsideO365Scope();
        LibraryLowerPermissions.AddPermissionSet('Fabric Exp Admin');
        //[GIVEN] Expected success notification
        ExpectedMessages.Add(TestConnectionSuccessMsg);

        //[WHEN] TestConnection is requested
        FabricPlatformMgt.TestConnection();

        //[THEN] The seam fired and the real workspace probe was bypassed
        Assert.IsTrue(PlatformTestSub.WasTestConnectionCalled(), 'Expected the test-connection seam to fire.');
        UnbindSubscription(PlatformTestSub);
    end;

    [Test]
    procedure GetWorkspacesErrorsOnMalformedResponse()
    var
        AdminClient: Codeunit "Fabric Platform Admin Client";
        CredMgt: Codeunit "Fabric Platform Credential Mgt";
        TempBuffer: Record "Name/Value Buffer" temporary;
        Token: SecretText;
    begin
        //[SCENARIO] GetWorkspaces treats a success response without a value array as malformed
        //[GIVEN] Initialize
        Initialize();
        //[GIVEN] A cached Fabric API token so no real OAuth flow is triggered
        CredMgt.SetClientId('11111111-1111-1111-1111-111111111111');
        Token := SecretStrSubstNo('sample-token');
        LookupState.SetFabricApiToken(Token, 3600);
        //[GIVEN] The HTTP handler is mocked to return a success response without a value array
        BindSubscription(PlatformTestSub);
        PlatformTestSub.SetMockHttpResponse(200, '{}');
        //[GIVEN] Lower permissions
        LibraryLowerPermissions.SetOutsideO365Scope();
        LibraryLowerPermissions.AddPermissionSet('Fabric Exp Admin');

        //[WHEN] GetWorkspaces is called
        asserterror AdminClient.GetWorkspaces(TempBuffer);

        //[THEN] The malformed response is rejected
        Assert.ExpectedError('malformed');
        UnbindSubscription(PlatformTestSub);
    end;

    [Test]
    procedure GetMirroredDatabasesErrorsOnMalformedResponse()
    var
        AdminClient: Codeunit "Fabric Platform Admin Client";
        CredMgt: Codeunit "Fabric Platform Credential Mgt";
        TempBuffer: Record "Name/Value Buffer" temporary;
        Token: SecretText;
    begin
        //[SCENARIO] GetMirroredDatabases treats a success response without a value array as malformed
        //[GIVEN] Initialize
        Initialize();
        //[GIVEN] A cached Fabric API token so no real OAuth flow is triggered
        CredMgt.SetClientId('11111111-1111-1111-1111-111111111111');
        Token := SecretStrSubstNo('sample-token');
        LookupState.SetFabricApiToken(Token, 3600);
        //[GIVEN] The HTTP handler is mocked to return a success response without a value array
        BindSubscription(PlatformTestSub);
        PlatformTestSub.SetMockHttpResponse(200, '{}');
        //[GIVEN] Lower permissions
        LibraryLowerPermissions.SetOutsideO365Scope();
        LibraryLowerPermissions.AddPermissionSet('Fabric Exp Admin');

        //[WHEN] GetMirroredDatabases is called
        asserterror AdminClient.GetMirroredDatabases('11111111-1111-1111-1111-111111111111', TempBuffer);

        //[THEN] The malformed response is rejected
        Assert.ExpectedError('malformed');
        UnbindSubscription(PlatformTestSub);
    end;

    [Test]
    procedure ClaimTableCreatesRowAndClaimForNewTable()
    var
        TenantFabricTables: Record "Tenant Fabric Tables";
        FabricTableClaim: Record "Fabric Table Claim";
        FabricPlatformMgt: Codeunit "Fabric Platform Mgt";
    begin
        //[SCENARIO] Claiming an unclaimed table creates the platform row and a claim
        //[GIVEN] Initialize
        Initialize();
        //[GIVEN] Lower permissions
        LibraryLowerPermissions.SetOutsideO365Scope();
        LibraryLowerPermissions.AddPermissionSet('Fabric Exp Admin');

        //[WHEN] A package claims a table not yet selected
        FabricPlatformMgt.ClaimTable(Database::"Tenant Fabric Setup", "Fabric Table Claim Source"::Package, 'PKG-A');

        //[THEN] The platform row and the claim both exist
        Assert.IsTrue(TenantFabricTables.Get(Database::"Tenant Fabric Setup"), 'Expected the platform row to be created.');
        Assert.IsTrue(FabricTableClaim.Get(Database::"Tenant Fabric Setup", "Fabric Table Claim Source"::Package, 'PKG-A'), 'Expected the package claim to exist.');
    end;

    [Test]
    procedure ClaimTableAdoptsPreExistingRowAsManual()
    var
        TenantFabricTables: Record "Tenant Fabric Tables";
        FabricTableClaim: Record "Fabric Table Claim";
        FabricPlatformMgt: Codeunit "Fabric Platform Mgt";
    begin
        //[SCENARIO] Claiming a table that already exists without any claim adopts it as Manual first
        //[GIVEN] The table is already selected outside of any claim (e.g. legacy data)
        Initialize();
        TenantFabricTables.Init();
        TenantFabricTables."Table ID" := Database::"Tenant Fabric Setup";
        TenantFabricTables.Insert(false);
        //[GIVEN] Lower permissions
        LibraryLowerPermissions.SetOutsideO365Scope();
        LibraryLowerPermissions.AddPermissionSet('Fabric Exp Admin');

        //[WHEN] A package claims that same table
        FabricPlatformMgt.ClaimTable(Database::"Tenant Fabric Setup", "Fabric Table Claim Source"::Package, 'PKG-A');

        //[THEN] Both a Manual claim and the package claim exist
        Assert.IsTrue(FabricTableClaim.Get(Database::"Tenant Fabric Setup", "Fabric Table Claim Source"::Manual, ''), 'Expected the pre-existing row to be adopted as a Manual claim.');
        Assert.IsTrue(FabricTableClaim.Get(Database::"Tenant Fabric Setup", "Fabric Table Claim Source"::Package, 'PKG-A'), 'Expected the package claim to exist.');
    end;

    [Test]
    procedure ReleaseTableRemovesRowWhenLastClaimIsReleased()
    var
        TenantFabricTables: Record "Tenant Fabric Tables";
        FabricPlatformMgt: Codeunit "Fabric Platform Mgt";
    begin
        //[SCENARIO] Releasing the only claim on a table removes its platform row
        //[GIVEN] A table claimed by a single package
        Initialize();
        FabricPlatformMgt.ClaimTable(Database::"Tenant Fabric Setup", "Fabric Table Claim Source"::Package, 'PKG-A');
        //[GIVEN] Lower permissions
        LibraryLowerPermissions.SetOutsideO365Scope();
        LibraryLowerPermissions.AddPermissionSet('Fabric Exp Admin');

        //[WHEN] That package releases its claim
        FabricPlatformMgt.ReleaseTable(Database::"Tenant Fabric Setup", "Fabric Table Claim Source"::Package, 'PKG-A');

        //[THEN] The platform row is removed
        Assert.IsFalse(TenantFabricTables.Get(Database::"Tenant Fabric Setup"), 'Expected the platform row to be removed after the last claim is released.');
    end;

    [Test]
    procedure ReleaseTableKeepsRowWhenAnotherClaimRemains()
    var
        TenantFabricTables: Record "Tenant Fabric Tables";
        FabricTableClaim: Record "Fabric Table Claim";
        FabricPlatformMgt: Codeunit "Fabric Platform Mgt";
    begin
        //[SCENARIO] Releasing one of several claims keeps the platform row while other claims remain
        //[GIVEN] A table claimed both manually and by a package
        Initialize();
        FabricPlatformMgt.AddTable(Database::"Tenant Fabric Setup");
        FabricPlatformMgt.ClaimTable(Database::"Tenant Fabric Setup", "Fabric Table Claim Source"::Package, 'PKG-A');
        //[GIVEN] Lower permissions
        LibraryLowerPermissions.SetOutsideO365Scope();
        LibraryLowerPermissions.AddPermissionSet('Fabric Exp Admin');

        //[WHEN] The package claim is released
        FabricPlatformMgt.ReleaseTable(Database::"Tenant Fabric Setup", "Fabric Table Claim Source"::Package, 'PKG-A');

        //[THEN] The platform row and the Manual claim both remain
        Assert.IsTrue(TenantFabricTables.Get(Database::"Tenant Fabric Setup"), 'Expected the platform row to remain while the Manual claim exists.');
        Assert.IsTrue(FabricTableClaim.Get(Database::"Tenant Fabric Setup", "Fabric Table Claim Source"::Manual, ''), 'Expected the Manual claim to remain.');
    end;

    [Test]
    procedure IsClaimedByOthersReflectsRemainingClaims()
    var
        FabricPlatformMgt: Codeunit "Fabric Platform Mgt";
    begin
        //[SCENARIO] IsClaimedByOthers reports true only while a different claim exists
        //[GIVEN] A table claimed both manually and by a package
        Initialize();
        FabricPlatformMgt.AddTable(Database::"Tenant Fabric Setup");
        FabricPlatformMgt.ClaimTable(Database::"Tenant Fabric Setup", "Fabric Table Claim Source"::Package, 'PKG-A');
        //[GIVEN] Lower permissions
        LibraryLowerPermissions.SetOutsideO365Scope();
        LibraryLowerPermissions.AddPermissionSet('Fabric Exp Admin');

        //[WHEN] Checked before and after the Manual claim is released

        //[THEN] It reports true while the Manual claim exists, false once it is the only claim left
        Assert.IsTrue(
            FabricPlatformMgt.IsClaimedByOthers(Database::"Tenant Fabric Setup", "Fabric Table Claim Source"::Package, 'PKG-A'),
            'Expected the Manual claim to count as another claimant.');
        FabricPlatformMgt.ReleaseTable(Database::"Tenant Fabric Setup", "Fabric Table Claim Source"::Manual, '');
        Assert.IsFalse(
            FabricPlatformMgt.IsClaimedByOthers(Database::"Tenant Fabric Setup", "Fabric Table Claim Source"::Package, 'PKG-A'),
            'Expected no other claimant once the Manual claim is gone.');
    end;

    #region Handlers

    [MessageHandler]
    procedure MessageHandler(Message: Text[1024])
    var
        ExpectedMessage: Text;
    begin
        ExpectedMessage := ExpectedMessages.Get(1);
        ExpectedMessages.RemoveAt(1);
        Assert.ExpectedMessage(ExpectedMessage, Message);
    end;

    #endregion Handlers
}
