// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Document;

using Microsoft.Finance.Currency;
using Microsoft.Finance.VAT.Calculation;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Posting;
using Microsoft.Sales.Pricing;
using Microsoft.Sales.Setup;
using System.Utilities;

page 402 "Sales Order Statistics"
{
    Caption = 'Sales Order Statistics';
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    PageType = Card;
    SourceTable = "Sales Header";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(LineAmountGeneral; TotalSalesLine[1]."Line Amount")
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = Rec."Currency Code";
                    AutoFormatType = 1;
                    CaptionClass = GetCaptionClass(Text002, false);
                    Editable = false;
                }
                field(InvDiscountAmount_General; TotalSalesLine[1]."Inv. Discount Amount")
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = Rec."Currency Code";
                    AutoFormatType = 1;
                    Caption = 'Inv. Discount Amount';
                    Editable = DynamicEditable;
                    ToolTip = 'Specifies the invoice discount amount for the sales document.';

                    trigger OnValidate()
                    begin
                        ActiveTab := ActiveTab::General;
                        UpdateInvDiscAmount(1);
                    end;
                }
                field("TotalAmount1[1]"; TotalAmount1[1])
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = Rec."Currency Code";
                    AutoFormatType = 1;
                    CaptionClass = GetCaptionClass(Text001, false);
                    Editable = DynamicEditable;

                    trigger OnValidate()
                    begin
                        ActiveTab := ActiveTab::General;
                        UpdateTotalAmount(1);
                    end;
                }
                field(VATAmount; VATAmount[1])
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = Rec."Currency Code";
                    AutoFormatType = 1;
                    CaptionClass = Format(VATAmountText[1]);
                    Caption = 'VAT Amount';
                    Editable = false;
                    ToolTip = 'Specifies the total VAT amount that has been calculated for all the lines in the sales document.';
                }
                field("TotalAmount2[1]"; TotalAmount2[1])
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = Rec."Currency Code";
                    AutoFormatType = 1;
                    CaptionClass = GetCaptionClass(Text001, true);
                    Editable = false;

                    trigger OnValidate()
                    begin
                        TotalAmount21OnAfterValidate();
                    end;
                }
                field("TotalSalesLineLCY[1].Amount"; TotalSalesLineLCY[1].Amount)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    Caption = 'Sales (LCY)';
                    Editable = false;
                    ToolTip = 'Specifies your total sales turnover in the fiscal year. It is calculated from amounts excluding VAT on all completed and open sales invoices and credit memos.';
                }
                field("ProfitLCY[1]"; ProfitLCY[1])
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    Caption = 'Original Profit (LCY)';
                    Editable = false;
                    Importance = Additional;
                    ToolTip = 'Specifies the original profit that was associated with the sales when they were originally posted.';
                }
                field("AdjProfitLCY[1]"; AdjProfitLCY[1])
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    Caption = 'Adjusted Profit (LCY)';
                    Editable = false;
                    Importance = Additional;
                    ToolTip = 'Specifies the profit, taking into consideration changes in the purchase prices of the goods.';
                }
                field("ProfitPct[1]"; ProfitPct[1])
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Original Profit %';
                    DecimalPlaces = 1 : 1;
                    Editable = false;
                    Importance = Additional;
                    ToolTip = 'Specifies the original percentage of profit that was associated with the sales when they were originally posted.';
                }
                field("AdjProfitPct[1]"; AdjProfitPct[1])
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Adjusted Profit %';
                    DecimalPlaces = 1 : 1;
                    Editable = false;
                    Importance = Additional;
                    ToolTip = 'Specifies the percentage of profit for all sales, taking into account changes that occurred in the purchase prices of the goods.';
                }
                field("TotalSalesLine[1].Quantity"; TotalSalesLine[1].Quantity)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Quantity';
                    DecimalPlaces = 0 : 5;
                    Editable = false;
                    Importance = Additional;
                    ToolTip = 'Specifies the total quantity of G/L account entries, items, and/or resources in the sales document. If the amount is rounded, because the Invoice Rounding check box is selected in the Sales & Receivables Setup window, this field will contain the quantity of items in the sales document plus one.';
                }
#pragma warning disable AA0100
                field("TotalSalesLine[1].""Units per Parcel"""; TotalSalesLine[1]."Units per Parcel")
#pragma warning restore AA0100
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Parcels';
                    DecimalPlaces = 0 : 5;
                    Editable = false;
                    Importance = Additional;
                    ToolTip = 'Specifies the total number of parcels in the sales document.';
                }
#pragma warning disable AA0100
                field("TotalSalesLine[1].""Net Weight"""; TotalSalesLine[1]."Net Weight")
#pragma warning restore AA0100
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Net Weight';
                    DecimalPlaces = 0 : 5;
                    Editable = false;
                    Importance = Additional;
                    ToolTip = 'Specifies the total net weight of the items in the sales document.';
                }
#pragma warning disable AA0100
                field("TotalSalesLine[1].""Gross Weight"""; TotalSalesLine[1]."Gross Weight")
#pragma warning restore AA0100
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Gross Weight';
                    DecimalPlaces = 0 : 5;
                    Editable = false;
                    Importance = Additional;
                    ToolTip = 'Specifies the total gross weight of the items in the sales document.';
                }
#pragma warning disable AA0100
                field("TotalSalesLine[1].""Unit Volume"""; TotalSalesLine[1]."Unit Volume")
#pragma warning restore AA0100
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Volume';
                    DecimalPlaces = 0 : 5;
                    Editable = false;
                    Importance = Additional;
                    ToolTip = 'Specifies the total volume of the items in the sales document.';
                }
#pragma warning disable AA0100
                field("TotalSalesLineLCY[1].""Unit Cost (LCY)"""; TotalSalesLineLCY[1]."Unit Cost (LCY)")
#pragma warning restore AA0100
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    Caption = 'Original Cost (LCY)';
                    Editable = false;
                    Importance = Additional;
                    ToolTip = 'Specifies the total cost, in LCY, of the G/L account entries, items, and/or resources in the sales document. The cost is calculated as unit cost x quantity of the items or resources.';
                }
                field("TotalAdjCostLCY[1]"; TotalAdjCostLCY[1])
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    Caption = 'Adjusted Cost (LCY)';
                    Editable = false;
                    Importance = Additional;
                    ToolTip = 'Specifies the total cost, in LCY, of the items in the sales document, adjusted for any changes in the original costs of these items. If this field contains zero, it means that there were no entries to calculate, possibly because of date compression or because the adjustment batch job has not yet been run.';
                }
#pragma warning disable AA0100
                field("TotalAdjCostLCY[1] - TotalSalesLineLCY[1].""Unit Cost (LCY)"""; TotalAdjCostLCY[1] - TotalSalesLineLCY[1]."Unit Cost (LCY)")
#pragma warning restore AA0100
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    Caption = 'Cost Adjmt. Amount (LCY)';
                    Editable = false;
                    Importance = Additional;
                    ToolTip = 'Specifies the difference between the original cost and the total adjusted cost of the items in the sales document.';

                    trigger OnDrillDown()
                    begin
                        Rec.LookupAdjmtValueEntries(0);
                    end;
                }
                field(NoOfVATLines_General; TempVATAmountLine1.Count)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'No. of Tax Lines';
                    DrillDown = true;
                    Importance = Additional;
                    ToolTip = 'Specifies the number of lines on the sales order that have VAT amounts.';

                    trigger OnDrillDown()
                    begin
                        VATLinesDrillDown(TempVATAmountLine1, false);
                        UpdateHeaderInfo(1, TempVATAmountLine1);
                    end;
                }
                field("Reserved From Stock"; Rec.GetQtyReservedFromStockState())
                {
                    ApplicationArea = Reservation;
                    Editable = false;
                    Importance = Additional;
                    Caption = 'Reserved from stock';
                    ToolTip = 'Specifies what part of the sales order is reserved from inventory.';
                }
            }
            group(Invoicing)
            {
                Caption = 'Invoicing';
                field(AmountInclVAT_Invoicing; TotalSalesLine[2]."Line Amount")
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = Rec."Currency Code";
                    AutoFormatType = 1;
                    CaptionClass = GetCaptionClass(Text002, false);
                    Editable = false;
                }
                field(InvDiscountAmount_Invoicing; TotalSalesLine[2]."Inv. Discount Amount")
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = Rec."Currency Code";
                    AutoFormatType = 1;
                    Caption = 'Inv. Discount Amount';
                    Editable = DynamicEditable;
                    ToolTip = 'Specifies the invoice discount amount for the sales document.';

                    trigger OnValidate()
                    begin
                        ActiveTab := ActiveTab::Invoicing;
                        UpdateInvDiscAmount(2);
                    end;
                }
                field(TotalInclVAT_Invoicing; TotalAmount1[2])
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = Rec."Currency Code";
                    AutoFormatType = 1;
                    CaptionClass = GetCaptionClass(Text001, false);
                    Editable = DynamicEditable;

                    trigger OnValidate()
                    begin
                        ActiveTab := ActiveTab::Invoicing;
                        UpdateTotalAmount(2);
                    end;
                }
                field(VATAmount_Invoicing; VATAmount[2])
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = Rec."Currency Code";
                    AutoFormatType = 1;
                    CaptionClass = Format(VATAmountText[2]);
                    Editable = false;
                }
                field(TotalExclVAT_Invoicing; TotalAmount2[2])
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = Rec."Currency Code";
                    AutoFormatType = 1;
                    CaptionClass = GetCaptionClass(Text001, true);
                    Editable = false;
                }
                field("TotalSalesLineLCY[2].Amount"; TotalSalesLineLCY[2].Amount)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    Caption = 'Sales (LCY)';
                    Editable = false;
                    ToolTip = 'Specifies your total sales turnover in the fiscal year. It is calculated from amounts excluding VAT on all completed and open sales invoices and credit memos.';
                }
                field("ProfitLCY[2]"; ProfitLCY[2])
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    Caption = 'Original Profit (LCY)';
                    Editable = false;
                    Importance = Additional;
                    ToolTip = 'Specifies the original profit that was associated with the sales when they were originally posted.';
                }
                field("AdjProfitLCY[2]"; AdjProfitLCY[2])
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    Caption = 'Adjusted Profit (LCY)';
                    Editable = false;
                    Importance = Additional;
                    ToolTip = 'Specifies the profit, taking into consideration changes in the purchase prices of the goods.';
                }
                field("ProfitPct[2]"; ProfitPct[2])
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Original Profit %';
                    DecimalPlaces = 1 : 1;
                    Editable = false;
                    Importance = Additional;
                    ToolTip = 'Specifies the original percentage of profit that was associated with the sales when they were originally posted.';
                }
                field("AdjProfitPct[2]"; AdjProfitPct[2])
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Adjusted Profit %';
                    DecimalPlaces = 1 : 1;
                    Editable = false;
                    Importance = Additional;
                    ToolTip = 'Specifies the percentage of profit for all sales, taking into account changes that occurred in the purchase prices of the goods.';
                }
                field("TotalSalesLine[2].Quantity"; TotalSalesLine[2].Quantity)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Quantity';
                    DecimalPlaces = 0 : 5;
                    Editable = false;
                    Importance = Additional;
                    ToolTip = 'Specifies the total quantity of G/L account entries, items, and/or resources in the sales document. If the amount is rounded, because the Invoice Rounding check box is selected in the Sales & Receivables Setup window, this field will contain the quantity of items in the sales document plus one.';
                }
#pragma warning disable AA0100
                field("TotalSalesLine[2].""Units per Parcel"""; TotalSalesLine[2]."Units per Parcel")
#pragma warning restore AA0100
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Parcels';
                    DecimalPlaces = 0 : 5;
                    Editable = false;
                    Importance = Additional;
                    ToolTip = 'Specifies the total number of parcels in the sales document.';
                }
#pragma warning disable AA0100
                field("TotalSalesLine[2].""Net Weight"""; TotalSalesLine[2]."Net Weight")
#pragma warning restore AA0100
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Net Weight';
                    DecimalPlaces = 0 : 5;
                    Editable = false;
                    Importance = Additional;
                    ToolTip = 'Specifies the total net weight of the items in the sales document.';
                }
#pragma warning disable AA0100
                field("TotalSalesLine[2].""Gross Weight"""; TotalSalesLine[2]."Gross Weight")
#pragma warning restore AA0100
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Gross Weight';
                    DecimalPlaces = 0 : 5;
                    Editable = false;
                    Importance = Additional;
                    ToolTip = 'Specifies the total gross weight of the items in the sales document.';
                }
#pragma warning disable AA0100
                field("TotalSalesLine[2].""Unit Volume"""; TotalSalesLine[2]."Unit Volume")
#pragma warning restore AA0100
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Volume';
                    DecimalPlaces = 0 : 5;
                    Editable = false;
                    Importance = Additional;
                    ToolTip = 'Specifies the total volume of the items in the sales document.';
                }
#pragma warning disable AA0100
                field("TotalSalesLineLCY[2].""Unit Cost (LCY)"""; TotalSalesLineLCY[2]."Unit Cost (LCY)")
#pragma warning restore AA0100
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    Caption = 'Original Cost (LCY)';
                    Editable = false;
                    Importance = Additional;
                    ToolTip = 'Specifies the total cost, in LCY, of the G/L account entries, items, and/or resources in the sales document. The cost is calculated as unit cost x quantity of the items or resources.';
                }
                field("TotalAdjCostLCY[2]"; TotalAdjCostLCY[2])
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    Caption = 'Adjusted Cost (LCY)';
                    Editable = false;
                    Importance = Additional;
                    ToolTip = 'Specifies the total cost, in LCY, of the items in the sales document, adjusted for any changes in the original costs of these items. If this field contains zero, it means that there were no entries to calculate, possibly because of date compression or because the adjustment batch job has not yet been run.';
                }
#pragma warning disable AA0100
                field("TotalAdjCostLCY[2] - TotalSalesLineLCY[2].""Unit Cost (LCY)"""; TotalAdjCostLCY[2] - TotalSalesLineLCY[2]."Unit Cost (LCY)")
#pragma warning restore AA0100
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    Caption = 'Cost Adjmt. Amount (LCY)';
                    Editable = false;
                    Importance = Additional;
                    ToolTip = 'Specifies the difference between the original cost and the total adjusted cost of the items in the sales document.';

                    trigger OnDrillDown()
                    begin
                        Rec.LookupAdjmtValueEntries(1);
                    end;
                }
                field(NoOfVATLines_Invoicing; TempVATAmountLine2.Count)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'No. of Tax Lines';
                    DrillDown = true;
                    Importance = Additional;
                    ToolTip = 'Specifies the number of lines on the sales order that have VAT amounts.';

                    trigger OnDrillDown()
                    begin
                        ActiveTab := ActiveTab::Invoicing;
                        VATLinesDrillDown(TempVATAmountLine2, true);
                        UpdateHeaderInfo(2, TempVATAmountLine2);

                        if TempVATAmountLine2.GetAnyLineModified() then begin
                            UpdateVATOnSalesLines();
                            RefreshOnAfterGetRecord();
                        end;
                    end;
                }
                field("Amount Excl. Prepayment"; TotalSalesLine[2]."Line Amount" - PrepmtTotalAmount)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = Rec."Currency Code";
                    AutoFormatType = 1;
                    Caption = 'Amount Excl. Prepayment';
                    Editable = false;
                    ToolTip = 'Specifies the difference between Amount Excl. VAT and Prepayment Amount Excl. VAT.';
                }
            }
            group(Shipping)
            {
                Caption = 'Shipping';
#pragma warning disable AA0100
                field("TotalSalesLine[3].""Line Amount"""; TotalSalesLine[3]."Line Amount")
#pragma warning restore AA0100
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = Rec."Currency Code";
                    AutoFormatType = 1;
                    CaptionClass = GetCaptionClass(Text002, false);
                    Editable = false;
                }
#pragma warning disable AA0100
                field("TotalSalesLine[3].""Inv. Discount Amount"""; TotalSalesLine[3]."Inv. Discount Amount")
#pragma warning restore AA0100
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = Rec."Currency Code";
                    AutoFormatType = 1;
                    Caption = 'Inv. Discount Amount';
                    Editable = false;
                    ToolTip = 'Specifies the invoice discount amount for the sales document.';
                }
                field("TotalAmount1[3]"; TotalAmount1[3])
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = Rec."Currency Code";
                    AutoFormatType = 1;
                    CaptionClass = GetCaptionClass(Text001, false);
                    Editable = false;
                }
                field("VATAmount[3]"; VATAmount[3])
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = Rec."Currency Code";
                    AutoFormatType = 1;
                    CaptionClass = Format(VATAmountText[3]);
                    Editable = false;
                }
                field("TotalAmount2[3]"; TotalAmount2[3])
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = Rec."Currency Code";
                    AutoFormatType = 1;
                    CaptionClass = GetCaptionClass(Text001, true);
                    Editable = false;
                }
                field("TotalSalesLineLCY[3].Amount"; TotalSalesLineLCY[3].Amount)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    Caption = 'Sales (LCY)';
                    Editable = false;
                    ToolTip = 'Specifies your total sales turnover in the fiscal year. It is calculated from amounts excluding VAT on all completed and open sales invoices and credit memos.';
                }
#pragma warning disable AA0100
                field("TotalSalesLineLCY[3].""Unit Cost (LCY)"""; TotalSalesLineLCY[3]."Unit Cost (LCY)")
#pragma warning restore AA0100
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    Caption = 'Cost (LCY)';
                    Editable = false;
                    Importance = Additional;
                    ToolTip = 'Specifies the total cost of the sales order.';
                }
                field("ProfitLCY[3]"; ProfitLCY[3])
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    Caption = 'Profit (LCY)';
                    Editable = false;
                    Importance = Additional;
                    ToolTip = 'Specifies the total profit of the sales order.';
                }
                field("ProfitPct[3]"; ProfitPct[3])
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Profit %';
                    DecimalPlaces = 1 : 1;
                    Editable = false;
                    Importance = Additional;
                    ToolTip = 'Specifies the total profit of the sales order expressed as a percentage of the total amount.';
                }
                field("TotalSalesLine[3].Quantity"; TotalSalesLine[3].Quantity)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Quantity';
                    DecimalPlaces = 0 : 5;
                    Editable = false;
                    Importance = Additional;
                    ToolTip = 'Specifies the total quantity of G/L account entries, items, and/or resources in the sales document. If the amount is rounded, because the Invoice Rounding check box is selected in the Sales & Receivables Setup window, this field will contain the quantity of items in the sales document plus one.';
                }
#pragma warning disable AA0100
                field("TotalSalesLine[3].""Units per Parcel"""; TotalSalesLine[3]."Units per Parcel")
#pragma warning restore AA0100
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Parcels';
                    DecimalPlaces = 0 : 5;
                    Editable = false;
                    Importance = Additional;
                    ToolTip = 'Specifies the total number of parcels in the sales document.';
                }
#pragma warning disable AA0100
                field("TotalSalesLine[3].""Net Weight"""; TotalSalesLine[3]."Net Weight")
#pragma warning restore AA0100
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Net Weight';
                    DecimalPlaces = 0 : 5;
                    Editable = false;
                    Importance = Additional;
                    ToolTip = 'Specifies the total net weight of the items in the sales document.';
                }
#pragma warning disable AA0100
                field("TotalSalesLine[3].""Gross Weight"""; TotalSalesLine[3]."Gross Weight")
#pragma warning restore AA0100
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Gross Weight';
                    DecimalPlaces = 0 : 5;
                    Editable = false;
                    Importance = Additional;
                    ToolTip = 'Specifies the total gross weight of the items in the sales document.';
                }
#pragma warning disable AA0100
                field("TotalSalesLine[3].""Unit Volume"""; TotalSalesLine[3]."Unit Volume")
#pragma warning restore AA0100
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Volume';
                    DecimalPlaces = 0 : 5;
                    Editable = false;
                    Importance = Additional;
                    ToolTip = 'Specifies the total volume of the items in the sales document.';
                }
                field("TempVATAmountLine3.COUNT"; TempVATAmountLine3.Count)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'No. of Tax Lines';
                    DrillDown = true;
                    Importance = Additional;
                    ToolTip = 'Specifies the number of lines on the sales order that have VAT amounts.';

                    trigger OnDrillDown()
                    begin
                        VATLinesDrillDown(TempVATAmountLine3, false);
                    end;
                }
            }
            group(Prepayment)
            {
                Caption = 'Prepayment';
                field(PrepmtTotalAmount; PrepmtTotalAmount)
                {
                    ApplicationArea = Prepayments;
                    AutoFormatExpression = Rec."Currency Code";
                    AutoFormatType = 1;
                    CaptionClass = GetCaptionClass(Text006, false);
                    Editable = DynamicEditable;

                    trigger OnValidate()
                    begin
                        ActiveTab := ActiveTab::Prepayment;
                        UpdatePrepmtAmount();
                    end;
                }
                field(PrepmtVATAmount; PrepmtVATAmount)
                {
                    ApplicationArea = Prepayments;
                    AutoFormatExpression = Rec."Currency Code";
                    AutoFormatType = 1;
                    CaptionClass = Format(PrepmtVATAmountText);
                    Caption = 'Prepayment Amount Invoiced';
                    Editable = false;
                    ToolTip = 'Specifies how much has been invoiced as prepayment.';
                }
                field(PrepmtTotalAmount2; PrepmtTotalAmount2)
                {
                    ApplicationArea = Prepayments;
                    AutoFormatExpression = Rec."Currency Code";
                    AutoFormatType = 1;
                    CaptionClass = GetCaptionClass(Text006, true);
                    Editable = false;

                    trigger OnValidate()
                    begin
                        OnBeforeValidatePrepmtTotalAmount2(Rec, PrepmtTotalAmount, PrepmtTotalAmount2);
                        UpdatePrepmtAmount();
                    end;
                }
#pragma warning disable AA0100
                field("TotalSalesLine[1].""Prepmt. Amt. Inv."""; TotalSalesLine[1]."Prepmt. Amt. Inv.")
#pragma warning restore AA0100
                {
                    ApplicationArea = Prepayments;
                    AutoFormatExpression = Rec."Currency Code";
                    AutoFormatType = 1;
                    CaptionClass = GetCaptionClass(Text007, false);
                    Editable = false;
                }
                field(PrepmtInvPct; PrepmtInvPct)
                {
                    ApplicationArea = Prepayments;
                    Caption = 'Invoiced % of Prepayment Amt.';
                    ExtendedDatatype = Ratio;
                    ToolTip = 'Specifies Invoiced Percentage of Prepayment Amt.';
                }
#pragma warning disable AA0100
                field("TotalSalesLine[1].""Prepmt Amt Deducted"""; TotalSalesLine[1]."Prepmt Amt Deducted")
#pragma warning restore AA0100
                {
                    ApplicationArea = Prepayments;
                    AutoFormatExpression = Rec."Currency Code";
                    AutoFormatType = 1;
                    CaptionClass = GetCaptionClass(Text008, false);
                    Editable = false;
                }
                field(PrepmtDeductedPct; PrepmtDeductedPct)
                {
                    ApplicationArea = Prepayments;
                    Caption = 'Deducted % of Prepayment Amt. to Deduct';
                    ExtendedDatatype = Ratio;
                    ToolTip = 'Specifies the deducted percentage of the prepayment amount to deduct.';
                }
#pragma warning disable AA0100
                field("TotalSalesLine[1].""Prepmt Amt to Deduct"""; TotalSalesLine[1]."Prepmt Amt to Deduct")
#pragma warning restore AA0100
                {
                    ApplicationArea = Prepayments;
                    AutoFormatExpression = Rec."Currency Code";
                    AutoFormatType = 1;
                    CaptionClass = GetCaptionClass(Text009, false);
                    Editable = false;
                }
                field("TempVATAmountLine4.COUNT"; TempVATAmountLine4.Count)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'No. of Tax Lines';
                    DrillDown = true;
                    ToolTip = 'Specifies the number of lines on the sales order that have VAT amounts.';

                    trigger OnDrillDown()
                    begin
                        VATLinesDrillDown(TempVATAmountLine4, true);
                    end;
                }
            }
            group(Customer)
            {
                Caption = 'Customer';
#pragma warning disable AA0100
                field("Cust.""Balance (LCY)"""; Cust."Balance (LCY)")
#pragma warning restore AA0100
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    Caption = 'Balance (LCY)';
                    Editable = false;
                    ToolTip = 'Specifies the balance on the customer''s account.';
                }
#pragma warning disable AA0100
                field("Cust.""Credit Limit (LCY)"""; Cust."Credit Limit (LCY)")
#pragma warning restore AA0100
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    Caption = 'Credit Limit (LCY)';
                    Editable = false;
                    ToolTip = 'Specifies the credit limit of the customer on the sales document. The value 0 represents unlimited credit.';
                }
                field(CreditLimitLCYExpendedPct; CreditLimitLCYExpendedPct)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Expended % of Credit Limit (LCY)';
                    ExtendedDatatype = Ratio;
                    ToolTip = 'Specifies the expended percentage of the credit limit in (LCY).';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetCurrRecord()
    begin
        DynamicEditable := CurrPage.Editable;
    end;

    trigger OnAfterGetRecord()
    begin
        RefreshOnAfterGetRecord();
    end;

    trigger OnOpenPage()
    begin
#if not CLEAN26
        if not Rec.SkipStatisticsPreparation() then
            Rec.PrepareOpeningDocumentStatistics();
        Rec.ResetSkipStatisticsPreparationFlag();
#else
        Rec.PrepareOpeningDocumentStatistics();
#endif
        SalesSetup.Get();
        AllowInvDisc := not (SalesSetup."Calc. Inv. Discount" and CustInvDiscRecExists(Rec."Invoice Disc. Code"));
        AllowVATDifference :=
          SalesSetup."Allow VAT Difference" and
          not (Rec."Document Type" in [Rec."Document Type"::Quote, Rec."Document Type"::"Blanket Order"]);
        OnOpenPageOnBeforeSetEditable(AllowInvDisc, AllowVATDifference, Rec);
        VATLinesFormIsEditable := AllowVATDifference or AllowInvDisc;
        CurrPage.Editable := VATLinesFormIsEditable;
    end;

    trigger OnClosePage()
    var
        SalesCalcDiscountByType: Codeunit "Sales - Calc Discount By Type";
    begin
        SalesCalcDiscountByType.ResetRecalculateInvoiceDisc(Rec);
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        SalesLine: Record "Sales Line";
        ReleaseSalesDocument: Codeunit "Release Sales Document";
    begin
        GetVATSpecification(PrevTab);
        ReleaseSalesDocument.CalcAndUpdateVATOnLines(Rec, SalesLine);
        exit(true);
    end;

    var
        Cust: Record Customer;
        TempVATAmountLine1: Record "VAT Amount Line" temporary;
        TempVATAmountLine2: Record "VAT Amount Line" temporary;
        TempVATAmountLine3: Record "VAT Amount Line" temporary;
        TempVATAmountLine4: Record "VAT Amount Line" temporary;
        SalesSetup: Record "Sales & Receivables Setup";
        VATLinesForm: Page "VAT Amount Lines";
        VATAmountText: array[3] of Text[30];
        PrepmtVATAmountText: Text[30];
        CreditLimitLCYExpendedPct: Decimal;
        PrepmtInvPct: Decimal;
        PrepmtDeductedPct: Decimal;
        i: Integer;
        PrevNo: Code[20];
        ActiveTab: Option General,Invoicing,Shipping,Prepayment;
        PrevTab: Option General,Invoicing,Shipping,Prepayment;
        AllowInvDisc: Boolean;
        AllowVATDifference: Boolean;

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'Sales %1 Statistics';
#pragma warning restore AA0470
        Text001: Label 'Total';
        Text002: Label 'Amount';
#pragma warning disable AA0470
        Text003: Label '%1 must not be 0.';
        Text004: Label '%1 must not be greater than %2.';
        Text005: Label 'You cannot change the invoice discount because a customer invoice discount with the code %1 exists.';
#pragma warning restore AA0470
        Text006: Label 'Prepmt. Amount';
        Text007: Label 'Prepmt. Amt. Invoiced';
        Text008: Label 'Prepmt. Amt. Deducted';
        Text009: Label 'Prepmt. Amt. to Deduct';
#pragma warning restore AA0074
        UpdateInvDiscountQst: Label 'One or more lines have been invoiced. The discount distributed to invoiced lines will not be taken into account.\\Do you want to update the invoice discount?';

    protected var
        TotalSalesLine: array[3] of Record "Sales Line";
        TotalSalesLineLCY: array[3] of Record "Sales Line";
        SalesPost: Codeunit "Sales-Post";
        TotalAmount1: array[3] of Decimal;
        TotalAmount2: array[3] of Decimal;
        VATAmount: array[3] of Decimal;
        ProfitLCY: array[3] of Decimal;
        ProfitPct: array[3] of Decimal;
        AdjProfitLCY: array[3] of Decimal;
        AdjProfitPct: array[3] of Decimal;
        TotalAdjCostLCY: array[3] of Decimal;
        PrepmtTotalAmount: Decimal;
        PrepmtTotalAmount2: Decimal;
        PrepmtVATAmount: Decimal;
        DynamicEditable: Boolean;
        VATLinesFormIsEditable: Boolean;

    local procedure RefreshOnAfterGetRecord()
    var
        SalesLine: Record "Sales Line";
        TempSalesLine: Record "Sales Line" temporary;
        SalesPostPrepayments: Codeunit "Sales-Post Prepayments";
        OptionValueOutOfRange: Integer;
    begin
        CurrPage.Caption(StrSubstNo(Text000, Rec."Document Type"));

        if PrevNo = Rec."No." then
            exit;
        PrevNo := Rec."No.";
        Rec.FilterGroup(2);
        Rec.SetRange("No.", PrevNo);
        Rec.FilterGroup(0);

        Clear(SalesLine);
        Clear(TotalSalesLine);
        Clear(TotalSalesLineLCY);
        Clear(TotalAmount1);
        Clear(TotalAmount2);
        Clear(VATAmount);
        Clear(ProfitLCY);
        Clear(ProfitPct);
        Clear(AdjProfitLCY);
        Clear(AdjProfitPct);
        Clear(TotalAdjCostLCY);
        Clear(TempVATAmountLine1);
        Clear(TempVATAmountLine2);
        Clear(TempVATAmountLine3);
        Clear(TempVATAmountLine4);
        Clear(PrepmtTotalAmount);
        Clear(PrepmtVATAmount);
        Clear(PrepmtTotalAmount2);
        Clear(VATAmountText);
        Clear(PrepmtVATAmountText);
        Clear(CreditLimitLCYExpendedPct);
        Clear(PrepmtInvPct);
        Clear(PrepmtDeductedPct);

        // 1 to 3, so that it does calculations for all 3 tabs, General,Invoicing,Shipping
        for i := 1 to 3 do begin
            OnRefreshOnAfterGetRecordOnBeforeTempSalesLineDeleteAll(Rec, TempSalesLine);
            TempSalesLine.DeleteAll();
            Clear(TempSalesLine);
            Clear(SalesPost);
            SalesPost.GetSalesLines(Rec, TempSalesLine, i - 1, false);
            OnRefreshOnAfterGetRecordOnAfterGetSalesLines(Rec, TempSalesLine);
            Clear(SalesPost);
            case i of
                1:
                    SalesLine.CalcVATAmountLines(0, Rec, TempSalesLine, TempVATAmountLine1);
                2:
                    SalesLine.CalcVATAmountLines(0, Rec, TempSalesLine, TempVATAmountLine2);
                3:
                    SalesLine.CalcVATAmountLines(0, Rec, TempSalesLine, TempVATAmountLine3);
            end;

            SalesPost.SumSalesLinesTemp(
              Rec, TempSalesLine, i - 1, TotalSalesLine[i], TotalSalesLineLCY[i],
              VATAmount[i], VATAmountText[i], ProfitLCY[i], ProfitPct[i], TotalAdjCostLCY[i], false);

            if i = 3 then
                TotalAdjCostLCY[i] := TotalSalesLineLCY[i]."Unit Cost (LCY)";

            AdjProfitLCY[i] := TotalSalesLineLCY[i].Amount - TotalAdjCostLCY[i];
            if TotalSalesLineLCY[i].Amount <> 0 then
                AdjProfitPct[i] := Round(AdjProfitLCY[i] / TotalSalesLineLCY[i].Amount * 100, 0.1);

            if Rec."Prices Including VAT" then begin
                TotalAmount2[i] := TotalSalesLine[i].Amount;
                TotalAmount1[i] := TotalAmount2[i] + VATAmount[i];
                TotalSalesLine[i]."Line Amount" := TotalAmount1[i] + TotalSalesLine[i]."Inv. Discount Amount";
            end else begin
                TotalAmount1[i] := TotalSalesLine[i].Amount;
                TotalAmount2[i] := TotalSalesLine[i]."Amount Including VAT";
            end;
            OnRefreshOnAfterGetRecordOnAfterSetTotalAmounts(TotalAmount1, TotalAmount2, TotalSalesLine);
        end;

        OnAfterCalculateTotalAmounts(TempSalesLine, TempVATAmountLine1);

        TempSalesLine.DeleteAll();
        Clear(TempSalesLine);
        SalesPostPrepayments.GetSalesLines(Rec, 0, TempSalesLine);
        SalesPostPrepayments.SumPrepmt(
          Rec, TempSalesLine, TempVATAmountLine4, PrepmtTotalAmount, PrepmtVATAmount, PrepmtVATAmountText);
        PrepmtInvPct :=
          Pct(TotalSalesLine[1]."Prepmt. Amt. Inv.", PrepmtTotalAmount);
        PrepmtDeductedPct :=
          Pct(TotalSalesLine[1]."Prepmt Amt Deducted", TotalSalesLine[1]."Prepmt. Amt. Inv.");
        if Rec."Prices Including VAT" then begin
            PrepmtTotalAmount2 := PrepmtTotalAmount;
            PrepmtTotalAmount := PrepmtTotalAmount + PrepmtVATAmount;
        end else
            PrepmtTotalAmount2 := PrepmtTotalAmount + PrepmtVATAmount;

        if Cust.Get(Rec."Bill-to Customer No.") then
            Cust.CalcFields("Balance (LCY)")
        else
            Clear(Cust);

        OnRefreshOnAfterGetRecordOnBeforeSetCreditLimitLCYExpendedPct(Cust, Rec);

        case true of
            Cust."Credit Limit (LCY)" = 0:
                CreditLimitLCYExpendedPct := 0;
            Cust."Balance (LCY)" / Cust."Credit Limit (LCY)" < 0:
                CreditLimitLCYExpendedPct := 0;
            Cust."Balance (LCY)" / Cust."Credit Limit (LCY)" > 1:
                CreditLimitLCYExpendedPct := 10000;
            else
                CreditLimitLCYExpendedPct := Round(Cust."Balance (LCY)" / Cust."Credit Limit (LCY)" * 10000, 1);
        end;

        TempVATAmountLine1.ModifyAll(Modified, false);
        TempVATAmountLine2.ModifyAll(Modified, false);
        TempVATAmountLine3.ModifyAll(Modified, false);
        TempVATAmountLine4.ModifyAll(Modified, false);

        OptionValueOutOfRange := -1;
        PrevTab := OptionValueOutOfRange;

        UpdateHeaderInfo(2, TempVATAmountLine2);
    end;

    procedure UpdateHeaderInfo(IndexNo: Integer; var VATAmountLine: Record "VAT Amount Line")
    var
        CurrExchRate: Record "Currency Exchange Rate";
        UseDate: Date;
        IsHandled: Boolean;
    begin
        TotalSalesLine[IndexNo]."Inv. Discount Amount" := VATAmountLine.GetTotalInvDiscAmount();
        TotalAmount1[IndexNo] := TotalSalesLine[IndexNo]."Line Amount" - TotalSalesLine[IndexNo]."Inv. Discount Amount";
        OnUpdateHeaderInfoOnAfterSetTotalAmount(IndexNo, TotalAmount1, TotalSalesLine);
        VATAmount[IndexNo] := VATAmountLine.GetTotalVATAmount();
        if Rec."Prices Including VAT" then begin
            TotalAmount1[IndexNo] := VATAmountLine.GetTotalAmountInclVAT();
            TotalAmount2[IndexNo] := TotalAmount1[IndexNo] - VATAmount[IndexNo];
            IsHandled := false;
            OnUpdateHeaderInfoOnBeforeSetLineAmount(TotalSalesLine, TotalAmount1, IndexNo, IsHandled);
            if not IsHandled then
                TotalSalesLine[IndexNo]."Line Amount" :=
                  TotalAmount1[IndexNo] + TotalSalesLine[IndexNo]."Inv. Discount Amount";
        end else
            TotalAmount2[IndexNo] := TotalAmount1[IndexNo] + VATAmount[IndexNo];

        OnUpdateHeaderInfoOnBeforeSetAmount(IndexNo);
        if Rec."Prices Including VAT" then
            TotalSalesLineLCY[IndexNo].Amount := TotalAmount2[IndexNo]
        else
            TotalSalesLineLCY[IndexNo].Amount := TotalAmount1[IndexNo];
        if Rec."Currency Code" <> '' then
            if Rec."Posting Date" = 0D then
                UseDate := WorkDate()
            else
                UseDate := Rec."Posting Date";

        TotalSalesLineLCY[IndexNo].Amount :=
          CurrExchRate.ExchangeAmtFCYToLCY(
            UseDate, Rec."Currency Code", TotalSalesLineLCY[IndexNo].Amount, Rec."Currency Factor");

        ProfitLCY[IndexNo] := TotalSalesLineLCY[IndexNo].Amount - TotalSalesLineLCY[IndexNo]."Unit Cost (LCY)";
        if TotalSalesLineLCY[IndexNo].Amount = 0 then
            ProfitPct[IndexNo] := 0
        else
            ProfitPct[IndexNo] := Round(100 * ProfitLCY[IndexNo] / TotalSalesLineLCY[IndexNo].Amount, 0.01);

        AdjProfitLCY[IndexNo] := TotalSalesLineLCY[IndexNo].Amount - TotalAdjCostLCY[IndexNo];
        if TotalSalesLineLCY[IndexNo].Amount = 0 then
            AdjProfitPct[IndexNo] := 0
        else
            AdjProfitPct[IndexNo] := Round(100 * AdjProfitLCY[IndexNo] / TotalSalesLineLCY[IndexNo].Amount, 0.01);

        OnAfterUpdateHeaderInfo(TotalSalesLineLCY, IndexNo);
    end;

    local procedure GetVATSpecification(QtyType: Option General,Invoicing,Shipping)
    begin
        case QtyType of
            QtyType::General:
                begin
                    VATLinesForm.GetTempVATAmountLine(TempVATAmountLine1);
                    UpdateHeaderInfo(1, TempVATAmountLine1);
                end;
            QtyType::Invoicing:
                begin
                    VATLinesForm.GetTempVATAmountLine(TempVATAmountLine2);
                    UpdateHeaderInfo(2, TempVATAmountLine2);
                end;
            QtyType::Shipping:
                VATLinesForm.GetTempVATAmountLine(TempVATAmountLine3);
        end;
    end;

    protected procedure UpdateTotalAmount(IndexNo: Integer)
    var
        SaveTotalAmount: Decimal;
    begin
        CheckAllowInvDisc();
        if Rec."Prices Including VAT" then begin
            SaveTotalAmount := TotalAmount1[IndexNo];
            UpdateInvDiscAmount(IndexNo);
            TotalAmount1[IndexNo] := SaveTotalAmount;
        end;

        TotalSalesLine[IndexNo]."Inv. Discount Amount" := TotalSalesLine[IndexNo]."Line Amount" - TotalAmount1[IndexNo];
        UpdateInvDiscAmount(IndexNo);
    end;

    protected procedure UpdateInvDiscAmount(ModifiedIndexNo: Integer)
    var
        ConfirmManagement: Codeunit "Confirm Management";
        PartialInvoicing: Boolean;
        MaxIndexNo: Integer;
        IndexNo: array[2] of Integer;
        i: Integer;
        InvDiscBaseAmount: Decimal;
    begin
        if Rec.Status = Rec.Status::"Pending Approval" then
            Rec.FieldError(Rec.Status);
        CheckAllowInvDisc();
        if not (ModifiedIndexNo in [1, 2]) then
            exit;

        if Rec.InvoicedLineExists() then
            if not ConfirmManagement.GetResponseOrDefault(UpdateInvDiscountQst, true) then
                Error('');

        if ModifiedIndexNo = 1 then
            InvDiscBaseAmount := TempVATAmountLine1.GetTotalInvDiscBaseAmount(false, Rec."Currency Code")
        else
            InvDiscBaseAmount := TempVATAmountLine2.GetTotalInvDiscBaseAmount(false, Rec."Currency Code");

        if InvDiscBaseAmount = 0 then
            Error(Text003, TempVATAmountLine2.FieldCaption("Inv. Disc. Base Amount"));

        if TotalSalesLine[ModifiedIndexNo]."Inv. Discount Amount" / InvDiscBaseAmount > 1 then
            Error(
              Text004,
              TotalSalesLine[ModifiedIndexNo].FieldCaption("Inv. Discount Amount"),
              TempVATAmountLine2.FieldCaption("Inv. Disc. Base Amount"));

        PartialInvoicing := (TotalSalesLine[1]."Line Amount" <> TotalSalesLine[2]."Line Amount");

        IndexNo[1] := ModifiedIndexNo;
        IndexNo[2] := 3 - ModifiedIndexNo;
        if (ModifiedIndexNo = 2) and PartialInvoicing then
            MaxIndexNo := 1
        else
            MaxIndexNo := 2;

        if not PartialInvoicing then
            if ModifiedIndexNo = 1 then
                TotalSalesLine[2]."Inv. Discount Amount" := TotalSalesLine[1]."Inv. Discount Amount"
            else
                TotalSalesLine[1]."Inv. Discount Amount" := TotalSalesLine[2]."Inv. Discount Amount";

        for i := 1 to MaxIndexNo do begin
            if (i = 1) or not PartialInvoicing then
                if IndexNo[i] = 1 then
                    TempVATAmountLine1.SetInvoiceDiscountAmount(
                      TotalSalesLine[IndexNo[i]]."Inv. Discount Amount", TotalSalesLine[IndexNo[i]]."Currency Code", Rec."Prices Including VAT", Rec."VAT Base Discount %")
                else
                    TempVATAmountLine2.SetInvoiceDiscountAmount(
                      TotalSalesLine[IndexNo[i]]."Inv. Discount Amount", TotalSalesLine[IndexNo[i]]."Currency Code", Rec."Prices Including VAT", Rec."VAT Base Discount %");

            if (i = 2) and PartialInvoicing then
                if IndexNo[i] = 1 then begin
                    InvDiscBaseAmount := TempVATAmountLine2.GetTotalInvDiscBaseAmount(false, TotalSalesLine[IndexNo[i]]."Currency Code");
                    if InvDiscBaseAmount = 0 then
                        TempVATAmountLine1.SetInvoiceDiscountPercent(
                          0, TotalSalesLine[IndexNo[i]]."Currency Code", Rec."Prices Including VAT", false, Rec."VAT Base Discount %")
                    else
                        TempVATAmountLine1.SetInvoiceDiscountPercent(
                          100 * TempVATAmountLine2.GetTotalInvDiscAmount() / InvDiscBaseAmount,
                          TotalSalesLine[IndexNo[i]]."Currency Code", Rec."Prices Including VAT", false, Rec."VAT Base Discount %");
                end else begin
                    InvDiscBaseAmount := TempVATAmountLine1.GetTotalInvDiscBaseAmount(false, TotalSalesLine[IndexNo[i]]."Currency Code");
                    if InvDiscBaseAmount = 0 then
                        TempVATAmountLine2.SetInvoiceDiscountPercent(
                          0, TotalSalesLine[IndexNo[i]]."Currency Code", Rec."Prices Including VAT", false, Rec."VAT Base Discount %")
                    else
                        TempVATAmountLine2.SetInvoiceDiscountPercent(
                          100 * TempVATAmountLine1.GetTotalInvDiscAmount() / InvDiscBaseAmount,
                          TotalSalesLine[IndexNo[i]]."Currency Code", Rec."Prices Including VAT", false, Rec."VAT Base Discount %");
                end;
        end;

        UpdateHeaderInfo(1, TempVATAmountLine1);
        UpdateHeaderInfo(2, TempVATAmountLine2);

        if ModifiedIndexNo = 1 then
            VATLinesForm.SetTempVATAmountLine(TempVATAmountLine1)
        else
            VATLinesForm.SetTempVATAmountLine(TempVATAmountLine2);

        Rec."Invoice Discount Calculation" := Rec."Invoice Discount Calculation"::Amount;
        Rec."Invoice Discount Value" := TotalSalesLine[1]."Inv. Discount Amount";
        Rec.Modify();

        UpdateVATOnSalesLines();
    end;

    local procedure UpdatePrepmtAmount()
    var
        TempSalesLine: Record "Sales Line" temporary;
        SalesPostPrepmt: Codeunit "Sales-Post Prepayments";
    begin
        SalesPostPrepmt.UpdatePrepmtAmountOnSaleslines(Rec, PrepmtTotalAmount);
        SalesPostPrepmt.GetSalesLines(Rec, 0, TempSalesLine);
        SalesPostPrepmt.SumPrepmt(
          Rec, TempSalesLine, TempVATAmountLine4, PrepmtTotalAmount, PrepmtVATAmount, PrepmtVATAmountText);
        PrepmtInvPct :=
          Pct(TotalSalesLine[1]."Prepmt. Amt. Inv.", PrepmtTotalAmount);
        PrepmtDeductedPct :=
          Pct(TotalSalesLine[1]."Prepmt Amt Deducted", TotalSalesLine[1]."Prepmt. Amt. Inv.");
        if Rec."Prices Including VAT" then begin
            PrepmtTotalAmount2 := PrepmtTotalAmount;
            PrepmtTotalAmount := PrepmtTotalAmount + PrepmtVATAmount;
        end else
            PrepmtTotalAmount2 := PrepmtTotalAmount + PrepmtVATAmount;
        Rec.Modify();
    end;

    protected procedure GetCaptionClass(FieldCaption: Text[100]; ReverseCaption: Boolean): Text[80]
    begin
        if Rec."Prices Including VAT" xor ReverseCaption then
            exit('2,1,' + FieldCaption);
        exit('2,0,' + FieldCaption);
    end;

    local procedure UpdateVATOnSalesLines()
    var
        SalesLine: Record "Sales Line";
    begin
        GetVATSpecification(ActiveTab);
        if TempVATAmountLine1.GetAnyLineModified() then
            SalesLine.UpdateVATOnLines(0, Rec, SalesLine, TempVATAmountLine1);
        if TempVATAmountLine2.GetAnyLineModified() then
            SalesLine.UpdateVATOnLines(1, Rec, SalesLine, TempVATAmountLine2);
        PrevNo := '';
    end;

    local procedure CustInvDiscRecExists(InvDiscCode: Code[20]): Boolean
    var
        CustInvDisc: Record "Cust. Invoice Disc.";
    begin
        CustInvDisc.SetRange(Code, InvDiscCode);
        exit(CustInvDisc.FindFirst())
    end;

    local procedure CheckAllowInvDisc()
    begin
        if not AllowInvDisc then
            Error(Text005, Rec."Invoice Disc. Code");

        OnAfterCheckAllowInvDisc(Rec);
    end;

    local procedure Pct(Numerator: Decimal; Denominator: Decimal): Decimal
    begin
        if Denominator = 0 then
            exit(0);
        exit(Round(Numerator / Denominator * 10000, 1));
    end;

    protected procedure VATLinesDrillDown(var VATLinesToDrillDown: Record "VAT Amount Line"; ThisTabAllowsVATEditing: Boolean)
    begin
        Clear(VATLinesForm);
        VATLinesForm.SetTempVATAmountLine(VATLinesToDrillDown);
        VATLinesForm.InitGlobals(
          Rec."Currency Code", AllowVATDifference, AllowVATDifference and ThisTabAllowsVATEditing,
          Rec."Prices Including VAT", AllowInvDisc, Rec."VAT Base Discount %");
        VATLinesForm.RunModal();
        VATLinesForm.GetTempVATAmountLine(VATLinesToDrillDown);
    end;

    local procedure TotalAmount21OnAfterValidate()
    begin
        if Rec."Prices Including VAT" then
            TotalSalesLine[1]."Inv. Discount Amount" := TotalSalesLine[1]."Line Amount" - TotalSalesLine[1]."Amount Including VAT"
        else
            TotalSalesLine[1]."Inv. Discount Amount" := TotalSalesLine[1]."Line Amount" - TotalSalesLine[1].Amount;
        UpdateInvDiscAmount(1);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnOpenPageOnBeforeSetEditable(var AllowInvDisc: Boolean; var AllowVATDifference: Boolean; SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterCalculateTotalAmounts(var TempSalesLine: Record "Sales Line" temporary; var TempVATAmountLine1: Record "VAT Amount Line" temporary)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterUpdateHeaderInfo(var TotalSalesLineLCY: array[3] of Record "Sales Line"; var IndexNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidatePrepmtTotalAmount2(SalesHeader: Record "Sales Header"; var PrepmtTotalAmount: Decimal; var PrepmtTotalAmount2: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckAllowInvDisc(SalesHeader: Record "Sales Header");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRefreshOnAfterGetRecordOnAfterGetSalesLines(SalesHeader: Record "Sales Header"; var TempSalesLine: Record "Sales Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRefreshOnAfterGetRecordOnBeforeTempSalesLineDeleteAll(SalesHeader: Record "Sales Header"; var TempSalesLine: Record "Sales Line" temporary)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnUpdateHeaderInfoOnBeforeSetAmount(IndexNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRefreshOnAfterGetRecordOnAfterSetTotalAmounts(var TotalAmount1: array[3] of Decimal; var TotalAmount2: array[3] of Decimal; var TotalSalesLine: array[3] of Record "sales line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateHeaderInfoOnAfterSetTotalAmount(IndexNo: Integer; var TotalAmount1: array[3] of Decimal; var TotalSalesLine: array[3] of Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateHeaderInfoOnBeforeSetLineAmount(var TotalSalesLine: array[3] of Record "Sales Line"; var TotalAmount1: array[3] of Decimal; IndexNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnRefreshOnAfterGetRecordOnBeforeSetCreditLimitLCYExpendedPct(var Customer: Record Customer; var SalesHeader: Record "Sales Header")
    begin
    end;
}
