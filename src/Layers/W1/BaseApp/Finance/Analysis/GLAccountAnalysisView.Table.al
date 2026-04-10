// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Analysis;

using Microsoft.CashFlow.Account;
using Microsoft.CashFlow.Forecast;
using Microsoft.Finance.Consolidation;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.FinancialReports;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Budget;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.SalesTax;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.Comment;

/// <summary>
/// Virtual table combining G/L Account and Cash Flow Account data for analysis view operations.
/// Provides unified interface for analysis across multiple account sources with dimensional filtering.
/// </summary>
/// <remarks>
/// Extends G/L Account functionality with Cash Flow Account integration for comprehensive financial analysis.
/// Supports multi-dimensional filtering and budget analysis across different account types.
/// Used by analysis views and financial reporting for cross-account-type analysis.
/// </remarks>
table 376 "G/L Account (Analysis View)"
{
    Caption = 'G/L Account (Analysis View)';
    DataCaptionFields = "No.", Name;
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Unique identifier for the G/L account or cash flow account.
        /// </summary>
        field(1; "No."; Code[20])
        {
            Caption = 'No.';
            ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
            NotBlank = true;
            TableRelation = if ("Account Source" = const("G/L Account")) "G/L Account"
            else
            if ("Account Source" = const("Cash Flow Account")) "Cash Flow Account";
        }
        /// <summary>
        /// Name of the account for display and identification purposes.
        /// </summary>
        field(2; Name; Text[100])
        {
            Caption = 'Name';
            ToolTip = 'Specifies the name of the general ledger account.';
        }
        /// <summary>
        /// Alternative search name for quick lookup and filtering operations.
        /// </summary>
        field(3; "Search Name"; Code[100])
        {
            Caption = 'Search Name';
        }
        /// <summary>
        /// Type of account (Posting, Heading, Total, Begin-Total, End-Total).
        /// </summary>
        field(4; "Account Type"; Enum "G/L Account Type")
        {
            Caption = 'Account Type';
            ToolTip = 'Specifies the purpose of the account. Total: Used to total a series of balances on accounts from many different account groupings. To use Total, leave this field blank. Begin-Total: A marker for the beginning of a series of accounts to be totaled that ends with an End-Total account. End-Total: A total of a series of accounts that starts with the preceding Begin-Total account. The total is defined in the Totaling field.';
        }
        /// <summary>
        /// Source of the account data (G/L Account or Cash Flow Forecast).
        /// </summary>
        field(5; "Account Source"; Enum "Analysis Account Source")
        {
            Caption = 'Account Source';
        }
        /// <summary>
        /// Global Dimension 1 code associated with the account for dimensional analysis.
        /// </summary>
        field(6; "Global Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,1,1';
            Caption = 'Global Dimension 1 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1));
        }
        /// <summary>
        /// Global Dimension 2 code associated with the account for dimensional analysis.
        /// </summary>
        field(7; "Global Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,1,2';
            Caption = 'Global Dimension 2 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2));
        }
        /// <summary>
        /// Classification of account as Income Statement or Balance Sheet type.
        /// </summary>
        field(9; "Income/Balance"; Enum "G/L Account Report Type")
        {
            Caption = 'Income/Balance';
            ToolTip = 'Specifies whether a general ledger account is an income statement account or a balance sheet account.';
        }
        /// <summary>
        /// Restricts posting to either Both, Debit only, or Credit only transactions.
        /// </summary>
        field(10; "Debit/Credit"; Option)
        {
            Caption = 'Debit/Credit';
            OptionCaption = 'Both,Debit,Credit';
            OptionMembers = Both,Debit,Credit;
        }
        /// <summary>
        /// Secondary account number for alternative identification or reference.
        /// </summary>
        field(11; "No. 2"; Code[20])
        {
            Caption = 'No. 2';
        }
        /// <summary>
        /// Indicates whether comments exist for this G/L account.
        /// </summary>
        field(12; Comment; Boolean)
        {
            CalcFormula = exist("Comment Line" where("Table Name" = const("G/L Account"),
                                                      "No." = field("No.")));
            Caption = 'Comment';
            Editable = false;
            FieldClass = FlowField;
        }
        /// <summary>
        /// Indicates whether the account is blocked from posting transactions.
        /// </summary>
        field(13; Blocked; Boolean)
        {
            Caption = 'Blocked';
        }
        /// <summary>
        /// Indicates whether transactions can be posted directly to this account.
        /// </summary>
        field(14; "Direct Posting"; Boolean)
        {
            Caption = 'Direct Posting';
            ToolTip = 'Specifies whether you will be able to post directly or only indirectly to this general ledger account.';
            InitValue = true;
        }
        /// <summary>
        /// Indicates whether this account is used for reconciliation purposes.
        /// </summary>
        field(16; "Reconciliation Account"; Boolean)
        {
            Caption = 'Reconciliation Account';
        }
        /// <summary>
        /// Indicates whether to start a new page when printing this account in reports.
        /// </summary>
        field(17; "New Page"; Boolean)
        {
            Caption = 'New Page';
        }
        /// <summary>
        /// Number of blank lines to insert before this account in reports.
        /// </summary>
        field(18; "No. of Blank Lines"; Integer)
        {
            Caption = 'No. of Blank Lines';
            MinValue = 0;
        }
        /// <summary>
        /// Indentation level for this account in hierarchical report displays.
        /// </summary>
        field(19; Indentation; Integer)
        {
            Caption = 'Indentation';
            MinValue = 0;
        }
        /// <summary>
        /// Date when this account record was last modified.
        /// </summary>
        field(26; "Last Date Modified"; Date)
        {
            Caption = 'Last Date Modified';
            Editable = false;
        }
        /// <summary>
        /// Filter for Cash Flow Forecast codes when analyzing cash flow accounts.
        /// </summary>
        field(27; "Cash Flow Forecast Filter"; Code[20])
        {
            Caption = 'Cash Flow Forecast Filter';
            FieldClass = FlowFilter;
            TableRelation = "Cash Flow Forecast";
        }
        /// <summary>
        /// Date filter for limiting analysis to specific date ranges.
        /// </summary>
        field(28; "Date Filter"; Date)
        {
            Caption = 'Date Filter';
            FieldClass = FlowFilter;
        }
        /// <summary>
        /// Global dimension 1 filter for dimensional analysis.
        /// </summary>
        field(29; "Global Dimension 1 Filter"; Code[20])
        {
            CaptionClass = '1,3,1';
            Caption = 'Global Dimension 1 Filter';
            FieldClass = FlowFilter;
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1));
        }
        /// <summary>
        /// Global dimension 2 filter for dimensional analysis.
        /// </summary>
        field(30; "Global Dimension 2 Filter"; Code[20])
        {
            CaptionClass = '1,3,2';
            Caption = 'Global Dimension 2 Filter';
            FieldClass = FlowFilter;
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2));
        }
        /// <summary>
        /// Account balance at the specified date from analysis view entries.
        /// </summary>
        field(31; "Balance at Date"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            BlankZero = true;
            CalcFormula = sum("Analysis View Entry".Amount where("Analysis View Code" = field("Analysis View Filter"),
                                                                  "Business Unit Code" = field("Business Unit Filter"),
                                                                  "Account No." = field("No."),
                                                                  "Account Source" = field("Account Source"),
                                                                  "Account No." = field(filter(Totaling)),
                                                                  "Dimension 1 Value Code" = field("Dimension 1 Filter"),
                                                                  "Dimension 2 Value Code" = field("Dimension 2 Filter"),
                                                                  "Dimension 3 Value Code" = field("Dimension 3 Filter"),
                                                                  "Dimension 4 Value Code" = field("Dimension 4 Filter"),
                                                                  "Posting Date" = field(upperlimit("Date Filter")),
                                                                  "Cash Flow Forecast No." = field("Cash Flow Forecast Filter")));
            Caption = 'Balance at Date';
            ToolTip = 'Specifies the G/L account balance on the last date included in the Date Filter field.';
            Editable = false;
            FieldClass = FlowField;
        }
        /// <summary>
        /// Net change in account balance during the filtered period from analysis view entries.
        /// </summary>
        field(32; "Net Change"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            BlankZero = true;
            CalcFormula = sum("Analysis View Entry".Amount where("Analysis View Code" = field("Analysis View Filter"),
                                                                  "Business Unit Code" = field("Business Unit Filter"),
                                                                  "Account No." = field("No."),
                                                                  "Account Source" = field("Account Source"),
                                                                  "Account No." = field(filter(Totaling)),
                                                                  "Dimension 1 Value Code" = field("Dimension 1 Filter"),
                                                                  "Dimension 2 Value Code" = field("Dimension 2 Filter"),
                                                                  "Dimension 3 Value Code" = field("Dimension 3 Filter"),
                                                                  "Dimension 4 Value Code" = field("Dimension 4 Filter"),
                                                                  "Posting Date" = field("Date Filter"),
                                                                   "Cash Flow Forecast No." = field("Cash Flow Forecast Filter")));
            Caption = 'Net Change';
            ToolTip = 'Specifies the net change in the account balance during the time period in the Date Filter field.';
            Editable = false;
            FieldClass = FlowField;
        }
        /// <summary>
        /// Budgeted amount for the account in the analysis view period.
        /// </summary>
        field(33; "Budgeted Amount"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            BlankZero = true;
            CalcFormula = sum("Analysis View Budget Entry".Amount where("Analysis View Code" = field("Analysis View Filter"),
                                                                         "Budget Name" = field("Budget Filter"),
                                                                         "Business Unit Code" = field("Business Unit Filter"),
                                                                         "G/L Account No." = field("No."),
                                                                         "G/L Account No." = field(filter(Totaling)),
                                                                         "Dimension 1 Value Code" = field("Dimension 1 Filter"),
                                                                         "Dimension 2 Value Code" = field("Dimension 2 Filter"),
                                                                         "Dimension 3 Value Code" = field("Dimension 3 Filter"),
                                                                         "Dimension 4 Value Code" = field("Dimension 4 Filter"),
                                                                         "Posting Date" = field("Date Filter")));
            Caption = 'Budgeted Amount';
            ToolTip = 'Specifies either the G/L account''s total budget or, if you have specified a name in the Budget Name field, a specific budget.';
            FieldClass = FlowField;
        }
        /// <summary>
        /// Account totaling range for sum-type accounts in analysis views.
        /// </summary>
        field(34; Totaling; Text[250])
        {
            Caption = 'Totaling';
            ToolTip = 'Specifies an account interval or a list of account numbers. The entries of the account will be totaled to give a total balance. How entries are totaled depends on the value in the Account Type field.';
            TableRelation = if ("Account Source" = const("G/L Account")) "G/L Account"
            else
            if ("Account Source" = const("Cash Flow Account")) "Cash Flow Account";
            ValidateTableRelation = false;
        }
        /// <summary>
        /// Budget filter for limiting analysis to specific budget names.
        /// </summary>
        field(35; "Budget Filter"; Code[10])
        {
            Caption = 'Budget Filter';
            FieldClass = FlowFilter;
            TableRelation = "G/L Budget Name";
        }
        /// <summary>
        /// Current account balance from analysis view entries.
        /// </summary>
        field(36; Balance; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            BlankZero = true;
            CalcFormula = sum("Analysis View Entry".Amount where("Analysis View Code" = field("Analysis View Filter"),
                                                                  "Business Unit Code" = field("Business Unit Filter"),
                                                                  "Account No." = field("No."),
                                                                  "Account Source" = field("Account Source"),
                                                                  "Account No." = field(filter(Totaling)),
                                                                  "Dimension 1 Value Code" = field("Dimension 1 Filter"),
                                                                  "Dimension 2 Value Code" = field("Dimension 2 Filter"),
                                                                  "Dimension 3 Value Code" = field("Dimension 3 Filter"),
                                                                  "Dimension 4 Value Code" = field("Dimension 4 Filter"),
                                                                  "Posting Date" = field("Date Filter"),
                                                                   "Cash Flow Forecast No." = field("Cash Flow Forecast Filter")));
            Caption = 'Balance';
            ToolTip = 'Specifies the balance on this account.';
            Editable = false;
            FieldClass = FlowField;
        }
        /// <summary>
        /// Budgeted amount for the account at a specific date in analysis views.
        /// </summary>
        field(37; "Budgeted at Date"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            BlankZero = true;
            CalcFormula = sum("Analysis View Budget Entry".Amount where("Analysis View Code" = field("Analysis View Filter"),
                                                                         "Budget Name" = field("Budget Filter"),
                                                                         "Business Unit Code" = field("Business Unit Filter"),
                                                                         "G/L Account No." = field("No."),
                                                                         "G/L Account No." = field(filter(Totaling)),
                                                                         "Dimension 1 Value Code" = field("Dimension 1 Filter"),
                                                                         "Dimension 2 Value Code" = field("Dimension 2 Filter"),
                                                                         "Dimension 3 Value Code" = field("Dimension 3 Filter"),
                                                                         "Dimension 4 Value Code" = field("Dimension 4 Filter"),
                                                                         "Posting Date" = field(upperlimit("Date Filter"))));
            Caption = 'Budgeted at Date';
            FieldClass = FlowField;
        }
        /// <summary>
        /// Consolidation debit account for consolidation processes.
        /// </summary>
        field(40; "Consol. Debit Acc."; Code[20])
        {
            AccessByPermission = TableData "Business Unit" = R;
            Caption = 'Consol. Debit Acc.';
            ToolTip = 'Specifies the account number in a consolidated company to transfer credit balances.';
        }
        /// <summary>
        /// Consolidation credit account for consolidation processes.
        /// </summary>
        field(41; "Consol. Credit Acc."; Code[20])
        {
            AccessByPermission = TableData "Business Unit" = R;
            Caption = 'Consol. Credit Acc.';
            ToolTip = 'Specifies the account number in a consolidated company to transfer credit balances.';
        }
        /// <summary>
        /// Business unit filter for multi-company analysis.
        /// </summary>
        field(42; "Business Unit Filter"; Code[20])
        {
            Caption = 'Business Unit Filter';
            FieldClass = FlowFilter;
            TableRelation = "Business Unit";
        }
        /// <summary>
        /// General posting type for transaction categorization in analysis.
        /// </summary>
        field(43; "Gen. Posting Type"; Option)
        {
            Caption = 'Gen. Posting Type';
            ToolTip = 'Specifies the type of transaction.';
            OptionCaption = ' ,Purchase,Sale';
            OptionMembers = " ",Purchase,Sale;
        }
        /// <summary>
        /// General business posting group for analysis categorization.
        /// </summary>
        field(44; "Gen. Bus. Posting Group"; Code[20])
        {
            Caption = 'Gen. Bus. Posting Group';
            ToolTip = 'Specifies the vendor''s or customer''s trade type to link transactions made for this business partner with the appropriate general ledger account according to the general posting setup.';
            TableRelation = "Gen. Business Posting Group";
        }
        /// <summary>
        /// General product posting group for analysis categorization.
        /// </summary>
        field(45; "Gen. Prod. Posting Group"; Code[20])
        {
            Caption = 'Gen. Prod. Posting Group';
            ToolTip = 'Specifies the item''s product type to link transactions made for this item with the appropriate general ledger account according to the general posting setup.';
            TableRelation = "Gen. Product Posting Group";
        }
        /// <summary>
        /// Total debit amounts for the account in the analysis period.
        /// </summary>
        field(47; "Debit Amount"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            BlankZero = true;
            CalcFormula = sum("Analysis View Entry"."Debit Amount" where("Analysis View Code" = field("Analysis View Filter"),
                                                                          "Business Unit Code" = field("Business Unit Filter"),
                                                                          "Account No." = field("No."),
                                                                          "Account Source" = field("Account Source"),
                                                                          "Account No." = field(Totaling),
                                                                          "Dimension 1 Value Code" = field("Dimension 1 Filter"),
                                                                          "Dimension 2 Value Code" = field("Dimension 2 Filter"),
                                                                          "Dimension 3 Value Code" = field("Dimension 3 Filter"),
                                                                          "Dimension 4 Value Code" = field("Dimension 4 Filter"),
                                                                          "Posting Date" = field("Date Filter"),
                                                                           "Cash Flow Forecast No." = field("Cash Flow Forecast Filter")));
            Caption = 'Debit Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        /// <summary>
        /// Total credit amounts for the account in the analysis period.
        /// </summary>
        field(48; "Credit Amount"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            BlankZero = true;
            CalcFormula = sum("Analysis View Entry"."Credit Amount" where("Analysis View Code" = field("Analysis View Filter"),
                                                                           "Business Unit Code" = field("Business Unit Filter"),
                                                                           "Account No." = field("No."),
                                                                           "Account Source" = field("Account Source"),
                                                                           "Account No." = field(Totaling),
                                                                           "Dimension 1 Value Code" = field("Dimension 1 Filter"),
                                                                           "Dimension 2 Value Code" = field("Dimension 2 Filter"),
                                                                           "Dimension 3 Value Code" = field("Dimension 3 Filter"),
                                                                           "Dimension 4 Value Code" = field("Dimension 4 Filter"),
                                                                           "Posting Date" = field("Date Filter"),
                                                                           "Cash Flow Forecast No." = field("Cash Flow Forecast Filter")));
            Caption = 'Credit Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        /// <summary>
        /// Indicates if automatic extended texts are enabled for the account.
        /// </summary>
        field(49; "Automatic Ext. Texts"; Boolean)
        {
            Caption = 'Automatic Ext. Texts';
        }
        /// <summary>
        /// Budgeted debit amount for the account in the analysis period.
        /// </summary>
        field(52; "Budgeted Debit Amount"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            BlankNumbers = BlankNegAndZero;
            BlankZero = true;
            CalcFormula = sum("Analysis View Budget Entry".Amount where("Analysis View Code" = field("Analysis View Filter"),
                                                                         "Budget Name" = field("Budget Filter"),
                                                                         "Business Unit Code" = field("Business Unit Filter"),
                                                                         "G/L Account No." = field("No."),
                                                                         "G/L Account No." = field(filter(Totaling)),
                                                                         "Dimension 1 Value Code" = field("Dimension 1 Filter"),
                                                                         "Dimension 2 Value Code" = field("Dimension 2 Filter"),
                                                                         "Dimension 3 Value Code" = field("Dimension 3 Filter"),
                                                                         "Dimension 4 Value Code" = field("Dimension 4 Filter"),
                                                                         "Posting Date" = field("Date Filter"),
                                                                         Amount = filter(> 0)));
            Caption = 'Budgeted Debit Amount';
            FieldClass = FlowField;
        }
        /// <summary>
        /// Budgeted credit amount for the account in the analysis period.
        /// </summary>
        field(53; "Budgeted Credit Amount"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            BlankNumbers = BlankZeroAndPos;
            BlankZero = true;
            CalcFormula = - sum("Analysis View Budget Entry".Amount where("Analysis View Code" = field("Analysis View Filter"),
                                                                          "Budget Name" = field("Budget Filter"),
                                                                          "Business Unit Code" = field("Business Unit Filter"),
                                                                          "G/L Account No." = field("No."),
                                                                          "G/L Account No." = field(filter(Totaling)),
                                                                          "Dimension 1 Value Code" = field("Dimension 1 Filter"),
                                                                          "Dimension 2 Value Code" = field("Dimension 2 Filter"),
                                                                          "Dimension 3 Value Code" = field("Dimension 3 Filter"),
                                                                          "Dimension 4 Value Code" = field("Dimension 4 Filter"),
                                                                          "Posting Date" = field("Date Filter"),
                                                                          Amount = filter(< 0)));
            Caption = 'Budgeted Credit Amount';
            FieldClass = FlowField;
        }
        /// <summary>
        /// Tax area code for sales tax calculations in analysis.
        /// </summary>
        field(54; "Tax Area Code"; Code[20])
        {
            Caption = 'Tax Area Code';
            TableRelation = "Tax Area";
        }
        /// <summary>
        /// Indicates if the account is liable for sales tax calculations.
        /// </summary>
        field(55; "Tax Liable"; Boolean)
        {
            Caption = 'Tax Liable';
        }
        /// <summary>
        /// Tax group code for sales tax calculations in analysis.
        /// </summary>
        field(56; "Tax Group Code"; Code[20])
        {
            Caption = 'Tax Group Code';
            TableRelation = "Tax Group";
        }
        /// <summary>
        /// VAT business posting group for VAT calculations in analysis.
        /// </summary>
        field(57; "VAT Bus. Posting Group"; Code[20])
        {
            Caption = 'VAT Bus. Posting Group';
            ToolTip = 'Specifies the VAT specification of the involved customer or vendor to link transactions made for this record with the appropriate general ledger account according to the VAT posting setup.';
            TableRelation = "VAT Business Posting Group";
        }
        /// <summary>
        /// VAT product posting group for VAT calculations in analysis.
        /// </summary>
        field(58; "VAT Prod. Posting Group"; Code[20])
        {
            Caption = 'VAT Prod. Posting Group';
            ToolTip = 'Specifies the VAT specification of the involved item or resource to link transactions made for this record with the appropriate general ledger account according to the VAT posting setup.';
            TableRelation = "VAT Product Posting Group";
        }
        /// <summary>
        /// Additional currency net change amount for the analysis period.
        /// </summary>
        field(60; "Additional-Currency Net Change"; Decimal)
        {
            AutoFormatExpression = GetAdditionalReportingCurrencyCode();
            AutoFormatType = 1;
            BlankZero = true;
            CalcFormula = sum("Analysis View Entry"."Add.-Curr. Amount" where("Analysis View Code" = field("Analysis View Filter"),
                                                                               "Business Unit Code" = field("Business Unit Filter"),
                                                                               "Account No." = field("No."),
                                                                               "Account Source" = field("Account Source"),
                                                                               "Account No." = field(filter(Totaling)),
                                                                               "Dimension 1 Value Code" = field("Dimension 1 Filter"),
                                                                               "Dimension 2 Value Code" = field("Dimension 2 Filter"),
                                                                               "Dimension 3 Value Code" = field("Dimension 3 Filter"),
                                                                               "Dimension 4 Value Code" = field("Dimension 4 Filter"),
                                                                               "Posting Date" = field("Date Filter"),
                                                                               "Cash Flow Forecast No." = field("Cash Flow Forecast Filter")));
            Caption = 'Additional-Currency Net Change';
            ToolTip = 'Specifies the net change in the account balance.';
            Editable = false;
            FieldClass = FlowField;
        }
        /// <summary>
        /// Additional currency balance at specific date for analysis.
        /// </summary>
        field(61; "Add.-Currency Balance at Date"; Decimal)
        {
            AutoFormatExpression = GetAdditionalReportingCurrencyCode();
            AutoFormatType = 1;
            BlankZero = true;
            CalcFormula = sum("Analysis View Entry"."Add.-Curr. Amount" where("Analysis View Code" = field("Analysis View Filter"),
                                                                               "Business Unit Code" = field("Business Unit Filter"),
                                                                               "Account No." = field("No."),
                                                                               "Account Source" = field("Account Source"),
                                                                               "Account No." = field(filter(Totaling)),
                                                                               "Dimension 1 Value Code" = field("Dimension 1 Filter"),
                                                                               "Dimension 2 Value Code" = field("Dimension 2 Filter"),
                                                                               "Dimension 3 Value Code" = field("Dimension 3 Filter"),
                                                                               "Dimension 4 Value Code" = field("Dimension 4 Filter"),
                                                                               "Posting Date" = field(upperlimit("Date Filter")),
                                                                               "Cash Flow Forecast No." = field("Cash Flow Forecast Filter")));
            Caption = 'Add.-Currency Balance at Date';
            ToolTip = 'Specifies the G/L account balance, in the additional reporting currency, on the last date included in the Date Filter field.';
            Editable = false;
            FieldClass = FlowField;
        }
        /// <summary>
        /// Additional currency balance for the account in analysis views.
        /// </summary>
        field(62; "Additional-Currency Balance"; Decimal)
        {
            AutoFormatExpression = GetAdditionalReportingCurrencyCode();
            AutoFormatType = 1;
            BlankZero = true;
            CalcFormula = sum("Analysis View Entry"."Add.-Curr. Amount" where("Analysis View Code" = field("Analysis View Filter"),
                                                                               "Business Unit Code" = field("Business Unit Filter"),
                                                                               "Account No." = field("No."),
                                                                               "Account Source" = field("Account Source"),
                                                                               "Account No." = field(filter(Totaling)),
                                                                               "Dimension 1 Value Code" = field("Dimension 1 Filter"),
                                                                               "Dimension 2 Value Code" = field("Dimension 2 Filter"),
                                                                               "Dimension 3 Value Code" = field("Dimension 3 Filter"),
                                                                               "Dimension 4 Value Code" = field("Dimension 4 Filter"),
                                                                               "Posting Date" = field("Date Filter"),
                                                                               "Cash Flow Forecast No." = field("Cash Flow Forecast Filter")));
            Caption = 'Additional-Currency Balance';
            ToolTip = 'Specifies the balance on this account, in the additional reporting currency.';
            Editable = false;
            FieldClass = FlowField;
        }
        /// <summary>
        /// Exchange rate adjustment type for currency conversion in analysis.
        /// </summary>
        field(63; "Exchange Rate Adjustment"; Option)
        {
            Caption = 'Exchange Rate Adjustment';
            OptionCaption = 'No Adjustment,Adjust Amount,Adjust Additional-Currency Amount';
            OptionMembers = "No Adjustment","Adjust Amount","Adjust Additional-Currency Amount";
        }
        /// <summary>
        /// Additional currency debit amount for the analysis period.
        /// </summary>
        field(64; "Add.-Currency Debit Amount"; Decimal)
        {
            AutoFormatExpression = GetAdditionalReportingCurrencyCode();
            AutoFormatType = 1;
            BlankZero = true;
            CalcFormula = sum("Analysis View Entry"."Add.-Curr. Debit Amount" where("Analysis View Code" = field("Analysis View Filter"),
                                                                                     "Business Unit Code" = field("Business Unit Filter"),
                                                                                     "Account No." = field("No."),
                                                                                     "Account Source" = field("Account Source"),
                                                                                     "Account No." = field(filter(Totaling)),
                                                                                     "Dimension 1 Value Code" = field("Dimension 1 Filter"),
                                                                                     "Dimension 2 Value Code" = field("Dimension 2 Filter"),
                                                                                     "Dimension 3 Value Code" = field("Dimension 3 Filter"),
                                                                                     "Dimension 4 Value Code" = field("Dimension 4 Filter"),
                                                                                     "Posting Date" = field("Date Filter"),
                                                                                     "Cash Flow Forecast No." = field("Cash Flow Forecast Filter")));
            Caption = 'Add.-Currency Debit Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        /// <summary>
        /// Additional currency credit amount for the analysis period.
        /// </summary>
        field(65; "Add.-Currency Credit Amount"; Decimal)
        {
            AutoFormatExpression = GetAdditionalReportingCurrencyCode();
            AutoFormatType = 1;
            BlankZero = true;
            CalcFormula = sum("Analysis View Entry"."Add.-Curr. Credit Amount" where("Analysis View Code" = field("Analysis View Filter"),
                                                                                      "Business Unit Code" = field("Business Unit Filter"),
                                                                                      "Account No." = field("No."),
                                                                                      "Account Source" = field("Account Source"),
                                                                                      "Account No." = field(filter(Totaling)),
                                                                                      "Dimension 1 Value Code" = field("Dimension 1 Filter"),
                                                                                      "Dimension 2 Value Code" = field("Dimension 2 Filter"),
                                                                                      "Dimension 3 Value Code" = field("Dimension 3 Filter"),
                                                                                      "Dimension 4 Value Code" = field("Dimension 4 Filter"),
                                                                                      "Posting Date" = field("Date Filter"),
                                                                                      "Cash Flow Forecast No." = field("Cash Flow Forecast Filter")));
            Caption = 'Add.-Currency Credit Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        /// <summary>
        /// Analysis view filter code for data selection.
        /// </summary>
        field(66; "Analysis View Filter"; Code[10])
        {
            Caption = 'Analysis View Filter';
            FieldClass = FlowFilter;
            TableRelation = "Analysis View";
        }
        /// <summary>
        /// Dimension 1 filter for analysis view data selection.
        /// </summary>
        field(67; "Dimension 1 Filter"; Code[20])
        {
            CaptionClass = GetCaptionClass(1);
            Caption = 'Dimension 1 Filter';
            FieldClass = FlowFilter;
        }
        /// <summary>
        /// Dimension 2 filter for analysis view data selection.
        /// </summary>
        field(68; "Dimension 2 Filter"; Code[20])
        {
            CaptionClass = GetCaptionClass(2);
            Caption = 'Dimension 2 Filter';
            FieldClass = FlowFilter;
        }
        /// <summary>
        /// Dimension 3 filter for analysis view data selection.
        /// </summary>
        field(69; "Dimension 3 Filter"; Code[20])
        {
            CaptionClass = GetCaptionClass(3);
            Caption = 'Dimension 3 Filter';
            FieldClass = FlowFilter;
        }
        /// <summary>
        /// Dimension 4 filter for analysis view data selection.
        /// </summary>
        field(70; "Dimension 4 Filter"; Code[20])
        {
            CaptionClass = GetCaptionClass(4);
            Caption = 'Dimension 4 Filter';
            FieldClass = FlowFilter;
        }
    }

    keys
    {
        key(Key1; "No.", "Account Source")
        {
            Clustered = true;
        }
        key(Key2; "Search Name")
        {
        }
        key(Key3; "Reconciliation Account")
        {
        }
        key(Key4; "Gen. Bus. Posting Group")
        {
        }
        key(Key5; "Gen. Prod. Posting Group")
        {
        }
    }

    fieldgroups
    {
    }

    var
        AnalysisView: Record "Analysis View";

#pragma warning disable AA0074
        Text000: Label '1,6,,Dimension 1 Filter';
        Text001: Label '1,6,,Dimension 2 Filter';
        Text002: Label '1,6,,Dimension 3 Filter';
        Text003: Label '1,6,,Dimension 4 Filter';
#pragma warning restore AA0074

    /// <summary>
    /// Returns the caption class string for dimension fields based on analysis view configuration.
    /// </summary>
    /// <param name="AnalysisViewDimType">Dimension type (1-4) for caption generation</param>
    /// <returns>Caption class string for the specified dimension type</returns>
    procedure GetCaptionClass(AnalysisViewDimType: Integer) Result: Text[250]
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetCaptionClass(Rec, AnalysisViewDimType, Result, IsHandled);
        if IsHandled then
            exit;

        if AnalysisView.Code <> GetFilter("Analysis View Filter") then
            AnalysisView.Get(GetFilter("Analysis View Filter"));
        case AnalysisViewDimType of
            1:
                begin
                    if AnalysisView."Dimension 1 Code" <> '' then
                        exit('1,6,' + AnalysisView."Dimension 1 Code");

                    exit(Text000);
                end;
            2:
                begin
                    if AnalysisView."Dimension 2 Code" <> '' then
                        exit('1,6,' + AnalysisView."Dimension 2 Code");

                    exit(Text001);
                end;
            3:
                begin
                    if AnalysisView."Dimension 3 Code" <> '' then
                        exit('1,6,' + AnalysisView."Dimension 3 Code");

                    exit(Text002);
                end;
            4:
                begin
                    if AnalysisView."Dimension 4 Code" <> '' then
                        exit('1,6,' + AnalysisView."Dimension 4 Code");

                    exit(Text003);
                end;
        end;
    end;

    /// <summary>
    /// Copies dimension filters from account schedule line to this analysis view record.
    /// </summary>
    /// <param name="AccSchedLine">Account schedule line containing dimension filters to copy</param>
    procedure CopyDimFilters(var AccSchedLine: Record "Acc. Schedule Line")
    begin
        AccSchedLine.CopyFilter("Dimension 1 Filter", "Dimension 1 Filter");
        AccSchedLine.CopyFilter("Dimension 2 Filter", "Dimension 2 Filter");
        AccSchedLine.CopyFilter("Dimension 3 Filter", "Dimension 3 Filter");
        AccSchedLine.CopyFilter("Dimension 4 Filter", "Dimension 4 Filter");
    end;

    /// <summary>
    /// Sets dimension filters for analysis view filtering.
    /// </summary>
    /// <param name="DimFilter1">Dimension 1 filter text</param>
    /// <param name="DimFilter2">Dimension 2 filter text</param>
    /// <param name="DimFilter3">Dimension 3 filter text</param>
    /// <param name="DimFilter4">Dimension 4 filter text</param>
    procedure SetDimFilters(DimFilter1: Text; DimFilter2: Text; DimFilter3: Text; DimFilter4: Text)
    begin
        SetFilter("Dimension 1 Filter", DimFilter1);
        SetFilter("Dimension 2 Filter", DimFilter2);
        SetFilter("Dimension 3 Filter", DimFilter3);
        SetFilter("Dimension 4 Filter", DimFilter4);
    end;

    /// <summary>
    /// Integration event for customizing caption class generation for analysis view dimensions.
    /// </summary>
    /// <param name="GLAccountAnalysisView">G/L Account analysis view record</param>
    /// <param name="AnalysisViewDimType">Dimension type for caption generation</param>
    /// <param name="Result">Caption class result string</param>
    /// <param name="IsHandled">Set to true to skip standard caption class logic</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetCaptionClass(var GLAccountAnalysisView: Record "G/L Account (Analysis View)"; AnalysisViewDimType: Integer; var Result: Text[250]; var IsHandled: Boolean)
    begin
    end;

    local procedure GetAdditionalReportingCurrencyCode(): Code[10]
    var
        GLSetup: Record "General Ledger Setup";
    begin
        GLSetup.Get();
        exit(GLSetup."Additional Reporting Currency");
    end;
}
