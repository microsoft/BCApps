codeunit 134612 "Test Editing Permissions"
{
    Permissions = TableData "Permission Set Link" = r;
    Subtype = Test;

    trigger OnRun()
    begin
        // [FEATURE] [Permissions]
    end;

    var
        Assert: Codeunit Assert;
        LibraryE2EPlanPermissions: Codeunit "Library - E2E Plan Permissions";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        LibraryPermissions: Codeunit "Library - Permissions";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        CopySuccessMsg: Label 'New permission set, %1, has been created.', Comment = 'New permission set, D365 Basic Set, has been created.';
        MissingSourceErr: Label 'There is no permission set to copy from.';
        MultipleSourcesErr: Label 'You can only copy one permission set at a time.';
        TargetExistsErr: Label 'The new permission set already exists.';
        TargetNameMissingErr: Label 'You must specify a name for the new permission set.';
        ZeroGuid: Guid;
        MSPermSetChangedMsg: Label 'One or more System permission sets that you have copied to create your own have changed. You may want to review the changed permission set in case the changes are relevant for your user-defined permission sets.';
        CannotEditPermissionSetMsg: Label 'Permission sets of type System and Extension cannot be changed. Only permission sets of type User-Defined can be changed.';
        CannotRenameTenantPermissionSetHavingUsageErr: Label 'You cannot rename a tenant permission set while it is used elsewhere, for example, in permission settings for a user or security group.';

    [Test]
    [Scope('OnPrem')]
    procedure StanCanCreateNewTenantPermissionSets()
    var
        NewPermissionSetName: Text[30];
        NewPermissionSetRoleID: Code[20];
    begin
        Initialize();

        // Setup
        NewPermissionSetRoleID := GenerateRandomTenantPermissionSetRoleID();
        NewPermissionSetName := GenerateRandomTenantPermissionSetName();

        // Exercise
        LibraryE2EPlanPermissions.SetBusinessManagerPlan();
        CreateNewTenantPermissionSetFromPermissionSetsPage(NewPermissionSetRoleID, NewPermissionSetName);

        // Verify
        AssertTenantPermissionSetExists(NewPermissionSetRoleID);
    end;

    [Test]
    [HandlerFunctions('CopyPermissionSetWithNewNameRequestPageHandler,CopyPermissionSetSuccessMessageHandler')]
    [Scope('OnPrem')]
    procedure StanCanCopyPermissionSetsToNewTenantPermissionSets()
    var
        PermissionSetRoleID: Code[20];
        NewPermissionSetRoleID: Code[20];
    begin
        Initialize();

        // Setup
        PermissionSetRoleID := GenerateRandomPermissionSetRoleID();
        NewPermissionSetRoleID := GenerateRandomTenantPermissionSetRoleID();

        LibraryLowerPermissions.SetOutsideO365Scope();
        CreateNewPermissionSet(PermissionSetRoleID);

        // Exercise
        LibraryVariableStorage.Enqueue(NewPermissionSetRoleID); // 1st time is for the request page handler
        // enabled criteria for the option to notify depends on the source being a System permission set
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(NewPermissionSetRoleID); // 2nd time is for the message handler
        LibraryE2EPlanPermissions.SetBusinessManagerPlan();
        CopyPermissionSetToNewTenantPermissionSet(PermissionSetRoleID, ZeroGuid);

        // Verify
        AssertTenantPermissionSetEqualsPermissionSet(NewPermissionSetRoleID, PermissionSetRoleID);
        AssertTenantPermissionsEqualPermissions(NewPermissionSetRoleID, PermissionSetRoleID);
        LibraryVariableStorage.AssertEmpty();
        AssertPermissionSetLinkExistsWithCorrectHash(PermissionSetRoleID, NewPermissionSetRoleID);
    end;

    [Test]
    [HandlerFunctions('CopyPermissionSetWithNewNameRequestPageHandlerWithoutLink,CopyPermissionSetSuccessMessageHandler')]
    [Scope('OnPrem')]
    procedure StanCanCopyPermissionSetsToNewTenantPermissionSetsWithoutCopyingLink()
    var
        PermissionSetRoleID: Code[20];
        NewPermissionSetRoleID: Code[20];
    begin
        Initialize();

        // Setup
        PermissionSetRoleID := GenerateRandomPermissionSetRoleID();
        NewPermissionSetRoleID := GenerateRandomTenantPermissionSetRoleID();

        LibraryLowerPermissions.SetOutsideO365Scope();
        CreateNewPermissionSet(PermissionSetRoleID);

        // Exercise
        LibraryVariableStorage.Enqueue(NewPermissionSetRoleID);
        LibraryE2EPlanPermissions.SetBusinessManagerPlan();
        // enabled criteria for the option to notify depends on the source being a System permission set
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(NewPermissionSetRoleID); // for the message handler
        CopyPermissionSetToNewTenantPermissionSet(PermissionSetRoleID, ZeroGuid);

        // Verify
        AssertTenantPermissionSetEqualsPermissionSet(NewPermissionSetRoleID, PermissionSetRoleID);
        AssertTenantPermissionsEqualPermissions(NewPermissionSetRoleID, PermissionSetRoleID);
        LibraryVariableStorage.AssertEmpty();
        AssertPermissionSetLinkDoesNotExist(PermissionSetRoleID, NewPermissionSetRoleID);
    end;

    [Test]
    [HandlerFunctions('CopyPermissionSetWithNewNameRequestPageHandler,CopyPermissionSetSuccessMessageHandler')]
    [Scope('OnPrem')]
    procedure StanCanCopyExtensionPermissionSetsToNewTenantPermissionSets()
    var
        ExtensionPermissionSetAppID: Guid;
        ExtensionPermissionSetRoleID: Code[20];
        NewPermissionSetRoleID: Code[20];
    begin
        Initialize();

        // Setup
        ExtensionPermissionSetRoleID := GenerateRandomTenantPermissionSetRoleID();
        NewPermissionSetRoleID := GenerateRandomTenantPermissionSetRoleID();

        ExtensionPermissionSetAppID := CreateNewExtensionPermissionSet(ExtensionPermissionSetRoleID);

        // Exercise
        LibraryVariableStorage.Enqueue(NewPermissionSetRoleID); // 1st time is for the request page handler
        // disabled criteria for the option to notify depends on the source being a System permission set
        LibraryVariableStorage.Enqueue(false);
        LibraryVariableStorage.Enqueue(NewPermissionSetRoleID); // 2nd time is for the message handler
        LibraryE2EPlanPermissions.SetBusinessManagerPlan();
        CopyPermissionSetToNewTenantPermissionSet(ExtensionPermissionSetRoleID, ExtensionPermissionSetAppID);

        // Verify
        AssertTenantPermissionSetEqualsTenantPermissionSet(
          NewPermissionSetRoleID, ExtensionPermissionSetRoleID, ExtensionPermissionSetAppID);
        AssertTenantPermissionsEqualTenantPermissions(
          NewPermissionSetRoleID, ExtensionPermissionSetRoleID, ExtensionPermissionSetAppID);
        LibraryVariableStorage.AssertEmpty();
        AssertPermissionSetLinkDoesNotExist(ExtensionPermissionSetRoleID, NewPermissionSetRoleID);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure StanCanDeleteNewlyCreatedTenantPermissionSets()
    var
        NewPermissionSetRoleID: Code[20];
    begin
        Initialize();

        // Setup
        NewPermissionSetRoleID := GenerateRandomTenantPermissionSetRoleID();
        CreateNewTenantPermissionSet(NewPermissionSetRoleID);

        // Exercise
        LibraryE2EPlanPermissions.SetBusinessManagerPlan();
        DeleteExistingTenantPermissionSet(NewPermissionSetRoleID);

        // Verify
        AssertTenantPermissionSetNotExisting(NewPermissionSetRoleID);
    end;

    [Test]
    [HandlerFunctions('CopyPermissionSetWithNewNameRequestPageHandler,CopyPermissionSetSuccessMessageHandler')]
    [Scope('OnPrem')]
    procedure StanCanDeleteCopiedApplicationPermissionSets()
    var
        PermissionSetRoleID: Code[20];
        NewPermissionSetRoleID: Code[20];
    begin
        Initialize();

        // Setup
        PermissionSetRoleID := GenerateRandomPermissionSetRoleID();
        NewPermissionSetRoleID := GenerateRandomTenantPermissionSetRoleID();

        LibraryLowerPermissions.SetOutsideO365Scope();
        CreateNewPermissionSet(PermissionSetRoleID);
        Commit();

        LibraryVariableStorage.Enqueue(NewPermissionSetRoleID); // 1st time is for the request page handler
        // enabled criteria for the option to notify depends on the source being a System permission set
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(NewPermissionSetRoleID); // 2nd time is for the message handler
        CopyPermissionSetToNewTenantPermissionSet(PermissionSetRoleID, ZeroGuid);

        // Exercise
        LibraryE2EPlanPermissions.SetBusinessManagerPlan();
        DeleteExistingTenantPermissionSet(NewPermissionSetRoleID);

        // Verify
        AssertTenantPermissionSetNotExisting(NewPermissionSetRoleID);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('CopyPermissionSetWithNewNameRequestPageHandler,CopyPermissionSetSuccessMessageHandler')]
    [Scope('OnPrem')]
    procedure StanCanDeleteCopiedExtensionPermissionSets()
    var
        ExtensionPermissionSetRoleID: Code[20];
        NewPermissionSetRoleID: Code[20];
        ExtensionPermissionSetAppID: Guid;
    begin
        Initialize();

        // Setup
        ExtensionPermissionSetRoleID := GenerateRandomTenantPermissionSetRoleID();
        NewPermissionSetRoleID := GenerateRandomTenantPermissionSetRoleID();

        ExtensionPermissionSetAppID := CreateNewExtensionPermissionSet(ExtensionPermissionSetRoleID);
        Commit();

        LibraryVariableStorage.Enqueue(NewPermissionSetRoleID); // 1st time is for the request page handler
        // enabled criteria for the option to notify depends on the source being a System permission set
        LibraryVariableStorage.Enqueue(false);
        LibraryVariableStorage.Enqueue(NewPermissionSetRoleID); // 2nd time is for the message handler
        CopyPermissionSetToNewTenantPermissionSet(ExtensionPermissionSetRoleID, ExtensionPermissionSetAppID);

        // Exercise
        LibraryE2EPlanPermissions.SetBusinessManagerPlan();
        DeleteExistingTenantPermissionSet(NewPermissionSetRoleID);

        // Verify
        AssertTenantPermissionSetNotExisting(NewPermissionSetRoleID);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('CopyPermissionSetMissingNewNameRequestPageHandler')]
    [Scope('OnPrem')]
    procedure StanHasToSpecifyNewNameForCopiedPermissionSet()
    var
        PermissionSetRoleID: Code[20];
        NewPermissionSetRoleID: Code[20];
    begin
        Initialize();

        // Setup
        PermissionSetRoleID := GenerateRandomPermissionSetRoleID();
        NewPermissionSetRoleID := GenerateRandomTenantPermissionSetRoleID();

        LibraryLowerPermissions.SetOutsideO365Scope();
        CreateNewPermissionSet(PermissionSetRoleID);

        // Exercise
        LibraryVariableStorage.Enqueue(NewPermissionSetRoleID);
        LibraryE2EPlanPermissions.SetBusinessManagerPlan();
        asserterror CopyPermissionSetToNewTenantPermissionSet(PermissionSetRoleID, ZeroGuid);

        // Verify
        Assert.ExpectedError(TargetNameMissingErr);
    end;

    [Test]
    [HandlerFunctions('CopyPermissionSetWithNewNameRequestPageHandler')]
    [Scope('OnPrem')]
    procedure StanHasToUseUniqueNameForCopiedPermissionSet()
    var
        PermissionSetRoleID: Code[20];
    begin
        Initialize();

        // Setup
        PermissionSetRoleID := GenerateRandomPermissionSetRoleID();

        LibraryLowerPermissions.SetOutsideO365Scope();
        CreateNewPermissionSet(PermissionSetRoleID);

        // Exercise
        LibraryVariableStorage.Enqueue(PermissionSetRoleID);
        LibraryVariableStorage.Enqueue(true); // as source is permission set
        LibraryE2EPlanPermissions.SetBusinessManagerPlan();
        asserterror CopyPermissionSetToNewTenantPermissionSet(PermissionSetRoleID, ZeroGuid);

        // Verify
        Assert.ExpectedError(TargetExistsErr);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('CopyPermissionSetWithNewNameRequestPageHandler')]
    [Scope('OnPrem')]
    procedure StanHasToSpecifyExistingPermissionSetToCopy()
    var
        PermissionSetRoleID: Code[20];
        NewPermissionSetRoleID: Code[20];
    begin
        Initialize();

        // Setup
        PermissionSetRoleID := GenerateRandomPermissionSetRoleID();
        NewPermissionSetRoleID := GenerateRandomTenantPermissionSetRoleID();

        // Exercise
        LibraryVariableStorage.Enqueue(NewPermissionSetRoleID);
        LibraryVariableStorage.Enqueue(false); // as source does not exist
        LibraryE2EPlanPermissions.SetBusinessManagerPlan();
        asserterror CopyPermissionSetToNewTenantPermissionSet(PermissionSetRoleID, ZeroGuid);

        // Verify
        Assert.ExpectedError(MissingSourceErr);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('CopyPermissionSetWithNewNameRequestPageHandler')]
    [Scope('OnPrem')]
    procedure StanCannotCopyMultiplePermissionSetsSimultaneously()
    var
        PermissionSetRoleIDOne: Code[20];
        PermissionSetRoleIDTwo: Code[20];
        NewPermissionSetRoleID: Code[20];
    begin
        Initialize();

        // Setup
        PermissionSetRoleIDOne := GenerateRandomPermissionSetRoleID();
        PermissionSetRoleIDTwo := GenerateRandomPermissionSetRoleID();
        NewPermissionSetRoleID := GenerateRandomTenantPermissionSetRoleID();

        LibraryLowerPermissions.SetOutsideO365Scope();
        CreateNewPermissionSet(PermissionSetRoleIDOne);
        CreateNewPermissionSet(PermissionSetRoleIDTwo);

        // Exercise
        LibraryVariableStorage.Enqueue(NewPermissionSetRoleID);
        LibraryVariableStorage.Enqueue(false);
        LibraryE2EPlanPermissions.SetBusinessManagerPlan();
        asserterror CopyTwoPermissionSetsToNewTenantPermissionSets(PermissionSetRoleIDOne, PermissionSetRoleIDTwo);

        // Verify
        Assert.ExpectedError(MultipleSourcesErr);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure IsaacIdentifiedPermissionSetsToBeNonEditable()
    var
        AggregatePermissionSet: Record "Aggregate Permission Set";
        PermissionPagesMgt: Codeunit "Permission Pages Mgt.";
        ZeroGUID: Guid;
        PermissionSetRoleID: Code[20];
        CanEditPermissionSet: Boolean;
    begin
        Initialize();

        // Setup
        PermissionSetRoleID := GenerateRandomPermissionSetRoleID();

        LibraryLowerPermissions.SetOutsideO365Scope();
        CreateNewPermissionSet(PermissionSetRoleID);

        AggregatePermissionSet.Get(AggregatePermissionSet.Scope::System, ZeroGUID, PermissionSetRoleID);

        // Exercise
        LibraryE2EPlanPermissions.SetBusinessManagerPlan();
        CanEditPermissionSet := PermissionPagesMgt.IsPermissionSetEditable(AggregatePermissionSet);

        // Verify
        Assert.IsFalse(CanEditPermissionSet, StrSubstNo('Permission set %1 is editable.', PermissionSetRoleID));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure IsaacIdentifiedExtensionPermissionSetsToBeNonEditable()
    var
        AggregatePermissionSet: Record "Aggregate Permission Set";
        PermissionPagesMgt: Codeunit "Permission Pages Mgt.";
        ExtensionPermissionSetAppID: Guid;
        ExtensionPermissionSetRoleID: Code[20];
        CanEditPermissionSet: Boolean;
    begin
        Initialize();

        // Setup
        ExtensionPermissionSetRoleID := GenerateRandomTenantPermissionSetRoleID();
        ExtensionPermissionSetAppID := CreateNewExtensionPermissionSet(ExtensionPermissionSetRoleID);
        AggregatePermissionSet.Get(AggregatePermissionSet.Scope::Tenant, ExtensionPermissionSetAppID, ExtensionPermissionSetRoleID);

        // Exercise
        LibraryE2EPlanPermissions.SetBusinessManagerPlan();
        CanEditPermissionSet := PermissionPagesMgt.IsPermissionSetEditable(AggregatePermissionSet);

        // Verify
        Assert.IsFalse(CanEditPermissionSet, StrSubstNo('Extension permission set %1 is editable.', ExtensionPermissionSetRoleID));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure IsaacIdentifiedUserCreatedTenantPermissionSetsToBeEditable()
    var
        AggregatePermissionSet: Record "Aggregate Permission Set";
        PermissionPagesMgt: Codeunit "Permission Pages Mgt.";
        ZeroGUID: Guid;
        NewPermissionSetRoleID: Code[20];
        CanEditPermissionSet: Boolean;
    begin
        Initialize();

        // Setup
        NewPermissionSetRoleID := GenerateRandomTenantPermissionSetRoleID();
        CreateNewTenantPermissionSet(NewPermissionSetRoleID);
        AggregatePermissionSet.Get(AggregatePermissionSet.Scope::Tenant, ZeroGUID, NewPermissionSetRoleID);

        // Exercise
        LibraryE2EPlanPermissions.SetBusinessManagerPlan();
        CanEditPermissionSet := PermissionPagesMgt.IsPermissionSetEditable(AggregatePermissionSet);

        // Verify
        Assert.IsTrue(CanEditPermissionSet, StrSubstNo('User-created permission set %1 is not editable.', NewPermissionSetRoleID));
    end;

    [Test]
    [HandlerFunctions('CopyPermissionSetWithNewNameRequestPageHandler,CopyPermissionSetSuccessMessageHandler,HandleNotificationAppDbPermissionSetChanged,CopiedPermissionSetPageHandler')]
    [Scope('OnPrem')]
    procedure StanGetsNotifiedWhenHashOfPermissionSetChanges()
    var
        PermissionSet: Record "Permission Set";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        PermissionSets: TestPage "Permission Sets";
        PermissionSetRoleIDThatIsLaterChanged: Code[20];
        PermissionSetRoleIDThatIsLaterDeleted: Code[20];
        PermissionSetRoleIDThatIsNotLaterChanged: Code[20];
        NewPermissionSet1: Code[20];
        NewPermissionSet2: Code[20];
        NewPermissionSet3: Code[20];
    begin
        Initialize();

        // Setup: Create new permission sets
        PermissionSetRoleIDThatIsLaterChanged := GenerateRandomPermissionSetRoleID();
        PermissionSetRoleIDThatIsLaterDeleted := GenerateRandomPermissionSetRoleID();
        PermissionSetRoleIDThatIsNotLaterChanged := GenerateRandomPermissionSetRoleID();

        LibraryLowerPermissions.SetOutsideO365Scope();
        CreateNewPermissionSet(PermissionSetRoleIDThatIsLaterChanged);
        CreateNewPermissionSet(PermissionSetRoleIDThatIsLaterDeleted);
        CreateNewPermissionSet(PermissionSetRoleIDThatIsNotLaterChanged);

        // Setup: Copy permission sets
        LibraryE2EPlanPermissions.SetBusinessManagerPlan();
        NewPermissionSet1 := GenerateRandomTenantPermissionSetRoleID();
        LibraryVariableStorage.Enqueue(NewPermissionSet1);
        Commit();
        // enabled criteria for the option to notify depends on the source being a System permission set
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(NewPermissionSet1); // for the message handler
        CopyPermissionSetToNewTenantPermissionSet(PermissionSetRoleIDThatIsLaterChanged, ZeroGuid);

        NewPermissionSet2 := GenerateRandomTenantPermissionSetRoleID();
        LibraryVariableStorage.Enqueue(NewPermissionSet2);
        Commit();
        // enabled criteria for the option to notify depends on the source being a System permission set
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(NewPermissionSet2); // for the message handler
        CopyPermissionSetToNewTenantPermissionSet(PermissionSetRoleIDThatIsLaterDeleted, ZeroGuid);

        NewPermissionSet3 := GenerateRandomTenantPermissionSetRoleID();
        LibraryVariableStorage.Enqueue(NewPermissionSet3);
        Commit();
        // enabled criteria for the option to notify depends on the source being a System permission set
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(NewPermissionSet3); // for the message handler
        CopyPermissionSetToNewTenantPermissionSet(PermissionSetRoleIDThatIsNotLaterChanged, ZeroGuid);

        // Setup: Source Permission sets have changed
        LibraryLowerPermissions.SetOutsideO365Scope();
        PermissionSet.Get(PermissionSetRoleIDThatIsLaterChanged);
        PermissionSet.Hash := 'Some new hash';
        PermissionSet.Modify();
        PermissionSet.Get(PermissionSetRoleIDThatIsLaterDeleted);
        PermissionSet.Delete();

        // Exercise: Stan opens the permission set page and ensures that the only 2 records show up
        PermissionSets.Trap();
        LibraryVariableStorage.Enqueue(PermissionSetRoleIDThatIsLaterChanged);
        LibraryVariableStorage.Enqueue(NewPermissionSet1);
        LibraryVariableStorage.Enqueue(PermissionSetRoleIDThatIsLaterDeleted);
        LibraryVariableStorage.Enqueue(NewPermissionSet2);
        LibraryVariableStorage.Enqueue(PermissionSetRoleIDThatIsNotLaterChanged);
        PermissionSets.OpenEdit();

        // Verify: Source Hash changes for the permission set that is later changed
        AssertPermissionSetLinkExistsWithCorrectHash(PermissionSetRoleIDThatIsLaterChanged, NewPermissionSet1);
        AssertPermissionSetLinkExistsWithCorrectHash(PermissionSetRoleIDThatIsNotLaterChanged, NewPermissionSet3);

        // Verify: Permission set link gets deleted for the second permission set
        AssertPermissionSetLinkDoesNotExist(PermissionSetRoleIDThatIsLaterDeleted, NewPermissionSet2);

        // Verify: All variables have been dequeued
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RenameUserDefinedPermissionSet()
    var
        TenantPermissionSet: Record "Tenant Permission Set";
        PermissionSetBuffer: Record "Permission Set Buffer";
        PermissionSets: TestPage "Permission Sets";
        OldRoleID: Code[20];
        NewRoleID: Code[20];
    begin
        // [FEATURE] [Tenant Perminsion Set]
        // [SCENARIO 298247] User can rename User defined permission sets on the page "Permission Sets"
        Initialize();

        // [GIVEN] User defined permission set with Role ID = 'PermSet1'
        OldRoleID := LibraryUtility.GenerateRandomCode20(TenantPermissionSet.FieldNo("Role ID"), DATABASE::"Tenant Permission Set");
        NewRoleID := LibraryUtility.GenerateRandomCode20(TenantPermissionSet.FieldNo("Role ID"), DATABASE::"Tenant Permission Set");
        CreateNewTenantPermissionSet(OldRoleID);
        LibraryE2EPlanPermissions.SetBusinessManagerPlan();

        // [GIVEN] Open page "Permission Sets"
        PermissionSets.OpenEdit();
        PermissionSets.FILTER.SetFilter("Role ID", OldRoleID);
        PermissionSets.FILTER.SetFilter(Type, Format(PermissionSetBuffer.Type::"User-Defined"));

        // [WHEN] Rename permission set 'PermSet1' to 'PermSet2' on the page "Permission Sets"
        PermissionSets.PermissionSet.SetValue(NewRoleID);

        // [THEN] Permission set has Role ID = 'PermSet2'
        TenantPermissionSet.SetRange("Role ID", OldRoleID);
        Assert.RecordIsEmpty(TenantPermissionSet);
        TenantPermissionSet.SetRange("Role ID", NewRoleID);
        Assert.RecordIsNotEmpty(TenantPermissionSet);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RenameUserDefinedPermissionSetUsedUsersSettings()
    var
        TenantPermissionSet: Record "Tenant Permission Set";
        PermissionSetBuffer: Record "Permission Set Buffer";
        AccessControl: Record "Access Control";
        PermissionSets: TestPage "Permission Sets";
        OldRoleID: Code[20];
        NewRoleID: Code[20];
    begin
        // [FEATURE] [Tenant Perminsion Set]
        // [SCENARIO 364626] User cannot rename User defined permission sets on the page "Permission Sets" if it is used elsewhere (users or groups permission settings)
        Initialize();

        // [GIVEN] User defined permission set with Role ID = "A"
        OldRoleID := LibraryUtility.GenerateRandomCode20(TenantPermissionSet.FieldNo("Role ID"), DATABASE::"Tenant Permission Set");
        NewRoleID := LibraryUtility.GenerateRandomCode20(TenantPermissionSet.FieldNo("Role ID"), DATABASE::"Tenant Permission Set");
        CreateNewTenantPermissionSet(OldRoleID);
        LibraryE2EPlanPermissions.SetBusinessManagerPlan();

        // [GIVEN] Permission set "A" is used by a user
        AccessControl."Role ID" := OldRoleID;
        AccessControl.Insert();

        // [GIVEN] Open page "Permission Sets"
        PermissionSets.OpenEdit();
        PermissionSets.FILTER.SetFilter("Role ID", OldRoleID);
        PermissionSets.FILTER.SetFilter(Type, Format(PermissionSetBuffer.Type::"User-Defined"));

        // [WHEN] Rename permission set "A" to "B" on the page "Permission Sets"
        asserterror PermissionSets.PermissionSet.SetValue(NewRoleID);

        // [THEN] Error has been thrown with message "You cannot rename a tenant permission set while it is used elsewhere, for example, in permission settings for a user or security group."
        Assert.ExpectedError(Format(CannotRenameTenantPermissionSetHavingUsageErr));
    end;

    local procedure Initialize()
    var
        ExperienceTierSetup: Record "Experience Tier Setup";
        PermissionSetLink: Record "Permission Set Link";
        ApplicationAreaMgmtFacade: Codeunit "Application Area Mgmt. Facade";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Test Editing Permissions");

        LibraryVariableStorage.Clear();
        ApplicationAreaMgmtFacade.SaveExperienceTierCurrentCompany(ExperienceTierSetup.FieldCaption(Essential));
        PermissionSetLink.DeleteAll();
    end;

    local procedure GenerateRandomPermissionSetRoleID(): Code[20]
    var
        PermissionSet: Record "Permission Set";
    begin
        exit(LibraryUtility.GenerateRandomCode20(PermissionSet.FieldNo("Role ID"), DATABASE::"Permission Set"));
    end;

    local procedure GenerateRandomTenantPermissionSetRoleID(): Code[20]
    var
        TenantPermissionSet: Record "Tenant Permission Set";
    begin
        exit(LibraryUtility.GenerateRandomCode20(TenantPermissionSet.FieldNo("Role ID"), DATABASE::"Tenant Permission Set"));
    end;

    local procedure GenerateRandomTenantPermissionSetName(): Text[30]
    var
        TenantPermissionSet: Record "Tenant Permission Set";
    begin
        exit(CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(TenantPermissionSet.Name)), 1, MaxStrLen(TenantPermissionSet.Name)));
    end;

    local procedure CreateNewPermissionSet(PermissionSetRoleID: Code[20])
    var
        Permission: Record Permission;
        TenantPermissionSet: Record "Tenant Permission Set";
    begin
        LibraryPermissions.CreatePermissionSet(TenantPermissionSet, PermissionSetRoleID);

        LibraryPermissions.AddPermission(PermissionSetRoleID, Permission."Object Type"::"Table Data", DATABASE::Customer);
        LibraryPermissions.AddPermission(PermissionSetRoleID, Permission."Object Type"::"Table Data", DATABASE::Vendor);
    end;

    local procedure CreateNewExtensionPermissionSet(TenantPermissionSetRoleID: Code[20]) TenantPermissionSetAppID: Guid
    begin
        TenantPermissionSetAppID := CreateGuid();
        CreateNewTenantPermissionSetWithSpecificGUID(TenantPermissionSetRoleID, TenantPermissionSetAppID);
    end;

    local procedure CreateNewTenantPermissionSet(TenantPermissionSetRoleID: Code[20])
    var
        ZeroGUID: Guid;
    begin
        CreateNewTenantPermissionSetWithSpecificGUID(TenantPermissionSetRoleID, ZeroGUID);
    end;

    local procedure CreateNewTenantPermissionSetWithSpecificGUID(TenantPermissionSetRoleID: Code[20]; TenantPermissionSetAppID: Guid)
    var
        TenantPermission: Record "Tenant Permission";
        TenantPermissionSet: Record "Tenant Permission Set";
    begin
        LibraryPermissions.CreateTenantPermissionSet(TenantPermissionSet, TenantPermissionSetRoleID, TenantPermissionSetAppID);

        LibraryPermissions.AddTenantPermission(
          TenantPermissionSetAppID, TenantPermissionSetRoleID, TenantPermission."Object Type"::"Table Data", DATABASE::Customer);
        LibraryPermissions.AddTenantPermission(
          TenantPermissionSetAppID, TenantPermissionSetRoleID, TenantPermission."Object Type"::"Table Data", DATABASE::Vendor);
    end;

    local procedure CreateNewTenantPermissionSetFromPermissionSetsPage(NewRoleID: Code[20]; NewName: Text[30])
    var
        PermissionSets: TestPage "Permission Sets";
    begin
        PermissionSets.OpenEdit();
        PermissionSets.New();
        PermissionSets.PermissionSet.SetValue(NewRoleID);
        PermissionSets.Name.SetValue(NewName);
        PermissionSets.Close();
    end;

    local procedure DeleteExistingTenantPermissionSet(ExistingRoleID: Code[20])
    var
        TenantPermissionSet: Record "Tenant Permission Set";
        ZeroGUID: Guid;
    begin
        TenantPermissionSet.Get(ZeroGUID, ExistingRoleID);
        TenantPermissionSet.Delete();
    end;

    local procedure CopyPermissionSetToNewTenantPermissionSet(SourcePermissionSetRoleID: Code[20]; AppId: Guid)
    var
        AggregatePermissionSet: Record "Aggregate Permission Set";
        PermissionSets: TestPage "Permission Sets";
    begin
        PermissionSets.OpenEdit();
        PermissionSets.FILTER.SetFilter("Role ID", SourcePermissionSetRoleID);
        PermissionSets.FILTER.SetFilter("App ID", AppId);
        AggregatePermissionSet.SetRange("Role ID", SourcePermissionSetRoleID);
        AggregatePermissionSet.SetRange("App ID", AppId);
        PermissionSets.CopyPermissionSet.Invoke();
        PermissionSets.Close();
    end;

    local procedure CopyTwoPermissionSetsToNewTenantPermissionSets(FirstSourcePermissionSetRoleID: Code[20]; SecondSourcePermissionSetRoleID: Code[20])
    var
        AggregatePermissionSet: Record "Aggregate Permission Set";
    begin
        AggregatePermissionSet.SetFilter("Role ID", '%1|%2', FirstSourcePermissionSetRoleID, SecondSourcePermissionSetRoleID);
        REPORT.Run(REPORT::"Copy Permission Set", true, true, AggregatePermissionSet);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CopyPermissionSetWithNewNameRequestPageHandler(var CopyPermissionSet: TestRequestPage "Copy Permission Set")
    var
        TenantPermissionSet: Record "Tenant Permission Set";
        TargetTenantPermissionSetRoleID: Code[20];
        NotifyFlagEnabled: Boolean;
    begin
        TargetTenantPermissionSetRoleID := CopyStr(LibraryVariableStorage.DequeueText(), 1, MaxStrLen(TenantPermissionSet."Role ID"));
        CopyPermissionSet.NewPermissionSet.SetValue(TargetTenantPermissionSetRoleID);
        CopyPermissionSet.CopyType.SetValue("Permission Set Copy Type"::Flat);
        NotifyFlagEnabled := LibraryVariableStorage.DequeueBoolean();
        Assert.AreEqual(NotifyFlagEnabled, CopyPermissionSet.CreateLink.Enabled(), 'Enabled criteria not fulfilled');
        if NotifyFlagEnabled then
            CopyPermissionSet.CreateLink.SetValue(true);
        CopyPermissionSet.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CopyPermissionSetWithNewNameRequestPageHandlerWithoutLink(var CopyPermissionSet: TestRequestPage "Copy Permission Set")
    var
        TenantPermissionSet: Record "Tenant Permission Set";
        TargetTenantPermissionSetRoleID: Code[20];
        NotifyFlagEnabled: Boolean;
    begin
        TargetTenantPermissionSetRoleID := CopyStr(LibraryVariableStorage.DequeueText(), 1, MaxStrLen(TenantPermissionSet."Role ID"));
        CopyPermissionSet.NewPermissionSet.SetValue(TargetTenantPermissionSetRoleID);
        CopyPermissionSet.CopyType.SetValue("Permission Set Copy Type"::Flat);
        NotifyFlagEnabled := LibraryVariableStorage.DequeueBoolean();
        Assert.AreEqual(NotifyFlagEnabled, CopyPermissionSet.CreateLink.Enabled(), 'Enabled criteria not fulfilled');
        if NotifyFlagEnabled then
            CopyPermissionSet.CreateLink.SetValue(false);
        CopyPermissionSet.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CopyPermissionSetMissingNewNameRequestPageHandler(var CopyPermissionSet: TestRequestPage "Copy Permission Set")
    begin
        CopyPermissionSet.OK().Invoke();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure CopyPermissionSetSuccessMessageHandler(Message: Text[1024])
    var
        TenantPermissionSet: Record "Tenant Permission Set";
        CopiedRoleID: Code[20];
    begin
        CopiedRoleID := CopyStr(LibraryVariableStorage.DequeueText(), 1, MaxStrLen(TenantPermissionSet."Role ID"));
        Assert.ExpectedMessage(StrSubstNo(CopySuccessMsg, CopiedRoleID), Message);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure AddNewSecurityFilterToTenantPermissionModalPageHandler(var TableFilterPage: TestPage "Table Filter")
    var
        TableFilter: Record "Table Filter";
        InputFieldFilter: Text[250];
        InputFieldNumber: Integer;
    begin
        InputFieldNumber := LibraryVariableStorage.DequeueInteger();
        InputFieldFilter := CopyStr(LibraryVariableStorage.DequeueText(), 1, MaxStrLen(TableFilter."Field Filter"));

        TableFilterPage.New();
        TableFilterPage."Field Number".SetValue(InputFieldNumber);
        TableFilterPage."Field Filter".SetValue(InputFieldFilter);
        TableFilterPage.OK().Invoke();
    end;

    local procedure AssertTenantPermissionSetExists(ExpectedRoleID: Code[20])
    var
        TenantPermissionSet: Record "Tenant Permission Set";
        ZeroGUID: Guid;
    begin
        TenantPermissionSet.SetRange("App ID", ZeroGUID);
        TenantPermissionSet.SetRange("Role ID", ExpectedRoleID);

        Assert.RecordIsNotEmpty(TenantPermissionSet);
    end;

    local procedure AssertTenantPermissionSetNotExisting(ExpectedRoleID: Code[20])
    var
        TenantPermissionSet: Record "Tenant Permission Set";
        ZeroGUID: Guid;
    begin
        TenantPermissionSet.SetRange("App ID", ZeroGUID);
        TenantPermissionSet.SetRange("Role ID", ExpectedRoleID);

        Assert.RecordIsEmpty(TenantPermissionSet);
    end;

    local procedure AssertTenantPermissionSetEqualsPermissionSet(TenantPermissionSetRoleID: Code[20]; PermissionSetRoleID: Code[20])
    var
        FromPermissionSet: Record "Permission Set";
        ToTenantPermissionSet: Record "Tenant Permission Set";
        ZeroGUID: Guid;
    begin
        FromPermissionSet.Get(PermissionSetRoleID);
        ToTenantPermissionSet.Get(ZeroGUID, TenantPermissionSetRoleID);
        ToTenantPermissionSet.TestField(Name, FromPermissionSet.Name);
    end;

    local procedure AssertTenantPermissionsEqualPermissions(TenantPermissionSetRoleID: Code[20]; PermissionSetRoleID: Code[20])
    begin
        AssertTenantPermissionCountEqualsPermissionCount(TenantPermissionSetRoleID, PermissionSetRoleID);
        AssertTenantPermissionValuesEqualPermissionValues(TenantPermissionSetRoleID, PermissionSetRoleID);
    end;

    local procedure AssertTenantPermissionCountEqualsPermissionCount(TenantPermissionSetRoleID: Code[20]; PermissionSetRoleID: Code[20])
    var
        FromPermission: Record Permission;
        ToTenantPermission: Record "Tenant Permission";
        ZeroGUID: Guid;
    begin
        FromPermission.SetRange("Role ID", PermissionSetRoleID);
        Assert.RecordIsNotEmpty(FromPermission);

        ToTenantPermission.SetRange("App ID", ZeroGUID);
        ToTenantPermission.SetRange("Role ID", TenantPermissionSetRoleID);
        Assert.RecordIsNotEmpty(ToTenantPermission);

        Assert.RecordCount(ToTenantPermission, FromPermission.Count);
    end;

    local procedure AssertTenantPermissionValuesEqualPermissionValues(TenantPermissionSetRoleID: Code[20]; PermissionSetRoleID: Code[20])
    var
        FromPermission: Record Permission;
        ToTenantPermission: Record "Tenant Permission";
        ZeroGUID: Guid;
    begin
        FromPermission.SetRange("Role ID", PermissionSetRoleID);
        FromPermission.FindSet();

        ToTenantPermission.SetRange("App ID", ZeroGUID);
        ToTenantPermission.SetRange("Role ID", TenantPermissionSetRoleID);
        ToTenantPermission.FindSet();

        repeat
            AssertTenantPermissionSetupEqualsPermissionSetup(ToTenantPermission, FromPermission);
        until (ToTenantPermission.Next() = 0) and (FromPermission.Next() = 0);
    end;

    local procedure AssertTenantPermissionSetupEqualsPermissionSetup(var ToTenantPermission: Record "Tenant Permission"; var FromPermission: Record Permission)
    begin
        ToTenantPermission.TestField("Object Type", FromPermission."Object Type");
        ToTenantPermission.TestField("Object ID", FromPermission."Object ID");
        ToTenantPermission.TestField("Read Permission", FromPermission."Read Permission");
        ToTenantPermission.TestField("Insert Permission", FromPermission."Insert Permission");
        ToTenantPermission.TestField("Modify Permission", FromPermission."Modify Permission");
        ToTenantPermission.TestField("Delete Permission", FromPermission."Delete Permission");
        ToTenantPermission.TestField("Execute Permission", FromPermission."Execute Permission");
        ToTenantPermission.TestField("Security Filter", FromPermission."Security Filter");
    end;

    local procedure AssertTenantPermissionSetEqualsTenantPermissionSet(ToTenantPermissionSetRoleID: Code[20]; FromTenantPermissionSetRoleID: Code[20]; FromTenantPermissionSetAppID: Guid)
    var
        FromTenantPermissionSet: Record "Tenant Permission Set";
        ToTenantPermissionSet: Record "Tenant Permission Set";
        ZeroGUID: Guid;
    begin
        FromTenantPermissionSet.Get(FromTenantPermissionSetAppID, FromTenantPermissionSetRoleID);
        ToTenantPermissionSet.Get(ZeroGUID, ToTenantPermissionSetRoleID);
        ToTenantPermissionSet.TestField(Name, FromTenantPermissionSet.Name);
    end;

    local procedure AssertTenantPermissionsEqualTenantPermissions(ToTenantPermissionSetRoleID: Code[20]; FromTenantPermissionSetRoleID: Code[20]; FromTenantPermissionSetAppID: Guid)
    begin
        AssertTenantPermissionCountEqualsTenantPermissionCount(
          ToTenantPermissionSetRoleID, FromTenantPermissionSetRoleID, FromTenantPermissionSetAppID);
        AssertTenantPermissionValuesEqualTenantPermissionValues(
          ToTenantPermissionSetRoleID, FromTenantPermissionSetRoleID, FromTenantPermissionSetAppID);
    end;

    local procedure AssertTenantPermissionCountEqualsTenantPermissionCount(ToTenantPermissionSetRoleID: Code[20]; FromTenantPermissionSetRoleID: Code[20]; FromTenantPermissionSetAppID: Guid)
    var
        FromTenantPermission: Record "Tenant Permission";
        ToTenantPermission: Record "Tenant Permission";
        ZeroGUID: Guid;
    begin
        FromTenantPermission.SetRange("App ID", FromTenantPermissionSetAppID);
        FromTenantPermission.SetRange("Role ID", FromTenantPermissionSetRoleID);
        Assert.RecordIsNotEmpty(FromTenantPermission);

        ToTenantPermission.SetRange("App ID", ZeroGUID);
        ToTenantPermission.SetRange("Role ID", ToTenantPermissionSetRoleID);
        Assert.RecordIsNotEmpty(ToTenantPermission);

        Assert.RecordCount(ToTenantPermission, FromTenantPermission.Count);
    end;

    local procedure AssertTenantPermissionValuesEqualTenantPermissionValues(ToTenantPermissionSetRoleID: Code[20]; FromTenantPermissionSetRoleID: Code[20]; FromTenantPermissionSetAppID: Guid)
    var
        FromTenantPermission: Record "Tenant Permission";
        ToTenantPermission: Record "Tenant Permission";
        ZeroGUID: Guid;
    begin
        FromTenantPermission.SetRange("App ID", FromTenantPermissionSetAppID);
        FromTenantPermission.SetRange("Role ID", FromTenantPermissionSetRoleID);
        FromTenantPermission.FindSet();

        ToTenantPermission.SetRange("App ID", ZeroGUID);
        ToTenantPermission.SetRange("Role ID", ToTenantPermissionSetRoleID);
        ToTenantPermission.FindSet();

        repeat
            AssertTenantPermissionSetupEqualsTenantPermissionSetup(ToTenantPermission, FromTenantPermission);
        until (ToTenantPermission.Next() = 0) and (FromTenantPermission.Next() = 0);
    end;

    local procedure AssertTenantPermissionSetupEqualsTenantPermissionSetup(var ToTenantPermission: Record "Tenant Permission"; var FromTenantPermission: Record "Tenant Permission")
    begin
        ToTenantPermission.TestField("Object Type", FromTenantPermission."Object Type");
        ToTenantPermission.TestField("Object ID", FromTenantPermission."Object ID");
        ToTenantPermission.TestField("Read Permission", FromTenantPermission."Read Permission");
        ToTenantPermission.TestField("Insert Permission", FromTenantPermission."Insert Permission");
        ToTenantPermission.TestField("Modify Permission", FromTenantPermission."Modify Permission");
        ToTenantPermission.TestField("Delete Permission", FromTenantPermission."Delete Permission");
        ToTenantPermission.TestField("Execute Permission", FromTenantPermission."Execute Permission");
        ToTenantPermission.TestField("Security Filter", FromTenantPermission."Security Filter");
    end;

    local procedure AssertPermissionSetLinkExistsWithCorrectHash(SourcePermissionSet: Code[20]; TargetpermissionSet: Code[20])
    var
        PermissionSetLink: Record "Permission Set Link";
        PermissionSet: Record "Permission Set";
        PermissionManager: Codeunit "Permission Manager";
    begin
        Assert.IsTrue(PermissionSetLink.Get(SourcePermissionSet, TargetpermissionSet), 'Record does not exist');
        PermissionSet.Get(SourcePermissionSet);
        Assert.AreEqual(PermissionManager.GenerateHashForPermissionSet(PermissionSet."Role ID"), PermissionSetLink."Source Hash", 'Hash mismatch');
    end;

    local procedure AssertPermissionSetLinkDoesNotExist(SourcePermissionSet: Code[20]; TargetpermissionSet: Code[20])
    var
        PermissionSetLink: Record "Permission Set Link";
    begin
        Assert.IsFalse(PermissionSetLink.Get(SourcePermissionSet, TargetpermissionSet), 'Record does not exist');
    end;

    [SendNotificationHandler]
    [Scope('OnPrem')]
    procedure HandleNotificationAppDbPermissionSetChanged(var Notification: Notification): Boolean
    var
        PermissionPagesMgt: Codeunit "Permission Pages Mgt.";
    begin
        Assert.AreEqual(MSPermSetChangedMsg, Notification.Message, 'Message mismatch');
        PermissionPagesMgt.AppDbPermissionSetChangedShowDetails(Notification);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CopiedPermissionSetPageHandler(var ChangedPermissionSetList: TestPage "Changed Permission Set List")
    begin
        ChangedPermissionSetList.First();
        ChangedPermissionSetList."Permission Set ID".AssertEquals(LibraryVariableStorage.DequeueText()); // the permission set that changed
        ChangedPermissionSetList."Linked Permission Set ID".AssertEquals(LibraryVariableStorage.DequeueText());

        ChangedPermissionSetList.Last();
        ChangedPermissionSetList."Permission Set ID".AssertEquals(LibraryVariableStorage.DequeueText()); // the permission set that was deleted
        ChangedPermissionSetList."Linked Permission Set ID".AssertEquals(LibraryVariableStorage.DequeueText());

        ChangedPermissionSetList.FILTER.SetFilter("Permission Set ID", LibraryVariableStorage.DequeueText()); // the permission set that did not change
        ChangedPermissionSetList.First();
        ChangedPermissionSetList."Permission Set ID".AssertEquals('');
    end;

    [SendNotificationHandler]
    [Scope('OnPrem')]
    procedure HandleNotificationCannotEditPermissionSets(var Notification: Notification): Boolean
    begin
        Assert.AreEqual(CannotEditPermissionSetMsg, Notification.Message, 'Message mismatch');
    end;
}
