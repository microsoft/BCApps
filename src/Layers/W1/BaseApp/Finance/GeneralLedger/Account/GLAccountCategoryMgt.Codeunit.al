// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Account;

using Microsoft.Finance.FinancialReports;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Company;

/// <summary>
/// Manages general ledger account categorization system and automatic financial statement generation.
/// Provides functionality for account category initialization, financial report structure creation, and category-based reporting.
/// </summary>
/// <remarks>
/// Key functions: Account category setup, financial report generation, balance sheet and income statement structure creation.
/// Used during company initialization and when setting up financial reporting requirements.
/// Integrates with Financial Reports framework for automated statement generation based on account categories.
/// </remarks>
codeunit 570 "G/L Account Category Mgt."
{

    trigger OnRun()
    begin
        InitializeAccountCategories();
    end;

    var
        BalanceColumnNameTxt: Label 'M-BALANCE', Comment = 'Max 10 char';
        BalanceColumnDescTxt: Label 'Balance', Comment = 'Max 10 char';
        BalanceColumnInternalDescTxt: Label 'Single-column layout showing balance-at-date using ledger net amounts. Useful for point-in-time balances, financial position, reconciliations, and snapshot reporting of assets, liabilities, or equity.', MaxLength = 210;
        NetChangeColumnNameTxt: Label 'M-NETCHANG', Comment = 'Max 10 char';
        NetChangeColumnDescTxt: Label 'Net Change', Comment = 'Max 10 char';
        NetChangeColumnInternalDescTxt: Label 'Single-column layout showing period net change from ledger entries (Net Amount). Useful for reporting activity, income statement movements, variance analysis, and tracking transaction-driven account changes.', MaxLength = 210;
        BalanceSheetCodeTxt: Label 'M-BALANCE', Comment = 'Max 10 char';
        BalanceSheetDescTxt: Label 'Balance Sheet', Comment = 'Max 80 chars';
        BalanceSheetFinReportInternalDescTxt: Label 'Presents a balance sheet layout based on account categories, covering current and fixed assets, liabilities, and equity. Includes subrows for cash, receivables, inventory, prepaid expenses, equipment, depreciation, payroll liabilities, and shareholder distributions, with totals and balancing checks. Shows a single-column balance as of a specific date. Generated from G/L Account Categories.', MaxLength = 500;
        IncomeStmdCodeTxt: Label 'M-INCOME', Comment = 'Max 10 chars';
        IncomeStmdDescTxt: Label 'Income Statement', Comment = 'Max 80 chars';
        IncomeStmdFinReportInternalDescTxt: Label 'Displays a simple income statement layout structured into income, cost of goods sold, and expenses, with formulas for gross profit and net income to deliver clear profitability metrics. Organizes revenue streams, direct costs, and operating expenses for accurate performance tracking. Uses a single column showing net change for the selected period. Useful for profit analysis, budgeting, and evaluating operational efficiency across reporting periods. Generated from G/L Account Categories.', MaxLength = 500;
        CashFlowCodeTxt: Label 'M-CASHFLOW', Comment = 'Max 10 chars';
        CashFlowDescTxt: Label 'Cash Flow Statement', Comment = 'Max 80 chars';
        CashFlowFinReportInternalDescTxt: Label 'Structures a cash flow statement with operating, investing, and financing sections, including detailed groupings and formulas for net cash flows. Reconciles net income with cash movements, tracks changes in receivables, liabilities, and equity, and calculates period-end cash for liquidity analysis. Shows net change in a single column for the selected period. Generated from G/L Account Categories.', MaxLength = 500;
        RetainedEarnCodeTxt: Label 'M-RETAIND', Comment = 'Max 10 char.';
        RetainedEarnDescTxt: Label 'Retained Earnings', Comment = 'Max 80 chars';
        RetainedEarnFinReportInternalDescTxt: Label 'Tracks retained earnings across periods with a seven-row layout, using formulas to combine beginning balance, net income, and shareholder distributions for accurate equity movement. Calculates changes over time to show accumulated profits after dividends. Uses a single column showing net change for the selected period. Useful for equity reconciliation, assessing financial position, and preparing statements of changes in equity. Generated from G/L Account Categories.', MaxLength = 500;
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
        DraftCodeTxt: Label 'DRAFT', Locked = true, MaxLength = 10;
        DraftNameTxt: Label 'Draft', MaxLength = 50;
        DraftDescTxt: Label 'Report is under development and not available to users', MaxLength = 100;
        ActiveCodeTxt: Label 'ACTIVE', Locked = true, MaxLength = 10;
        ActiveNameTxt: Label 'Active', MaxLength = 50;
        ActiveDescTxt: Label 'Report has been tested and is available to users', MaxLength = 100;
        RetiredCodeTxt: Label 'RETIRED', Locked = true, MaxLength = 10;
        RetiredNameTxt: Label 'Retired', MaxLength = 50;
        RetiredDescTxt: Label 'Report is phased out and no longer available', MaxLength = 100;
        GeneratedFromGLAccountCategoriesPageTxt: Label 'Generated from G/L Account Categories.', MaxLength = 40;
        ProfitabilityCatCodeTxt: Label 'PROFITABILITY', MaxLength = 20;
        ProfitabilityCatNameTxt: Label 'Profitability', MaxLength = 100;
        ProfitabilityCatDescTxt: Label 'Reports that measure income, margins, and overall profitability. Example reports could be Income Statement, Gross Margin Analysis', MaxLength = 250;
        BalanceSheetCatCodeTxt: Label 'BALANCE SHEET', MaxLength = 20;
        BalanceSheetCatNameTxt: Label 'Balance Sheet & Position', MaxLength = 100;
        BalanceSheetCatDescTxt: Label 'Shows financial position at a specific point in time. Example reports could be Balance Sheet, Working Capital Analysis', MaxLength = 250;
        CashFlowCatCodeTxt: Label 'CASHFLOW', MaxLength = 20;
        CashFlowCatNameTxt: Label 'Cash Flow', MaxLength = 100;
        CashFlowCatDescTxt: Label 'Reports tracking cash inflows and outflows for liquidity management. Example reports could be Cash Flow Statement, Liquidity Analysis', MaxLength = 250;
        BudgetingCatCodeTxt: Label 'BUDGET & FORECAST', MaxLength = 20;
        BudgetingCatNameTxt: Label 'Budgeting & Forecasting', MaxLength = 100;
        BudgetingCatDescTxt: Label 'Compares actuals to budgets and projects future performance. Example reports could be Budget vs Actual, Variance Analysis', MaxLength = 250;
        RevenueAnalysisCatCodeTxt: Label 'REVENUE ANALYSIS', MaxLength = 20;
        RevenueAnalysisCatNameTxt: Label 'Revenue Analysis', MaxLength = 100;
        RevenueAnalysisCatDescTxt: Label 'Analyzes revenue streams by product, region, or customer. Example reports could be Sales by Dimension, Deferred Revenue Schedule', MaxLength = 250;
        ExpenseAnalysisCatCodeTxt: Label 'EXPENSE ANALYSIS', MaxLength = 20;
        ExpenseAnalysisCatNameTxt: Label 'Expense Analysis', MaxLength = 100;
        ExpenseAnalysisCatDescTxt: Label 'Breaks down operating expenses and departmental spending. Example reports could be Departmental Spend, Operating Expense Breakdown', MaxLength = 250;
        AssetsLiabilitiesCatCodeTxt: Label 'ASSETS & LIABLE', MaxLength = 20;
        AssetsLiabilitiesCatNameTxt: Label 'Assets & Liabilities', MaxLength = 100;
        AssetsLiabilitiesCatDescTxt: Label 'Tracks fixed assets, depreciation, loans, and obligations. Example reports could be Fixed Asset Depreciation, Loan & Debt Report', MaxLength = 250;
        EquityCapitalCatCodeTxt: Label 'EQUITY & CAPITAL', MaxLength = 20;
        EquityCapitalCatNameTxt: Label 'Equity & Capital', MaxLength = 100;
        EquityCapitalCatDescTxt: Label 'Reports on shareholder equity and capital structure changes. Example reports could be Retained Earnings Movement, Capital Structure Analysis', MaxLength = 250;
        ComplianceAuditCatCodeTxt: Label 'COMPLIANCE & AUDIT', MaxLength = 20;
        ComplianceAuditCatNameTxt: Label 'Compliance & Audit', MaxLength = 100;
        ComplianceAuditCatDescTxt: Label 'Ensures regulatory compliance and provides audit trails. Example reports could be Audit Trail, SOX Compliance Snapshot', MaxLength = 250;
        InventoryCostingCatCodeTxt: Label 'INVENTORY & COSTING', MaxLength = 20;
        InventoryCostingCatNameTxt: Label 'Inventory & Costing', MaxLength = 100;
        InventoryCostingCatDescTxt: Label 'Valuates inventory and analyzes cost of goods sold. Example reports could be Inventory Valuation, COGS Analysis', MaxLength = 250;
        ProjectJobCostingCatCodeTxt: Label 'PROJECTS & COSTING', MaxLength = 20;
        ProjectJobCostingCatNameTxt: Label 'Project & Job Costing', MaxLength = 100;
        ProjectJobCostingCatDescTxt: Label 'Measures profitability and costs for projects and jobs. Example reports could be Project Profitability, WIP Report', MaxLength = 250;
        PerformanceMetricsCatCodeTxt: Label 'PERFORMANCE', MaxLength = 20;
        PerformanceMetricsCatNameTxt: Label 'Performance Metrics', MaxLength = 100;
        PerformanceMetricsCatDescTxt: Label 'Provides KPIs and financial ratios for performance tracking. Example reports could be KPI Dashboard, Financial Ratios', MaxLength = 250;
        PeriodEndClosingCatCodeTxt: Label 'PERIOD-END & CLOSING', MaxLength = 20;
        PeriodEndClosingCatNameTxt: Label 'Period-End & Closing', MaxLength = 100;
        PeriodEndClosingCatDescTxt: Label 'Summarizes trial balances and closing entries for period-end. Example reports could be Trial Balance, Closing Entries Summary', MaxLength = 250;
        CreateAccountScheduleForBalanceSheet: Boolean;
        CreateAccountScheduleForIncomeStatement: Boolean;
        CreateAccountScheduleForCashFlowStatement: Boolean;
        CreateAccountScheduleForRetainedEarnings: Boolean;
        ForceCreateAccountSchedule: Boolean;

    /// <summary>
    /// Creates the complete hierarchy of standard G/L account categories and subcategories for financial reporting.
    /// Initializes categories for Assets, Liabilities, Equity, Income, and Cost of Goods Sold with detailed subcategories.
    /// </summary>
    /// <remarks>
    /// Called during company setup or when account categories need to be reset.
    /// Creates both high-level categories and detailed subcategories for comprehensive financial reporting.
    /// Assigns cash flow activity classifications to categories for cash flow statement generation.
    /// </remarks>
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

    /// <summary>
    /// Creates a new general ledger account category with specified hierarchical position and properties.
    /// Inserts the category at the specified position in the category tree and updates presentation order.
    /// </summary>
    /// <param name="InsertAfterEntryNo">Entry number of the category to insert after, or 0 for end of list</param>
    /// <param name="ParentEntryNo">Entry number of the parent category for hierarchical structure</param>
    /// <param name="AccountCategory">Primary account category classification (Assets, Liabilities, etc.)</param>
    /// <param name="NewDescription">Descriptive text for the new category</param>
    /// <param name="SystemGenerated">Indicates if this is a system-generated category that cannot be modified by users</param>
    /// <param name="CashFlowActivity">Cash flow statement activity classification for the category</param>
    /// <returns>Entry number of the newly created account category</returns>
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

    /// <summary>
    /// Forces recreation of standard account schedules even if they already exist.
    /// Used when account schedules need to be reset or updated with new standard definitions.
    /// </summary>
    procedure ForceInitializeStandardAccountSchedules()
    begin
        ForceCreateAccountSchedule := true;
        InitializeStandardAccountSchedules();
    end;

    /// <summary>
    /// Creates standard financial report structures including Balance Sheet, Income Statement, Cash Flow, and Retained Earnings.
    /// Generates account schedules and column layouts based on account categories for automated financial reporting.
    /// </summary>
    /// <remarks>
    /// Creates Financial Reports with associated row and column definitions.
    /// Updates General Ledger Setup with references to the created financial reports.
    /// Only creates reports that don't already exist unless forced recreation is specified.
    /// </remarks>
    procedure InitializeStandardAccountSchedules()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        FinancialReportStatus: Record "Financial Report Status";
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

        if FinancialReportStatus.IsEmpty() and (GeneralLedgerSetup.DefaultFinancialReportStatus = '') then
            GeneralLedgerSetup.DefaultFinancialReportStatus := DraftCodeTxt;

        GeneralLedgerSetup.Modify();

        AddFinancialReportStatus(DraftCodeTxt, DraftNameTxt, DraftDescTxt, true);
        AddFinancialReportStatus(ActiveCodeTxt, ActiveNameTxt, ActiveDescTxt, false);
        AddFinancialReportStatus(RetiredCodeTxt, RetiredNameTxt, RetiredDescTxt, true);

        AddColumnLayout(GeneralLedgerSetup."Fin. Rep. Bal. Sheet Column", BalanceColumnDescTxt, true, StrSubstNo('%1 %2', GeneratedFromGLAccountCategoriesPageTxt, BalanceColumnInternalDescTxt));
        AddColumnLayout(GeneralLedgerSetup."Fin. Rep. Net Change Column", NetChangeColumnDescTxt, false, StrSubstNo('%1 %2', GeneratedFromGLAccountCategoriesPageTxt, NetChangeColumnInternalDescTxt));

        AddAccountSchedule(GeneralLedgerSetup."Fin. Rep. Bal. Sheet Row", BalanceSheetDescTxt);
        AddAccountSchedule(GeneralLedgerSetup."Fin. Rep. Income Stmt. Row", IncomeStmdDescTxt);
        AddAccountSchedule(GeneralLedgerSetup."Fin. Rep. Cash Flow Stmt. Row", CashFlowDescTxt);
        AddAccountSchedule(GeneralLedgerSetup."Fin. Rep. Retained Earn. Row", RetainedEarnDescTxt);

        AddFinancialReportCategory(ProfitabilityCatCodeTxt, ProfitabilityCatNameTxt, ProfitabilityCatDescTxt);
        AddFinancialReportCategory(BalanceSheetCatCodeTxt, BalanceSheetCatNameTxt, BalanceSheetCatDescTxt);
        AddFinancialReportCategory(CashFlowCatCodeTxt, CashFlowCatNameTxt, CashFlowCatDescTxt);
        AddFinancialReportCategory(BudgetingCatCodeTxt, BudgetingCatNameTxt, BudgetingCatDescTxt);
        AddFinancialReportCategory(RevenueAnalysisCatCodeTxt, RevenueAnalysisCatNameTxt, RevenueAnalysisCatDescTxt);
        AddFinancialReportCategory(ExpenseAnalysisCatCodeTxt, ExpenseAnalysisCatNameTxt, ExpenseAnalysisCatDescTxt);
        AddFinancialReportCategory(AssetsLiabilitiesCatCodeTxt, AssetsLiabilitiesCatNameTxt, AssetsLiabilitiesCatDescTxt);
        AddFinancialReportCategory(EquityCapitalCatCodeTxt, EquityCapitalCatNameTxt, EquityCapitalCatDescTxt);
        AddFinancialReportCategory(ComplianceAuditCatCodeTxt, ComplianceAuditCatNameTxt, ComplianceAuditCatDescTxt);
        AddFinancialReportCategory(InventoryCostingCatCodeTxt, InventoryCostingCatNameTxt, InventoryCostingCatDescTxt);
        AddFinancialReportCategory(ProjectJobCostingCatCodeTxt, ProjectJobCostingCatNameTxt, ProjectJobCostingCatDescTxt);
        AddFinancialReportCategory(PerformanceMetricsCatCodeTxt, PerformanceMetricsCatNameTxt, PerformanceMetricsCatDescTxt);
        AddFinancialReportCategory(PeriodEndClosingCatCodeTxt, PeriodEndClosingCatNameTxt, PeriodEndClosingCatDescTxt);

        AddFinancialReport(GeneralLedgerSetup."Fin. Rep. for Balance Sheet", BalanceSheetDescTxt, GeneralLedgerSetup."Fin. Rep. Bal. Sheet Row", GeneralLedgerSetup."Fin. Rep. Bal. Sheet Column", BalanceSheetFinReportInternalDescTxt, BalanceSheetCatCodeTxt, DraftCodeTxt);
        AddFinancialReport(GeneralLedgerSetup."Fin. Rep. for Income Stmt.", IncomeStmdDescTxt, GeneralLedgerSetup."Fin. Rep. Income Stmt. Row", GeneralLedgerSetup."Fin. Rep. Net Change Column", IncomeStmdFinReportInternalDescTxt, ProfitabilityCatCodeTxt, DraftCodeTxt);
        AddFinancialReport(GeneralLedgerSetup."Fin. Rep. for Cash Flow Stmt", CashFlowDescTxt, GeneralLedgerSetup."Fin. Rep. Cash Flow Stmt. Row", GeneralLedgerSetup."Fin. Rep. Net Change Column", CashFlowFinReportInternalDescTxt, CashFlowCatCodeTxt, DraftCodeTxt);
        AddFinancialReport(GeneralLedgerSetup."Fin. Rep. for Retained Earn.", RetainedEarnDescTxt, GeneralLedgerSetup."Fin. Rep. Retained Earn. Row", GeneralLedgerSetup."Fin. Rep. Net Change Column", RetainedEarnFinReportInternalDescTxt, EquityCapitalCatCodeTxt, DraftCodeTxt);
    end;

    local procedure AddFinancialReport(Name: Code[10]; Description: Text[80]; RowGroupCode: Code[10]; ColumnGroupCode: Code[10]; NewInternalDescription: Text[500]; CategoryCode: Code[20]; StatusCode: Code[10])
    var
        FinancialReport: Record "Financial Report";
    begin
        if FinancialReport.Get(Name) then
            UpdateFinancialReport(FinancialReport, RowGroupCode, ColumnGroupCode, NewInternalDescription, CategoryCode)
        else begin
            FinancialReport.Init();
            FinancialReport.Name := Name;
            FinancialReport.Description := Description;
            FinancialReport."Internal Description" := NewInternalDescription;
            FinancialReport."Financial Report Row Group" := RowGroupCode;
            FinancialReport."Financial Report Column Group" := ColumnGroupCode;
            FinancialReport."Internal Description" := NewInternalDescription;
            FinancialReport.CategoryCode := CategoryCode;
            FinancialReport.Status := StatusCode;
            FinancialReport.Insert();
        end;
    end;

    local procedure UpdateFinancialReport(var FinancialReport: Record "Financial Report"; RowGroupCode: Code[10]; ColumnGroupCode: Code[10]; InternalDescription: Text[500]; CategoryCode: Code[20])
    begin
        if ForceCreateAccountSchedule then
            if (FinancialReport."Financial Report Row Group" <> RowGroupCode) or
                (FinancialReport."Financial Report Column Group" <> ColumnGroupCode) or
                (FinancialReport.CategoryCode <> CategoryCode)
            then begin
                FinancialReport."Internal Description" := InternalDescription;
                FinancialReport."Financial Report Row Group" := RowGroupCode;
                FinancialReport."Financial Report Column Group" := ColumnGroupCode;
                FinancialReport.CategoryCode := CategoryCode;
                FinancialReport.Modify();
            end;
    end;

    local procedure AddAccountSchedule(NewName: Code[10]; NewDescription: Text[80])
    var
        AccScheduleName: Record "Acc. Schedule Name";
    begin
        if AccScheduleName.Get(NewName) then
            exit;
        AccScheduleName.Init();
        AccScheduleName.Name := NewName;
        AccScheduleName.Description := NewDescription;
        AccScheduleName."Internal Description" := GeneratedFromGLAccountCategoriesPageTxt;
        AccScheduleName.Insert();
    end;

    local procedure AddColumnLayout(NewName: Code[10]; NewDescription: Text[80]; IsBalance: Boolean; NewInternalDescription: Text[500])
    var
        ColumnLayoutName: Record "Column Layout Name";
        ColumnLayout: Record "Column Layout";
    begin
        if ColumnLayoutName.Get(NewName) then
            exit;
        ColumnLayoutName.Init();
        ColumnLayoutName.Name := NewName;
        ColumnLayoutName.Description := NewDescription;
        ColumnLayoutName."Internal Description" := NewInternalDescription;
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

    local procedure AddFinancialReportCategory(Code: Code[20]; Name: Text[100]; Description: Text[250])
    var
        FinRepCategory: Record "Financial Report Category";
    begin
        if FinRepCategory.Get(Code) then
            exit;
        FinRepCategory.Init();
        FinRepCategory.Code := Code;
        FinRepCategory.Name := Name;
        FinRepCategory.Description := Description;
        FinRepCategory.Insert();
    end;

    local procedure AddFinancialReportStatus(Code: Code[10]; Name: Text[50]; Description: Text[100]; Blocked: Boolean)
    var
        FinancialReportStatus: Record "Financial Report Status";
    begin
        if FinancialReportStatus.Get(Code) then
            exit;
        FinancialReportStatus.Init();
        FinancialReportStatus.Code := Code;
        FinancialReportStatus.Name := Name;
        FinancialReportStatus.Description := Description;
        FinancialReportStatus.Blocked := Blocked;
        FinancialReportStatus.Insert();
    end;

    /// <summary>
    /// Retrieves General Ledger Setup with validation that required financial reports are configured.
    /// Automatically initializes missing financial reports and triggers account schedule generation if needed.
    /// </summary>
    /// <param name="GeneralLedgerSetup">Returns the General Ledger Setup record with verified financial report configuration</param>
    /// <remarks>
    /// Ensures all standard financial reports are available before returning setup.
    /// Creates missing financial reports automatically and runs category-based account schedule generation.
    /// Throws error if financial reports cannot be created or configured properly.
    /// </remarks>
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

    /// <summary>
    /// Executes the account schedule report for the specified financial report configuration.
    /// Opens the Account Schedule report with predefined filters and formatting based on the financial report setup.
    /// </summary>
    /// <param name="FinancialReportName">Code identifying the financial report configuration to run</param>
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

    /// <summary>
    /// Prompts user confirmation and generates missing account schedules for financial reporting.
    /// Initializes financial report management and creates required account schedules if not already defined in setup.
    /// </summary>
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

    /// <summary>
    /// Checks if all required account schedule names are properly defined in General Ledger Setup.
    /// Returns true if any standard financial report configurations are missing from setup.
    /// </summary>
    /// <returns>True if account schedule names are not fully defined, false if all are configured</returns>
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

    /// <summary>
    /// Returns the localized text description for the Current Assets account subcategory.
    /// Used for identifying and filtering current asset accounts in financial reports.
    /// </summary>
    /// <returns>Localized description text for Current Assets subcategory</returns>
    procedure GetCurrentAssets(): Text
    begin
        exit(CurrentAssetsTxt);
    end;

    /// <summary>
    /// Returns the localized text description for the Accounts Receivable account subcategory.
    /// Used for identifying and filtering accounts receivable accounts in financial reports.
    /// </summary>
    /// <returns>Localized description text for Accounts Receivable subcategory</returns>
    procedure GetAR(): Text
    begin
        exit(ARTxt);
    end;

    /// <summary>
    /// Returns the localized text description for the Cash account subcategory.
    /// Used for identifying and filtering cash and cash equivalent accounts in financial reports.
    /// </summary>
    /// <returns>Localized description text for Cash subcategory</returns>
    procedure GetCash(): Text
    begin
        exit(CashTxt);
    end;

    /// <summary>
    /// Returns the localized text description for the Prepaid Expenses account subcategory.
    /// Used for identifying and filtering prepaid expense accounts in financial reports.
    /// </summary>    
    /// <returns>Localized description text for Prepaid Expenses subcategory</returns>
    procedure GetPrepaidExpenses(): Text
    begin
        exit(PrepaidExpensesTxt);
    end;

    /// <summary>
    /// Returns the localized text description for the Inventory account subcategory.
    /// Used for identifying and filtering inventory-related accounts in financial reports.
    /// </summary>
    /// <returns>Localized description text for Inventory subcategory</returns>  
    procedure GetInventory(): Text
    begin
        exit(InventoryTxt);
    end;

    /// <summary>
    /// Returns the localized text description for the Fixed Assets account subcategory.
    /// Used for identifying and filtering fixed asset accounts in financial reports.
    /// </summary>
    /// <returns>Localized description text for Fixed Assets subcategory</returns>
    procedure GetFixedAssets(): Text
    begin
        exit(FixedAssetsTxt);
    end;

    /// <summary>
    /// Returns the localized text description for the Equipment account subcategory.
    /// Used for identifying and filtering equipment-related accounts in financial reports.
    /// </summary>
    /// <returns>Localized description text for Equipment subcategory</returns>
    procedure GetEquipment(): Text
    begin
        exit(EquipementTxt);
    end;

    /// <summary>
    /// Returns the localized text description for the Accumulated Depreciation account subcategory.
    /// Used for identifying and filtering accumulated depreciation accounts in financial reports.
    /// </summary>
    /// <returns>Localized description text for Accumulated Depreciation subcategory</returns>
    procedure GetAccumDeprec(): Text
    begin
        exit(AccumDeprecTxt);
    end;

    /// <summary>
    /// Returns the localized text description for the Current Liabilities account subcategory.
    /// Used for identifying and filtering current liability accounts in financial reports.
    /// </summary>
    /// <returns>Localized description text for Current Liabilities subcategory</returns>
    procedure GetCurrentLiabilities(): Text
    begin
        exit(CurrentLiabilitiesTxt);
    end;

    /// <summary>
    /// Returns the localized text description for the Payroll Liabilities account subcategory.
    /// Used for identifying and filtering payroll-related liability accounts in financial reports.
    /// </summary>
    /// <returns>Localized description text for Payroll Liabilities subcategory</returns>
    procedure GetPayrollLiabilities(): Text
    begin
        exit(PayrollLiabilitiesTxt);
    end;

    /// <summary>
    /// Returns the localized text description for the Long Term Liabilities account subcategory.
    /// Used for identifying and filtering long-term liability accounts in financial reports.
    /// </summary>
    /// <returns>Localized description text for Long Term Liabilities subcategory</returns>
    procedure GetLongTermLiabilities(): Text
    begin
        exit(LongTermLiabilitiesTxt);
    end;

    /// <summary>
    /// Returns the localized text description for the Common Stock account subcategory.
    /// Used for identifying and filtering common stock equity accounts in financial reports.
    /// </summary>
    /// <returns>Localized description text for Common Stock subcategory</returns>
    procedure GetCommonStock(): Text
    begin
        exit(CommonStockTxt);
    end;

    /// <summary>
    /// Returns the localized text description for the Retained Earnings account subcategory.
    /// Used for identifying and filtering retained earnings accounts in financial reports.
    /// </summary>
    /// <returns>Localized description text for Retained Earnings subcategory</returns>
    procedure GetRetEarnings(): Text
    begin
        exit(RetEarningsTxt);
    end;

    /// <summary>
    /// Returns the localized text description for the Distribution to Shareholders account subcategory.
    /// Used for identifying and filtering shareholder distribution accounts in financial reports.
    /// </summary>
    /// <returns>Localized description text for Distribution to Shareholders subcategory</returns>
    procedure GetDistrToShareholders(): Text
    begin
        exit(DistrToShareholdersTxt);
    end;

    /// <summary>
    /// Returns the localized text description for the Service Income account subcategory.
    /// Used for identifying and filtering service revenue accounts in financial reports.
    /// </summary>
    /// <returns>Localized description text for Service Income subcategory</returns>
    procedure GetIncomeService(): Text
    begin
        exit(IncomeServiceTxt);
    end;

    /// <summary>
    /// Returns the localized text description for the Product Sales Income account subcategory.
    /// Used for identifying and filtering product sales revenue accounts in financial reports.
    /// </summary>
    /// <returns>Localized description text for Product Sales Income subcategory</returns>
    procedure GetIncomeProdSales(): Text
    begin
        exit(IncomeProdSalesTxt);
    end;

    /// <summary>
    /// Returns the localized text description for the Sales Discounts Income account subcategory.
    /// Used for identifying and filtering sales discount accounts in financial reports.
    /// </summary>
    /// <returns>Localized description text for Sales Discounts Income subcategory</returns>
    procedure GetIncomeSalesDiscounts(): Text
    begin
        exit(IncomeSalesDiscountsTxt);
    end;

    /// <summary>
    /// Returns the localized text description for the Sales Returns Income account subcategory.
    /// Used for identifying and filtering sales return accounts in financial reports.
    /// </summary>
    /// <returns>Localized description text for Sales Returns Income subcategory</returns>
    procedure GetIncomeSalesReturns(): Text
    begin
        exit(IncomeSalesReturnsTxt);
    end;

    /// <summary>
    /// Returns the localized text description for the Interest Income account subcategory.
    /// Used for identifying and filtering interest income accounts in financial reports.
    /// </summary>
    /// <returns>Localized description text for Interest Income subcategory</returns>
    procedure GetIncomeInterest(): Text
    begin
        exit(IncomeInterestTxt);
    end;

    /// <summary>
    /// Returns the localized text description for the Cost of Goods Sold - Labor account subcategory.
    /// Used for identifying and filtering labor-related cost of goods sold accounts in financial reports.
    /// </summary>
    /// <returns>Localized description text for COGS Labor subcategory</returns>
    procedure GetCOGSLabor(): Text
    begin
        exit(COGSLaborTxt);
    end;

    /// <summary>
    /// Returns the localized text description for the Cost of Goods Sold - Materials account subcategory.
    /// Used for identifying and filtering material-related cost of goods sold accounts in financial reports.
    /// </summary>
    /// <returns>Localized description text for COGS Materials subcategory</returns>
    procedure GetCOGSMaterials(): Text
    begin
        exit(COGSMaterialsTxt);
    end;

    /// <summary>
    /// Returns the localized text description for the Cost of Goods Sold - Discounts Granted account subcategory.
    /// Used for identifying and filtering discount-related cost of goods sold accounts in financial reports.
    /// </summary>
    /// <returns>Localized description text for COGS Discounts Granted subcategory</returns>
    procedure GetCOGSDiscountsGranted(): Text
    begin
        exit(COGSDiscountsGrantedTxt);
    end;

    /// <summary>
    /// Returns the localized text description for the Rent Expense account subcategory.
    /// Used for identifying and filtering rent expense accounts in financial reports.
    /// </summary>
    /// <returns>Localized description text for Rent Expense subcategory</returns>
    procedure GetRentExpense(): Text
    begin
        exit(RentExpenseTxt);
    end;

    /// <summary>
    /// Returns the localized text description for the Advertising Expense account subcategory.
    /// Used for identifying and filtering advertising expense accounts in financial reports.
    /// </summary>
    /// <returns>Localized description text for Advertising Expense subcategory</returns>
    procedure GetAdvertisingExpense(): Text
    begin
        exit(AdvertisingExpenseTxt);
    end;

    /// <summary>
    /// Returns the localized text description for the Interest Expense account subcategory.
    /// Used for identifying and filtering interest expense accounts in financial reports.
    /// </summary>
    /// <returns>Localized description text for Interest Expense subcategory</returns>
    procedure GetInterestExpense(): Text
    begin
        exit(InterestExpenseTxt);
    end;

    /// <summary>
    /// Returns the localized text description for the Fees Expense account subcategory.
    /// Used for identifying and filtering fees expense accounts in financial reports.
    /// </summary>
    /// <returns>Localized description text for Fees Expense subcategory</returns>
    procedure GetFeesExpense(): Text
    begin
        exit(FeesExpenseTxt);
    end;

    /// <summary>
    /// Returns the localized text description for the Insurance Expense account subcategory.
    /// Used for identifying and filtering insurance expense accounts in financial reports.
    /// </summary>
    /// <returns>Localized description text for Insurance Expense subcategory</returns>
    procedure GetInsuranceExpense(): Text
    begin
        exit(InsuranceExpenseTxt);
    end;

    /// <summary>
    /// Returns the localized text description for the Payroll Expense account subcategory.
    /// Used for identifying and filtering payroll expense accounts in financial reports.
    /// </summary>
    /// <returns>Localized description text for Payroll Expense subcategory</returns>
    procedure GetPayrollExpense(): Text
    begin
        exit(PayrollExpenseTxt);
    end;

    /// <summary>
    /// Returns the localized text description for the Benefits Expense account subcategory.
    /// Used for identifying and filtering employee benefits expense accounts in financial reports.
    /// </summary>
    /// <returns>Localized description text for Benefits Expense subcategory</returns>
    procedure GetBenefitsExpense(): Text
    begin
        exit(BenefitsExpenseTxt);
    end;

    /// <summary>
    /// Returns the localized text description for the Repairs Expense account subcategory.
    /// Used for identifying and filtering repairs and maintenance expense accounts in financial reports.
    /// </summary>
    /// <returns>Localized description text for Repairs Expense subcategory</returns>
    procedure GetRepairsExpense(): Text
    begin
        exit(RepairsTxt);
    end;

    /// <summary>
    /// Returns the localized text description for the Utilities Expense account subcategory.
    /// Used for identifying and filtering utilities expense accounts in financial reports.
    /// </summary>
    /// <returns>Localized description text for Utilities Expense subcategory</returns>
    procedure GetUtilitiesExpense(): Text
    begin
        exit(UtilitiesExpenseTxt);
    end;

    /// <summary>
    /// Returns the localized text description for the Other Income/Expense account subcategory.
    /// Used for identifying and filtering miscellaneous income and expense accounts in financial reports.
    /// </summary>
    /// <returns>Localized description text for Other Income/Expense subcategory</returns>
    procedure GetOtherIncomeExpense(): Text
    begin
        exit(OtherIncomeExpenseTxt);
    end;

    /// <summary>
    /// Returns the localized text description for the Tax Expense account subcategory.
    /// Used for identifying and filtering tax expense accounts in financial reports.
    /// </summary>
    /// <returns>Localized description text for Tax Expense subcategory</returns>
    procedure GetTaxExpense(): Text
    begin
        exit(TaxExpenseTxt);
    end;

    /// <summary>
    /// Returns the localized text description for the Travel Expense account subcategory.
    /// Used for identifying and filtering travel expense accounts in financial reports.
    /// </summary>
    /// <returns>Localized description text for Travel Expense subcategory</returns>
    procedure GetTravelExpense(): Text
    begin
        exit(TravelExpenseTxt);
    end;

    /// <summary>
    /// Returns the localized text description for the Vehicle Expenses account subcategory.
    /// Used for identifying and filtering vehicle-related expense accounts in financial reports.
    /// </summary>
    /// <returns>Localized description text for Vehicle Expenses subcategory</returns>
    procedure GetVehicleExpenses(): Text
    begin
        exit(VehicleExpensesTxt);
    end;

    /// <summary>
    /// Returns the localized text description for the Bad Debt Expense account subcategory.
    /// Used for identifying and filtering bad debt expense accounts in financial reports.
    /// </summary>
    /// <returns>Localized description text for Bad Debt Expense subcategory</returns>
    procedure GetBadDebtExpense(): Text
    begin
        exit(BadDebtExpenseTxt);
    end;

    /// <summary>
    /// Returns the localized text description for the Salaries Expense account subcategory.
    /// Used for identifying and filtering salaries expense accounts in financial reports.
    /// </summary>
    /// <returns>Localized description text for Salaries Expense subcategory</returns>
    procedure GetSalariesExpense(): Text
    begin
        exit(SalariesExpenseTxt);
    end;

    /// <summary>
    /// Returns the localized text description for the Jobs Cost account subcategory.
    /// Used for identifying and filtering job cost accounts in financial reports.
    /// </summary>
    /// <returns>Localized description text for Jobs Cost subcategory</returns>
    procedure GetJobsCost(): Text
    begin
        exit(JobsCostTxt);
    end;

    /// <summary>
    /// Returns the localized text description for the Jobs Income account subcategory.
    /// Used for identifying and filtering job income accounts in financial reports.
    /// </summary>
    /// <returns>Localized description text for Jobs Income subcategory</returns>
    procedure GetIncomeJobs(): Text
    begin
        exit(IncomeJobsTxt);
    end;

    /// <summary>
    /// Returns the localized text description for the Job Sales Contra account subcategory.
    /// Used for identifying and filtering job sales contra accounts in financial reports.
    /// </summary>
    /// <returns>Localized description text for Job Sales Contra subcategory</returns>
    procedure GetJobSalesContra(): Text
    begin
        exit(JobSalesContraTxt);
    end;

    /// <summary>
    /// Retrieves the G/L Account Category record for the specified primary account category.
    /// Filters for top-level categories with no parent entry and returns the first match.
    /// </summary>
    /// <param name="GLAccountCategory">Returns the found G/L Account Category record</param>
    /// <param name="Category">Account category option value to search for</param>
    /// <returns>True if category is found, false otherwise</returns>
    procedure GetAccountCategory(var GLAccountCategory: Record "G/L Account Category"; Category: Option): Boolean
    begin
        GLAccountCategory.SetRange("Account Category", Category);
        GLAccountCategory.SetRange("Parent Entry No.", 0);
        exit(GLAccountCategory.FindFirst());
    end;

    /// <summary>
    /// Retrieves the G/L Account Category record for a specific subcategory under a primary account category.
    /// Filters for child categories with a parent entry and matches the description text.
    /// </summary>
    /// <param name="GLAccountCategory">Returns the found G/L Account Category record</param>
    /// <param name="Category">Primary account category option value</param>
    /// <param name="Description">Subcategory description text to match</param>
    /// <returns>True if subcategory is found, false otherwise</returns>
    procedure GetAccountSubcategory(var GLAccountCategory: Record "G/L Account Category"; Category: Option; Description: Text): Boolean
    begin
        GLAccountCategory.SetRange("Account Category", Category);
        GLAccountCategory.SetFilter("Parent Entry No.", '<>%1', 0);
        GLAccountCategory.SetRange(Description, Description);
        exit(GLAccountCategory.FindFirst());
    end;

    /// <summary>
    /// Returns the entry number for a subcategory under the specified primary account category.
    /// Searches for matching category and description, returning the entry number for category assignment.
    /// </summary>
    /// <param name="Category">Primary account category option value</param>
    /// <param name="SubcategoryDescription">Subcategory description text to locate</param>
    /// <returns>Entry number of the matching subcategory, or 0 if not found</returns>
    procedure GetSubcategoryEntryNo(Category: Option; SubcategoryDescription: Text): Integer
    var
        GLAccountCategory: Record "G/L Account Category";
    begin
        GLAccountCategory.SetRange("Account Category", Category);
        GLAccountCategory.SetRange(Description, SubcategoryDescription);
        if GLAccountCategory.FindFirst() then
            exit(GLAccountCategory."Entry No.");
    end;

    /// <summary>
    /// Validates G/L Account setup and assigns account category and subcategory if not already set.
    /// Simplified version that delegates to the full CheckGLAccount procedure with default table and field parameters.
    /// </summary>
    /// <param name="AccNo">G/L Account number to validate and categorize</param>
    /// <param name="CheckProdPostingGroup">Whether to validate General Product Posting Group is assigned</param>
    /// <param name="CheckDirectPosting">Whether to validate Direct Posting is enabled</param>
    /// <param name="AccountCategory">Account category to assign if account has no category</param>
    /// <param name="AccountSubcategory">Subcategory description to assign if account has no category</param>
    procedure CheckGLAccount(AccNo: Code[20]; CheckProdPostingGroup: Boolean; CheckDirectPosting: Boolean; AccountCategory: Option; AccountSubcategory: Text)
    begin
        CheckGLAccount(0, 0, AccNo, CheckProdPostingGroup, CheckDirectPosting, AccountCategory, AccountSubcategory);
    end;

    /// <summary>
    /// Validates G/L Account setup and assigns account category and subcategory if not already set.
    /// Performs comprehensive validation including posting group checks and automatic category assignment.
    /// </summary>
    /// <param name="TableNo">Source table number for extensibility events</param>
    /// <param name="FieldNo">Source field number for extensibility events</param>
    /// <param name="AccNo">G/L Account number to validate and categorize</param>
    /// <param name="CheckProdPostingGroup">Whether to validate General Product Posting Group is assigned</param>
    /// <param name="CheckDirectPosting">Whether to validate Direct Posting is enabled</param>
    /// <param name="AccountCategory">Account category to assign if account has no category</param>
    /// <param name="AccountSubcategory">Subcategory description to assign if account has no category</param>
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

    /// <summary>
    /// Validates G/L Account setup without requiring or assigning account categories.
    /// Performs basic validation for posting groups and direct posting without category enforcement.
    /// </summary>
    /// <param name="AccNo">G/L Account number to validate</param>
    /// <param name="CheckProdPostingGroup">Whether to validate General Product Posting Group is assigned</param>
    /// <param name="CheckDirectPosting">Whether to validate Direct Posting is enabled</param>
    procedure CheckGLAccountWithoutCategory(AccNo: Code[20]; CheckProdPostingGroup: Boolean; CheckDirectPosting: Boolean)
    var
        OptionValueOutOfRange: Integer;
    begin
        OptionValueOutOfRange := -1;
        CheckGLAccount(AccNo, CheckProdPostingGroup, CheckDirectPosting, OptionValueOutOfRange, '');
    end;

    /// <summary>
    /// Opens G/L Account lookup filtered by account category and subcategory for user selection.
    /// Simplified version that delegates to the full LookupGLAccount procedure with default table and field parameters.
    /// </summary>
    /// <param name="AccountNo">Current account number, updated with user selection</param>
    /// <param name="AccountCategory">Account category to filter the lookup</param>
    /// <param name="AccountSubcategoryFilter">Subcategory filter text for refined lookup results</param>
    procedure LookupGLAccount(var AccountNo: Code[20]; AccountCategory: Option; AccountSubcategoryFilter: Text)
    begin
        LookupGLAccount(0, 0, AccountNo, AccountCategory, AccountSubcategoryFilter);
    end;

    /// <summary>
    /// Opens G/L Account lookup filtered by account category and subcategory for user selection.
    /// Provides filtered lookup based on category and subcategory criteria with extensibility support.
    /// </summary>
    /// <param name="TableNo">Source table number for extensibility events</param>
    /// <param name="FieldNo">Source field number for extensibility events</param>
    /// <param name="AccountNo">Current account number, updated with user selection</param>
    /// <param name="AccountCategory">Account category to filter the lookup</param>
    /// <param name="AccountSubcategoryFilter">Subcategory filter text for refined lookup results</param>
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

    /// <summary>
    /// Opens G/L Account lookup without category filtering for unrestricted user selection.
    /// Provides access to all posting-type G/L accounts without category or subcategory restrictions.
    /// </summary>
    /// <param name="AccountNo">Current account number, updated with user selection</param>
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

    /// <summary>
    /// Integration event raised after company initialization is complete.
    /// Allows subscribers to perform custom setup or validation after standard account categories are created.
    /// </summary>
    [IntegrationEvent(false, false)]
    local procedure OnAfterInitializeCompany()
    begin
    end;

    /// <summary>
    /// Integration event raised before company initialization begins.
    /// Allows subscribers to perform custom setup or preparation before standard account categories are created.
    /// </summary>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitializeCompany()
    begin
    end;

    /// <summary>
    /// Integration event raised before running an account schedule report.
    /// Allows subscribers to customize or override the standard account schedule execution.
    /// </summary>
    /// <param name="AccSchedName">Account schedule name to be executed</param>
    /// <param name="IsHandled">Set to true to skip standard report execution</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnRunAccountScheduleReport(AccSchedName: Code[10]; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised before initializing standard account categories.
    /// Allows subscribers to customize or override the standard account category initialization process.
    /// </summary>
    /// <param name="IsHandled">Set to true to skip standard account category initialization</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitializeAccountCategories(var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised before validating and categorizing a G/L account.
    /// Allows subscribers to customize account validation logic or override category assignment.
    /// </summary>
    /// <param name="TableNo">Source table number for context</param>
    /// <param name="FieldNo">Source field number for context</param>
    /// <param name="AccNo">G/L Account number being validated</param>
    /// <param name="CheckProdPostingGroup">Whether to validate General Product Posting Group</param>
    /// <param name="CheckDirectPosting">Whether to validate Direct Posting is enabled</param>
    /// <param name="AccountCategory">Account category to assign if account has no category</param>
    /// <param name="AccountSubcategory">Subcategory description to assign if account has no category</param>
    /// <param name="IsHandled">Set to true to skip standard account validation</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckGLAccount(TableNo: Integer; FieldNo: Integer; AccNo: Code[20]; CheckProdPostingGroup: Boolean; CheckDirectPosting: Boolean; var AccountCategory: Option; var AccountSubcategory: Text; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised before opening G/L account lookup with category filtering.
    /// Allows subscribers to customize lookup behavior or override filtering criteria.
    /// </summary>
    /// <param name="TableNo">Source table number for context</param>
    /// <param name="FieldNo">Source field number for context</param>
    /// <param name="AccountNo">Current account number being looked up</param>
    /// <param name="AccountCategory">Account category filter for lookup</param>
    /// <param name="AccountSubcategoryFilter">Subcategory filter text for lookup</param>
    /// <param name="IsHandled">Set to true to skip standard lookup process</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeLookupGLAccount(TableNo: Integer; FieldNo: Integer; var AccountNo: Code[20]; var AccountCategory: Option; var AccountSubcategoryFilter: Text; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised after account categories have been initialized.
    /// Allows subscribers to perform additional setup or customization after standard categories are created.
    /// </summary>
    [IntegrationEvent(false, false)]
    local procedure OnAfterInitializeAccountCategories()
    begin
    end;
}

