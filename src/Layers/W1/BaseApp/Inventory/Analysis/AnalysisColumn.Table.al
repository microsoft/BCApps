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
        }
        field(5; "Column Header"; Text[50])
        {
            Caption = 'Column Header';
        }
        field(6; "Column Type"; Enum "Analysis Column Type")
        {
            Caption = 'Column Type';
            InitValue = "Net Change";
        }
        field(7; "Ledger Entry Type"; Option)
        {
            Caption = 'Ledger Entry Type';
            OptionCaption = 'Item Entries,Item Budget Entries';
            OptionMembers = "Item Entries","Item Budget Entries";
        }
        field(8; Formula; Code[80])
        {
            Caption = 'Formula';

            trigger OnValidate()
            begin
                TempAnalysisLine.CheckFormula(Formula);
            end;
        }
        field(9; "Comparison Date Formula"; DateFormula)
        {
            Caption = 'Comparison Date Formula';

            trigger OnValidate()
            begin
                if Format("Comparison Date Formula") <> '' then
                    Validate("Comparison Period Formula", '');
            end;
        }
        field(10; "Show Opposite Sign"; Boolean)
        {
            Caption = 'Show Opposite Sign';
        }
        field(11; Show; Option)
        {
            Caption = 'Show';
            InitValue = Always;
            OptionCaption = 'Always,Never,When Positive,When Negative';
            OptionMembers = Always,Never,"When Positive","When Negative";
        }
        field(12; "Rounding Factor"; Enum "Analysis Rounding Factor")
        {
            Caption = 'Rounding Factor';
        }
        field(13; "Comparison Period Formula"; Code[20])
        {
            Caption = 'Comparison Period Formula';

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
        }
        field(18; Invoiced; Boolean)
        {
            Caption = 'Invoiced';
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

