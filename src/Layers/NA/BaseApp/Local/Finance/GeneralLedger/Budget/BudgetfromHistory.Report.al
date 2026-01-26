// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Budget;

using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Period;
using System.Utilities;

report 10031 "Budget from History"
{
    Caption = 'Budget from History';
    ProcessingOnly = true;

    dataset
    {
        dataitem("G/L Account"; "G/L Account")
        {
            DataItemTableView = sorting("No.");
            RequestFilterFields = "No.", "Global Dimension 1 Filter", "Global Dimension 2 Filter", "Budget Filter";
            dataitem("Integer"; "Integer")
            {
                DataItemTableView = sorting(Number);

                trigger OnAfterGetRecord()
                var
                    TempDimSetEntry: Record "Dimension Set Entry" temporary;
                    DimensionValue: Record "Dimension Value";
                    DimMgt: Codeunit DimensionManagement;
                begin
                    CurrentPeriod := CurrentPeriod + 1;
                    if CurrentPeriod > NoPeriods then
                        CurrReport.Break();

                    "G/L Account".SetRange("Date Filter", RunHistoryDate, NextDate(RunHistoryDate) - 1);
                    "G/L Account".SetRange("Account Type", "G/L Account"."Account Type"::Posting);
                    "G/L Account".CalcFields("Net Change");
                    RunHistoryDate := NextDate(RunHistoryDate);

                    EntryNo := EntryNo + 10000;
                    GLBudgetEntry.Init();
                    GLBudgetEntry."Entry No." := EntryNo;
                    GLBudgetEntry."Budget Name" := "G/L Account".GetFilter("Budget Filter");
                    GLBudgetEntry."G/L Account No." := "G/L Account"."No.";
                    GLBudgetEntry.Date := RunBudgetDate;
                    if "G/L Account".GetFilter("Global Dimension 1 Filter") <> '' then begin
                        GLBudgetEntry."Global Dimension 1 Code" := "G/L Account".GetRangeMin("Global Dimension 1 Filter");
                        if DimensionValue.Get(GlobalDim1Code, GLBudgetEntry."Global Dimension 1 Code") then begin
                            TempDimSetEntry.Init();
                            TempDimSetEntry."Dimension Code" := DimensionValue."Dimension Code";
                            TempDimSetEntry."Dimension Value Code" := DimensionValue.Code;
                            TempDimSetEntry."Dimension Value ID" := DimensionValue."Dimension Value ID";
                            TempDimSetEntry.Insert();
                        end;
                    end;
                    if "G/L Account".GetFilter("Global Dimension 2 Filter") <> '' then begin
                        GLBudgetEntry."Global Dimension 2 Code" := "G/L Account".GetRangeMin("Global Dimension 2 Filter");
                        if DimensionValue.Get(GlobalDim2Code, GLBudgetEntry."Global Dimension 2 Code") then begin
                            TempDimSetEntry.Init();
                            TempDimSetEntry."Dimension Code" := DimensionValue."Dimension Code";
                            TempDimSetEntry."Dimension Value Code" := DimensionValue.Code;
                            TempDimSetEntry."Dimension Value ID" := DimensionValue."Dimension Value ID";
                            TempDimSetEntry.Insert();
                        end;
                    end;
                    GLBudgetEntry.Amount := Round("G/L Account"."Net Change" * PercentChg, Precision);
                    GLBudgetEntry."Dimension Set ID" := DimMgt.GetDimensionSetID(TempDimSetEntry);
                    GLBudgetEntry.Insert();
                    RunBudgetDate := NextDate(RunBudgetDate);
                end;

                trigger OnPreDataItem()
                begin
                    GLBudgetEntry.Reset();
                    if GLBudgetEntry.FindLast() then
                        EntryNo := GLBudgetEntry."Entry No.";
                    CurrentPeriod := 0;
                    RunHistoryDate := HistoryDate;
                    RunBudgetDate := BudgetDate;
                end;
            }

            trigger OnPreDataItem()
            begin
                if HistoryDate = 0D then
                    Error(Text001);
                if BudgetDate = 0D then
                    Error(Text002);
                if NoPeriods = 0 then
                    Error(Text003);
                PercentChg := PercentChg / 100;

                if PercentChg < 1 then
                    PercentChg := 1 + PercentChg;
                case Rounding of
                    Rounding::Pennies:
                        Precision := 0.05;
                    Rounding::Dollars:
                        Precision := 1;
                    Rounding::Hundreds:
                        Precision := 100;
                    Rounding::Thousands:
                        Precision := 1000;
                    Rounding::Millions:
                        Precision := 1000000;
                end;
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
                    field(HistoryBeginningDate; HistoryDate)
                    {
                        ApplicationArea = Suite;
                        Caption = 'History Beginning Date';
                        ToolTip = 'Specifies the starting date of the first historical period to be analyzed for the creation of the budget. Usually this would be one fiscal year before the budget beginning date.';
                    }
                    field(BudgetBeginningDate; BudgetDate)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Budget Beginning Date';
                        ToolTip = 'Specifies the starting date of the first budget period to be created.';
                    }
                    field(NoOfPeriods; NoPeriods)
                    {
                        ApplicationArea = Suite;
                        Caption = 'No. of Periods';
                        ToolTip = 'Specifies the number of budget periods to be created.';
                    }
                    field(PeriodLength; PeriodLength)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Period Length';
                        OptionCaption = ',Day,Week,Month,Quarter,Year,Accounting Period';
                        ToolTip = 'Specifies the length of each period, for example, enter "1M" for one month.';
                    }
                    field(PercentChg; PercentChg)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Percent Change';
                        ToolTip = 'Specifies if you want the budget to increase in relation to the corresponding historical period. The budget created will be that percentage over (under if negative) the actual amounts existing in the corresponding historical period. For example, if the historical amount for a period is $100, and the percent change is 10, then the budget for the corresponding period will be $110.';
                    }
                    field(RoundTo; Rounding)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Round To';
                        OptionCaption = ',Pennies,Dollars,Hundreds,Thousands,Millions';
                        ToolTip = 'Specifies if you want the results in the report to be rounded to the nearest penny (hundredth of a unit), dollar (unit), or thousand dollars (units). The results are in US dollars, unless you use an additional reporting currency.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            if PeriodLength = 0 then
                PeriodLength := PeriodLength::Month;
            if Rounding = 0 then
                Rounding := Rounding::Dollars;
            if NoPeriods = 0 then
                NoPeriods := 12;
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        GLSetup.Get();
        GlobalDim1Code := GLSetup."Global Dimension 1 Code";
        GlobalDim2Code := GLSetup."Global Dimension 2 Code";
    end;

    var
        GLBudgetEntry: Record "G/L Budget Entry";
        AcctPeriod: Record "Accounting Period";
        GLSetup: Record "General Ledger Setup";
        PercentChg: Decimal;
        Precision: Decimal;
        BudgetDate: Date;
        RunBudgetDate: Date;
        HistoryDate: Date;
        RunHistoryDate: Date;
        PeriodLength: Option ,Day,Week,Month,Quarter,Year,"Accounting Period";
        Rounding: Option ,Pennies,Dollars,Hundreds,Thousands,Millions;
        NoPeriods: Integer;
        CurrentPeriod: Integer;
        EntryNo: Integer;
        Text000: Label 'There are not enough accounting periods set up to complete this budget.';
        Text001: Label 'Please enter a beginning date for the history.';
        Text002: Label 'Please enter a beginning date for the budget.';
        Text003: Label 'Please enter the number of periods to budget.';
        GlobalDim1Code: Code[20];
        GlobalDim2Code: Code[20];

    procedure NextDate(CurrentDate: Date): Date
    var
        CalculatedDate: Date;
    begin
        case PeriodLength of
            PeriodLength::Day:
                CalculatedDate := CalcDate('<+1D>', CurrentDate);
            PeriodLength::Week:
                CalculatedDate := CalcDate('<+1W>', CurrentDate);
            PeriodLength::Month:
                CalculatedDate := CalcDate('<+1M>', CurrentDate);
            PeriodLength::Quarter:
                CalculatedDate := CalcDate('<+1Q>', CurrentDate);
            PeriodLength::Year:
                CalculatedDate := CalcDate('<+1Y>', CurrentDate);
            PeriodLength::"Accounting Period":
                begin
                    AcctPeriod.SetFilter("Starting Date", '>%1', CurrentDate);
                    if not AcctPeriod.FindFirst() then
                        Error(Text000);
                    CalculatedDate := AcctPeriod."Starting Date";
                end;
        end;
        exit(CalculatedDate);
    end;
}

