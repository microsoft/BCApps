namespace Microsoft.FixedAssets.Depreciation;

using Microsoft.DemoData.Finance;
using Microsoft.DemoData.FixedAsset;
using Microsoft.DemoTool;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Journal;
#if not CLEAN30
using Microsoft.Finance.GeneralLedger.Ledger;
#endif
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.FixedAssets.Journal;
using Microsoft.FixedAssets.Ledger;
#if not CLEAN30
using Microsoft.FixedAssets.Reports;
#endif
using Microsoft.FixedAssets.Setup;
#if not CLEANSCHEMA33
using Microsoft.Foundation.AuditCodes;
#endif
using Microsoft.Foundation.NoSeries;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Setup;
#if not CLEAN30
using System.Environment.Configuration;
using System.TestLibraries.Upgrade;
#endif
using System.TestLibraries.Utilities;
#if not CLEANSCHEMA33
using System.Upgrade;
#endif

codeunit 148163 "Depr. Diff. Calculation FI"
{
    Subtype = Test;
    TestPermissions = Disabled;
    EventSubscriberInstance = Manual;

    trigger OnRun()
    begin
        // [FEATURE] [Fixed Asset] [Depreciation]
        isInitialized := false;
    end;

    var
        LibraryFixedAsset: Codeunit "Library - Fixed Asset";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryReportValidation: Codeunit "Library - Report Validation";
        LibraryRandom: Codeunit "Library - Random";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryERM: Codeunit "Library - ERM";
#if not CLEAN30
        TestCU: Codeunit "Depr. Diff. Calculation FI";
        FeatureEnabled: Boolean;
        FeatureCheckCount: Integer;
#endif
        isInitialized: Boolean;
        PleaseEnterPostingDateTxt: Label 'Please enter the Posting Date.';
        PleaseEnterDocumentNoTxt: Label 'Please enter the Document No.';
        PleaseEnterStartingDateTxt: Label 'Please enter the Starting Date for Depreciation Calculation.';
        PleaseEnterEndingDateTxt: Label 'Please enter the Ending Date for Depreciation Calculation.';
        EndingDateAfterStartingDateTxt: Label 'Ending Date must not be before Starting Date.';
        PleaseEnterBook1AndBook2Txt: Label 'Please specify Depreciation Book Code 1 and Depreciation Book Code 2.';
        SpecifyDeprDiffAccTxt: Label 'You must specify Depr. Difference Acc. in FA posting Group';
        SpecifyDeprDiffBalAccTxt: Label 'You must specify Depr. Difference Bal. Acc. in FA posting Group';
        DeprDiffPostedTxt: Label 'The Depreciation Difference was successfully posted.';
        PostingDeprDiffTxt: Label 'Do you want to post the Depreciation Difference ?';
        Book1InGLTxt: Label 'The Depreciation Book Code 1 must be integrated with G/L.';
        Book2NotInGLTxt: Label 'The Depreciation Book Code 2 must not be integrated with G/L.';
        NoDeprDiffPostedTxt: Label 'There is no Depreciation Difference posted for the specified period.';
        ZeroDifferenceLineErr: Label '''%1'' report contains lines with 0 in difference amount', Comment = '%1 is the report name.';
        ExpectedReportRowErr: Label 'The report did not produce the expected difference row.';
        HandledMessage: Text;
        DifferenceAmtErr: Label 'Current row does not have ''DifferenceAmt'' value greater than zero. Value  = <%1>.', Comment = '%1 is the DifferenceAmt value.';
        CompletionStatsTok: Label 'The depreciation has been calculated.';
#if not CLEAN30
        FeatureNotEnabledErr: Label 'The Depreciation Differences FI feature must be enabled before you can run this report.';
        LegacyReportFeatureEnabledErr: Label 'The Depreciation Differences FI feature is enabled. Run the Calculate and Post Depreciation Difference report from the Depreciation Differences FI app instead.';
#endif

#if not CLEAN30
    [Test]
    [HandlerFunctions('FixedAssetListRequestPageHandler')]
    procedure UnrelatedReportDoesNotInitializeFeatureStatus()
    var
        DepreciationDifferencesFIFeature: Codeunit "FI Depreciation Diff. Feature";
        RequestPageParameters: Text;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] A feature lookup is read-only and an unrelated report does not repeat it.
        Initialize();

        // [GIVEN] The company has no depreciation differences feature status.
        ClearFeatureDataUpdateStatus();
        SetFeatureEnabled(false);
        Commit();

        // [WHEN] The feature is queried and an unrelated report request page is opened.
        DepreciationDifferencesFIFeature.IsEnabled();
        RequestPageParameters := Report.RunRequestPage(Report::"Fixed Asset - List");

        // [THEN] Only the explicit lookup ran, no status was inserted, and the report was not substituted.
        VerifyUnrelatedReportFeatureCheck(RequestPageParameters);
        DisableFeature();
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('SubstitutedDeprDiffRequestPageHandler')]
    procedure LegacyReportIsSubstitutedWhenFeatureEnabled()
    var
        RequestPageParameters: Text;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] An enabled company feature substitutes the legacy depreciation differences report.
        Initialize();

        // [GIVEN] The depreciation differences feature is enabled for the company.
        PrepareReportFeatureStatus(Enum::"Feature Status"::Enabled);
        Commit();

        // [WHEN] The legacy report request page is opened.
        RequestPageParameters := Report.RunRequestPage(13402);

        // [THEN] The extension report opens and the feature status is unchanged.
        VerifyReportFeatureStatus(Report::"Calc. and Post Depr. Diff. FI", Enum::"Feature Status"::Enabled, RequestPageParameters);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('LegacyDeprDiffRequestPageHandler')]
    procedure LegacyReportIsNotSubstitutedWhenFeatureDisabled()
    var
        RequestPageParameters: Text;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] A disabled company feature preserves the legacy depreciation differences report.
        Initialize();

        // [GIVEN] The depreciation differences feature is disabled for the company.
        PrepareReportFeatureStatus(Enum::"Feature Status"::Disabled);
        Commit();

        // [WHEN] The legacy report request page is opened.
        RequestPageParameters := Report.RunRequestPage(13402);

        // [THEN] The legacy report opens and the feature status remains disabled.
        VerifyReportFeatureStatus(13402, Enum::"Feature Status"::Disabled, RequestPageParameters);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('LegacyDeprDiffRequestPageHandler')]
    procedure LegacyReportIsNotSubstitutedWhileMigrationPending()
    var
        RequestPageParameters: Text;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Pending feature migration preserves the legacy depreciation differences report.
        Initialize();

        // [GIVEN] The depreciation differences feature migration is pending for the company.
        PrepareReportFeatureStatus(Enum::"Feature Status"::Pending);
        Commit();

        // [WHEN] The legacy report request page is opened.
        RequestPageParameters := Report.RunRequestPage(13402);

        // [THEN] The legacy report opens and the pending status is preserved.
        VerifyReportFeatureStatus(13402, Enum::"Feature Status"::Pending, RequestPageParameters);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure LegacyReportInstancesCannotRunWhenFeatureEnabled()
    begin
        // [SCENARIO] Instance calls cannot bypass feature isolation when the replacement is enabled.
        VerifyLegacyReportInstanceFeatureStatus(Enum::"Feature Status"::Enabled, LegacyReportFeatureEnabledErr);
    end;

    [Test]
    procedure LegacyReportInstancesCannotRunWhenMigrationComplete()
    begin
        // [SCENARIO] Completed migration prevents legacy instance calls from posting the same entries again.
        VerifyLegacyReportInstanceFeatureStatus(Enum::"Feature Status"::Complete, LegacyReportFeatureEnabledErr);
    end;

    [Test]
    procedure LegacyReportInstancesRetainValidationWhenFeatureDisabled()
    begin
        // [SCENARIO] Disabled feature state preserves legacy report validation.
        VerifyLegacyReportInstanceFeatureStatus(Enum::"Feature Status"::Disabled, PleaseEnterBook1AndBook2Txt);
    end;

    [Test]
    procedure LegacyReportInstancesRetainValidationWhileMigrationPending()
    begin
        // [SCENARIO] Pending migration preserves legacy report validation.
        VerifyLegacyReportInstanceFeatureStatus(Enum::"Feature Status"::Pending, PleaseEnterBook1AndBook2Txt);
    end;
#endif

    local procedure Initialize()
    var
        FAClass: Record "FA Class";
        GeneralPostingSetup: Record "General Posting Setup";
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        InitializeTest();
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Depr. Diff. Calculation FI");

        LibraryERM.CreateGeneralPostingSetupInvt(GeneralPostingSetup);
        LibraryFixedAsset.CreateFAClass(FAClass);
        LibraryUtility.UpdateSetupNoSeriesCode(
            Database::"Purchases & Payables Setup", PurchasesPayablesSetup.FieldNo("Invoice Nos."));
        LibraryUtility.UpdateSetupNoSeriesCode(
            Database::"Purchases & Payables Setup", PurchasesPayablesSetup.FieldNo("Posted Invoice Nos."));
        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Depr. Diff. Calculation FI");
    end;

    local procedure InitializeTest()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Depr. Diff. Calculation FI");
        LibraryVariableStorage.Clear();
        Clear(LibraryReportValidation);
        Clear(HandledMessage);
    end;

    local procedure InitializeContosoDemoTest()
    var
        ContosoCoffeeDemoDataSetup: Record "Contoso Coffee Demo Data Setup";
        ContosoDemoDataModule: Record "Contoso Demo Data Module";
    begin
        InitializeTest();
        ContosoCoffeeDemoDataSetup.InitRecord();
        ContosoDemoDataModule.DeleteAll();
    end;

#if not CLEAN30
    [Test]
    procedure LegacyDataCreatedAfterEmptyReviewRemainsEligibleForMigration()
    var
        FAPostingGroup: Record "FA Posting Group";
        UpgradeTag: Codeunit "Upgrade Tag";
        DepDiffFIUpgradeTag: Codeunit "Dep Diff FI Upgrade Tag";
        DepDiffFIFeatureDataUpdate: Codeunit "Dep Diff FI Feature Data Upd.";
        UpgradeTagLibrary: Codeunit "Upgrade Tag Library";
        IsDataUpdateRequired: Boolean;
    begin
        Initialize();

        // [GIVEN] No legacy depreciation difference data and no migration upgrade tag exist.
        ClearLegacyDepreciationDifferenceData();
        if UpgradeTag.HasUpgradeTag(DepDiffFIUpgradeTag.GetUpgradeTag()) then
            UpgradeTagLibrary.DeleteUpgradeTag(
                DepDiffFIUpgradeTag.GetUpgradeTag(), CopyStr(CompanyName(), 1, 30));

        // [WHEN] The feature data update checks whether an update is required.
        IsDataUpdateRequired := DepDiffFIFeatureDataUpdate.IsDataUpdateRequired();

        // [THEN] No update is required and the check does not register the migration tag.
        Assert.IsFalse(
            IsDataUpdateRequired,
            'The feature data update must not be required when no legacy depreciation difference data exists.');
        Assert.IsFalse(
            UpgradeTag.HasUpgradeTag(DepDiffFIUpgradeTag.GetUpgradeTag()),
            'Reviewing an empty feature data update must not register the depreciation differences migration tag.');

        // [GIVEN] Legacy depreciation difference data is created after the empty check.
        LibraryFixedAsset.CreateFAPostingGroup(FAPostingGroup);
#pragma warning disable AL0432
        FAPostingGroup."Depr. Difference Acc." := LibraryERM.CreateGLAccountNo();
#pragma warning restore AL0432
        FAPostingGroup.Modify(false);

        // [WHEN] The feature data update checks again whether an update is required.
        IsDataUpdateRequired := DepDiffFIFeatureDataUpdate.IsDataUpdateRequired();

        // [THEN] The newly created legacy data remains eligible and checking it does not register the tag.
        Assert.IsTrue(
            IsDataUpdateRequired,
            'Legacy depreciation difference data created after an empty review must remain eligible for migration.');
        Assert.IsFalse(
            UpgradeTag.HasUpgradeTag(DepDiffFIUpgradeTag.GetUpgradeTag()),
            'Detecting legacy data must not register the depreciation differences migration tag.');
    end;

    [Test]
    procedure FeatureDataUpdateMigratesLegacyFields()
    var
        FAPostingGroup: Record "FA Posting Group";
        FALedgerEntry: Record "FA Ledger Entry";
        SourceCodeSetup: Record "Source Code Setup";
        FeatureDataUpdateStatus: Record "Feature Data Update Status";
        DepDiffFIFeatureDataUpdate: Codeunit "Dep Diff FI Feature Data Upd.";
        DeprDifferenceAccount: Code[20];
        DeprDifferenceBalAccount: Code[20];
        DeprDifferenceSourceCode: Code[10];
        FALedgerEntryNo: Integer;
    begin
        Initialize();

        DeprDifferenceAccount := LibraryERM.CreateGLAccountNo();
        DeprDifferenceBalAccount := LibraryERM.CreateGLAccountNo();
        DeprDifferenceSourceCode := CopyStr(LibraryUtility.GenerateRandomText(10), 1, MaxStrLen(DeprDifferenceSourceCode));

        LibraryFixedAsset.CreateFAPostingGroup(FAPostingGroup);
#pragma warning disable AL0432
        FAPostingGroup."Depr. Difference Acc." := DeprDifferenceAccount;
        FAPostingGroup."Depr. Difference Bal. Acc." := DeprDifferenceBalAccount;
#pragma warning restore AL0432
        FAPostingGroup."Deprec. Difference Account" := '';
        FAPostingGroup."Deprec. Difference Bal Acct" := '';
        FAPostingGroup.Modify(false);

        if FALedgerEntry.FindLast() then
            FALedgerEntryNo := FALedgerEntry."Entry No.";
        FALedgerEntry.Init();
        FALedgerEntry."Entry No." := FALedgerEntryNo + 1;
#pragma warning disable AL0432
        FALedgerEntry."Depr. Difference Posted" := true;
#pragma warning restore AL0432
        FALedgerEntry."Depreciation Difference Posted" := false;
        FALedgerEntry.Insert(false);

        if not SourceCodeSetup.Get() then begin
            SourceCodeSetup.Init();
            SourceCodeSetup.Insert(false);
        end;
#pragma warning disable AL0432
        SourceCodeSetup."Depr. Difference" := DeprDifferenceSourceCode;
#pragma warning restore AL0432
        SourceCodeSetup."Depreciation Difference Code" := '';
        SourceCodeSetup.Modify(false);

        Assert.IsTrue(
            DepDiffFIFeatureDataUpdate.IsDataUpdateRequired(),
            'The feature data update must be required when legacy depreciation difference data exists.');

        FeatureDataUpdateStatus."Feature Key" := 'DepreciationDifferencesFI';
        FeatureDataUpdateStatus."Company Name" := CopyStr(CompanyName(), 1, MaxStrLen(FeatureDataUpdateStatus."Company Name"));
        DepDiffFIFeatureDataUpdate.UpdateData(FeatureDataUpdateStatus);

        FAPostingGroup.Get(FAPostingGroup.Code);
        FAPostingGroup.TestField("Deprec. Difference Account", DeprDifferenceAccount);
        FAPostingGroup.TestField("Deprec. Difference Bal Acct", DeprDifferenceBalAccount);
        FALedgerEntry.Get(FALedgerEntry."Entry No.");
        FALedgerEntry.TestField("Depreciation Difference Posted", true);
        SourceCodeSetup.Get();
        SourceCodeSetup.TestField("Depreciation Difference Code", DeprDifferenceSourceCode);
    end;

    local procedure ClearLegacyDepreciationDifferenceData()
    var
        FAPostingGroup: Record "FA Posting Group";
        FALedgerEntry: Record "FA Ledger Entry";
        SourceCodeSetup: Record "Source Code Setup";
    begin
#pragma warning disable AL0432
        FAPostingGroup.ModifyAll("Depr. Difference Acc.", '', false);
        FAPostingGroup.ModifyAll("Depr. Difference Bal. Acc.", '', false);
        FALedgerEntry.ModifyAll("Depr. Difference Posted", false, false);
        if SourceCodeSetup.Get() then begin
            SourceCodeSetup."Depr. Difference" := '';
            SourceCodeSetup.Modify(false);
        end;
#pragma warning restore AL0432
    end;
#else
#if not CLEANSCHEMA33
    [Test]
    procedure ForcedUpgradePreservesMigratedFields()
    var
        FAPostingGroup: Record "FA Posting Group";
        FALedgerEntry: Record "FA Ledger Entry";
        SourceCodeSetup: Record "Source Code Setup";
        DepDiffFIUpgradeTag: Codeunit "Dep Diff FI Upgrade Tag";
        UpgradeDepreciationDiffFI: Codeunit "Upgrade Depreciation Diff. FI";
        UpgradeTag: Codeunit "Upgrade Tag";
        DeprDifferenceAccount: Code[20];
        DeprDifferenceBalAccount: Code[20];
        DeprDifferenceSourceCode: Code[10];
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] A completed forced upgrade preserves subsequent changes to all four migrated fields.
        Initialize();

        // [GIVEN] The per-company migration tag exists and migrated data has been edited.
        CreateForcedUpgradeData(FAPostingGroup, FALedgerEntry, SourceCodeSetup);
        SetForcedUpgradeTag();
        DeprDifferenceAccount := FAPostingGroup."Deprec. Difference Account";
        DeprDifferenceBalAccount := FAPostingGroup."Deprec. Difference Bal Acct";
        DeprDifferenceSourceCode := SourceCodeSetup."Depreciation Difference Code";

        // [WHEN] The forced upgrade runs again.
        UpgradeDepreciationDiffFI.UpgradeDepreciationDifferencesFI();

        // [THEN] All edited values and the per-company migration tag are preserved.
        VerifyForcedUpgradeData(
            FAPostingGroup.Code, FALedgerEntry."Entry No.", DeprDifferenceAccount,
            DeprDifferenceBalAccount, DeprDifferenceSourceCode, true);
        Assert.IsTrue(
            UpgradeTag.HasUpgradeTag(DepDiffFIUpgradeTag.GetUpgradeTag()),
            'The forced upgrade must preserve its per-company upgrade tag.');
    end;

    local procedure CreateForcedUpgradeData(
        var FAPostingGroup: Record "FA Posting Group"; var FALedgerEntry: Record "FA Ledger Entry";
        var SourceCodeSetup: Record "Source Code Setup")
    var
        FALedgerEntryNo: Integer;
    begin
        LibraryFixedAsset.CreateFAPostingGroup(FAPostingGroup);
        FAPostingGroup."Deprec. Difference Account" := LibraryERM.CreateGLAccountNo();
        FAPostingGroup."Deprec. Difference Bal Acct" := LibraryERM.CreateGLAccountNo();
        FAPostingGroup.Modify(false);

        if FALedgerEntry.FindLast() then
            FALedgerEntryNo := FALedgerEntry."Entry No.";
        FALedgerEntry.Init();
        FALedgerEntry."Entry No." := FALedgerEntryNo + 1;
        FALedgerEntry."Depreciation Difference Posted" := true;
        FALedgerEntry.Insert(false);

        if not SourceCodeSetup.Get() then begin
            SourceCodeSetup.Init();
            SourceCodeSetup.Insert(false);
        end;
        SourceCodeSetup."Depreciation Difference Code" :=
            CopyStr(LibraryUtility.GenerateRandomText(10), 1, MaxStrLen(SourceCodeSetup."Depreciation Difference Code"));
        SourceCodeSetup.Modify(false);
    end;

    local procedure SetForcedUpgradeTag()
    var
        DepDiffFIUpgradeTag: Codeunit "Dep Diff FI Upgrade Tag";
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if not UpgradeTag.HasUpgradeTag(DepDiffFIUpgradeTag.GetUpgradeTag()) then
            UpgradeTag.SetUpgradeTag(DepDiffFIUpgradeTag.GetUpgradeTag());
    end;

    local procedure VerifyForcedUpgradeData(
        FAPostingGroupCode: Code[20]; FALedgerEntryNo: Integer; DeprDifferenceAccount: Code[20];
        DeprDifferenceBalAccount: Code[20]; DeprDifferenceSourceCode: Code[10]; DepreciationDifferencePosted: Boolean)
    var
        FAPostingGroup: Record "FA Posting Group";
        FALedgerEntry: Record "FA Ledger Entry";
        SourceCodeSetup: Record "Source Code Setup";
    begin
        FAPostingGroup.Get(FAPostingGroupCode);
        Assert.AreEqual(DeprDifferenceAccount, FAPostingGroup."Deprec. Difference Account", 'The depreciation difference account must be preserved.');
        Assert.AreEqual(DeprDifferenceBalAccount, FAPostingGroup."Deprec. Difference Bal Acct", 'The depreciation difference balancing account must be preserved.');
        FALedgerEntry.Get(FALedgerEntryNo);
        Assert.AreEqual(DepreciationDifferencePosted, FALedgerEntry."Depreciation Difference Posted", 'The depreciation difference posting flag must be preserved.');
        SourceCodeSetup.Get();
        Assert.AreEqual(DeprDifferenceSourceCode, SourceCodeSetup."Depreciation Difference Code", 'The depreciation difference source code must be preserved.');
    end;
#endif
#endif

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ContosoDemoGeneratorInitializesExtensionAccounts()
    var
        ContosoDemoToolPage: TestPage "Contoso Demo Tool";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Contoso setup generation initializes the extension accounts for all five FI posting groups.
        InitializeContosoDemoTest();
        EnableFeature();

        // [GIVEN] Fixed asset setup and its dependencies have not been generated.
        PrepareContosoFixedAssetSetup(ContosoDemoToolPage);

        // [WHEN] Setup data is generated through the public Contoso Demo Tool page.
        ContosoDemoToolPage.GenerateSetup.Invoke();
        ContosoDemoToolPage.Close();
        DisableFeature();

        // [THEN] All five posting groups have extension accounts instead of legacy accounts.
        VerifyContosoPostingGroupAccounts(true);
    end;

#if not CLEAN30
    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ContosoDemoGeneratorInitializesLegacyAccountsWhenFeatureDisabled()
    var
        ContosoDemoToolPage: TestPage "Contoso Demo Tool";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Contoso setup generation retains legacy FI accounts when the feature is disabled.
        InitializeContosoDemoTest();
        SetFeatureEnabled(false);

        // [GIVEN] Fixed asset setup and its dependencies have not been generated.
        PrepareContosoFixedAssetSetup(ContosoDemoToolPage);

        // [WHEN] Setup data is generated through the public Contoso Demo Tool page.
        ContosoDemoToolPage.GenerateSetup.Invoke();
        ContosoDemoToolPage.Close();
        DisableFeature();

        // [THEN] All five posting groups have legacy accounts and empty extension accounts.
        VerifyContosoPostingGroupAccounts(false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CannotRunReportWhenFeatureIsDisabled()
    begin
        Initialize();
        SetFeatureEnabled(false);

        asserterror Report.Run(Report::"Calc. and Post Depr. Diff. FI", false, false);

        Assert.ExpectedError(FeatureNotEnabledErr);
        DisableFeature();
    end;
#endif

    [Test]
    [HandlerFunctions('CalcAndPostDeprDifferenceRPH,DepreciationCalcConfirmHandler')]
    [Scope('OnPrem')]
    procedure CalcAndPostDeprDifferenceReportWithZeroDifference()
    var
        FADepreciationBook: Record "FA Depreciation Book";
        DepreciationBookCodeSUMU: Code[10];
        DepreciationBookCodeTax: Code[10];
        StartingDate: Date;
        PostingDate: Date;
        FixedAssetNo1: Code[20];
        FixedAssetNo2: Code[20];
    begin
        EnableFeature();
        // Setup
        Initialize();
        StartingDate := CalcDate('<-' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate());
        PostingDate := CalcDate('<3M-1D>', StartingDate);
        DepreciationBookCodeSUMU := CreateDepreciationBook(10.0, true);
        DepreciationBookCodeTax := CreateDepreciationBook(0, false);
        // Excercise
        FixedAssetNo1 :=
          CreateFAAndPostDepreciation(
            4000, StartingDate, PostingDate, DepreciationBookCodeSUMU, DepreciationBookCodeTax,
            FADepreciationBook."Depreciation Method"::"Declining-Balance 1", '', 25, false, false);
        FixedAssetNo2 :=
          CreateFAAndPostDepreciation(
            6000, StartingDate, PostingDate, DepreciationBookCodeSUMU, DepreciationBookCodeTax,
            FADepreciationBook."Depreciation Method"::"Straight-Line", '<3Y-1D>', 0, false, false);

        RunCalcAndPostDeprDifferenceReportWithEnqueue(
          DepreciationBookCodeSUMU, DepreciationBookCodeTax, StartingDate, PostingDate, PostingDate,
          CopyStr(Format(CreateGuid()), 1, 20), false, false, StrSubstNo('%1..%2', FixedAssetNo1, FixedAssetNo2));

        // Verify
        VerifyCalcAndPostDeprDifferenceReportWithZeroDifference();
        DisableFeature();
    end;

    [Test]
    [HandlerFunctions('CalcAndPostDeprDifferenceRPH,DepreciationCalcConfirmHandler')]
    [Scope('OnPrem')]
    procedure CalcAndPostDeprDifferenceReportWithEmptyLines()
    var
        FADepreciationBook: Record "FA Depreciation Book";
        DepreciationBookCodeSUMU: Code[10];
        DepreciationBookCodeTax: Code[10];
        StartingDate: Date;
        PostingDate: Date;
        FixedAssetNo1: Code[20];
    begin
        EnableFeature();
        // Setup
        Initialize();
        StartingDate := CalcDate('<-' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate());
        PostingDate := CalcDate('<3M-1D>', StartingDate);
        DepreciationBookCodeSUMU := CreateDepreciationBook(10.0, true);
        DepreciationBookCodeTax := CreateDepreciationBook(0, false);

        // Excercise
        FixedAssetNo1 := CreateFAAndPostDepreciation(
            6000, StartingDate, PostingDate, DepreciationBookCodeSUMU, DepreciationBookCodeTax,
            FADepreciationBook."Depreciation Method"::"Straight-Line", '<3Y-1D>', 0, false, false);

        RunCalcAndPostDeprDifferenceReportWithEnqueue(
          DepreciationBookCodeSUMU, DepreciationBookCodeTax, StartingDate, PostingDate, PostingDate,
          CopyStr(Format(CreateGuid()), 1, 20), true, false, FixedAssetNo1);

        // Verify
        VerifyCalcAndPostDeprDifferenceReportWithEmptyLines();
        DisableFeature();
    end;

    [Test]
    [HandlerFunctions('CalcAndPostDeprDifferenceRPH,PostingDeprDiffCFH,MessageHandler')]
    [Scope('OnPrem')]
    procedure CalcAndPostDeprDifferenceReportWithDifference()
    var
        FADepreciationBook: Record "FA Depreciation Book";
        DepreciationBookCodeSUMU: Code[10];
        DepreciationBookCodeTax: Code[10];
        StartingDate: Date;
        PostingDate: Date;
        FixedAssetNo1: Code[20];
        FixedAssetNo2: Code[20];
        ExpectedMessage: Text;
    begin
        EnableFeature();
        // Setup
        Initialize();
        StartingDate := CalcDate('<-' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate());
        PostingDate := CalcDate('<3M-1D>', StartingDate);
        DepreciationBookCodeSUMU := CreateDepreciationBook(10.0, true);
        DepreciationBookCodeTax := CreateDepreciationBook(0, false);
        // Excercise
        FixedAssetNo1 :=
          CreateFAAndPostDepreciation(
            4000, StartingDate, PostingDate, DepreciationBookCodeSUMU, DepreciationBookCodeTax,
            FADepreciationBook."Depreciation Method"::"Declining-Balance 1", '', 25, false, false);
        FixedAssetNo2 :=
          CreateFAAndPostDepreciation(
            6000, StartingDate, PostingDate, DepreciationBookCodeSUMU, DepreciationBookCodeTax,
            FADepreciationBook."Depreciation Method"::"Straight-Line", '<3Y-1D>', 0, false, false);

        RunCalcAndPostDeprDifferenceReportWithEnqueue(
          DepreciationBookCodeSUMU, DepreciationBookCodeTax, StartingDate, PostingDate, PostingDate,
          CopyStr(Format(CreateGuid()), 1, 20), false, true, StrSubstNo('%1..%2', FixedAssetNo1, FixedAssetNo2));

        // Verify
        ExpectedMessage := DeprDiffPostedTxt;
        Assert.AreEqual(ExpectedMessage, HandledMessage, 'DeprDiffPostedTxt must be equal to Report13402.Text13408');
        VerifyCalcAndPostDeprDifferenceReportWithDifference();
        DisableFeature();
    end;

    [Test]
    [HandlerFunctions('CalcAndPostDeprDifferenceRPH,DepreciationCalcConfirmHandler')]
    [Scope('OnPrem')]
    procedure SpecifyDeprDiffAcc()
    var
        FADepreciationBook: Record "FA Depreciation Book";
        DepreciationBookCodeSUMU: Code[10];
        DepreciationBookCodeTax: Code[10];
        StartingDate: Date;
        PostingDate: Date;
        FixedAssetNo1: Code[20];
    begin
        EnableFeature();
        // Setup
        Initialize();
        StartingDate := CalcDate('<-' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate());
        PostingDate := CalcDate('<3M-1D>', StartingDate);
        DepreciationBookCodeSUMU := CreateDepreciationBook(10.0, true);
        DepreciationBookCodeTax := CreateDepreciationBook(0, false);

        // Excercise
        FixedAssetNo1 := CreateFAAndPostDepreciation(
            4000, StartingDate, PostingDate, DepreciationBookCodeSUMU, DepreciationBookCodeTax,
            FADepreciationBook."Depreciation Method"::"Declining-Balance 1", '', 25, true, false);

        asserterror RunCalcAndPostDeprDifferenceReportWithEnqueue(
            DepreciationBookCodeSUMU, DepreciationBookCodeTax, StartingDate, PostingDate, PostingDate, '', false, false, Format(FixedAssetNo1));

        // Verify
        Assert.ExpectedError(SpecifyDeprDiffAccTxt);
        DisableFeature();
    end;

    [Test]
    [HandlerFunctions('CalcAndPostDeprDifferenceRPH,DepreciationCalcConfirmHandler')]
    [Scope('OnPrem')]
    procedure SpecifyDeprDiffBalAcc()
    var
        FADepreciationBook: Record "FA Depreciation Book";
        DepreciationBookCodeSUMU: Code[10];
        DepreciationBookCodeTax: Code[10];
        StartingDate: Date;
        PostingDate: Date;
        FixedAssetNo1: Code[20];
    begin
        EnableFeature();
        // Setup
        Initialize();
        StartingDate := CalcDate('<-' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate());
        PostingDate := CalcDate('<3M-1D>', StartingDate);
        DepreciationBookCodeSUMU := CreateDepreciationBook(10.0, true);
        DepreciationBookCodeTax := CreateDepreciationBook(0, false);

        // Excercise
        FixedAssetNo1 := CreateFAAndPostDepreciation(
            4000, StartingDate, PostingDate, DepreciationBookCodeSUMU, DepreciationBookCodeTax,
            FADepreciationBook."Depreciation Method"::"Declining-Balance 1", '', 25, false, true);

        asserterror RunCalcAndPostDeprDifferenceReportWithEnqueue(
            DepreciationBookCodeSUMU, DepreciationBookCodeTax, StartingDate, PostingDate, PostingDate, '', false, false, Format(FixedAssetNo1));

        // Verify
        Assert.ExpectedError(SpecifyDeprDiffBalAccTxt);
        DisableFeature();
    end;

    [Test]
    [HandlerFunctions('CalcAndPostDeprDifferenceRPH')]
    [Scope('OnPrem')]
    procedure PleaseEnterPostingDate()
    var
        DepreciationBookCodeSUMU: Code[10];
        DepreciationBookCodeTax: Code[10];
        PostingDate: Date;
        PostDepreciationDifference: Boolean;
    begin
        EnableFeature();
        // Setup
        Initialize();
        PostingDate := 0D;
        PostDepreciationDifference := true;
        DepreciationBookCodeSUMU := CreateDepreciationBook(10.0, true);
        DepreciationBookCodeTax := CreateDepreciationBook(0, false);
        Commit();

        // Excercise
        asserterror RunCalcAndPostDeprDifferenceReportWithEnqueue(
            DepreciationBookCodeSUMU, DepreciationBookCodeTax, WorkDate(), WorkDate(), PostingDate, '', false, PostDepreciationDifference, '');

        // Verify
        Assert.ExpectedError(PleaseEnterPostingDateTxt);
        DisableFeature();
    end;

    [Test]
    [HandlerFunctions('CalcAndPostDeprDifferenceRPH')]
    [Scope('OnPrem')]
    procedure PleaseEnterDocumentNo()
    var
        DepreciationBookCodeSUMU: Code[10];
        DepreciationBookCodeTax: Code[10];
        DocumentNo: Code[20];
        PostDepreciationDifference: Boolean;
    begin
        EnableFeature();
        // Setup
        Initialize();
        DocumentNo := '';
        PostDepreciationDifference := true;
        DepreciationBookCodeSUMU := CreateDepreciationBook(10.0, true);
        DepreciationBookCodeTax := CreateDepreciationBook(0, false);
        Commit();

        // Excercise
        asserterror RunCalcAndPostDeprDifferenceReportWithEnqueue(
            DepreciationBookCodeSUMU, DepreciationBookCodeTax, WorkDate(), WorkDate(), WorkDate(), DocumentNo, false, PostDepreciationDifference, '');

        // Verify
        Assert.ExpectedError(PleaseEnterDocumentNoTxt);
        DisableFeature();
    end;

    [Test]
    [HandlerFunctions('CalcAndPostDeprDifferenceRPH')]
    [Scope('OnPrem')]
    procedure PleaseEnterStartingDate()
    var
        DepreciationBookCodeSUMU: Code[10];
        DepreciationBookCodeTax: Code[10];
        StartingDate: Date;
    begin
        EnableFeature();
        // Setup
        Initialize();
        StartingDate := 0D;
        DepreciationBookCodeSUMU := CreateDepreciationBook(10.0, true);
        DepreciationBookCodeTax := CreateDepreciationBook(0, false);
        Commit();

        // Excercise
        asserterror RunCalcAndPostDeprDifferenceReportWithEnqueue(
            DepreciationBookCodeSUMU, DepreciationBookCodeTax, StartingDate, WorkDate(), WorkDate(), '', false, false, '');

        // Verify
        Assert.ExpectedError(PleaseEnterStartingDateTxt);
        DisableFeature();
    end;

    [Test]
    [HandlerFunctions('CalcAndPostDeprDifferenceRPH')]
    [Scope('OnPrem')]
    procedure PleaseEnterEndingDate()
    var
        DepreciationBookCodeSUMU: Code[10];
        DepreciationBookCodeTax: Code[10];
        EndingDate: Date;
    begin
        EnableFeature();
        // Setup
        Initialize();
        EndingDate := 0D;
        DepreciationBookCodeSUMU := CreateDepreciationBook(10.0, true);
        DepreciationBookCodeTax := CreateDepreciationBook(0, false);
        Commit();

        // Excercise
        asserterror RunCalcAndPostDeprDifferenceReportWithEnqueue(
            DepreciationBookCodeSUMU, DepreciationBookCodeTax, WorkDate(), EndingDate, WorkDate(), '', false, false, '');

        // Verify
        Assert.ExpectedError(PleaseEnterEndingDateTxt);
        DisableFeature();
    end;

    [Test]
    [HandlerFunctions('CalcAndPostDeprDifferenceRPH')]
    [Scope('OnPrem')]
    procedure EndingDateAfterStartingDate()
    var
        DepreciationBookCodeSUMU: Code[10];
        DepreciationBookCodeTax: Code[10];
        EndingDate: Date;
        StartingDate: Date;
    begin
        EnableFeature();
        // Setup
        Initialize();
        StartingDate := CalcDate('<-' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate());
        EndingDate := CalcDate('<-1D>', StartingDate);
        DepreciationBookCodeSUMU := CreateDepreciationBook(10.0, true);
        DepreciationBookCodeTax := CreateDepreciationBook(0, false);
        Commit();

        // Excercise
        asserterror RunCalcAndPostDeprDifferenceReportWithEnqueue(
            DepreciationBookCodeSUMU, DepreciationBookCodeTax, WorkDate(), EndingDate, WorkDate(), '', false, false, '');

        // Verify
        Assert.ExpectedError(EndingDateAfterStartingDateTxt);
        DisableFeature();
    end;

    [Test]
    [HandlerFunctions('CalcAndPostDeprDifferenceRPH')]
    [Scope('OnPrem')]
    procedure PleaseEnterBook1AndBook2()
    var
        EmptyBookCode: Code[10];
    begin
        EnableFeature();
        // Setup
        Initialize();
        EmptyBookCode := '';

        // Excercise
        asserterror RunCalcAndPostDeprDifferenceReportWithEnqueue(
            EmptyBookCode, EmptyBookCode, WorkDate(), WorkDate(), WorkDate(), '', false, false, '');

        // Verify
        Assert.ExpectedError(PleaseEnterBook1AndBook2Txt);
        DisableFeature();
    end;

    [Test]
    [HandlerFunctions('CalcAndPostDeprDifferenceRPH')]
    [Scope('OnPrem')]
    procedure Book1InGL()
    var
        BookInGL: Code[10];
    begin
        EnableFeature();
        // Setup
        Initialize();
        BookInGL := CreateDepreciationBook(0, false);
        Commit();

        // Excercise
        asserterror RunCalcAndPostDeprDifferenceReportWithEnqueue(
            BookInGL, BookInGL, WorkDate(), WorkDate(), WorkDate(), '', false, false, '');

        // Verify
        Assert.ExpectedError(Book1InGLTxt);
        DisableFeature();
    end;

    [Test]
    [HandlerFunctions('CalcAndPostDeprDifferenceRPH')]
    [Scope('OnPrem')]
    procedure Book2NotInGL()
    var
        BookNotInGL: Code[10];
    begin
        EnableFeature();
        // Setup
        Initialize();
        BookNotInGL := CreateDepreciationBook(0, true);
        Commit();

        // Excercise
        asserterror RunCalcAndPostDeprDifferenceReportWithEnqueue(BookNotInGL, BookNotInGL, WorkDate(), WorkDate(), WorkDate(), '', false, false, '');

        // Verify
        Assert.ExpectedError(Book2NotInGLTxt);
        DisableFeature();
    end;

    [Test]
    [HandlerFunctions('CalcAndPostDeprDifferenceRPH,PostingDeprDiffCFH,MessageHandler')]
    [Scope('OnPrem')]
    procedure NoDeprDiffPosted()
    var
        DepreciationBookCodeSUMU: Code[10];
        DepreciationBookCodeTax: Code[10];
        PostingDate: Date;
        ExpectedMessage: Text;
    begin
        EnableFeature();
        // Setup
        Initialize();
        PostingDate := DMY2Date(1, 1, 1900);
        DepreciationBookCodeSUMU := CreateDepreciationBook(10.0, true);
        DepreciationBookCodeTax := CreateDepreciationBook(0, false);
        Commit();

        // Excercise
        RunCalcAndPostDeprDifferenceReportWithEnqueue(
          DepreciationBookCodeSUMU, DepreciationBookCodeTax, PostingDate, PostingDate, PostingDate,
          CopyStr(Format(CreateGuid()), 1, 20), false, true, '');

        // Verify
        ExpectedMessage := NoDeprDiffPostedTxt;
        Assert.AreEqual(ExpectedMessage, HandledMessage, 'NoDeprDiffPostedTxt must be equal to Report13402.Text13412');
        DisableFeature();
    end;

    [Test]
    [HandlerFunctions('CalcAndPostDeprDifferenceRPH,PostingDeprDiffCFH,MessageHandlerWithEnqueue')]
    [Scope('OnPrem')]
    procedure CalcAndPostDeprDiffWithOneBookZeroDepr()
    var
        FixedAsset: Record "Fixed Asset";
        FALedgerEntry: Record "FA Ledger Entry";
        FADepreciationBook: Record "FA Depreciation Book";
        DeprBookCode: array[2] of Code[10];
    begin
        EnableFeature();
        // [SCENARIO 311958] Calc And Post Deprectiation Difference repost posts difference when one of the values is zero, but the other is not
        Initialize();

        // [GIVEN] Depreciation book "B1" integrated to ledger
        DeprBookCode[1] := CreateDepreciationBook(0, true);

        // [GIVEN] Depreciation book "B2"
        DeprBookCode[2] := CreateDepreciationBook(0, false);

        // [GIVEN] A Fixed Asset
        LibraryFixedAsset.CreateFixedAssetWithSetup(FixedAsset);

        // [GIVEN] FA Depreciation Book "FAB1" with a posting group setup
        CreateFADeprBookWithPostingGroup(FADepreciationBook, FixedAsset."No.", DeprBookCode[1]);

        // [GIVEN ] FA Deprection Book "FAB2"
        LibraryFixedAsset.CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", DeprBookCode[2]);

        // [GIVEN] FA Ledger entry for book "FAB1" with non-zero amount
        MockFADepreciationLedgerEntry(FALedgerEntry, FixedAsset."No.", DeprBookCode[1]);

        // [WHEN] Run report 13402 for books "FAB1" and "FAB2"
        EnqueueParamsForCalcAndPostDeprDifferenceReport(
          DeprBookCode[1], DeprBookCode[2], WorkDate(), WorkDate(), WorkDate(), LibraryUtility.GenerateGUID(), false, true);

        Commit();

        RunCalcAndPostDeprDifferenceReport(FixedAsset."No.");
        // UI Handled by CalcAndPostDeprDifferenceRPH,PostingDeprDiffCFH,MessageHandlerWithEnqueue

        // [THEN] Depreciation Difference is posted
        Assert.AreEqual(DeprDiffPostedTxt, LibraryVariableStorage.DequeueText(), 'DeprDiffPostedTxt must be equal to Report13402.Text13408');
        LibraryVariableStorage.AssertEmpty();
        DisableFeature();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure PostingDeprDiffCFH(Question: Text; var Reply: Boolean)
    var
        Expected: Text;
    begin
        if 0 <> StrPos(Question, CompletionStatsTok) then
            Reply := false
        else begin
            Expected := PostingDeprDiffTxt;
            Assert.AreEqual(Expected, Question, 'PostingDeprDiffTxt must be equal to Report13402.Text13409');
            Reply := true;
        end;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text)
    begin
        HandledMessage := Message;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CalcAndPostDeprDifferenceRPH(var CalcAndPostDeprDifferenceRequestPage: TestRequestPage "Calc. and Post Depr. Diff. FI")
    var
        Value: Variant;
    begin
        LibraryVariableStorage.Dequeue(Value);
        CalcAndPostDeprDifferenceRequestPage."Depreciation Book Code 1".SetValue(Value);
        LibraryVariableStorage.Dequeue(Value);
        CalcAndPostDeprDifferenceRequestPage."Depreciation Book Code 2".SetValue(Value);
        LibraryVariableStorage.Dequeue(Value);
        CalcAndPostDeprDifferenceRequestPage."Starting Date".SetValue(Value);
        LibraryVariableStorage.Dequeue(Value);
        CalcAndPostDeprDifferenceRequestPage."Ending Date".SetValue(Value);
        LibraryVariableStorage.Dequeue(Value);
        CalcAndPostDeprDifferenceRequestPage."Posting Date".SetValue(Value);
        LibraryVariableStorage.Dequeue(Value);
        CalcAndPostDeprDifferenceRequestPage."Document No.".SetValue(Value);
        LibraryVariableStorage.Dequeue(Value);
        CalcAndPostDeprDifferenceRequestPage."Print Empty Lines".SetValue(Value);
        LibraryVariableStorage.Dequeue(Value);
        CalcAndPostDeprDifferenceRequestPage."Post Depreciation Difference".SetValue(Value);

        CalcAndPostDeprDifferenceRequestPage.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    local procedure PrepareContosoFixedAssetSetup(var ContosoDemoToolPage: TestPage "Contoso Demo Tool")
    var
        ContosoCoffeeDemoDataSetup: Record "Contoso Coffee Demo Data Setup";
        FAPostingGroup: Record "FA Posting Group";
        PostingGroupCode: Code[20];
    begin
        foreach PostingGroupCode in GetContosoPostingGroupCodes() do
            if FAPostingGroup.Get(PostingGroupCode) then
                FAPostingGroup.Delete(false);

        ContosoDemoToolPage.OpenView();
        ContosoDemoToolPage.Filter.SetFilter(Module, Format(Enum::"Contoso Demo Data Module"::"Fixed Asset Module"));
        ContosoCoffeeDemoDataSetup.Get();
        ContosoCoffeeDemoDataSetup.Validate("Language ID", 0);
        ContosoCoffeeDemoDataSetup.Modify(true);
    end;

    local procedure GetContosoPostingGroupCodes() PostingGroupCodes: List of [Code[20]]
    var
        CreateFAPostingGroup: Codeunit "Create FA Posting Group";
    begin
        PostingGroupCodes.Add(CreateFAPostingGroup.Equipment());
        PostingGroupCodes.Add(CreateFAPostingGroup.Goodwill());
        PostingGroupCodes.Add(CreateFAPostingGroup.Plant());
        PostingGroupCodes.Add(CreateFAPostingGroup.Property());
        PostingGroupCodes.Add(CreateFAPostingGroup.Vehicles());
    end;

    local procedure VerifyContosoPostingGroupAccounts(UseExtensionFields: Boolean)
    var
        FAPostingGroup: Record "FA Posting Group";
        GLAccount: Record "G/L Account";
        CreateGLAccountFI: Codeunit "Create FI GL Accounts";
        DeprDifferenceAccount: Code[20];
        DeprDifferenceBalAccount: Code[20];
        PostingGroupCode: Code[20];
    begin
        DeprDifferenceAccount := CreateGLAccountFI.Changeindepreciationreserve4();
        DeprDifferenceBalAccount := CreateGLAccountFI.Depreciationdifference3();
        Assert.AreNotEqual('', DeprDifferenceAccount, 'The depreciation difference account must be generated.');
        Assert.AreNotEqual('', DeprDifferenceBalAccount, 'The depreciation difference balancing account must be generated.');
        GLAccount.Get(DeprDifferenceAccount);
        GLAccount.Get(DeprDifferenceBalAccount);

        foreach PostingGroupCode in GetContosoPostingGroupCodes() do begin
            FAPostingGroup.Get(PostingGroupCode);
            if UseExtensionFields then begin
                Assert.AreEqual(DeprDifferenceAccount, FAPostingGroup."Deprec. Difference Account", 'The extension depreciation difference account must be initialized.');
                Assert.AreEqual(DeprDifferenceBalAccount, FAPostingGroup."Deprec. Difference Bal Acct", 'The extension depreciation difference balancing account must be initialized.');
            end else begin
                Assert.AreEqual('', FAPostingGroup."Deprec. Difference Account", 'The extension depreciation difference account must remain empty.');
                Assert.AreEqual('', FAPostingGroup."Deprec. Difference Bal Acct", 'The extension depreciation difference balancing account must remain empty.');
            end;
#if not CLEAN30
#pragma warning disable AL0432
            if UseExtensionFields then begin
                Assert.AreEqual('', FAPostingGroup."Depr. Difference Acc.", 'The legacy depreciation difference account must remain empty.');
                Assert.AreEqual('', FAPostingGroup."Depr. Difference Bal. Acc.", 'The legacy depreciation difference balancing account must remain empty.');
            end else begin
                Assert.AreEqual(DeprDifferenceAccount, FAPostingGroup."Depr. Difference Acc.", 'The legacy depreciation difference account must be initialized.');
                Assert.AreEqual(DeprDifferenceBalAccount, FAPostingGroup."Depr. Difference Bal. Acc.", 'The legacy depreciation difference balancing account must be initialized.');
            end;
#pragma warning restore AL0432
#endif
        end;
    end;

    local procedure CreateFixedAsset(var FixedAsset: Record "Fixed Asset"; FAPostingGroup: Code[20])
    begin
        LibraryFixedAsset.CreateFixedAsset(FixedAsset);
        FixedAsset.Validate("FA Posting Group", FAPostingGroup);
        FixedAsset.Modify(true);
    end;

    local procedure CreateFixedAssetPostingGroup(var FixedAsset: Record "Fixed Asset"; ClearDeprDifferenceAcc: Boolean; ClearDeprDifferenceBalAcc: Boolean)
    var
        FAPostingGroup: Record "FA Posting Group";
    begin
        LibraryFixedAsset.CreateFAPostingGroup(FAPostingGroup);
        UpdateFAPostingGroup(FAPostingGroup, ClearDeprDifferenceAcc, ClearDeprDifferenceBalAcc);
        CreateFixedAsset(FixedAsset, FAPostingGroup.Code);
    end;

    local procedure CreateAndSetupFixedAsset(var FixedAsset: Record "Fixed Asset"; StartingDate: Date; FAPostingGroupCode: Code[20]; DepreciationBookCodeSUMU: Code[10]; DepreciationMethodSUMU: Enum "FA Depreciation Method"; EndingDateFormulaSUMU: Text; DecliningBalancePercentSUMU: Decimal; DepreciationBookCodeTax: Code[10]; DepreciationMethodTax: Enum "FA Depreciation Method"; EndingDateFormulaTax: Text; DecliningBalancePercentTax: Decimal; ClearDeprDifferenceAcc: Boolean; ClearDeprDifferenceBalAcc: Boolean)
    var
        FAClass: Record "FA Class";
    begin
        CreateFixedAssetPostingGroup(FixedAsset, ClearDeprDifferenceAcc, ClearDeprDifferenceBalAcc);
        LibraryFixedAsset.FindFAClass(FAClass);
        FixedAsset."FA Class Code" := FAClass.Code;
        FixedAsset.Modify(true);

        FAPostingGroupCode := FixedAsset."FA Posting Group";

        CreateAndSetupFADepreciationBook(
          FixedAsset, FAPostingGroupCode, DepreciationBookCodeSUMU, DepreciationMethodSUMU,
          StartingDate, EndingDateFormulaSUMU, DecliningBalancePercentSUMU);
        CreateAndSetupFADepreciationBook(
          FixedAsset, FAPostingGroupCode, DepreciationBookCodeTax, DepreciationMethodTax,
          StartingDate, EndingDateFormulaTax, DecliningBalancePercentTax);
    end;

    local procedure CreateAndSetupFADepreciationBook(FixedAsset: Record "Fixed Asset"; FAPostingGroupCode: Code[20]; DepreciationBooKCode: Code[10]; DepreciationMethod: Enum "FA Depreciation Method"; StartDate: Date; EndingDateFormulaExpression: Text; DecliningBalancePercent: Decimal)
    var
        FADepreciationBook: Record "FA Depreciation Book";
        EndingDateFormula: DateFormula;
    begin
        LibraryFixedAsset.CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", DepreciationBooKCode);
        FADepreciationBook.Validate("FA Posting Group", FAPostingGroupCode);
        FADepreciationBook.Validate("Depreciation Method", DepreciationMethod);
        FADepreciationBook.Validate("Depreciation Starting Date", StartDate);
        if EndingDateFormulaExpression <> '' then begin
            Evaluate(EndingDateFormula, EndingDateFormulaExpression);
            FADepreciationBook.Validate("Depreciation Ending Date", CalcDate(EndingDateFormula, StartDate));
        end;
        FADepreciationBook.Validate("Declining-Balance %", DecliningBalancePercent);
        FADepreciationBook.Modify(true);
    end;

    local procedure CreateDepreciationBook(DefaultRounding: Decimal; Integration: Boolean): Code[10]
    var
        DepreciationBook: Record "Depreciation Book";
    begin
        CreateDepreciationJournalSetup(DepreciationBook);
        DepreciationBook."Default Final Rounding Amount" := DefaultRounding;
        DepreciationBook."Use FA Ledger Check" := true;
        DepreciationBook."Use Rounding in Periodic Depr." := true;
        DepreciationBook."Use Same FA+G/L Posting Dates" := true;
        DepreciationBook."G/L Integration - Acq. Cost" := Integration;
        DepreciationBook."G/L Integration - Depreciation" := Integration;
        DepreciationBook."G/L Integration - Write-Down" := Integration;
        DepreciationBook."G/L Integration - Appreciation" := Integration;
        DepreciationBook."G/L Integration - Custom 1" := Integration;
        DepreciationBook."G/L Integration - Custom 2" := Integration;
        DepreciationBook."G/L Integration - Disposal" := Integration;
        DepreciationBook."G/L Integration - Maintenance" := Integration;
        DepreciationBook."Allow more than 360/365 Days" := true;
        DepreciationBook.Modify();

        exit(DepreciationBook.Code);
    end;

    local procedure CreateDepreciationJournalSetup(var DepreciationBook: Record "Depreciation Book")
    var
        FAJournalSetup: Record "FA Journal Setup";
    begin
        LibraryFixedAsset.CreateDepreciationBook(DepreciationBook);
        if LibraryFixedAsset.GetDefaultDeprBook() = '' then
            LibraryFixedAsset.UpdateFASetupDefaultDeprBook(DepreciationBook.Code);
        LibraryFixedAsset.CreateFAJournalSetup(FAJournalSetup, DepreciationBook.Code, '');
        UpdateFAJournalSetup(FAJournalSetup);
    end;

    local procedure CreateFAJournalLineWithAmount(var FAJournalLine: Record "FA Journal Line"; FANo: Code[20]; DepreciationBookCode: Code[10]; FAPostingType: Enum "FA Journal Line Document Type"; PostingDate: Date; LineAmount: Decimal)
    var
        FAJournalBatch: Record "FA Journal Batch";
    begin
        CreateFAJournalBatch(FAJournalBatch);
        LibraryFixedAsset.CreateFAJournalLine(FAJournalLine, FAJournalBatch."Journal Template Name", FAJournalBatch.Name);
        FAJournalLine.Validate("Document No.", FAJournalBatch.Name);
        FAJournalLine.Validate("Posting Date", PostingDate);
        FAJournalLine.Validate("FA Posting Date", PostingDate);
        FAJournalLine.Validate("FA Posting Type", FAPostingType);
        FAJournalLine.Validate("FA No.", FANo);
        FAJournalLine.Validate(Amount, LineAmount);
        FAJournalLine.Validate("Depreciation Book Code", DepreciationBookCode);
        FAJournalLine.Modify(true);
    end;

    local procedure CreateFADeprBookWithPostingGroup(var FADepreciationBook: Record "FA Depreciation Book"; FixedAssetNo: Code[20]; DeprBookCode: Code[10])
    var
        FAPostingGroup: Record "FA Posting Group";
    begin
        LibraryFixedAsset.CreateFADepreciationBook(FADepreciationBook, FixedAssetNo, DeprBookCode);
        LibraryFixedAsset.CreateFAPostingGroup(FAPostingGroup);
        UpdateFAPostingGroup(FAPostingGroup, false, false);
        FADepreciationBook.Validate("FA Posting Group", FAPostingGroup.Code);
        FADepreciationBook.Modify(true);
    end;

    local procedure CreateAndPostPurchaseInvoice(PostingDate: Date; FixedAssetNo: Code[20]; DepreciationBookCode: Code[10]; Quantity: Decimal; Cost: Decimal): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, '');
        PurchaseHeader.Validate(
          "Vendor Invoice No.", LibraryUtility.GenerateRandomCode(PurchaseHeader.FieldNo("Vendor Invoice No."), DATABASE::"Purchase Header"));
        PurchaseHeader.Validate("Posting Date", PostingDate);
        PurchaseHeader.Validate("Message Type", PurchaseHeader."Message Type"::Message);
        PurchaseHeader.Validate("Invoice Message", FixedAssetNo);
        PurchaseHeader.Modify(true);

        CreatePurchaseLine(PurchaseHeader, FixedAssetNo, DepreciationBookCode, Quantity, Cost);

        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true));
    end;

    local procedure CreatePurchaseLine(var PurchaseHeader: Record "Purchase Header"; FixedAssetNo: Code[20]; DepreciationBookCode: Code[10]; FAQuantity: Decimal; FACost: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"Fixed Asset", FixedAssetNo, FAQuantity);
        PurchaseLine.Validate("Depreciation Book Code", DepreciationBookCode);
        PurchaseLine.Validate("Direct Unit Cost", FACost);
        PurchaseLine.Modify(true);
    end;

    local procedure CreateAndPostAcqusitionLine(FANo: Code[20]; FAPostingType: Enum "FA Journal Line FA Posting Type"; DepreciationBookCode: Code[10]; PostingDate: Date; LineAmount: Decimal)
    var
        FAJournalLine: Record "FA Journal Line";
    begin
        CreateFAJournalLineWithAmount(FAJournalLine, FANo, DepreciationBookCode, FAPostingType, PostingDate, LineAmount);
        LibraryFixedAsset.PostFAJournalLine(FAJournalLine);
    end;

    local procedure CreateFAAndPostDepreciation(Amount: Decimal; StartingDate: Date; PostingDate: Date; DepreciationBookCodeSUMU: Code[10]; DepreciationBookCodeTax: Code[10]; DepreciationMethodTax: Enum "FA Depreciation Method"; EndingDateFormulaTax: Text; DecliningBalancePercentTax: Decimal; ClearDeprDifferenceAcc: Boolean; ClearDeprDifferenceBalAcc: Boolean): Code[20]
    var
        FixedAsset: Record "Fixed Asset";
        FAJournalLine: Record "FA Journal Line";
        FADepreciationBook: Record "FA Depreciation Book";
    begin
        CreateAndSetupFixedAsset(
            FixedAsset, StartingDate, '',
            DepreciationBookCodeSUMU, FADepreciationBook."Depreciation Method"::"Straight-Line", '<3Y-1D>', 0,
            DepreciationBookCodeTax, DepreciationMethodTax, EndingDateFormulaTax, DecliningBalancePercentTax,
            ClearDeprDifferenceAcc, ClearDeprDifferenceBalAcc);

        CreateAndPostPurchaseInvoice(StartingDate, FixedAsset."No.", DepreciationBookCodeSUMU, 1, Amount);
        CreateAndPostAcqusitionLine(
          FixedAsset."No.", FAJournalLine."FA Posting Type"::"Acquisition Cost", DepreciationBookCodeTax, StartingDate, Amount);

        RunAndPostDepreciation(FixedAsset."No.", DepreciationBookCodeSUMU, CalcDate('<1M-1D>', StartingDate), true, false);
        RunAndPostDepreciation(FixedAsset."No.", DepreciationBookCodeSUMU, PostingDate, true, false);
        RunAndPostDepreciation(FixedAsset."No.", DepreciationBookCodeTax, PostingDate, false, true);

        exit(FixedAsset."No.");
    end;

    local procedure CreateFAJournalBatch(var FAJournalBatch: Record "FA Journal Batch")
    var
        FAJournalTemplate: Record "FA Journal Template";
    begin
        FAJournalTemplate.SetRange(Recurring, false);
        if not FAJournalTemplate.FindFirst() then
            LibraryFixedAsset.CreateJournalTemplate(FAJournalTemplate);
        LibraryFixedAsset.CreateFAJournalBatch(FAJournalBatch, FAJournalTemplate.Name);
        FAJournalBatch.Validate("No. Series", LibraryUtility.GetGlobalNoSeriesCode());
        FAJournalBatch.Modify(true);
    end;

    local procedure MockFADepreciationLedgerEntry(var FALedgerEntry: Record "FA Ledger Entry"; FANo: Code[20]; DeprBookCode: Code[10])
    begin
        FALedgerEntry.Init();
        FALedgerEntry."FA No." := FANo;
        FALedgerEntry."Depreciation Book Code" := DeprBookCode;
        FALedgerEntry."FA Posting Category" := FALedgerEntry."FA Posting Category"::"Bal. Disposal";
        FALedgerEntry."FA Posting Type" := FALedgerEntry."FA Posting Type"::Depreciation;
        FALedgerEntry."Posting Date" := WorkDate();
        FALedgerEntry."Depreciation Difference Posted" := false;
        FALedgerEntry.Amount := LibraryRandom.RandDec(100, 2);
        FALedgerEntry.Insert();
    end;

    local procedure RunAndPostDepreciation(FixedAssetNo: Code[20]; DepreciationBookCode: Code[10]; PostingDate: Date; InsertBalanceAccount: Boolean; Tax: Boolean)
    begin
        RunCalculateDepreciation(FixedAssetNo, DepreciationBookCode, PostingDate, InsertBalanceAccount);
        if Tax then
            PostTaxDepreciation(DepreciationBookCode, FixedAssetNo)
        else
            PostDepreciation(DepreciationBookCode);
    end;

    local procedure RunCalculateDepreciation(FixedAssetNo: Code[20]; DepreciationBookCode: Code[10]; PostingDate: Date; InsertBalanceAccount: Boolean)
    var
        FixedAsset: Record "Fixed Asset";
        CalculateDepreciation: Report "Calculate Depreciation";
    begin
        Clear(CalculateDepreciation);
        FixedAsset.SetRange("No.", FixedAssetNo);

        CalculateDepreciation.SetTableView(FixedAsset);
        CalculateDepreciation.InitializeRequest(
          DepreciationBookCode, PostingDate, false, 0, PostingDate, FixedAssetNo, FixedAsset.Description, InsertBalanceAccount);
        CalculateDepreciation.UseRequestPage(false);
        CalculateDepreciation.Run();
    end;

    local procedure PostDepreciation(DepreciationBookCode: Code[10])
    var
        GenJournalLine: Record "Gen. Journal Line";
        FAJournalSetup: Record "FA Journal Setup";
        GenJournalBatch: Record "Gen. Journal Batch";
        NoSeries: Codeunit "No. Series";
        DocumentNo: Code[20];
    begin
        FAJournalSetup.Get(DepreciationBookCode, '');
        GenJournalLine.SetRange("Journal Template Name", FAJournalSetup."Gen. Jnl. Template Name");
        GenJournalLine.SetRange("Journal Batch Name", FAJournalSetup."Gen. Jnl. Batch Name");
        GenJournalLine.FindSet();
        GenJournalBatch.Get(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name");

        DocumentNo := NoSeries.PeekNextNo(GenJournalBatch."No. Series");
        repeat
            GenJournalLine.Validate("Document No.", DocumentNo);
            GenJournalLine.Validate(Description, FAJournalSetup."Gen. Jnl. Batch Name");
            GenJournalLine.Modify(true);
        until GenJournalLine.Next() = 0;
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure PostTaxDepreciation(DepreciationBookCode: Code[10]; FixedAssetNo: Code[20])
    var
        FAJournalLine: Record "FA Journal Line";
        FAJournalSetup: Record "FA Journal Setup";
        FAJournalBatch: Record "FA Journal Batch";
        NoSeries: Codeunit "No. Series";
        DocumentNo: Code[20];
    begin
        FAJournalSetup.Get(DepreciationBookCode, '');
        FAJournalLine.SetRange("Journal Template Name", FAJournalSetup."FA Jnl. Template Name");
        FAJournalLine.SetRange("Journal Batch Name", FAJournalSetup."FA Jnl. Batch Name");
#pragma warning disable AA0210 // FA Journal Line has no key containing FA No.
        FAJournalLine.SetRange("FA No.", FixedAssetNo);
#pragma warning restore AA0210
        FAJournalLine.FindSet();
        FAJournalBatch.Get(FAJournalLine."Journal Template Name", FAJournalLine."Journal Batch Name");
        DocumentNo := NoSeries.PeekNextNo(FAJournalBatch."No. Series");
        repeat
            FAJournalLine.Validate("Document No.", DocumentNo);
            FAJournalLine.Validate(Description, FAJournalSetup."FA Jnl. Batch Name");
            FAJournalLine.Modify(true);
        until FAJournalLine.Next() = 0;
        LibraryFixedAsset.PostFAJournalLine(FAJournalLine);
    end;

    local procedure UpdateFAPostingGroup(var FAPostingGroup: Record "FA Posting Group"; ClearDeprDifferenceAcc: Boolean; ClearDeprDifferenceBalAcc: Boolean)
    begin
        if ClearDeprDifferenceAcc then
            FAPostingGroup.Validate("Deprec. Difference Account", '')
        else
            FAPostingGroup.Validate("Deprec. Difference Account", LibraryERM.CreateGLAccountNo());
        if ClearDeprDifferenceBalAcc then
            FAPostingGroup.Validate("Deprec. Difference Bal Acct", '')
        else
            FAPostingGroup.Validate("Deprec. Difference Bal Acct", LibraryERM.CreateGLAccountNo());
        FAPostingGroup.Modify(true);
    end;

    local procedure UpdateFAJournalSetup(var FAJournalSetup: Record "FA Journal Setup")
    var
        FAJournalBatch: Record "FA Journal Batch";
        FAJournalTemplate: Record "FA Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        GenJournalTemplate.Validate(Type, GenJournalTemplate.Type::Assets);
        GenJournalTemplate.Modify(true);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        GenJournalBatch.Validate("No. Series", LibraryUtility.GetGlobalNoSeriesCode());
        GenJournalBatch.Modify(true);

        LibraryFixedAsset.CreateJournalTemplate(FAJournalTemplate);
        LibraryFixedAsset.CreateFAJournalBatch(FAJournalBatch, FAJournalTemplate.Name);
        FAJournalBatch.Validate("No. Series", LibraryUtility.GetGlobalNoSeriesCode());
        FAJournalBatch.Modify(true);

        FAJournalSetup.Validate("Gen. Jnl. Template Name", GenJournalTemplate.Name);
        FAJournalSetup.Validate("Gen. Jnl. Batch Name", GenJournalBatch.Name);
        FAJournalSetup.Validate("FA Jnl. Template Name", FAJournalTemplate.Name);
        FAJournalSetup.Validate("FA Jnl. Batch Name", FAJournalBatch.Name);
        FAJournalSetup.Modify(true);
    end;

    local procedure EnqueueParamsForCalcAndPostDeprDifferenceReport(DepreciationBookCodeSUMU: Code[10]; DepreciationBookCodeTax: Code[10]; StartingDate: Date; EndingDate: Date; PostingDate: Date; DocumentNo: Code[20]; PrintEmptyLines: Boolean; PostDepreciationDifference: Boolean)
    begin
        LibraryVariableStorage.Enqueue(DepreciationBookCodeSUMU);
        LibraryVariableStorage.Enqueue(DepreciationBookCodeTax);
        LibraryVariableStorage.Enqueue(StartingDate);
        LibraryVariableStorage.Enqueue(EndingDate);
        LibraryVariableStorage.Enqueue(PostingDate);
        LibraryVariableStorage.Enqueue(DocumentNo);
        LibraryVariableStorage.Enqueue(PrintEmptyLines);
        LibraryVariableStorage.Enqueue(PostDepreciationDifference);
    end;

    local procedure RunCalcAndPostDeprDifferenceReport(FixedAssetFilter: Text)
    var
        FixedAsset: Record "Fixed Asset";
        CalcAndPostDeprDiffReport: Report "Calc. and Post Depr. Diff. FI";
    begin
        FixedAsset.SetFilter("No.", FixedAssetFilter);
        CalcAndPostDeprDiffReport.SetTableView(FixedAsset);
        CalcAndPostDeprDiffReport.UseRequestPage(true);
        CalcAndPostDeprDiffReport.Run();
    end;

    local procedure RunCalcAndPostDeprDifferenceReportWithEnqueue(DepreciationBookCodeSUMU: Code[10]; DepreciationBookCodeTax: Code[10]; StartingDate: Date; EndingDate: Date; PostingDate: Date; DocumentNo: Code[20]; PrintEmptyLines: Boolean; PostDepreciationDifference: Boolean; FixedAssetFilter: Text)
    begin
        EnqueueParamsForCalcAndPostDeprDifferenceReport(
          DepreciationBookCodeSUMU, DepreciationBookCodeTax, StartingDate, EndingDate,
          PostingDate, DocumentNo, PrintEmptyLines, PostDepreciationDifference);

        RunCalcAndPostDeprDifferenceReport(FixedAssetFilter);
        LibraryVariableStorage.AssertEmpty();
    end;

    local procedure VerifyCalcAndPostDeprDifferenceReportWithZeroDifference()
    begin
        LibraryReportDataset.LoadDataSetFile();
        Assert.IsFalse(
          LibraryReportDataset.FindRow('DifferenceAmt', 0) > -1,
                    StrSubstNo(ZeroDifferenceLineErr, 'Calc. and Post Depr. Diff.'));
    end;

    local procedure VerifyCalcAndPostDeprDifferenceReportWithEmptyLines()
    var
        DifferenceAmt: Variant;
    begin
        LibraryReportDataset.LoadDataSetFile();
        if LibraryReportDataset.GetNextRow() then begin
            LibraryReportDataset.FindCurrentRowValue('DifferenceAmt', DifferenceAmt);
            Assert.AreEqual(0, DifferenceAmt, StrSubstNo(DifferenceAmtErr, 0));
        end
    end;

    local procedure VerifyCalcAndPostDeprDifferenceReportWithDifference()
    var
        DifferenceAmt: Variant;
    begin
        LibraryReportDataset.LoadDataSetFile();
        Assert.IsTrue(LibraryReportDataset.GetNextRow(), ExpectedReportRowErr);
        LibraryReportDataset.FindCurrentRowValue('DifferenceAmt', DifferenceAmt);
        Assert.AreNotEqual(0, DifferenceAmt, StrSubstNo(DifferenceAmtErr, 0));
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure DepreciationCalcConfirmHandler(Message: Text[1024]; var Reply: Boolean)
    begin
        Reply := false;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandlerWithEnqueue(Message: Text)
    begin
        LibraryVariableStorage.Enqueue(Message);
    end;


#if not CLEAN30
    local procedure VerifyLegacyReportInstanceFeatureStatus(FeatureStatus: Enum "Feature Status"; ExpectedError: Text)
    var
        GLEntry: Record "G/L Entry";
        FALedgerEntry: Record "FA Ledger Entry";
        FeatureDataUpdateStatus: Record "Feature Data Update Status";
#pragma warning disable AL0432
        LegacyDeprDiffReport: Report "Calc. and Post Depr. Diff.";
#pragma warning restore AL0432
        DepreciationDifferencesFIFeature: Codeunit "FI Depreciation Diff. Feature";
        GLEntryCount: Integer;
        LegacyPostedEntryCount: Integer;
        PostedEntryCount: Integer;
    begin
        Initialize();
        PrepareReportFeatureStatus(FeatureStatus);
        GLEntryCount := GLEntry.Count();
#pragma warning disable AL0432
        FALedgerEntry.SetRange("Depr. Difference Posted", true);
#pragma warning restore AL0432
        LegacyPostedEntryCount := FALedgerEntry.Count();
        FALedgerEntry.Reset();
        FALedgerEntry.SetRange("Depreciation Difference Posted", true);
        PostedEntryCount := FALedgerEntry.Count();
        Commit();

        LegacyDeprDiffReport.UseRequestPage(false);
        asserterror LegacyDeprDiffReport.Run();
        Assert.ExpectedError(ExpectedError);

        Clear(LegacyDeprDiffReport);
        LegacyDeprDiffReport.UseRequestPage(false);
        asserterror LegacyDeprDiffReport.RunModal();
        Assert.ExpectedError(ExpectedError);

        Assert.RecordCount(GLEntry, GLEntryCount);
        Assert.RecordCount(FALedgerEntry, PostedEntryCount);
        FALedgerEntry.Reset();
#pragma warning disable AL0432
        FALedgerEntry.SetRange("Depr. Difference Posted", true);
#pragma warning restore AL0432
        Assert.RecordCount(FALedgerEntry, LegacyPostedEntryCount);
        FeatureDataUpdateStatus.Get(DepreciationDifferencesFIFeature.GetFeatureKeyId(), CompanyName());
        FeatureDataUpdateStatus.TestField("Feature Status", FeatureStatus);
    end;

    local procedure ClearFeatureDataUpdateStatus()
    var
        FeatureKey: Record "Feature Key";
        FeatureDataUpdateStatus: Record "Feature Data Update Status";
        DepreciationDifferencesFIFeature: Codeunit "FI Depreciation Diff. Feature";
    begin
        FeatureKey.Get(DepreciationDifferencesFIFeature.GetFeatureKeyId());
        FeatureDataUpdateStatus.SetRange("Feature Key", FeatureKey.ID);
        FeatureDataUpdateStatus.SetRange("Company Name", CompanyName());
        FeatureDataUpdateStatus.DeleteAll();
    end;

    local procedure PrepareReportFeatureStatus(FeatureStatus: Enum "Feature Status")
    var
        FeatureDataUpdateStatus: Record "Feature Data Update Status";
        DepreciationDifferencesFIFeature: Codeunit "FI Depreciation Diff. Feature";
    begin
        DisableFeature();
        ClearFeatureDataUpdateStatus();
        FeatureDataUpdateStatus.Init();
        FeatureDataUpdateStatus."Feature Key" := DepreciationDifferencesFIFeature.GetFeatureKeyId();
        FeatureDataUpdateStatus."Company Name" := CopyStr(CompanyName(), 1, MaxStrLen(FeatureDataUpdateStatus."Company Name"));
        FeatureDataUpdateStatus."Feature Status" := FeatureStatus;
        FeatureDataUpdateStatus.Insert();
    end;

    local procedure VerifyUnrelatedReportFeatureCheck(RequestPageParameters: Text)
    var
        FeatureDataUpdateStatus: Record "Feature Data Update Status";
        DepreciationDifferencesFIFeature: Codeunit "FI Depreciation Diff. Feature";
    begin
        Assert.AreEqual(1, TestCU.GetFeatureCheckCount(), 'An unrelated report must not check the FI feature.');
        Assert.IsFalse(
            FeatureDataUpdateStatus.Get(DepreciationDifferencesFIFeature.GetFeatureKeyId(), CompanyName()),
            'Checking the feature must not insert a company feature status.');
        Assert.AreEqual(Report::"Fixed Asset - List", LibraryVariableStorage.DequeueInteger(), 'The unrelated report must not be substituted.');
        Assert.AreEqual('', RequestPageParameters, 'The request page must be canceled without running the report.');
    end;

    local procedure VerifyReportFeatureStatus(ExpectedReportId: Integer; ExpectedFeatureStatus: Enum "Feature Status"; RequestPageParameters: Text)
    var
        FeatureDataUpdateStatus: Record "Feature Data Update Status";
        DepreciationDifferencesFIFeature: Codeunit "FI Depreciation Diff. Feature";
    begin
        Assert.AreEqual(ExpectedReportId, LibraryVariableStorage.DequeueInteger(), 'Unexpected report substitution.');
        FeatureDataUpdateStatus.Get(DepreciationDifferencesFIFeature.GetFeatureKeyId(), CompanyName());
        Assert.AreEqual(ExpectedFeatureStatus, FeatureDataUpdateStatus."Feature Status", 'Report substitution must not change feature status.');
        Assert.AreEqual('', RequestPageParameters, 'The request page must be canceled without running the report.');
    end;

    local procedure EnableFeature()
    begin
        SetFeatureEnabled(true);
    end;

    local procedure SetFeatureEnabled(Enabled: Boolean)
    begin
        UnbindSubscription(TestCU);
        TestCU.SetFeatureEnabledValue(Enabled);
        BindSubscription(TestCU);
    end;

    procedure SetFeatureEnabledValue(Enabled: Boolean)
    begin
        FeatureEnabled := Enabled;
        FeatureCheckCount := 0;
    end;

    procedure GetFeatureCheckCount(): Integer
    begin
        exit(FeatureCheckCount);
    end;

    local procedure DisableFeature()
    begin
        UnbindSubscription(TestCU);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"FI Depreciation Diff. Feature", OnAfterCheckFeatureEnabled, '', false, false)]
    local procedure OnAfterCheckFeatureEnabled(var IsEnabled: Boolean)
    begin
        FeatureCheckCount += 1;
        IsEnabled := FeatureEnabled;
    end;

    [RequestPageHandler]
    procedure FixedAssetListRequestPageHandler(var FixedAssetList: TestRequestPage "Fixed Asset - List")
    begin
        LibraryVariableStorage.Enqueue(Report::"Fixed Asset - List");
        FixedAssetList.Cancel().Invoke();
    end;

    [RequestPageHandler]
    procedure SubstitutedDeprDiffRequestPageHandler(var DeprDiffReport: TestRequestPage "Calc. and Post Depr. Diff. FI")
    begin
        LibraryVariableStorage.Enqueue(Report::"Calc. and Post Depr. Diff. FI");
        DeprDiffReport.Cancel().Invoke();
    end;

    [RequestPageHandler]
    procedure LegacyDeprDiffRequestPageHandler(var DeprDiffReport: TestRequestPage "Calc. and Post Depr. Diff.")
    begin
        LibraryVariableStorage.Enqueue(13402);
        DeprDiffReport.Cancel().Invoke();
    end;
#else
    local procedure EnableFeature()
    begin
    end;

    local procedure DisableFeature()
    begin
    end;
#endif
}
