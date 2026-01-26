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

report 10030 "Budget Amount by Period"
{
    Caption = 'Budget Amount by Period';
    ProcessingOnly = true;

    dataset
    {
        dataitem("G/L Account"; "G/L Account")
        {
            DataItemTableView = sorting("No.");
            MaxIteration = 1;
            RequestFilterFields = "No.", "Global Dimension 1 Filter", "Global Dimension 2 Filter", "Budget Filter";

            trigger OnPreDataItem()
            begin
                if DistributeAmt = 0 then
                    Error(Text001);
                if BudgetDate = 0D then
                    Error(Text002);
                if NoPeriods = 0 then
                    Error(Text003);
            end;
        }
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
                    CurrReport.Break()
                    ;
                if CurrentPeriod > 1 then begin
                    BaseAmount := BaseAmount * PercentChg;
                    BudgetDate := NextDate(BudgetDate);
                end;
                EntryNo := EntryNo + 10000;
                GLBudgetEntry.Init();
                GLBudgetEntry."Entry No." := EntryNo;
                GLBudgetEntry."Budget Name" := "G/L Account".GetFilter("Budget Filter");
                GLBudgetEntry."G/L Account No." := "G/L Account"."No.";
                GLBudgetEntry.Date := BudgetDate;
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
                GLBudgetEntry."Dimension Set ID" := DimMgt.GetDimensionSetID(TempDimSetEntry);
                GLBudgetEntry.Amount := Round(BaseAmount, Precision);
                GLBudgetEntry.Insert();
            end;

            trigger OnPreDataItem()
            begin
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

                PercentChg := PercentChg / 100;
                if PercentChg <= 1 then
                    PercentChg := 1 + PercentChg;
                if AmountType = AmountType::"Total Amount" then begin
                    if PercentChg <> 1 then
                        BaseAmount := DistributeAmt / (((PercentChg - Power(PercentChg, NoPeriods)) / (1 - PercentChg)) + 1)
                    else
                        BaseAmount := DistributeAmt / NoPeriods;
                end else
                    BaseAmount := DistributeAmt;

                GLBudgetEntry.Reset();
                if GLBudgetEntry.FindLast() then
                    EntryNo := GLBudgetEntry."Entry No.";
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
                    field(BudgetDate; BudgetDate)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Budget Beginning Date';
                        ToolTip = 'Specifies the starting date of the first budget period to be created.';
                    }
                    field(NoPeriods; NoPeriods)
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
                    field(DistributeAmt; DistributeAmt)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Budget Amount';
                        ToolTip = 'Specifies the budgeted amount. ';
                    }
                    field(AmountType; AmountType)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Amount Type';
                        OptionCaption = 'Total Amount,Beginning Amount';
                        ToolTip = 'Specifies what is shown in the Budget Amount field. Total Amount: The amount is the total of all of the periods to be created. Beginning Amount: The amount is the budget for the first period to be created.';
                    }
                    field(PercentChg; PercentChg)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Period Percent Change';
                        ToolTip = 'Specifies if you want the budget to increase in relation to the previous period. For example, if the budget amount is $100, and the amount type is Beginning Amount, and the period percent change is 10, then the first period will have a budget of $100, the second period will have a budget of $110, the third will have a budget of $121.';
                    }
                    field(Rounding; Rounding)
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
        DistributeAmt: Decimal;
        BaseAmount: Decimal;
        PercentChg: Decimal;
        Precision: Decimal;
        BudgetDate: Date;
        AmountType: Option "Total Amount","Beginning Amount";
        Rounding: Option ,Pennies,Dollars,Hundreds,Thousands,Millions;
        PeriodLength: Option ,Day,Week,Month,Quarter,Year,"Accounting Period";
        NoPeriods: Integer;
        CurrentPeriod: Integer;
        EntryNo: Integer;
        Text000: Label 'There are not enough accounting periods set up to complete this budget.';
        Text001: Label 'Please enter an amount to budget.';
        Text002: Label 'Please enter a beginning date.';
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

