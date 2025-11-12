// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.FinancialReports;

using Microsoft.CostAccounting.Setup;
using Microsoft.Finance.Analysis;
using Microsoft.Finance.Consolidation;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Budget;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Enums;
using Microsoft.Foundation.Period;

table 334 "Column Layout"
{
    Caption = 'Column Layout';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Column Layout Name"; Code[10])
        {
            Caption = 'Column Layout Name';
            TableRelation = "Column Layout Name";
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(3; "Column No."; Code[10])
        {
            Caption = 'Column No.';
        }
        field(4; "Column Header"; Text[30])
        {
            Caption = 'Column Header';
        }
        field(5; "Column Type"; Enum "Column Layout Type")
        {
            Caption = 'Column Type';
            InitValue = "Net Change";
        }
        field(6; "Ledger Entry Type"; Enum "Column Layout Entry Type")
        {
            Caption = 'Ledger Entry Type';
        }
        field(7; "Amount Type"; Enum "Account Schedule Amount Type")
        {
            Caption = 'Amount Type';
        }
        field(8; Formula; Code[80])
        {
            Caption = 'Formula';

            trigger OnValidate()
            var
                TempAccSchedLine: Record "Acc. Schedule Line" temporary;
            begin
                TempAccSchedLine.CheckFormula(Formula);
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
        field(11; Show; Enum "Column Layout Show")
        {
            Caption = 'Show';
            InitValue = Always;
        }
        field(12; "Rounding Factor"; Enum "Analysis Rounding Factor")
        {
            Caption = 'Rounding Factor';
        }
        field(13; "Show Indented Lines"; Option)
        {
            Caption = 'Show Indented Lines';
            OptionCaption = 'All,Indented Only,Non-Indented Only';
            OptionMembers = All,"Indented Only","Non-Indented Only";
        }
        field(14; "Comparison Period Formula"; Code[20])
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
        field(15; "Business Unit Totaling"; Text[80])
        {
            Caption = 'Business Unit Totaling';
            TableRelation = "Business Unit";
            ValidateTableRelation = false;
        }
        field(16; "Dimension 1 Totaling"; Text[80])
        {
            AccessByPermission = TableData Dimension = R;
            CaptionClass = GetCaptionClass(5);
            Caption = 'Dimension 1 Totaling';
        }
        field(17; "Dimension 2 Totaling"; Text[80])
        {
            AccessByPermission = TableData Dimension = R;
            CaptionClass = GetCaptionClass(6);
            Caption = 'Dimension 2 Totaling';
        }
        field(18; "Dimension 3 Totaling"; Text[80])
        {
            AccessByPermission = TableData "Dimension Combination" = R;
            CaptionClass = GetCaptionClass(7);
            Caption = 'Dimension 3 Totaling';
        }
        field(19; "Dimension 4 Totaling"; Text[80])
        {
            AccessByPermission = TableData "Dimension Combination" = R;
            CaptionClass = GetCaptionClass(8);
            Caption = 'Dimension 4 Totaling';
        }
        field(20; "Cost Center Totaling"; Text[80])
        {
            Caption = 'Cost Center Totaling';
        }
        field(21; "Cost Object Totaling"; Text[80])
        {
            Caption = 'Cost Object Totaling';
        }
        field(30; "Comparison Period Formula LCID"; Integer)
        {
            Caption = 'Comparison Period Formula LCID';
        }
        field(35; "Budget Name"; Code[10])
        {
            Caption = 'Budget Name';
            TableRelation = "G/L Budget Name";
        }
        field(40; "Hide Currency Symbol"; Boolean)
        {
            Caption = 'Hide Currency Symbol';

            trigger OnValidate()
            begin
                if "Hide Currency Symbol" then
                    TestField("Column Type", "Column Layout Type"::Formula);
            end;
        }
        field(41; "Include Date In Header"; Enum ColumnHeaderDateType)
        {
            Caption = 'Include Date in Column Header';
            ToolTip = 'Specifies how the ending date of the Date Filter applied to the column is displayed on the Column Header.';
        }
        field(42; "G/L Account Totaling"; Text[250])
        {
            Caption = 'G/L Account Totaling';
            ToolTip = 'Specifies which G/L accounts will be totaled in this column.';

            trigger OnLookup()
            var
                GLAccountList: Page "G/L Account List";
            begin
                GLAccountList.LookupMode(true);
                if GLAccountList.RunModal() = Action::LookupOK then
                    Validate("G/L Account Totaling", GLAccountList.GetSelectionFilter());
            end;

            trigger OnValidate()
            var
                GLAccount: Record "G/L Account";
            begin
                GLAccount.SetFilter("No.", "G/L Account Totaling");
            end;
        }
        field(43; "Show in ACY"; Boolean)
        {
            Caption = 'Show in ACY';
            ToolTip = 'Specifies whether amounts are shown in the Additional Reporting Currency.';
        }
    }

    keys
    {
        key(Key1; "Column Layout Name", "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
        ColumnLayoutName: Record "Column Layout Name";
        AnalysisView: Record "Analysis View";
        GLSetup: Record "General Ledger Setup";
        HasGLSetup: Boolean;

#pragma warning disable AA0074
        Text006: Label '1,6,,Dimension 1 Filter';
        Text007: Label '1,6,,Dimension 2 Filter';
        Text008: Label '1,6,,Dimension 3 Filter';
        Text009: Label '1,6,,Dimension 4 Filter';
        Text010: Label ',, Totaling';
        Text011: Label '1,5,,Dimension 1 Totaling';
        Text012: Label '1,5,,Dimension 2 Totaling';
        Text013: Label '1,5,,Dimension 3 Totaling';
        Text014: Label '1,5,,Dimension 4 Totaling';
#pragma warning disable AA0470
        Text015: Label 'The %1 refers to %2 %3, which does not exist. The field %4 on table %5 has now been deleted.';
#pragma warning restore AA0470
#pragma warning restore AA0074

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

    procedure LookUpDimFilter(DimNo: Integer; var Text: Text[250]) Result: Boolean
    var
        DimVal: Record "Dimension Value";
        CostAccSetup: Record "Cost Accounting Setup";
        DimValList: Page "Dimension Value List";
        IsHandled: Boolean;
    begin
        GetColLayoutSetup();

        IsHandled := false;
        OnBeforeLookUpDimFilter(Rec, DimNo, Text, ColumnLayoutName, Result, IsHandled, AnalysisView);
        if IsHandled then
            exit(Result);

        if CostAccSetup.Get() then;
        case DimNo of
            1:
                DimVal.SetRange("Dimension Code", AnalysisView."Dimension 1 Code");
            2:
                DimVal.SetRange("Dimension Code", AnalysisView."Dimension 2 Code");
            3:
                DimVal.SetRange("Dimension Code", AnalysisView."Dimension 3 Code");
            4:
                DimVal.SetRange("Dimension Code", AnalysisView."Dimension 4 Code");
            5:
                DimVal.SetRange("Dimension Code", CostAccSetup."Cost Center Dimension");
            6:
                DimVal.SetRange("Dimension Code", CostAccSetup."Cost Object Dimension");
        end;
        DimValList.LookupMode(true);
        DimValList.SetTableView(DimVal);
        if DimValList.RunModal() = ACTION::LookupOK then begin
            DimValList.GetRecord(DimVal);
            Text := DimValList.GetSelectionFilter();
            exit(true);
        end;
        exit(false)
    end;

    procedure GetCaptionClass(AnalysisViewDimType: Integer) Result: Text[250]
    var
        IsHandled: Boolean;
    begin
        GetColLayoutSetup();

        IsHandled := false;
        OnBeforeGetCaptionClass(Rec, ColumnLayoutName, AnalysisViewDimType, Result, IsHandled);
        if IsHandled then
            exit(Result);

        case AnalysisViewDimType of
            1:
                begin
                    if AnalysisView."Dimension 1 Code" <> '' then
                        exit('1,6,' + AnalysisView."Dimension 1 Code");

                    exit(Text006);
                end;
            2:
                begin
                    if AnalysisView."Dimension 2 Code" <> '' then
                        exit('1,6,' + AnalysisView."Dimension 2 Code");

                    exit(Text007);
                end;
            3:
                begin
                    if AnalysisView."Dimension 3 Code" <> '' then
                        exit('1,6,' + AnalysisView."Dimension 3 Code");

                    exit(Text008);
                end;
            4:
                begin
                    if AnalysisView."Dimension 4 Code" <> '' then
                        exit('1,6,' + AnalysisView."Dimension 4 Code");

                    exit(Text009);
                end;
            5:
                begin
                    if AnalysisView."Dimension 1 Code" <> '' then
                        exit('1,5,' + AnalysisView."Dimension 1 Code" + Text010);

                    exit(Text011);
                end;
            6:
                begin
                    if AnalysisView."Dimension 2 Code" <> '' then
                        exit('1,5,' + AnalysisView."Dimension 2 Code" + Text010);

                    exit(Text012);
                end;
            7:
                begin
                    if AnalysisView."Dimension 3 Code" <> '' then
                        exit('1,5,' + AnalysisView."Dimension 3 Code" + Text010);

                    exit(Text013);
                end;
            8:
                begin
                    if AnalysisView."Dimension 4 Code" <> '' then
                        exit('1,5,' + AnalysisView."Dimension 4 Code" + Text010);

                    exit(Text014);
                end;
        end;
    end;

    local procedure GetColLayoutSetup()
    begin
        if "Column Layout Name" <> ColumnLayoutName.Name then
            ColumnLayoutName.Get("Column Layout Name");
        if ColumnLayoutName."Analysis View Name" <> '' then
            if ColumnLayoutName."Analysis View Name" <> AnalysisView.Code then
                if not AnalysisView.Get(ColumnLayoutName."Analysis View Name") then begin
                    Message(
                      Text015,
                      ColumnLayoutName.TableCaption(), AnalysisView.TableCaption(), ColumnLayoutName."Analysis View Name",
                      ColumnLayoutName.FieldCaption("Analysis View Name"), ColumnLayoutName.TableCaption());
                    ColumnLayoutName."Analysis View Name" := '';
                    ColumnLayoutName.Modify();
                end;

        if ColumnLayoutName."Analysis View Name" = '' then begin
            if not HasGLSetup then begin
                GLSetup.Get();
                HasGLSetup := true;
            end;
            Clear(AnalysisView);
            AnalysisView."Dimension 1 Code" := GLSetup."Global Dimension 1 Code";
            AnalysisView."Dimension 2 Code" := GLSetup."Global Dimension 2 Code";
        end;
    end;

#if not CLEAN27
    [Obsolete('Moved to codeunit Period Formula Parser', '27.0')]
    procedure GetPeriodName(): Code[10]
    var
        PeriodFormulaParser: Codeunit "Period Formula Parser";
    begin
        exit(PeriodFormulaParser.GetPeriodName());
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetCaptionClass(var ColumnLayout: Record "Column Layout"; ColumnLayoutName: Record "Column Layout Name"; AnalysisViewDimType: Integer; var Result: Text[250]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeLookUpDimFilter(var ColumnLayout: Record "Column Layout"; DimNo: Integer; var Text: Text[250]; ColumnLayoutName: Record "Column Layout Name"; var Result: Boolean; var IsHandled: Boolean; var AnalysisView: Record "Analysis View")
    begin
    end;
}

