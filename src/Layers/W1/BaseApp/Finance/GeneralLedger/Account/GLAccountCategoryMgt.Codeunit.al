// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Account;

using Microsoft.Finance.FinancialReports;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Company;

codeunit 570 "G/L Account Category Mgt."
{

    trigger OnRun()
    begin
        InitializeAccountCategories();
    end;

    var
        BalanceColumnNameTxt: Label 'M-BALANCE', Comment = 'Max 10 char';
        BalanceColumnDescTxt: Label 'Balance', Comment = 'Max 10 char';
        NetChangeColumnNameTxt: Label 'M-NETCHANG', Comment = 'Max 10 char';
        NetChangeColumnDescTxt: Label 'Net Change', Comment = 'Max 10 char';
        BalanceSheetCodeTxt: Label 'M-BALANCE', Comment = 'Max 10 char';
        BalanceSheetDescTxt: Label 'Balance Sheet', Comment = 'Max 80 chars';
        IncomeStmdCodeTxt: Label 'M-INCOME', Comment = 'Max 10 chars';
        IncomeStmdDescTxt: Label 'Income Statement', Comment = 'Max 80 chars';
        CashFlowCodeTxt: Label 'M-CASHFLOW', Comment = 'Max 10 chars';
        CashFlowDescTxt: Label 'Cash Flow Statement', Comment = 'Max 80 chars';
        RetainedEarnCodeTxt: Label 'M-RETAIND', Comment = 'Max 10 char.';
        RetainedEarnDescTxt: Label 'Retained Earnings', Comment = 'Max 80 chars';
        MissingSetupErr: Label 'You must define a %1 in %2 before performing this function.', Comment = '%1 = field name, %2 = table name.';
        CurrentAssetsTxt: Label 'Current Assets';
        ARTxt: Label 'Accounts Receivable';
        CashTxt: Label 'Cash';
        PrepaidExpensesTxt: Label 'Prepaid Expenses';
        InventoryTxt: Label 'Inventory';
        FixedAssetsTxt: Label 'Fixed Assets';
        EquipementTxt: Label 'Equipment';
        AccumDeprecTxt: Label 'Accumulated Depreciation';
        CurrentLiabilitiesTxt: Label 'Current Liabilities';
        PayrollLiabilitiesTxt: Label 'Payroll Liabilities';
        LongTermLiabilitiesTxt: Label 'Long Term Liabilities';
        CommonStockTxt: Label 'Common Stock';
        RetEarningsTxt: Label 'Retained Earnings';
        DistrToShareholdersTxt: Label 'Distributions to Shareholders';
        IncomeServiceTxt: Label 'Income, Services';
        IncomeProdSalesTxt: Label 'Income, Product Sales';
        IncomeSalesDiscountsTxt: Label 'Sales Discounts';
        IncomeSalesReturnsTxt: Label 'Sales Returns & Allowances';
        IncomeInterestTxt: Label 'Income, Interest';
        COGSLaborTxt: Label 'Labor';
        COGSMaterialsTxt: Label 'Materials';
        COGSDiscountsGrantedTxt: Label 'Discounts Granted';
        RentExpenseTxt: Label 'Rent Expense';
        AdvertisingExpenseTxt: Label 'Advertising Expense';
        InterestExpenseTxt: Label 'Interest Expense';
        FeesExpenseTxt: Label 'Fees Expense';
        InsuranceExpenseTxt: Label 'Insurance Expense';
        PayrollExpenseTxt: Label 'Payroll Expense';
        BenefitsExpenseTxt: Label 'Benefits Expense';
        RepairsTxt: Label 'Repairs and Maintenance Expense';
        UtilitiesExpenseTxt: Label 'Utilities Expense';
        OtherIncomeExpenseTxt: Label 'Other Income & Expenses';
        TaxExpenseTxt: Label 'Tax Expense';
        TravelExpenseTxt: Label 'Travel Expense';
        VehicleExpensesTxt: Label 'Vehicle Expenses';
        BadDebtExpenseTxt: Label 'Bad Debt Expense';
        SalariesExpenseTxt: Label 'Salaries Expense';
        JobsCostTxt: Label 'Jobs Cost';
        IncomeJobsTxt: Label 'Income, Jobs';
        JobSalesContraTxt: Label 'Job Sales Contra';
        OverwriteConfirmationQst: Label 'How do you want to generate standard financial reports?';
        GenerateAccountSchedulesOptionsTxt: Label 'Keep existing financial reports with their row definitions and create new ones.,Overwrite existing financial reports and row defintions.';
        GeneratedFromGLAccountCategoriesPageTxt: Label 'Generated from the G/L Account Categories page.';
        CreateAccountScheduleForBalanceSheet: Boolean;
        CreateAccountScheduleForIncomeStatement: Boolean;
        CreateAccountScheduleForCashFlowStatement: Boolean;
        CreateAccountScheduleForRetainedEarnings: Boolean;
        ForceCreateAccountSchedule: Boolean;

    procedure InitializeAccountCategories()
    var
        GLAccountCategory: Record "G/L Account Category";
        GLAccount: Record "G/L Account";
        CategoryID: array[3] of Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInitializeAccountCategories(IsHandled);
        if IsHandled then
            exit;

        GLAccount.SetFilter("Account Subcategory Entry No.", '<>0');
        if not GLAccount.IsEmpty() then
            if not GLAccountCategory.IsEmpty() then
                exit;

        GLAccount.ModifyAll("Account Subcategory Entry No.", 0);
        GLAccountCategory.DeleteAll();
        CategoryID[1] := AddCategory(0, 0, GLAccountCategory."Account Category"::Assets, '', true, 0);
        CategoryID[2] := AddCategory(0, CategoryID[1], GLAccountCategory."Account Category"::Assets, CurrentAssetsTxt, false, 0);
        CategoryID[3] :=
          AddCategory(0, CategoryID[2], GLAccountCategory."Account Category"::Assets, CashTxt, false, GLAccountCategory."Additional Report Definition"::"Cash Accounts");
        CategoryID[3] :=
          AddCategory(
            0, CategoryID[2], GLAccountCategory."Account Category"::Assets, ARTxt, false,
            GLAccountCategory."Additional Report Definition"::"Operating Activities");
        CategoryID[3] :=
          AddCategory(
            0, CategoryID[2], GLAccountCategory."Account Category"::Assets, PrepaidExpensesTxt, false,
            GLAccountCategory."Additional Report Definition"::"Operating Activities");
        CategoryID[3] :=
          AddCategory(
            0, CategoryID[2], GLAccountCategory."Account Category"::Assets, InventoryTxt, false,
            GLAccountCategory."Additional Report Definition"::"Operating Activities");
        CategoryID[2] := AddCategory(0, CategoryID[1], GLAccountCategory."Account Category"::Assets, FixedAssetsTxt, false, 0);
        CategoryID[3] :=
          AddCategory(
            0, CategoryID[2], GLAccountCategory."Account Category"::Assets, EquipementTxt, false,
            GLAccountCategory."Additional Report Definition"::"Investing Activities");
        CategoryID[3] :=
          AddCategory(
            0, CategoryID[2], GLAccountCategory."Account Category"::Assets, AccumDeprecTxt, false,
            GLAccountCategory."Additional Report Definition"::"Investing Activities");
        CategoryID[1] := AddCategory(0, 0, GLAccountCategory."Account Category"::Liabilities, '', true, 0);
        CategoryID[2] :=
          AddCategory(
            0, CategoryID[1], GLAccountCategory."Account Category"::Liabilities, CurrentLiabilitiesTxt, false,
            GLAccountCategory."Additional Report Definition"::"Operating Activities");
        CategoryID[2] :=
          AddCategory(
            0, CategoryID[1], GLAccountCategory."Account Category"::Liabilities, PayrollLiabilitiesTxt, false,
            GLAccountCategory."Additional Report Definition"::"Operating Activities");
        CategoryID[2] :=
          AddCategory(
            0, CategoryID[1], GLAccountCategory."Account Category"::Liabilities, LongTermLiabilitiesTxt, false,
            GLAccountCategory."Additional Report Definition"::"Financing Activities");
        CategoryID[1] := AddCategory(0, 0, GLAccountCategory."Account Category"::Equity, '', true, 0);
        CategoryID[2] := AddCategory(0, CategoryID[1], GLAccountCategory."Account Category"::Equity, CommonStockTxt, false, 0);
        CategoryID[2] :=
          AddCategory(
            0, CategoryID[1], GLAccountCategory."Account Category"::Equity, RetEarningsTxt, false,
            GLAccountCategory."Additional Report Definition"::"Retained Earnings");
        CategoryID[2] :=
          AddCategory(
            0, CategoryID[1], GLAccountCategory."Account Category"::Equity, DistrToShareholdersTxt, false,
            GLAccountCategory."Additional Report Definition"::"Distribution to Shareholders");
        CategoryID[1] := AddCategory(0, 0, GLAccountCategory."Account Category"::Income, '', true, 0);
        CategoryID[2] := AddCategory(0, CategoryID[1], GLAccountCategory."Account Category"::Income, IncomeServiceTxt, false, 0);
        CategoryID[2] := AddCategory(0, CategoryID[1], GLAccountCategory."Account Category"::Income, IncomeProdSalesTxt, false, 0);
        CategoryID[2] := AddCategory(0, CategoryID[1], GLAccountCategory."Account Category"::Income, IncomeJobsTxt, false, 0);
        CategoryID[2] := AddCategory(0, CategoryID[1], GLAccountCategory."Account Category"::Income, IncomeSalesDiscountsTxt, false, 0);
        CategoryID[2] := AddCategory(0, CategoryID[1], GLAccountCategory."Account Category"::Income, IncomeSalesReturnsTxt, false, 0);
        CategoryID[2] := AddCategory(0, CategoryID[1], GLAccountCategory."Account Category"::Income, IncomeInterestTxt, false, 0);
        CategoryID[2] := AddCategory(0, CategoryID[1], GLAccountCategory."Account Category"::Income, JobSalesContraTxt, false, 0);
        CategoryID[1] := AddCategory(0, 0, GLAccountCategory."Account Category"::"Cost of Goods Sold", '', true, 0);
        CategoryID[2] := AddCategory(0, CategoryID[1], GLAccountCategory."Account Category"::"Cost of Goods Sold", COGSLaborTxt, false, 0);
        CategoryID[2] := AddCategory(0, CategoryID[1], GLAccountCategory."Account Category"::"Cost of Goods Sold", COGSMaterialsTxt, false, 0);
        CategoryID[2] := AddCategory(0, CategoryID[1], GLAccountCategory."Account Category"::"Cost of Goods Sold", COGSDiscountsGrantedTxt, false, 0);
        CategoryID[2] := AddCategory(0, CategoryID[1], GLAccountCategory."Account Category"::"Cost of Goods Sold", JobsCostTxt, false, 0);
        CategoryID[1] := AddCategory(0, 0, GLAccountCategory."Account Category"::Expense, '', true, 0);
        CategoryID[2] := AddCategory(0, CategoryID[1], GLAccountCategory."Account Category"::Expense, RentExpenseTxt, false, 0);
        CategoryID[2] := AddCategory(0, CategoryID[1], GLAccountCategory."Account Category"::Expense, AdvertisingExpenseTxt, false, 0);
        CategoryID[2] := AddCategory(0, CategoryID[1], GLAccountCategory."Account Category"::Expense, InterestExpenseTxt, false, 0);
        CategoryID[2] := AddCategory(0, CategoryID[1], GLAccountCategory."Account Category"::Expense, FeesExpenseTxt, false, 0);
        CategoryID[2] := AddCategory(0, CategoryID[1], GLAccountCategory."Account Category"::Expense, InsuranceExpenseTxt, false, 0);
        CategoryID[2] := AddCategory(0, CategoryID[1], GLAccountCategory."Account Category"::Expense, PayrollExpenseTxt, false, 0);
        CategoryID[2] := AddCategory(0, CategoryID[1], GLAccountCategory."Account Category"::Expense, BenefitsExpenseTxt, false, 0);
        CategoryID[2] := AddCategory(0, CategoryID[1], GLAccountCategory."Account Category"::Expense, SalariesExpenseTxt, false, 0);
        CategoryID[2] := AddCategory(0, CategoryID[1], GLAccountCategory."Account Category"::Expense, RepairsTxt, false, 0);
        CategoryID[2] := AddCategory(0, CategoryID[1], GLAccountCategory."Account Category"::Expense, UtilitiesExpenseTxt, false, 0);
        CategoryID[2] := AddCategory(0, CategoryID[1], GLAccountCategory."Account Category"::Expense, OtherIncomeExpenseTxt, false, 0);
        CategoryID[2] := AddCategory(0, CategoryID[1], GLAccountCategory."Account Category"::Expense, TaxExpenseTxt, false, 0);
        CategoryID[2] := AddCategory(0, CategoryID[1], GLAccountCategory."Account Category"::Expense, TravelExpenseTxt, false, 0);
        CategoryID[2] := AddCategory(0, CategoryID[1], GLAccountCategory."Account Category"::Expense, VehicleExpensesTxt, false, 0);
        CategoryID[2] := AddCategory(0, CategoryID[1], GLAccountCategory."Account Category"::Expense, BadDebtExpenseTxt, false, 0);

        OnAfterInitializeAccountCategories();
    end;

    procedure AddCategory(InsertAfterEntryNo: Integer; ParentEntryNo: Integer; AccountCategory: Option; NewDescription: Text[80]; SystemGenerated: Boolean; CashFlowActivity: Option): Integer
    var
        GLAccountCategory: Record "G/L Account Category";
        InsertAfterSequenceNo: Integer;
        InsertBeforeSequenceNo: Integer;
    begin
        if InsertAfterEntryNo <> 0 then begin
            GLAccountCategory.SetCurrentKey("Presentation Order", "Sibling Sequence No.");
            if GLAccountCategory.Get(InsertAfterEntryNo) then begin
                InsertAfterSequenceNo := GLAccountCategory."Sibling Sequence No.";
                if GLAccountCategory.Next() <> 0 then
                    InsertBeforeSequenceNo := GLAccountCategory."Sibling Sequence No.";
            end;
        end;
        GLAccountCategory.Init();
        GLAccountCategory."Entry No." := 0;
        GLAccountCategory."System Generated" := SystemGenerated;
        GLAccountCategory."Parent Entry No." := ParentEntryNo;
        GLAccountCategory.Validate("Account Category", AccountCategory);
        GLAccountCategory.Validate("Additional Report Definition", CashFlowActivity);
        if NewDescription <> '' then
            GLAccountCategory.Description := NewDescription;
        if InsertAfterSequenceNo <> 0 then
            if InsertBeforeSequenceNo <> 0 then
                GLAccountCategory."Sibling Sequence No." := (InsertBeforeSequenceNo + InsertAfterSequenceNo) div 2
            else
                GLAccountCategory."Sibling Sequence No." := InsertAfterSequenceNo + 10000;
        GLAccountCategory.Insert(true);
        GLAccountCategory.UpdatePresentationOrder();
        exit(GLAccountCategory."Entry No.");
    end;

    procedure ForceInitializeStandardAccountSchedules()
    begin
        ForceCreateAccountSchedule := true;
        InitializeStandardAccountSchedules();
    end;

    procedure InitializeStandardAccountSchedules()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        if not GeneralLedgerSetup.Get() then
            exit;

        if GeneralLedgerSetup."Fin. Rep. Bal. Sheet Column" = '' then
            GeneralLedgerSetup."Fin. Rep. Bal. Sheet Column" := BalanceColumnNameTxt;
        if GeneralLedgerSetup."Fin. Rep. Net Change Column" = '' then
            GeneralLedgerSetup."Fin. Rep. Net Change Column" := NetChangeColumnNameTxt;

        if GeneralLedgerSetup."Fin. Rep. Bal. Sheet Row" = '' then
            GeneralLedgerSetup."Fin. Rep. Bal. Sheet Row" := BalanceSheetCodeTxt;
        if GeneralLedgerSetup."Fin. Rep. Income Stmt. Row" = '' then
            GeneralLedgerSetup."Fin. Rep. Income Stmt. Row" := IncomeStmdCodeTxt;
        if GeneralLedgerSetup."Fin. Rep. Cash Flow Stmt. Row" = '' then
            GeneralLedgerSetup."Fin. Rep. Cash Flow Stmt. Row" := CashFlowCodeTxt;
        if GeneralLedgerSetup."Fin. Rep. Retained Earn. Row" = '' then
            GeneralLedgerSetup."Fin. Rep. Retained Earn. Row" := RetainedEarnCodeTxt;

        if ForceCreateAccountSchedule then begin
            GeneralLedgerSetup."Fin. Rep. Bal. Sheet Column" := CreateUniqueColumnLayoutName(GeneralLedgerSetup."Fin. Rep. Bal. Sheet Column");
            GeneralLedgerSetup."Fin. Rep. Net Change Column" := CreateUniqueColumnLayoutName(GeneralLedgerSetup."Fin. Rep. Net Change Column");

            GeneralLedgerSetup."Fin. Rep. Bal. Sheet Row" := CreateUniqueAccSchedName(GeneralLedgerSetup."Fin. Rep. Bal. Sheet Row");
            GeneralLedgerSetup."Fin. Rep. Income Stmt. Row" := CreateUniqueAccSchedName(GeneralLedgerSetup."Fin. Rep. Income Stmt. Row");
            GeneralLedgerSetup."Fin. Rep. Cash Flow Stmt. Row" := CreateUniqueAccSchedName(GeneralLedgerSetup."Fin. Rep. Cash Flow Stmt. Row");
            GeneralLedgerSetup."Fin. Rep. Retained Earn. Row" := CreateUniqueAccSchedName(GeneralLedgerSetup."Fin. Rep. Retained Earn. Row");
        end;

        if (GeneralLedgerSetup."Fin. Rep. for Balance Sheet" = '') or ForceCreateAccountSchedule then begin
            if GeneralLedgerSetup."Fin. Rep. for Balance Sheet" = '' then
                GeneralLedgerSetup."Fin. Rep. for Balance Sheet" := CreateUniqueFinancialReportName(BalanceSheetCodeTxt)
            else
                GeneralLedgerSetup."Fin. Rep. for Balance Sheet" := CreateUniqueFinancialReportName(GeneralLedgerSetup."Fin. Rep. for Balance Sheet");
            CreateAccountScheduleForBalanceSheet := true;
        end;

        if (GeneralLedgerSetup."Fin. Rep. for Income Stmt." = '') or ForceCreateAccountSchedule then begin
            if GeneralLedgerSetup."Fin. Rep. for Income Stmt." = '' then
                GeneralLedgerSetup."Fin. Rep. for Income Stmt." := CreateUniqueFinancialReportName(IncomeStmdCodeTxt)
            else
                GeneralLedgerSetup."Fin. Rep. for Income Stmt." := CreateUniqueFinancialReportName(GeneralLedgerSetup."Fin. Rep. for Income Stmt.");
            CreateAccountScheduleForIncomeStatement := true;
        end;

        if (GeneralLedgerSetup."Fin. Rep. for Cash Flow Stmt" = '') or ForceCreateAccountSchedule then begin
            if GeneralLedgerSetup."Fin. Rep. for Cash Flow Stmt" = '' then
                GeneralLedgerSetup."Fin. Rep. for Cash Flow Stmt" := CreateUniqueFinancialReportName(CashFlowCodeTxt)
            else
                GeneralLedgerSetup."Fin. Rep. for Cash Flow Stmt" := CreateUniqueFinancialReportName(GeneralLedgerSetup."Fin. Rep. for Cash Flow Stmt");
            CreateAccountScheduleForCashFlowStatement := true;
        end;

        if (GeneralLedgerSetup."Fin. Rep. for Retained Earn." = '') or ForceCreateAccountSchedule then begin
            if GeneralLedgerSetup."Fin. Rep. for Retained Earn." = '' then
                GeneralLedgerSetup."Fin. Rep. for Retained Earn." := CreateUniqueFinancialReportName(RetainedEarnCodeTxt)
            else
                GeneralLedgerSetup."Fin. Rep. for Retained Earn." := CreateUniqueFinancialReportName(GeneralLedgerSetup."Fin. Rep. for Retained Earn.");
            CreateAccountScheduleForRetainedEarnings := true;
        end;

        GeneralLedgerSetup.Modify();

        AddColumnLayout(GeneralLedgerSetup."Fin. Rep. Bal. Sheet Column", BalanceColumnDescTxt, true);
        AddColumnLayout(GeneralLedgerSetup."Fin. Rep. Net Change Column", NetChangeColumnDescTxt, false);

        AddAccountSchedule(GeneralLedgerSetup."Fin. Rep. Bal. Sheet Row", BalanceSheetDescTxt);
        AddAccountSchedule(GeneralLedgerSetup."Fin. Rep. Income Stmt. Row", IncomeStmdDescTxt);
        AddAccountSchedule(GeneralLedgerSetup."Fin. Rep. Cash Flow Stmt. Row", CashFlowDescTxt);
        AddAccountSchedule(GeneralLedgerSetup."Fin. Rep. Retained Earn. Row", RetainedEarnDescTxt);

        AddFinancialReport(GeneralLedgerSetup."Fin. Rep. for Balance Sheet", BalanceSheetDescTxt, GeneralLedgerSetup."Fin. Rep. Bal. Sheet Row", GeneralLedgerSetup."Fin. Rep. Bal. Sheet Column");
        AddFinancialReport(GeneralLedgerSetup."Fin. Rep. for Income Stmt.", IncomeStmdDescTxt, GeneralLedgerSetup."Fin. Rep. Income Stmt. Row", GeneralLedgerSetup."Fin. Rep. Net Change Column");
        AddFinancialReport(GeneralLedgerSetup."Fin. Rep. for Cash Flow Stmt", CashFlowDescTxt, GeneralLedgerSetup."Fin. Rep. Cash Flow Stmt. Row", GeneralLedgerSetup."Fin. Rep. Net Change Column");
        AddFinancialReport(GeneralLedgerSetup."Fin. Rep. for Retained Earn.", RetainedEarnDescTxt, GeneralLedgerSetup."Fin. Rep. Retained Earn. Row", GeneralLedgerSetup."Fin. Rep. Net Change Column");
    end;

    local procedure AddFinancialReport(Name: Code[10]; Description: Text[80]; RowGroupCode: Code[10]; ColumnGroupCode: Code[10])
    var
        FinancialReport: Record "Financial Report";
    begin
        if FinancialReport.Get(Name) then
            UpdateFinancialReport(FinancialReport, RowGroupCode, ColumnGroupCode)
        else begin
            FinancialReport.Init();
            FinancialReport.Name := Name;
            FinancialReport.Description := Description;
            FinancialReport."Internal Description" := GeneratedFromGLAccountCategoriesPageTxt;
            FinancialReport."Financial Report Row Group" := RowGroupCode;
            FinancialReport."Financial Report Column Group" := ColumnGroupCode;
            FinancialReport.Insert();
        end;
    end;

    local procedure UpdateFinancialReport(var FinancialReport: Record "Financial Report"; RowGroupCode: Code[10]; ColumnGroupCode: Code[10])
    begin
        if ForceCreateAccountSchedule then
            if (FinancialReport."Financial Report Row Group" <> RowGroupCode) or (FinancialReport."Financial Report Column Group" <> ColumnGroupCode) then begin
                FinancialReport."Internal Description" := GeneratedFromGLAccountCategoriesPageTxt;
                FinancialReport."Financial Report Row Group" := RowGroupCode;
                FinancialReport."Financial Report Column Group" := ColumnGroupCode;
                FinancialReport.Modify();
            end;
    end;

    local procedure AddAccountSchedule(NewName: Code[10]; NewDescription: Text[80])
    var
        AccScheduleName: Record "Acc. Schedule Name";
        InternalDescriptionLbl: Label 'Generated from the G/L Account Categories page.', MaxLength = 250;
    begin
        if AccScheduleName.Get(NewName) then
            exit;
        AccScheduleName.Init();
        AccScheduleName.Name := NewName;
        AccScheduleName.Description := NewDescription;
        AccScheduleName."Internal Description" := InternalDescriptionLbl;
        AccScheduleName.Insert();
    end;

    local procedure AddColumnLayout(NewName: Code[10]; NewDescription: Text[80]; IsBalance: Boolean)
    var
        ColumnLayoutName: Record "Column Layout Name";
        ColumnLayout: Record "Column Layout";
    begin
        if ColumnLayoutName.Get(NewName) then
            exit;
        ColumnLayoutName.Init();
        ColumnLayoutName.Name := NewName;
        ColumnLayoutName.Description := NewDescription;
        ColumnLayoutName."Internal Description" := GeneratedFromGLAccountCategoriesPageTxt;
        ColumnLayoutName.Insert();

        ColumnLayout.Init();
        ColumnLayout."Column Layout Name" := NewName;
        ColumnLayout."Line No." := 10000;
        ColumnLayout."Column Header" := CopyStr(NewDescription, 1, MaxStrLen(ColumnLayout."Column Header"));
        if IsBalance then
            ColumnLayout."Column Type" := ColumnLayout."Column Type"::"Balance at Date"
        else
            ColumnLayout."Column Type" := ColumnLayout."Column Type"::"Net Change";
        ColumnLayout.Insert();
    end;

    procedure GetGLSetup(var GeneralLedgerSetup: Record "General Ledger Setup")
    var
        CategGenerateAccSchedules: Codeunit "Categ. Generate Acc. Schedules";
    begin
        GeneralLedgerSetup.Get();
        if AnyAccSchedSetupMissing(GeneralLedgerSetup) then begin
            InitializeStandardAccountSchedules();
            GeneralLedgerSetup.Get();
            if AnyAccSchedSetupMissing(GeneralLedgerSetup) then
                Error(MissingSetupErr, GeneralLedgerSetup.FieldCaption("Fin. Rep. for Balance Sheet"), GeneralLedgerSetup.TableCaption());
            Commit();

            if CreateAccountScheduleForBalanceSheet then begin
                CategGenerateAccSchedules.CreateBalanceSheet();
                CreateAccountScheduleForBalanceSheet := false;
            end;

            if CreateAccountScheduleForCashFlowStatement then begin
                CategGenerateAccSchedules.CreateCashFlowStatement();
                CreateAccountScheduleForCashFlowStatement := false;
            end;

            if CreateAccountScheduleForIncomeStatement then begin
                CategGenerateAccSchedules.CreateIncomeStatement();
                CreateAccountScheduleForIncomeStatement := false;
            end;

            if CreateAccountScheduleForRetainedEarnings then begin
                CategGenerateAccSchedules.CreateRetainedEarningsStatement();
                CreateAccountScheduleForRetainedEarnings := false;
            end;
            Commit();
        end;
    end;

    local procedure CreateUniqueFinancialReportName(SuggestedName: Code[10]): Code[10]
    var
        FinancialReport: Record "Financial Report";
        i: Integer;
    begin
        i := 0;
        while FinancialReport.Get(SuggestedName) and (i < 1000) do
            SuggestedName := GenerateNextName(SuggestedName, i);
        exit(SuggestedName);
    end;

    local procedure CreateUniqueAccSchedName(SuggestedName: Code[10]): Code[10]
    var
        AccScheduleName: Record "Acc. Schedule Name";
        i: Integer;
    begin
        i := 0;
        while AccScheduleName.Get(SuggestedName) and (i < 1000) do
            SuggestedName := GenerateNextName(SuggestedName, i);
        exit(SuggestedName);
    end;

    local procedure CreateUniqueColumnLayoutName(SuggestedName: Code[10]): Code[10]
    var
        ColumnLayoutName: Record "Column Layout Name";
        i: Integer;
    begin
        i := 0;
        while ColumnLayoutName.Get(SuggestedName) and (i < 1000) do
            SuggestedName := GenerateNextName(SuggestedName, i);
        exit(SuggestedName);
    end;

    local procedure GenerateNextName(SuggestedName: Code[10]; var i: Integer): Code[10]
    var
        NumPart: Code[3];
    begin
        i += 1;
        NumPart := CopyStr(Format(i), 1, MaxStrLen(NumPart));
        exit(CopyStr(SuggestedName, 1, MaxStrLen(SuggestedName) - StrLen(NumPart)) + NumPart);
    end;

    procedure RunAccountScheduleReport(FinancialReportName: Code[10])
    var
        AccountSchedule: Report "Account Schedule";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOnRunAccountScheduleReport(FinancialReportName, IsHandled);
        if IsHandled then
            exit;

        AccountSchedule.InitAccSched();
        AccountSchedule.SetFinancialReportNameNonEditable(FinancialReportName);
        AccountSchedule.Run();
    end;

    procedure ConfirmAndRunGenerateAccountSchedules()
    var
        FinancialReportMgt: Codeunit "Financial Report Mgt.";
    begin
        FinancialReportMgt.Initialize();
        if GLSetupAllAccScheduleNamesNotDefined() then begin
            Codeunit.Run(Codeunit::"Categ. Generate Acc. Schedules");
            exit;
        end;

        case StrMenu(GenerateAccountSchedulesOptionsTxt, 1, OverwriteConfirmationQst) of
            1:
                begin
                    ForceInitializeStandardAccountSchedules();
                    Codeunit.Run(Codeunit::"Categ. Generate Acc. Schedules");
                end;
            2:
                Codeunit.Run(Codeunit::"Categ. Generate Acc. Schedules");
        end;
    end;

    local procedure AnyAccSchedSetupMissing(var GeneralLedgerSetup: Record "General Ledger Setup"): Boolean
    var
        FinancialReport: Record "Financial Report";
    begin
        if (GeneralLedgerSetup."Fin. Rep. for Balance Sheet" = '') or
           (GeneralLedgerSetup."Fin. Rep. for Cash Flow Stmt" = '') or
           (GeneralLedgerSetup."Fin. Rep. for Income Stmt." = '') or
           (GeneralLedgerSetup."Fin. Rep. for Retained Earn." = '')
        then
            exit(true);
        FinancialReport.Get(GeneralLedgerSetup."Fin. Rep. for Balance Sheet");
        if FinancialReport."Financial Report Row Group" = '' then
            exit(true);
        FinancialReport.Get(GeneralLedgerSetup."Fin. Rep. for Cash Flow Stmt");
        if FinancialReport."Financial Report Row Group" = '' then
            exit(true);
        FinancialReport.Get(GeneralLedgerSetup."Fin. Rep. for Income Stmt.");
        if FinancialReport."Financial Report Row Group" = '' then
            exit(true);
        FinancialReport.Get(GeneralLedgerSetup."Fin. Rep. for Retained Earn.");
        if FinancialReport."Financial Report Row Group" = '' then
            exit(true);
        exit(false);
    end;

    procedure GLSetupAllAccScheduleNamesNotDefined(): Boolean
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        exit(
            (GeneralLedgerSetup."Fin. Rep. for Balance Sheet" = '') and
           (GeneralLedgerSetup."Fin. Rep. for Cash Flow Stmt" = '') and
           (GeneralLedgerSetup."Fin. Rep. for Income Stmt." = '') and
           (GeneralLedgerSetup."Fin. Rep. for Retained Earn." = ''));
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Company-Initialize", 'OnCompanyInitialize', '', false, false)]
    local procedure OnInitializeCompany()
    var
        GLAccountCategory: Record "G/L Account Category";
    begin
        if not GLAccountCategory.IsEmpty() then
            exit;

        OnBeforeInitializeCompany();

        InitializeAccountCategories();
        CODEUNIT.Run(CODEUNIT::"Categ. Generate Acc. Schedules");

        OnAfterInitializeCompany();
    end;

    procedure GetCurrentAssets(): Text
    begin
        exit(CurrentAssetsTxt);
    end;

    procedure GetAR(): Text
    begin
        exit(ARTxt);
    end;

    procedure GetCash(): Text
    begin
        exit(CashTxt);
    end;

    procedure GetPrepaidExpenses(): Text
    begin
        exit(PrepaidExpensesTxt);
    end;

    procedure GetInventory(): Text
    begin
        exit(InventoryTxt);
    end;

    procedure GetFixedAssets(): Text
    begin
        exit(FixedAssetsTxt);
    end;

    procedure GetEquipment(): Text
    begin
        exit(EquipementTxt);
    end;

    procedure GetAccumDeprec(): Text
    begin
        exit(AccumDeprecTxt);
    end;

    procedure GetCurrentLiabilities(): Text
    begin
        exit(CurrentLiabilitiesTxt);
    end;

    procedure GetPayrollLiabilities(): Text
    begin
        exit(PayrollLiabilitiesTxt);
    end;

    procedure GetLongTermLiabilities(): Text
    begin
        exit(LongTermLiabilitiesTxt);
    end;

    procedure GetCommonStock(): Text
    begin
        exit(CommonStockTxt);
    end;

    procedure GetRetEarnings(): Text
    begin
        exit(RetEarningsTxt);
    end;

    procedure GetDistrToShareholders(): Text
    begin
        exit(DistrToShareholdersTxt);
    end;

    procedure GetIncomeService(): Text
    begin
        exit(IncomeServiceTxt);
    end;

    procedure GetIncomeProdSales(): Text
    begin
        exit(IncomeProdSalesTxt);
    end;

    procedure GetIncomeSalesDiscounts(): Text
    begin
        exit(IncomeSalesDiscountsTxt);
    end;

    procedure GetIncomeSalesReturns(): Text
    begin
        exit(IncomeSalesReturnsTxt);
    end;

    procedure GetIncomeInterest(): Text
    begin
        exit(IncomeInterestTxt);
    end;

    procedure GetCOGSLabor(): Text
    begin
        exit(COGSLaborTxt);
    end;

    procedure GetCOGSMaterials(): Text
    begin
        exit(COGSMaterialsTxt);
    end;

    procedure GetCOGSDiscountsGranted(): Text
    begin
        exit(COGSDiscountsGrantedTxt);
    end;

    procedure GetRentExpense(): Text
    begin
        exit(RentExpenseTxt);
    end;

    procedure GetAdvertisingExpense(): Text
    begin
        exit(AdvertisingExpenseTxt);
    end;

    procedure GetInterestExpense(): Text
    begin
        exit(InterestExpenseTxt);
    end;

    procedure GetFeesExpense(): Text
    begin
        exit(FeesExpenseTxt);
    end;

    procedure GetInsuranceExpense(): Text
    begin
        exit(InsuranceExpenseTxt);
    end;

    procedure GetPayrollExpense(): Text
    begin
        exit(PayrollExpenseTxt);
    end;

    procedure GetBenefitsExpense(): Text
    begin
        exit(BenefitsExpenseTxt);
    end;

    procedure GetRepairsExpense(): Text
    begin
        exit(RepairsTxt);
    end;

    procedure GetUtilitiesExpense(): Text
    begin
        exit(UtilitiesExpenseTxt);
    end;

    procedure GetOtherIncomeExpense(): Text
    begin
        exit(OtherIncomeExpenseTxt);
    end;

    procedure GetTaxExpense(): Text
    begin
        exit(TaxExpenseTxt);
    end;

    procedure GetTravelExpense(): Text
    begin
        exit(TravelExpenseTxt);
    end;

    procedure GetVehicleExpenses(): Text
    begin
        exit(VehicleExpensesTxt);
    end;

    procedure GetBadDebtExpense(): Text
    begin
        exit(BadDebtExpenseTxt);
    end;

    procedure GetSalariesExpense(): Text
    begin
        exit(SalariesExpenseTxt);
    end;

    procedure GetJobsCost(): Text
    begin
        exit(JobsCostTxt);
    end;

    procedure GetIncomeJobs(): Text
    begin
        exit(IncomeJobsTxt);
    end;

    procedure GetJobSalesContra(): Text
    begin
        exit(JobSalesContraTxt);
    end;

    procedure GetAccountCategory(var GLAccountCategory: Record "G/L Account Category"; Category: Option): Boolean
    begin
        GLAccountCategory.SetRange("Account Category", Category);
        GLAccountCategory.SetRange("Parent Entry No.", 0);
        exit(GLAccountCategory.FindFirst());
    end;

    procedure GetAccountSubcategory(var GLAccountCategory: Record "G/L Account Category"; Category: Option; Description: Text): Boolean
    begin
        GLAccountCategory.SetRange("Account Category", Category);
        GLAccountCategory.SetFilter("Parent Entry No.", '<>%1', 0);
        GLAccountCategory.SetRange(Description, Description);
        exit(GLAccountCategory.FindFirst());
    end;

    procedure GetSubcategoryEntryNo(Category: Option; SubcategoryDescription: Text): Integer
    var
        GLAccountCategory: Record "G/L Account Category";
    begin
        GLAccountCategory.SetRange("Account Category", Category);
        GLAccountCategory.SetRange(Description, SubcategoryDescription);
        if GLAccountCategory.FindFirst() then
            exit(GLAccountCategory."Entry No.");
    end;

    procedure CheckGLAccount(AccNo: Code[20]; CheckProdPostingGroup: Boolean; CheckDirectPosting: Boolean; AccountCategory: Option; AccountSubcategory: Text)
    begin
        CheckGLAccount(0, 0, AccNo, CheckProdPostingGroup, CheckDirectPosting, AccountCategory, AccountSubcategory);
    end;

    procedure CheckGLAccount(TableNo: Integer; FieldNo: Integer; AccNo: Code[20]; CheckProdPostingGroup: Boolean; CheckDirectPosting: Boolean; AccountCategory: Option; AccountSubcategory: Text)
    var
        GLAcc: Record "G/L Account";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckGLAccount(TableNo, FieldNo, AccNo, CheckProdPostingGroup, CheckDirectPosting, AccountCategory, AccountSubcategory, IsHandled);
        if IsHandled then
            exit;

        if AccNo = '' then
            exit;

        GLAcc.Get(AccNo);
        GLAcc.CheckGLAcc();
        if CheckProdPostingGroup then
            GLAcc.TestField("Gen. Prod. Posting Group");
        if CheckDirectPosting then
            GLAcc.TestField("Direct Posting", true);
        if GLAcc."Account Category" = GLAcc."Account Category"::" " then begin
            GLAcc.Validate("Account Category", AccountCategory);
            if AccountSubcategory <> '' then
                GLAcc.Validate("Account Subcategory Entry No.", GetSubcategoryEntryNo(AccountCategory, AccountSubcategory));
            GLAcc.Modify();
        end;
    end;

    procedure CheckGLAccountWithoutCategory(AccNo: Code[20]; CheckProdPostingGroup: Boolean; CheckDirectPosting: Boolean)
    var
        OptionValueOutOfRange: Integer;
    begin
        OptionValueOutOfRange := -1;
        CheckGLAccount(AccNo, CheckProdPostingGroup, CheckDirectPosting, OptionValueOutOfRange, '');
    end;

    procedure LookupGLAccount(var AccountNo: Code[20]; AccountCategory: Option; AccountSubcategoryFilter: Text)
    begin
        LookupGLAccount(0, 0, AccountNo, AccountCategory, AccountSubcategoryFilter);
    end;

    procedure LookupGLAccount(TableNo: Integer; FieldNo: Integer; var AccountNo: Code[20]; AccountCategory: Option; AccountSubcategoryFilter: Text)
    var
        GLAccount: Record "G/L Account";
        GLAccountCategory: Record "G/L Account Category";
        GLAccountList: Page "G/L Account List";
        EntryNoFilter: Text;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeLookupGLAccount(TableNo, FieldNo, AccountNo, AccountCategory, AccountSubcategoryFilter, IsHandled);
        if IsHandled then
            exit;

        GLAccount.Reset();
        GLAccount.SetRange("Account Type", GLAccount."Account Type"::Posting);
        GLAccountCategory.SetRange("Account Category", AccountCategory);
        GLAccountCategory.SetFilter(Description, AccountSubcategoryFilter);
        if not GLAccountCategory.IsEmpty() then begin
            EntryNoFilter := '';
            GLAccountCategory.FindSet();
            repeat
                EntryNoFilter := EntryNoFilter + Format(GLAccountCategory."Entry No.") + '|';
            until GLAccountCategory.Next() = 0;
            EntryNoFilter := CopyStr(EntryNoFilter, 1, StrLen(EntryNoFilter) - 1);
            GLAccount.SetRange("Account Category", GLAccountCategory."Account Category");
            GLAccount.SetFilter("Account Subcategory Entry No.", EntryNoFilter);
            if not GLAccount.FindFirst() then begin
                GLAccount.SetRange("Account Category", 0);
                GLAccount.SetRange("Account Subcategory Entry No.", 0);
            end;
        end;
        GLAccountList.SetTableView(GLAccount);
        GLAccountList.LookupMode(true);
        if AccountNo <> '' then
            if GLAccount.Get(AccountNo) then
                GLAccountList.SetRecord(GLAccount);
        if GLAccountList.RunModal() = ACTION::LookupOK then begin
            GLAccountList.GetRecord(GLAccount);
            AccountNo := GLAccount."No.";
        end;
    end;

    procedure LookupGLAccountWithoutCategory(var AccountNo: Code[20])
    var
        GLAccount: Record "G/L Account";
        GLAccountList: Page "G/L Account List";
    begin
        GLAccount.Reset();
        GLAccount.SetRange("Account Type", GLAccount."Account Type"::Posting);
        GLAccountList.SetTableView(GLAccount);
        GLAccountList.LookupMode(true);
        if AccountNo <> '' then
            if GLAccount.Get(AccountNo) then
                GLAccountList.SetRecord(GLAccount);
        if GLAccountList.RunModal() = ACTION::LookupOK then begin
            GLAccountList.GetRecord(GLAccount);
            AccountNo := GLAccount."No.";
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitializeCompany()
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitializeCompany()
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnRunAccountScheduleReport(AccSchedName: Code[10]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitializeAccountCategories(var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckGLAccount(TableNo: Integer; FieldNo: Integer; AccNo: Code[20]; CheckProdPostingGroup: Boolean; CheckDirectPosting: Boolean; var AccountCategory: Option; var AccountSubcategory: Text; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeLookupGLAccount(TableNo: Integer; FieldNo: Integer; var AccountNo: Code[20]; var AccountCategory: Option; var AccountSubcategoryFilter: Text; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitializeAccountCategories()
    begin
    end;
}

