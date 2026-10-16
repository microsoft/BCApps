// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using Microsoft.Bank.BankAccount;
using Microsoft.Bank.Check;
using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Foundation.Reporting;
using System.Automation;
using System.Environment.Configuration;
using System.Reflection;
using System.TestLibraries.Upgrade;
using System.Upgrade;
using System.Utilities;

codeunit 144044 "UT REP Number To Text"
{
    // [FEATURE] [Language] [UT] [Check]
    // The French amount wording is provided by Payment Management FR through the Check report event.
    // Exact grammar expectations use the forced API in English, not French translation parity.
    // Routing checks compare the report with the forced API in the same session language.

    Subtype = Test;
    TestPermissions = Disabled;
    TestType = Uncategorized;
    EventSubscriberInstance = Manual;

    var
        AttemptedCheckEntry: Record "Check Ledger Entry";
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryJournals: Codeunit "Library - Journals";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryUtility: Codeunit "Library - Utility";
        UpgradeTagLibrary: Codeunit "Upgrade Tag Library";
        UnexpectedAmountTextErr: Label 'Unexpected amount text for %1 in language %2.', Comment = '%1 = amount, %2 = language ID';
        UnexpectedLayoutErr: Label 'Unexpected check layout selection.';
        RestrictionDetailsTxt: Label 'Test-print journal line requires approval.';
        CheckInsertCount: Integer;

    [Test]
    procedure TestPrintPreservesJournalAssociation()
    var
        BankAccount: Record "Bank Account";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653674] FR test printing associates the entry with its journal without advancing the bank check number.
        Initialize();

        // [GIVEN] Bank account B and payment journal line J with Payment Management FR installed.
        CreateTestPrintJournalLine(BankAccount, GenJournalLine);
        Commit();

        // [WHEN] The Check report executes its test-print path.
        RunTestPrint(BankAccount, GenJournalLine);

        // [THEN] The test-print entry references J and B keeps its last check number.
        VerifyTestPrint(BankAccount, GenJournalLine.SystemId);
    end;

    [Test]
    procedure TestPrintRejectsRestrictedJournalLine()
    var
        BankAccount: Record "Bank Account";
        GenJournalLine: Record "Gen. Journal Line";
        RecordRestrictionMgt: Codeunit "Record Restriction Mgt.";
        RestrictionObserver: Codeunit "UT REP Number To Text";
        ExpectedRestrictionError: Text;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653674] FR test printing enforces journal usage restrictions when inserting the check entry.
        Initialize();

        // [GIVEN] Journal line J is restricted and an observer captures the attempted check insertion.
        CreateTestPrintJournalLine(BankAccount, GenJournalLine);
        RecordRestrictionMgt.RestrictRecordUsage(GenJournalLine, RestrictionDetailsTxt);
        Commit();
        ExpectedRestrictionError := GetJournalRestrictionError(GenJournalLine);
        BindSubscription(RestrictionObserver);

        // [WHEN] The Check report attempts to test print J.
        asserterror RunTestPrint(BankAccount, GenJournalLine);

        // [THEN] The journal restriction, not report preflight, rejects the test-print insertion.
        Assert.ExpectedError(ExpectedRestrictionError);
        Assert.ExpectedErrorCode('Dialog');
        UnbindSubscription(RestrictionObserver);
        VerifyRejectedTestPrint(RestrictionObserver, BankAccount, GenJournalLine.SystemId);
    end;

    [Test]
    procedure FrenchNumberGrammar()
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653674] The forced FR API preserves legacy grammar with known English source labels.
        Initialize();

        // [GIVEN] English source labels, independently of the user's session language.

        // [WHEN] Each amount is passed to a fresh formatter without initialization.

        // [THEN] Both lines match the legacy French algorithm, not a French translation.
        VerifyFrenchAmountText(21, '**** TWENTY AND ONE EUROS');
        VerifyFrenchAmountText(71, '**** SIXTY AND ELEVEN EUROS');
        VerifyFrenchAmountText(80, '**** EIGHTYS EUROS');
        VerifyFrenchAmountText(81, '**** EIGHTY ONE EUROS');
        VerifyFrenchAmountText(91, '**** EIGHTY ELEVEN EUROS');
        VerifyFrenchAmountText(100, '**** HUNDRED EUROS');
        VerifyFrenchAmountText(200, '**** TWO HUNDREDS EUROS');
        VerifyFrenchAmountText(201, '**** TWO HUNDRED ONE EUROS');
        VerifyFrenchAmountText(1000, '**** THOUSAND EUROS');
        VerifyFrenchAmountText(1001, '**** THOUSAND ONE EUROS');
        VerifyFrenchAmountText(2000, '**** TWO THOUSAND EUROS');
        VerifyFrenchAmountText(1000000, '**** ONE MILLION EUROS');
        VerifyFrenchAmountText(2000000, '**** TWO MILLIONS EUROS');
    end;

    [Test]
    procedure FrenchEuroAndCentWording()
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653674] Blank currency keeps the legacy euro and cent grammar.
        Initialize();

        // [GIVEN] English source labels and a blank currency.

        // [WHEN] The forced FR API formats whole and fractional amounts.

        // [THEN] Both lines match the legacy output.
        VerifyFrenchAmountText(0, '**** ZERO EUROS');
        VerifyFrenchAmountText(1, '**** ONE EUROS');
        VerifyFrenchAmountText(1.01, '**** ONE EUROS ONE CENT');
        VerifyFrenchAmountText(1.02, '**** ONE EUROS TWO CENTS');
    end;

    [Test]
    procedure AllFrenchLanguagesUseFrenchWording()
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653674] Standard, Belgian, Swiss and Canadian French sessions use the French wording.
        Initialize();

        // [GIVEN] The four supported French session languages.

        // [WHEN] The report and forced FR API format the same amount in each language.

        // [THEN] Both lines agree, without assuming which translations are installed.
        VerifyFrenchReportRouting();
    end;

    [Test]
    procedure NonFrenchLanguageUsesHundredths()
    var
        Check: Report Check;
        NoText: array[2] of Text[80];
        OriginalLanguageId: Integer;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653674] Other languages keep the international wording with hundredths.
        Initialize();

        // [GIVEN] An English session and a report without wording initialization.
        OriginalLanguageId := GlobalLanguage();
        GlobalLanguage(1033);

        // [WHEN] The report routes the amount to the subscriber.
        Check.FormatNoText(NoText, 21.25, '');
        GlobalLanguage(OriginalLanguageId);

        // [THEN] The international result is returned on both lines.
        VerifyAmountLines(NoText, '**** TWENTY ONE AND 25/100', '');
    end;

    [Test]
    procedure PublicInternationalAPIRequiresNoInitialization()
    var
        CheckAmountWordingFR: Codeunit "Check Amount Wording FR";
        NoText: array[2] of Text[80];
        OriginalLanguageId: Integer;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653674] A Cloud-callable forced INTL API works without report initialization.
        Initialize();

        // [GIVEN] A fresh formatter in an English session.
        OriginalLanguageId := GlobalLanguage();
        GlobalLanguage(1033);

        // [WHEN] The public INTL method is called directly.
        CheckAmountWordingFR.FormatNoTextINTL(NoText, 21.25, 'USD');
        GlobalLanguage(OriginalLanguageId);

        // [THEN] The exact legacy international output is returned.
        VerifyAmountLines(NoText, '**** TWENTY ONE AND 25/100 USD', '');
    end;

    [Test]
    procedure PublicTensAPIRequiresNoInitialization()
    var
        CheckAmountWordingFR: Codeunit "Check Amount Wording FR";
        NoText: array[2] of Text[80];
        NoTextIndex: Integer;
        OriginalLanguageId: Integer;
        PrintExponent: Boolean;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653674] The public tens API initializes labels and preserves the caller's buffer.
        Initialize();

        // [GIVEN] A fresh formatter and a partially filled second line in English.
        OriginalLanguageId := GlobalLanguage();
        GlobalLanguage(1033);
        NoText[1] := 'FIRST LINE';
        NoText[2] := '****';
        NoTextIndex := 2;

        // [WHEN] The legacy signature formats seventy-one without a preceding API call.
        CheckAmountWordingFR.FormatTens(NoText, NoTextIndex, PrintExponent, 1, 0, 7, 1);
        GlobalLanguage(OriginalLanguageId);

        // [THEN] The text and by-reference state follow the legacy contract.
        VerifyTensResult(NoText, NoTextIndex, PrintExponent);
    end;

    [Test]
    procedure PublicAPIsRefreshLabelsAfterLanguageSwitch()
    var
        FrenchFormatter: Codeunit "Check Amount Wording FR";
        InternationalFormatter: Codeunit "Check Amount Wording FR";
        TensFormatter: Codeunit "Check Amount Wording FR";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653674] All public APIs reload labels when the same instance changes language.
        Initialize();

        // [GIVEN] An instance first used with English source labels.
        VerifyCurrentLanguageAPIs(FrenchFormatter, InternationalFormatter, TensFormatter, 1033);

        // [WHEN] The same instance switches to French and back to English.

        // [THEN] Each API matches a fresh instance in the current language on both lines.
        VerifyCurrentLanguageAPIs(FrenchFormatter, InternationalFormatter, TensFormatter, 1036);
        VerifyCurrentLanguageAPIs(FrenchFormatter, InternationalFormatter, TensFormatter, 1033);
    end;

    [Test]
    procedure MissingFrenchCurrencyRaisesRecordNotFound()
    var
        Currency: Record Currency;
        CheckAmountWordingFR: Codeunit "Check Amount Wording FR";
        NoText: array[2] of Text[80];
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653674] Forced French wording retains the missing currency error.
        Initialize();

        // [GIVEN] A unique currency code whose record no longer exists.
        CreateUniqueCurrency(Currency);
        Currency.Delete();

        // [WHEN] The forced FR API needs the missing currency description.
        asserterror CheckAmountWordingFR.FormatNoTextFR(NoText, 1.02, Currency.Code);

        // [THEN] The missing record error names the requested currency.
        VerifyMissingCurrencyError(Currency.Code);
    end;

    [Test]
    procedure InternationalWordingIgnoresCurrencyPrecision()
    var
        Currency: Record Currency;
        Check: Report Check;
        CheckAmountWordingFR: Codeunit "Check Amount Wording FR";
        NoText: array[2] of Text[80];
        ReportNoText: array[2] of Text[80];
        OriginalLanguageId: Integer;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653674] Both the forced INTL API and report use /100 for a three-decimal currency.
        Initialize();

        // [GIVEN] Currency C has three-decimal precision in an English session.
        CreateUniqueCurrency(Currency);
        Currency."Amount Rounding Precision" := 0.001;
        Currency."Amount Decimal Places" := '3:3';
        Currency.Modify();
        OriginalLanguageId := GlobalLanguage();
        GlobalLanguage(1033);

        // [WHEN] The same amount is formatted directly and through the report.
        CheckAmountWordingFR.FormatNoTextINTL(NoText, 21.25, Currency.Code);
        Check.FormatNoText(ReportNoText, 21.25, Currency.Code);
        GlobalLanguage(OriginalLanguageId);

        // [THEN] Neither path uses the currency's /1000 denominator.
        VerifyInternationalPrecision(NoText, ReportNoText, Currency.Code);
    end;

    [Test]
    procedure FrenchExplicitCurrencyWording()
    var
        Currency: Record Currency;
        NoText: array[2] of Text[80];
        EuroNoText: array[2] of Text[80];
        OtherNoText: array[2] of Text[80];
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653674] Explicit currencies use the currency description, and only FRF prints cents.
        Initialize();

        // [GIVEN] FRF, EUR and another currency have known descriptions.
        CreateCurrency(Currency, 'FRF', 'Franc');
        CreateCurrency(Currency, 'EUR', 'Euro');
        CreateCurrency(Currency, 'TESTFR', 'Test Currency');

        // [WHEN] The forced FR API uses English source labels for the same amount.
        FormatFrenchAmount(NoText, 1.02, 'FRF');
        FormatFrenchAmount(EuroNoText, 1.02, 'EUR');
        FormatFrenchAmount(OtherNoText, 1.02, 'TESTFR');

        // [THEN] FRF prints cents, while explicit EUR differs from blank currency.
        VerifyExplicitCurrencies(NoText, EuroNoText, OtherNoText);
    end;

    [Test]
    procedure LongAmountTextIsSplitInTwoLines()
    var
        NoText: array[2] of Text[80];
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653674] A long amount text is split into the two lines of the check.
        Initialize();

        // [GIVEN] An amount whose forced French wording exceeds eighty characters.

        // [WHEN] The forced FR API formats it using English source labels.
        FormatFrenchAmount(NoText, 999999.99, '');

        // [THEN] Both complete lines preserve the legacy word boundaries and cents.
        VerifyAmountLines(
            NoText, '**** NINE HUNDRED EIGHTY NINETEEN THOUSAND NINE HUNDRED EIGHTY NINETEEN EUROS',
            'EIGHTY NINETEEN CENTS');
    end;

    [Test]
    procedure FrenchCheckLayoutIsProvidedByExtension()
    var
        ReportLayoutList: Record "Report Layout List";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653674] The French layout is owned by Payment Management FR, not Base Application.
        Initialize();

        // [GIVEN] The payment extension is installed.

        // [WHEN] Its CheckFR layout is looked up.
        ReportLayoutList.Get(Report::Check, 'CheckFR', PaymentManagementAppId());

        // [THEN] The app-owned layout is RDLC.
        Assert.AreEqual(ReportLayoutList."Layout Format"::RDLC, ReportLayoutList."Layout Format", UnexpectedLayoutErr);
    end;

    [Test]
    procedure FrenchCheckLayoutIsSelectedWithoutExistingSelection()
    var
        ReportLayoutsFR: Codeunit "Report Layouts FR";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653674] A company using the implicit built-in layout gets the extension layout.
        Initialize();

        // [GIVEN] No check layout selection exists.
        ClearLayoutSelections();

        // [WHEN] The default layout is selected.
        ReportLayoutsFR.SetDefaultCheckLayout();

        // [THEN] The company uses the extension layout.
        VerifyLayoutSelection(CompanyName(), 'CheckFR', PaymentManagementAppId());
    end;

    [Test]
    procedure LegacyBuiltInCheckLayoutIsMigrated()
    var
        ReportLayoutsFR: Codeunit "Report Layouts FR";
        BaseApplicationId: Guid;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653674] An explicit Base Application check layout selection is migrated.
        Initialize();

        // [GIVEN] The company explicitly uses the Base Application layout.
        ClearLayoutSelections();
        BaseApplicationId := '437dbf0e-84ff-417a-965d-ed2bb9650972';
        CreateLayoutSelection(CompanyName(), 'RDLCLayout', BaseApplicationId);

        // [WHEN] The default layout is selected.
        ReportLayoutsFR.SetDefaultCheckLayout();

        // [THEN] The company uses the extension layout.
        VerifyLayoutSelection(CompanyName(), 'CheckFR', PaymentManagementAppId());
    end;

    [Test]
    procedure AllCompanyBuiltInCheckLayoutIsMigratedPerCompany()
    var
        ReportLayoutsFR: Codeunit "Report Layouts FR";
        BaseApplicationId: Guid;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653674] A global built-in default is migrated only for the current company.
        Initialize();

        // [GIVEN] All companies use the Base Application default.
        ClearLayoutSelections();
        BaseApplicationId := '437dbf0e-84ff-417a-965d-ed2bb9650972';
        CreateLayoutSelection('', 'RDLCLayout', BaseApplicationId);

        // [WHEN] The current company's default is selected.
        ReportLayoutsFR.SetDefaultCheckLayout();

        // [THEN] The company migrates without changing the global default.
        VerifyCompanyAndGlobalLayouts(BaseApplicationId);
    end;

    [Test]
    procedure CustomCheckLayoutSelectionIsPreserved()
    var
        ReportLayoutsFR: Codeunit "Report Layouts FR";
        EmptyGuid: Guid;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653674] A tenant-defined company layout is not replaced.
        Initialize();

        // [GIVEN] The company uses a tenant-defined layout.
        ClearLayoutSelections();
        CreateLayoutSelection(CompanyName(), 'CUSTOM CHECK', EmptyGuid);

        // [WHEN] The default layout is selected.
        ReportLayoutsFR.SetDefaultCheckLayout();

        // [THEN] The tenant-defined selection is unchanged.
        VerifyLayoutSelection(CompanyName(), 'CUSTOM CHECK', EmptyGuid);
    end;

    [Test]
    procedure AllCompanyCustomCheckLayoutSelectionIsPreserved()
    var
        ReportLayoutsFR: Codeunit "Report Layouts FR";
        EmptyGuid: Guid;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653674] A custom default applying to all companies is not shadowed.
        Initialize();

        // [GIVEN] A global tenant-defined layout is selected.
        ClearLayoutSelections();
        CreateLayoutSelection('', 'CUSTOM CHECK', EmptyGuid);

        // [WHEN] The company default is selected.
        ReportLayoutsFR.SetDefaultCheckLayout();

        // [THEN] The global selection survives without a company-specific override.
        VerifyGlobalCustomLayout(EmptyGuid);
    end;

    [Test]
    procedure OtherExtensionCheckLayoutSelectionIsPreserved()
    var
        ReportLayoutsFR: Codeunit "Report Layouts FR";
        OtherAppId: Guid;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653674] A layout selected from another extension is not replaced.
        Initialize();

        // [GIVEN] A third-party extension layout is selected.
        ClearLayoutSelections();
        OtherAppId := CreateGuid();
        CreateLayoutSelection(CompanyName(), 'OTHER CHECK', OtherAppId);

        // [WHEN] The default layout is selected.
        ReportLayoutsFR.SetDefaultCheckLayout();

        // [THEN] The third-party selection is unchanged.
        VerifyLayoutSelection(CompanyName(), 'OTHER CHECK', OtherAppId);
    end;

    [Test]
    procedure LegacyCustomCheckLayoutSelectionIsPreserved()
    var
        ReportLayoutsFR: Codeunit "Report Layouts FR";
        CustomLayoutCode: Code[20];
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653674] A legacy custom layout remains selected.
        Initialize();

        // [GIVEN] A legacy custom selection references an existing layout for the check report.
        ClearLayoutSelections();
        CustomLayoutCode := CreateLegacyCustomLayoutSelection();

        // [WHEN] The default layout is selected.
        ReportLayoutsFR.SetDefaultCheckLayout();

        // [THEN] The legacy selection remains without a tenant override.
        VerifyLegacyCustomLayout(CustomLayoutCode);
    end;

    [Test]
    procedure FrenchCheckLayoutSelectionIsIdempotent()
    var
        ReportLayoutsFR: Codeunit "Report Layouts FR";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653674] The shared install/upgrade path tags the migration and is idempotent.
        Initialize();

        // [GIVEN] A company without selections or the cheque layout upgrade tag.
        ClearLayoutSelections();
        ClearCheckLayoutUpgradeTag();

        // [WHEN] The same entry point used by installation and upgrade runs twice.
        ReportLayoutsFR.UpgradeCheckLayout();
        ReportLayoutsFR.UpgradeCheckLayout();

        // [THEN] The layout is selected once and the upgrade tag is persisted.
        VerifyTaggedLayout('CheckFR', PaymentManagementAppId());
    end;

    [Test]
    procedure UserSpecificCheckLayoutSelectionIsPreserved()
    var
        TenantReportLayoutSelection: Record "Tenant Report Layout Selection";
        ReportLayoutsFR: Codeunit "Report Layouts FR";
        SelectedUserId: Guid;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653674] Migrating the company default does not change user-specific selections.
        Initialize();

        // [GIVEN] A user-specific selection exists.
        ClearLayoutSelections();
        SelectedUserId := CreateGuid();
        TenantReportLayoutSelection.Init();
        TenantReportLayoutSelection."Report ID" := Report::Check;
        TenantReportLayoutSelection."Company Name" :=
            CopyStr(CompanyName(), 1, MaxStrLen(TenantReportLayoutSelection."Company Name"));
        TenantReportLayoutSelection."User ID" := SelectedUserId;
        TenantReportLayoutSelection."Layout Name" := 'USER CHECK';
        TenantReportLayoutSelection.Insert();

        // [WHEN] The company default is selected.
        ReportLayoutsFR.SetDefaultCheckLayout();

        // [THEN] The company migrates but the user's selection is unchanged.
        VerifyUserSpecificLayout(SelectedUserId);
    end;

    [Test]
    procedure CompletedLayoutUpgradeDoesNotOverrideLaterSelection()
    var
        ReportLayoutsFR: Codeunit "Report Layouts FR";
        BaseApplicationId: Guid;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653674] Later upgrades preserve a built-in choice made after the install migration.
        Initialize();

        // [GIVEN] The shared install path has migrated and tagged the company.
        ClearLayoutSelections();
        ClearCheckLayoutUpgradeTag();
        ReportLayoutsFR.UpgradeCheckLayout();

        // [GIVEN] The user subsequently selects the Base Application layout explicitly.
        BaseApplicationId := '437dbf0e-84ff-417a-965d-ed2bb9650972';
        ChangeCompanyLayoutSelection('RDLCLayout', BaseApplicationId);

        // [WHEN] A later upgrade runs the same tagged migration.
        ReportLayoutsFR.UpgradeCheckLayout();

        // [THEN] The explicit built-in choice and original tag survive.
        VerifyTaggedLayout('RDLCLayout', BaseApplicationId);
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"UT REP Number To Text");
        ClearLastError();
    end;

    local procedure CreateTestPrintJournalLine(var BankAccount: Record "Bank Account"; var GenJournalLine: Record "Gen. Journal Line")
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        LibraryERM.CreateBankAccount(BankAccount);
        BankAccount.Validate("Last Check No.", '100');
        BankAccount.Modify(true);
        LibraryJournals.CreateGenJournalBatch(GenJournalBatch);
        GenJournalBatch.Validate("No. Series", LibraryUtility.GetGlobalNoSeriesCode());
        GenJournalBatch.Validate("Bal. Account Type", GenJournalBatch."Bal. Account Type"::"Bank Account");
        GenJournalBatch.Validate("Bal. Account No.", BankAccount."No.");
        GenJournalBatch.Modify(true);
        LibraryERM.CreateGeneralJnlLine(
            GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
            GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Vendor,
            LibraryPurchase.CreateVendorNo(), 100);
        GenJournalLine.Validate("Bank Payment Type", GenJournalLine."Bank Payment Type"::"Computer Check");
        GenJournalLine.Modify(true);
        GenJournalLine.SetRecFilter();
    end;

    local procedure RunTestPrint(BankAccount: Record "Bank Account"; GenJournalLine: Record "Gen. Journal Line")
    var
        Check: Report Check;
        TempBlob: Codeunit "Temp Blob";
        JournalRecordRef: RecordRef;
        OutputStream: OutStream;
    begin
        JournalRecordRef.GetTable(GenJournalLine);
        Check.InitializeRequest(BankAccount."No.", BankAccount."Last Check No.", false, false, true, false);
        TempBlob.CreateOutStream(OutputStream);
        Check.SaveAs('', ReportFormat::Xml, OutputStream, JournalRecordRef);
    end;

    local procedure GetJournalRestrictionError(GenJournalLine: Record "Gen. Journal Line"): Text
    var
        RecordRestrictionMgt: Codeunit "Record Restriction Mgt.";
    begin
        asserterror RecordRestrictionMgt.CheckRecordHasUsageRestrictions(GenJournalLine);
        Assert.ExpectedError(RestrictionDetailsTxt);
        Assert.ExpectedErrorCode('Dialog');
        exit(GetLastErrorText());
    end;

    procedure GetAttemptedCheckEntry(var CheckLedgerEntry: Record "Check Ledger Entry"): Integer
    begin
        CheckLedgerEntry := AttemptedCheckEntry;
        exit(CheckInsertCount);
    end;

    local procedure VerifyTestPrint(BankAccount: Record "Bank Account"; ExpectedJournalSystemId: Guid)
    var
        CheckLedgerEntry: Record "Check Ledger Entry";
    begin
        CheckLedgerEntry.SetRange("Bank Account No.", BankAccount."No.");
        Assert.RecordCount(CheckLedgerEntry, 1);
        CheckLedgerEntry.FindFirst();
        VerifyTestPrintEntry(CheckLedgerEntry, ExpectedJournalSystemId);
        VerifyLastCheckNo(BankAccount);
    end;

    local procedure VerifyTestPrintEntry(CheckLedgerEntry: Record "Check Ledger Entry"; ExpectedJournalSystemId: Guid)
    begin
        Assert.AreEqual(CheckLedgerEntry."Entry Status"::"Test Print", CheckLedgerEntry."Entry Status", 'Expected a test-print check ledger entry.');
        Assert.AreEqual(ExpectedJournalSystemId, CheckLedgerEntry."Print Gen Jnl Line SystemId", 'Test printing must preserve the source journal association.');
    end;

    local procedure VerifyLastCheckNo(BankAccount: Record "Bank Account")
    var
        LastCheckNo: Code[20];
    begin
        LastCheckNo := BankAccount."Last Check No.";
        BankAccount.Get(BankAccount."No.");
        Assert.AreEqual(LastCheckNo, BankAccount."Last Check No.", 'Test printing must not advance the last check number.');
    end;

    local procedure VerifyRejectedTestPrint(RestrictionObserver: Codeunit "UT REP Number To Text"; BankAccount: Record "Bank Account"; ExpectedJournalSystemId: Guid)
    var
        CheckLedgerEntry: Record "Check Ledger Entry";
    begin
        Assert.AreEqual(1, RestrictionObserver.GetAttemptedCheckEntry(CheckLedgerEntry), 'The report must reach check ledger entry insertion once.');
        VerifyTestPrintEntry(CheckLedgerEntry, ExpectedJournalSystemId);
        CheckLedgerEntry.SetRange("Bank Account No.", BankAccount."No.");
        Assert.RecordIsEmpty(CheckLedgerEntry);
        VerifyLastCheckNo(BankAccount);
    end;

    local procedure ClearLayoutSelections()
    var
        ReportLayoutSelection: Record "Report Layout Selection";
        TenantReportLayoutSelection: Record "Tenant Report Layout Selection";
    begin
        ReportLayoutSelection.SetRange("Report ID", Report::Check);
        ReportLayoutSelection.DeleteAll();
        TenantReportLayoutSelection.SetRange("Report ID", Report::Check);
        TenantReportLayoutSelection.DeleteAll();
    end;

    local procedure CreateLayoutSelection(SelectedCompany: Text; LayoutName: Text[250]; AppId: Guid)
    var
        TenantReportLayoutSelection: Record "Tenant Report Layout Selection";
    begin
        TenantReportLayoutSelection.Init();
        TenantReportLayoutSelection."Report ID" := Report::Check;
        TenantReportLayoutSelection."Company Name" :=
            CopyStr(SelectedCompany, 1, MaxStrLen(TenantReportLayoutSelection."Company Name"));
        TenantReportLayoutSelection."Layout Name" := LayoutName;
        TenantReportLayoutSelection."App ID" := AppId;
        TenantReportLayoutSelection.Insert();
    end;

    local procedure VerifyLayoutSelection(SelectedCompany: Text; LayoutName: Text[250]; AppId: Guid)
    var
        TenantReportLayoutSelection: Record "Tenant Report Layout Selection";
        EmptyGuid: Guid;
    begin
        TenantReportLayoutSelection.Get(Report::Check, SelectedCompany, EmptyGuid);
        Assert.AreEqual(LayoutName, TenantReportLayoutSelection."Layout Name", UnexpectedLayoutErr);
        Assert.AreEqual(AppId, TenantReportLayoutSelection."App ID", UnexpectedLayoutErr);
    end;

    local procedure PaymentManagementAppId(): Guid
    begin
        exit('24f54185-e697-4e03-bae0-f134f2d69673');
    end;

    local procedure VerifyFrenchAmountText(Amount: Decimal; ExpectedAmountText: Text)
    var
        NoText: array[2] of Text[80];
    begin
        FormatFrenchAmount(NoText, Amount, '');
        VerifyAmountLines(NoText, ExpectedAmountText, '');
    end;

    local procedure FrenchLanguageIds() LanguageIds: List of [Integer]
    begin
        LanguageIds.Add(1036);
        LanguageIds.Add(2060);
        LanguageIds.Add(3084);
        LanguageIds.Add(4108);
    end;

    local procedure VerifyFrenchReportRouting()
    var
        Check: Report Check;
        CheckAmountWordingFR: Codeunit "Check Amount Wording FR";
        ExpectedNoText: array[2] of Text[80];
        NoText: array[2] of Text[80];
        LanguageId: Integer;
        OriginalLanguageId: Integer;
    begin
        OriginalLanguageId := GlobalLanguage();
        foreach LanguageId in FrenchLanguageIds() do begin
            GlobalLanguage(LanguageId);
            Clear(CheckAmountWordingFR);
            Clear(Check);
            CheckAmountWordingFR.FormatNoTextFR(ExpectedNoText, 999999.99, '');
            Check.FormatNoText(NoText, 999999.99, '');
            GlobalLanguage(OriginalLanguageId);
            Assert.AreEqual(ExpectedNoText[1], NoText[1], StrSubstNo(UnexpectedAmountTextErr, 999999.99, LanguageId));
            Assert.AreEqual(ExpectedNoText[2], NoText[2], StrSubstNo(UnexpectedAmountTextErr, 999999.99, LanguageId));
        end;
    end;

    local procedure FormatFrenchAmount(var NoText: array[2] of Text[80]; Amount: Decimal; CurrencyCode: Code[10])
    var
        CheckAmountWordingFR: Codeunit "Check Amount Wording FR";
        OriginalLanguageId: Integer;
    begin
        OriginalLanguageId := GlobalLanguage();
        GlobalLanguage(1033);
        CheckAmountWordingFR.FormatNoTextFR(NoText, Amount, CurrencyCode);
        GlobalLanguage(OriginalLanguageId);
    end;

    local procedure VerifyAmountLines(NoText: array[2] of Text[80]; ExpectedFirstLine: Text; ExpectedSecondLine: Text)
    begin
        Assert.AreEqual(ExpectedFirstLine, NoText[1], 'Unexpected first amount line.');
        Assert.AreEqual(ExpectedSecondLine, NoText[2], 'Unexpected second amount line.');
    end;

    local procedure VerifyTensResult(NoText: array[2] of Text[80]; NoTextIndex: Integer; PrintExponent: Boolean)
    begin
        VerifyAmountLines(NoText, 'FIRST LINE', '**** SIXTY AND ELEVEN');
        Assert.AreEqual(2, NoTextIndex, 'The caller-selected line must be preserved.');
        Assert.IsTrue(PrintExponent, 'The appended words must request the exponent.');
    end;

    local procedure VerifyCurrentLanguageAPIs(var FrenchFormatter: Codeunit "Check Amount Wording FR"; var InternationalFormatter: Codeunit "Check Amount Wording FR"; var TensFormatter: Codeunit "Check Amount Wording FR"; LanguageId: Integer)
    var
        FreshFormatter: Codeunit "Check Amount Wording FR";
        FrenchNoText: array[2] of Text[80];
        InternationalNoText: array[2] of Text[80];
        TensNoText: array[2] of Text[80];
        ExpectedFrenchNoText: array[2] of Text[80];
        ExpectedInternationalNoText: array[2] of Text[80];
        ExpectedTensNoText: array[2] of Text[80];
        NoTextIndex: Integer;
        ExpectedNoTextIndex: Integer;
        PrintExponent: Boolean;
        ExpectedPrintExponent: Boolean;
        OriginalLanguageId: Integer;
    begin
        OriginalLanguageId := GlobalLanguage();
        GlobalLanguage(LanguageId);
        FrenchFormatter.FormatNoTextFR(FrenchNoText, 2345.67, '');
        FreshFormatter.FormatNoTextFR(ExpectedFrenchNoText, 2345.67, '');
        Clear(FreshFormatter);
        InternationalFormatter.FormatNoTextINTL(InternationalNoText, 2345.67, '');
        FreshFormatter.FormatNoTextINTL(ExpectedInternationalNoText, 2345.67, '');
        Clear(FreshFormatter);
        NoTextIndex := 1;
        ExpectedNoTextIndex := 1;
        TensFormatter.FormatTens(TensNoText, NoTextIndex, PrintExponent, 1, 0, 3, 2);
        FreshFormatter.FormatTens(ExpectedTensNoText, ExpectedNoTextIndex, ExpectedPrintExponent, 1, 0, 3, 2);
        GlobalLanguage(OriginalLanguageId);

        VerifyAmountLines(FrenchNoText, ExpectedFrenchNoText[1], ExpectedFrenchNoText[2]);
        VerifyAmountLines(InternationalNoText, ExpectedInternationalNoText[1], ExpectedInternationalNoText[2]);
        VerifyAmountLines(TensNoText, ExpectedTensNoText[1], ExpectedTensNoText[2]);
        Assert.AreEqual(ExpectedNoTextIndex, NoTextIndex, 'The tens API must use the current language.');
        Assert.AreEqual(ExpectedPrintExponent, PrintExponent, 'The tens API must preserve exponent behavior.');
    end;

    local procedure VerifyMissingCurrencyError(CurrencyCode: Code[10])
    begin
        Assert.ExpectedError(CurrencyCode);
        Assert.ExpectedErrorCode('DB:RecordNotFound');
    end;

    local procedure VerifyInternationalPrecision(NoText: array[2] of Text[80]; ReportNoText: array[2] of Text[80]; CurrencyCode: Code[10])
    begin
        VerifyAmountLines(NoText, '**** TWENTY ONE AND 25/100 ' + CurrencyCode, '');
        VerifyAmountLines(ReportNoText, NoText[1], NoText[2]);
    end;

    local procedure VerifyExplicitCurrencies(FrancNoText: array[2] of Text[80]; EuroNoText: array[2] of Text[80]; OtherNoText: array[2] of Text[80])
    begin
        VerifyAmountLines(FrancNoText, '**** ONE FRANC TWO CENTS', '');
        VerifyAmountLines(EuroNoText, '**** ONE EURO TWO', '');
        VerifyAmountLines(OtherNoText, '**** ONE TEST CURRENCY TWO', '');
    end;

    local procedure ClearCheckLayoutUpgradeTag()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgTagPayment: Codeunit "Upg. Tag Payment Management FR";
        SelectedCompany: Code[30];
    begin
        SelectedCompany := CopyStr(CompanyName(), 1, MaxStrLen(SelectedCompany));
        if UpgradeTag.HasUpgradeTag(UpgTagPayment.GetCheckLayoutUpgradeTag()) then
            UpgradeTagLibrary.DeleteUpgradeTag(UpgTagPayment.GetCheckLayoutUpgradeTag(), SelectedCompany);
    end;

    local procedure ChangeCompanyLayoutSelection(LayoutName: Text[250]; AppId: Guid)
    var
        TenantReportLayoutSelection: Record "Tenant Report Layout Selection";
        EmptyGuid: Guid;
    begin
        TenantReportLayoutSelection.Get(Report::Check, CompanyName(), EmptyGuid);
        TenantReportLayoutSelection."Layout Name" := LayoutName;
        TenantReportLayoutSelection."App ID" := AppId;
        TenantReportLayoutSelection.Modify();
    end;

    local procedure VerifyTaggedLayout(LayoutName: Text[250]; AppId: Guid)
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgTagPayment: Codeunit "Upg. Tag Payment Management FR";
    begin
        VerifyLayoutSelection(CompanyName(), LayoutName, AppId);
        Assert.IsTrue(UpgradeTag.HasUpgradeTag(UpgTagPayment.GetCheckLayoutUpgradeTag()), 'The shared install/upgrade path must set the cheque layout tag.');
    end;

    local procedure CreateLegacyCustomLayoutSelection(): Code[20]
    var
        CustomReportLayout: Record "Custom Report Layout";
        ReportLayoutSelection: Record "Report Layout Selection";
    begin
        CustomReportLayout.Init();
        CustomReportLayout.Code := CopyStr(DelChr(Format(CreateGuid()), '=', '{}-'), 1, MaxStrLen(CustomReportLayout.Code));
        CustomReportLayout."Report ID" := Report::Check;
        CustomReportLayout."Company Name" := CopyStr(CompanyName(), 1, MaxStrLen(CustomReportLayout."Company Name"));
        CustomReportLayout.Type := CustomReportLayout.Type::RDLC;
        CustomReportLayout.Insert();

        ReportLayoutSelection.Init();
        ReportLayoutSelection."Report ID" := Report::Check;
        ReportLayoutSelection."Company Name" := CopyStr(CompanyName(), 1, MaxStrLen(ReportLayoutSelection."Company Name"));
        ReportLayoutSelection.Type := ReportLayoutSelection.Type::"Custom Layout";
        ReportLayoutSelection.Validate("Custom Report Layout Code", CustomReportLayout.Code);
        ReportLayoutSelection.Insert();
        exit(CustomReportLayout.Code);
    end;

    local procedure VerifyCompanyAndGlobalLayouts(BaseApplicationId: Guid)
    begin
        VerifyLayoutSelection(CompanyName(), 'CheckFR', PaymentManagementAppId());
        VerifyLayoutSelection('', 'RDLCLayout', BaseApplicationId);
    end;

    local procedure VerifyGlobalCustomLayout(EmptyGuid: Guid)
    var
        TenantReportLayoutSelection: Record "Tenant Report Layout Selection";
    begin
        VerifyLayoutSelection('', 'CUSTOM CHECK', EmptyGuid);
        Assert.IsFalse(TenantReportLayoutSelection.Get(Report::Check, CompanyName(), EmptyGuid), UnexpectedLayoutErr);
    end;

    local procedure VerifyLegacyCustomLayout(CustomLayoutCode: Code[20])
    var
        ReportLayoutSelection: Record "Report Layout Selection";
        TenantReportLayoutSelection: Record "Tenant Report Layout Selection";
        EmptyGuid: Guid;
    begin
        ReportLayoutSelection.Get(Report::Check, CompanyName());
        Assert.AreEqual(CustomLayoutCode, ReportLayoutSelection."Custom Report Layout Code", UnexpectedLayoutErr);
        Assert.IsFalse(TenantReportLayoutSelection.Get(Report::Check, CompanyName(), EmptyGuid), UnexpectedLayoutErr);
    end;

    local procedure VerifyUserSpecificLayout(SelectedUserId: Guid)
    var
        TenantReportLayoutSelection: Record "Tenant Report Layout Selection";
        EmptyGuid: Guid;
    begin
        VerifyLayoutSelection(CompanyName(), 'CheckFR', PaymentManagementAppId());
        TenantReportLayoutSelection.Get(Report::Check, CompanyName(), SelectedUserId);
        Assert.AreEqual('USER CHECK', TenantReportLayoutSelection."Layout Name", UnexpectedLayoutErr);
        Assert.AreEqual(EmptyGuid, TenantReportLayoutSelection."App ID", UnexpectedLayoutErr);
    end;

    local procedure CreateCurrency(var Currency: Record Currency; CurrencyCode: Code[10]; Description: Text[30])
    begin
        if not Currency.Get(CurrencyCode) then begin
            // Wording needs no exchange-rate setup or its currency validation notifications.
            Currency.Init();
            Currency.Code := CurrencyCode;
            Currency.Insert();
        end;
        Currency.Description := Description;
        Currency.Modify();
    end;

    local procedure CreateUniqueCurrency(var Currency: Record Currency)
    begin
        CreateCurrency(
            Currency, LibraryUtility.GenerateRandomCode(Currency.FieldNo(Code), Database::Currency),
            'Test Currency');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::CheckManagement, 'OnInsertCheckOnBeforeCheckLedgEntryInsert', '', false, false)]
    local procedure CaptureCheckInsertion(var CheckLedgEntry: Record "Check Ledger Entry")
    begin
        CheckInsertCount += 1;
        AttemptedCheckEntry := CheckLedgEntry;
    end;
}
