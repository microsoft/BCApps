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
    SourceTable = Item;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Current Inventory Value"; CurrentInventoryValue)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Current Inventory Value (LCY)';
                    ToolTip = 'Specifies the current inventory value (in local currency), calculated as the sum of Cost Amount (Actual) + Cost Amount (Expected) on posted Value Entries for this item. Run the Adjust Cost - Item Entries batch job to ensure the amount is up to date.';

                    trigger OnDrillDown()
                    begin
                        ItemStatistics.DrilldownCurrentInventoryValue(Rec);
                    end;
                }
                field("Expired Stock Value"; ExpiredStockValue)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Expired Inventory Value (LCY)';
                    ToolTip = 'Specifies the inventory value (in local currency) of quantities whose expiration date is earlier than the work date. Calculated as the sum of Cost Amount (Actual) + Cost Amount (Expected) from Value Entries applied to open Item Ledger Entries (Remaining Qty. > 0) with Expiration Date < Work Date. Run the Adjust Cost - Item Entries batch job to ensure the value is up to date. Only meaningful for items where expiration/lot dates are tracked.';

                    trigger OnDrillDown()
                    begin
                        ItemStatistics.DrilldownExpiredStockValue(Rec);
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
                        field("ItemDateName[1]"; ItemDateName[1])
                        {
                            ApplicationArea = Basic, Suite;
                            ShowCaption = false;
                        }
                        field("SalesGrowthRate[1]"; SalesGrowthRate[1])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 10;
                            AutoFormatExpression = '<precision, 2:2><standard format,0>%';
                            Caption = 'Sales Growth Rate (%)';
                            ToolTip = 'Specifies the percentage change in sales compared to the previous period in the fiscal year, calculated as ((Sales in the current period in the fiscal year - Sales in the prior period in the fiscal year) ÷ Sales in the prior period in the fiscal year) x 100%. A positive value indicates growth, while a negative value indicates a decline in sales.';

                            trigger OnDrillDown()
                            begin
                                ItemStatistics.DrilldownSalesGrowthRate(Rec, ItemDateFilter[1], PriorPeriodItemDateFilter[1]);
                            end;
                        }
                        field("NetSalesLCY[1]"; NetSales[1])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            Caption = 'Net Sales (LCY)';
                            ToolTip = 'Specifies the total revenue (in local currency) from sales for the current period in fiscal year after deducting given discounts and returns. This value represents the actual income generated from sales transactions during the fiscal year. Calculated as: Net Sales = Total sales in the period  - Total returns - Total given discounts.';

                            trigger OnDrillDown()
                            begin
                                ItemStatistics.DrilldownSalesAmount(Rec, ItemDateFilter[1]);
                            end;
                        }
                        field("GrossMargin[1]"; GrossMargin[1])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 10;
                            AutoFormatExpression = '<precision, 2:2><standard format,0>%';
                            Caption = 'Gross Margin (%)';
                            ToolTip = 'Specifies the percentage of revenue remaining after deducting the cost of goods sold (COGS) for the current period in the fiscal year. This metric indicates how efficiently the company produces and sells its products. Calculated as: Gross Margin (%) = ((Net Sales - COGS) ÷ Net Sales) x 100%. A higher percentage reflects better profitability.';

                            trigger OnDrillDown()
                            begin
                                ItemStatistics.DrilldownSalesAmount(Rec, ItemDateFilter[1]);
                            end;
                        }
                        field("ReturnRate[1]"; ReturnRate[1])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 10;
                            AutoFormatExpression = '<precision, 2:2><standard format,0>%';
                            Caption = 'Return Rate (%)';
                            ToolTip = 'Specifies the percentage of sold quantity that were returned during the current period in the fiscal year. This metric helps measure product quality and customer satisfaction. Calculated as: Return Rate (%) = (Returned Quantity ÷ Total Sold Quantity) x 100%. A lower percentage indicates fewer returns and higher product acceptance.';

                            trigger OnDrillDown()
                            begin
                                ItemStatistics.DrilldownProductReturnRate(Rec, ItemDateFilter[1]);
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
                        field("SalesGrowthRate[2]"; SalesGrowthRate[2])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 10;
                            AutoFormatExpression = '<precision, 2:2><standard format,0>%';
                            Caption = 'Sales Growth Rate (%)';
                            ToolTip = 'Specifies the percentage change in sales compared to the previous fiscal year, calculated as ((Sales in current fiscal year - Sales in the last fiscal year) ÷ Sales in the last fiscal year) x 100%. A positive value indicates growth, while a negative value indicates a decline in sales.';

                            trigger OnDrillDown()
                            begin
                                ItemStatistics.DrilldownSalesGrowthRate(Rec, ItemDateFilter[2], PriorPeriodItemDateFilter[2]);
                            end;
                        }
                        field("NetSalesLCY[2]"; NetSales[2])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            Caption = 'Net Sales (LCY)';
                            ToolTip = 'Specifies the total revenue (in local currency) from sales for the current fiscal year after deducting given discounts and returns. This value represents the actual income generated from sales transactions during the fiscal year. Calculated as: Net Sales = Total sales in the fiscal year - Total returns in the fiscal year - Total given discounts in the fiscal year.';
                            trigger OnDrillDown()
                            begin
                                ItemStatistics.DrilldownSalesAmount(Rec, ItemDateFilter[2]);
                            end;
                        }
                        field("GrossMargin[2]"; GrossMargin[2])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 10;
                            AutoFormatExpression = '<precision, 2:2><standard format,0>%';
                            Caption = 'Gross Margin (%)';
                            ToolTip = 'Specifies the percentage of revenue remaining after deducting the cost of goods sold (COGS) for the current fiscal year. This metric indicates how efficiently the company produces and sells its products. Calculated as: Gross Margin (%) = ((Net Sales - COGS) ÷ Net Sales) x 100%. A higher percentage reflects better profitability.';

                            trigger OnDrillDown()
                            begin
                                ItemStatistics.DrilldownSalesAmount(Rec, ItemDateFilter[2]);
                            end;
                        }
                        field("ReturnRate[2]"; ReturnRate[2])
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Return Rate (%)';
                            AutoFormatType = 10;
                            AutoFormatExpression = '<precision, 2:2><standard format,0>%';
                            ToolTip = 'Specifies the percentage of sold quantity that were returned during the current fiscal year. This metric helps measure product quality and customer satisfaction. Calculated as: Return Rate (%) = (Returned Quantity ÷ Total Sold Quantity) x 100%. A lower percentage indicates fewer returns and higher product acceptance.';

                            trigger OnDrillDown()
                            begin
                                ItemStatistics.DrilldownProductReturnRate(Rec, ItemDateFilter[2]);
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
                        field("SalesGrowthRate[3]"; SalesGrowthRate[3])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 10;
                            AutoFormatExpression = '<precision, 2:2><standard format,0>%';
                            Caption = 'Sales Growth Rate (%)';
                            ToolTip = 'Specifies the percentage change in sales compared to the previous fiscal year, calculated as ((Sales in the last fiscal year - Sales in the prior fiscal year) ÷ Sales in the prior fiscal year) x 100%. A positive value indicates growth, while a negative value indicates a decline in sales.';

                            trigger OnDrillDown()
                            begin
                                ItemStatistics.DrilldownSalesGrowthRate(Rec, ItemDateFilter[3], PriorPeriodItemDateFilter[3]);
                            end;
                        }
                        field("NetSalesLCY[3]"; NetSales[3])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            Caption = 'Net Sales (LCY)';
                            ToolTip = 'Specifies the total revenue (in local currency) from sales for the last fiscal year after deducting given discounts and returns. This value represents the actual income generated from sales transactions during the last fiscal year. Calculated as: Net Sales = Total sales in the last fiscal year - Total returns in the last fiscal year - Total given discounts in the last fiscal year.';
                            trigger OnDrillDown()
                            begin
                                ItemStatistics.DrilldownSalesAmount(Rec, ItemDateFilter[3]);
                            end;
                        }
                        field("GrossMargin[3]"; GrossMargin[3])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 10;
                            AutoFormatExpression = '<precision, 2:2><standard format,0>%';
                            Caption = 'Gross Margin (%)';
                            ToolTip = 'Specifies the percentage of revenue remaining after deducting the cost of goods sold (COGS) for the last fiscal year. This metric indicates how efficiently the company produces and sells its products. Calculated as: Gross Margin (%) = ((Net Sales - COGS) ÷ Net Sales) x 100%. A higher percentage reflects better profitability.';

                            trigger OnDrillDown()
                            begin
                                ItemStatistics.DrilldownSalesAmount(Rec, ItemDateFilter[3]);
                            end;
                        }
                        field("ReturnRate[3]"; ReturnRate[3])
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Return Rate (%)';
                            AutoFormatType = 10;
                            AutoFormatExpression = '<precision, 2:2><standard format,0>%';
                            ToolTip = 'Specifies the percentage of sold quantity that were returned during the last fiscal year. This metric helps measure product quality and customer satisfaction. Calculated as: Return Rate (%) = (Returned Quantity ÷ Total Sold Quantity) x 100%. A lower percentage indicates fewer returns and higher product acceptance.';

                            trigger OnDrillDown()
                            begin
                                ItemStatistics.DrilldownProductReturnRate(Rec, ItemDateFilter[3]);
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
                        field("NetSalesLCY[4]"; NetSales[4])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            Caption = 'Net Sales (LCY)';
                            ToolTip = 'Specifies the total revenue (in local currency) from sales after deducting given discounts and returns. This value represents the actual income generated from sales transactions during the lifetime. Calculated as: Net Sales = Total sales so far - Total returns so far - Total given discounts so far.';

                            trigger OnDrillDown()
                            begin
                                ItemStatistics.DrilldownSalesAmount(Rec, ItemDateFilter[4]);
                            end;
                        }
                        field("GrossMargin[4]"; GrossMargin[4])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 10;
                            AutoFormatExpression = '<precision, 2:2><standard format,0>%';
                            Caption = 'Gross Margin (%)';
                            ToolTip = 'Specifies the percentage of revenue remaining after deducting the cost of goods sold (COGS) for the lifetime. This metric indicates how efficiently the company produces and sells its products. Calculated as: Gross Margin (%) = ((Net Sales - COGS) ÷ Net Sales) x 100%. A higher percentage reflects better profitability.';

                            trigger OnDrillDown()
                            begin
                                ItemStatistics.DrilldownSalesAmount(Rec, ItemDateFilter[4]);
                            end;
                        }
                        field("ReturnRate[4]"; ReturnRate[4])
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Return Rate';
                            AutoFormatType = 10;
                            AutoFormatExpression = '<precision, 2:2><standard format,0>%';
                            ToolTip = 'Specifies the percentage of sold quantity that were returned during the lifetime. This metric helps measure product quality and customer satisfaction. Calculated as: Return Rate (%) = (Returned Quantity ÷ Total Sold Quantity) x 100%. A lower percentage indicates fewer returns and higher product acceptance.';

                            trigger OnDrillDown()
                            begin
                                ItemStatistics.DrilldownProductReturnRate(Rec, ItemDateFilter[4]);
                            end;
                        }
                    }
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        if CurrentDate <> WorkDate() then begin
            CurrentDate := WorkDate();
            DateFilterCalc.CreateAccountingPeriodFilter(ItemDateFilter[1], ItemDateName[1], CurrentDate, 0);
            DateFilterCalc.CreateFiscalYearFilter(ItemDateFilter[2], ItemDateName[2], CurrentDate, 0);
            DateFilterCalc.CreateFiscalYearFilter(ItemDateFilter[3], ItemDateName[3], CurrentDate, -1);

            DateFilterCalc.CreateAccountingPeriodFilter(PriorPeriodItemDateFilter[1], PriorPeriodItemDateName[1], CurrentDate, -1);
            DateFilterCalc.CreateFiscalYearFilter(PriorPeriodItemDateFilter[2], PriorPeriodItemDateName[2], CurrentDate, -1);
            DateFilterCalc.CreateFiscalYearFilter(PriorPeriodItemDateFilter[3], PriorPeriodItemDateName[3], CurrentDate, -2);
        end;

        CurrentInventoryValue := ItemStatistics.CalculateCurrentInventoryValue(Rec);
        ExpiredStockValue := ItemStatistics.CalculateExpiredStockValue(Rec);

        for i := 1 to 4 do begin
            if i <= 3 then
                SalesGrowthRate[i] := ItemStatistics.CalculateSalesGrowthRate(Rec, ItemDateFilter[i], PriorPeriodItemDateFilter[i]) / 100;
            NetSales[i] := ItemStatistics.CalculateNetSales(Rec, ItemDateFilter[i]);
            GrossMargin[i] := ItemStatistics.CalculateGrossMarginPercentage(Rec, ItemDateFilter[i]) / 100;
            ReturnRate[i] := ItemStatistics.CalculateProductReturnRate(Rec, ItemDateFilter[i]) / 100;
        end;
        Rec.SetRange("Date Filter", 0D, CurrentDate);
    end;

    var
        ItemStatistics: Codeunit "Item Statistics";
        DateFilterCalc: Codeunit "DateFilter-Calc";
        CurrentInventoryValue: Decimal;
        ExpiredStockValue: Decimal;
        PlaceHolderLbl: Label 'Placeholder';

        ItemDateFilter: array[4] of Text[30];
        ItemDateName: array[4] of Text[30];
        PriorPeriodItemDateFilter: array[4] of Text[30];
        PriorPeriodItemDateName: array[4] of Text[30];
        CurrentDate: Date;
        SalesGrowthRate: array[4] of Decimal;
        NetSales: array[4] of Decimal;
        GrossMargin: array[4] of Decimal;
        ReturnRate: array[4] of Decimal;
        i: Integer;
}
