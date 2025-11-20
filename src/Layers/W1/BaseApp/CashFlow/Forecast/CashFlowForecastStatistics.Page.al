// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CashFlow.Forecast;

using Microsoft.CashFlow.Setup;

page 868 "Cash Flow Forecast Statistics"
{
    Caption = 'Cash Flow Forecast Statistics';
    Editable = false;
    PageType = Card;
    SourceTable = "Cash Flow Forecast";

    layout
    {
        area(content)
        {
            group(Disclaimer)
            {
                Caption = ' ';
                ShowCaption = false;
                Editable = false;
                InstructionalText = 'AI generated suggestions may not always be accurate. Please validate results for correctness before using content provided.';
            }
            group(General)
            {
                Caption = 'General';
                field(LiquidFunds; Rec.CalcSourceTypeAmount(CashFlowForecastEntry."Source Type"::"Liquid Funds"))
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Liquid Funds';
                    ToolTip = 'Specifies amounts related to liquid funds.';

                    trigger OnDrillDown()
                    begin
                        Rec.DrillDownSourceTypeEntries(Rec."Source Type Filter"::"Liquid Funds");
                    end;
                }
                field(Receivables; Rec.CalcSourceTypeAmount(CashFlowForecastEntry."Source Type"::Receivables))
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Receivables';
                    ToolTip = 'Specifies amounts related to receivables.';

                    trigger OnDrillDown()
                    begin
                        Rec.DrillDownSourceTypeEntries(Rec."Source Type Filter"::Receivables);
                    end;
                }
                field(SalesOrders; Rec.CalcSourceTypeAmount(CashFlowForecastEntry."Source Type"::"Sales Orders"))
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Sales Orders';
                    ToolTip = 'Specifies amounts related to sales orders.';

                    trigger OnDrillDown()
                    begin
                        Rec.DrillDownSourceTypeEntries(Rec."Source Type Filter"::"Sales Orders");
                    end;
                }
                field(SalesofFixedAssets; Rec.CalcSourceTypeAmount(CashFlowForecastEntry."Source Type"::"Fixed Assets Disposal"))
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Fixed Assets Disposal';
                    ToolTip = 'Specifies amounts related to fixed assets disposal.';

                    trigger OnDrillDown()
                    begin
                        Rec.DrillDownSourceTypeEntries(Rec."Source Type Filter"::"Fixed Assets Disposal");
                    end;
                }
                field(ManualRevenues; Rec.CalcSourceTypeAmount(CashFlowForecastEntry."Source Type"::"Cash Flow Manual Revenue"))
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Cash Flow Manual Revenues';
                    ToolTip = 'Specifies amounts related to cash flow manual revenues.';

                    trigger OnDrillDown()
                    begin
                        Rec.DrillDownSourceTypeEntries(Rec."Source Type Filter"::"Cash Flow Manual Revenue");
                    end;
                }
                field(Payables; Rec.CalcSourceTypeAmount(CashFlowForecastEntry."Source Type"::Payables))
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    Caption = 'Payables';
                    ToolTip = 'Specifies amounts related to payables.';

                    trigger OnDrillDown()
                    begin
                        Rec.DrillDownSourceTypeEntries(Rec."Source Type Filter"::Payables);
                    end;
                }
                field(PurchaseOrders; Rec.CalcSourceTypeAmount(CashFlowForecastEntry."Source Type"::"Purchase Orders"))
                {
                    ApplicationArea = Suite;
                    Caption = 'Purchase Orders';
                    ToolTip = 'Specifies amounts related to purchase orders.';

                    trigger OnDrillDown()
                    begin
                        Rec.DrillDownSourceTypeEntries(Rec."Source Type Filter"::"Purchase Orders");
                    end;
                }
                field(BudgetedFixedAssets; Rec.CalcSourceTypeAmount(CashFlowForecastEntry."Source Type"::"Fixed Assets Budget"))
                {
                    ApplicationArea = FixedAssets;
                    Caption = 'Fixed Assets Budget';
                    ToolTip = 'Specifies amounts related to fixed asset budgets.';

                    trigger OnDrillDown()
                    begin
                        Rec.DrillDownSourceTypeEntries(Rec."Source Type Filter"::"Fixed Assets Budget");
                    end;
                }
                field(ManualExpenses; Rec.CalcSourceTypeAmount(CashFlowForecastEntry."Source Type"::"Cash Flow Manual Expense"))
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Cash Flow Manual Expenses';
                    ToolTip = 'Specifies amounts related to cash flow manual expenses.';

                    trigger OnDrillDown()
                    begin
                        Rec.DrillDownSourceTypeEntries(Rec."Source Type Filter"::"Cash Flow Manual Expense");
                    end;
                }
                field(GLBudgets; Rec.CalcSourceTypeAmount(CashFlowForecastEntry."Source Type"::"G/L Budget"))
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'G/L Budgets';
                    ToolTip = 'Specifies amounts related to general ledger budgets.';

                    trigger OnDrillDown()
                    begin
                        Rec.DrillDownSourceTypeEntries(Rec."Source Type Filter"::"G/L Budget");
                    end;
                }
                field(Job; Rec.CalcSourceTypeAmount(CashFlowForecastEntry."Source Type"::Job))
                {
                    ApplicationArea = Jobs;
                    Caption = 'Project';
                    ToolTip = 'Specifies amounts related to projects.';

                    trigger OnDrillDown()
                    begin
                        Rec.DrillDownSourceTypeEntries(Rec."Source Type Filter"::Job);
                    end;
                }
                field(Tax; Rec.CalcSourceTypeAmount(CashFlowForecastEntry."Source Type"::Tax))
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Tax';
                    ToolTip = 'Specifies amounts related to taxes.';

                    trigger OnDrillDown()
                    begin
                        Rec.DrillDownSourceTypeEntries(Rec."Source Type Filter"::Tax);
                    end;
                }
                field(Total; Rec.CalcSourceTypeAmount("Cash Flow Source Type"::" "))
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = Format(StrSubstNo(Text1000, Format(Rec."Manual Payments To")));
                    Caption = 'Total';
                    ToolTip = 'Specifies total amounts.';

                    trigger OnDrillDown()
                    begin
                        Rec.DrillDownSourceTypeEntries("Cash Flow Source Type"::" ");
                    end;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        if CurrentDate <> WorkDate() then
            CurrentDate := WorkDate();
        if Rec."Manual Payments To" <> 0D then
            CurrentDate := Rec."Manual Payments To";

        if Rec."Manual Payments From" <> 0D then
            Rec.SetCashFlowDateFilter(Rec."Manual Payments From", CurrentDate)
        else
            Rec.SetCashFlowDateFilter(0D, CurrentDate);
    end;

    var
        CashFlowForecastEntry: Record "Cash Flow Forecast Entry";
        CurrentDate: Date;

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text1000: Label 'Liquid Funds at %1';
#pragma warning restore AA0470
#pragma warning restore AA0074
}

