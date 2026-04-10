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

/// <summary>
/// Defines column layout structure for account schedule reports and analysis.
/// Contains period formulas, display options, dimension filters, and calculation parameters for financial reporting columns.
/// </summary>
/// <remarks>
/// Key relationships: Column Layout Name, Account Schedule Line calculations, Analysis Views.
/// Extensible via table extensions for custom column types and additional filtering dimensions.
/// Integrates with budget systems, cost accounting, and multi-dimensional analysis reporting.
/// </remarks>
table 334 "Column Layout"
{
    Caption = 'Column Layout';
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Column layout name that groups related column definitions for account schedule reporting.
        /// </summary>
        field(1; "Column Layout Name"; Code[10])
        {
            Caption = 'Column Layout Name';
            TableRelation = "Column Layout Name";
        }
        /// <summary>
        /// Unique line number identifying column position within the column layout.
        /// </summary>
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
            ToolTip = 'Specifies the line number for the financial report column.';
        }
        /// <summary>
        /// Column identifier displayed in account schedule headers and used for formula references.
        /// </summary>
        field(3; "Column No."; Code[10])
        {
            Caption = 'Column No.';
            ToolTip = 'Specifies a number for the column in the analysis view.';
        }
        /// <summary>
        /// Display header text shown at the top of the column in account schedule reports.
        /// </summary>
        field(4; "Column Header"; Text[30])
        {
            Caption = 'Column Header';
            ToolTip = 'Specifies a header for the column.';
        }
        /// <summary>
        /// Column type determining calculation method and data source for the column values.
        /// </summary>
        field(5; "Column Type"; Enum "Column Layout Type")
        {
            Caption = 'Column Type';
            ToolTip = 'Specifies the analysis column type, which determines how the amounts in the column are calculated.';
            InitValue = "Net Change";
        }
        /// <summary>
        /// Ledger entry type filter constraining calculation to specific entry sources such as G/L or budget entries.
        /// </summary>
        field(6; "Ledger Entry Type"; Enum "Column Layout Entry Type")
        {
            Caption = 'Ledger Entry Type';
            ToolTip = 'Specifies the type of ledger entries that will be included in the amounts in the financial report column.';
        }
        /// <summary>
        /// Amount type specifying whether to use net change, balance, or budget amounts in calculations.
        /// </summary>
        field(7; "Amount Type"; Enum "Account Schedule Amount Type")
        {
            Caption = 'Amount Type';
            ToolTip = 'Specifies the type of entries that will be included in the amounts in the financial report column.';
        }
        /// <summary>
        /// Formula expression for calculating column values using references to other columns and mathematical operations.
        /// </summary>
        field(8; Formula; Code[80])
        {
            Caption = 'Formula';
            ToolTip = 'Specifies a formula. The result of the formula will appear in the column when the financial report is printed.';

            trigger OnValidate()
            var
                TempAccSchedLine: Record "Acc. Schedule Line" temporary;
            begin
                TempAccSchedLine.CheckFormula(Formula);
            end;
        }
        /// <summary>
        /// Date formula for calculating comparison periods relative to the current date filter in account schedule reporting.
        /// </summary>
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
        /// <summary>
        /// Reverses the sign of calculated amounts for display purposes in financial reports.
        /// </summary>
        field(10; "Show Opposite Sign"; Boolean)
        {
            Caption = 'Show Opposite Sign';
            ToolTip = 'Specifies whether to show debits in reports as negative amounts (that is, with a minus sign) and credits as positive amounts.';
        }
        /// <summary>
        /// Display option controlling when column values are shown based on positive, negative, or zero values.
        /// </summary>
        field(11; Show; Enum "Column Layout Show")
        {
            Caption = 'Show';
            ToolTip = 'Specifies when you want the amounts in the column to be shown in reports.';
            InitValue = Always;
        }
        /// <summary>
        /// Rounding factor applied to column values for simplified display in financial reports.
        /// </summary>
        field(12; "Rounding Factor"; Enum "Analysis Rounding Factor")
        {
            Caption = 'Rounding Factor';
            ToolTip = 'Specifies a rounding factor for amounts in the column.';
        }
        /// <summary>
        /// Controls display of indented account schedule lines within the column calculations.
        /// </summary>
        field(13; "Show Indented Lines"; Option)
        {
            Caption = 'Show Indented Lines';
            ToolTip = 'Specifies that indented lines are shown.';
            OptionCaption = 'All,Indented Only,Non-Indented Only';
            OptionMembers = All,"Indented Only","Non-Indented Only";
        }
        /// <summary>
        /// Period formula expression for advanced period calculations with locale-specific formatting support.
        /// </summary>
        field(14; "Comparison Period Formula"; Code[20])
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
        /// <summary>
        /// Business unit filter for consolidation reporting and multi-company financial analysis.
        /// </summary>
        field(15; "Business Unit Totaling"; Text[80])
        {
            Caption = 'Business Unit Totaling';
            ToolTip = 'Specifies which business unit amounts will be totaled in this column.';
            TableRelation = "Business Unit";
            ValidateTableRelation = false;
        }
        /// <summary>
        /// Dimension 1 filter for detailed financial analysis by primary classification dimension.
        /// </summary>
        field(16; "Dimension 1 Totaling"; Text[80])
        {
            AccessByPermission = TableData Dimension = R;
            CaptionClass = GetCaptionClass(5);
            Caption = 'Dimension 1 Totaling';
            ToolTip = 'Specifies which dimension value amounts will be totaled in this column. If the column type of the column is Formula, you must not enter anything in this field. Also, if you do not wish the amounts on the line to be filtered by dimension, you should leave this field blank.';
        }
        /// <summary>
        /// Dimension 2 filter for detailed financial analysis by secondary classification dimension.
        /// </summary>
        field(17; "Dimension 2 Totaling"; Text[80])
        {
            AccessByPermission = TableData Dimension = R;
            CaptionClass = GetCaptionClass(6);
            Caption = 'Dimension 2 Totaling';
            ToolTip = 'Specifies which dimension value amounts will be totaled in this column. If the column type of the column is Formula, you must not enter anything in this field. Also, if you do not wish the amounts on the line to be filtered by dimension, you should leave this field blank.';
        }
        /// <summary>
        /// Dimension 3 filter for extended dimensional analysis using analysis view configuration.
        /// </summary>
        field(18; "Dimension 3 Totaling"; Text[80])
        {
            AccessByPermission = TableData "Dimension Combination" = R;
            CaptionClass = GetCaptionClass(7);
            Caption = 'Dimension 3 Totaling';
            ToolTip = 'Specifies which dimension value amounts will be totaled in this column. If the column type is Formula, you must not enter anything in this field. Also, if you do not wish the amounts on the line to be filtered by dimension, you should leave this field blank.';
        }
        /// <summary>
        /// Dimension 4 filter for extended dimensional analysis using analysis view configuration.
        /// </summary>
        field(19; "Dimension 4 Totaling"; Text[80])
        {
            AccessByPermission = TableData "Dimension Combination" = R;
            CaptionClass = GetCaptionClass(8);
            Caption = 'Dimension 4 Totaling';
            ToolTip = 'Specifies which dimension value amounts will be totaled in this column. If the column type is Formula, you must not enter anything in this field. Also, if you do not wish the amounts on the line to be filtered by dimension, you should leave this field blank.';
        }
        /// <summary>
        /// Cost center filter for cost accounting analysis and departmental reporting.
        /// </summary>
        field(20; "Cost Center Totaling"; Text[80])
        {
            Caption = 'Cost Center Totaling';
            ToolTip = 'Specifies which cost center amounts will be totaled in this column.';
        }
        /// <summary>
        /// Cost object filter for cost accounting analysis and project-based reporting.
        /// </summary>
        field(21; "Cost Object Totaling"; Text[80])
        {
            Caption = 'Cost Object Totaling';
            ToolTip = 'Specifies which cost object amounts will be totaled in this column.';
        }
        /// <summary>
        /// Locale identifier for period formula parsing to support international date format requirements.
        /// </summary>
        field(30; "Comparison Period Formula LCID"; Integer)
        {
            Caption = 'Comparison Period Formula LCID';
        }
        /// <summary>
        /// G/L budget name for budget-based column calculations and variance analysis.
        /// </summary>
        field(35; "Budget Name"; Code[10])
        {
            Caption = 'Budget Name';
            ToolTip = 'Specifies which budget amounts will be totaled in this column.';
            TableRelation = "G/L Budget Name";
        }
        /// <summary>
        /// Hides currency symbol display in formula-based columns for simplified numeric presentation.
        /// </summary>
        field(40; "Hide Currency Symbol"; Boolean)
        {
            Caption = 'Hide Currency Symbol';
            ToolTip = 'Specifies whether to hide currency symbols when a calculated result is not a currency.';

            trigger OnValidate()
            begin
                if "Hide Currency Symbol" then
                    TestField("Column Type", "Column Layout Type"::Formula);
            end;
        }
        /// <summary>
        /// Controls how date filter ending date is displayed in column headers for period identification.
        /// </summary>
        field(41; "Include Date In Header"; Enum ColumnHeaderDateType)
        {
            Caption = 'Include Date in Column Header';
            ToolTip = 'Specifies how the ending date of the Date Filter applied to the column is displayed on the Column Header.';
        }
        /// <summary>
        /// G/L account filter constraining calculations to specific chart of accounts ranges.
        /// </summary>
        field(42; "G/L Account Totaling"; Text[250])
        {
            Caption = 'G/L Account Totaling';
            ToolTip = 'Specifies which G/L accounts will be totalled in this column. Note that this filter will be applied in addition to any G/L account filters from the row definition lines.';

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
#if not CLEAN28
#pragma warning disable AS0086
#endif
        field(44; "Internal Description"; Text[500])
#if not CLEAN28
#pragma warning restore AS0086
#endif
        {
            Caption = 'Internal Description';
            ToolTip = 'Specifies the internal description for the column definition line that highlights complex logic or areas needing review for the next report designer.';
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
    /// <summary>
    /// Parses period formula expression into component values for period calculation processing.
    /// </summary>
    /// <param name="FormulaExpression">Period formula code to parse into components</param>
    /// <param name="Steps">Number of period steps calculated from formula</param>
    /// <param name="Type">Period type determined from formula expression</param>
    /// <param name="RangeFromType">Starting range type for period calculation</param>
    /// <param name="RangeToType">Ending range type for period calculation</param>
    /// <param name="RangeFromInt">Starting range integer value</param>
    /// <param name="RangeToInt">Ending range integer value</param>
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

    /// <summary>
    /// Opens dimension value lookup dialog and returns selected dimension filter expression.
    /// Handles both standard dimensions and cost accounting dimension mappings.
    /// </summary>
    /// <param name="DimNo">Dimension number identifying which dimension to filter (1-4)</param>
    /// <param name="Text">Dimension filter text updated with selected values</param>
    /// <returns>True if dimension values were selected, false if lookup was cancelled</returns>
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

    /// <summary>
    /// Retrieves caption class text for dimension field captions based on analysis view configuration.
    /// Supports dynamic field captioning for dimensions 1-4 in financial reporting interfaces.
    /// </summary>
    /// <param name="AnalysisViewDimType">Analysis view dimension type number (1-4) for caption lookup</param>
    /// <returns>Caption class text for dimension field display formatting</returns>
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
    /// <summary>
    /// Retrieves current period name for display purposes in financial reporting.
    /// </summary>
    /// <returns>Period name code for current period identification</returns>
    [Obsolete('Moved to codeunit Period Formula Parser', '27.0')]
    procedure GetPeriodName(): Code[10]
    var
        PeriodFormulaParser: Codeunit "Period Formula Parser";
    begin
        exit(PeriodFormulaParser.GetPeriodName());
    end;
#endif

    /// <summary>
    /// Integration event raised before retrieving caption class for dimension field display.
    /// </summary>
    /// <param name="ColumnLayout">Column layout record containing dimension configuration</param>
    /// <param name="ColumnLayoutName">Column layout name with analysis view settings</param>
    /// <param name="AnalysisViewDimType">Dimension type number for caption lookup</param>
    /// <param name="Result">Caption class result to be returned</param>
    /// <param name="IsHandled">Set to true to override standard caption class logic</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetCaptionClass(var ColumnLayout: Record "Column Layout"; ColumnLayoutName: Record "Column Layout Name"; AnalysisViewDimType: Integer; var Result: Text[250]; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised before opening dimension filter lookup dialog.
    /// </summary>
    /// <param name="ColumnLayout">Column layout record requesting dimension filter</param>
    /// <param name="DimNo">Dimension number being filtered</param>
    /// <param name="Text">Current dimension filter text</param>
    /// <param name="ColumnLayoutName">Column layout name with analysis view context</param>
    /// <param name="Result">Lookup result to be returned</param>
    /// <param name="IsHandled">Set to true to override standard dimension lookup</param>
    /// <param name="AnalysisView">Analysis view record with dimension configuration</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeLookUpDimFilter(var ColumnLayout: Record "Column Layout"; DimNo: Integer; var Text: Text[250]; ColumnLayoutName: Record "Column Layout Name"; var Result: Boolean; var IsHandled: Boolean; var AnalysisView: Record "Analysis View")
    begin
    end;
}

