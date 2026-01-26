#if not CLEANSCHEMA28 
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft;

using Microsoft.Finance.Analysis;
using Microsoft.Finance.Consolidation;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Budget;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.SalesTax;
using Microsoft.Finance.VAT.Setup;

table 10725 "Hist. G/L Account (An. View)"
{
    Caption = 'Hist. G/L Account (An. View)';
    DataCaptionFields = "No.", Name;
    ObsoleteReason = 'Obsolete feature';
    ObsoleteState = Removed;
    ObsoleteTag = '28.0';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';
            NotBlank = true;
        }
        field(2; Name; Text[30])
        {
            Caption = 'Name';
        }
        field(3; "Search Name"; Code[30])
        {
            Caption = 'Search Name';
        }
        field(4; "Account Type"; Option)
        {
            Caption = 'Account Type';
            OptionCaption = 'Posting,Heading,Total,Begin-Total,End-Total';
            OptionMembers = Posting,Heading,Total,"Begin-Total","End-Total";
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
        field(9; "Income/Balance"; Option)
        {
            Caption = 'Income/Balance';
            OptionCaption = 'Income Statement,Balance Sheet';
            OptionMembers = "Income Statement","Balance Sheet";
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
            AutoFormatType = 1;
            BlankZero = true;
            CalcFormula = sum("Analysis View Entry".Amount where("Analysis View Code" = field("Analysis View Filter"),
                                                                  "Business Unit Code" = field("Business Unit Filter"),
                                                                  "Old G/L Account No." = field("No."),
                                                                  "Old G/L Account No." = field(filter(Totaling)),
                                                                  "Dimension 1 Value Code" = field("Dimension 1 Filter"),
                                                                  "Dimension 2 Value Code" = field("Dimension 2 Filter"),
                                                                  "Dimension 3 Value Code" = field("Dimension 3 Filter"),
                                                                  "Dimension 4 Value Code" = field("Dimension 4 Filter"),
                                                                  "Posting Date" = field(upperlimit("Date Filter"))));
            Caption = 'Balance at Date';
            Editable = false;
            FieldClass = FlowField;
        }
        field(32; "Net Change"; Decimal)
        {
            AutoFormatType = 1;
            BlankZero = true;
            CalcFormula = sum("Analysis View Entry".Amount where("Analysis View Code" = field("Analysis View Filter"),
                                                                  "Business Unit Code" = field("Business Unit Filter"),
                                                                  "Old G/L Account No." = field("No."),
                                                                  "Old G/L Account No." = field(filter(Totaling)),
                                                                  "Dimension 1 Value Code" = field("Dimension 1 Filter"),
                                                                  "Dimension 2 Value Code" = field("Dimension 2 Filter"),
                                                                  "Dimension 3 Value Code" = field("Dimension 3 Filter"),
                                                                  "Dimension 4 Value Code" = field("Dimension 4 Filter"),
                                                                  "Posting Date" = field("Date Filter")));
            Caption = 'Net Change';
            Editable = false;
            FieldClass = FlowField;
        }
        field(33; "Budgeted Amount"; Decimal)
        {
            AutoFormatType = 1;
            BlankZero = true;
            CalcFormula = sum("Analysis View Budget Entry".Amount where("Analysis View Code" = field("Analysis View Filter"),
                                                                         "Budget Name" = field("Budget Filter"),
                                                                         "Business Unit Code" = field("Business Unit Filter"),
                                                                         "Old G/L Account No." = field("No."),
                                                                         "Old G/L Account No." = field(filter(Totaling)),
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
        }
        field(35; "Budget Filter"; Code[10])
        {
            Caption = 'Budget Filter';
            FieldClass = FlowFilter;
            TableRelation = "G/L Budget Name";
        }
        field(36; Balance; Decimal)
        {
            AutoFormatType = 1;
            BlankZero = true;
            CalcFormula = sum("Analysis View Entry".Amount where("Analysis View Code" = field("Analysis View Filter"),
                                                                  "Business Unit Code" = field("Business Unit Filter"),
                                                                  "Old G/L Account No." = field("No."),
                                                                  "Old G/L Account No." = field(filter(Totaling)),
                                                                  "Dimension 1 Value Code" = field("Dimension 1 Filter"),
                                                                  "Dimension 2 Value Code" = field("Dimension 2 Filter"),
                                                                  "Dimension 3 Value Code" = field("Dimension 3 Filter"),
                                                                  "Dimension 4 Value Code" = field("Dimension 4 Filter"),
                                                                  "Posting Date" = field("Date Filter")));
            Caption = 'Balance';
            Editable = false;
            FieldClass = FlowField;
        }
        field(37; "Budgeted at Date"; Decimal)
        {
            AutoFormatType = 1;
            BlankZero = true;
            CalcFormula = sum("Analysis View Budget Entry".Amount where("Analysis View Code" = field("Analysis View Filter"),
                                                                         "Budget Name" = field("Budget Filter"),
                                                                         "Business Unit Code" = field("Business Unit Filter"),
                                                                         "Old G/L Account No." = field("No."),
                                                                         "Old G/L Account No." = field(filter(Totaling)),
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
            Caption = 'Consol. Debit Acc.';
        }
        field(41; "Consol. Credit Acc."; Code[20])
        {
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
            AutoFormatType = 1;
            BlankZero = true;
            CalcFormula = sum("Analysis View Entry"."Debit Amount" where("Analysis View Code" = field("Analysis View Filter"),
                                                                          "Business Unit Code" = field("Business Unit Filter"),
                                                                          "Old G/L Account No." = field("No."),
                                                                          "Old G/L Account No." = field(filter(Totaling)),
                                                                          "Dimension 1 Value Code" = field("Dimension 1 Filter"),
                                                                          "Dimension 2 Value Code" = field("Dimension 2 Filter"),
                                                                          "Dimension 3 Value Code" = field("Dimension 3 Filter"),
                                                                          "Dimension 4 Value Code" = field("Dimension 4 Filter"),
                                                                          "Posting Date" = field("Date Filter")));
            Caption = 'Debit Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(48; "Credit Amount"; Decimal)
        {
            AutoFormatType = 1;
            BlankZero = true;
            CalcFormula = sum("Analysis View Entry"."Credit Amount" where("Analysis View Code" = field("Analysis View Filter"),
                                                                           "Business Unit Code" = field("Business Unit Filter"),
                                                                           "Old G/L Account No." = field("No."),
                                                                           "Old G/L Account No." = field(filter(Totaling)),
                                                                           "Dimension 1 Value Code" = field("Dimension 1 Filter"),
                                                                           "Dimension 2 Value Code" = field("Dimension 2 Filter"),
                                                                           "Dimension 3 Value Code" = field("Dimension 3 Filter"),
                                                                           "Dimension 4 Value Code" = field("Dimension 4 Filter"),
                                                                           "Posting Date" = field("Date Filter")));
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
            AutoFormatType = 1;
            BlankNumbers = BlankNegAndZero;
            BlankZero = true;
            CalcFormula = sum("Analysis View Budget Entry".Amount where("Analysis View Code" = field("Analysis View Filter"),
                                                                         "Budget Name" = field("Budget Filter"),
                                                                         "Business Unit Code" = field("Business Unit Filter"),
                                                                         "Old G/L Account No." = field("No."),
                                                                         "Old G/L Account No." = field(filter(Totaling)),
                                                                         "Dimension 1 Value Code" = field("Dimension 1 Filter"),
                                                                         "Dimension 2 Value Code" = field("Dimension 2 Filter"),
                                                                         "Dimension 3 Value Code" = field("Dimension 3 Filter"),
                                                                         "Dimension 4 Value Code" = field("Dimension 4 Filter"),
                                                                         "Posting Date" = field("Date Filter")));
            Caption = 'Budgeted Debit Amount';
            FieldClass = FlowField;
        }
        field(53; "Budgeted Credit Amount"; Decimal)
        {
            AutoFormatType = 1;
            BlankNumbers = BlankZeroAndPos;
            BlankZero = true;
            CalcFormula = - sum("Analysis View Budget Entry".Amount where("Analysis View Code" = field("Analysis View Filter"),
                                                                          "Budget Name" = field("Budget Filter"),
                                                                          "Business Unit Code" = field("Business Unit Filter"),
                                                                          "Old G/L Account No." = field("No."),
                                                                          "Old G/L Account No." = field(filter(Totaling)),
                                                                          "Dimension 1 Value Code" = field("Dimension 1 Filter"),
                                                                          "Dimension 2 Value Code" = field("Dimension 2 Filter"),
                                                                          "Dimension 3 Value Code" = field("Dimension 3 Filter"),
                                                                          "Dimension 4 Value Code" = field("Dimension 4 Filter"),
                                                                          "Posting Date" = field("Date Filter")));
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
            AutoFormatType = 1;
            BlankZero = true;
            CalcFormula = sum("Analysis View Entry"."Add.-Curr. Amount" where("Analysis View Code" = field("Analysis View Filter"),
                                                                               "Business Unit Code" = field("Business Unit Filter"),
                                                                               "Old G/L Account No." = field("No."),
                                                                               "Old G/L Account No." = field(filter(Totaling)),
                                                                               "Dimension 1 Value Code" = field("Dimension 1 Filter"),
                                                                               "Dimension 2 Value Code" = field("Dimension 2 Filter"),
                                                                               "Dimension 3 Value Code" = field("Dimension 3 Filter"),
                                                                               "Dimension 4 Value Code" = field("Dimension 4 Filter"),
                                                                               "Posting Date" = field("Date Filter")));
            Caption = 'Additional-Currency Net Change';
            Editable = false;
            FieldClass = FlowField;
        }
        field(61; "Add.-Currency Balance at Date"; Decimal)
        {
            AutoFormatType = 1;
            BlankZero = true;
            CalcFormula = sum("Analysis View Entry"."Add.-Curr. Amount" where("Analysis View Code" = field("Analysis View Filter"),
                                                                               "Business Unit Code" = field("Business Unit Filter"),
                                                                               "Old G/L Account No." = field("No."),
                                                                               "Old G/L Account No." = field(filter(Totaling)),
                                                                               "Dimension 1 Value Code" = field("Dimension 1 Filter"),
                                                                               "Dimension 2 Value Code" = field("Dimension 2 Filter"),
                                                                               "Dimension 3 Value Code" = field("Dimension 3 Filter"),
                                                                               "Dimension 4 Value Code" = field("Dimension 4 Filter"),
                                                                               "Posting Date" = field(upperlimit("Date Filter"))));
            Caption = 'Add.-Currency Balance at Date';
            Editable = false;
            FieldClass = FlowField;
        }
        field(62; "Additional-Currency Balance"; Decimal)
        {
            AutoFormatType = 1;
            BlankZero = true;
            CalcFormula = sum("Analysis View Entry"."Add.-Curr. Amount" where("Analysis View Code" = field("Analysis View Filter"),
                                                                               "Business Unit Code" = field("Business Unit Filter"),
                                                                               "Old G/L Account No." = field("No."),
                                                                               "Old G/L Account No." = field(filter(Totaling)),
                                                                               "Dimension 1 Value Code" = field("Dimension 1 Filter"),
                                                                               "Dimension 2 Value Code" = field("Dimension 2 Filter"),
                                                                               "Dimension 3 Value Code" = field("Dimension 3 Filter"),
                                                                               "Dimension 4 Value Code" = field("Dimension 4 Filter"),
                                                                               "Posting Date" = field("Date Filter")));
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
            AutoFormatType = 1;
            BlankZero = true;
            CalcFormula = sum("Analysis View Entry"."Add.-Curr. Debit Amount" where("Analysis View Code" = field("Analysis View Filter"),
                                                                                     "Business Unit Code" = field("Business Unit Filter"),
                                                                                     "Old G/L Account No." = field("No."),
                                                                                     "Old G/L Account No." = field(filter(Totaling)),
                                                                                     "Dimension 1 Value Code" = field("Dimension 1 Filter"),
                                                                                     "Dimension 2 Value Code" = field("Dimension 2 Filter"),
                                                                                     "Dimension 3 Value Code" = field("Dimension 3 Filter"),
                                                                                     "Dimension 4 Value Code" = field("Dimension 4 Filter"),
                                                                                     "Posting Date" = field("Date Filter")));
            Caption = 'Add.-Currency Debit Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(65; "Add.-Currency Credit Amount"; Decimal)
        {
            AutoFormatType = 1;
            BlankZero = true;
            CalcFormula = sum("Analysis View Entry"."Add.-Curr. Credit Amount" where("Analysis View Code" = field("Analysis View Filter"),
                                                                                      "Business Unit Code" = field("Business Unit Filter"),
                                                                                      "Old G/L Account No." = field("No."),
                                                                                      "Old G/L Account No." = field(filter(Totaling)),
                                                                                      "Dimension 1 Value Code" = field("Dimension 1 Filter"),
                                                                                      "Dimension 2 Value Code" = field("Dimension 2 Filter"),
                                                                                      "Dimension 3 Value Code" = field("Dimension 3 Filter"),
                                                                                      "Dimension 4 Value Code" = field("Dimension 4 Filter"),
                                                                                      "Posting Date" = field("Date Filter")));
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
        key(Key1; "No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
        Text1100000: Label '1,6,,Dimension 1 Filter';
        Text1100001: Label '1,6,,Dimension 2 Filter';
        Text1100002: Label '1,6,,Dimension 3 Filter';
        Text1100003: Label '1,6,,Dimension 4 Filter';
        GLSetup: Record "General Ledger Setup";
        AnalysisView: Record "Analysis View";
        GLSetupRead: Boolean;

    [Scope('OnPrem')]
    procedure GetCurrencyCode(): Code[10]
    begin
        if not GLSetupRead then begin
            GLSetup.Get();
            GLSetupRead := true;
        end;
        exit(GLSetup."Additional Reporting Currency");
    end;

    [Scope('OnPrem')]
    procedure GetCaptionClass(AnalysisViewDimType: Integer): Text[250]
    begin
        if AnalysisView.Code <> GetFilter("Analysis View Filter") then
            AnalysisView.Get(GetFilter("Analysis View Filter"));
        case AnalysisViewDimType of
            1:
                begin
                    if AnalysisView."Dimension 1 Code" <> '' then
                        exit('1,6,' + AnalysisView."Dimension 1 Code");

                    exit(Text1100000);
                end;
            2:
                begin
                    if AnalysisView."Dimension 2 Code" <> '' then
                        exit('1,6,' + AnalysisView."Dimension 2 Code");

                    exit(Text1100001);
                end;
            3:
                begin
                    if AnalysisView."Dimension 3 Code" <> '' then
                        exit('1,6,' + AnalysisView."Dimension 3 Code");

                    exit(Text1100002);
                end;
            4:
                begin
                    if AnalysisView."Dimension 4 Code" <> '' then
                        exit('1,6,' + AnalysisView."Dimension 4 Code");

                    exit(Text1100003);
                end;
        end;
    end;
}

 
#endif