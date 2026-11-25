// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.ExpenseTaxIntegration;

using Microsoft.ExpenseAgent;
using Microsoft.ExpenseTaxIntegration;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.HumanResources.Employee;
using Microsoft.HumanResources.Payables;
using Microsoft.Test.ExpenseAgent;
using Microsoft.WithholdingTax;
using Microsoft.WithholdingTax.Employee;

codeunit 148370 "Expense WHT Posting Tests"
{
    Subtype = Test;
    TestType = IntegrationTest;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Withholding Tax] [Employee] [Expense Report] [Threshold]
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryExpense: Codeunit "Library - Expense";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryUtility: Codeunit "Library - Utility";
        IsInitialized: Boolean;
        WrongValueErr: Label 'Wrong value of %1.', Comment = '%1 = field or amount description';

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure TotalPeriodThresholdExpenseReportLinesShareThreshold()
    begin
        // [SCENARIO 657603] Posting an expense report with two lines deducts the Total in Period threshold once and accumulates each line's original base.
        // [GIVEN] Total in Period threshold 1,000, 20 % withholding and "Tax Only Amount Above Threshold" enabled.
        // [WHEN] Post an expense report with two 1,500 lines in two expense categories.
        // [THEN] The lines withhold 100 and 300; the employee is credited with 2,600, the withholding tax account with 400 and the period accumulates 3,000.
        PostExpenseReportWithTwoLines("Withholding Threshold Base"::"Total Period", 3000);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure DocumentThresholdExpenseReportLinesShareThreshold()
    begin
        // [SCENARIO 657603] Posting an expense report with two lines deducts the Document threshold once.
        // [GIVEN] Document threshold 1,000, 20 % withholding and "Tax Only Amount Above Threshold" enabled.
        // [WHEN] Post an expense report with two 1,500 lines in two expense categories.
        // [THEN] The lines withhold 100 and 300; the employee is credited with 2,600 and the withholding tax account with 400.
        PostExpenseReportWithTwoLines("Withholding Threshold Base"::Document, 0);
    end;

    local procedure PostExpenseReportWithTwoLines(ThresholdBase: Enum "Withholding Threshold Base"; ExpectedAccumulatedBase: Decimal)
    var
        WHTPostingSetup: Record "Withholding Tax Posting Setup";
        ExpenseUser: Record "Expense User";
        ExpenseCategory: array[2] of Record "Expense Category";
        ExpensePaymentMethod: Record "Expense Payment Method";
        ExpenseReportHeader: Record "Expense Report Header";
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseReportPost: Codeunit "Expense Report-Post";
        i: Integer;
    begin
        Initialize();

        CreateEmployeeWHTPostingSetup(WHTPostingSetup, ThresholdBase);
        CreateExpenseUser(ExpenseUser, WHTPostingSetup."Wthldg. Tax Bus. Post. Group");
        LibraryExpense.FindExpensePaymentMethod(ExpensePaymentMethod, ExpensePaymentMethod."Reimbursement Type"::"Employee Paid");

        LibraryExpense.CreateExpenseReport(ExpenseReportHeader, ExpenseUser."No.", '', '');
        for i := 1 to 2 do begin
            CreateWHTExpenseCategory(ExpenseCategory[i], WHTPostingSetup."Wthldg. Tax Prod. Post. Group", ExpensePaymentMethod.Code);
            LibraryExpense.CreateExpenseReportLine(
                ExpenseReportLine, ExpenseReportHeader, ExpenseUser."No.", ExpenseCategory[i].Code, ExpensePaymentMethod.Code, true, '', 1500, false);
            ExpenseReportLine.Validate("Expense Date", WorkDate());
            ExpenseReportLine.Modify(true);
        end;

        ExpenseReportHeader.PerformManualRelease();
        ExpenseReportPost.PostExpenseReport(ExpenseReportHeader);

        VerifyPostedExpenseReport(WHTPostingSetup, ExpenseReportHeader."Last Posting No.", ExpenseUser."Employee No.", 2600, 400);
        VerifyLineWithholdingEntries(ExpenseReportHeader."Last Posting No.", ExpenseUser."Employee No.");
        VerifyAccumulatedBase(ExpenseUser."Employee No.", ExpectedAccumulatedBase);
    end;

    local procedure Initialize()
    var
        ExpenseAgentSetup: Record "Expense Agent Setup";
        GeneralLedgerSetup: Record "General Ledger Setup";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibrarySetupStorage.Restore();
        LibraryExpense.CleanUpBeforeTesting();
        LibraryExpense.SetupNumberSeriesInExpenseMgmt();
        LibraryExpense.InitializeExpenseSourceCode();
        LibraryExpense.UpdateEnableApprovalWorkflowInAgentSetup(false);

        if IsInitialized then
            exit;

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.CreateGeneralPostingSetupData();
        LibraryERMCountryData.UpdateVATPostingSetup();
        LibraryERMCountryData.UpdateJournalTemplMandatory(false);

        ExpenseAgentSetup.Get();
        ExpenseAgentSetup.Validate("Allow VAT Reclaim", false);
        ExpenseAgentSetup.Validate("Use Rules", false);
        ExpenseAgentSetup.Modify(true);

        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."Enable Withholding Tax" := true;
        GeneralLedgerSetup."Additional Reporting Currency" := '';
        GeneralLedgerSetup.Modify();

        LibrarySetupStorage.SaveGeneralLedgerSetup();
        IsInitialized := true;
        Commit();
    end;

    local procedure CreateEmployeeWHTPostingSetup(var WHTPostingSetup: Record "Withholding Tax Posting Setup"; ThresholdBase: Enum "Withholding Threshold Base")
    var
        WHTBusinessPostingGroup: Record "Wthldg. Tax Bus. Post. Group";
        WHTProductPostingGroup: Record "Wthldg. Tax Prod. Post. Group";
    begin
        WHTBusinessPostingGroup.Init();
        WHTBusinessPostingGroup.Validate(Code, LibraryUtility.GenerateRandomCode(WHTBusinessPostingGroup.FieldNo(Code), Database::"Wthldg. Tax Bus. Post. Group"));
        WHTBusinessPostingGroup.Validate("Party Applicability", "Withholding Party Type"::Employee);
        WHTBusinessPostingGroup.Insert(true);

        WHTProductPostingGroup.Init();
        WHTProductPostingGroup.Validate(Code, LibraryUtility.GenerateRandomCode(WHTProductPostingGroup.FieldNo(Code), Database::"Wthldg. Tax Prod. Post. Group"));
        WHTProductPostingGroup.Insert(true);

        WHTPostingSetup.Init();
        WHTPostingSetup.Validate("Wthldg. Tax Bus. Post. Group", WHTBusinessPostingGroup.Code);
        WHTPostingSetup.Validate("Wthldg. Tax Prod. Post. Group", WHTProductPostingGroup.Code);
        WHTPostingSetup.Insert(true);

        WHTPostingSetup.Validate("Withholding Tax %", 20);
        WHTPostingSetup.Validate("Wthldg. Tax Min. Inv. Amount", 1000);
        WHTPostingSetup.Validate("Calculation Base", "Withholding Calculation Base"::Gross);
        WHTPostingSetup.Validate("WHT Threshold Base", ThresholdBase);
        if ThresholdBase in ["Withholding Threshold Base"::"Category Period", "Withholding Threshold Base"::"Total Period"] then
            WHTPostingSetup.Validate("WHT Threshold Period", "WHT Threshold Period Type"::Month);
        WHTPostingSetup.Validate("Tax Amount Above Threshold", true);
        WHTPostingSetup.Validate("Payable Wthldg. Tax Acc. Code", LibraryERM.CreateGLAccountNoWithDirectPosting());
        WHTPostingSetup.Modify(true);
    end;

    local procedure CreateExpenseUser(var ExpenseUser: Record "Expense User"; WHTBusPostingGroupCode: Code[20])
    var
        Employee: Record Employee;
    begin
        LibraryExpense.CreateExpenseUser(ExpenseUser);
        Employee.Get(ExpenseUser."Employee No.");
        Employee."Wthldg. Tax Bus. Post. Group" := WHTBusPostingGroupCode;
        Employee.Modify(true);
        LibraryExpense.UpdateExpenseAccountInEmployeePostingGroup(Employee."Employee Posting Group");
    end;

    local procedure CreateWHTExpenseCategory(var ExpenseCategory: Record "Expense Category"; WHTProdPostingGroupCode: Code[20]; PaymentMethodCode: Code[10])
    begin
        LibraryExpense.CreateExpenseCategory(
            ExpenseCategory, ExpenseCategory."Reimbursement Type"::"Employee Paid", ExpenseCategory."Expense Detail Required"::" ", PaymentMethodCode);
        ExpenseCategory.Validate("Withholding Selection Mode", "Withholding Selection Mode"::"Single Tax");
        ExpenseCategory.Validate("Wthldg. Tax Prod. Post. Group", WHTProdPostingGroupCode);
        ExpenseCategory.Modify(true);
    end;

    local procedure VerifyPostedExpenseReport(WHTPostingSetup: Record "Withholding Tax Posting Setup"; DocumentNo: Code[20]; EmployeeNo: Code[20]; ExpectedEmployeeAmount: Decimal; ExpectedWHTAmount: Decimal)
    var
        EmployeeLedgerEntry: Record "Employee Ledger Entry";
        WithholdingTaxEntry: Record "Withholding Tax Entry";
        GLEntry: Record "G/L Entry";
    begin
        EmployeeLedgerEntry.SetRange("Employee No.", EmployeeNo);
#pragma warning disable AA0210
        EmployeeLedgerEntry.SetRange("Document No.", DocumentNo);
#pragma warning restore AA0210
        Assert.RecordCount(EmployeeLedgerEntry, 1);
        EmployeeLedgerEntry.FindFirst();
        EmployeeLedgerEntry.CalcFields(Amount);
        Assert.AreEqual(-ExpectedEmployeeAmount, EmployeeLedgerEntry.Amount, StrSubstNo(WrongValueErr, EmployeeLedgerEntry.FieldCaption(Amount)));

#pragma warning disable AA0210
        WithholdingTaxEntry.SetRange("Employee No.", EmployeeNo);
#pragma warning restore AA0210
        WithholdingTaxEntry.SetRange("Document No.", DocumentNo);
        WithholdingTaxEntry.CalcSums(Amount);
        Assert.AreEqual(-ExpectedWHTAmount, WithholdingTaxEntry.Amount, StrSubstNo(WrongValueErr, WithholdingTaxEntry.FieldCaption(Amount)));

        GLEntry.SetRange("G/L Account No.", WHTPostingSetup."Payable Wthldg. Tax Acc. Code");
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.CalcSums(Amount);
        Assert.AreEqual(-ExpectedWHTAmount, GLEntry.Amount, StrSubstNo(WrongValueErr, GLEntry.FieldCaption(Amount)));
    end;

    local procedure VerifyLineWithholdingEntries(DocumentNo: Code[20]; EmployeeNo: Code[20])
    var
        WithholdingTaxEntry: Record "Withholding Tax Entry";
    begin
#pragma warning disable AA0210
        WithholdingTaxEntry.SetRange("Employee No.", EmployeeNo);
#pragma warning restore AA0210
        WithholdingTaxEntry.SetRange("Document No.", DocumentNo);
        Assert.RecordCount(WithholdingTaxEntry, 2);

        // Each entry keeps its line's original base 1,500 for the threshold accumulation.
        WithholdingTaxEntry.SetRange("Threshold Accum. Base Amount", 1500);
        Assert.RecordCount(WithholdingTaxEntry, 2);
        WithholdingTaxEntry.SetRange("Threshold Accum. Base Amount");

        WithholdingTaxEntry.SetRange(Amount, -100);
        WithholdingTaxEntry.SetRange(Base, 500);
        Assert.RecordCount(WithholdingTaxEntry, 1);
        WithholdingTaxEntry.SetRange(Amount, -300);
        WithholdingTaxEntry.SetRange(Base, 1500);
        Assert.RecordCount(WithholdingTaxEntry, 1);
    end;

    local procedure VerifyAccumulatedBase(EmployeeNo: Code[20]; ExpectedAmount: Decimal)
    var
        WHTThresholdAccumulator: Record "WHT Threshold Accumulator";
    begin
        WHTThresholdAccumulator.SetRange("Employee No.", EmployeeNo);
        WHTThresholdAccumulator.CalcSums("Accumulated Base Amount");
        Assert.AreEqual(ExpectedAmount, WHTThresholdAccumulator."Accumulated Base Amount", StrSubstNo(WrongValueErr, WHTThresholdAccumulator.FieldCaption("Accumulated Base Amount")));
    end;

    [ConfirmHandler]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;
}
