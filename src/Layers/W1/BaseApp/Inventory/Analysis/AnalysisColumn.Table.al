// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Analysis;

using Microsoft.Foundation.Enums;
using Microsoft.Foundation.Period;

table 7118 "Analysis Column"
{
    Caption = 'Analysis Column';
    DrillDownPageID = "Analysis Columns";
    LookupPageID = "Analysis Columns";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Analysis Area"; Enum "Analysis Area Type")
        {
            Caption = 'Analysis Area';
        }
        field(2; "Analysis Column Template"; Code[10])
        {
            Caption = 'Analysis Column Template';
            TableRelation = "Analysis Column Template".Name where("Analysis Area" = field("Analysis Area"));
        }
        field(3; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(4; "Column No."; Code[10])
        {
            Caption = 'Column No.';
            ToolTip = 'Specifies a number for the column in the analysis view.';
        }
        field(5; "Column Header"; Text[50])
        {
            Caption = 'Column Header';
            ToolTip = 'Specifies a header for the column as you want it to appear on printed reports.';
        }
        field(6; "Column Type"; Enum "Analysis Column Type")
        {
            Caption = 'Column Type';
            ToolTip = 'Specifies the analysis column type, which determines how the amounts in the column are calculated.';
            InitValue = "Net Change";
        }
        field(7; "Ledger Entry Type"; Option)
        {
            Caption = 'Ledger Entry Type';
            ToolTip = 'Specifies the type of ledger entries that will be included in the amounts in the analysis column.';
            OptionCaption = 'Item Entries,Item Budget Entries';
            OptionMembers = "Item Entries","Item Budget Entries";
        }
        field(8; Formula; Code[80])
        {
            Caption = 'Formula';
            ToolTip = 'Specifies a formula for how data is shown in the column when the analysis report is printed.';

            trigger OnValidate()
            begin
                TempAnalysisLine.CheckFormula(Formula);
            end;
        }
        field(9; "Comparison Date Formula"; DateFormula)
        {
            Caption = 'Comparison Date Formula';
            ToolTip = 'Specifies a date formula that specifies which dates should be used to calculate the amount in this column.';

            trigger OnValidate()
            begin
                if Format("Comparison Date Formula") <> '' then
                    Validate("Comparison Period Formula", '');
            end;
        }
        field(10; "Show Opposite Sign"; Boolean)
        {
            Caption = 'Show Opposite Sign';
            ToolTip = 'Specifies if you want purchases and positive adjustments to be shown as negative amounts and sales and negative adjustments to be shown as positive amounts.';
        }
        field(11; Show; Option)
        {
            Caption = 'Show';
            ToolTip = 'Specifies when you want the amounts in the column to be shown in reports.';
            InitValue = Always;
            OptionCaption = 'Always,Never,When Positive,When Negative';
            OptionMembers = Always,Never,"When Positive","When Negative";
        }
        field(12; "Rounding Factor"; Enum "Analysis Rounding Factor")
        {
            Caption = 'Rounding Factor';
            ToolTip = 'Specifies a rounding factor for the amounts in the column.';
        }
        field(13; "Comparison Period Formula"; Code[20])
        {
            Caption = 'Comparison Period Formula';
            ToolTip = 'Specifies a period formula that specifies the accounting periods you want to use to calculate the amount in this column.';

            trigger OnValidate()
            var
                PeriodFormulaParser: Codeunit "Period Formula Parser";
            begin
                "Comparison Period Formula LCID" := GlobalLanguage;
                PeriodFormulaParser.ParsePeriodFormula("Comparison Period Formula", "Comparison Period Formula LCID");
                if "Comparison Period Formula" <> '' then
                    Clear("Comparison Date Formula");
            end;
        }
        field(14; "Analysis Type Code"; Code[10])
        {
            Caption = 'Analysis Type Code';
            ToolTip = 'Specifies the analysis type to apply to the column.';
            TableRelation = "Analysis Type";

            trigger OnValidate()
            var
                ItemAnalysisType: Record "Analysis Type";
            begin
                if "Analysis Type Code" <> '' then begin
                    ItemAnalysisType.Get("Analysis Type Code");
                    if "Column Header" = '' then
                        "Column Header" := ItemAnalysisType.Name;
                    "Item Ledger Entry Type Filter" := ItemAnalysisType."Item Ledger Entry Type Filter";
                    "Value Entry Type Filter" := ItemAnalysisType."Value Entry Type Filter";
                    "Value Type" := ItemAnalysisType."Value Type";
                end;
            end;
        }
        field(15; "Item Ledger Entry Type Filter"; Text[250])
        {
            Caption = 'Item Ledger Entry Type Filter';
            ToolTip = 'Specifies the filter that applies to the item ledger entry type that you want this column to be calculated from.';

            trigger OnValidate()
            begin
                AnalysisRepMgmt.ValidateFilter(
                  "Item Ledger Entry Type Filter", DATABASE::"Analysis Column",
                  FieldNo("Item Ledger Entry Type Filter"), true);
            end;
        }
        field(16; "Value Entry Type Filter"; Text[250])
        {
            Caption = 'Value Entry Type Filter';
            ToolTip = 'Specifies the filter that applies to the item value entry type that you want this column to be calculated from.';

            trigger OnValidate()
            begin
                AnalysisRepMgmt.ValidateFilter(
                  "Value Entry Type Filter", DATABASE::"Analysis Column",
                  FieldNo("Value Entry Type Filter"), true);
            end;
        }
        field(17; "Value Type"; Enum "Analysis Value Type")
        {
            Caption = 'Value Type';
            ToolTip = 'Specifies the source data that the source data type in the Analysis Type Code field, in the Analysis Columns window, is based on.';
        }
        field(18; Invoiced; Boolean)
        {
            Caption = 'Invoiced';
            ToolTip = 'Specifies if you want the analysis report to be based on invoiced amounts. If left field blank, the report will be based on expected amounts.';
        }
        field(30; "Comparison Period Formula LCID"; Integer)
        {
            Caption = 'Comparison Period Formula LCID';
        }
    }

    keys
    {
        key(Key1; "Analysis Area", "Analysis Column Template", "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
        TempAnalysisLine: Record "Analysis Line" temporary;
        AnalysisRepMgmt: Codeunit "Analysis Report Management";

#if not CLEAN27
    [Obsolete('Moved to codeunit Period Formula Parser', '27.0')]
    procedure ParsePeriodFormula(FormulaExpression: Code[20]; var Steps: Integer; var Type: Enum "Period Type"; var RangeFromType: Enum "Period Formula Range"; var RangeToType: Enum "Period Formula Range"; var RangeFromInt: Integer; var RangeToInt: Integer)
    var
        PeriodFormulaParser: Codeunit "Period Formula Parser";
    begin
        PeriodFormulaParser.ParsePeriodFormula(
            FormulaExpression,
            Steps,
            Type,
            RangeFromType,
            RangeToType,
            RangeFromInt,
            RangeToInt,
            "Comparison Period Formula LCID");
    end;
#endif
}

