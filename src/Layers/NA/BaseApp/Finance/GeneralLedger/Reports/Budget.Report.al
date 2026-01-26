// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Reports;

using Microsoft.Finance.Analysis;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Foundation.Company;
using Microsoft.Foundation.Enums;
using Microsoft.Foundation.Period;
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
report 10001 Budget
{
    DefaultLayout = RDLC;
    RDLCLayout = './Finance/GeneralLedger/Reports/Budget.rdlc';
    ApplicationArea = Suite;
    Caption = 'Budget';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("G/L Account"; "G/L Account")
        {
            DataItemTableView = sorting("No.");
            RequestFilterFields = "No.", "Account Type", "Budget Filter", "Global Dimension 1 Filter", "Global Dimension 2 Filter";
            column(MainTitle; MainTitle)
            {
            }
            column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
            {
            }
            column(TIME; Time)
            {
            }
            column(CompanyInformation_Name; CompanyInformation.Name)
            {
            }
            column(USERID; UserId)
            {
            }
            column(SubTitle; SubTitle)
            {
            }
            column(STRSUBSTNO_Text004_PeriodLength_; StrSubstNo(Text004, PeriodLength))
            {
            }
            column(PeriodLength; PeriodLength)
            {
            }
            column(STRSUBSTNO_Text005_PeriodCalcToPrint_; StrSubstNo(Text005, PeriodCalcToPrint))
            {
            }
            column(PeriodCalculation; PeriodCalculation)
            {
            }
            column(InThousandsText; InThousandsText)
            {
            }
            column(InThousandsText_Control1400002; InThousandsText)
            {
            }
            column(Text006; Text006Lbl)
            {
            }
            column(PrintAllBalance; PrintAllBalance)
            {
            }
            column(G_L_Account__TABLECAPTION__________GLFilter; "G/L Account".TableCaption + ': ' + GLFilter)
            {
            }
            column(GLFilter; GLFilter)
            {
            }
            column(PeriodStartingDate_1_; PeriodStartingDateText[1])
            {
            }
            column(PeriodStartingDate_2_; PeriodStartingDateText[2])
            {
            }
            column(PeriodStartingDate_3_; PeriodStartingDateText[3])
            {
            }
            column(PeriodStartingDate_4_; PeriodStartingDateText[4])
            {
            }
            column(PeriodStartingDate_5_; PeriodStartingDateText[5])
            {
            }
            column(PeriodStartingDate_6_; PeriodStartingDateText[6])
            {
            }
            column(PeriodStartingDate_7_; PeriodStartingDateText[7])
            {
            }
            column(PeriodStartingDate_8_; PeriodStartingDateText[8])
            {
            }
            column(PeriodStartingDate_9_; PeriodStartingDateText[9])
            {
            }
            column(PeriodStartingDate_10_; PeriodStartingDateText[10])
            {
            }
            column(PeriodStartingDate_11_; PeriodStartingDateText[11])
            {
            }
            column(PeriodStartingDate_12_; PeriodStartingDateText[12])
            {
            }
            column(PeriodStartingDate_2__1; PeriodStartingDateText2[2])
            {
            }
            column(PeriodStartingDate_3__1; PeriodStartingDateText2[3])
            {
            }
            column(PeriodStartingDate_4__1; PeriodStartingDateText2[4])
            {
            }
            column(PeriodStartingDate_5__1; PeriodStartingDateText2[5])
            {
            }
            column(PeriodStartingDate_6__1; PeriodStartingDateText2[6])
            {
            }
            column(PeriodStartingDate_7__1; PeriodStartingDateText2[7])
            {
            }
            column(PeriodStartingDate_8__1; PeriodStartingDateText2[8])
            {
            }
            column(PeriodStartingDate_9__1; PeriodStartingDateText2[9])
            {
            }
            column(PeriodStartingDate_10__1; PeriodStartingDateText2[10])
            {
            }
            column(PeriodStartingDate_11__1; PeriodStartingDateText2[11])
            {
            }
            column(PeriodStartingDate_12__1; PeriodStartingDateText2[12])
            {
            }
            column(PeriodStartingDate_13__1; PeriodStartingDateText2[13])
            {
            }
            column(PageGroupNo; PageGroupNo)
            {
            }
            column(G_L_Account_No_; "No.")
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(G_L_Account___No__Caption; FieldCaption("No."))
            {
            }
            column(NameCaption; NameCaptionLbl)
            {
            }
            column(TotalCaption; TotalLbl)
            {
            }
            column(RowNumber; RowNumber)
            {
            }
            dataitem(BlankLineCounter; "Integer")
            {
                DataItemTableView = sorting(Number);
                column(BlankLineCounter_Number; Number)
                {
                }

                trigger OnPreDataItem()
                begin
                    SetRange(Number, 1, "G/L Account"."No. of Blank Lines");
                end;
            }
            dataitem("Integer"; "Integer")
            {
                DataItemTableView = sorting(Number) where(Number = const(1));
                column(G_L_Account___No__; "G/L Account"."No.")
                {
                }
                column(PADSTR_____G_L_Account__Indentation___G_L_Account__Name; PadStr('', "G/L Account".Indentation) + "G/L Account".Name)
                {
                }
                column(BudgetToPrint_1_; BudgetToPrint[1])
                {
                    DecimalPlaces = 0 : 0;
                }
                column(BudgetToPrint_2_; BudgetToPrint[2])
                {
                    DecimalPlaces = 0 : 0;
                }
                column(BudgetToPrint_3_; BudgetToPrint[3])
                {
                    DecimalPlaces = 0 : 0;
                }
                column(BudgetToPrint_4_; BudgetToPrint[4])
                {
                    DecimalPlaces = 0 : 0;
                }
                column(BudgetToPrint_5_; BudgetToPrint[5])
                {
                    DecimalPlaces = 0 : 0;
                }
                column(BudgetToPrint_6_; BudgetToPrint[6])
                {
                    DecimalPlaces = 0 : 0;
                }
                column(BudgetToPrint_7_; BudgetToPrint[7])
                {
                    DecimalPlaces = 0 : 0;
                }
                column(BudgetToPrint_8_; BudgetToPrint[8])
                {
                    DecimalPlaces = 0 : 0;
                }
                column(BudgetToPrint_9_; BudgetToPrint[9])
                {
                    DecimalPlaces = 0 : 0;
                }
                column(BudgetToPrint_10_; BudgetToPrint[10])
                {
                    DecimalPlaces = 0 : 0;
                }
                column(BudgetToPrint_11_; BudgetToPrint[11])
                {
                    DecimalPlaces = 0 : 0;
                }
                column(BudgetToPrint_12_; BudgetToPrint[12])
                {
                    DecimalPlaces = 0 : 0;
                }
                column(TotalBudgetAmount; TotalBudgetAmount)
                {
                    DecimalPlaces = 0 : 0;
                }
                column(G_L_Account___No___Control41; "G/L Account"."No.")
                {
                }
                column(PADSTR_____G_L_Account__Indentation___G_L_Account__Name_Control42; PadStr('', "G/L Account".Indentation) + "G/L Account".Name)
                {
                }
                column(AccountTypeNo; AccountTypeNo)
                {
                }
                column(G_L_Account__Totaling; "G/L Account".Totaling)
                {
                }
                column(G_L_Account___No___Control51; "G/L Account"."No.")
                {
                }
                column(PADSTR_____G_L_Account__Indentation___G_L_Account__Name_Control52; PadStr('', "G/L Account".Indentation) + "G/L Account".Name)
                {
                }
                column(Integer_Number; Number)
                {
                }
            }

            trigger OnAfterGetRecord()
            begin
                AccountTypeNo := "Account Type".AsInteger();
                PageGroupNo := NextPageGroupNo;
                if "New Page" then
                    NextPageGroupNo := PageGroupNo + 1;

                NoDataFound := true; // used to indicate if any budget values are found
                TotalBudgetAmount := 0;
                for i := 1 to ArrayLen(BudgetToPrint) do begin
                    SetRange("Date Filter", PeriodStartingDate[i], PeriodStartingDate[i + 1] - 1);
                    CalcFields("Budgeted Amount");
                    if InThousands then
                        "Budgeted Amount" := "Budgeted Amount" / 1000;
                    BudgetToPrint[i] := MatrixMgt.RoundAmount("Budgeted Amount", RndFactor);
                    TotalBudgetAmount += BudgetToPrint[i];
                    if NoDataFound then
                        NoDataFound := ("Budgeted Amount" = 0); // will set NoDataFound flag to no if budget found
                end;

                // if PrintAllBalance is true then skip printing posting accounts
                // that do not have any budget amounts.
                if NoDataFound and PrintAllBalance and ("Account Type" = "Account Type"::Posting) then
                    CurrReport.Skip();

                RowNumber += 1;
            end;

            trigger OnPreDataItem()
            begin
                PageGroupNo := 1;
                NextPageGroupNo := 1;
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
                    field(StartingPeriodDate; PeriodCalculation)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Starting Period Date';
                        ToolTip = 'Specifies the starting accounting period from which to generate the budget. For example, enter P to start at the current accounting period, enter P-1 to start with the prior accounting period, or enter P+2 to start with the accounting period after the next one. If you enter a value in this field, each column will cover one accounting period.';
                    }
                    field(PeriodLengthControl; PeriodLength)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Period Length';
                        MultiLine = false;
                        ToolTip = 'Specifies that you want to print by your accounting periods. You can also print by a different division of time. For example, you could enter 10D, which will create divisions of ten days. The range of dates will expand if needed to cover complete periods of time.';
                    }
                    field(FromDate; FromDate)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Start Date';
                        ToolTip = 'Specifies the date from which the report or batch job processes information.';
                    }
                    field(AmountsIn1000s; InThousands)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Amounts in 1000s';
                        ToolTip = 'Specifies that budget values are divided by USD 1,000 and rounded to improve readability.';
                    }
                    field(PrintAllBalance; PrintAllBalance)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Acc. with Budgets Only';
                        ToolTip = 'Specifies that you want to include all accounts that have a balance other than zero, even if there has been no activity in the period. This option cannot be used if you are also entering Customer Ledger Entry Filters such as the Open filter.';
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
            if PeriodCalculation = '' then begin
                if FromDate = 0D then
                    FromDate := CalcDate('<-CY+1D>', WorkDate());
                if Format(PeriodLength) = '' then
                    Evaluate(PeriodLength, '<1M>');
            end;
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        GLFilter := "G/L Account".GetFilters();
        CompanyInformation.Get();
        if PeriodCalculation <> '' then begin
            Evaluate(PeriodLength, '');
            FromDate := 0D;
            if PeriodCalculation = Text008 then begin
                PeriodCalcToPrint := Text000;
                AccountingPeriod.SetRange("Starting Date", 0D, WorkDate());
                AccountingPeriod.Find('+');
                PeriodCalculation := Format(AccountingPeriod."Starting Date");
            end else
                PeriodCalcToPrint := PeriodCalculation + '.';
            "G/L Account".SetFilter("Date Filter", PeriodCalculation);
            PeriodStartingDate[1] := "G/L Account".GetRangeMin("Date Filter");
            PeriodStartingDateText[1] := Format(PeriodStartingDate[1]);
            AccountingPeriod.SetRange("Starting Date", PeriodStartingDate[1]);
            AccountingPeriod.Find('-');
            for i := 2 to ArrayLen(PeriodStartingDate) do begin
                AccountingPeriod.Reset();
                AccountingPeriod.Next();
                PeriodStartingDate[i] := AccountingPeriod."Starting Date";
                PeriodStartingDateText[i] := Format(PeriodStartingDate[i]);
                PeriodStartingDateText2[i] := Format(PeriodStartingDate[i] - 1);
            end;
        end else begin
            if PeriodStartingDate[1] = 0D then
                PeriodStartingDate[1] := FromDate;
            PeriodStartingDate[1] := CalcDate('<1D-CY>', PeriodStartingDate[1]);
            PeriodStartingDateText[1] := Format(PeriodStartingDate[1], 0, '<Month Text,3>');
            for i := 2 to ArrayLen(PeriodStartingDate) do begin
                PeriodStartingDate[i] := CalcDate(PeriodLength, PeriodStartingDate[i - 1]);
                PeriodStartingDateText[i] := Format(PeriodStartingDate[i], 0, '<Month Text,3>');
                PeriodStartingDateText2[i] := Format(PeriodStartingDate[i] - 1, 0, '<Month Text,3>');
            end;
        end;
        if InThousands then
            InThousandsText := Text001;
        MainTitle := StrSubstNo(Text002, PeriodStartingDate[1], PeriodStartingDate[ArrayLen(PeriodStartingDate)] - 1);
        SubTitle := "G/L Account".GetFilter("Budget Filter");
        if SubTitle = '' then
            SubTitle := "G/L Account".FieldCaption("Budget Filter") + ': ' + Text003
        else
            SubTitle := "G/L Account".FieldCaption("Budget Filter") + ': ' + SubTitle;
    end;

    var
        CompanyInformation: Record "Company Information";
        AccountingPeriod: Record "Accounting Period";
        MatrixMgt: Codeunit "Matrix Management";
        MainTitle: Text[132];
        SubTitle: Text;
        PrintAllBalance: Boolean;
        FromDate: Date;
        PeriodCalculation: Code[10];
        PeriodLength: DateFormula;
        BudgetToPrint: array[12] of Decimal;
        TotalBudgetAmount: Decimal;
        PeriodStartingDate: array[13] of Date;
        PeriodStartingDateText: array[13] of Text;
        PeriodStartingDateText2: array[13] of Text;
        InThousands: Boolean;
        RowNumber: Integer;
        i: Integer;
        InThousandsText: Text[40];
        PeriodCalcToPrint: Text[15];
        NoDataFound: Boolean;
        PageGroupNo: Integer;
        NextPageGroupNo: Integer;
        AccountTypeNo: Integer;
        RndFactor: Enum "Analysis Rounding Factor";

        Text000: Label 'Current Period.';
        Text001: Label 'Amounts are in 1000s.';
        Text002: Label 'Budget for %1 to %2';
        Text003: Label 'All Budgets';
        Text004: Label 'Time divisions of %1.';
        Text005: Label 'By period starting with %1';
        Text008: Label 'P', Comment = '''P'' = Period';
        Text006Lbl: Label 'Accounts without budgets are not included.';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        NameCaptionLbl: Label 'Name';
        TotalLbl: Label 'Total';

    protected var
        GLFilter: Text;

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
        exit(PeriodStartingDate[1]);
    end;
}

