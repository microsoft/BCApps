namespace Microsoft.FabricExport;

using Microsoft.Sales.Customer;
using Microsoft.Utilities;
using System.Fabric;

codeunit 140013 "Test FAB API"
{
    //[FEATURE] Fabric mirroring API
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Assert";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        LookupState: Codeunit "Fabric Platform Lookup State";
        TableExistsErr: Label 'Table %1 is already selected for export.', Comment = '%1 = table id';
        CompanyExistsErr: Label 'Company %1 is already selected for export.', Comment = '%1 = company name';
        TableClaimedByPackageErr: Label 'Table %1 is included in an active configuration package. Deactivate or edit the package to remove it.', Comment = '%1 = table id';
        WorkspaceRoleAssignmentsUrlLbl: Label 'https://api.fabric.microsoft.com/v1/workspaces/11111111-1111-1111-1111-111111111111/roleAssignments', Locked = true;
        WorkspaceRoleAssignmentsNextPageUrlLbl: Label 'https://api.fabric.microsoft.com/v1/workspaces/11111111-1111-1111-1111-111111111111/roleAssignments?continuationToken=next%3D', Locked = true;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AddFirstTableThroughSetupAPI()
    var
        TenantFabricSetup: Record "Tenant Fabric Setup";
        FabricAPISetup: Page "Fabric API Setup";
        ActionContext: WebServiceActionContext;
    begin
        //[SCENARIO] Add the first table through the setup API
        //[GIVEN] Initialized with empty selections
        Initialize();
        //[GIVEN] Setup exists
        CreateSetup(TenantFabricSetup);
        //[GIVEN] API is bound to setup
        FabricAPISetup.SetRecord(TenantFabricSetup);
        //[GIVEN] Outside O365 permission scope
        LibraryLowerPermissions.SetOutsideO365Scope();
        //[GIVEN] Lowered permissions
        LibraryLowerPermissions.AddPermissionSet('Fabric Exp Admin');

        //[WHEN] Customer is added through the setup action
        FabricAPISetup.AddTable(Database::Customer, ActionContext);

        //[THEN] Customer is selected with a Manual claim
        VerifyTableSelected(Database::Customer);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AddFirstCompanyThroughSetupAPI()
    var
        TenantFabricSetup: Record "Tenant Fabric Setup";
        FabricAPISetup: Page "Fabric API Setup";
        ActionContext: WebServiceActionContext;
    begin
        //[SCENARIO] Add the first company through the setup API
        //[GIVEN] Initialized with empty selections
        Initialize();
        //[GIVEN] Setup exists
        CreateSetup(TenantFabricSetup);
        //[GIVEN] API is bound to setup
        FabricAPISetup.SetRecord(TenantFabricSetup);
        //[GIVEN] Outside O365 permission scope
        LibraryLowerPermissions.SetOutsideO365Scope();
        //[GIVEN] Lowered permissions
        LibraryLowerPermissions.AddPermissionSet('Fabric Exp Admin');

        //[WHEN] Current company is added through the setup action
        FabricAPISetup.AddCompany(CopyStr(CompanyName(), 1, 30), ActionContext);

        //[THEN] Current company is selected and enabled
        VerifyCompanySelected();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RejectDuplicateTableThroughSetupAPI()
    var
        TenantFabricSetup: Record "Tenant Fabric Setup";
        TenantFabricTables: Record "Tenant Fabric Tables";
        FabricTableClaim: Record "Fabric Table Claim";
        FabricAPISetup: Page "Fabric API Setup";
        ActionContext: WebServiceActionContext;
        ActionSucceeded: Boolean;
    begin
        //[SCENARIO] Add an already selected table through the setup API
        //[GIVEN] Initialized
        Initialize();
        //[GIVEN] Setup exists
        CreateSetup(TenantFabricSetup);
        //[GIVEN] Customer is selected
        CreateSelectedTable(TenantFabricTables);
        //[GIVEN] Customer has a Manual claim
        CreateTableClaim(FabricTableClaim, "Fabric Table Claim Source"::Manual, '');
        //[GIVEN] API is bound to setup
        FabricAPISetup.SetRecord(TenantFabricSetup);
        //[GIVEN] Outside O365 permission scope
        LibraryLowerPermissions.SetOutsideO365Scope();
        //[GIVEN] Lowered permissions
        LibraryLowerPermissions.AddPermissionSet('Fabric Exp Admin');

        //[WHEN] Customer is added again through the setup action
        ActionSucceeded := TryAddTableThroughSetupAPI(FabricAPISetup, ActionContext);

        //[THEN] Duplicate error is raised and the original selection remains
        VerifyDuplicateTableRejected(ActionSucceeded, TenantFabricTables, FabricTableClaim);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RejectDuplicateCompanyThroughSetupAPI()
    var
        TenantFabricSetup: Record "Tenant Fabric Setup";
        TenantFabricCompanies: Record "Tenant Fabric Companies";
        FabricAPISetup: Page "Fabric API Setup";
        ActionContext: WebServiceActionContext;
        ActionSucceeded: Boolean;
    begin
        //[SCENARIO] Add an already selected company through the setup API
        //[GIVEN] Initialized
        Initialize();
        //[GIVEN] Setup exists
        CreateSetup(TenantFabricSetup);
        //[GIVEN] Current company is selected
        CreateSelectedCompany(TenantFabricCompanies);
        //[GIVEN] API is bound to setup
        FabricAPISetup.SetRecord(TenantFabricSetup);
        //[GIVEN] Outside O365 permission scope
        LibraryLowerPermissions.SetOutsideO365Scope();
        //[GIVEN] Lowered permissions
        LibraryLowerPermissions.AddPermissionSet('Fabric Exp Admin');

        //[WHEN] Current company is added again through the setup action
        ActionSucceeded := TryAddCompanyThroughSetupAPI(FabricAPISetup, TenantFabricCompanies."Company Name", ActionContext);

        //[THEN] Duplicate error is raised and the original selection remains
        VerifyDuplicateCompanyRejected(ActionSucceeded, TenantFabricCompanies);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RemoveManualTableThroughAPI()
    var
        TenantFabricTables: Record "Tenant Fabric Tables";
        FabricTableClaim: Record "Fabric Table Claim";
        FabricAPITables: Page "Fabric API Tables";
        ActionContext: WebServiceActionContext;
    begin
        //[SCENARIO] Remove a manually selected table through the API
        //[GIVEN] Initialized
        Initialize();
        //[GIVEN] Customer is selected
        CreateSelectedTable(TenantFabricTables);
        //[GIVEN] Customer has a Manual claim
        CreateTableClaim(FabricTableClaim, "Fabric Table Claim Source"::Manual, '');
        //[GIVEN] API is bound to Customer selection
        FabricAPITables.SetRecord(TenantFabricTables);
        //[GIVEN] Outside O365 permission scope
        LibraryLowerPermissions.SetOutsideO365Scope();
        //[GIVEN] Lowered permissions
        LibraryLowerPermissions.AddPermissionSet('Fabric Exp Admin');

        //[WHEN] Customer is removed through the row action
        FabricAPITables.RemoveTable(ActionContext);

        //[THEN] Customer selection and its claim are removed
        VerifyTableRemoved(TenantFabricTables."Table ID");
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RemoveUnclaimedTableThroughAPI()
    var
        TenantFabricTables: Record "Tenant Fabric Tables";
        FabricAPITables: Page "Fabric API Tables";
        ActionContext: WebServiceActionContext;
    begin
        //[SCENARIO] Remove a table without claims through the API
        //[GIVEN] Initialized
        Initialize();
        //[GIVEN] Customer is selected without claims
        CreateSelectedTable(TenantFabricTables);
        //[GIVEN] API is bound to Customer selection
        FabricAPITables.SetRecord(TenantFabricTables);
        //[GIVEN] Outside O365 permission scope
        LibraryLowerPermissions.SetOutsideO365Scope();
        //[GIVEN] Lowered permissions
        LibraryLowerPermissions.AddPermissionSet('Fabric Exp Admin');

        //[WHEN] Customer is removed through the row action
        FabricAPITables.RemoveTable(ActionContext);

        //[THEN] Customer selection is removed
        VerifyTableRemoved(TenantFabricTables."Table ID");
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RejectRemovePackageClaimedTableThroughAPI()
    var
        TenantFabricTables: Record "Tenant Fabric Tables";
        ManualClaim: Record "Fabric Table Claim";
        PackageClaim: Record "Fabric Table Claim";
        FabricAPITables: Page "Fabric API Tables";
        ActionContext: WebServiceActionContext;
        ActionSucceeded: Boolean;
    begin
        //[SCENARIO] Remove a table claimed by a configuration package through the API
        //[GIVEN] Initialized
        Initialize();
        //[GIVEN] Customer is selected
        CreateSelectedTable(TenantFabricTables);
        //[GIVEN] Customer has a Manual claim
        CreateTableClaim(ManualClaim, "Fabric Table Claim Source"::Manual, '');
        //[GIVEN] Customer also has a package claim
        CreateTableClaim(PackageClaim, "Fabric Table Claim Source"::Package, 'API-TEST');
        //[GIVEN] API is bound to Customer selection
        FabricAPITables.SetRecord(TenantFabricTables);
        //[GIVEN] Outside O365 permission scope
        LibraryLowerPermissions.SetOutsideO365Scope();
        //[GIVEN] Lowered permissions
        LibraryLowerPermissions.AddPermissionSet('Fabric Exp Admin');

        //[WHEN] Customer is removed through the row action
        ActionSucceeded := TryRemoveTableThroughAPI(FabricAPITables, ActionContext);

        //[THEN] Package-protection error is raised and selection and claims remain
        VerifyPackageTableRemovalRejected(ActionSucceeded, TenantFabricTables, ManualClaim, PackageClaim);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RemoveCompanyThroughAPI()
    var
        TenantFabricCompanies: Record "Tenant Fabric Companies";
        FabricAPICompanies: Page "Fabric API Companies";
        ActionContext: WebServiceActionContext;
    begin
        //[SCENARIO] Remove a selected company through the API
        //[GIVEN] Initialized
        Initialize();
        //[GIVEN] Current company is selected
        CreateSelectedCompany(TenantFabricCompanies);
        //[GIVEN] API is bound to company selection
        FabricAPICompanies.SetRecord(TenantFabricCompanies);
        //[GIVEN] Outside O365 permission scope
        LibraryLowerPermissions.SetOutsideO365Scope();
        //[GIVEN] Lowered permissions
        LibraryLowerPermissions.AddPermissionSet('Fabric Exp Admin');

        //[WHEN] Company is removed through the row action
        FabricAPICompanies.RemoveCompany(ActionContext);

        //[THEN] Company selection is removed
        VerifyCompanyRemoved(TenantFabricCompanies."Company Name");
    end;

    [Test]
    procedure GetWorkspacesShowsHttpFailureMessage()
    var
        TempBuffer: Record "Name/Value Buffer" temporary;
        AdminClient: Codeunit "Fabric Platform Admin Client";
        FabricPrivacyNotice: Codeunit "Fabric Privacy Notice";
        PlatformTestSub: Codeunit "Fabric Platform Test Sub";
        SampleTokenLbl: Label 'sample-token0', Locked = true;
        Token: SecretText;
    begin
        InitializeAdminClient();
        FabricPrivacyNotice.Approve();
        Token := SecretStrSubstNo(SampleTokenLbl);
        LookupState.SetFabricApiToken(Token, 3600);
        PlatformTestSub.AddMockHttpResponse(403, '{}', 'GET', 'https://api.fabric.microsoft.com/v1/workspaces');
        BindSubscription(PlatformTestSub);
        LibraryLowerPermissions.SetOutsideO365Scope();
        LibraryLowerPermissions.AddPermissionSet('Fabric Exp Admin');

        asserterror AdminClient.GetWorkspaces(TempBuffer);

        Assert.ExpectedError('Failed to retrieve workspaces. Contact your administrator if the problem persists.');
        PlatformTestSub.AssertHttpRequestsComplete();
        UnbindSubscription(PlatformTestSub);
    end;

    [Test]
    procedure GetWorkspacesErrorsOnMalformedResponse()
    var
        TempBuffer: Record "Name/Value Buffer" temporary;
        AdminClient: Codeunit "Fabric Platform Admin Client";
        CredMgt: Codeunit "Fabric Platform Credential Mgt";
        FabricPrivacyNotice: Codeunit "Fabric Privacy Notice";
        PlatformTestSub: Codeunit "Fabric Platform Test Sub";
        SampleTokenLbl: Label 'sample-token0', Locked = true;
        Token: SecretText;
    begin
        //[SCENARIO] GetWorkspaces treats a success response without a value array as malformed
        //[GIVEN] Initialize
        InitializeAdminClient();
        //[GIVEN] The privacy notice is approved so the mandatory consent gate passes
        FabricPrivacyNotice.Approve();
        //[GIVEN] A cached Fabric API token so no real OAuth flow is triggered
        CredMgt.SetClientId('11111111-1111-1111-1111-111111111111');
        Token := SecretStrSubstNo(SampleTokenLbl);
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
        TempBuffer: Record "Name/Value Buffer" temporary;
        AdminClient: Codeunit "Fabric Platform Admin Client";
        CredMgt: Codeunit "Fabric Platform Credential Mgt";
        FabricPrivacyNotice: Codeunit "Fabric Privacy Notice";
        PlatformTestSub: Codeunit "Fabric Platform Test Sub";
        SampleTokenLbl: Label 'sample-token0', Locked = true;
        Token: SecretText;
    begin
        //[SCENARIO] GetMirroredDatabases treats a success response without a value array as malformed
        //[GIVEN] Initialize
        InitializeAdminClient();
        //[GIVEN] The privacy notice is approved so the mandatory consent gate passes
        FabricPrivacyNotice.Approve();
        //[GIVEN] A cached Fabric API token so no real OAuth flow is triggered
        CredMgt.SetClientId('11111111-1111-1111-1111-111111111111');
        Token := SecretStrSubstNo(SampleTokenLbl);
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
    procedure AddServicePrincipalToWorkspaceSucceeds()
    var
        CredMgt: Codeunit "Fabric Platform Credential Mgt";
        FabricPrivacyNotice: Codeunit "Fabric Privacy Notice";
        PlatformTestSub: Codeunit "Fabric Platform Test Sub";
        Token: SecretText;
        SampleTokenLbl: Label 'sample-token0', Locked = true;
        Success: Boolean;
    begin
        //[SCENARIO] AddServicePrincipalToWorkspace succeeds on a successful Fabric response
        //[GIVEN] Initialize
        InitializeAdminClient();
        //[GIVEN] The privacy notice is approved so the mandatory consent gate passes
        FabricPrivacyNotice.Approve();
        //[GIVEN] A cached Fabric API token so no real OAuth flow is triggered
        CredMgt.SetClientId('11111111-1111-1111-1111-111111111111');
        Token := SecretStrSubstNo(SampleTokenLbl);
        LookupState.SetFabricApiToken(Token, 3600);
        //[GIVEN] The HTTP handler is mocked to return a successful role assignment response
        BindSubscription(PlatformTestSub);
        PlatformTestSub.SetMockHttpResponse(200, '{}');
        //[GIVEN] Lower permissions
        LibraryLowerPermissions.SetOutsideO365Scope();
        LibraryLowerPermissions.AddPermissionSet('Fabric Exp Admin');

        //[WHEN] The service principal is added to the workspace
        Success := TryAddServicePrincipalToWorkspace('11111111-1111-1111-1111-111111111111', '22222222-2222-2222-2222-222222222222');

        //[THEN] The call completes without error
        Assert.IsTrue(Success, 'Expected AddServicePrincipalToWorkspace to succeed on a 200 response.');
        UnbindSubscription(PlatformTestSub);
    end;

    [Test]
    procedure AddConnectionRequiresPrincipalIdForFirstParty()
    begin
        VerifyAddConnectionRequiresPrincipalId(false);
    end;

    [Test]
    procedure AddConnectionRequiresPrincipalIdForCustomApp()
    begin
        VerifyAddConnectionRequiresPrincipalId(true);
    end;

    [Test]
    procedure AddServicePrincipalToWorkspaceSucceedsWhenAlreadyContributor()
    var
        AdminClient: Codeunit "Fabric Platform Admin Client";
        PlatformTestSub: Codeunit "Fabric Platform Test Sub";
    begin
        //[GIVEN] The principal already has Contributor access
        InitializeWorkspaceRoleConflict(PlatformTestSub);
        PlatformTestSub.AddMockHttpResponse(200, GetWorkspaceRoleResponse('22222222-2222-2222-2222-222222222222', 'Contributor', ''), 'GET', WorkspaceRoleAssignmentsUrlLbl);

        //[WHEN] Adding the principal returns a conflict
        AdminClient.AddServicePrincipalToWorkspace('11111111-1111-1111-1111-111111111111', '22222222-2222-2222-2222-222222222222');

        //[THEN] Existing access is verified before reporting success
        PlatformTestSub.AssertHttpRequestsComplete();
        UnbindSubscription(PlatformTestSub);
    end;

    [Test]
    procedure AddServicePrincipalToWorkspaceFailsForExistingViewer()
    var
        AdminClient: Codeunit "Fabric Platform Admin Client";
        PlatformTestSub: Codeunit "Fabric Platform Test Sub";
    begin
        //[GIVEN] The principal only has Viewer access
        InitializeWorkspaceRoleConflict(PlatformTestSub);
        PlatformTestSub.AddMockHttpResponse(200, GetWorkspaceRoleResponse('22222222-2222-2222-2222-222222222222', 'Viewer', ''), 'GET', WorkspaceRoleAssignmentsUrlLbl);

        //[WHEN] Adding the principal returns a conflict
        asserterror AdminClient.AddServicePrincipalToWorkspace('11111111-1111-1111-1111-111111111111', '22222222-2222-2222-2222-222222222222');

        //[THEN] Contributor-or-higher access is required
        Assert.ExpectedError('Contributor, Member, or Admin');
        PlatformTestSub.AssertHttpRequestsComplete();
        UnbindSubscription(PlatformTestSub);
    end;

    [Test]
    procedure AddServicePrincipalToWorkspaceChecksRolesOnNextPage()
    var
        AdminClient: Codeunit "Fabric Platform Admin Client";
        PlatformTestSub: Codeunit "Fabric Platform Test Sub";
    begin
        //[GIVEN] Another principal is on the first page and this principal is an Admin on the next
        InitializeWorkspaceRoleConflict(PlatformTestSub);
        PlatformTestSub.AddMockHttpResponse(200, GetWorkspaceRoleResponse('33333333-3333-3333-3333-333333333333', 'Contributor', WorkspaceRoleAssignmentsNextPageUrlLbl), 'GET', WorkspaceRoleAssignmentsUrlLbl);
        PlatformTestSub.AddMockHttpResponse(200, GetWorkspaceRoleResponse('22222222-2222-2222-2222-222222222222', 'Admin', ''), 'GET', WorkspaceRoleAssignmentsNextPageUrlLbl);

        //[WHEN] Adding the principal returns a conflict
        AdminClient.AddServicePrincipalToWorkspace('11111111-1111-1111-1111-111111111111', '22222222-2222-2222-2222-222222222222');

        //[THEN] All pages are checked and higher access is accepted
        PlatformTestSub.AssertHttpRequestsComplete();
        UnbindSubscription(PlatformTestSub);
    end;

    [Test]
    procedure AddServicePrincipalToWorkspaceFailsWhenRoleLookupFails()
    var
        AdminClient: Codeunit "Fabric Platform Admin Client";
        PlatformTestSub: Codeunit "Fabric Platform Test Sub";
    begin
        //[GIVEN] Existing workspace roles cannot be read
        InitializeWorkspaceRoleConflict(PlatformTestSub);
        PlatformTestSub.AddMockHttpResponse(403, '{}', 'GET', WorkspaceRoleAssignmentsUrlLbl);

        //[WHEN] Adding the principal returns a conflict
        asserterror AdminClient.AddServicePrincipalToWorkspace('11111111-1111-1111-1111-111111111111', '22222222-2222-2222-2222-222222222222');

        //[THEN] Failure to verify access is not treated as success
        Assert.ExpectedError('Failed to verify the existing workspace role');
        PlatformTestSub.AssertHttpRequestsComplete();
        UnbindSubscription(PlatformTestSub);
    end;

    #region given
    local procedure Initialize()
    var
        TenantFabricSetup: Record "Tenant Fabric Setup";
        TenantFabricTables: Record "Tenant Fabric Tables";
        TenantFabricTableFields: Record "Tenant Fabric Table Fields";
        TenantFabricCompanies: Record "Tenant Fabric Companies";
        FabricTableClaim: Record "Fabric Table Claim";
    begin
        FabricTableClaim.DeleteAll(false);
        TenantFabricTableFields.DeleteAll(false);
        TenantFabricTables.DeleteAll(false);
        TenantFabricCompanies.DeleteAll(false);
        TenantFabricSetup.DeleteAll(false);
    end;

    local procedure InitializeAdminClient()
    var
        TenantFabricSetup: Record "Tenant Fabric Setup";
        TenantFabricTables: Record "Tenant Fabric Tables";
        TenantFabricTableFields: Record "Tenant Fabric Table Fields";
        TenantFabricCompanies: Record "Tenant Fabric Companies";
        FabricTableClaim: Record "Fabric Table Claim";
        TenantFabricExportSummary: Record "Tenant Fabric Export Summary";
        TenantFabricExportDetails: Record "Tenant Fabric Export Details";
        CredMgt: Codeunit "Fabric Platform Credential Mgt";
        PlatformTestSub: Codeunit "Fabric Platform Test Sub";
    begin
        TenantFabricTables.DeleteAll(false);
        TenantFabricTableFields.DeleteAll(false);
        TenantFabricSetup.DeleteAll(false);
        TenantFabricCompanies.DeleteAll(false);
        FabricTableClaim.DeleteAll(false);
        TenantFabricExportSummary.DeleteAll(false);
        TenantFabricExportDetails.DeleteAll(false);
        PlatformTestSub.Reset();
        LookupState.ClearFabricApiToken();
        // Isolated Storage is not rolled back between tests, unlike table data.
        CredMgt.ClearEnvironmentCredentials();
    end;

    local procedure InitializeWorkspaceRoleConflict(var PlatformTestSub: Codeunit "Fabric Platform Test Sub")
    var
        FabricPrivacyNotice: Codeunit "Fabric Privacy Notice";
        Token: SecretText;
        SampleTokenLbl: Label 'sample-token0', Locked = true;
    begin
        InitializeAdminClient();
        FabricPrivacyNotice.Approve();
        Token := SecretStrSubstNo(SampleTokenLbl);
        LookupState.SetFabricApiToken(Token, 3600);
        PlatformTestSub.SetMockHttpResponse(409, '{}');
        BindSubscription(PlatformTestSub);
        LibraryLowerPermissions.SetOutsideO365Scope();
        LibraryLowerPermissions.AddPermissionSet('Fabric Exp Admin');
    end;

    local procedure GetWorkspaceRoleResponse(PrincipalId: Text; Role: Text; ContinuationUri: Text) ResponseBody: Text
    var
        RootObj: JsonObject;
        AssignmentObj: JsonObject;
        PrincipalObj: JsonObject;
        Assignments: JsonArray;
    begin
        PrincipalObj.Add('id', PrincipalId);
        AssignmentObj.Add('principal', PrincipalObj);
        AssignmentObj.Add('role', Role);
        Assignments.Add(AssignmentObj);
        RootObj.Add('value', Assignments);
        if ContinuationUri <> '' then
            RootObj.Add('continuationUri', ContinuationUri);
        RootObj.WriteTo(ResponseBody);
    end;

    local procedure CreateSetup(var TenantFabricSetup: Record "Tenant Fabric Setup")
    begin
        TenantFabricSetup.Init();
        TenantFabricSetup."Max Consecutive Failed Runs" := 2;
        TenantFabricSetup."Fabric Data Namespace" := 'BusinessCentral';
        TenantFabricSetup."Fabric Logging Namespace" := 'BusinessCentral_log';
        TenantFabricSetup.Insert(false);
    end;

    local procedure CreateSelectedTable(var TenantFabricTables: Record "Tenant Fabric Tables")
    begin
        TenantFabricTables.Init();
        TenantFabricTables."Table ID" := Database::Customer;
        TenantFabricTables."Table Name" := 'Customer';
        TenantFabricTables."Fabric Entity Name" := 'customer';
        TenantFabricTables."Per Company" := true;
        TenantFabricTables.Insert(false);
    end;

    local procedure CreateSelectedCompany(var TenantFabricCompanies: Record "Tenant Fabric Companies")
    begin
        TenantFabricCompanies.Init();
        TenantFabricCompanies."Company Name" := CopyStr(CompanyName(), 1, MaxStrLen(TenantFabricCompanies."Company Name"));
        TenantFabricCompanies.Enabled := true;
        TenantFabricCompanies.Insert(false);
    end;

    local procedure CreateTableClaim(var FabricTableClaim: Record "Fabric Table Claim"; SourceType: Enum "Fabric Table Claim Source"; PackageCode: Code[20])
    begin
        FabricTableClaim.Init();
        FabricTableClaim."Table ID" := Database::Customer;
        FabricTableClaim."Source Type" := SourceType;
        FabricTableClaim."Package Code" := PackageCode;
        FabricTableClaim.Insert(false);
    end;
    #endregion

    #region when
    // Catch guard errors without rolling back the fixtures needed by unchanged-state assertions.
    [TryFunction]
    local procedure TryAddTableThroughSetupAPI(var FabricAPISetup: Page "Fabric API Setup"; var ActionContext: WebServiceActionContext)
    begin
        ClearLastError();
        FabricAPISetup.AddTable(Database::Customer, ActionContext);
    end;

    [TryFunction]
    local procedure TryAddCompanyThroughSetupAPI(var FabricAPISetup: Page "Fabric API Setup"; SelectedCompanyName: Text[30]; var ActionContext: WebServiceActionContext)
    begin
        ClearLastError();
        FabricAPISetup.AddCompany(SelectedCompanyName, ActionContext);
    end;

    [TryFunction]
    local procedure TryRemoveTableThroughAPI(var FabricAPITables: Page "Fabric API Tables"; var ActionContext: WebServiceActionContext)
    begin
        ClearLastError();
        FabricAPITables.RemoveTable(ActionContext);
    end;

    [TryFunction]
    local procedure TryAddServicePrincipalToWorkspace(WorkspaceId: Text; PrincipalId: Text)
    var
        AdminClient: Codeunit "Fabric Platform Admin Client";
    begin
        AdminClient.AddServicePrincipalToWorkspace(WorkspaceId, PrincipalId);
    end;
    #endregion

    #region then
    local procedure VerifyAddConnectionRequiresPrincipalId(UseCustomApp: Boolean)
    var
        AdminClient: Codeunit "Fabric Platform Admin Client";
        CredMgt: Codeunit "Fabric Platform Credential Mgt";
        FabricPrivacyNotice: Codeunit "Fabric Privacy Notice";
    begin
        InitializeAdminClient();
        CredMgt.SetCustomAppEnabled(UseCustomApp);
        FabricPrivacyNotice.Approve();
        LibraryLowerPermissions.SetOutsideO365Scope();
        LibraryLowerPermissions.AddPermissionSet('Fabric Exp Admin');

        asserterror AdminClient.AddConnectionToWorkspace('11111111-1111-1111-1111-111111111111');

        Assert.ExpectedError('Principal ID is missing');
    end;

    local procedure VerifyTableSelected(TableId: Integer)
    var
        TenantFabricTables: Record "Tenant Fabric Tables";
        FabricTableClaim: Record "Fabric Table Claim";
    begin
        Assert.AreEqual(1, TenantFabricTables.Count(), 'Expected exactly one selected table.');
        Assert.IsTrue(TenantFabricTables.Get(TableId), 'Expected Customer to be selected.');
        Assert.AreEqual('Customer', TenantFabricTables."Table Name", 'Unexpected selected table name.');
        Assert.AreEqual('customer', TenantFabricTables."Fabric Entity Name", 'Unexpected Fabric entity name.');
        Assert.IsTrue(TenantFabricTables."Per Company", 'Expected Customer to be a per-company table.');
        Assert.IsTrue(FabricTableClaim.Get(TableId, "Fabric Table Claim Source"::Manual, ''), 'Expected a Manual claim.');
        FabricTableClaim.SetRange("Table ID", TableId);
        Assert.AreEqual(1, FabricTableClaim.Count(), 'Expected exactly one claim for Customer.');
    end;

    local procedure VerifyCompanySelected()
    var
        TenantFabricCompanies: Record "Tenant Fabric Companies";
    begin
        Assert.AreEqual(1, TenantFabricCompanies.Count(), 'Expected exactly one selected company.');
        Assert.IsTrue(TenantFabricCompanies.Get(CompanyName()), 'Expected the current company to be selected.');
        Assert.IsTrue(TenantFabricCompanies.Enabled, 'Expected the selected company to be enabled.');
    end;

    local procedure VerifyDuplicateTableRejected(ActionSucceeded: Boolean; ExpectedTable: Record "Tenant Fabric Tables"; ExpectedClaim: Record "Fabric Table Claim")
    var
        TenantFabricTables: Record "Tenant Fabric Tables";
        FabricTableClaim: Record "Fabric Table Claim";
    begin
        VerifyActionRejected(ActionSucceeded, StrSubstNo(TableExistsErr, ExpectedTable."Table ID"));
        VerifyTableSelected(ExpectedTable."Table ID");
        TenantFabricTables.Get(ExpectedTable."Table ID");
        Assert.AreEqual(ExpectedTable.SystemId, TenantFabricTables.SystemId, 'Expected the original table selection to remain.');
        FabricTableClaim.Get(ExpectedClaim."Table ID", ExpectedClaim."Source Type", ExpectedClaim."Package Code");
        Assert.AreEqual(ExpectedClaim.SystemId, FabricTableClaim.SystemId, 'Expected the original claim to remain.');
    end;

    local procedure VerifyDuplicateCompanyRejected(ActionSucceeded: Boolean; ExpectedCompany: Record "Tenant Fabric Companies")
    var
        TenantFabricCompanies: Record "Tenant Fabric Companies";
    begin
        VerifyActionRejected(ActionSucceeded, StrSubstNo(CompanyExistsErr, ExpectedCompany."Company Name"));
        VerifyCompanySelected();
        TenantFabricCompanies.Get(ExpectedCompany."Company Name");
        Assert.AreEqual(ExpectedCompany.SystemId, TenantFabricCompanies.SystemId, 'Expected the original company selection to remain.');
    end;

    local procedure VerifyTableRemoved(TableId: Integer)
    var
        TenantFabricTables: Record "Tenant Fabric Tables";
        FabricTableClaim: Record "Fabric Table Claim";
    begin
        Assert.IsFalse(TenantFabricTables.Get(TableId), 'Expected the table selection to be removed.');
        FabricTableClaim.SetRange("Table ID", TableId);
        Assert.IsTrue(FabricTableClaim.IsEmpty(), 'Expected all claims for the removed table to be removed.');
    end;

    local procedure VerifyPackageTableRemovalRejected(ActionSucceeded: Boolean; ExpectedTable: Record "Tenant Fabric Tables"; ExpectedManualClaim: Record "Fabric Table Claim"; ExpectedPackageClaim: Record "Fabric Table Claim")
    var
        TenantFabricTables: Record "Tenant Fabric Tables";
        FabricTableClaim: Record "Fabric Table Claim";
    begin
        VerifyActionRejected(ActionSucceeded, StrSubstNo(TableClaimedByPackageErr, ExpectedTable."Table ID"));
        Assert.IsTrue(TenantFabricTables.Get(ExpectedTable."Table ID"), 'Expected the package-claimed table selection to remain.');
        Assert.AreEqual(ExpectedTable.SystemId, TenantFabricTables.SystemId, 'Expected the original table selection to remain.');
        Assert.IsTrue(FabricTableClaim.Get(ExpectedManualClaim."Table ID", ExpectedManualClaim."Source Type", ExpectedManualClaim."Package Code"), 'Expected the Manual claim to remain.');
        Assert.AreEqual(ExpectedManualClaim.SystemId, FabricTableClaim.SystemId, 'Expected the original Manual claim to remain.');
        Assert.IsTrue(FabricTableClaim.Get(ExpectedPackageClaim."Table ID", ExpectedPackageClaim."Source Type", ExpectedPackageClaim."Package Code"), 'Expected the package claim to remain.');
        Assert.AreEqual(ExpectedPackageClaim.SystemId, FabricTableClaim.SystemId, 'Expected the original package claim to remain.');
        FabricTableClaim.SetRange("Table ID", ExpectedTable."Table ID");
        Assert.AreEqual(2, FabricTableClaim.Count(), 'Expected both claims to remain.');
    end;

    local procedure VerifyActionRejected(ActionSucceeded: Boolean; ExpectedErrorText: Text)
    var
        ActualErrorText: Text;
        ActualErrorCode: Text;
    begin
        ActualErrorText := GetLastErrorText();
        ActualErrorCode := GetLastErrorCode();
        Assert.IsFalse(ActionSucceeded, 'Expected the API action to fail.');
        Assert.AreEqual(ExpectedErrorText, ActualErrorText, 'Unexpected API error.');
        Assert.AreEqual('Dialog', ActualErrorCode, 'Unexpected API error code.');
    end;

    local procedure VerifyCompanyRemoved(SelectedCompanyName: Text[30])
    var
        TenantFabricCompanies: Record "Tenant Fabric Companies";
    begin
        Assert.IsFalse(TenantFabricCompanies.Get(SelectedCompanyName), 'Expected the company selection to be removed.');
    end;
    #endregion
}
