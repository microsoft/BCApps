// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Reports;

using Microsoft.Finance.Analysis;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Foundation.Enums;
using Microsoft.Foundation.Reporting;
using System.Utilities;

/// <summary>
/// Generates budget analysis report with period-by-period budget breakdowns and variance analysis.
/// Displays budgeted amounts across multiple periods with configurable rounding and period length options.
/// </summary>
/// <remarks>
/// Data sources: G/L Account table with Budget Filter integration for budget vs. actual comparison.
/// Supports period length configuration, thousands display option, and comprehensive dimension filtering.
/// Output format: RDLC layout with columnar period display and variance calculation capabilities.
/// </remarks>
report 8 Budget
{
    DefaultLayout = RDLC;
    RDLCLayout = './Finance/GeneralLedger/Reports/Budget.rdlc';
    ApplicationArea = Suite;
    Caption = 'Budget';
    PreviewMode = PrintLayout;
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("G/L Account"; "G/L Account")
        {
            DataItemTableView = sorting("No.");
            RequestFilterFields = "No.", "Account Type", "Budget Filter", "Global Dimension 1 Filter", "Global Dimension 2 Filter";
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(GLBudgetFilter; GLBudgetFilter)
            {
            }
            column(NoOfBlankLines_GLAcc; "No. of Blank Lines")
            {
            }
            column(AmountsAreIn1000sCaption; RoundingText)
            {
            }
            column(AmtsInThousands; RoundingNO)
            {
            }
            column(GLFilterTableCaption_GLAcc; TableCaption + ': ' + GLFilter)
            {
            }
            column(GLFilter; GLFilter)
            {
            }
            column(Type_GLAcc; "Account Type")
            {
            }
            column(AccountTypePosting; GLAccountTypePosting)
            {
            }
            column(PeriodStartDate1; Format(PeriodStartDate[1], 0, '<Month Text,3>'))
            {
            }
            column(PeriodStartDate2; Format(PeriodStartDate[2], 0, '<Month Text,3>'))
            {
            }
            column(PeriodStartDate3; Format(PeriodStartDate[3], 0, '<Month Text,3>'))
            {
            }
            column(PeriodStartDate4; Format(PeriodStartDate[4], 0, '<Month Text,3>'))
            {
            }
            column(PeriodStartDate5; Format(PeriodStartDate[5], 0, '<Month Text,3>'))
            {
            }
            column(PeriodStartDate6; Format(PeriodStartDate[6], 0, '<Month Text,3>'))
            {
            }
            column(PeriodStartDate7; Format(PeriodStartDate[7], 0, '<Month Text,3>'))
            {
            }
            column(PeriodStartDate8; Format(PeriodStartDate[8], 0, '<Month Text,3>'))
            {
            }
            column(PeriodStartDate9; Format(PeriodStartDate[9], 0, '<Month Text,3>'))
            {
            }
            column(PeriodStartDate10; Format(PeriodStartDate[10], 0, '<Month Text,3>'))
            {
            }
            column(PeriodStartDate11; Format(PeriodStartDate[11], 0, '<Month Text,3>'))
            {
            }
            column(PeriodStartDate12; Format(PeriodStartDate[12], 0, '<Month Text,3>'))
            {
            }
            column(PeriodStartDate21; Format(PeriodStartDate[2] - 1, 0, '<Month Text,3>'))
            {
            }
            column(PeriodStartDate31; Format(PeriodStartDate[3] - 1, 0, '<Month Text,3>'))
            {
            }
            column(PeriodStartDate41; Format(PeriodStartDate[4] - 1, 0, '<Month Text,3>'))
            {
            }
            column(PeriodStartDate51; Format(PeriodStartDate[5] - 1, 0, '<Month Text,3>'))
            {
            }
            column(PeriodStartDate61; Format(PeriodStartDate[6] - 1, 0, '<Month Text,3>'))
            {
            }
            column(PeriodStartDate71; Format(PeriodStartDate[7] - 1, 0, '<Month Text,3>'))
            {
            }
            column(PeriodStartDate81; Format(PeriodStartDate[8] - 1, 0, '<Month Text,3>'))
            {
            }
            column(PeriodStartDate91; Format(PeriodStartDate[9] - 1, 0, '<Month Text,3>'))
            {
            }
            column(PeriodStartDate101; Format(PeriodStartDate[10] - 1, 0, '<Month Text,3>'))
            {
            }
            column(PeriodStartDate111; Format(PeriodStartDate[11] - 1, 0, '<Month Text,3>'))
            {
            }
            column(PeriodStartDate121; Format(PeriodStartDate[12] - 1, 0, '<Month Text,3>'))
            {
            }
            column(PeriodStartDate131; Format(PeriodStartDate[13] - 1, 0, '<Month Text,3>'))
            {
            }
            column(No_GLAcc; "No.")
            {
                IncludeCaption = true;
            }
            column(BudgetCaption; BudgetCaptionTxt)
            {
            }
            column(PageCaption; PageCaptionLbl)
            {
            }
            column(BudgetFilterCaption; BudgetFilterCaptionLbl)
            {
            }
            column(GLAccNameCaption; GLAccNameCaptionLbl)
            {
            }
            column(TotalCaption; TotalLbl)
            {
            }
            column(RowNumber; RowNumber)
            {
            }
            column(StartingDateAsText; StartingDateAsText)
            {
            }
            dataitem(BlankLineCounter; "Integer")
            {
                DataItemTableView = sorting(Number);

                trigger OnPreDataItem()
                begin
                    SetRange(Number, 1, "G/L Account"."No. of Blank Lines");
                end;
            }
            dataitem("Integer"; "Integer")
            {
                DataItemTableView = sorting(Number) where(Number = const(1));
                column(GLAccNo_BlankLineCounter; "G/L Account"."No.")
                {
                    IncludeCaption = true;
                }
                column(PADSTRIndentName_GLAcc; PadStr('', "G/L Account".Indentation * 2) + "G/L Account".Name)
                {
                }
                column(GLBudgetedAmount1; GLBudgetedAmount[1])
                {
                    DecimalPlaces = 0 : 5;
                }
                column(GLBudgetedAmount2; GLBudgetedAmount[2])
                {
                    DecimalPlaces = 0 : 5;
                }
                column(GLBudgetedAmount3; GLBudgetedAmount[3])
                {
                    DecimalPlaces = 0 : 5;
                }
                column(GLBudgetedAmount4; GLBudgetedAmount[4])
                {
                    DecimalPlaces = 0 : 5;
                }
                column(GLBudgetedAmount5; GLBudgetedAmount[5])
                {
                    DecimalPlaces = 0 : 5;
                }
                column(GLBudgetedAmount6; GLBudgetedAmount[6])
                {
                    DecimalPlaces = 0 : 5;
                }
                column(GLBudgetedAmount7; GLBudgetedAmount[7])
                {
                    DecimalPlaces = 0 : 5;
                }
                column(GLBudgetedAmount8; GLBudgetedAmount[8])
                {
                    DecimalPlaces = 0 : 5;
                }
                column(GLBudgetedAmount9; GLBudgetedAmount[9])
                {
                    DecimalPlaces = 0 : 5;
                }
                column(GLBudgetedAmount10; GLBudgetedAmount[10])
                {
                    DecimalPlaces = 0 : 5;
                }
                column(GLBudgetedAmount11; GLBudgetedAmount[11])
                {
                    DecimalPlaces = 0 : 5;
                }
                column(GLBudgetedAmount12; GLBudgetedAmount[12])
                {
                    DecimalPlaces = 0 : 5;
                }
                column(TotalBudgetAmount; TotalBudgetAmount)
                {
                    DecimalPlaces = 0 : 5;
                }
            }

            trigger OnAfterGetRecord()
            begin
                TotalBudgetAmount := 0;
                for i := 1 to ArrayLen(GLBudgetedAmount) do begin
                    SetRange("Date Filter", PeriodStartDate[i], PeriodStartDate[i + 1] - 1);
                    CalcFields("Budgeted Amount");
                    if InThousands then
                        "Budgeted Amount" := "Budgeted Amount" / 1000;
                    if (RoundingFromPage) then
                        GLBudgetedAmount[i] := MatrixMgt.RoundAmount("Budgeted Amount", RndFactor)
                    else
                        GLBudgetedAmount[i] := ReportMgmnt.RoundAmount("Budgeted Amount", Rounding);
                    TotalBudgetAmount += GLBudgetedAmount[i];
                end;
                SetRange("Date Filter", PeriodStartDate[1], PeriodStartDate[ArrayLen(PeriodStartDate)] - 1);

                GLAccountTypePosting := "Account Type" = "Account Type"::Posting;
                RowNumber += 1;
            end;

            trigger OnPreDataItem()
            begin
                RoundingText := ReportMgmnt.RoundDescription(Rounding);
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(StartingDate; PeriodStartDate[1])
                    {
                        ApplicationArea = Suite;
                        Caption = 'Starting Date';
                        ToolTip = 'Specifies the date from which the report or batch job processes information.';
                    }
                    field(PeriodLength; PeriodLength)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Period Length';
                        Editable = false;
                        Enabled = false;
                        ToolTip = 'Specifies the period for which data is shown in the report. For example, enter "1M" for one month, "30D" for thirty days, "3Q" for three quarters, or "5Y" for five years.';
                    }
                    field(AmountsInWhole; Rounding)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Amounts in whole';
                        ToolTip = 'Specifies if the amounts in the report are shown in whole 1000s.';
                    }
                    field(RoundingFactor; RndFactor)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Rounding Factor';
                        ToolTip = 'Specifies the factor that is used to round the amounts.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            if PeriodStartDate[1] = 0D then
                PeriodStartDate[1] := CalcDate('<-CY+1D>', WorkDate());
            if Format(PeriodLength) = '' then
                Evaluate(PeriodLength, '<1M>');
        end;
    }

    labels
    {
        NoCaption = 'No.';
    }

    trigger OnInitReport()
    begin
        RoundingNO := Rounding;
    end;

    trigger OnPreReport()
    begin
        GLFilter := "G/L Account".GetFilters();
        GLBudgetFilter := "G/L Account".GetFilter("Budget Filter");
        if PeriodStartDate[1] = 0D then
            PeriodStartDate[1] := WorkDate();
        for i := 2 to ArrayLen(PeriodStartDate) do
            PeriodStartDate[i] := CalcDate(PeriodLength, PeriodStartDate[i - 1]);

        BudgetCaptionTxt := StrSubstNo(BudgetCaptionTok, Format(PeriodStartDate[1], 0, '<Year4>'));
        StartingDateAsText := StrSubstNo(StartingDateTok, PeriodStartDate[1]);
        if (Rounding = Rounding::" ") and (RndFactor <> RndFactor::None) then
            RoundingFromPage := true;
    end;

    var
        MatrixMgt: Codeunit "Matrix Management";
        ReportMgmnt: Codeunit "Report Management APAC";
        PeriodLength: DateFormula;
        InThousands: Boolean;
        GLBudgetFilter: Text[250];
        BudgetCaptionTxt: Text;
        GLBudgetedAmount: array[12] of Decimal;
        TotalBudgetAmount: Decimal;
        PeriodStartDate: array[13] of Date;
        i: Integer;
        RowNumber: Integer;
        GLAccountTypePosting: Boolean;
        RndFactor: Enum "Analysis Rounding Factor";
        StartingDateAsText: Text;
        RoundingFromPage: Boolean;
        Rounding: Option " ",Tens,Hundreds,Thousands,"Hundred Thousands",Millions;
        RoundingText: Text[50];
        RoundingNO: Integer;

        BudgetCaptionTok: Label 'Budget for %1', Comment = '%1 - year';
        PageCaptionLbl: Label 'Page';
        BudgetFilterCaptionLbl: Label 'Budget Filter';
        GLAccNameCaptionLbl: Label 'Name';
        TotalLbl: Label 'Total';
        StartingDateTok: Label 'Starting Date: %1', Comment = '%1 - date';

    protected var
        GLFilter: Text;

    /// <summary>
    /// Initializes report parameters for programmatic execution with period configuration and display options.
    /// Sets starting date, period length formula, and thousands display option for automated budget report generation.
    /// </summary>
    /// <param name="NewPeriodStartDate">Starting date for budget period analysis</param>
    /// <param name="NewPeriodLength">Period length formula as text (e.g., '1M', '1Q', '1Y')</param>
    procedure InitializeRequest(NewPeriodStartDate: Date; NewPeriodLength: Text[30]; NewRounding: Option)
    begin
        PeriodStartDate[1] := NewPeriodStartDate;
        Evaluate(PeriodLength, NewPeriodLength);
        Rounding := NewRounding;
    end;

    /// <summary>
    /// Sets the rounding factor for amount display formatting in the budget report.
    /// Controls precision level for budget amounts (ones, thousands, millions).
    /// </summary>
    /// <param name="NewRoundingFactor">Analysis rounding factor enum value for amount formatting</param>
    procedure SetRoundingFactor(NewRoundingFactor: Enum "Analysis Rounding Factor")
    begin
        RndFactor := NewRoundingFactor;
    end;

    /// <summary>
    /// Retrieves the configured period length formula for the budget report.
    /// Returns the DateFormula used to calculate period intervals for budget analysis.
    /// </summary>
    /// <returns>DateFormula representing the period length (e.g., 1M for monthly, 1Q for quarterly)</returns>
    procedure GetPeriodLength(): DateFormula
    begin
        exit(PeriodLength);
    end;

    /// <summary>
    /// Retrieves the starting date configured for the budget report period analysis.
    /// Returns the first period's starting date used in budget calculations.
    /// </summary>
    /// <returns>Starting date for the first budget period</returns>
    procedure GetPeriodStartDate(): Date
    begin
        exit(PeriodStartDate[1]);
    end;
}
