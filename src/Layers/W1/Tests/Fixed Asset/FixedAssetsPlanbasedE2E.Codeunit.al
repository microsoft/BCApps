codeunit 135401 "Fixed Assets Plan-based E2E"
{
    Subtype = Test;

    trigger OnRun()
    begin
        // [FEATURE] [Fixed Asset] [UI] [User Group Plan]
    end;

    var
        Assert: Codeunit Assert;
        LibraryE2EPlanPermissions: Codeunit "Library - E2E Plan Permissions";
        LibraryERM: Codeunit "Library - ERM";
        LibraryFixedAsset: Codeunit "Library - Fixed Asset";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        LibraryNotificationMgt: Codeunit "Library - Notification Mgt.";
        IsInitialized: Boolean;
        FAJournalTemplateNameTok: Label 'ASSETS', Locked = true;
        FATypeOfAcquisitionTok: Label 'Bank Account', Locked = true;
        MissingPermissionsErr: Label 'Sorry, the current permissions prevented the action.';

    [Scope('OnPrem')]
    procedure Initialize()
    var
        ExperienceTierSetup: Record "Experience Tier Setup";
        FixedAsset: Record "Fixed Asset";
        ApplicationAreaMgmtFacade: Codeunit "Application Area Mgmt. Facade";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Fixed Assets Plan-based E2E");

        ApplicationAreaMgmtFacade.SaveExperienceTierCurrentCompany(ExperienceTierSetup.FieldCaption(Essential));

        DeleteAllAssetGeneralJournalLines();
        FixedAsset.DeleteAll();

        // Lazy Setup
        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Fixed Assets Plan-based E2E");

        CreateDefaultDepretiationBook();

        IsInitialized := true;
        Commit();

        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Fixed Assets Plan-based E2E");
    end;

    [Test]
    [HandlerFunctions('AcquireFANotificationHandler,FAAcquisitionWizardModalHandler,CalculateDepreciationModalHandler,CalculateDepreciationConfirmHandler,FixedAssetGLJournalHandler,PostMessageHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure FixedAssetJourneyAsBusinessManager()
    var
        FixedAsset: Record "Fixed Asset";
        FASubclass: Record "FA Subclass";
    begin
        // [E2E] Scenario going trough the entire life of a fixed asset (i.e. acquisition, depreciation, disposal)

        // [GIVEN] A default depreciation book, FA Posting Group, FA Class, and FA Subclass
        // [GIVEN] A user with a Business Manager Plan
        Initialize();
        CreateFAPostingGroupClassAndSubclass(FASubclass);

        LibraryE2EPlanPermissions.SetBusinessManagerPlan();

        // [WHEN] Create, Acquire, Depreciate, Dispose a Fixed Asset
        CreateFixedAsset(FixedAsset, FASubclass.Code);

        AcquireFixedAsset(FixedAsset);

        DepreciateFixedAsset(FixedAsset);

        DisposeFixedAsset(FixedAsset);

        // [THEN] Test suceeds, if no other errors are encountered and all verifications passed.
        VerifyFALedgerEntries(FixedAsset);

        LibraryNotificationMgt.RecallNotificationsForRecord(FixedAsset);
    end;

    [Test]
    [HandlerFunctions('AcquireFANotificationHandler,FAAcquisitionWizardModalHandler,CalculateDepreciationModalHandler,CalculateDepreciationConfirmHandler,FixedAssetGLJournalHandler,PostMessageHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure FixedAssetJourneyAsExternalAccountant()
    var
        FixedAsset: Record "Fixed Asset";
        FASubclass: Record "FA Subclass";
    begin
        // [E2E] Scenario going trough the entire life of a fixed asset (i.e. acquisition, depreciation, disposal)

        // [GIVEN] A default depreciation book, FA Posting Group, FA Class, and FA Subclass
        // [GIVEN] A user with a External Accountant Plan
        Initialize();
        CreateFAPostingGroupClassAndSubclass(FASubclass);

        LibraryE2EPlanPermissions.SetExternalAccountantPlan();

        // [WHEN] Create, Acquire, Depreciate, Dispose a Fixed Asset
        CreateFixedAsset(FixedAsset, FASubclass.Code);

        AcquireFixedAsset(FixedAsset);

        DepreciateFixedAsset(FixedAsset);

        DisposeFixedAsset(FixedAsset);

        // [THEN] Test suceeds, if no other errors are encountered and all verifications passed.
        VerifyFALedgerEntries(FixedAsset);

        LibraryNotificationMgt.RecallNotificationsForRecord(FixedAsset);
    end;

    [Test]
    [HandlerFunctions('AcquireFANotificationHandler,FAAcquisitionWizardModalHandler,CalculateDepreciationModalHandler,CalculateDepreciationConfirmHandler,FixedAssetGLJournalHandler,PostMessageHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure FixedAssetJourneyAsTeamMember()
    var
        FixedAsset: Record "Fixed Asset";
        FASubclass: Record "FA Subclass";
    begin
        // [E2E] Scenario going trough the entire life of a fixed asset (i.e. acquisition, depreciation, disposal)

        // [GIVEN] A default depreciation book, FA Posting Group, FA Class, and FA Subclass
        // [GIVEN] A user with a Team Member Plan
        Initialize();
        CreateFAPostingGroupClassAndSubclass(FASubclass);
        Commit();

        // [WHEN] Create a Fixed Asset
        LibraryE2EPlanPermissions.SetTeamMemberPlan();
        // [THEN] A permission error is thrown
        asserterror CreateFixedAsset(FixedAsset, FASubclass.Code);
        Assert.ExpectedError(MissingPermissionsErr);
        LibraryE2EPlanPermissions.SetBusinessManagerPlan();
        CreateFixedAsset(FixedAsset, FASubclass.Code);
        Commit();

        // [WHEN] Edit a Fixed Asset
        LibraryE2EPlanPermissions.SetTeamMemberPlan();
        // [THEN] No error is thrown
        ModifyFixedAsset(FixedAsset);
        Commit();

        // [WHEN] Acquire a Fixed Asset
        LibraryE2EPlanPermissions.SetTeamMemberPlan();
        // [THEN] A permission error is thrown
        asserterror AcquireFixedAsset(FixedAsset);
        Assert.ExpectedError(MissingPermissionsErr);
        LibraryE2EPlanPermissions.SetBusinessManagerPlan();
        AcquireFixedAsset(FixedAsset);
        Commit();

        // [WHEN] Depreciate a Fixed Asset
        LibraryE2EPlanPermissions.SetTeamMemberPlan();
        // [THEN] A permission error is thrown
        asserterror DepreciateFixedAsset(FixedAsset);
        Assert.ExpectedError(MissingPermissionsErr);
        LibraryE2EPlanPermissions.SetBusinessManagerPlan();
        Commit();
        DepreciateFixedAsset(FixedAsset);

        // [WHEN] Dispose a Fixed Asset
        LibraryE2EPlanPermissions.SetTeamMemberPlan();
        // [THEN] A permission error is thrown
        asserterror DisposeFixedAsset(FixedAsset);
        Assert.ExpectedError(MissingPermissionsErr);

        LibraryNotificationMgt.RecallNotificationsForRecord(FixedAsset);
        // [THEN] Test suceeds, if errors are encountered as expected from the selected Plan

        LibraryNotificationMgt.ClearTemporaryNotificationContext();
    end;

    [Test]
    [HandlerFunctions('AcquireFANotificationHandler,FAAcquisitionWizardModalHandler,CalculateDepreciationModalHandler,CalculateDepreciationConfirmHandler,FixedAssetGLJournalHandler,PostMessageHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure FixedAssetJourneyAsEssentialISVEmbUser()
    var
        FixedAsset: Record "Fixed Asset";
        FASubclass: Record "FA Subclass";
    begin
        // [E2E] Scenario going trough the entire life of a fixed asset (i.e. acquisition, depreciation, disposal)

        // [GIVEN] A default depreciation book, FA Posting Group, FA Class, and FA Subclass
        // [GIVEN] A user with a Essential ISV Emb Plan
        Initialize();
        CreateFAPostingGroupClassAndSubclass(FASubclass);

        LibraryE2EPlanPermissions.SetEssentialISVEmbUserPlan();

        // [WHEN] Create, Acquire, Depreciate, Dispose a Fixed Asset
        CreateFixedAsset(FixedAsset, FASubclass.Code);

        AcquireFixedAsset(FixedAsset);

        DepreciateFixedAsset(FixedAsset);

        DisposeFixedAsset(FixedAsset);

        // [THEN] Test suceeds, if no other errors are encountered and all verifications passed.
        VerifyFALedgerEntries(FixedAsset);

        LibraryNotificationMgt.RecallNotificationsForRecord(FixedAsset);
    end;

    [Test]
    [HandlerFunctions('AcquireFANotificationHandler,FAAcquisitionWizardModalHandler,CalculateDepreciationModalHandler,CalculateDepreciationConfirmHandler,FixedAssetGLJournalHandler,PostMessageHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure FixedAssetJourneyAsTeamMemberISVEmb()
    var
        FixedAsset: Record "Fixed Asset";
        FASubclass: Record "FA Subclass";
    begin
        // [E2E] Scenario going trough the entire life of a fixed asset (i.e. acquisition, depreciation, disposal)

        // [GIVEN] A default depreciation book, FA Posting Group, FA Class, and FA Subclass
        // [GIVEN] A user with a Team Member ISV Emb Plan
        Initialize();
        CreateFAPostingGroupClassAndSubclass(FASubclass);
        Commit();

        // [WHEN] Create a Fixed Asset
        LibraryE2EPlanPermissions.SetTeamMemberISVEmbPlan();

        // [THEN] A permission error is thrown
        asserterror CreateFixedAsset(FixedAsset, FASubclass.Code);
        Assert.ExpectedError(MissingPermissionsErr);

        LibraryE2EPlanPermissions.SetEssentialISVEmbUserPlan();
        CreateFixedAsset(FixedAsset, FASubclass.Code);
        Commit();

        // [WHEN] Edit a Fixed Asset
        LibraryE2EPlanPermissions.SetTeamMemberISVEmbPlan();
        // [THEN] No error is thrown
        ModifyFixedAsset(FixedAsset);
        Commit();

        // [WHEN] Acquire a Fixed Asset
        // [THEN] A permission error is thrown
        asserterror AcquireFixedAsset(FixedAsset);
        Assert.ExpectedError(MissingPermissionsErr);

        LibraryE2EPlanPermissions.SetEssentialISVEmbUserPlan();
        AcquireFixedAsset(FixedAsset);
        Commit();

        // [WHEN] Depreciate a Fixed Asset
        LibraryE2EPlanPermissions.SetTeamMemberISVEmbPlan();
        // [THEN] A permission error is thrown
        asserterror DepreciateFixedAsset(FixedAsset);
        Assert.ExpectedError(MissingPermissionsErr);

        LibraryE2EPlanPermissions.SetEssentialISVEmbUserPlan();
        Commit();
        DepreciateFixedAsset(FixedAsset);

        // [WHEN] Dispose a Fixed Asset
        LibraryE2EPlanPermissions.SetTeamMemberISVEmbPlan();
        // [THEN] A permission error is thrown
        asserterror DisposeFixedAsset(FixedAsset);
        Assert.ExpectedError(MissingPermissionsErr);

        LibraryNotificationMgt.RecallNotificationsForRecord(FixedAsset);
        // [THEN] Test suceeds, if errors are encountered as expected from the selected Plan

        LibraryNotificationMgt.ClearTemporaryNotificationContext();
    end;

    [Test]
    [HandlerFunctions('AcquireFANotificationHandler,FAAcquisitionWizardModalHandler,CalculateDepreciationModalHandler,CalculateDepreciationConfirmHandler,FixedAssetGLJournalHandler,PostMessageHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure FixedAssetJourneyAsDeviceISVEmbUser()
    var
        FixedAsset: Record "Fixed Asset";
        FASubclass: Record "FA Subclass";
    begin
        // [E2E] Scenario going trough the entire life of a fixed asset (i.e. acquisition, depreciation, disposal)

        // [GIVEN] A default depreciation book, FA Posting Group, FA Class, and FA Subclass
        // [GIVEN] A user with a Device ISV Emb Plan
        Initialize();
        CreateFAPostingGroupClassAndSubclass(FASubclass);

        LibraryE2EPlanPermissions.SetDeviceISVEmbUserPlan();

        // [WHEN] Create, Acquire, Depreciate, Dispose a Fixed Asset
        CreateFixedAsset(FixedAsset, FASubclass.Code);

        AcquireFixedAsset(FixedAsset);

        DepreciateFixedAsset(FixedAsset);

        DisposeFixedAsset(FixedAsset);

        // [THEN] Test suceeds, if no other errors are encountered and all verifications passed.
        VerifyFALedgerEntries(FixedAsset);

        LibraryNotificationMgt.RecallNotificationsForRecord(FixedAsset);
    end;

    local procedure CreateFixedAsset(var FixedAsset: Record "Fixed Asset"; FASubclassCode: Code[20])
    var
        FixedAssetCard: TestPage "Fixed Asset Card";
        Description: Text[100];
        FANo: Code[20];
    begin
        Description := CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(FixedAsset.Description)), 1, MaxStrLen(FixedAsset.Description));
        FixedAssetCard.OpenNew();
        FixedAssetCard.Description.SetValue(Description);
        FixedAssetCard."FA Subclass Code".SetValue(FASubclassCode);
        FixedAssetCard.DepreciationStartingDate.SetValue(WorkDate());
        FixedAssetCard.NumberOfDepreciationYears.SetValue(LibraryRandom.RandIntInRange(1, 10));
        FixedAssetCard.DepreciationEndingDate.Activate();
        FANo := FixedAssetCard."No.".Value();
        FixedAssetCard.Close();
        FixedAsset.Get(FANo);
    end;

    local procedure AcquireFixedAsset(FixedAsset: Record "Fixed Asset")
    var
        FixedAssetCard: TestPage "Fixed Asset Card";
    begin
        FixedAssetCard.OpenEdit();
        FixedAssetCard.GotoRecord(FixedAsset);
        FixedAssetCard.Acquire.Invoke();
        FixedAssetCard.Close();
    end;

    local procedure ModifyFixedAsset(FixedAsset: Record "Fixed Asset")
    var
        FixedAssetCard: TestPage "Fixed Asset Card";
        Description: Text[100];
    begin
        Description := CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(FixedAsset.Description)), 1, MaxStrLen(FixedAsset.Description));
        FixedAssetCard.OpenEdit();
        FixedAssetCard.GotoRecord(FixedAsset);
        FixedAssetCard.Description.SetValue(Description);
        FixedAssetCard.Close();
    end;

    local procedure DepreciateFixedAsset(FixedAsset: Record "Fixed Asset")
    var
        FixedAssetList: TestPage "Fixed Asset List";
    begin
        FixedAssetList.OpenView();
        FixedAssetList.GotoRecord(FixedAsset);
        FixedAssetList.CalculateDepreciation.Invoke();
    end;

    local procedure DisposeFixedAsset(FixedAsset: Record "Fixed Asset")
    var
        FADepreciationBook: Record "FA Depreciation Book";
        GLAccount: Record "G/L Account";
        GenJournalLine: Record "Gen. Journal Line";
        FixedAssetGLJournal: TestPage "Fixed Asset G/L Journal";
    begin
        FADepreciationBook.Get(FixedAsset."No.", LibraryFixedAsset.GetDefaultDeprBook());
        FixedAssetGLJournal.OpenEdit();
        FixedAssetGLJournal."Posting Date".SetValue(CalcDate('<1D>', FADepreciationBook."Depreciation Ending Date"));
        FixedAssetGLJournal."Document Type".SetValue(GenJournalLine."Document Type"::Invoice);
        FixedAssetGLJournal."Account Type".SetValue(GenJournalLine."Account Type"::"Fixed Asset");
        FixedAssetGLJournal."Account No.".SetValue(FixedAsset."No.");
        FixedAssetGLJournal."FA Posting Type".SetValue(GenJournalLine."FA Posting Type"::Disposal);
        FixedAssetGLJournal.Amount.SetValue(-LibraryRandom.RandInt(100));
        LibraryERM.CreateGLAccount(GLAccount);
        FixedAssetGLJournal."Bal. Account No.".SetValue(GLAccount."No.");
        FixedAssetGLJournal."P&ost".Invoke();// Post
    end;

    local procedure VerifyFALedgerEntries(FixedAsset: Record "Fixed Asset")
    var
        FALedgerEntry: Record "FA Ledger Entry";
        FixedAssetList: TestPage "Fixed Asset List";
        FALedgerEntries: TestPage "FA Ledger Entries";
    begin
        FixedAssetList.OpenView();
        FixedAssetList.GotoRecord(FixedAsset);
        FALedgerEntries.Trap();
        FixedAssetList."Ledger E&ntries".Invoke();
        FALedgerEntries.FILTER.SetFilter("FA Posting Type", Format(FALedgerEntry."FA Posting Type"::"Acquisition Cost"));
        Assert.IsTrue(FALedgerEntries.First(), 'FA Ledger Entries shoud contain at least one acquisition entry');
        FALedgerEntries.FILTER.SetFilter("FA Posting Type", Format(FALedgerEntry."FA Posting Type"::Depreciation));
        Assert.IsTrue(FALedgerEntries.First(), 'FA Ledger Entries shoud contain at least one depreciation entry');
        FALedgerEntries.FILTER.SetFilter("FA Posting Type", Format(FALedgerEntry."FA Posting Type"::"Proceeds on Disposal"));
        Assert.IsTrue(FALedgerEntries.First(), 'FA Ledger Entries shoud contain at least one disposal entry');
    end;

    local procedure CreateFAPostingGroupClassAndSubclass(var FASubclass: Record "FA Subclass")
    var
        FAPostingGroup: Record "FA Posting Group";
        FAClass: Record "FA Class";
    begin
        LibraryFixedAsset.CreateFAPostingGroup(FAPostingGroup);
        LibraryFixedAsset.CreateFAClass(FAClass);
        LibraryFixedAsset.CreateFASubclassDetailed(FASubclass, FAClass.Code, FAPostingGroup.Code);
    end;

    local procedure CreateDefaultDepretiationBook()
    var
        DepreciationBook: Record "Depreciation Book";
    begin
        CreateJournalSetupDepreciation(DepreciationBook);
        SetIndexationAndIntegrationInBook(DepreciationBook.Code);
        SetDefaultDepreciationBook(DepreciationBook.Code);
    end;

    local procedure CreateJournalSetupDepreciation(var DepreciationBook: Record "Depreciation Book")
    var
        FAJournalSetup: Record "FA Journal Setup";
    begin
        LibraryFixedAsset.CreateDepreciationBook(DepreciationBook);
        LibraryFixedAsset.CreateFAJournalSetup(FAJournalSetup, DepreciationBook.Code, '');
        UpdateMissingFieldsInFAJournalSetup(FAJournalSetup);
    end;

    local procedure SetDefaultDepreciationBook(DepreciationBookCode: Code[10])
    var
        FASetup: Record "FA Setup";
    begin
        FASetup.Get();
        FASetup.Validate("Default Depr. Book", DepreciationBookCode);
        FASetup.Modify(true);
    end;

    local procedure SetIndexationAndIntegrationInBook(DepreciationBookCode: Code[10])
    var
        DepreciationBook: Record "Depreciation Book";
    begin
        DepreciationBook.Get(DepreciationBookCode);
        DepreciationBook.Validate("G/L Integration - Acq. Cost", true);
        DepreciationBook.Validate("G/L Integration - Depreciation", true);
        DepreciationBook.Validate("G/L Integration - Write-Down", true);
        DepreciationBook.Validate("G/L Integration - Appreciation", true);
        DepreciationBook.Validate("G/L Integration - Disposal", true);
        DepreciationBook.Validate("Use Rounding in Periodic Depr.", true);
        DepreciationBook.Validate("Allow Indexation", true);
        DepreciationBook.Validate("G/L Integration - Custom 1", true);
        DepreciationBook.Validate("G/L Integration - Custom 2", true);
        DepreciationBook.Validate("G/L Integration - Maintenance", true);
        DepreciationBook.Validate("Use Same FA+G/L Posting Dates", true);
        DepreciationBook.Modify(true);
    end;

    local procedure UpdateMissingFieldsInFAJournalSetup(var FAJournalSetup: Record "FA Journal Setup")
    var
        FAJournalSetup2: Record "FA Journal Setup";
    begin
        FAJournalSetup2.SetRange("Depreciation Book Code", LibraryFixedAsset.GetDefaultDeprBook());
        FAJournalSetup2.FindFirst();
        FAJournalSetup.TransferFields(FAJournalSetup2, false);
        FAJournalSetup.Modify(true);
    end;

    [SendNotificationHandler]
    [Scope('OnPrem')]
    procedure AcquireFANotificationHandler(var AcquireFANotification: Notification): Boolean
    begin
        exit(true);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure FAAcquisitionWizardModalHandler(var FixedAssetAcquisitionWizard: TestPage "Fixed Asset Acquisition Wizard")
    begin
        FixedAssetAcquisitionWizard.NextPage.Invoke();
        FixedAssetAcquisitionWizard.TypeOfAcquisitions.SetValue(FATypeOfAcquisitionTok);
        FixedAssetAcquisitionWizard.BalancingAccountNo.SetValue(LibraryERM.CreateBankAccountNo());
        if FixedAssetAcquisitionWizard.ExternalDocNo.Visible() then
            FixedAssetAcquisitionWizard.ExternalDocNo.SetValue(LibraryUtility.GenerateGUID());
        FixedAssetAcquisitionWizard.NextPage.Invoke();
        FixedAssetAcquisitionWizard.AcquisitionCost.SetValue(LibraryRandom.RandInt(100));
        FixedAssetAcquisitionWizard.AcquisitionDate.SetValue(WorkDate());
        FixedAssetAcquisitionWizard.NextPage.Invoke();
        FixedAssetAcquisitionWizard.PreviousPage.Invoke();
        FixedAssetAcquisitionWizard.NextPage.Invoke();
        FixedAssetAcquisitionWizard.OpenFAGLJournal.SetValue(false);
        // COMMIT is enforced because the Finish action is invoking a codeunit and uses the return value.
        Commit();
        FixedAssetAcquisitionWizard.Finish.Invoke();
    end;

    [Scope('OnPrem')]
    procedure DeleteAllAssetGeneralJournalLines()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        GenJournalLine.SetRange("Journal Template Name", FAJournalTemplateNameTok);
        if not GenJournalLine.IsEmpty() then
            GenJournalLine.DeleteAll();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CalculateDepreciationModalHandler(var CalculateDepreciation: TestRequestPage "Calculate Depreciation")
    var
        FADepreciationBook: Record "FA Depreciation Book";
    begin
        FADepreciationBook.SetRange("Depreciation Book Code", LibraryFixedAsset.GetDefaultDeprBook());
        FADepreciationBook.FindFirst();
        CalculateDepreciation.DepreciationBook.SetValue(FADepreciationBook."Depreciation Book Code");
        CalculateDepreciation.PostingDate.SetValue(FADepreciationBook."Depreciation Ending Date");
        CalculateDepreciation.PostingDescription.SetValue(FAJournalTemplateNameTok);
        CalculateDepreciation.OK().Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure CalculateDepreciationConfirmHandler(Question: Text; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure FixedAssetGLJournalHandler(var FixedAssetGLJournal: TestPage "Fixed Asset G/L Journal")
    begin
        FixedAssetGLJournal."P&ost".Invoke();// Post
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure PostMessageHandler(Message: Text)
    begin
    end;

    [RecallNotificationHandler]
    [Scope('OnPrem')]
    procedure RecallNotificationHandler(var NotificationToRecall: Notification): Boolean
    begin
        exit(true);
    end;
}

