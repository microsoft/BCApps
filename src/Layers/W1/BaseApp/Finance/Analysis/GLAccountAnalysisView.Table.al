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

table 376 "G/L Account (Analysis View)"
{
    Caption = 'G/L Account (Analysis View)';
    DataCaptionFields = "No.", Name;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';
            NotBlank = true;
            TableRelation = if ("Account Source" = const("G/L Account")) "G/L Account"
            else
            if ("Account Source" = const("Cash Flow Account")) "Cash Flow Account";
        }
        field(2; Name; Text[100])
        {
            Caption = 'Name';
        }
        field(3; "Search Name"; Code[100])
        {
            Caption = 'Search Name';
        }
        field(4; "Account Type"; Enum "G/L Account Type")
        {
            Caption = 'Account Type';
        }
        field(5; "Account Source"; Enum "Analysis Account Source")
        {
            Caption = 'Account Source';
        }
        field(6; "Global Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,1,1';
            Caption = 'Global Dimension 1 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1));
        }
        field(7; "Global Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,1,2';
            Caption = 'Global Dimension 2 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2));
        }
        field(9; "Income/Balance"; Enum "G/L Account Report Type")
        {
            Caption = 'Income/Balance';
        }
        field(10; "Debit/Credit"; Option)
        {
            Caption = 'Debit/Credit';
            OptionCaption = 'Both,Debit,Credit';
            OptionMembers = Both,Debit,Credit;
        }
        field(11; "No. 2"; Code[20])
        {
            Caption = 'No. 2';
        }
        field(12; Comment; Boolean)
        {
            CalcFormula = exist("Comment Line" where("Table Name" = const("G/L Account"),
                                                      "No." = field("No.")));
            Caption = 'Comment';
            Editable = false;
            FieldClass = FlowField;
        }
        field(13; Blocked; Boolean)
        {
            Caption = 'Blocked';
        }
        field(14; "Direct Posting"; Boolean)
        {
            Caption = 'Direct Posting';
            InitValue = true;
        }
        field(16; "Reconciliation Account"; Boolean)
        {
            Caption = 'Reconciliation Account';
        }
        field(17; "New Page"; Boolean)
        {
            Caption = 'New Page';
        }
        field(18; "No. of Blank Lines"; Integer)
        {
            Caption = 'No. of Blank Lines';
            MinValue = 0;
        }
        field(19; Indentation; Integer)
        {
            Caption = 'Indentation';
            MinValue = 0;
        }
        field(26; "Last Date Modified"; Date)
        {
            Caption = 'Last Date Modified';
            Editable = false;
        }
        field(27; "Cash Flow Forecast Filter"; Code[20])
        {
            Caption = 'Cash Flow Forecast Filter';
            FieldClass = FlowFilter;
            TableRelation = "Cash Flow Forecast";
        }
        field(28; "Date Filter"; Date)
        {
            Caption = 'Date Filter';
            FieldClass = FlowFilter;
        }
        field(29; "Global Dimension 1 Filter"; Code[20])
        {
            CaptionClass = '1,3,1';
            Caption = 'Global Dimension 1 Filter';
            FieldClass = FlowFilter;
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1));
        }
        field(30; "Global Dimension 2 Filter"; Code[20])
        {
            CaptionClass = '1,3,2';
            Caption = 'Global Dimension 2 Filter';
            FieldClass = FlowFilter;
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2));
        }
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
            Editable = false;
            FieldClass = FlowField;
        }
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
            Editable = false;
            FieldClass = FlowField;
        }
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
            FieldClass = FlowField;
        }
        field(34; Totaling; Text[250])
        {
            Caption = 'Totaling';
            TableRelation = if ("Account Source" = const("G/L Account")) "G/L Account"
            else
            if ("Account Source" = const("Cash Flow Account")) "Cash Flow Account";
            ValidateTableRelation = false;
        }
        field(35; "Budget Filter"; Code[10])
        {
            Caption = 'Budget Filter';
            FieldClass = FlowFilter;
            TableRelation = "G/L Budget Name";
        }
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
            Editable = false;
            FieldClass = FlowField;
        }
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
        field(40; "Consol. Debit Acc."; Code[20])
        {
            AccessByPermission = TableData "Business Unit" = R;
            Caption = 'Consol. Debit Acc.';
        }
        field(41; "Consol. Credit Acc."; Code[20])
        {
            AccessByPermission = TableData "Business Unit" = R;
            Caption = 'Consol. Credit Acc.';
        }
        field(42; "Business Unit Filter"; Code[20])
        {
            Caption = 'Business Unit Filter';
            FieldClass = FlowFilter;
            TableRelation = "Business Unit";
        }
        field(43; "Gen. Posting Type"; Option)
        {
            Caption = 'Gen. Posting Type';
            OptionCaption = ' ,Purchase,Sale';
            OptionMembers = " ",Purchase,Sale;
        }
        field(44; "Gen. Bus. Posting Group"; Code[20])
        {
            Caption = 'Gen. Bus. Posting Group';
            TableRelation = "Gen. Business Posting Group";
        }
        field(45; "Gen. Prod. Posting Group"; Code[20])
        {
            Caption = 'Gen. Prod. Posting Group';
            TableRelation = "Gen. Product Posting Group";
        }
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
        field(49; "Automatic Ext. Texts"; Boolean)
        {
            Caption = 'Automatic Ext. Texts';
        }
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
        field(54; "Tax Area Code"; Code[20])
        {
            Caption = 'Tax Area Code';
            TableRelation = "Tax Area";
        }
        field(55; "Tax Liable"; Boolean)
        {
            Caption = 'Tax Liable';
        }
        field(56; "Tax Group Code"; Code[20])
        {
            Caption = 'Tax Group Code';
            TableRelation = "Tax Group";
        }
        field(57; "VAT Bus. Posting Group"; Code[20])
        {
            Caption = 'VAT Bus. Posting Group';
            TableRelation = "VAT Business Posting Group";
        }
        field(58; "VAT Prod. Posting Group"; Code[20])
        {
            Caption = 'VAT Prod. Posting Group';
            TableRelation = "VAT Product Posting Group";
        }
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
            Editable = false;
            FieldClass = FlowField;
        }
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
            Editable = false;
            FieldClass = FlowField;
        }
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
            Editable = false;
            FieldClass = FlowField;
        }
        field(63; "Exchange Rate Adjustment"; Option)
        {
            Caption = 'Exchange Rate Adjustment';
            OptionCaption = 'No Adjustment,Adjust Amount,Adjust Additional-Currency Amount';
            OptionMembers = "No Adjustment","Adjust Amount","Adjust Additional-Currency Amount";
        }
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
        field(66; "Analysis View Filter"; Code[10])
        {
            Caption = 'Analysis View Filter';
            FieldClass = FlowFilter;
            TableRelation = "Analysis View";
        }
        field(67; "Dimension 1 Filter"; Code[20])
        {
            CaptionClass = GetCaptionClass(1);
            Caption = 'Dimension 1 Filter';
            FieldClass = FlowFilter;
        }
        field(68; "Dimension 2 Filter"; Code[20])
        {
            CaptionClass = GetCaptionClass(2);
            Caption = 'Dimension 2 Filter';
            FieldClass = FlowFilter;
        }
        field(69; "Dimension 3 Filter"; Code[20])
        {
            CaptionClass = GetCaptionClass(3);
            Caption = 'Dimension 3 Filter';
            FieldClass = FlowFilter;
        }
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

    procedure CopyDimFilters(var AccSchedLine: Record "Acc. Schedule Line")
    begin
        AccSchedLine.CopyFilter("Dimension 1 Filter", "Dimension 1 Filter");
        AccSchedLine.CopyFilter("Dimension 2 Filter", "Dimension 2 Filter");
        AccSchedLine.CopyFilter("Dimension 3 Filter", "Dimension 3 Filter");
        AccSchedLine.CopyFilter("Dimension 4 Filter", "Dimension 4 Filter");
    end;

    procedure SetDimFilters(DimFilter1: Text; DimFilter2: Text; DimFilter3: Text; DimFilter4: Text)
    begin
        SetFilter("Dimension 1 Filter", DimFilter1);
        SetFilter("Dimension 2 Filter", DimFilter2);
        SetFilter("Dimension 3 Filter", DimFilter3);
        SetFilter("Dimension 4 Filter", DimFilter4);
    end;

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
