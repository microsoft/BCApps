// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Reports;

using Microsoft.Bank.BankAccount;
using Microsoft.Bank.Check;
using Microsoft.Finance.Currency;
using Microsoft.Finance.FinancialReports;
using Microsoft.Finance.GeneralLedger.Journal;
#if not CLEAN30
using Microsoft.Finance.GeneralLedger.Setup;
#endif
using Microsoft.Foundation.Reporting;
using System.Automation;
#if not CLEAN30
using System.Environment;
#endif
using System.Environment.Configuration;
using System.Reflection;
using System.TestLibraries.Security.AccessControl;
using System.TestLibraries.Upgrade;
using System.Upgrade;
using System.Utilities;

codeunit 144044 "UT REP Number To Text"
{
    // [FEATURE] [Language] [UT] [Check]
    // The French amount wording is provided by Reports FR through the Check report event.
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
        ReportLayoutsFR: Codeunit "Library - Reports FR";
        UpgradeTagLibrary: Codeunit "Upgrade Tag Library";
        PermissionsMock: Codeunit "Permissions Mock";
#if not CLEAN30
        FeatureState: Codeunit "Library - Reports FR";
#endif
        UnexpectedAmountTextErr: Label 'Unexpected amount text for %1 in language %2.', Comment = '%1 = amount, %2 = language ID';
        UnexpectedLayoutErr: Label 'Unexpected check layout selection.';
        RestrictionDetailsTxt: Label 'Test-print journal line requires approval.';
        CheckInsertCount: Integer;
#if not CLEAN30
        FormattingAfterEventCount: Integer;
        FormattingAfterEventAmount: Decimal;
#endif

    [Test]
    procedure TestPrintPreservesJournalAssociation()
    var
        BankAccount: Record "Bank Account";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653674] FR test printing associates the entry with its journal without advancing the bank check number.
        Initialize();

        // [GIVEN] Bank account B and payment journal line J with Reports FR installed.
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
        FormatReportAmount(Check, NoText, 21.25, '');
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
        FormatReportAmount(Check, ReportNoText, 21.25, Currency.Code);
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
        // [SCENARIO 653674] The French layout is owned by Reports FR, not Base Application.
        Initialize();

        // [GIVEN] The reports extension is installed.

        // [WHEN] Its CheckFR layout is looked up.
        ReportLayoutList.SetRange("Report ID", Report::Check);
        ReportLayoutList.SetRange(Name, 'CheckFR');
        ReportLayoutList.SetRange("Application ID", ReportsAppId());
        Assert.IsTrue(ReportLayoutList.FindFirst(), 'Reports FR must provide the CheckFR layout.');

        // [THEN] The app-owned layout is RDLC.
        Assert.AreEqual(ReportLayoutList."Layout Format"::RDLC, ReportLayoutList."Layout Format", UnexpectedLayoutErr);
    end;

    [Test]
    procedure FrenchCheckLayoutIsSelectedWithoutExistingSelection()
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653674] A company using the implicit built-in layout gets the extension layout.
        Initialize();

        // [GIVEN] No check layout selection exists.
        ClearLayoutSelections();
        ClearCheckLayoutUpgradeTag();

        // [WHEN] The default layout is selected.
        ReportLayoutsFR.MigrateCompanyData();

        // [THEN] The company uses the extension layout.
        VerifyLayoutSelection(CompanyName(), 'CheckFR', ReportsAppId());
    end;

    [Test]
    procedure LegacyBuiltInCheckLayoutIsMigrated()
    var
        BaseApplicationId: Guid;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653674] An explicit Base Application check layout selection is migrated.
        Initialize();

        // [GIVEN] The company explicitly uses the Base Application layout.
        ClearLayoutSelections();
        ClearCheckLayoutUpgradeTag();
        BaseApplicationId := '437dbf0e-84ff-417a-965d-ed2bb9650972';
        CreateLayoutSelection(CompanyName(), 'RDLCLayout', BaseApplicationId);

        // [WHEN] The default layout is selected.
        ReportLayoutsFR.MigrateCompanyData();

        // [THEN] The company uses the extension layout.
        VerifyLayoutSelection(CompanyName(), 'CheckFR', ReportsAppId());
    end;

    [Test]
    procedure AllCompanyBuiltInCheckLayoutIsMigratedPerCompany()
    var
        BaseApplicationId: Guid;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653674] A global built-in default is migrated only for the current company.
        Initialize();

        // [GIVEN] All companies use the Base Application default.
        ClearLayoutSelections();
        ClearCheckLayoutUpgradeTag();
        BaseApplicationId := '437dbf0e-84ff-417a-965d-ed2bb9650972';
        CreateLayoutSelection('', 'RDLCLayout', BaseApplicationId);

        // [WHEN] The current company's default is selected.
        ReportLayoutsFR.MigrateCompanyData();

        // [THEN] The company migrates without changing the global default.
        VerifyCompanyAndGlobalLayouts(BaseApplicationId);
    end;

    [Test]
    procedure CustomCheckLayoutSelectionIsPreserved()
    var
        EmptyGuid: Guid;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653674] A tenant-defined company layout is not replaced.
        Initialize();

        // [GIVEN] The company uses a tenant-defined layout.
        ClearLayoutSelections();
        ClearCheckLayoutUpgradeTag();
        CreateLayoutSelection(CompanyName(), 'CUSTOM CHECK', EmptyGuid);

        // [WHEN] The default layout is selected.
        ReportLayoutsFR.MigrateCompanyData();

        // [THEN] The tenant-defined selection is unchanged.
        VerifyLayoutSelection(CompanyName(), 'CUSTOM CHECK', EmptyGuid);
    end;

    [Test]
    procedure AllCompanyCustomCheckLayoutSelectionIsPreserved()
    var
        EmptyGuid: Guid;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653674] A custom default applying to all companies is not shadowed.
        Initialize();

        // [GIVEN] A global tenant-defined layout is selected.
        ClearLayoutSelections();
        ClearCheckLayoutUpgradeTag();
        CreateLayoutSelection('', 'CUSTOM CHECK', EmptyGuid);

        // [WHEN] The company default is selected.
        ReportLayoutsFR.MigrateCompanyData();

        // [THEN] The global selection survives without a company-specific override.
        VerifyGlobalCustomLayout(EmptyGuid);
    end;

    [Test]
    procedure OtherExtensionCheckLayoutSelectionIsPreserved()
    var
        OtherAppId: Guid;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653674] A layout selected from another extension is not replaced.
        Initialize();

        // [GIVEN] A third-party extension layout is selected.
        ClearLayoutSelections();
        ClearCheckLayoutUpgradeTag();
        OtherAppId := CreateGuid();
        CreateLayoutSelection(CompanyName(), 'OTHER CHECK', OtherAppId);

        // [WHEN] The default layout is selected.
        ReportLayoutsFR.MigrateCompanyData();

        // [THEN] The third-party selection is unchanged.
        VerifyLayoutSelection(CompanyName(), 'OTHER CHECK', OtherAppId);
    end;

    [Test]
    procedure LegacyCustomCheckLayoutSelectionIsPreserved()
    var
        CustomLayoutCode: Code[20];
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653674] A legacy custom layout remains selected.
        Initialize();

        // [GIVEN] A legacy custom selection references an existing layout for the check report.
        ClearLayoutSelections();
        ClearCheckLayoutUpgradeTag();
        CustomLayoutCode := CreateLegacyCustomLayoutSelection();

        // [WHEN] The default layout is selected.
        ReportLayoutsFR.MigrateCompanyData();

        // [THEN] The legacy selection remains without a tenant override.
        VerifyLegacyCustomLayout(CustomLayoutCode);
    end;

    [Test]
    procedure FrenchCheckLayoutSelectionIsIdempotent()
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653674] Check layout migration records completion and is idempotent.
        Initialize();

        // [GIVEN] A company without selections or the cheque layout upgrade tag.
        ClearLayoutSelections();
        ClearCheckLayoutUpgradeTag();

        // [WHEN] The feature's layout migration runs twice.
        ReportLayoutsFR.MigrateCompanyData();
        ReportLayoutsFR.MigrateCompanyData();

        // [THEN] The layout is selected once and the upgrade tag is persisted.
        VerifyTaggedLayout('CheckFR', ReportsAppId());
    end;

    [Test]
    procedure UserSpecificCheckLayoutSelectionIsPreserved()
    var
        TenantReportLayoutSelection: Record "Tenant Report Layout Selection";
        SelectedUserId: Guid;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653674] Migrating the company default does not change user-specific selections.
        Initialize();

        // [GIVEN] A user-specific selection exists.
        ClearLayoutSelections();
        ClearCheckLayoutUpgradeTag();
        SelectedUserId := CreateGuid();
        TenantReportLayoutSelection.Init();
        TenantReportLayoutSelection."Report ID" := Report::Check;
        TenantReportLayoutSelection."Company Name" :=
            CopyStr(CompanyName(), 1, MaxStrLen(TenantReportLayoutSelection."Company Name"));
        TenantReportLayoutSelection."User ID" := SelectedUserId;
        TenantReportLayoutSelection."Layout Name" := 'USER CHECK';
        TenantReportLayoutSelection.Insert();

        // [WHEN] The company default is selected.
        ReportLayoutsFR.MigrateCompanyData();

        // [THEN] The company migrates but the user's selection is unchanged.
        VerifyUserSpecificLayout(SelectedUserId);
    end;

    [Test]
    procedure AllCompanyUserSpecificCheckLayoutSelectionIsPreserved()
    var
        SelectedUserId: Guid;
        EmptyGuid: Guid;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653674] A companyless user selection does not prevent migration for other users.
        Initialize();

        // [GIVEN] A user-specific selection applies to all companies.
        ClearLayoutSelections();
        ClearCheckLayoutUpgradeTag();
        SelectedUserId := CreateGuid();
        CreateLayoutSelection('', 'USER CHECK', EmptyGuid, SelectedUserId);

        // [WHEN] Check layout migration initializes the current company.
        ReportLayoutsFR.MigrateCompanyData();

        // [THEN] The user choice remains global and the default for other users is migrated and tagged.
        VerifyGlobalUserLayout(SelectedUserId, 'USER CHECK', EmptyGuid);
        VerifyTaggedLayout('CheckFR', ReportsAppId());
    end;

    [Test]
    procedure AllCompanyUserLayoutAllowsCompanyDefaultMigration()
    var
        SelectedUserId: Guid;
        OtherAppId: Guid;
        BaseApplicationId: Guid;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653674] A companyless user choice survives migration of an explicit Base Application default.
        Initialize();

        // [GIVEN] A third-party user layout applies globally and the company has a built-in default.
        ClearLayoutSelections();
        ClearCheckLayoutUpgradeTag();
        SelectedUserId := CreateGuid();
        OtherAppId := CreateGuid();
        BaseApplicationId := '437dbf0e-84ff-417a-965d-ed2bb9650972';
        CreateLayoutSelection('', 'USER CHECK', OtherAppId, SelectedUserId);
        CreateLayoutSelection(CompanyName(), 'RDLCLayout', BaseApplicationId);

        // [WHEN] The company default is initialized.
        ReportLayoutsFR.MigrateCompanyData();

        // [THEN] The company default migrates while the global user choice remains unchanged.
        VerifyLayoutSelection(CompanyName(), 'CheckFR', ReportsAppId());
        VerifyGlobalUserLayout(SelectedUserId, 'USER CHECK', OtherAppId);
    end;

    [Test]
    procedure CompanyAndGlobalUserLayoutsSurviveDefaultMigration()
    var
        GlobalUserId: Guid;
        CompanyUserId: Guid;
        EmptyGuid: Guid;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653674] Existing global and company-specific user choices survive company default migration.
        Initialize();

        // [GIVEN] User "U1" has a global choice and user "U2" has a company-specific choice.
        ClearLayoutSelections();
        ClearCheckLayoutUpgradeTag();
        GlobalUserId := CreateGuid();
        CompanyUserId := CreateGuid();
        CreateLayoutSelection('', 'GLOBAL USER CHECK', EmptyGuid, GlobalUserId);
        CreateLayoutSelection(CompanyName(), 'COMPANY USER CHECK', EmptyGuid, CompanyUserId);

        // [WHEN] The company default is initialized.
        ReportLayoutsFR.MigrateCompanyData();

        // [THEN] Both choices survive and users without a choice receive the French default.
        VerifyGlobalUserLayout(GlobalUserId, 'GLOBAL USER CHECK', EmptyGuid);
        VerifyLayoutSelection(CompanyName(), 'COMPANY USER CHECK', EmptyGuid, CompanyUserId);
        VerifyLayoutSelection(CompanyName(), 'CheckFR', ReportsAppId());
    end;

    [Test]
    procedure RepeatedMigrationPreservesLaterGlobalUserChoice()
    var
        TenantReportLayoutSelection: Record "Tenant Report Layout Selection";
        SelectedUserId: Guid;
        EmptyGuid: Guid;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653674] Repeated migration preserves a later global user choice and the migrated default.
        Initialize();

        // [GIVEN] Migration has completed alongside a global user choice.
        ClearLayoutSelections();
        ClearCheckLayoutUpgradeTag();
        SelectedUserId := CreateGuid();
        CreateLayoutSelection('', 'USER CHECK', EmptyGuid, SelectedUserId);
        ReportLayoutsFR.MigrateCompanyData();

        // [GIVEN] The user changes their global choice after migration.
        TenantReportLayoutSelection.Get(Report::Check, '', SelectedUserId);
        TenantReportLayoutSelection."Layout Name" := 'LATER USER CHECK';
        TenantReportLayoutSelection.Modify();

        // [WHEN] Migration runs again.
        ReportLayoutsFR.MigrateCompanyData();

        // [THEN] The later choice remains global and the French company default remains selected.
        VerifyGlobalUserLayout(SelectedUserId, 'LATER USER CHECK', EmptyGuid);
        VerifyTaggedLayout('CheckFR', ReportsAppId());
    end;

    [Test]
    procedure GlobalUserLayoutDoesNotHideMissingCompanyLayout()
    var
        SelectedUserId: Guid;
        EmptyGuid: Guid;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653674] A global user choice cannot mark an unavailable company default as migrated.
        Initialize();

        // [GIVEN] A global user choice exists but the company has not migrated.
        ClearLayoutSelections();
        ClearCheckLayoutUpgradeTag();
        SelectedUserId := CreateGuid();
        CreateLayoutSelection('', 'USER CHECK', EmptyGuid, SelectedUserId);
        Commit();

        // [WHEN] Migration cannot find its owning app's layout.
        asserterror ReportLayoutsFR.InitializeCheckLayout(CreateGuid());

        // [THEN] Migration fails without a completion tag or changes to the user choice.
        Assert.ExpectedError('The CheckFR layout from Reports FR is not available.');
        Assert.ExpectedErrorCode('Dialog');
        VerifyUncompletedLayoutMigration();
        VerifyGlobalUserLayout(SelectedUserId, 'USER CHECK', EmptyGuid);

        // [WHEN] The correct package is available on retry.
        ReportLayoutsFR.MigrateCompanyData();

        // [THEN] Other users receive the French default while the global user choice survives.
        VerifyTaggedLayout('CheckFR', ReportsAppId());
        VerifyGlobalUserLayout(SelectedUserId, 'USER CHECK', EmptyGuid);
    end;

    [Test]
    procedure OtherCompanyUserLayoutDoesNotPreventCheckMigration()
    var
        TenantReportLayoutSelection: Record "Tenant Report Layout Selection";
        SelectedCompany: Text[30];
        SelectedUserId: Guid;
        EmptyGuid: Guid;
    begin
        // [SCENARIO 653674] A user selection scoped to another company does not block this company's migration.
        Initialize();

        // [GIVEN] A user layout is selected only in another company.
        ClearLayoutSelections();
        ClearCheckLayoutUpgradeTag();
        SelectedCompany := CopyStr(CreateGuid(), 1, MaxStrLen(SelectedCompany));
        SelectedUserId := CreateGuid();
        CreateLayoutSelection(SelectedCompany, 'USER CHECK', EmptyGuid, SelectedUserId);

        // [WHEN] The current company's default is initialized.
        ReportLayoutsFR.MigrateCompanyData();

        // [THEN] The current company migrates and the other company's user choice remains untouched.
        VerifyLayoutSelection(CompanyName(), 'CheckFR', ReportsAppId());
        TenantReportLayoutSelection.Get(Report::Check, SelectedCompany, SelectedUserId);
        Assert.AreEqual('USER CHECK', TenantReportLayoutSelection."Layout Name", UnexpectedLayoutErr);
        Assert.AreEqual(EmptyGuid, TenantReportLayoutSelection."App ID", UnexpectedLayoutErr);
    end;

    [Test]
    procedure CompletedLayoutMigrationDoesNotOverrideLaterSelection()
    var
        BaseApplicationId: Guid;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653674] Repeated migration preserves a built-in choice made after feature activation.
        Initialize();

        // [GIVEN] Layout migration has completed and tagged the company.
        ClearLayoutSelections();
        ClearCheckLayoutUpgradeTag();
        ReportLayoutsFR.MigrateCompanyData();

        // [GIVEN] The user subsequently selects the Base Application layout explicitly.
        BaseApplicationId := '437dbf0e-84ff-417a-965d-ed2bb9650972';
        ChangeCompanyLayoutSelection('RDLCLayout', BaseApplicationId);

        // [WHEN] The same tagged migration is invoked again.
        ReportLayoutsFR.MigrateCompanyData();

        // [THEN] The explicit built-in choice and original tag survive.
        VerifyTaggedLayout('RDLCLayout', BaseApplicationId);
    end;

    [Test]
    procedure CheckLayoutSetupWithOnlyReportsFRPermissions()
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653674] Layout initialization does not depend on SUPER or unrestricted table writes.
        Initialize();

        // [GIVEN] No Check layout or completion tag and only the Reports FR permission set.
        ClearLayoutSelections();
        ClearCheckLayoutUpgradeTag();
        PermissionsMock.Start();
        PermissionsMock.SetExactPermissionSet('Reports FR');

        // [WHEN] The Check migration executes with reduced permissions.
        ReportLayoutsFR.InitializeCheckLayout();
        PermissionsMock.Stop();

        // [THEN] Layout lookup, selection writes, and completion tagging succeed.
        VerifyTaggedLayout('CheckFR', ReportsAppId());
    end;

    [Test]
    procedure FrenchCheckLayoutRendersPdf()
    var
        BankAccount: Record "Bank Account";
        GenJournalLine: Record "Gen. Journal Line";
        PdfSignature: Text;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653674] The installed Reports FR layout renders through standard report 1401.
        Initialize();

        // [GIVEN] A test-print journal line and the extension's selected RDLC layout.
        CreateTestPrintJournalLine(BankAccount, GenJournalLine);
        ClearLayoutSelections();
        ClearCheckLayoutUpgradeTag();
        ReportLayoutsFR.MigrateCompanyData();
        Commit();

        // [WHEN] Standard Check renders a PDF rather than merely exporting its dataset.
        PdfSignature := RenderTestPrintPdf(BankAccount, GenJournalLine);

        // [THEN] The renderer returns a PDF document.
        Assert.AreEqual('%PDF-', PdfSignature, 'CheckFR must produce an actual PDF.');
        VerifyLastCheckNo(BankAccount);
    end;

    [Test]
    procedure AlreadyHandledWordingIsPreserved()
    var
        CheckAmountWordingFR: Codeunit "Library - Reports FR";
        NoText: array[2] of Text[80];
        IsHandled: Boolean;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653674] An earlier handler owns both lines even when Reports FR is installed.
        Initialize();

        // [GIVEN] Another extension has already formatted the amount.
        NoText[1] := 'OTHER EXTENSION';
        NoText[2] := 'SECOND LINE';
        IsHandled := true;

        // [WHEN] The Reports FR subscriber receives the handled event.
        CheckAmountWordingFR.OnBeforeFormatNoText(NoText, 21, '', IsHandled);

        // [THEN] The earlier handler's text survives.
        VerifyAmountLines(NoText, 'OTHER EXTENSION', 'SECOND LINE');
        Assert.IsTrue(IsHandled, 'Reports FR must not reset an earlier handler.');
    end;

    [Test]
    procedure MissingLayoutFailsWithoutCompletionAndCanRetry()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653674] Missing package metadata cannot be recorded as a successful migration.
        Initialize();

        // [GIVEN] The company uses an implicit default and has not completed setup.
        ClearLayoutSelections();
        ClearCheckLayoutUpgradeTag();

        // [WHEN] Migration cannot find its owning app's layout.
        asserterror ReportLayoutsFR.InitializeCheckLayout(CreateGuid());

        // [THEN] It raises an actionable error, without a tag or selection.
        Assert.ExpectedError('The CheckFR layout from Reports FR is not available.');
        Assert.ExpectedErrorCode('Dialog');
        Assert.IsFalse(UpgradeTag.HasUpgradeTag(ReportLayoutsFR.GetCheckLayoutUpgradeTag()), 'Failed migration must not be tagged.');
        VerifyNoCompanyLayoutSelection();

        // [WHEN] The correct package is available on retry.
        ReportLayoutsFR.MigrateCompanyData();

        // [THEN] The same migration completes successfully.
        VerifyTaggedLayout('CheckFR', ReportsAppId());
    end;

    [Test]
    procedure NewCompanyInitializationDoesNotTrustSeededTag()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653674] A tag seeded before company setup does not suppress layout initialization.
        Initialize();

        // [GIVEN] A fresh company state with a historical completion tag.
        ClearLayoutSelections();
        ClearCheckLayoutUpgradeTag();
        UpgradeTag.SetUpgradeTag(ReportLayoutsFR.GetCheckLayoutUpgradeTag());

        // [WHEN] The initialization operation used for a pending new company runs.
        ReportLayoutsFR.InitializeCheckLayout();

        // [THEN] The actual default is initialized, not just the tag.
        VerifyTaggedLayout('CheckFR', ReportsAppId());
    end;

    [Test]
    procedure CompletionTagIsNotAutomaticallySeeded()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        PerCompanyUpgradeTags: List of [Code[250]];
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653674] Company creation cannot seed the Check migration completion contract.
        Initialize();

        // [GIVEN] All registered per-company upgrade tags.
        UpgradeTag.GetPerCompanyUpgradeTags(PerCompanyUpgradeTags);

        // [WHEN] The list used by SetAllUpgradeTags is inspected.
        // [THEN] Check completion is registered only by successful migration.
        Assert.IsFalse(PerCompanyUpgradeTags.Contains(ReportLayoutsFR.GetCheckLayoutUpgradeTag()), 'Check completion must never be pre-seeded.');
    end;

    [Test]
    procedure GlobalLegacyCustomLayoutIsPreserved()
    var
        ReportLayoutSelection: Record "Report Layout Selection";
        CustomLayoutCode: Code[20];
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653674] An inherited legacy custom selection is not shadowed by a company default.
        Initialize();

        // [GIVEN] A legacy layout is selected for all companies.
        ClearLayoutSelections();
        ClearCheckLayoutUpgradeTag();
        CustomLayoutCode := CreateLegacyCustomLayoutSelection();
        ReportLayoutSelection.Get(Report::Check, CompanyName());
        ReportLayoutSelection.Rename(Report::Check, '');

        // [WHEN] The current company activates Check.
        ReportLayoutsFR.MigrateCompanyData();

        // [THEN] The global legacy selection remains authoritative.
        ReportLayoutSelection.Get(Report::Check, '');
        Assert.AreEqual(CustomLayoutCode, ReportLayoutSelection."Custom Report Layout Code", UnexpectedLayoutErr);
        VerifyNoCompanyLayoutSelection();
    end;

#if not CLEAN30
#pragma warning disable AL0432
    [Test]
    procedure DisabledCompanyStatusAdoptsDataUpdateRequirement()
    begin
        // [SCENARIO 653674] A company initialized under old metadata must not skip a later feature data update.
        Initialize();
        VerifyCompanyStatusAdoptsDataUpdateRequirement("Feature Status"::Disabled);
    end;

    [Test]
    procedure PendingCompanyStatusAdoptsDataUpdateRequirement()
    begin
        // [SCENARIO 653674] Metadata reconciliation does not mark a pending company complete.
        Initialize();
        VerifyCompanyStatusAdoptsDataUpdateRequirement("Feature Status"::Pending);
    end;

    [Test]
    procedure CompletedCompanyStatusRetainsCompletion()
    begin
        // [SCENARIO 653674] Refreshing cached metadata does not reset a completed company.
        Initialize();
        VerifyCompanyStatusAdoptsDataUpdateRequirement("Feature Status"::Complete);
    end;

    [Test]
    procedure DisabledFeatureUsesLegacyCheckWording()
    begin
        // [SCENARIO 653674] A disabled company retains legacy hundredths even with three-decimal LCY precision.
        Initialize();
        VerifyReportFeatureRouting("Feature Status"::Disabled, false, '**** TWENTY ONE AND 25/100', 21.25);
    end;

    [Test]
    procedure PendingFeatureUsesLegacyCheckWording()
    begin
        // [SCENARIO 653674] Pending activation leaves both BaseApp and the extension on the legacy path.
        Initialize();
        VerifyReportFeatureRouting("Feature Status"::Pending, false, '**** TWENTY ONE AND 25/100', 21.25);
    end;

    [Test]
    procedure CompletedFeatureUsesExtensionCheckWording()
    begin
        // [SCENARIO 653674] Completed activation uses the extension's fixed hundredths and raises the after-event once.
        Initialize();
        VerifyReportFeatureRouting("Feature Status"::Complete, false, '**** TWENTY ONE AND 25/100', 21.25);
    end;

    [Test]
    procedure EnabledUnhandledCheckUsesStandardWording()
    begin
        // [SCENARIO 653674] Enabled BaseApp cannot fall back to legacy wording when the extension leaves formatting unhandled.
        Initialize();
        VerifyReportFeatureRouting("Feature Status"::Enabled, true, '**** TWENTY ONE AND 250/1000', 0.25);
    end;

    [Test]
    procedure CompletedUnhandledCheckUsesStandardWording()
    begin
        // [SCENARIO 653674] Completed BaseApp uses W1 precision and the fractional after-event amount when unhandled.
        Initialize();
        VerifyReportFeatureRouting("Feature Status"::Complete, true, '**** TWENTY ONE AND 250/1000', 0.25);
    end;

    [Test]
    procedure DisabledSubscriberDoesNotHandleWording()
    var
        CheckAmountWordingFR: Codeunit "Library - Reports FR";
        FeatureSubscriber: Codeunit "UT REP Number To Text";
        NoText: array[2] of Text[80];
        IsHandled: Boolean;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653674] Disabled Reports FR leaves the legacy report path untouched.
        Initialize();

        // [GIVEN] Reports FR is disabled for the automatic subscriber.
        FeatureSubscriber.SetFeatureEnabled(false);
        BindSubscription(FeatureSubscriber);
        NoText[1] := 'LEGACY INPUT';

        // [WHEN] The event is raised before legacy formatting.
        CheckAmountWordingFR.OnBeforeFormatNoText(NoText, 21, '', IsHandled);
        UnbindSubscription(FeatureSubscriber);

        // [THEN] Legacy formatting remains responsible for the result.
        Assert.IsFalse(IsHandled, 'Disabled Reports FR must not handle the event.');
        VerifyAmountLines(NoText, 'LEGACY INPUT', '');
    end;

    [Test]
    procedure ForcedAPIsWorkWhileFeatureIsDisabled()
    var
        FeatureSubscriber: Codeunit "UT REP Number To Text";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653674] Explicit calls are independent of automatic feature routing.
        Initialize();

        // [GIVEN] Automatic Reports FR formatting is disabled.
        FeatureSubscriber.SetFeatureEnabled(false);
        BindSubscription(FeatureSubscriber);

        // [WHEN] A caller explicitly requests French wording without initialization.
        VerifyFrenchAmountText(21, '**** TWENTY AND ONE EUROS');
        UnbindSubscription(FeatureSubscriber);

        // [THEN] The forced API produced its normal result.
    end;

    [Test]
    procedure DisabledCompanyInitializationDoesNotMigrate()
    var
        FeatureKey: Record "Feature Key";
        UpgradeTag: Codeunit "Upgrade Tag";
        OriginalEnabled: Option;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653674] Installation and new-company setup do not select a layout while the feature is disabled.
        Initialize();

        // [GIVEN] The platform feature is disabled; its metadata is not modified.
        ClearLayoutSelections();
        ClearCheckLayoutUpgradeTag();
        FeatureKey.Get('FRReports');
        OriginalEnabled := FeatureKey.Enabled;
        FeatureKey.Enabled := FeatureKey.Enabled::None;
        FeatureKey.Modify();

        // [WHEN] The shared initialization used by install and company creation runs.
        ReportLayoutsFR.InitializeCompany();
        FeatureKey.Enabled := OriginalEnabled;
        FeatureKey.Modify();

        // [THEN] Initialization writes neither a selection nor a completion tag.
        VerifyNoCompanyLayoutSelection();
        Assert.IsFalse(UpgradeTag.HasUpgradeTag(ReportLayoutsFR.GetCheckLayoutUpgradeTag()), 'Disabled setup must not complete migration.');
    end;

    [Test]
    procedure ImplicitDefaultRequiresFeatureDataUpdate()
    var
        FeatureReportsFR: Codeunit "Library - Reports FR";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653674] No explicit record is still work for feature activation.
        Initialize();

        // [GIVEN] An implicit Base Application default and no completion tag.
        ClearLayoutSelections();
        ClearCheckLayoutUpgradeTag();

        // [WHEN] The framework asks whether a migration is required.
        // [THEN] It cannot skip initialization simply because no selection row exists.
        Assert.IsTrue(FeatureReportsFR.IsDataUpdateRequired(), 'Implicit defaults require the feature update.');
    end;

    [Test]
    procedure FeatureUpdateRejectsAnotherCompany()
    var
        TempFeatureDataUpdateStatus: Record "Feature Data Update Status" temporary;
        FeatureReportsFR: Codeunit "Library - Reports FR";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653674] An update cannot accidentally complete another company's migration.
        Initialize();

        // [GIVEN] A status parameter that does not belong to the current company.
        TempFeatureDataUpdateStatus."Feature Key" := 'FRReports';
        TempFeatureDataUpdateStatus."Company Name" := CopyStr(CreateGuid(), 1, 30);

        // [WHEN] It is passed to the company-specific migration.
        asserterror FeatureReportsFR.UpdateData(TempFeatureDataUpdateStatus);

        // [THEN] Validation rejects the foreign company before any migration.
        Assert.ExpectedError('Company Name');
        Assert.ExpectedErrorCode('TestField');
    end;

    [Test]
    procedure FeatureFrameworkResolvesReportsFR()
    var
        TempFeatureDataUpdateStatus: Record "Feature Data Update Status" temporary;
        FeatureManagementFacade: Codeunit "Feature Management Facade";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653674] The real framework resolves the FRReports enum registration.
        Initialize();

        // [GIVEN] The exact platform feature token.
        TempFeatureDataUpdateStatus."Feature Key" := 'FRReports';

        // [WHEN] The framework resolves its implementation.
        // [THEN] The enum name and implementation are wired correctly.
        Assert.IsTrue(FeatureManagementFacade.GetImplementation(TempFeatureDataUpdateStatus), 'FRReports must resolve through Feature To Update.');
    end;

    [Test]
    procedure PlatformMetadataMeetsActivationContract()
    var
        FeatureKey: Record "Feature Key";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653674] Release verification requires actual platform one-way and data-update metadata.
        Initialize();

        // [GIVEN] Platform-owned metadata, not a mocked feature-enabled event.
        FeatureKey.Get('FRReports');

        // [WHEN] The real activation prerequisites are examined.
        // [THEN] Both platform flags must be set before this feature can ship.
        Assert.IsTrue(FeatureKey."Is One Way", 'RELEASE BLOCKER: FRReports must be registered as one-way.');
        Assert.IsTrue(FeatureKey."Data Update Required", 'RELEASE BLOCKER: FRReports must require a per-company data update.');
    end;

    [Test]
    procedure PendingActivationCompletesOnlyCurrentCompany()
    var
        FeatureDataUpdateStatus: Record "Feature Data Update Status";
        OtherFeatureDataUpdateStatus: Record "Feature Data Update Status";
        FeatureKey: Record "Feature Key";
        FeatureManagementFacade: Codeunit "Feature Management Facade";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653674] Real feature activation migrates the current company before framework completion.
        Initialize();

        // [GIVEN] Compatible platform metadata and a pending current-company status.
        FeatureKey.Get('FRReports');
        ReportLayoutsFR.VerifyFeatureMetadata(FeatureKey);
        ClearLayoutSelections();
        ClearCheckLayoutUpgradeTag();
        FeatureManagementFacade.GetFeatureDataUpdateStatus(FeatureKey, FeatureDataUpdateStatus);
        FeatureDataUpdateStatus."Feature Status" := "Feature Status"::Pending;
        FeatureDataUpdateStatus.Modify();
        FindOtherCompanyFeatureStatus(OtherFeatureDataUpdateStatus);

        // [WHEN] The actual framework runs the registered implementation.
        FeatureManagementFacade.UpdateData(FeatureDataUpdateStatus);

        // [THEN] Only the current company completes, with a successfully migrated layout.
        VerifyTaggedLayout('CheckFR', ReportsAppId());
        FeatureDataUpdateStatus.Get('FRReports', CompanyName());
        Assert.AreEqual("Feature Status"::Complete, FeatureDataUpdateStatus."Feature Status", 'The current company must complete.');
        VerifyOtherCompanyFeatureStatus(OtherFeatureDataUpdateStatus);
    end;

    [Test]
    procedure PendingCompanyLifecycleIgnoresSeededTag()
    var
        FeatureDataUpdateStatus: Record "Feature Data Update Status";
        FeatureKey: Record "Feature Key";
        FeatureManagementFacade: Codeunit "Feature Management Facade";
        UpgradeTag: Codeunit "Upgrade Tag";
        OriginalEnabled: Option;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653674] New-company lifecycle completes actual setup despite a seeded tag.
        Initialize();

        // [GIVEN] A configured feature and a pending company with a historical tag.
        FeatureKey.Get('FRReports');
        ReportLayoutsFR.VerifyFeatureMetadata(FeatureKey);
        OriginalEnabled := FeatureKey.Enabled;
        FeatureKey.Enabled := FeatureKey.Enabled::"All Users";
        FeatureKey.Modify();
        ClearLayoutSelections();
        ClearCheckLayoutUpgradeTag();
        UpgradeTag.SetUpgradeTag(ReportLayoutsFR.GetCheckLayoutUpgradeTag());
        FeatureManagementFacade.GetFeatureDataUpdateStatus(FeatureKey, FeatureDataUpdateStatus);
        FeatureDataUpdateStatus."Feature Status" := "Feature Status"::Pending;
        FeatureDataUpdateStatus.Modify();

        // [WHEN] The new-company lifecycle path runs.
        ReportLayoutsFR.InitializeCompany();
        FeatureKey.Enabled := OriginalEnabled;
        FeatureKey.Modify();

        // [THEN] Actual layout initialization precedes company completion.
        VerifyTaggedLayout('CheckFR', ReportsAppId());
        FeatureDataUpdateStatus.Get('FRReports', CompanyName());
        Assert.AreEqual("Feature Status"::Complete, FeatureDataUpdateStatus."Feature Status", 'The initialized company must complete.');
    end;
#pragma warning restore AL0432
#else
    [Test]
    procedure MandatoryFirstInstallIgnoresSeededTag()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        // [SCENARIO 653674] First installation initializes the layout even if a completion tag was seeded.
        Initialize();
        ClearLayoutSelections();
        ClearCheckLayoutUpgradeTag();
        UpgradeTag.SetUpgradeTag(ReportLayoutsFR.GetCheckLayoutUpgradeTag());

        ReportLayoutsFR.InitializeCompany();

        VerifyTaggedLayout('CheckFR', ReportsAppId());
    end;

    [Test]
    procedure MandatoryInitializationPreservesGlobalUserLayout()
    var
        SelectedUserId: Guid;
        EmptyGuid: Guid;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 653674] Mandatory company initialization selects CheckFR without changing a global user choice.
        Initialize();

        // [GIVEN] A global user choice exists before company initialization.
        ClearLayoutSelections();
        ClearCheckLayoutUpgradeTag();
        SelectedUserId := CreateGuid();
        CreateLayoutSelection('', 'USER CHECK', EmptyGuid, SelectedUserId);

        // [WHEN] Company initialization runs without the retired feature gate.
        ReportLayoutsFR.InitializeCompany();

        // [THEN] The company default is migrated and tagged while the user choice remains global.
        VerifyTaggedLayout('CheckFR', ReportsAppId());
        VerifyGlobalUserLayout(SelectedUserId, 'USER CHECK', EmptyGuid);
    end;

#endif

    local procedure Initialize()
    begin
        PermissionsMock.Stop();
        LibraryTestInitialize.OnTestInitialize(Codeunit::"UT REP Number To Text");
        ClearLastError();
    end;

    local procedure VerifyNoCompanyLayoutSelection()
    var
        ReportLayoutSelection: Record "Report Layout Selection";
        TenantReportLayoutSelection: Record "Tenant Report Layout Selection";
        EmptyGuid: Guid;
    begin
        Assert.IsFalse(ReportLayoutSelection.Get(Report::Check, CompanyName()), 'No legacy company override is expected.');
        Assert.IsFalse(TenantReportLayoutSelection.Get(Report::Check, CompanyName(), EmptyGuid), 'No tenant company override is expected.');
    end;

#if not CLEAN30
    local procedure VerifyCompanyStatusAdoptsDataUpdateRequirement(FeatureStatus: Enum "Feature Status")
    var
        TempFeatureKey: Record "Feature Key" temporary;
        FeatureDataUpdateStatus: Record "Feature Data Update Status";
        OriginalFeatureDataUpdateStatus: Record "Feature Data Update Status";
        UpdatedFeatureDataUpdateStatus: Record "Feature Data Update Status";
        UpgradeTag: Codeunit "Upgrade Tag";
        StatusExisted: Boolean;
    begin
        ClearLayoutSelections();
        ClearCheckLayoutUpgradeTag();
        StatusExisted := OriginalFeatureDataUpdateStatus.Get('FRReports', CompanyName());
        if StatusExisted then
            FeatureDataUpdateStatus := OriginalFeatureDataUpdateStatus
        else begin
            FeatureDataUpdateStatus.Init();
            FeatureDataUpdateStatus."Feature Key" := 'FRReports';
            FeatureDataUpdateStatus."Company Name" := CopyStr(CompanyName(), 1, MaxStrLen(FeatureDataUpdateStatus."Company Name"));
        end;
        FeatureDataUpdateStatus."Data Update Required" := false;
        FeatureDataUpdateStatus."Feature Status" := FeatureStatus;
        FeatureDataUpdateStatus."Background Task" := false;
        if StatusExisted then
            FeatureDataUpdateStatus.Modify()
        else
            FeatureDataUpdateStatus.Insert();

        // Model the new registration without modifying the platform-owned feature metadata.
        TempFeatureKey.ID := 'FRReports';
        TempFeatureKey."Data Update Required" := true;
        ReportLayoutsFR.PrepareCompanyFeatureStatus(TempFeatureKey, FeatureDataUpdateStatus);
        FeatureDataUpdateStatus.Get('FRReports', CompanyName());
        UpdatedFeatureDataUpdateStatus := FeatureDataUpdateStatus;
        if StatusExisted then begin
            FeatureDataUpdateStatus := OriginalFeatureDataUpdateStatus;
            FeatureDataUpdateStatus.Modify();
        end else
            FeatureDataUpdateStatus.Delete();

        Assert.IsTrue(UpdatedFeatureDataUpdateStatus."Data Update Required", 'Cached company metadata must require the feature update.');
        Assert.AreEqual(FeatureStatus, UpdatedFeatureDataUpdateStatus."Feature Status", 'Metadata refresh must not change activation status.');
        Assert.IsFalse(UpgradeTag.HasUpgradeTag(ReportLayoutsFR.GetCheckLayoutUpgradeTag()), 'Metadata refresh must not complete Check migration.');
        VerifyNoCompanyLayoutSelection();
    end;

    local procedure FindOtherCompanyFeatureStatus(var FeatureDataUpdateStatus: Record "Feature Data Update Status")
    var
        OtherCompany: Record Company;
    begin
        OtherCompany.SetFilter(Name, '<>%1', CompanyName());
        if not OtherCompany.FindFirst() then
            Error('The multi-company activation test requires a second company.');
        if not FeatureDataUpdateStatus.Get('FRReports', OtherCompany.Name) then begin
            FeatureDataUpdateStatus.Init();
            FeatureDataUpdateStatus."Feature Key" := 'FRReports';
            FeatureDataUpdateStatus."Company Name" := OtherCompany.Name;
            FeatureDataUpdateStatus."Data Update Required" := true;
            FeatureDataUpdateStatus."Feature Status" := "Feature Status"::Pending;
            FeatureDataUpdateStatus.Insert();
        end;
    end;

    local procedure VerifyOtherCompanyFeatureStatus(OriginalStatus: Record "Feature Data Update Status")
    var
        FeatureDataUpdateStatus: Record "Feature Data Update Status";
    begin
        FeatureDataUpdateStatus.Get(OriginalStatus."Feature Key", OriginalStatus."Company Name");
        Assert.AreEqual(OriginalStatus."Feature Status", FeatureDataUpdateStatus."Feature Status", 'Another company must not complete.');
    end;
#endif

    local procedure RenderTestPrintPdf(BankAccount: Record "Bank Account"; GenJournalLine: Record "Gen. Journal Line"): Text
    var
        Check: Report Check;
        TempBlob: Codeunit "Temp Blob";
        JournalRecordRef: RecordRef;
        OutputStream: OutStream;
        InputStream: InStream;
        Signature: Text;
    begin
        JournalRecordRef.GetTable(GenJournalLine);
        Check.InitializeRequest(BankAccount."No.", BankAccount."Last Check No.", false, false, true, false);
        TempBlob.CreateOutStream(OutputStream);
        Check.SaveAs('', ReportFormat::Pdf, OutputStream, JournalRecordRef);
        TempBlob.CreateInStream(InputStream);
        InputStream.ReadText(Signature, 5);
        exit(Signature);
    end;

    local procedure FormatReportAmount(var Check: Report Check; var NoText: array[2] of Text[80]; Amount: Decimal; CurrencyCode: Code[10])
#if not CLEAN30
    var
        FeatureSubscriber: Codeunit "UT REP Number To Text";
#endif
    begin
#if not CLEAN30
        FeatureSubscriber.SetFeatureEnabled(true);
        BindSubscription(FeatureSubscriber);
#endif
        Check.FormatNoText(NoText, Amount, CurrencyCode);
#if not CLEAN30
        UnbindSubscription(FeatureSubscriber);
#endif
    end;

#if not CLEAN30
    local procedure VerifyReportFeatureRouting(FeatureStatus: Enum "Feature Status"; SuppressFormatter: Boolean; ExpectedText: Text; ExpectedAfterEventAmount: Decimal)
    var
        FeatureKey: Record "Feature Key";
        FeatureDataUpdateStatus: Record "Feature Data Update Status";
        OriginalFeatureDataUpdateStatus: Record "Feature Data Update Status";
        GeneralLedgerSetup: Record "General Ledger Setup";
        FeatureSubscriber: Codeunit "UT REP Number To Text";
        NoText: array[2] of Text[80];
        OriginalPrecision: Decimal;
        OriginalLanguageId: Integer;
        StatusExisted: Boolean;
        ExtensionHandled: Boolean;
        FormattingSucceeded: Boolean;
        FormattingError: Text;
    begin
        FeatureKey.Get('FRReports');
        StatusExisted := OriginalFeatureDataUpdateStatus.Get(FeatureKey.ID, CompanyName());
        if StatusExisted then
            FeatureDataUpdateStatus := OriginalFeatureDataUpdateStatus
        else begin
            FeatureDataUpdateStatus.Init();
            FeatureDataUpdateStatus."Feature Key" := FeatureKey.ID;
            FeatureDataUpdateStatus."Company Name" := CopyStr(CompanyName(), 1, MaxStrLen(FeatureDataUpdateStatus."Company Name"));
        end;
        FeatureDataUpdateStatus."Feature Status" := FeatureStatus;
        if StatusExisted then
            FeatureDataUpdateStatus.Modify()
        else
            FeatureDataUpdateStatus.Insert();

        GeneralLedgerSetup.Get();
        OriginalPrecision := GeneralLedgerSetup."Amount Rounding Precision";
        GeneralLedgerSetup."Amount Rounding Precision" := 0.001;
        GeneralLedgerSetup.Modify();
        OriginalLanguageId := GlobalLanguage();
        GlobalLanguage(1033);
        FeatureSubscriber.ObserveFeatureRouting(not SuppressFormatter);
        BindSubscription(FeatureSubscriber);

        FormattingSucceeded := TryFormatFeatureRoutingAmount(NoText, ExtensionHandled);
        FormattingError := GetLastErrorText();

        UnbindSubscription(FeatureSubscriber);
        GlobalLanguage(OriginalLanguageId);
        GeneralLedgerSetup."Amount Rounding Precision" := OriginalPrecision;
        GeneralLedgerSetup.Modify();
        if StatusExisted then begin
            FeatureDataUpdateStatus := OriginalFeatureDataUpdateStatus;
            FeatureDataUpdateStatus.Modify();
        end else
            FeatureDataUpdateStatus.Delete();

        if not FormattingSucceeded then
            Error(FormattingError);
        Assert.AreEqual(
            (FeatureStatus in ["Feature Status"::Enabled, "Feature Status"::Complete]) and not SuppressFormatter,
            ExtensionHandled, 'The extension must use the same effective company feature status as BaseApp.');
        VerifyAmountLines(NoText, ExpectedText, '');
        Assert.AreEqual(1, FeatureSubscriber.GetFormattingAfterEventCount(), 'Formatting must raise the after-event exactly once.');
        Assert.AreEqual(ExpectedAfterEventAmount, FeatureSubscriber.GetFormattingAfterEventAmount(), 'Formatting must preserve the after-event amount contract.');
    end;

    [TryFunction]
    local procedure TryFormatFeatureRoutingAmount(var NoText: array[2] of Text[80]; var ExtensionHandled: Boolean)
    var
        Check: Report Check;
        CheckAmountWordingFR: Codeunit "Library - Reports FR";
    begin
        CheckAmountWordingFR.OnBeforeFormatNoText(NoText, 21.25, '', ExtensionHandled);
        Clear(NoText);
        Check.InitTextVariable();
        Check.FormatNoText(NoText, 21.25, '');
    end;

    procedure ObserveFeatureRouting(ActualFeatureStatus: Boolean)
    begin
        Clear(FeatureState);
        if not ActualFeatureStatus then begin
            FeatureState.SetFeatureEnabled(false);
            BindSubscription(FeatureState);
        end;
        FormattingAfterEventCount := 0;
        FormattingAfterEventAmount := 0;
    end;

    procedure GetFormattingAfterEventCount(): Integer
    begin
        exit(FormattingAfterEventCount);
    end;

    procedure GetFormattingAfterEventAmount(): Decimal
    begin
        exit(FormattingAfterEventAmount);
    end;

    procedure SetFeatureEnabled(Enabled: Boolean)
    begin
        Clear(FeatureState);
        FeatureState.SetFeatureEnabled(Enabled);
        BindSubscription(FeatureState);
    end;
#endif

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
        OutputStream: OutStream;
    begin
        Check.InitializeRequest(BankAccount."No.", BankAccount."Last Check No.", false, false, true, false);
        Check.SetTableView(GenJournalLine);
        TempBlob.CreateOutStream(OutputStream);
        Check.SaveAs('', ReportFormat::Xml, OutputStream);
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
        EmptyGuid: Guid;
    begin
        CreateLayoutSelection(SelectedCompany, LayoutName, AppId, EmptyGuid);
    end;

    local procedure CreateLayoutSelection(SelectedCompany: Text; LayoutName: Text[250]; AppId: Guid; SelectedUserId: Guid)
    var
        TenantReportLayoutSelection: Record "Tenant Report Layout Selection";
    begin
        TenantReportLayoutSelection.Init();
        TenantReportLayoutSelection."Report ID" := Report::Check;
        TenantReportLayoutSelection."Company Name" :=
            CopyStr(SelectedCompany, 1, MaxStrLen(TenantReportLayoutSelection."Company Name"));
        TenantReportLayoutSelection."User ID" := SelectedUserId;
        TenantReportLayoutSelection."Layout Name" := LayoutName;
        TenantReportLayoutSelection."App ID" := AppId;
        TenantReportLayoutSelection.Insert();
    end;

    local procedure VerifyLayoutSelection(SelectedCompany: Text; LayoutName: Text[250]; AppId: Guid)
    var
        EmptyGuid: Guid;
    begin
        VerifyLayoutSelection(SelectedCompany, LayoutName, AppId, EmptyGuid);
    end;

    local procedure VerifyLayoutSelection(SelectedCompany: Text; LayoutName: Text[250]; AppId: Guid; SelectedUserId: Guid)
    var
        TenantReportLayoutSelection: Record "Tenant Report Layout Selection";
    begin
        TenantReportLayoutSelection.Get(Report::Check, SelectedCompany, SelectedUserId);
        Assert.AreEqual(LayoutName, TenantReportLayoutSelection."Layout Name", UnexpectedLayoutErr);
        Assert.AreEqual(AppId, TenantReportLayoutSelection."App ID", UnexpectedLayoutErr);
    end;

    local procedure VerifyGlobalUserLayout(SelectedUserId: Guid; LayoutName: Text[250]; AppId: Guid)
    var
        TenantReportLayoutSelection: Record "Tenant Report Layout Selection";
    begin
        VerifyLayoutSelection('', LayoutName, AppId, SelectedUserId);
        Assert.IsFalse(
            TenantReportLayoutSelection.Get(Report::Check, CompanyName(), SelectedUserId),
            'Migration must not copy a global user choice into a company-specific override.');
    end;

    local procedure VerifyUncompletedLayoutMigration()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        Assert.IsFalse(UpgradeTag.HasUpgradeTag(ReportLayoutsFR.GetCheckLayoutUpgradeTag()), 'Failed migration must not be tagged.');
        VerifyNoCompanyLayoutSelection();
    end;

    local procedure ReportsAppId(): Guid
    begin
        exit('6f93dbc5-c674-430e-b5f4-232449d55c20');
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
            FormatReportAmount(Check, NoText, 999999.99, '');
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
        SelectedCompany: Code[30];
    begin
        SelectedCompany := CopyStr(CompanyName(), 1, MaxStrLen(SelectedCompany));
        if UpgradeTag.HasUpgradeTag(ReportLayoutsFR.GetCheckLayoutUpgradeTag()) then
            UpgradeTagLibrary.DeleteUpgradeTag(ReportLayoutsFR.GetCheckLayoutUpgradeTag(), SelectedCompany);
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
    begin
        VerifyLayoutSelection(CompanyName(), LayoutName, AppId);
        Assert.IsTrue(UpgradeTag.HasUpgradeTag(ReportLayoutsFR.GetCheckLayoutUpgradeTag()), 'Successful Check layout migration must set its completion tag.');
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
        VerifyLayoutSelection(CompanyName(), 'CheckFR', ReportsAppId());
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
        VerifyLayoutSelection(CompanyName(), 'CheckFR', ReportsAppId());
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

#if not CLEAN30
    [EventSubscriber(ObjectType::Report, Report::Check, 'OnAfterFormatNoText', '', false, false)]
    local procedure OnAfterFormatNoText(var NoText: array[2] of Text[80]; No: Decimal; CurrencyCode: Code[10])
    begin
        FormattingAfterEventCount += 1;
        FormattingAfterEventAmount := No;
    end;
#endif
}
