// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using Microsoft.Bank.Check;
using Microsoft.Finance.Currency;
using Microsoft.Foundation.Reporting;
using System.Reflection;
using System.TestLibraries.Utilities;
using System.Upgrade;

codeunit 144042 "UT REP Number To Text"
{
    // [FEATURE] [Language] [UT] [Check]
    // The French amount wording is provided by Payment Management FR through the Check report event.
    // The expected texts rely on the untranslated labels of the app, only the number grammar is verified.

    Subtype = Test;
    TestPermissions = Disabled;
    TestType = Uncategorized;

    var
        Assert: Codeunit Assert;
        UnexpectedAmountTextErr: Label 'Unexpected amount text for %1 in language %2.', Comment = '%1 = amount, %2 = language ID';
        UnexpectedLayoutErr: Label 'Unexpected check layout selection.';

    [Test]
    procedure FrenchNumberGrammar()
    begin
        // [SCENARIO 653674] French number grammar is applied to the check amount in a French session.
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
        // [SCENARIO 653674] Euro and cent wording is applied to the check amount in a French session.
        VerifyFrenchAmountText(0, '**** ZERO EUROS');
        VerifyFrenchAmountText(1, '**** ONE EUROS');
        VerifyFrenchAmountText(1.01, '**** ONE EUROS ONE CENT');
        VerifyFrenchAmountText(1.02, '**** ONE EUROS TWO CENTS');
    end;

    [Test]
    procedure AllFrenchLanguagesUseFrenchWording()
    var
        LanguageId: Integer;
    begin
        // [SCENARIO 653674] Standard, Belgian, Swiss and Canadian French sessions use the French wording.
        foreach LanguageId in FrenchLanguageIds() do
            Assert.AreEqual(
                '**** TWO HUNDREDS EUROS',
                FormatAmountText(200, '', LanguageId),
                StrSubstNo(UnexpectedAmountTextErr, 200, LanguageId));
    end;

    [Test]
    procedure NonFrenchLanguageUsesHundredths()
    begin
        // [SCENARIO 653674] Other languages keep the international wording with hundredths.
        Assert.AreEqual(
            '**** TWENTY ONE AND 25/100',
            FormatAmountText(21.25, '', 1033),
            StrSubstNo(UnexpectedAmountTextErr, 21.25, 1033));
        Assert.AreEqual(
            '**** TWENTY ONE AND 25/100 USD',
            FormatAmountText(21.25, 'USD', 1033),
            StrSubstNo(UnexpectedAmountTextErr, 21.25, 1033));
    end;

    [Test]
    procedure FrenchExplicitCurrencyWording()
    var
        Currency: Record Currency;
    begin
        // [SCENARIO 653674] Explicit currencies use the currency description, and only FRF prints cents.
        CreateCurrency(Currency, 'FRF', 'Franc');
        Assert.AreEqual(
            '**** ONE FRANC TWO CENTS',
            FormatAmountText(1.02, Currency.Code, 1036),
            StrSubstNo(UnexpectedAmountTextErr, 1.02, 1036));

        CreateCurrency(Currency, 'TESTFR', 'Test Currency');
        Assert.AreEqual(
            '**** ONE TEST CURRENCY TWO',
            FormatAmountText(1.02, Currency.Code, 1036),
            StrSubstNo(UnexpectedAmountTextErr, 1.02, 1036));
    end;

    [Test]
    procedure LongAmountTextIsSplitInTwoLines()
    var
        NoText: array[2] of Text[80];
    begin
        // [SCENARIO 653674] A long amount text is split into the two lines of the check.
        FormatAmount(NoText, 999999.99, '', 1036);

        Assert.AreNotEqual('', NoText[2], StrSubstNo(UnexpectedAmountTextErr, 999999.99, 1036));
    end;

    [Test]
    procedure FrenchCheckLayoutIsProvidedByExtension()
    var
        ReportLayoutList: Record "Report Layout List";
    begin
        // [SCENARIO 653674] The French layout is owned by Payment Management FR, not Base Application.
        ReportLayoutList.Get(Report::Check, 'CheckFR', PaymentManagementAppId());
        Assert.AreEqual(ReportLayoutList."Layout Format"::RDLC, ReportLayoutList."Layout Format", UnexpectedLayoutErr);
    end;

    [Test]
    procedure FrenchCheckLayoutIsSelectedWithoutExistingSelection()
    var
        CheckLayoutFR: Codeunit "Check Layout FR";
    begin
        // [SCENARIO 653674] A company using the implicit built-in layout gets the extension layout.
        ClearLayoutSelections();

        CheckLayoutFR.SetDefaultLayout();

        VerifyLayoutSelection(CompanyName(), 'CheckFR', PaymentManagementAppId());
    end;

    [Test]
    procedure LegacyBuiltInCheckLayoutIsMigrated()
    var
        CheckLayoutFR: Codeunit "Check Layout FR";
        BaseApplicationId: Guid;
    begin
        // [SCENARIO 653674] An explicit Base Application check layout selection is migrated.
        ClearLayoutSelections();
        BaseApplicationId := '437dbf0e-84ff-417a-965d-ed2bb9650972';
        CreateLayoutSelection(CompanyName(), 'RDLCLayout', BaseApplicationId);

        CheckLayoutFR.SetDefaultLayout();

        VerifyLayoutSelection(CompanyName(), 'CheckFR', PaymentManagementAppId());
    end;

    [Test]
    procedure AllCompanyBuiltInCheckLayoutIsMigratedPerCompany()
    var
        CheckLayoutFR: Codeunit "Check Layout FR";
        BaseApplicationId: Guid;
    begin
        // [SCENARIO 653674] A global built-in default is migrated only for the current company.
        ClearLayoutSelections();
        BaseApplicationId := '437dbf0e-84ff-417a-965d-ed2bb9650972';
        CreateLayoutSelection('', 'RDLCLayout', BaseApplicationId);

        CheckLayoutFR.SetDefaultLayout();

        VerifyLayoutSelection(CompanyName(), 'CheckFR', PaymentManagementAppId());
        VerifyLayoutSelection('', 'RDLCLayout', BaseApplicationId);
    end;

    [Test]
    procedure CustomCheckLayoutSelectionIsPreserved()
    var
        CheckLayoutFR: Codeunit "Check Layout FR";
        EmptyGuid: Guid;
    begin
        // [SCENARIO 653674] A tenant-defined company layout is not replaced.
        ClearLayoutSelections();
        CreateLayoutSelection(CompanyName(), 'CUSTOM CHECK', EmptyGuid);

        CheckLayoutFR.SetDefaultLayout();

        VerifyLayoutSelection(CompanyName(), 'CUSTOM CHECK', EmptyGuid);
    end;

    [Test]
    procedure AllCompanyCustomCheckLayoutSelectionIsPreserved()
    var
        TenantReportLayoutSelection: Record "Tenant Report Layout Selection";
        CheckLayoutFR: Codeunit "Check Layout FR";
        EmptyGuid: Guid;
    begin
        // [SCENARIO 653674] A custom default applying to all companies is not shadowed.
        ClearLayoutSelections();
        CreateLayoutSelection('', 'CUSTOM CHECK', EmptyGuid);

        CheckLayoutFR.SetDefaultLayout();

        VerifyLayoutSelection('', 'CUSTOM CHECK', EmptyGuid);
        Assert.IsFalse(TenantReportLayoutSelection.Get(Report::Check, CompanyName(), EmptyGuid), UnexpectedLayoutErr);
    end;

    [Test]
    procedure OtherExtensionCheckLayoutSelectionIsPreserved()
    var
        CheckLayoutFR: Codeunit "Check Layout FR";
        OtherAppId: Guid;
    begin
        // [SCENARIO 653674] A layout selected from another extension is not replaced.
        ClearLayoutSelections();
        OtherAppId := CreateGuid();
        CreateLayoutSelection(CompanyName(), 'OTHER CHECK', OtherAppId);

        CheckLayoutFR.SetDefaultLayout();

        VerifyLayoutSelection(CompanyName(), 'OTHER CHECK', OtherAppId);
    end;

    [Test]
    procedure LegacyCustomCheckLayoutSelectionIsPreserved()
    var
        ReportLayoutSelection: Record "Report Layout Selection";
        TenantReportLayoutSelection: Record "Tenant Report Layout Selection";
        CheckLayoutFR: Codeunit "Check Layout FR";
        EmptyGuid: Guid;
    begin
        // [SCENARIO 653674] A legacy custom layout remains selected.
        ClearLayoutSelections();
        ReportLayoutSelection.Init();
        ReportLayoutSelection."Report ID" := Report::Check;
        ReportLayoutSelection."Company Name" := CompanyName();
        ReportLayoutSelection.Type := ReportLayoutSelection.Type::"Custom Layout";
        ReportLayoutSelection."Custom Report Layout Code" := 'CUSTOM CHECK';
        ReportLayoutSelection.Insert();

        CheckLayoutFR.SetDefaultLayout();

        ReportLayoutSelection.Get(Report::Check, CompanyName());
        Assert.AreEqual('CUSTOM CHECK', ReportLayoutSelection."Custom Report Layout Code", UnexpectedLayoutErr);
        Assert.IsFalse(TenantReportLayoutSelection.Get(Report::Check, CompanyName(), EmptyGuid), UnexpectedLayoutErr);
    end;

    [Test]
    procedure FrenchCheckLayoutSelectionIsIdempotent()
    var
        CheckLayoutFR: Codeunit "Check Layout FR";
    begin
        // [SCENARIO 653674] Repeated selection does not change the selected extension layout.
        ClearLayoutSelections();

        CheckLayoutFR.SetDefaultLayout();
        CheckLayoutFR.SetDefaultLayout();

        VerifyLayoutSelection(CompanyName(), 'CheckFR', PaymentManagementAppId());
    end;

    [Test]
    procedure UserSpecificCheckLayoutSelectionIsPreserved()
    var
        TenantReportLayoutSelection: Record "Tenant Report Layout Selection";
        CheckLayoutFR: Codeunit "Check Layout FR";
        EmptyGuid: Guid;
        SelectedUserId: Guid;
    begin
        // [SCENARIO 653674] Migrating the company default does not change user-specific selections.
        ClearLayoutSelections();
        SelectedUserId := CreateGuid();
        TenantReportLayoutSelection.Init();
        TenantReportLayoutSelection."Report ID" := Report::Check;
        TenantReportLayoutSelection."Company Name" := CompanyName();
        TenantReportLayoutSelection."User ID" := SelectedUserId;
        TenantReportLayoutSelection."Layout Name" := 'USER CHECK';
        TenantReportLayoutSelection.Insert();

        CheckLayoutFR.SetDefaultLayout();

        VerifyLayoutSelection(CompanyName(), 'CheckFR', PaymentManagementAppId());
        TenantReportLayoutSelection.Get(Report::Check, CompanyName(), SelectedUserId);
        Assert.AreEqual('USER CHECK', TenantReportLayoutSelection."Layout Name", UnexpectedLayoutErr);
        Assert.AreEqual(EmptyGuid, TenantReportLayoutSelection."App ID", UnexpectedLayoutErr);
    end;

    [Test]
    procedure CompletedLayoutUpgradeDoesNotOverrideLaterSelection()
    var
        CheckLayoutFR: Codeunit "Check Layout FR";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgTagPayment: Codeunit "Upg. Tag Payment Management FR";
        BaseApplicationId: Guid;
    begin
        // [SCENARIO 653674] Later upgrades preserve a built-in layout explicitly selected after migration.
        ClearLayoutSelections();
        if not UpgradeTag.HasUpgradeTag(UpgTagPayment.GetCheckLayoutUpgradeTag()) then
            UpgradeTag.SetUpgradeTag(UpgTagPayment.GetCheckLayoutUpgradeTag());
        BaseApplicationId := '437dbf0e-84ff-417a-965d-ed2bb9650972';
        CreateLayoutSelection(CompanyName(), 'RDLCLayout', BaseApplicationId);

        CheckLayoutFR.UpgradeLayout();

        VerifyLayoutSelection(CompanyName(), 'RDLCLayout', BaseApplicationId);
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

    local procedure CreateLayoutSelection(SelectedCompany: Text[30]; LayoutName: Text[250]; AppId: Guid)
    var
        TenantReportLayoutSelection: Record "Tenant Report Layout Selection";
    begin
        TenantReportLayoutSelection.Init();
        TenantReportLayoutSelection."Report ID" := Report::Check;
        TenantReportLayoutSelection."Company Name" := SelectedCompany;
        TenantReportLayoutSelection."Layout Name" := LayoutName;
        TenantReportLayoutSelection."App ID" := AppId;
        TenantReportLayoutSelection.Insert();
    end;

    local procedure VerifyLayoutSelection(SelectedCompany: Text[30]; LayoutName: Text[250]; AppId: Guid)
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
    begin
        Assert.AreEqual(
            ExpectedAmountText,
            FormatAmountText(Amount, '', 1036),
            StrSubstNo(UnexpectedAmountTextErr, Amount, 1036));
    end;

    local procedure FrenchLanguageIds() LanguageIds: List of [Integer]
    begin
        LanguageIds.Add(1036);
        LanguageIds.Add(2060);
        LanguageIds.Add(3084);
        LanguageIds.Add(4108);
    end;

    local procedure FormatAmountText(Amount: Decimal; CurrencyCode: Code[10]; LanguageId: Integer): Text
    var
        NoText: array[2] of Text[80];
    begin
        FormatAmount(NoText, Amount, CurrencyCode, LanguageId);

        if NoText[2] = '' then
            exit(NoText[1]);
        exit(NoText[1] + ' ' + NoText[2]);
    end;

    local procedure FormatAmount(var NoText: array[2] of Text[80]; Amount: Decimal; CurrencyCode: Code[10]; LanguageId: Integer)
    var
        Check: Report Check;
        OriginalLanguageId: Integer;
    begin
        OriginalLanguageId := GlobalLanguage();
        GlobalLanguage(LanguageId);
        Check.FormatNoText(NoText, Amount, CurrencyCode);
        GlobalLanguage(OriginalLanguageId);
    end;

    local procedure CreateCurrency(var Currency: Record Currency; CurrencyCode: Code[10]; Description: Text[30])
    begin
        if Currency.Get(CurrencyCode) then
            Currency.Delete();

        Currency.Init();
        Currency.Code := CurrencyCode;
        Currency.Description := Description;
        Currency.Insert();
    end;
}
