// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CashFlow.Forecast;

using Microsoft.CashFlow.Setup;
using Microsoft.Finance.Analysis;
using Microsoft.Foundation.Enums;
using Microsoft.Foundation.Period;
using System.Utilities;

page 866 "Cash Flow Availability Lines"
{
    Caption = 'Lines';
    PageType = ListPart;
    SourceTable = "Cash Flow Availability Buffer";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater(Control1000)
            {
                Editable = false;
                ShowCaption = false;
                field("Period Start"; Rec."Period Start")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies on which date the period starts, such as the first day of March, if the period is Month.';
                }
                field("Period Name"; Rec."Period Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the accounting period. it is a good idea to use descriptive names, such as Month01, 1st Month, 1st Month/2000, Month01-2000, M1-2001/2002, etc.';
                }
                field(Receivables; Rec.Receivables)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = FormatStr();
                    AutoFormatType = 11;
                    Caption = 'Receivables';
                    ToolTip = 'Specifies amounts related to receivables.';

                    trigger OnDrillDown()
                    begin
                        CashFlowForecast.DrillDownSourceTypeEntries(CashFlowForecast."Source Type Filter"::Receivables);
                    end;
                }
                field(SalesOrders; Rec."Sales Orders")
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = FormatStr();
                    AutoFormatType = 11;
                    Caption = 'Sales Orders';
                    ToolTip = 'Specifies amounts related to sales orders.';

                    trigger OnDrillDown()
                    begin
                        CashFlowForecast.DrillDownSourceTypeEntries(CashFlowForecast."Source Type Filter"::"Sales Orders");
                    end;
                }
                field(SalesofFixedAssets; Rec."Fixed Assets Disposal")
                {
                    ApplicationArea = FixedAssets;
                    AutoFormatExpression = FormatStr();
                    AutoFormatType = 11;
                    Caption = 'Fixed Assets Disposal';
                    ToolTip = 'Specifies amounts related to fixed assets disposal.';

                    trigger OnDrillDown()
                    begin
                        CashFlowForecast.DrillDownSourceTypeEntries(CashFlowForecast."Source Type Filter"::"Fixed Assets Disposal");
                    end;
                }
                field(ManualRevenues; Rec."Cash Flow Manual Revenues")
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = FormatStr();
                    AutoFormatType = 11;
                    Caption = 'Cash Flow Manual Revenues';
                    ToolTip = 'Specifies amounts related to manual revenues.';

                    trigger OnDrillDown()
                    begin
                        CashFlowForecast.DrillDownSourceTypeEntries(CashFlowForecast."Source Type Filter"::"Cash Flow Manual Revenue");
                    end;
                }
                field(Payables; Rec.Payables)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = FormatStr();
                    AutoFormatType = 11;
                    Caption = 'Payables';
                    ToolTip = 'Specifies amounts related to payables.';

                    trigger OnDrillDown()
                    begin
                        CashFlowForecast.DrillDownSourceTypeEntries(CashFlowForecast."Source Type Filter"::Payables);
                    end;
                }
                field(PurchaseOrders; Rec."Purchase Orders")
                {
                    ApplicationArea = Suite;
                    AutoFormatExpression = FormatStr();
                    AutoFormatType = 11;
                    Caption = 'Purchase Orders';
                    ToolTip = 'Specifies amounts related to purchase orders.';

                    trigger OnDrillDown()
                    begin
                        CashFlowForecast.DrillDownSourceTypeEntries(CashFlowForecast."Source Type Filter"::"Purchase Orders");
                    end;
                }
                field(BudgetedFixedAssets; Rec."Fixed Assets Budget")
                {
                    ApplicationArea = FixedAssets;
                    AutoFormatExpression = FormatStr();
                    AutoFormatType = 11;
                    Caption = 'Fixed Assets Budget';
                    ToolTip = 'Specifies amounts related to fixed assets.';

                    trigger OnDrillDown()
                    begin
                        CashFlowForecast.DrillDownSourceTypeEntries(CashFlowForecast."Source Type Filter"::"Fixed Assets Budget");
                    end;
                }
                field(ManualExpenses; Rec."Cash Flow Manual Expenses")
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = FormatStr();
                    AutoFormatType = 11;
                    Caption = 'Cash Flow Manual Expenses';
                    ToolTip = 'Specifies amounts related to manual expenses.';

                    trigger OnDrillDown()
                    begin
                        CashFlowForecast.DrillDownSourceTypeEntries(CashFlowForecast."Source Type Filter"::"Cash Flow Manual Expense");
                    end;
                }
                field(Budget; Rec."G/L Budget")
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = FormatStr();
                    AutoFormatType = 11;
                    Caption = 'G/L Budget';
                    ToolTip = 'Specifies amounts related to the general ledger budget.';

                    trigger OnDrillDown()
                    begin
                        CashFlowForecast.DrillDownSourceTypeEntries(CashFlowForecast."Source Type Filter"::"G/L Budget");
                    end;
                }
                field(Job; Rec.Job)
                {
                    ApplicationArea = Jobs;
                    AutoFormatExpression = FormatStr();
                    AutoFormatType = 11;
                    Caption = 'Project';
                    ToolTip = 'Specifies amounts related to projects.';

                    trigger OnDrillDown()
                    begin
                        CashFlowForecast.DrillDownSourceTypeEntries(CashFlowForecast."Source Type Filter"::Job);
                    end;
                }
                field(Tax; Rec.Tax)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = FormatStr();
                    AutoFormatType = 11;
                    Caption = 'Tax';
                    ToolTip = 'Specifies amounts related to taxes.';

                    trigger OnDrillDown()
                    begin
                        CashFlowForecast.DrillDownSourceTypeEntries(CashFlowForecast."Source Type Filter"::Tax);
                    end;
                }
                field(Total; Rec.Total)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = FormatStr();
                    AutoFormatType = 11;
                    Caption = 'Total';
                    Style = Strong;
                    StyleExpr = true;
                    ToolTip = 'Specifies total amounts.';

                    trigger OnDrillDown()
                    begin
                        CashFlowForecast.DrillDownSourceTypeEntries(CashFlowForecast."Source Type Filter"::" ");
                    end;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetCurrRecord()
    begin
        CashFlowForecast.SetCashFlowDateFilter(Rec."Period Start", Rec."Period End");
    end;

    trigger OnAfterGetRecord()
    begin
        if DateRec.Get(Rec."Period Type", Rec."Period Start") then;
        CalcLine();
    end;

    trigger OnFindRecord(Which: Text) FoundDate: Boolean
    var
        VariantRec: Variant;
    begin
        VariantRec := Rec;
        FoundDate := PeriodFormLinesMgt.FindDate(VariantRec, DateRec, Which, PeriodType.AsInteger());
        Rec := VariantRec;
    end;

    trigger OnNextRecord(Steps: Integer) ResultSteps: Integer
    var
        VariantRec: Variant;
    begin
        VariantRec := Rec;
        ResultSteps := PeriodFormLinesMgt.NextDate(VariantRec, DateRec, Steps, PeriodType.AsInteger());
        Rec := VariantRec;
    end;

    trigger OnOpenPage()
    begin
        Rec.Reset();
    end;

    protected var
        CashFlowForecast: Record "Cash Flow Forecast";
        RoundingFactor: Enum "Analysis Rounding Factor";

    var
        CashFlowForecast2: Record "Cash Flow Forecast";
        CashFlowForecastEntry: Record "Cash Flow Forecast Entry";
        DateRec: Record Date;
        PeriodFormLinesMgt: Codeunit "Period Form Lines Mgt.";
        MatrixMgt: Codeunit "Matrix Management";
        RoundingFactorFormatString: Text;
        PeriodType: Enum "Analysis Period Type";
        AmountType: Enum "Analysis Amount Type";
        Amounts: array[15] of Decimal;

    procedure SetLines(var NewCashFlowForecast: Record "Cash Flow Forecast"; NewPeriodType: Enum "Analysis Period Type"; NewAmountType: Enum "Analysis Amount Type"; NewRoundingFactor: Enum "Analysis Rounding Factor")
    begin
        CashFlowForecast.Copy(NewCashFlowForecast);
        CashFlowForecast2.Copy(NewCashFlowForecast);
        Rec.DeleteAll();
        PeriodType := NewPeriodType;
        AmountType := NewAmountType;
        CurrPage.Update(false);
        RoundingFactor := NewRoundingFactor;
        RoundingFactorFormatString := MatrixMgt.FormatRoundingFactor(RoundingFactor, false);
    end;

    procedure FormatStr(): Text
    begin
        exit(RoundingFactorFormatString);
    end;

    local procedure GetAmount(SourceType: Enum "Cash Flow Source Type"): Decimal
    begin
        exit(MatrixMgt.RoundAmount(CashFlowForecast.CalcSourceTypeAmount(SourceType), RoundingFactor));
    end;

    local procedure CalcLine()
    var
        SourceType: Integer;
    begin
        case AmountType of
            AmountType::"Net Change":
                CashFlowForecast.SetCashFlowDateFilter(Rec."Period Start", Rec."Period End");
            AmountType::"Balance at Date":
                CashFlowForecast.SetCashFlowDateFilter(0D, Rec."Period End");
        end;

        for SourceType := 1 to ArrayLen(Amounts) do
            Amounts[SourceType] := MatrixMgt.RoundAmount(Amounts[SourceType], RoundingFactor);

        Rec.Receivables := GetAmount(CashFlowForecastEntry."Source Type"::Receivables);
        Rec."Sales Orders" := GetAmount(CashFlowForecastEntry."Source Type"::"Sales Orders");
        Rec."Fixed Assets Disposal" := GetAmount(CashFlowForecastEntry."Source Type"::"Fixed Assets Disposal");
        Rec."Cash Flow Manual Revenues" := GetAmount(CashFlowForecastEntry."Source Type"::"Cash Flow Manual Revenue");
        Rec.Payables := GetAmount(CashFlowForecastEntry."Source Type"::Payables);
        Rec."Purchase Orders" := GetAmount(CashFlowForecastEntry."Source Type"::"Purchase Orders");
        Rec."Fixed Assets Budget" := GetAmount(CashFlowForecastEntry."Source Type"::"Fixed Assets Budget");
        Rec."Cash Flow Manual Expenses" := GetAmount(CashFlowForecastEntry."Source Type"::"Cash Flow Manual Expense");
        Rec."G/L Budget" := GetAmount(CashFlowForecastEntry."Source Type"::"G/L Budget");
        Rec.Job := GetAmount(CashFlowForecastEntry."Source Type"::Job);
        Rec.Tax := GetAmount(CashFlowForecastEntry."Source Type"::Tax);
        Rec.Total := GetAmount(CashFlowForecastEntry."Source Type"::" ");

        OnAfterCalcLine(CashFlowForecast, Rec, RoundingFactor.AsInteger());
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcLine(var CashFlowForecast: Record "Cash Flow Forecast"; var CashFlowAvailabilityBuffer: Record "Cash Flow Availability Buffer"; RoundingFactor: Option "None","1","1000","1000000")
    begin
    end;
}

