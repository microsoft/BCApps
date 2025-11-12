codeunit 139400 "Permissions Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Permissions]
    end;

    var
        LibraryUtility: Codeunit "Library - Utility";
        LibraryPermissions: Codeunit "Library - Permissions";
        AzureADPlanTestLibrary: Codeunit "Azure AD Plan Test Library";
        LibraryTextFileValidation: Codeunit "Library - Text File Validation";
        LibraryPlainTextFile: Codeunit "Library - Plain Text File";
        Assert: Codeunit Assert;
        BaseAppID: Codeunit "BaseApp ID";
        PermissionSetNonExistentTxt: Label 'Non-existent';
        PlanSmallBusinessTxt: Label 'Plan-SmallB-Test';
        PlanOffice365Txt: Label 'Plan-Office365-Test';
        PlanOffice365ExtraTxt: Label 'Plan-Office365Ext-Test';
        UserCassieTxt: Label 'User-Cassie-Test';
        UserDebraTxt: Label 'User-Debra-Test';
        ImportEmptyFileErr: Label 'Cannot import the specified XML document because the file is empty.';
        ResolvePermissionNotificationIdTxt: Label '3301a843-3a72-4777-83a2-a1eeb2041efa', Locked = true;
        NullGuid: Guid;

    [Test]
    [Scope('OnPrem')]
    procedure UserWithoutPlansKeepReviewedStatusForOnSaaS()
    var
        UserSecurityStatus: Record "User Security Status";
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
        Cassie: Guid;
    begin
        // [SCENARIO] When a user has no plans, the reviewed status is not changed for OnPrem
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);
        // [GIVEN] User Cassie
        Cassie := LibraryPermissions.CreateUserWithName(UserCassieTxt);
        // [GIVEN] Cassie is not marked for review by the security admin
        UserSecurityStatus.LoadUsers();
        UserSecurityStatus.Get(Cassie);
        UserSecurityStatus.Reviewed := true;
        UserSecurityStatus.Modify(true);

        // [WHEN] User Security Status is reloaded
        UserSecurityStatus.LoadUsers();

        // [THEN] Cassie is still marked as Reviewed = TRUE
        UserSecurityStatus.Get(Cassie);
        Assert.IsTrue(UserSecurityStatus.Reviewed, 'User Cassie should have status = reviewed');

        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UserWithoutPlansKeepReviewedStatusForOnPrem()
    var
        UserSecurityStatus: Record "User Security Status";
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
        Cassie: Guid;
    begin
        // [SCENARIO] When a user has no plans, the reviewed status is not changed for OnPrem
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);
        // [GIVEN] User Cassie
        Cassie := LibraryPermissions.CreateUserWithName(UserCassieTxt);
        // [GIVEN] Cassie is not marked for review by the security admin
        UserSecurityStatus.LoadUsers();
        UserSecurityStatus.Get(Cassie);
        UserSecurityStatus.Reviewed := true;
        UserSecurityStatus.Modify(true);

        // [WHEN] User Security Status is reloaded
        UserSecurityStatus.LoadUsers();

        // [THEN] Cassie is still marked as Reviewed = TRUE
        UserSecurityStatus.Get(Cassie);
        Assert.IsTrue(UserSecurityStatus.Reviewed, 'User Cassie should have status = reviewed');

        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LoadUsersInTableUserSecurityStatus()
    var
        UserSecurityStatus: Record "User Security Status";
        PlanID: Guid;
        Cassie: Guid;
        Debra: Guid;
    begin
        // [SCENARIO] Last plan removed from user, tags it as "to review" by the security admin

        // [GIVEN] Plan Office365
        PlanID := AzureADPlanTestLibrary.CreatePlan(PlanOffice365Txt);
        // [GIVEN] User Cassie, user Debra
        Cassie := LibraryPermissions.CreateUserWithName(UserCassieTxt);
        Debra := LibraryPermissions.CreateUserWithName(UserDebraTxt);

        // [GIVEN] Cassie and Debra are part of Office365
        LibraryPermissions.AddUserToPlan(Cassie, PlanID);
        LibraryPermissions.AddUserToPlan(Debra, PlanID);

        // [WHEN] Loading users into UserSecurityStatus
        UserSecurityStatus.LoadUsers();

        // [THEN] Users are Cassie and Debra have been added to UserSecurityStatus
        Assert.IsTrue(UserSecurityStatus.Get(Cassie), 'Cassie doesn''t exist in table UserSecurityStatus');
        Assert.IsFalse(UserSecurityStatus.Reviewed, 'Cassie should be tagged as Not Reviewed');
        Assert.IsTrue(UserSecurityStatus.Get(Debra), 'Debra doesn''t exist in table UserSecurityStatus');
        Assert.IsFalse(UserSecurityStatus.Reviewed, 'Debra should be tagged as Not Reviewed');
        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VisibilityOfControlsOnUserCardSaaS()
    var
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
        UserCard: TestPage "User Card";
    begin
        // [GIVEN] Running in SaaS
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);

        // [WHEN] Opening the user card page
        UserCard.OpenView();

        // [THEN] A series of PaaS/onPrem controls are not visible/editable
        Assert.IsFalse(UserCard."License Type".Visible(), 'License Type control on the User card should not be visible');
        Assert.IsFalse(UserCard."Expiry Date".Visible(), 'Expiry Date control on the User card should not be visible');
        Assert.IsFalse(UserCard.ACSStatus.Visible(), 'ACS Access Status control on the User card should not be visible');
        Assert.IsFalse(UserCard.Password.Visible(), 'Password control on the User card should not be visible');
        Assert.IsFalse(UserCard."Change Password".Visible(), 'Change Password control on the User card should not be visible');
        Assert.IsFalse(UserCard.AcsSetup.Visible(), 'ACS Setup action on the User card should not be visible');
        Assert.IsFalse(UserCard.ChangePassword.Visible(), 'Change Password action on the User card should not be visible');
        Assert.IsFalse(UserCard."Full Name".Editable(), 'Full name control on the User card should not be editable');
        Assert.IsFalse(UserCard."Authentication Email".Editable(), 'Authentication email on User Card should not be editable');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VisibilityOfControlsOnUsersListPaaSOnPrem()
    var
        User: Record User;
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
        UsersPage: TestPage Users;
    begin
        // [GIVEN] Running in PaaS or on-prem
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);

        // [WHEN] Opening the user list page
        UsersPage.OpenView();

        // [THEN] "Add myself as SUPER" is visible is there are no users already defined
        if User.Count = 0 then
            Assert.IsTrue(UsersPage.AddMeAsSuper.Visible(), 'AddMeAsSuper action on Users page should be visible');
        // [THEN] A series of PaaS/onPrem controls are visible/editable
        Assert.IsTrue(UsersPage."License Type".Visible(), 'License Type control on Users page should be visible');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VisibilityOfControlsOnUserSecurityActivitiesPage()
    var
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
        UserSecurityActivities: TestPage "User Security Activities";
    begin
        // [SCENARIO] Visibility of controls on the User Security Activities page when running PaaS or on-prem

        // [GIVEN] Running in PaaS or on-prem
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);

        // [WHEN] The Users security activities page is opened
        UserSecurityActivities.OpenView();

        // [THEN] SaaS-related cues are not visible
        Assert.IsFalse(UserSecurityActivities."Users - Without Subscriptions".Visible(),
          'Users without subscription plans on User Security Activities page should not be visible');
        Assert.IsFalse(UserSecurityActivities.NumberOfPlans.Visible(),
          'Users without group memberships on User Security Activities page should not be visible');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VisibilityOfNavigationToOfficePortalOnUserSecurityStatusPage()
    var
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
        UserSecurityStatusList: TestPage "User Security Status List";
    begin
        // [SCENARIO] Navigation to Azure AD plan assignment to users should only be visible in SaaS. Idem for plans.

        // [GIVEN] Running in PaaS or on-prem
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);

        // [WHEN] The Users security status list page is opened
        UserSecurityStatusList.OpenView();

        // [THEN] SaaS navigation controls are not visible
        Assert.IsFalse(UserSecurityStatusList."Manage plan assignments".Visible(),
          'Navigation to azure plan assignment should not be visible');
        Assert.IsFalse(UserSecurityStatusList."Belongs To Subscription Plan".Visible(), 'Plan related information should not be visible');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure D365BusFullAccessShouldHaveAdvancedPermissions()
    var
        HRConfidentialCommentLine: Record "HR Confidential Comment Line";
        PlanningErrorLog: Record "Planning Error Log";
        TimeSheetCommentLine: Record "Time Sheet Comment Line";
        ServiceCue: Record "Service Cue";
        ReturnsRelatedDocument: Record "Returns-Related Document";
        ServiceShipmentBuffer: Record "Service Shipment Buffer";
        CauseOfInactivity: Record "Cause of Inactivity";
        MiniformHeader: Record "Miniform Header";
        CurrentSalesperson: Record "Current Salesperson";
        WarehouseWorkerWMSCue: Record "Warehouse Worker WMS Cue";
        GroundsForTermination: Record "Grounds for Termination";
        InternalMovementHeader: Record "Internal Movement Header";
        UserDefaultStyleSheet: Record "User Default Style Sheet";
        MiscArticle: Record "Misc. Article";
        WarehouseWMSCue: Record "Warehouse WMS Cue";
        ATOSalesBuffer: Record "ATO Sales Buffer";
        JobWIPBuffer: Record "Job WIP Buffer";
        Relative: Record Relative;
        FaultAreaSymptomCode: Record "Fault Area/Symptom Code";
        StandardCostWorksheet: Record "Standard Cost Worksheet";
        CertificateOfSupply: Record "Certificate of Supply";
        ContactDuplDetailsBuffer: Record "Contact Dupl. Details Buffer";
        PlanningBuffer: Record "Planning Buffer";
        StandardCostWorksheetName: Record "Standard Cost Worksheet Name";
        StandardServiceCode: Record "Standard Service Code";
        MiniformFunction: Record "Miniform Function";
        OutstandingBankTransaction: Record "Outstanding Bank Transaction";
        WhseItemTrackingLine: Record "Whse. Item Tracking Line";
        WarehouseBasicCue: Record "Warehouse Basic Cue";
        ManufacturingCue: Record "Manufacturing Cue";
        LotBinBuffer: Record "Lot Bin Buffer";
        Confidential: Record Confidential;
        StandardServiceLine: Record "Standard Service Line";
        RegisteredInvtMovementLine: Record "Registered Invt. Movement Line";
        Union: Record Union;
        MiniformLine: Record "Miniform Line";
        StandardServiceItemGrCode: Record "Standard Service Item Gr. Code";
        RegisteredInvtMovementHdr: Record "Registered Invt. Movement Hdr.";
        TimeSheetCmtLineArchive: Record "Time Sheet Cmt. Line Archive";
        JobDifferenceBuffer: Record "Job Difference Buffer";
        JobBuffer: Record "Job Buffer";
        EmploymentContract: Record "Employment Contract";
        Qualification: Record Qualification;
        InternalMovementLine: Record "Internal Movement Line";
        EmployeeStatisticsGroup: Record "Employee Statistics Group";
        MiniformFunctionGroup: Record "Miniform Function Group";
        WhereUsedBaseCalendar: Record "Where Used Base Calendar";
        AssemblyCommentLine: Record "Assembly Comment Line";
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
        LibraryE2EPlanPermissions: Codeunit "Library - E2E Plan Permissions";
    begin
        // [SCENARIO] D365 Bus Full Access should have Advanced Permissions
        // [GIVEN] SaaS
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);
        LibraryE2EPlanPermissions.SetBusinessManagerPlan();

        // Verify
        Assert.IsTrue(HRConfidentialCommentLine.ReadPermission, 'HRConfidentialCommentLine does not have read permission');
        Assert.IsTrue(PlanningErrorLog.ReadPermission, 'PlanningErrorLog does not have read permission');
        Assert.IsTrue(TimeSheetCommentLine.ReadPermission, 'TimeSheetCommentLine does not have read permission');
        Assert.IsTrue(ServiceCue.ReadPermission, 'ServiceCue does not have read permission');
        Assert.IsTrue(ReturnsRelatedDocument.ReadPermission, 'ReturnsRelatedDocument does not have read permission');
        Assert.IsTrue(ServiceShipmentBuffer.ReadPermission, 'ServiceShipmentBuffer does not have read permission');
        Assert.IsTrue(CauseOfInactivity.ReadPermission, 'CauseofInactivity does not have read permission');
        Assert.IsTrue(MiniformHeader.ReadPermission, 'MiniformHeader does not have read permission');
        Assert.IsTrue(CurrentSalesperson.ReadPermission, 'CurrentSalesperson does not have read permission');
        Assert.IsTrue(WarehouseWorkerWMSCue.ReadPermission, 'WarehouseWorkerWMSCue does not have read permission');
        Assert.IsTrue(GroundsForTermination.ReadPermission, 'GroundsforTermination does not have read permission');
        Assert.IsTrue(InternalMovementHeader.ReadPermission, 'InternalMovementHeader does not have read permission');
        Assert.IsTrue(UserDefaultStyleSheet.ReadPermission, 'UserDefaultStyleSheet does not have read permission');
        Assert.IsTrue(MiscArticle.ReadPermission, 'MiscArticle does not have read permission');
        Assert.IsTrue(WarehouseWMSCue.ReadPermission, 'WarehouseWMSCue does not have read permission');
        Assert.IsTrue(ATOSalesBuffer.ReadPermission, 'ATOSalesBuffer does not have read permission');
        Assert.IsTrue(JobWIPBuffer.ReadPermission, 'JobWIPBuffer does not have read permission');
        Assert.IsTrue(Relative.ReadPermission, 'Relative does not have read permission');
        Assert.IsTrue(FaultAreaSymptomCode.ReadPermission, 'FaultAreaSymptomCode does not have read permission');
        Assert.IsTrue(StandardCostWorksheetName.ReadPermission, 'StandardCostWorksheetName does not have read permission');
        Assert.IsTrue(CertificateOfSupply.ReadPermission, 'CertificateofSupply does not have read permission');
        Assert.IsTrue(ContactDuplDetailsBuffer.ReadPermission, 'ContactDuplDetailsBuffer does not have read permission');
        Assert.IsTrue(PlanningBuffer.ReadPermission, 'PlanningBuffer does not have read permission');
        Assert.IsTrue(StandardCostWorksheet.ReadPermission, 'StandardCostWorksheet does not have read permission');
        Assert.IsTrue(StandardServiceCode.ReadPermission, 'StandardServiceCode does not have read permission');
        Assert.IsTrue(MiniformFunction.ReadPermission, 'MiniformFunction does not have read permission');
        Assert.IsTrue(OutstandingBankTransaction.ReadPermission, 'OutstandingBankTransaction does not have read permission');
        Assert.IsTrue(WhseItemTrackingLine.ReadPermission, 'WhseItemTrackingLine does not have read permission');
        Assert.IsTrue(WarehouseBasicCue.ReadPermission, 'WarehouseBasicCue does not have read permission');
        Assert.IsTrue(ManufacturingCue.ReadPermission, 'ManufacturingCue does not have read permission');
        Assert.IsTrue(LotBinBuffer.ReadPermission, 'LotBinBuffer does not have read permission');
        Assert.IsTrue(Confidential.ReadPermission, 'Confidential does not have read permission');
        Assert.IsTrue(StandardServiceLine.ReadPermission, 'StandardServiceLine does not have read permission');
        Assert.IsTrue(RegisteredInvtMovementLine.ReadPermission, 'RegisteredInvtMovementLine does not have read permission');
        Assert.IsTrue(Union.ReadPermission, 'Union does not have read permission');
        Assert.IsTrue(MiniformLine.ReadPermission, 'MiniformLine does not have read permission');
        Assert.IsTrue(StandardServiceItemGrCode.ReadPermission, 'StandardServiceItemGrCode does not have read permission');
        Assert.IsTrue(RegisteredInvtMovementHdr.ReadPermission, 'RegisteredInvtMovementHdr does not have read permission');
        Assert.IsTrue(TimeSheetCmtLineArchive.ReadPermission, 'TimeSheetCmtLineArchive does not have read permission');
        Assert.IsTrue(JobDifferenceBuffer.ReadPermission, 'JobDifferenceBuffer does not have read permission');
        Assert.IsTrue(JobBuffer.ReadPermission, 'JobBuffer does not have read permission');
        Assert.IsTrue(EmploymentContract.ReadPermission, 'EmploymentContract does not have read permission');
        Assert.IsTrue(Qualification.ReadPermission, 'Qualification does not have read permission');
        Assert.IsTrue(InternalMovementLine.ReadPermission, 'InternalMovementLine does not have read permission');
        Assert.IsTrue(EmployeeStatisticsGroup.ReadPermission, 'EmployeeStatisticsGroup does not have read permission');
        Assert.IsTrue(MiniformFunctionGroup.ReadPermission, 'MiniformFunctionGroup does not have read permission');
        Assert.IsTrue(WhereUsedBaseCalendar.ReadPermission, 'WhereUsedBaseCalendar does not have read permission');
        Assert.IsTrue(AssemblyCommentLine.ReadPermission, 'AssemblyCommentLine does not have read permission');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FillPermissionSetBufferWhenFiltered()
    var
        TenantPermissionSet: Record "Tenant Permission Set";
        TempPermissionSetBuffer: Record "Permission Set Buffer" temporary;
        RecordCountBeforeFiltered: Integer;
    begin
        // [SCENARIO 291532] Refilling Permission Set Buffer doesn't invoke an error when filtered

        // [GIVEN] Created Permission Set
        LibraryPermissions.CreateTenantPermissionSet(TenantPermissionSet, LibraryUtility.GenerateGUID(), NullGUID);

        // [GIVEN] Filled Permission Set Buffer
        TempPermissionSetBuffer.FillRecordBuffer();
        RecordCountBeforeFiltered := TempPermissionSetBuffer.Count();

        // [GIVEN] Filtered Permission Set Buffer by "Role ID"
        TempPermissionSetBuffer.SetFilter("Role ID", TenantPermissionSet."Role ID");

        // [WHEN] Refilled Permission Set Buffer with the the filter
        TempPermissionSetBuffer.FillRecordBuffer();
        TempPermissionSetBuffer.SetRange("Role ID");

        // [THEN] The number of entries in unfiltered Permission Set Buffer remains unchanged
        Assert.RecordCount(TempPermissionSetBuffer, RecordCountBeforeFiltered);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BasicPermissionSetHasReadOnlyPermissionForProfiles()
    var
        Permission: Record Permission;
    begin
        // [FEATURE] [UI]
        // [SCENARIO 305828] User with D365 BASIC permission set must have Read permissions to "Tenant Profile" and "All Profile"
        Assert.IsTrue(Permission.GET('D365 BASIC', Permission."Object Type"::"Table Data", DATABASE::"Tenant Profile"),
          'The D365 BASIC permission set has to have the read permissions for table Tenant Profile');
        Assert.IsTrue(Permission."Read Permission" = Permission."Read Permission"::Yes,
          'The D365 BASIC permission set has to have the read permissions for table Tenant Profile');
        Assert.IsFalse(Permission."Insert Permission" = Permission."Insert Permission"::Yes,
          'The D365 BASIC permission set should not have the insert permissions for table Tenant Profile');
        Assert.IsFalse(Permission."Delete Permission" = Permission."Delete Permission"::Yes,
          'The D365 BASIC permission set should not have the delete permissions for table Tenant Profile');
        Assert.IsFalse(Permission."Modify Permission" = Permission."Modify Permission"::Yes,
          'The D365 BASIC permission set should not have the modify permissions for table Tenant Profile');

        Assert.IsTrue(Permission.GET('D365 BASIC', Permission."Object Type"::"Table Data", DATABASE::"All Profile"),
          'The D365 BASIC permission set has to have the read permissions for table All Profile');
        Assert.IsTrue(Permission."Read Permission" = Permission."Read Permission"::Yes,
          'The D365 BASIC permission set has to have the read permissions for table All Profile');
        Assert.IsFalse(Permission."Insert Permission" = Permission."Insert Permission"::Yes,
          'The D365 BASIC permission set should not have the insert permissions for table All Profile');
        Assert.IsFalse(Permission."Modify Permission" = Permission."Modify Permission"::Yes,
          'The D365 BASIC permission set should not have the modify permissions for table All Profile');
        Assert.IsFalse(Permission."Delete Permission" = Permission."Delete Permission"::Yes,
          'The D365 BASIC permission set should not have the delete permissions for table All Profile');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportPermissionSets()
    var
        TenantPermissionSet: Record "Tenant Permission Set";
        FileManagement: Codeunit "File Management";
        FileContent: BigText;
        ExportFile: File;
        FileOutStream: OutStream;
        TextPosition: Integer;
        FileName: Text;
    begin
        // [FEATURE] [Export] [XMLPORT] [Permission Set] [Tenant Permission Set]
        // [SCENARIO 307489] Stan can export Tenant Permission Sets via XML PORT 9171 in a single run
        CreateTenantPermissionSet(TenantPermissionSet);
        FileName := FileManagement.ServerTempFileName('txt');

        ExportFile.Create(FileName);
        ExportFile.CreateOutStream(FileOutStream);

        XMLPORT.Export(XMLPORT::"Import/Export Permission Sets", FileOutStream);

        ExportFile.Close();

        LibraryTextFileValidation.ReadTextFile(FileName, FileContent);

        TextPosition := FileContent.TextPos(TenantPermissionSet."Role ID");
        Assert.IsTrue(TextPosition > 1, 'Tenant permission set is not found in exported file');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ImportPermissionSets_01()
    var
        ImportFile: File;
        FileInStream: InStream;
        FileFullPath: Text;
    begin
        // [FEATURE] [Import] [XMLPORT] [Permission Set] [Tenant Permission Set]
        // [SCENARIO 307489] Stan cannot import empty file as permission sets
        FileFullPath := LibraryPlainTextFile.Create('txt');
        LibraryPlainTextFile.Close();

        ImportFile.Open(FileFullPath);
        ImportFile.CreateInStream(FileInStream);
        asserterror XMLPORT.Import(XMLPORT::"Import/Export Permission Sets", FileInStream);
        Assert.ExpectedError(ImportEmptyFileErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ImportPermissionSets_03()
    var
        PermissionSet: Record "Permission Set";
        TenantPermissionSet: Record "Tenant Permission Set";
        ImportFile: File;
        FileInStream: InStream;
        FileFullPath: Text;
        Guids: array[2] of Text;
        RecordCount: array[2] of Integer;
    begin
        // [FEATURE] [Import] [XMLPORT] [Permission Set] [Tenant Permission Set]
        // [SCENARIO 307489] Stan can import tenant permission sets only via XMLPORT 9171
        FileFullPath := LibraryPlainTextFile.Create('txt');
        RecordCount[1] := PermissionSet.Count();
        RecordCount[2] := TenantPermissionSet.Count();
        Clear(NullGuid);

        Guids[1] := LibraryUtility.GenerateGUID();
        Guids[2] := LibraryUtility.GenerateGUID();

        LibraryPlainTextFile.AddLine('');
        LibraryPlainTextFile.AddLine('');
#pragma warning disable AA0217
        LibraryPlainTextFile.AddLine(StrSubstNo('"%1","%2"', Guids[1], Guids[2]));
#pragma warning restore
        LibraryPlainTextFile.Close();

        ImportFile.Open(FileFullPath);
        ImportFile.CreateInStream(FileInStream);
        XMLPORT.Import(XMLPORT::"Import/Export Permission Sets", FileInStream);

        TenantPermissionSet.Get(NullGuid, Guids[1]);
        TenantPermissionSet.TestField(Name, Guids[2]);

        Assert.RecordCount(PermissionSet, RecordCount[1]);
        Assert.RecordCount(TenantPermissionSet, RecordCount[2] + 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AggregatePermissionSetRoleIdSelectionFilterUT()
    var
        AggregatePermissionSet: Record "Aggregate Permission Set";
        PermissionSet: Record "Permission Set";
        SelectionFilterManagement: Codeunit SelectionFilterManagement;
        RoleIdFilter: Text;
        SelectedRoleIdFilter: Text;
    begin
        // [SCENARIO 292106] Return selection filter from the Aggregate Permission Set, used for multiple permission set filtering
        // [GIVEN] 5 "Permission Set"
        // [GIVEN] Filter for "Permisson Set"
        RoleIdFilter := '''D365 BASIC''|''D365 FULL ACCESS''';
        PermissionSet.SetFilter("Role ID", RoleIdFilter);
        // [GIVEN] "Aggregate Permission Set" marked according to "Permission Set"
        PermissionSet.FindSet();
        repeat
            if AggregatePermissionSet.Get(AggregatePermissionSet.Scope::System, BaseAppID.Get(), PermissionSet."Role ID") then
                AggregatePermissionSet.Mark(true);
        until PermissionSet.Next() = 0;
        AggregatePermissionSet.MarkedOnly(true);
        // [WHEN] Get "Role Id" selection filter for "Aggregate Permission Set"
        SelectedRoleIdFilter := SelectionFilterManagement.GetSelectionFilterForAggregatePermissionSetRoleId(AggregatePermissionSet);
        // [THEN] Function returns the same filter as was originally applied
        Assert.AreEqual(RoleIdFilter, SelectedRoleIdFilter, 'Role Id selection filter is wrong.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TestBasicHasDirectAccessToCueSetup()
    var
        LibraryLowerPermisisons: Codeunit "Library - Lower Permissions";
        RecRef: RecordRef;
    begin
        LibraryLowerPermisisons.PushPermissionSet('D365 BASIC');
        RecRef.Open(9701);

        RecRef.Insert();
        RecRef.FindFirst();
        RecRef.Modify();
        RecRef.Delete();
    end;

    //[Test] ignore 426467
    [HandlerFunctions('SendResolveNotificationHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TestResolvePermissionNotificationAction()
    var
        AccessControl: Record "Access Control";
        PermissionPagesMgt: Codeunit "Permission Pages Mgt.";
        AppID: Guid;
        Found: Boolean;
    begin
        // [SCENARIO] Test resolve permissions action for resolving permissions sets that no longer exist but still show in Access Control
        // [Given] Access control record which does not exist in Aggregated Permission Set
        AppID := CreateGuid();

        AccessControl.Init();
        AccessControl."App ID" := AppID;
        AccessControl."Role ID" := PermissionSetNonExistentTxt;
        AccessControl."User Security ID" := UserSecurityId();
        AccessControl."Company Name" := CompanyName();
        AccessControl.Scope := AccessControl.Scope::Tenant;
        AccessControl.Insert();

        // [When] Show resolve permission notification
        PermissionPagesMgt.CreateAndSendResolvePermissionNotification();

        // [Then] Validate that the record no longer exists
        Found := AccessControl.Get(UserSecurityId(), PermissionSetNonExistentTxt, CompanyName(), AccessControl.Scope::Tenant, AppID);
        Assert.IsFalse(Found, 'Access control still exists.');
    end;

    [SendNotificationHandler]
    procedure SendResolveNotificationHandler(var Notification: Notification): Boolean
    var
        PermissionPagesMgt: Codeunit "Permission Pages Mgt.";
        ResolvePermissionNotificationId: Guid;
    begin
        Evaluate(ResolvePermissionNotificationId, ResolvePermissionNotificationIdTxt);
        Assert.AreEqual(ResolvePermissionNotificationId, Notification.Id, 'The notification ids do not match.');

        PermissionPagesMgt.ResolvePermissionAction(Notification);
    end;

    local procedure CreateTenantPermissionSet(var TenantPermissionSet: Record "Tenant Permission Set")
    begin
        TenantPermissionSet.Init();
        TenantPermissionSet."Role ID" := LibraryUtility.GenerateGUID();
        TenantPermissionSet.Name := LibraryUtility.GenerateGUID();
        TenantPermissionSet.Insert();
    end;

    local procedure TearDown()
    var
        UserSecurityStatus: Record "User Security Status";
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
    begin
        AzureADPlanTestLibrary.DeletePlan(PlanSmallBusinessTxt);
        AzureADPlanTestLibrary.DeletePlan(PlanOffice365ExtraTxt);
        AzureADPlanTestLibrary.DeletePlan(PlanOffice365Txt);
        DeleteUser(UserCassieTxt);
        DeleteUser(UserDebraTxt);
        UserSecurityStatus.LoadUsers();
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);
    end;

    local procedure DeleteUser(UserName: Code[50])
    var
        User: Record User;
        UserPersonalization: Record "User Personalization";
    begin
        User.SetRange("User Name", UserName);
        if User.FindFirst() then begin
            if UserPersonalization.Get(User."User Security ID") then
                UserPersonalization.Delete();
            User.Delete();
        end;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandlerSimple(MessageText: Text[1024])
    begin
    end;
}
