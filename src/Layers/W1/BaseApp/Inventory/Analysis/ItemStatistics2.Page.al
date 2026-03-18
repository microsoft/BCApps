// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Analysis;

using Microsoft.Foundation.Period;
using Microsoft.Inventory.Item;

page 5833 "Item Statistics 2"
{
    Caption = 'Item Statistics';
    Editable = false;
    LinksAllowed = false;
    PageType = Card;
    SourceTable = "Item Statistics Cache";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Current Inventory Value"; Rec.CurrentInventoryValue)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 0;
                    Caption = 'Current Inventory Value (LCY)';

                    trigger OnDrillDown()
                    begin
                        ItemStatistics.DrilldownCurrentInventoryValue(Item);
                    end;
                }
                field("Expired Stock Value"; Rec.ExpiredStockValue)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 0;
                    Caption = 'Expired Inventory Value (LCY)';

                    trigger OnDrillDown()
                    begin
                        ItemStatistics.DrilldownExpiredStockValue(Item);
                    end;
                }
            }
            group(Control1904305601)
            {
                Caption = 'Sales';
                fixed(Control1904230801)
                {
                    ShowCaption = false;
                    group("This Period")
                    {
                        Caption = 'This Fiscal Period';
                        field("ItemDateName[1]"; ItemDateNames[1])
                        {
                            ApplicationArea = Basic, Suite;
                            ShowCaption = false;
                        }
                        field("SalesGrowthRate[1]"; Rec.SalesGrowthRateThisPeriod)
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 10;
                            AutoFormatExpression = '<precision, 2:2><standard format,0>%';
                            Caption = 'Sales Growth Rate (%)';
                            ToolTip = 'Specifies the percentage change in sales compared to the previous period in the fiscal year, calculated as ((Sales in the current period in the fiscal year - Sales in the prior period in the fiscal year) ÷ Sales in the prior period in the fiscal year) x 100%. A positive value indicates growth, while a negative value indicates a decline in sales.';

                            trigger OnDrillDown()
                            begin
                                ItemStatistics.DrilldownSalesGrowthRate(Item, ItemDateFilters[1], PriorPeriodItemDateFilters[1]);
                            end;
                        }
                        field("NetSalesLCY[1]"; Rec.NetSalesLCYThisPeriod)
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            AutoFormatExpression = '';
                            Caption = 'Net Sales (LCY)';

                            trigger OnDrillDown()
                            begin
                                ItemStatistics.DrilldownSalesAmount(Item, ItemDateFilters[1]);
                            end;
                        }
                        field("GrossMargin[1]"; Rec.GrossMarginThisPeriod)
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 10;
                            AutoFormatExpression = '<precision, 2:2><standard format,0>%';
                            Caption = 'Gross Margin (%)';
                            ToolTip = 'Specifies the percentage of revenue remaining after deducting the cost of goods sold (COGS) for the current period in the fiscal year. This metric indicates how efficiently the company produces and sells its products. Calculated as: Gross Margin (%) = ((Net Sales - COGS) ÷ Net Sales) x 100%. A higher percentage reflects better profitability.';

                            trigger OnDrillDown()
                            begin
                                ItemStatistics.DrilldownSalesAmount(Item, ItemDateFilters[1]);
                            end;
                        }
                        field("ReturnRate[1]"; Rec.ReturnRateThisPeriod)
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 10;
                            AutoFormatExpression = '<precision, 2:2><standard format,0>%';
                            Caption = 'Return Rate (%)';
                            ToolTip = 'Specifies the percentage of sold quantity that were returned during the current period in the fiscal year. This metric helps measure product quality and customer satisfaction. Calculated as: Return Rate (%) = (Returned Quantity ÷ Total Sold Quantity) x 100%. A lower percentage indicates fewer returns and higher product acceptance.';

                            trigger OnDrillDown()
                            begin
                                ItemStatistics.DrilldownProductReturnRate(Item, ItemDateFilters[1]);
                            end;
                        }
                    }
                    group("This Year")
                    {
                        Caption = 'This Fiscal Year';
                        field(PlaceHolder; PlaceHolderLbl)
                        {
                            ApplicationArea = Basic, Suite;
                            ShowCaption = false;
                            Visible = false;
                        }
                        field("SalesGrowthRate[2]"; Rec.SalesGrowthRateThisFY)
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 10;
                            AutoFormatExpression = '<precision, 2:2><standard format,0>%';
                            Caption = 'Sales Growth Rate (%)';
                            ToolTip = 'Specifies the percentage change in sales compared to the previous fiscal year, calculated as ((Sales in current fiscal year - Sales in the last fiscal year) ÷ Sales in the last fiscal year) x 100%. A positive value indicates growth, while a negative value indicates a decline in sales.';

                            trigger OnDrillDown()
                            begin
                                ItemStatistics.DrilldownSalesGrowthRate(Item, ItemDateFilters[2], PriorPeriodItemDateFilters[2]);
                            end;
                        }
                        field("NetSalesLCY[2]"; Rec.NetSalesLCYThisFY)
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            AutoFormatExpression = '';
                            Caption = 'Net Sales (LCY)';
                            trigger OnDrillDown()
                            begin
                                ItemStatistics.DrilldownSalesAmount(Item, ItemDateFilters[2]);
                            end;
                        }
                        field("GrossMargin[2]"; Rec.GrossMarginThisFY)
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 10;
                            AutoFormatExpression = '<precision, 2:2><standard format,0>%';
                            Caption = 'Gross Margin (%)';
                            ToolTip = 'Specifies the percentage of revenue remaining after deducting the cost of goods sold (COGS) for the current fiscal year. This metric indicates how efficiently the company produces and sells its products. Calculated as: Gross Margin (%) = ((Net Sales - COGS) ÷ Net Sales) x 100%. A higher percentage reflects better profitability.';

                            trigger OnDrillDown()
                            begin
                                ItemStatistics.DrilldownSalesAmount(Item, ItemDateFilters[2]);
                            end;
                        }
                        field("ReturnRate[2]"; Rec.ReturnRateThisFY)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Return Rate (%)';
                            AutoFormatType = 10;
                            AutoFormatExpression = '<precision, 2:2><standard format,0>%';
                            ToolTip = 'Specifies the percentage of sold quantity that were returned during the current fiscal year. This metric helps measure product quality and customer satisfaction. Calculated as: Return Rate (%) = (Returned Quantity ÷ Total Sold Quantity) x 100%. A lower percentage indicates fewer returns and higher product acceptance.';

                            trigger OnDrillDown()
                            begin
                                ItemStatistics.DrilldownProductReturnRate(Item, ItemDateFilters[2]);
                            end;
                        }
                    }
                    group("Last Year")
                    {
                        Caption = 'Last Fiscal Year';
                        field(Placeholder1; PlaceHolderLbl)
                        {
                            ApplicationArea = Basic, Suite;
                            ShowCaption = false;
                            Visible = false;
                        }
                        field("SalesGrowthRate[3]"; Rec.SalesGrowthRateLastFY)
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 10;
                            AutoFormatExpression = '<precision, 2:2><standard format,0>%';
                            Caption = 'Sales Growth Rate (%)';
                            ToolTip = 'Specifies the percentage change in sales compared to the previous fiscal year, calculated as ((Sales in the last fiscal year - Sales in the prior fiscal year) ÷ Sales in the prior fiscal year) x 100%. A positive value indicates growth, while a negative value indicates a decline in sales.';

                            trigger OnDrillDown()
                            begin
                                ItemStatistics.DrilldownSalesGrowthRate(Item, ItemDateFilters[3], PriorPeriodItemDateFilters[3]);
                            end;
                        }
                        field("NetSalesLCY[3]"; Rec.NetSalesLCYLastFY)
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            AutoFormatExpression = '';
                            Caption = 'Net Sales (LCY)';
                            trigger OnDrillDown()
                            begin
                                ItemStatistics.DrilldownSalesAmount(Item, ItemDateFilters[3]);
                            end;
                        }
                        field("GrossMargin[3]"; Rec.GrossMarginLastFY)
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 10;
                            AutoFormatExpression = '<precision, 2:2><standard format,0>%';
                            Caption = 'Gross Margin (%)';
                            ToolTip = 'Specifies the percentage of revenue remaining after deducting the cost of goods sold (COGS) for the last fiscal year. This metric indicates how efficiently the company produces and sells its products. Calculated as: Gross Margin (%) = ((Net Sales - COGS) ÷ Net Sales) x 100%. A higher percentage reflects better profitability.';

                            trigger OnDrillDown()
                            begin
                                ItemStatistics.DrilldownSalesAmount(Item, ItemDateFilters[3]);
                            end;
                        }
                        field("ReturnRate[3]"; Rec.ReturnRateLastFY)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Return Rate (%)';
                            AutoFormatType = 10;
                            AutoFormatExpression = '<precision, 2:2><standard format,0>%';
                            ToolTip = 'Specifies the percentage of sold quantity that were returned during the last fiscal year. This metric helps measure product quality and customer satisfaction. Calculated as: Return Rate (%) = (Returned Quantity ÷ Total Sold Quantity) x 100%. A lower percentage indicates fewer returns and higher product acceptance.';

                            trigger OnDrillDown()
                            begin
                                ItemStatistics.DrilldownProductReturnRate(Item, ItemDateFilters[3]);
                            end;
                        }
                    }
                    group("To Date")
                    {
                        Caption = 'Lifetime';
                        field(Placeholder2; PlaceHolderLbl)
                        {
                            ApplicationArea = Basic, Suite;
                            ShowCaption = false;
                            Visible = false;
                        }
                        field(Placeholder3; PlaceHolderLbl)
                        {
                            ApplicationArea = Basic, Suite;
                            ShowCaption = false;
                            Visible = false;
                        }
                        field("NetSalesLCY[4]"; Rec.NetSalesLCYLifetime)
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            AutoFormatExpression = '';
                            Caption = 'Net Sales (LCY)';

                            trigger OnDrillDown()
                            begin
                                ItemStatistics.DrilldownSalesAmount(Item, ItemDateFilters[4]);
                            end;
                        }
                        field("GrossMargin[4]"; Rec.GrossMarginLifetime)
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 10;
                            AutoFormatExpression = '<precision, 2:2><standard format,0>%';
                            Caption = 'Gross Margin (%)';
                            ToolTip = 'Specifies the percentage of revenue remaining after deducting the cost of goods sold (COGS) for the lifetime. This metric indicates how efficiently the company produces and sells its products. Calculated as: Gross Margin (%) = ((Net Sales - COGS) ÷ Net Sales) x 100%. A higher percentage reflects better profitability.';

                            trigger OnDrillDown()
                            begin
                                ItemStatistics.DrilldownSalesAmount(Item, ItemDateFilters[4]);
                            end;
                        }
                        field("ReturnRate[4]"; Rec.ReturnRateLifetime)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Return Rate';
                            AutoFormatType = 10;
                            AutoFormatExpression = '<precision, 2:2><standard format,0>%';
                            ToolTip = 'Specifies the percentage of sold quantity that were returned during the lifetime. This metric helps measure product quality and customer satisfaction. Calculated as: Return Rate (%) = (Returned Quantity ÷ Total Sold Quantity) x 100%. A lower percentage indicates fewer returns and higher product acceptance.';

                            trigger OnDrillDown()
                            begin
                                ItemStatistics.DrilldownProductReturnRate(Item, ItemDateFilters[4]);
                            end;
                        }
                    }
                }
            }
        }
    }

    trigger OnOpenPage()
    var
        Parameters: Dictionary of [Text, Text];
        ItemNoFilter: Text;
    begin
        ItemNoFilter := Rec.GetFilter("Item No.");
        Item.SetFilter("No.", ItemNoFilter);
        Item.FindFirst();

        CurrentDate := WorkDate();
        CreateDateFilters();

        if not Rec.Get(Item."No.") then
            Rec.InitAndInsert(Item."No.");

        Commit();

        SetPageBackgroundTaskParameters(Parameters);
        CurrPage.EnqueueBackgroundTask(TaskId, Codeunit::ItemStatisticsCache, Parameters);
    end;

    var
        Item: Record Item;
        ItemStatistics: Codeunit "Item Statistics";
        ItemDateFilters: array[4] of Text[30];
        ItemDateNames: array[4] of Text[30];
        PriorPeriodItemDateFilters: array[4] of Text[30];
        PriorPeriodItemDateNames: array[4] of Text[30];
        CurrentDate: Date;
        PlaceHolderLbl: Label 'Placeholder';
        TaskId: Integer;

    local procedure CreateDateFilters()
    var
        DateFilterCalc: Codeunit "DateFilter-Calc";
    begin
        DateFilterCalc.CreateAccountingPeriodFilter(ItemDateFilters[1], ItemDateNames[1], CurrentDate, 0);
        DateFilterCalc.CreateFiscalYearFilter(ItemDateFilters[2], ItemDateNames[2], CurrentDate, 0);
        DateFilterCalc.CreateFiscalYearFilter(ItemDateFilters[3], ItemDateNames[3], CurrentDate, -1);
        DateFilterCalc.CreateAccountingPeriodFilter(PriorPeriodItemDateFilters[1], PriorPeriodItemDateNames[1], CurrentDate, -1);
        DateFilterCalc.CreateFiscalYearFilter(PriorPeriodItemDateFilters[2], PriorPeriodItemDateNames[2], CurrentDate, -1);
        DateFilterCalc.CreateFiscalYearFilter(PriorPeriodItemDateFilters[3], PriorPeriodItemDateNames[3], CurrentDate, -2);
    end;

    local procedure SetPageBackgroundTaskParameters(var Parameters: Dictionary of [Text, Text])
    begin
        Parameters.Add('ItemNo', Item."No.");
        Parameters.Add('CurrentDate', Format(CurrentDate));
        Parameters.Add('ItemDateFilter1', ItemDateFilters[1]);
        Parameters.Add('ItemDateFilter2', ItemDateFilters[2]);
        Parameters.Add('ItemDateFilter3', ItemDateFilters[3]);
        Parameters.Add('ItemDateFilter4', ItemDateFilters[4]);
        Parameters.Add('PriorPeriodItemDateFilter1', PriorPeriodItemDateFilters[1]);
        Parameters.Add('PriorPeriodItemDateFilter2', PriorPeriodItemDateFilters[2]);
        Parameters.Add('PriorPeriodItemDateFilter3', PriorPeriodItemDateFilters[3]);
    end;

    trigger OnPageBackgroundTaskCompleted(TaskId: Integer; Results: Dictionary of [Text, Text])
    begin
        Evaluate(Rec."LastUpdated", Results.Get('LastUpdated'));

        Evaluate(Rec.CurrentInventoryValue, Results.Get('CurrentInventoryValue'));
        Evaluate(Rec.ExpiredStockValue, Results.Get('ExpiredStockValue'));

        Evaluate(Rec.SalesGrowthRateThisPeriod, Results.Get('SalesGrowthRateThisPeriod'));
        Evaluate(Rec.SalesGrowthRateLastFY, Results.Get('SalesGrowthRateLastFY'));
        Evaluate(Rec.SalesGrowthRateThisFY, Results.Get('SalesGrowthRateThisFY'));

        Evaluate(Rec.ReturnRateThisPeriod, Results.Get('ReturnRateThisPeriod'));
        Evaluate(Rec.ReturnRateThisFY, Results.Get('ReturnRateThisFY'));
        Evaluate(Rec.ReturnRateLastFY, Results.Get('ReturnRateLastFY'));
        Evaluate(Rec.ReturnRateLifetime, Results.Get('ReturnRateLifetime'));

        Evaluate(Rec.NetSalesLCYThisPeriod, Results.Get('NetSalesLCYThisPeriod'));
        Evaluate(Rec.NetSalesLCYThisFY, Results.Get('NetSalesLCYThisFY'));
        Evaluate(Rec.NetSalesLCYLastFY, Results.Get('NetSalesLCYLastFY'));
        Evaluate(Rec.NetSalesLCYLifetime, Results.Get('NetSalesLCYLifetime'));

        Evaluate(Rec.GrossMarginThisPeriod, Results.Get('GrossMarginThisPeriod'));
        Evaluate(Rec.GrossMarginThisFY, Results.Get('GrossMarginThisFY'));
        Evaluate(Rec.GrossMarginLastFY, Results.Get('GrossMarginLastFY'));
        Evaluate(Rec.GrossMarginLifetime, Results.Get('GrossMarginLifetime'));

        Rec.Modify();
    end;
}
