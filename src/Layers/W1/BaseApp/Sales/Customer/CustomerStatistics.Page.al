// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Customer;

using Microsoft.Foundation.Period;
using Microsoft.Inventory.Costing;
using Microsoft.Sales.Receivables;
using Microsoft.Sales.History;

page 151 "Customer Statistics"
{
    Caption = 'Customer Statistics';
    Editable = false;
    LinksAllowed = false;
    PageType = Card;
    SourceTable = Customer;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(CustomerSince; Rec."First Transaction Date")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                }
                field("Balance (LCY)"; Rec."Balance (LCY)")
                {
                    ApplicationArea = Basic, Suite;

                    trigger OnDrillDown()
                    var
                        DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
                        CustLedgEntry: Record "Cust. Ledger Entry";
                    begin
                        DtldCustLedgEntry.SetRange("Customer No.", Rec."No.");
                        Rec.CopyFilter("Global Dimension 1 Filter", DtldCustLedgEntry."Initial Entry Global Dim. 1");
                        Rec.CopyFilter("Global Dimension 2 Filter", DtldCustLedgEntry."Initial Entry Global Dim. 2");
                        Rec.CopyFilter("Currency Filter", DtldCustLedgEntry."Currency Code");
                        CustLedgEntry.DrillDownOnEntries(DtldCustLedgEntry);
                    end;
                }
                group(Sales)
                {
                    Caption = 'Sales';
                    field("Outstanding Orders (LCY)"; Rec."Outstanding Orders (LCY)")
                    {
                        ApplicationArea = Basic, Suite;
                    }
                    field("Shipped Not Invoiced (LCY)"; Rec."Shipped Not Invoiced (LCY)")
                    {
                        ApplicationArea = Basic, Suite;
                    }
                    field("Outstanding Invoices (LCY)"; Rec."Outstanding Invoices (LCY)")
                    {
                        ApplicationArea = Basic, Suite;
                    }
                    field(DaysSinceLastSale; CalcDaysSinceLastSale())
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Days Since Last Sale';
                        ToolTip = 'Specifies the number of days since the last sale was made to the customer.';

                        trigger OnDrillDown()
                        var
                            CustLedgEntry: Record "Cust. Ledger Entry";
                        begin
                            FilterCustLedgEntryToLastSale(CustLedgEntry);
                            Page.RunModal(0, CustLedgEntry);
                        end;
                    }
                }
                field(GetTotalAmountLCY; Rec.GetTotalAmountLCY())
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    Caption = 'Total (LCY)';
                    Importance = Promoted;
                    Style = Strong;
                    StyleExpr = true;
                    ToolTip = 'Specifies the payment amount that the customer owes for completed sales plus sales that are still ongoing.';
                }
                field("Credit Limit (LCY)"; Rec."Credit Limit (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Balance Due (LCY)"; Rec.CalcOverdueBalance())
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = Format(StrSubstNo(Text000, Format(CurrentDate)));

                    trigger OnDrillDown()
                    var
                        DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
                        CustLedgEntry: Record "Cust. Ledger Entry";
                    begin
                        DtldCustLedgEntry.SetFilter("Customer No.", Rec."No.");
                        Rec.CopyFilter("Global Dimension 1 Filter", DtldCustLedgEntry."Initial Entry Global Dim. 1");
                        Rec.CopyFilter("Global Dimension 2 Filter", DtldCustLedgEntry."Initial Entry Global Dim. 2");
                        Rec.CopyFilter("Currency Filter", DtldCustLedgEntry."Currency Code");
                        CustLedgEntry.DrillDownOnOverdueEntries(DtldCustLedgEntry);
                    end;
                }
                field(GetInvoicedPrepmtAmountLCY; Rec.GetInvoicedPrepmtAmountLCY())
                {
                    ApplicationArea = Prepayments;
                    Caption = 'Invoiced Prepayment Amount (LCY)';
                    ToolTip = 'Specifies your sales income from the customer based on invoiced prepayments.';
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
                        field("CustDateName[1]"; CustDateName[1])
                        {
                            ApplicationArea = Basic, Suite;
                            ShowCaption = false;
                        }
                        field("CustSalesLCY[1]"; CustSalesLCY[1])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            Caption = 'Sales (LCY)';
                            ToolTip = 'Specifies your total sales turnover in the fiscal year.';
                        }
                        field(ThisPeriodOriginalCostLCY; CustSalesLCY[1] - CustProfit[1])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            Caption = 'Original Costs (LCY)';
                            ToolTip = 'Specifies the original costs that were associated with the sales when they were originally posted.';
                        }
                        field(ThisPeriodOriginalProfitLCY; CustProfit[1])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            Caption = 'Original Profit (LCY)';
                            ToolTip = 'Specifies the original profit that was associated with the sales when they were originally posted.';
                        }
                        field("ProfitPct[1]"; ProfitPct[1])
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Original Profit %';
                            DecimalPlaces = 1 : 1;
                            ToolTip = 'Specifies the original percentage of profit that was associated with the sales when they were originally posted.';
                        }
                        field(ThisPeriodAdjustedCostLCY; CustSalesLCY[1] - CustProfit[1] - AdjmtCostLCY[1])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            Caption = 'Adjusted Costs (LCY)';
                            ToolTip = 'Specifies the costs that have been adjusted for changes in the purchase prices of the goods.';
                        }
                        field(ThisPeriodAdjustedProfitLCY; AdjCustProfit[1])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            Caption = 'Adjusted Profit (LCY)';
                            ToolTip = 'Specifies the profit, taking into consideration changes in the purchase prices of the goods.';
                        }
                        field("AdjProfitPct[1]"; AdjProfitPct[1])
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Adjusted Profit %';
                            DecimalPlaces = 1 : 1;
                            ToolTip = 'Specifies the percentage of profit for all sales, including changes that occurred in the purchase prices of the goods.';
                        }
                        field(ThisPeriodCostAdjmtAmountsLCY; -AdjmtCostLCY[1])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            Caption = 'Cost Adjmt. Amounts (LCY)';
                            ToolTip = 'Specifies the sum of the differences between original costs of the goods and the adjusted costs.';
                        }
                        field("CustInvDiscAmountLCY[1]"; CustInvDiscAmountLCY[1])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            Caption = 'Inv. Discounts (LCY)';
                            ToolTip = 'Specifies the sum of invoice discount amounts granted the customer.';
                        }
                        field("InvAmountsLCY[1]"; InvAmountsLCY[1])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            Caption = 'Inv. Amounts (LCY)';
                            ToolTip = 'Specifies the sum of amounts that have been invoiced to the customer.';
                        }
                        field("CustReminderChargeAmtLCY[1]"; CustReminderChargeAmtLCY[1])
                        {
                            ApplicationArea = Suite;
                            AutoFormatType = 1;
                            Caption = 'Reminder Amounts (LCY)';
                            ToolTip = 'Specifies the sum of amounts that the customer has been reminded to pay.';
                        }
                        field("CustFinChargeAmtLCY[1]"; CustFinChargeAmtLCY[1])
                        {
                            ApplicationArea = Suite;
                            AutoFormatType = 1;
                            Caption = 'Fin. Charges (LCY)';
                            ToolTip = 'Specifies the sum of amounts that the customer has been charged on finance charge memos.';
                        }
                        field("CustCrMemoAmountsLCY[1]"; CustCrMemoAmountsLCY[1])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            Caption = 'Cr. Memo Amounts (LCY)';
                            ToolTip = 'Specifies the sum of amounts that have been refunded to the customer.';
                        }
                        field("CustPaymentsLCY[1]"; CustPaymentsLCY[1])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            Caption = 'Payments (LCY)';
                            ToolTip = 'Specifies the sum of payments received from the customer in the current fiscal year.';
                        }
                        field("CustRefundsLCY[1]"; CustRefundsLCY[1])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            Caption = 'Refunds (LCY)';
                            ToolTip = 'Specifies the sum of refunds paid to the customer.';
                        }
                        field("CustOtherAmountsLCY[1]"; CustOtherAmountsLCY[1])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            Caption = 'Other Amounts (LCY)';
                            ToolTip = 'Specifies the sum of other amounts for the customer.';
                        }
                        field("CustPaymentDiscLCY[1]"; CustPaymentDiscLCY[1])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            Caption = 'Pmt. Discounts (LCY)';
                            ToolTip = 'Specifies the sum of payment discounts granted to the customer.';
                        }
                        field("CustPaymentDiscTolLCY[1]"; CustPaymentDiscTolLCY[1])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            Caption = 'Pmt. Disc. Tol. (LCY)';
                            ToolTip = 'Specifies the sum of payment discount tolerance for the customer.';
                        }
                        field("CustPaymentTolLCY[1]"; CustPaymentTolLCY[1])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            Caption = 'Pmt. Tolerances (LCY)';
                            ToolTip = 'Specifies the sum of payment tolerance for the customer.';
                        }
                        field(NumberOfSalesDocs1; NumberOfSalesDocs[1])
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'No. of Sales Docs.';
                            ToolTip = 'Specifies the number of sales documents for the customer.';
                        }
                        field(NumberOfDistinctItemsSold1; NumberOfDistinctItemsSold[1])
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'No. of Distinct Items Sold';
                            ToolTip = 'Specifies the number of distinct items sold to the customer.';
                        }
                    }
                    group("This Year")
                    {
                        Caption = 'This Fiscal Year';
                        field(Text001; Text001)
                        {
                            ApplicationArea = Basic, Suite;
                            ShowCaption = false;
                            Visible = false;
                        }
                        field("CustSalesLCY[2]"; CustSalesLCY[2])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            Caption = 'Sales (LCY)';
                            ToolTip = 'Specifies your total sales turnover in the fiscal year.';
                        }
                        field("CustSalesLCY[2] - CustProfit[2]"; CustSalesLCY[2] - CustProfit[2])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            Caption = 'Original Costs (LCY)';
                            ToolTip = 'Specifies the original costs that were associated with the sales when they were originally posted.';
                        }
                        field("CustProfit[2]"; CustProfit[2])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            Caption = 'Original Profit (LCY)';
                            ToolTip = 'Specifies the original profit that was associated with the sales when they were originally posted.';
                        }
                        field("ProfitPct[2]"; ProfitPct[2])
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Original Profit %';
                            DecimalPlaces = 1 : 1;
                            ToolTip = 'Specifies the original percentage of profit that was associated with the sales when they were originally posted.';
                        }
                        field("CustSalesLCY[2] - CustProfit[2] - AdjmtCostLCY[2]"; CustSalesLCY[2] - CustProfit[2] - AdjmtCostLCY[2])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            Caption = 'Adjusted Costs (LCY)';
                            ToolTip = 'Specifies the costs that have been adjusted for changes in the purchase prices of the goods.';
                        }
                        field("AdjCustProfit[2]"; AdjCustProfit[2])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            Caption = 'Adjusted Profit (LCY)';
                            ToolTip = 'Specifies the profit, taking into consideration changes in the purchase prices of the goods.';
                        }
                        field("AdjProfitPct[2]"; AdjProfitPct[2])
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Adjusted Profit %';
                            DecimalPlaces = 1 : 1;
                            ToolTip = 'Specifies the percentage of profit for all sales, including changes that occurred in the purchase prices of the goods.';
                        }
                        field("-AdjmtCostLCY[2]"; -AdjmtCostLCY[2])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            Caption = 'Adjustment Costs (LCY)';
                            ToolTip = 'Specifies the sum of adjustment amounts.';
                        }
                        field("CustInvDiscAmountLCY[2]"; CustInvDiscAmountLCY[2])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            Caption = 'Inv. Discounts (LCY)';
                            ToolTip = 'Specifies the sum of invoice discount amounts granted the customer.';
                        }
                        field("InvAmountsLCY[2]"; InvAmountsLCY[2])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            Caption = 'Inv. Amounts (LCY)';
                            ToolTip = 'Specifies the sum of amounts that have been invoiced to the customer.';
                        }
                        field("CustReminderChargeAmtLCY[2]"; CustReminderChargeAmtLCY[2])
                        {
                            ApplicationArea = Suite;
                            AutoFormatType = 1;
                            Caption = 'Reminder Amounts (LCY)';
                            ToolTip = 'Specifies the sum of amounts that the customer has been reminded to pay.';
                        }
                        field("CustFinChargeAmtLCY[2]"; CustFinChargeAmtLCY[2])
                        {
                            ApplicationArea = Suite;
                            AutoFormatType = 1;
                            Caption = 'Fin. Charges (LCY)';
                            ToolTip = 'Specifies the sum of amounts that the customer has been charged on finance charge memos.';
                        }
                        field("CustCrMemoAmountsLCY[2]"; CustCrMemoAmountsLCY[2])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            Caption = 'Cr. Memo Amounts (LCY)';
                            ToolTip = 'Specifies the sum of amounts that have been refunded to the customer.';
                        }
                        field("CustPaymentsLCY[2]"; CustPaymentsLCY[2])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            Caption = 'Payments (LCY)';
                            ToolTip = 'Specifies the sum of payments received from the customer in the current fiscal year.';
                        }
                        field("CustRefundsLCY[2]"; CustRefundsLCY[2])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            Caption = 'Refunds (LCY)';
                            ToolTip = 'Specifies the sum of refunds paid to the customer.';
                        }
                        field("CustOtherAmountsLCY[2]"; CustOtherAmountsLCY[2])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            Caption = 'Other Amounts (LCY)';
                            ToolTip = 'Specifies the sum of other amounts for the customer.';
                        }
                        field("CustPaymentDiscLCY[2]"; CustPaymentDiscLCY[2])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            Caption = 'Pmt. Discounts (LCY)';
                            ToolTip = 'Specifies the sum of payment discounts granted to the customer.';
                        }
                        field("CustPaymentDiscTolLCY[2]"; CustPaymentDiscTolLCY[2])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            Caption = 'Pmt. Disc. Tolerance (LCY)';
                            ToolTip = 'Specifies the sum of payment discount tolerance for the customer.';
                        }
                        field("CustPaymentTolLCY[2]"; CustPaymentTolLCY[2])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            Caption = 'Payment Tolerances (LCY)';
                            ToolTip = 'Specifies the sum of payment tolerance for the customer.';
                        }
                        field(NumberOfSalesDocs2; NumberOfSalesDocs[2])
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'No. of Sales Docs.';
                            ToolTip = 'Specifies the number of sales documents for the customer.';
                        }
                        field(NumberOfDistinctItemsSold2; NumberOfDistinctItemsSold[2])
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'No. of Distinct Items Sold';
                            ToolTip = 'Specifies the number of distinct items sold to the customer.';
                        }
                    }
                    group("Last Year")
                    {
                        Caption = 'Last Fiscal Year';
                        field(Placeholder1; Text001)
                        {
                            ApplicationArea = Basic, Suite;
                            ShowCaption = false;
                            Visible = false;
                        }
                        field("CustSalesLCY[3]"; CustSalesLCY[3])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            Caption = 'Sales (LCY)';
                            ToolTip = 'Specifies your total sales turnover in the fiscal year.';
                        }
                        field("CustSalesLCY[3] - CustProfit[3]"; CustSalesLCY[3] - CustProfit[3])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            Caption = 'Original Costs (LCY)';
                            ToolTip = 'Specifies the original costs that were associated with the sales when they were originally posted.';
                        }
                        field("CustProfit[3]"; CustProfit[3])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            Caption = 'Original Profit (LCY)';
                            ToolTip = 'Specifies the original profit that was associated with the sales when they were originally posted.';
                        }
                        field("ProfitPct[3]"; ProfitPct[3])
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Original Profit %';
                            DecimalPlaces = 1 : 1;
                            ToolTip = 'Specifies the original percentage of profit that was associated with the sales when they were originally posted.';
                        }
                        field("CustSalesLCY[3] - CustProfit[3] - AdjmtCostLCY[3]"; CustSalesLCY[3] - CustProfit[3] - AdjmtCostLCY[3])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            Caption = 'Adjusted Costs (LCY)';
                            ToolTip = 'Specifies the costs that have been adjusted for changes in the purchase prices of the goods.';
                        }
                        field("AdjCustProfit[3]"; AdjCustProfit[3])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            Caption = 'Adjusted Profit (LCY)';
                            ToolTip = 'Specifies the profit, taking into consideration changes in the purchase prices of the goods.';
                        }
                        field("AdjProfitPct[3]"; AdjProfitPct[3])
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Adjusted Profit %';
                            DecimalPlaces = 1 : 1;
                            ToolTip = 'Specifies the percentage of profit for all sales, including changes that occurred in the purchase prices of the goods.';
                        }
                        field("-AdjmtCostLCY[3]"; -AdjmtCostLCY[3])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            Caption = 'Adjustment Costs (LCY)';
                            ToolTip = 'Specifies the sum of adjustment amounts.';
                        }
                        field("CustInvDiscAmountLCY[3]"; CustInvDiscAmountLCY[3])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            Caption = 'Inv. Discounts (LCY)';
                            ToolTip = 'Specifies the sum of invoice discount amounts granted the customer.';
                        }
                        field("InvAmountsLCY[3]"; InvAmountsLCY[3])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            Caption = 'Inv. Amounts (LCY)';
                            ToolTip = 'Specifies the sum of amounts that have been invoiced to the customer.';
                        }
                        field("CustReminderChargeAmtLCY[3]"; CustReminderChargeAmtLCY[3])
                        {
                            ApplicationArea = Suite;
                            AutoFormatType = 1;
                            Caption = 'Reminder Amounts (LCY)';
                            ToolTip = 'Specifies the sum of amounts that the customer has been reminded to pay.';
                        }
                        field("CustFinChargeAmtLCY[3]"; CustFinChargeAmtLCY[3])
                        {
                            ApplicationArea = Suite;
                            AutoFormatType = 1;
                            Caption = 'Fin. Charges (LCY)';
                            ToolTip = 'Specifies the sum of amounts that the customer has been charged on finance charge memos.';
                        }
                        field("CustCrMemoAmountsLCY[3]"; CustCrMemoAmountsLCY[3])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            Caption = 'Cr. Memo Amounts (LCY)';
                            ToolTip = 'Specifies the sum of amounts that have been refunded to the customer.';
                        }
                        field("CustPaymentsLCY[3]"; CustPaymentsLCY[3])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            Caption = 'Payments (LCY)';
                            ToolTip = 'Specifies the sum of payments received from the customer in the current fiscal year.';
                        }
                        field("CustRefundsLCY[3]"; CustRefundsLCY[3])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            Caption = 'Refunds (LCY)';
                            ToolTip = 'Specifies the sum of refunds paid to the customer.';
                        }
                        field("CustOtherAmountsLCY[3]"; CustOtherAmountsLCY[3])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            Caption = 'Other Amounts (LCY)';
                            ToolTip = 'Specifies the sum of other amounts for the customer.';
                        }
                        field("CustPaymentDiscLCY[3]"; CustPaymentDiscLCY[3])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            Caption = 'Pmt. Discounts (LCY)';
                            ToolTip = 'Specifies the sum of payment discounts granted to the customer.';
                        }
                        field("CustPaymentDiscTolLCY[3]"; CustPaymentDiscTolLCY[3])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            Caption = 'Pmt. Disc. Tolerance (LCY)';
                            ToolTip = 'Specifies the sum of payment discount tolerance for the customer.';
                        }
                        field("CustPaymentTolLCY[3]"; CustPaymentTolLCY[3])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            Caption = 'Payment Tolerances (LCY)';
                            ToolTip = 'Specifies the sum of payment tolerance for the customer.';
                        }
                        field(NumberOfSalesDocs3; NumberOfSalesDocs[3])
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'No. of Sales Docs.';
                            ToolTip = 'Specifies the number of sales documents for the customer.';
                        }
                        field(NumberOfDistinctItemsSold3; NumberOfDistinctItemsSold[3])
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'No. of Distinct Items Sold';
                            ToolTip = 'Specifies the number of distinct items sold to the customer.';
                        }
                    }
                    group("To Date")
                    {
                        Caption = 'Lifetime (since)';
                        field(CustSinceDate; Rec."First Transaction Date")
                        {
                            ApplicationArea = Basic, Suite;
                            ShowCaption = false;
                        }
                        field("CustSalesLCY[4]"; CustSalesLCY[4])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            Caption = 'Sales (LCY)';
                            ToolTip = 'Specifies your total sales turnover in the fiscal year.';
                        }
                        field("CustSalesLCY[4] - CustProfit[4]"; CustSalesLCY[4] - CustProfit[4])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            Caption = 'Original Costs (LCY)';
                            ToolTip = 'Specifies the original costs that were associated with the sales when they were originally posted.';
                        }
                        field("CustProfit[4]"; CustProfit[4])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            Caption = 'Original Profit (LCY)';
                            ToolTip = 'Specifies the original profit that was associated with the sales when they were originally posted.';
                        }
                        field("ProfitPct[4]"; ProfitPct[4])
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Original Profit %';
                            DecimalPlaces = 1 : 1;
                            ToolTip = 'Specifies the original percentage of profit that was associated with the sales when they were originally posted.';
                        }
                        field("CustSalesLCY[4] - CustProfit[4] - AdjmtCostLCY[4]"; CustSalesLCY[4] - CustProfit[4] - AdjmtCostLCY[4])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            Caption = 'Adjusted Costs (LCY)';
                            ToolTip = 'Specifies the costs that have been adjusted for changes in the purchase prices of the goods.';
                        }
                        field("AdjCustProfit[4]"; AdjCustProfit[4])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            Caption = 'Adjusted Profit (LCY)';
                            ToolTip = 'Specifies the profit, taking into consideration changes in the purchase prices of the goods.';
                        }
                        field("AdjProfitPct[4]"; AdjProfitPct[4])
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Adjusted Profit %';
                            DecimalPlaces = 1 : 1;
                            ToolTip = 'Specifies the percentage of profit for all sales, including changes that occurred in the purchase prices of the goods.';
                        }
                        field("-AdjmtCostLCY[4]"; -AdjmtCostLCY[4])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            Caption = 'Adjustment Costs (LCY)';
                            ToolTip = 'Specifies the sum of adjustment amounts.';
                        }
                        field("CustInvDiscAmountLCY[4]"; CustInvDiscAmountLCY[4])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            Caption = 'Inv. Discounts (LCY)';
                            ToolTip = 'Specifies the sum of invoice discount amounts granted the customer.';
                        }
                        field("InvAmountsLCY[4]"; InvAmountsLCY[4])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            Caption = 'Inv. Amounts (LCY)';
                            ToolTip = 'Specifies the sum of amounts that have been invoiced to the customer.';
                        }
                        field("CustReminderChargeAmtLCY[4]"; CustReminderChargeAmtLCY[4])
                        {
                            ApplicationArea = Suite;
                            AutoFormatType = 1;
                            Caption = 'Reminder Amounts (LCY)';
                            ToolTip = 'Specifies the sum of amounts that the customer has been reminded to pay.';
                        }
                        field("CustFinChargeAmtLCY[4]"; CustFinChargeAmtLCY[4])
                        {
                            ApplicationArea = Suite;
                            AutoFormatType = 1;
                            Caption = 'Fin. Charges (LCY)';
                            ToolTip = 'Specifies the sum of amounts that the customer has been charged on finance charge memos.';
                        }
                        field("CustCrMemoAmountsLCY[4]"; CustCrMemoAmountsLCY[4])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            Caption = 'Cr. Memo Amounts (LCY)';
                            ToolTip = 'Specifies the sum of amounts that have been refunded to the customer.';
                        }
                        field("CustPaymentsLCY[4]"; CustPaymentsLCY[4])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            Caption = 'Payments (LCY)';
                            ToolTip = 'Specifies the sum of payments received from the customer in the current fiscal year.';
                        }
                        field("CustRefundsLCY[4]"; CustRefundsLCY[4])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            Caption = 'Refunds (LCY)';
                            ToolTip = 'Specifies the sum of refunds paid to the customer.';
                        }
                        field("CustOtherAmountsLCY[4]"; CustOtherAmountsLCY[4])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            Caption = 'Other Amounts (LCY)';
                            ToolTip = 'Specifies the sum of other amounts for the customer.';
                        }
                        field("CustPaymentDiscLCY[4]"; CustPaymentDiscLCY[4])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            Caption = 'Pmt. Discounts (LCY)';
                            ToolTip = 'Specifies the sum of payment discounts granted to the customer.';
                        }
                        field("CustPaymentDiscTolLCY[4]"; CustPaymentDiscTolLCY[4])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            Caption = 'Pmt. Disc. Tolerance (LCY)';
                            ToolTip = 'Specifies the sum of payment discount tolerance for the customer.';
                        }
                        field("CustPaymentTolLCY[4]"; CustPaymentTolLCY[4])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            Caption = 'Payment Tolerances (LCY)';
                            ToolTip = 'Specifies the sum of payment tolerance for the customer.';
                        }
                        field(NumberOfSalesDocs4; NumberOfSalesDocs[4])
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'No. of Sales Docs.';
                            ToolTip = 'Specifies the number of sales documents for the customer.';
                        }
                        field(NumberOfDistinctItemsSold4; NumberOfDistinctItemsSold[4])
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'No. of Distinct Items Sold';
                            ToolTip = 'Specifies the number of distinct items sold to the customer.';
                        }
                    }
#if not CLEAN27
#pragma warning disable AA0218, AA0225, AA0189
                    field(Placeholder2; Text001)
                    {
                        ApplicationArea = None;
                        Visible = false;
                        ObsoleteState = Pending;
                        ObsoleteReason = 'Replaced with CustSinceDate.';
                        ObsoleteTag = '27.0';
                    }
#pragma warning restore AA0218, AA0225, AA0189
#endif
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    var
        CostCalcMgt: Codeunit "Cost Calculation Management";
    begin
        if CurrentDate <> WorkDate() then begin
            CurrentDate := WorkDate();
            DateFilterCalc.CreateAccountingPeriodFilter(CustDateFilter[1], CustDateName[1], CurrentDate, 0);
            DateFilterCalc.CreateFiscalYearFilter(CustDateFilter[2], CustDateName[2], CurrentDate, 0);
            DateFilterCalc.CreateFiscalYearFilter(CustDateFilter[3], CustDateName[3], CurrentDate, -1);
        end;

        SetDateFilter();

        for i := 1 to 4 do begin
            Rec.SetFilter("Date Filter", CustDateFilter[i]);
            Rec.CalcFields(
              "Sales (LCY)", "Profit (LCY)", "Inv. Discounts (LCY)", "Inv. Amounts (LCY)", "Pmt. Discounts (LCY)",
              "Pmt. Disc. Tolerance (LCY)", "Pmt. Tolerance (LCY)",
              "Fin. Charge Memo Amounts (LCY)", "Cr. Memo Amounts (LCY)", "Payments (LCY)",
              "Reminder Amounts (LCY)", "Refunds (LCY)", "Other Amounts (LCY)");
            CustSalesLCY[i] := Rec."Sales (LCY)";
            CustProfit[i] := Rec."Profit (LCY)";
            AdjmtCostLCY[i] :=
              CustSalesLCY[i] - CustProfit[i] + CostCalcMgt.CalcCustActualCostLCY(Rec) + CostCalcMgt.NonInvtblCostAmt(Rec);
            AdjCustProfit[i] := CustProfit[i] + AdjmtCostLCY[i];

            if Rec."Sales (LCY)" <> 0 then begin
                ProfitPct[i] := Round(100 * CustProfit[i] / Rec."Sales (LCY)", 0.1);
                AdjProfitPct[i] := Round(100 * AdjCustProfit[i] / Rec."Sales (LCY)", 0.1);
            end else begin
                ProfitPct[i] := 0;
                AdjProfitPct[i] := 0;
            end;

            InvAmountsLCY[i] := Rec."Inv. Amounts (LCY)";
            CustInvDiscAmountLCY[i] := Rec."Inv. Discounts (LCY)";
            CustPaymentDiscLCY[i] := Rec."Pmt. Discounts (LCY)";
            CustPaymentDiscTolLCY[i] := Rec."Pmt. Disc. Tolerance (LCY)";
            CustPaymentTolLCY[i] := Rec."Pmt. Tolerance (LCY)";
            CustReminderChargeAmtLCY[i] := Rec."Reminder Amounts (LCY)";
            CustFinChargeAmtLCY[i] := Rec."Fin. Charge Memo Amounts (LCY)";
            CustCrMemoAmountsLCY[i] := Rec."Cr. Memo Amounts (LCY)";
            CustPaymentsLCY[i] := Rec."Payments (LCY)";
            CustRefundsLCY[i] := Rec."Refunds (LCY)";
            CustOtherAmountsLCY[i] := Rec."Other Amounts (LCY)";
            NumberOfSalesDocs[i] := CalcNumberOfSalesInvoices(CustDateFilter[i]);
            NumberOfDistinctItemsSold[i] := CalcNumberOfDistinctItemsSold(CustDateFilter[i]);
        end;
        Rec.SetRange("Date Filter", 0D, CurrentDate);
    end;

    var
        DateFilterCalc: Codeunit "DateFilter-Calc";
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'Overdue Amounts (LCY) as of %1';
#pragma warning restore AA0470
        Text001: Label 'Placeholder';
#pragma warning restore AA0074

    protected var
        CustDateFilter: array[4] of Text[30];
        CustDateName: array[4] of Text[30];
        CurrentDate: Date;
        CustSalesLCY: array[4] of Decimal;
        AdjmtCostLCY: array[4] of Decimal;
        CustProfit: array[4] of Decimal;
        ProfitPct: array[4] of Decimal;
        AdjCustProfit: array[4] of Decimal;
        AdjProfitPct: array[4] of Decimal;
        CustInvDiscAmountLCY: array[4] of Decimal;
        CustPaymentDiscLCY: array[4] of Decimal;
        CustPaymentDiscTolLCY: array[4] of Decimal;
        CustPaymentTolLCY: array[4] of Decimal;
        CustReminderChargeAmtLCY: array[4] of Decimal;
        CustFinChargeAmtLCY: array[4] of Decimal;
        CustCrMemoAmountsLCY: array[4] of Decimal;
        CustPaymentsLCY: array[4] of Decimal;
        CustRefundsLCY: array[4] of Decimal;
        CustOtherAmountsLCY: array[4] of Decimal;
        InvAmountsLCY: array[4] of Decimal;
        i: Integer;
        NumberOfSalesDocs: array[4] of Integer;
        NumberOfDistinctItemsSold: array[4] of Integer;

    local procedure SetDateFilter()
    begin
        Rec.SetRange("Date Filter", 0D, CurrentDate);

        OnAfterSetDateFilter(Rec);
    end;

    local procedure CalcDaysSinceLastSale(): Integer
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        if FilterCustLedgEntryToLastSale(CustLedgerEntry) then
            exit(WorkDate() - CustLedgerEntry."Posting Date");
    end;

    local procedure FilterCustLedgEntryToLastSale(var CustLedgerEntry: Record "Cust. Ledger Entry"): Boolean
    begin
        CustLedgerEntry.SetCurrentKey("Posting Date");
        CustLedgerEntry.SetRange("Customer No.", Rec."No.");
        CustLedgerEntry.SetFilter("Sales (LCY)", '>%1', 0);
        CustLedgerEntry.SetRange(Reversed, false);
        if CustLedgerEntry.FindLast() then begin
            CustLedgerEntry.SetRecFilter();
            exit(true);
        end;
    end;

    local procedure CalcNumberOfSalesInvoices(DateFilter: Text): Integer
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        SalesInvoiceHeader.SetRange("Sell-To Customer No.", Rec."No.");
        SalesInvoiceHeader.SetFilter("Posting Date", DateFilter);
        exit(SalesInvoiceHeader.Count());
    end;

    local procedure CalcNumberOfDistinctItemsSold(DateFilter: Text) Count: Integer
    var
        DistinctItemsSoldQuery: Query "Distinct Items Sold";
    begin
        DistinctItemsSoldQuery.SetFilter(PostingDateFilter, DateFilter);
        DistinctItemsSoldQuery.SetRange(CustomerNoFilter, Rec."No.");

        if DistinctItemsSoldQuery.Open() then
            while DistinctItemsSoldQuery.Read() do
                Count += 1;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetDateFilter(var Customer: Record Customer)
    begin
    end;
}
