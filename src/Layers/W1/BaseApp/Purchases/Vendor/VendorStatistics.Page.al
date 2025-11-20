// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Vendor;

using Microsoft.Foundation.Period;
using Microsoft.Inventory.Item;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Payables;
using Microsoft.Purchase.Vendor;

page 152 "Vendor Statistics"
{
    Caption = 'Vendor Statistics';
    Editable = false;
    LinksAllowed = false;
    PageType = Card;
    SourceTable = Vendor;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(VendorSince; Rec."First Transaction Date")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                }
                field(DefaultVendorItemCount; CalculateDefaultSupplierItemCount())
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    Caption = 'Default Supplier for Items';
                    ToolTip = 'Specifies the number of items for which the vendor is the default supplier.';

                    trigger OnDrillDown()
                    var
                        Item: Record Item;
                    begin
                        Item.SetRange("Vendor No.", Rec."No.");
                        Item.SetRange(Blocked, false);
                        Item.SetRange("Purchasing Blocked", false);
                        Page.RunModal(0, Item);
                    end;
                }

                field("Balance (LCY)"; Rec."Balance (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the total value of your completed purchases from the vendor in the current fiscal year.';

                    trigger OnDrillDown()
                    var
                        VendLedgEntry: Record "Vendor Ledger Entry";
                        DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry";
                    begin
                        DtldVendLedgEntry.SetRange("Vendor No.", Rec."No.");
                        Rec.CopyFilter("Global Dimension 1 Filter", DtldVendLedgEntry."Initial Entry Global Dim. 1");
                        Rec.CopyFilter("Global Dimension 2 Filter", DtldVendLedgEntry."Initial Entry Global Dim. 2");
                        Rec.CopyFilter("Currency Filter", DtldVendLedgEntry."Currency Code");
                        VendLedgEntry.DrillDownOnEntries(DtldVendLedgEntry);
                    end;
                }
                group(Purchase)
                {
                    Caption = 'Purchase';
                    field("Outstanding Orders (LCY)"; Rec."Outstanding Orders (LCY)")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies the sum of outstanding orders (in LCY) to this vendor.';
                    }
                    field("Amt. Rcd. Not Invoiced (LCY)"; Rec."Amt. Rcd. Not Invoiced (LCY)")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Amt. Rcd. Not Invd. (LCY)';
                        ToolTip = 'Specifies the total invoice amount (in LCY) for the items you have received but not yet been invoiced for.';
                    }
                    field("Outstanding Invoices (LCY)"; Rec."Outstanding Invoices (LCY)")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies the sum of the vendor''s outstanding purchase invoices in LCY.';
                    }
                    field(DaysSinceLastPurchase; CalcDaysSinceLastPurchase())
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Days Since Last Purchase';
                        ToolTip = 'Specifies the number of days since the last purchase was made from the vendor.';

                        trigger OnDrillDown()
                        var
                            VendorLedgerEntry: Record "Vendor Ledger Entry";
                        begin
                            FilterVendorLedgerEntryToLastPurchase(VendorLedgerEntry);
                            Page.RunModal(0, VendorLedgerEntry);
                        end;
                    }
                }
                field(GetTotalAmountLCY; Rec.GetTotalAmountLCY())
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    Caption = 'Total (LCY)';
                    ToolTip = 'Specifies the payment amount that you owe the vendor for completed purchases plus purchases that are still ongoing.';
                }
                field("Balance Due (LCY)"; Rec.CalcOverDueBalance())
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = Format(StrSubstNo(OverdueAmountsLCYTxt, Format(CurrentDate)));
                    ToolTip = 'Specifies the total amount (in LCY) that you owe the vendor for overdue invoices.';

                    trigger OnDrillDown()
                    var
                        VendLedgEntry: Record "Vendor Ledger Entry";
                        DtldVendLedgEntry: Record "Detailed Vendor Ledg. Entry";
                    begin
                        DtldVendLedgEntry.SetFilter("Vendor No.", Rec."No.");
                        Rec.CopyFilter("Global Dimension 1 Filter", DtldVendLedgEntry."Initial Entry Global Dim. 1");
                        Rec.CopyFilter("Global Dimension 2 Filter", DtldVendLedgEntry."Initial Entry Global Dim. 2");
                        Rec.CopyFilter("Currency Filter", DtldVendLedgEntry."Currency Code");
                        VendLedgEntry.DrillDownOnOverdueEntries(DtldVendLedgEntry);
                    end;
                }
                field(GetInvoicedPrepmtAmountLCY; Rec.GetInvoicedPrepmtAmountLCY())
                {
                    ApplicationArea = Prepayments;
                    Caption = 'Invoiced Prepayment Amount (LCY)';
                    ToolTip = 'Specifies your payments to the vendor based on invoiced prepayments.';
                }
            }
            group(Purchases)
            {
                Caption = 'Purchases';
                fixed(Control1904230801)
                {
                    ShowCaption = false;
                    group("This Period")
                    {
                        Caption = 'This Fiscal Period';
                        field("VendDateName[1]"; VendDateName[1])
                        {
                            ApplicationArea = Basic, Suite;
                            ShowCaption = false;
                        }
                        field("VendPurchLCY[1]"; VendPurchLCY[1])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            Caption = 'Purchase (LCY)';
                            ToolTip = 'Specifies your total purchases.';
                        }
                        field("VendInvDiscAmountLCY[1]"; VendInvDiscAmountLCY[1])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            Caption = 'Inv. Discount (LCY)';
                            ToolTip = 'specifies the sum of invoice discounts that the vendor has granted to you.';
                        }
                        field("InvAmountsLCY[1]"; InvAmountsLCY[1])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            Caption = 'Inv. Amounts (LCY)';
                            ToolTip = 'Specifies the sum of amounts that have been invoiced to the vendor.';
                        }
                        field("VendReminderChargeAmtLCY[1]"; VendReminderChargeAmtLCY[1])
                        {
                            ApplicationArea = Suite;
                            AutoFormatType = 1;
                            Caption = 'Reminder Amounts (LCY)';
                            ToolTip = 'Specifies the sum of amounts the vendor has reminded you of.';
                        }
                        field("VendFinChargeAmtLCY[1]"; VendFinChargeAmtLCY[1])
                        {
                            ApplicationArea = Suite;
                            AutoFormatType = 1;
                            Caption = 'Fin. Charges (LCY)';
                            ToolTip = 'Specifies the sum of amounts that the vendor has charged on finance charge memos.';
                        }
                        field("VendCrMemoAmountsLCY[1]"; VendCrMemoAmountsLCY[1])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            Caption = 'Cr. Memo Amounts (LCY)';
                            ToolTip = 'Specifies the sum of amounts that the vendor has refunded you.';
                        }
                        field("VendPaymentsLCY[1]"; VendPaymentsLCY[1])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            Caption = 'Payments (LCY)';
                            ToolTip = 'Specifies the sum of payments made to the vendor in the current fiscal year.';
                        }
                        field("VendRefundsLCY[1]"; VendRefundsLCY[1])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            Caption = 'Refunds (LCY)';
                            ToolTip = 'Specifies the sum of refunds received from the vendor.';
                        }
                        field("VendOtherAmountsLCY[1]"; VendOtherAmountsLCY[1])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            Caption = 'Other Amounts (LCY)';
                            ToolTip = 'Specifies the sum of other amounts for the vendor';
                        }
                        field("VendPaymentDiscLCY[1]"; VendPaymentDiscLCY[1])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            Caption = 'Pmt. Discounts (LCY)';
                            ToolTip = 'Specifies the sum of payment discounts the vendor has granted to you.';
                        }
                        field("VendPaymentDiscTolLCY[1]"; VendPaymentDiscTolLCY[1])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            Caption = 'Pmt. Disc. Tol. (LCY)';
                            ToolTip = 'Specifies the sum of payment discount tolerance from the vendor.';
                        }
                        field("VendPaymentTolLCY[1]"; VendPaymentTolLCY[1])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            Caption = 'Pmt. Tolerances (LCY)';
                            ToolTip = 'Specifies the sum of payment tolerance from the vendor.';
                        }
                        field(NumberOfPurchaseDocs1; NumberOfPurchaseDocs[1])
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'No. of Purchase Docs.';
                            ToolTip = 'Specifies the number of purchase documents for the vendor.';
                        }
                        field(NumberOfDistinctItemsPurchased1; NumberOfDistinctItemsPurchased[1])
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'No. of Distinct Items Purchased';
                            ToolTip = 'Specifies the number of distinct items purchased from the vendor.';
                        }
                    }
                    group("This Year")
                    {
                        Caption = 'This Fiscal Year';
                        field(Text001; PlaceholderTxt)
                        {
                            ApplicationArea = Basic, Suite;
                            ShowCaption = false;
                            Visible = false;
                        }
                        field("VendPurchLCY[2]"; VendPurchLCY[2])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            Caption = 'Purchase (LCY)';
                            ToolTip = 'Specifies your total purchases.';
                        }
                        field("VendInvDiscAmountLCY[2]"; VendInvDiscAmountLCY[2])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            Caption = 'Inv. Discount (LCY)';
                            ToolTip = 'specifies the sum of invoice discounts that the vendor has granted to you.';
                        }
                        field("InvAmountsLCY[2]"; InvAmountsLCY[2])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            Caption = 'Inv. Amounts (LCY)';
                            ToolTip = 'Specifies the sum of amounts that have been invoiced to the vendor.';
                        }
                        field("VendReminderChargeAmtLCY[2]"; VendReminderChargeAmtLCY[2])
                        {
                            ApplicationArea = Suite;
                            AutoFormatType = 1;
                            Caption = 'Reminder Amounts (LCY)';
                            ToolTip = 'Specifies the sum of amounts the vendor has reminded you of.';
                        }
                        field("VendFinChargeAmtLCY[2]"; VendFinChargeAmtLCY[2])
                        {
                            ApplicationArea = Suite;
                            AutoFormatType = 1;
                            Caption = 'Fin. Charges (LCY)';
                            ToolTip = 'Specifies the sum of amounts that the vendor has charged on finance charge memos.';
                        }
                        field("VendCrMemoAmountsLCY[2]"; VendCrMemoAmountsLCY[2])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            Caption = 'Cr. Memo Amounts (LCY)';
                            ToolTip = 'Specifies the sum of amounts that the vendor has refunded you.';
                        }
                        field("VendPaymentsLCY[2]"; VendPaymentsLCY[2])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            Caption = 'Payments (LCY)';
                            ToolTip = 'Specifies the sum of payments made to the vendor in the current fiscal year.';
                        }
                        field("VendRefundsLCY[2]"; VendRefundsLCY[2])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            Caption = 'Refunds (LCY)';
                            ToolTip = 'Specifies the sum of refunds received from the vendor.';
                        }
                        field("VendOtherAmountsLCY[2]"; VendOtherAmountsLCY[2])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            Caption = 'Other Amounts (LCY)';
                            ToolTip = 'Specifies the sum of other amounts for the vendor';
                        }
                        field("VendPaymentDiscLCY[2]"; VendPaymentDiscLCY[2])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            Caption = 'Pmt. Discounts (LCY)';
                            ToolTip = 'Specifies the sum of payment discounts the vendor has granted to you.';
                        }
                        field("VendPaymentDiscTolLCY[2]"; VendPaymentDiscTolLCY[2])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            Caption = 'Pmt. Disc. Tol. (LCY)';
                            ToolTip = 'Specifies the sum of payment discount tolerance from the vendor.';
                        }
                        field("VendPaymentTolLCY[2]"; VendPaymentTolLCY[2])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            Caption = 'Pmt. Tolerances (LCY)';
                            ToolTip = 'Specifies the sum of payment tolerance from the vendor.';
                        }
                        field(NumberOfPurchaseDocs2; NumberOfPurchaseDocs[2])
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'No. of Purchase Docs.';
                            ToolTip = 'Specifies the number of purchase documents for the vendor.';
                        }
                        field(NumberOfDistinctItemsPurchased2; NumberOfDistinctItemsPurchased[2])
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'No. of Distinct Items Purchased';
                            ToolTip = 'Specifies the number of distinct items purchased from the vendor.';
                        }
                    }
                    group("Last Year")
                    {
                        Caption = 'Last Fiscal Year';
                        field(Control81; PlaceholderTxt)
                        {
                            ApplicationArea = Basic, Suite;
                            ShowCaption = false;
                            Visible = false;
                        }
                        field("VendPurchLCY[3]"; VendPurchLCY[3])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            Caption = 'Purchase (LCY)';
                            ToolTip = 'Specifies your total purchases.';
                        }
                        field("VendInvDiscAmountLCY[3]"; VendInvDiscAmountLCY[3])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            Caption = 'Inv. Discount (LCY)';
                            ToolTip = 'specifies the sum of invoice discounts that the vendor has granted to you.';
                        }
                        field("InvAmountsLCY[3]"; InvAmountsLCY[3])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            Caption = 'Inv. Amounts (LCY)';
                            ToolTip = 'Specifies the sum of amounts that have been invoiced to the vendor.';
                        }
                        field("VendReminderChargeAmtLCY[3]"; VendReminderChargeAmtLCY[3])
                        {
                            ApplicationArea = Suite;
                            AutoFormatType = 1;
                            Caption = 'Reminder Amounts (LCY)';
                            ToolTip = 'Specifies the sum of amounts the vendor has reminded you of.';
                        }
                        field("VendFinChargeAmtLCY[3]"; VendFinChargeAmtLCY[3])
                        {
                            ApplicationArea = Suite;
                            AutoFormatType = 1;
                            Caption = 'Fin. Charges (LCY)';
                            ToolTip = 'Specifies the sum of amounts that the vendor has charged on finance charge memos.';
                        }
                        field("VendCrMemoAmountsLCY[3]"; VendCrMemoAmountsLCY[3])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            Caption = 'Cr. Memo Amounts (LCY)';
                            ToolTip = 'Specifies the sum of amounts that the vendor has refunded you.';
                        }
                        field("VendPaymentsLCY[3]"; VendPaymentsLCY[3])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            Caption = 'Payments (LCY)';
                            ToolTip = 'Specifies the sum of payments made to the vendor in the current fiscal year.';
                        }
                        field("VendRefundsLCY[3]"; VendRefundsLCY[3])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            Caption = 'Refunds (LCY)';
                            ToolTip = 'Specifies the sum of refunds received from the vendor.';
                        }
                        field("VendOtherAmountsLCY[3]"; VendOtherAmountsLCY[3])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            Caption = 'Other Amounts (LCY)';
                            ToolTip = 'Specifies the sum of other amounts for the vendor';
                        }
                        field("VendPaymentDiscLCY[3]"; VendPaymentDiscLCY[3])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            Caption = 'Pmt. Discounts (LCY)';
                            ToolTip = 'Specifies the sum of payment discounts the vendor has granted to you.';
                        }
                        field("VendPaymentDiscTolLCY[3]"; VendPaymentDiscTolLCY[3])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            Caption = 'Pmt. Disc. Tol. (LCY)';
                            ToolTip = 'Specifies the sum of payment discount tolerance from the vendor.';
                        }
                        field("VendPaymentTolLCY[3]"; VendPaymentTolLCY[3])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            Caption = 'Pmt. Tolerances (LCY)';
                            ToolTip = 'Specifies the sum of payment tolerance from the vendor.';
                        }
                        field(NumberOfPurchaseDocs3; NumberOfPurchaseDocs[3])
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'No. of Purchase Docs.';
                            ToolTip = 'Specifies the number of purchase documents for the vendor.';
                        }
                        field(NumberOfDistinctItemsPurchased3; NumberOfDistinctItemsPurchased[3])
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'No. of Distinct Items Purchased';
                            ToolTip = 'Specifies the number of distinct items purchased from the vendor.';
                        }
                    }
                    group("To Date")
                    {
                        Caption = 'Lifetime (since)';
                        field(Control82; Rec."First Transaction Date")
                        {
                            ApplicationArea = Basic, Suite;
                            ShowCaption = false;
                        }
                        field("VendPurchLCY[4]"; VendPurchLCY[4])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            Caption = 'Purchase (LCY)';
                            ToolTip = 'Specifies your total purchases.';
                        }
                        field("VendInvDiscAmountLCY[4]"; VendInvDiscAmountLCY[4])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            Caption = 'Inv. Discount (LCY)';
                            ToolTip = 'specifies the sum of invoice discounts that the vendor has granted to you.';
                        }
                        field("InvAmountsLCY[4]"; InvAmountsLCY[4])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            Caption = 'Inv. Amounts (LCY)';
                            ToolTip = 'Specifies the sum of amounts that have been invoiced to the vendor.';
                        }
                        field("VendReminderChargeAmtLCY[4]"; VendReminderChargeAmtLCY[4])
                        {
                            ApplicationArea = Suite;
                            AutoFormatType = 1;
                            Caption = 'Reminder Amounts (LCY)';
                            ToolTip = 'Specifies the sum of amounts the vendor has reminded you of.';
                        }
                        field("VendFinChargeAmtLCY[4]"; VendFinChargeAmtLCY[4])
                        {
                            ApplicationArea = Suite;
                            AutoFormatType = 1;
                            Caption = 'Fin. Charges (LCY)';
                            ToolTip = 'Specifies the sum of amounts that the vendor has charged on finance charge memos.';
                        }
                        field("VendCrMemoAmountsLCY[4]"; VendCrMemoAmountsLCY[4])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            Caption = 'Cr. Memo Amounts (LCY)';
                            ToolTip = 'Specifies the sum of amounts that the vendor has refunded you.';
                        }
                        field("VendPaymentsLCY[4]"; VendPaymentsLCY[4])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            Caption = 'Payments (LCY)';
                            ToolTip = 'Specifies the sum of payments made to the vendor in the current fiscal year.';
                        }
                        field("VendRefundsLCY[4]"; VendRefundsLCY[4])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            Caption = 'Refunds (LCY)';
                            ToolTip = 'Specifies the sum of refunds received from the vendor.';
                        }
                        field("VendOtherAmountsLCY[4]"; VendOtherAmountsLCY[4])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            Caption = 'Other Amounts (LCY)';
                            ToolTip = 'Specifies the sum of other amounts for the vendor';
                        }
                        field("VendPaymentDiscLCY[4]"; VendPaymentDiscLCY[4])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            Caption = 'Pmt. Discounts (LCY)';
                            ToolTip = 'Specifies the sum of payment discounts the vendor has granted to you.';
                        }
                        field("VendPaymentDiscTolLCY[4]"; VendPaymentDiscTolLCY[4])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            Caption = 'Pmt. Disc. Tol. (LCY)';
                            ToolTip = 'Specifies the sum of payment discount tolerance from the vendor.';
                        }
                        field("VendPaymentTolLCY[4]"; VendPaymentTolLCY[4])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            Caption = 'Pmt. Tolerances (LCY)';
                            ToolTip = 'Specifies the sum of payment tolerance from the vendor.';
                        }
                        field(NumberOfPurchaseDocs4; NumberOfPurchaseDocs[4])
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'No. of Purchase Docs.';
                            ToolTip = 'Specifies the number of purchase documents for the vendor.';
                        }
                        field(NumberOfDistinctItemsPurchased4; NumberOfDistinctItemsPurchased[4])
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'No. of Distinct Items Purchased';
                            ToolTip = 'Specifies the number of distinct items purchased from the vendor.';
                        }
                    }
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        if CurrentDate <> WorkDate() then begin
            CurrentDate := WorkDate();
            DateFilterCalc.CreateAccountingPeriodFilter(VendDateFilter[1], VendDateName[1], CurrentDate, 0);
            DateFilterCalc.CreateFiscalYearFilter(VendDateFilter[2], VendDateName[2], CurrentDate, 0);
            DateFilterCalc.CreateFiscalYearFilter(VendDateFilter[3], VendDateName[3], CurrentDate, -1);
        end;

        SetDateFilter();

        for i := 1 to 4 do begin
            Rec.SetFilter("Date Filter", VendDateFilter[i]);
            Rec.CalcFields(
              "Purchases (LCY)", "Inv. Discounts (LCY)", "Inv. Amounts (LCY)", "Pmt. Discounts (LCY)",
              "Pmt. Disc. Tolerance (LCY)", "Pmt. Tolerance (LCY)",
              "Fin. Charge Memo Amounts (LCY)", "Cr. Memo Amounts (LCY)", "Payments (LCY)",
              "Reminder Amounts (LCY)", "Refunds (LCY)", "Other Amounts (LCY)");
            VendPurchLCY[i] := Rec."Purchases (LCY)";
            VendInvDiscAmountLCY[i] := Rec."Inv. Discounts (LCY)";
            InvAmountsLCY[i] := Rec."Inv. Amounts (LCY)";
            VendPaymentDiscLCY[i] := Rec."Pmt. Discounts (LCY)";
            VendPaymentDiscTolLCY[i] := Rec."Pmt. Disc. Tolerance (LCY)";
            VendPaymentTolLCY[i] := Rec."Pmt. Tolerance (LCY)";
            VendReminderChargeAmtLCY[i] := Rec."Reminder Amounts (LCY)";
            VendFinChargeAmtLCY[i] := Rec."Fin. Charge Memo Amounts (LCY)";
            VendCrMemoAmountsLCY[i] := Rec."Cr. Memo Amounts (LCY)";
            VendPaymentsLCY[i] := Rec."Payments (LCY)";
            VendRefundsLCY[i] := Rec."Refunds (LCY)";
            VendOtherAmountsLCY[i] := Rec."Other Amounts (LCY)";
            NumberOfPurchaseDocs[i] := CalcNumberOfPurchaseInvoices(VendDateFilter[i]);
            NumberOfDistinctItemsPurchased[i] := CalcNumberOfDistinctItemsPurchased(VendDateFilter[i]);
        end;
        Rec.SetRange("Date Filter", 0D, CurrentDate);
    end;

    var
        DateFilterCalc: Codeunit "DateFilter-Calc";
#pragma warning disable AA0470
        OverdueAmountsLCYTxt: Label 'Overdue Amounts (LCY) as of %1';
#pragma warning restore AA0470
        PlaceholderTxt: Label 'Placeholder';

    protected var
        VendDateFilter: array[4] of Text[30];
        VendDateName: array[4] of Text[30];
        CurrentDate: Date;
        VendPurchLCY: array[4] of Decimal;
        VendInvDiscAmountLCY: array[4] of Decimal;
        VendPaymentDiscLCY: array[4] of Decimal;
        VendPaymentDiscTolLCY: array[4] of Decimal;
        VendPaymentTolLCY: array[4] of Decimal;
        VendReminderChargeAmtLCY: array[4] of Decimal;
        VendFinChargeAmtLCY: array[4] of Decimal;
        VendCrMemoAmountsLCY: array[4] of Decimal;
        VendPaymentsLCY: array[4] of Decimal;
        VendRefundsLCY: array[4] of Decimal;
        VendOtherAmountsLCY: array[4] of Decimal;
        InvAmountsLCY: array[4] of Decimal;
        NumberOfPurchaseDocs: array[4] of Integer;
        NumberOfDistinctItemsPurchased: array[4] of Integer;
        i: Integer;

    local procedure SetDateFilter()
    begin
        Rec.SetRange("Date Filter", 0D, CurrentDate);

        OnAfterSetDateFilter(Rec);
    end;

    local procedure CalcDaysSinceLastPurchase(): Integer
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        VendorLedgerEntry.SetLoadFields("Posting Date");
        VendorLedgerEntry.SetCurrentKey("Posting Date");
        VendorLedgerEntry.SetRange("Vendor No.", Rec."No.");
        VendorLedgerEntry.SetFilter("Purchase (LCY)", '<%1', 0);
        VendorLedgerEntry.SetRange(Reversed, false);
        if VendorLedgerEntry.FindLast() then
            exit(CurrentDate - VendorLedgerEntry."Posting Date");
        exit(0);
    end;

    local procedure FilterVendorLedgerEntryToLastPurchase(var VendorLedgerEntry: Record "Vendor Ledger Entry"): Boolean
    begin
        VendorLedgerEntry.SetCurrentKey("Posting Date");
        VendorLedgerEntry.SetRange("Vendor No.", Rec."No.");
        VendorLedgerEntry.SetFilter("Purchase (LCY)", '<%1', 0);
        VendorLedgerEntry.SetRange(Reversed, false);
        if VendorLedgerEntry.FindLast() then begin
            VendorLedgerEntry.SetRecFilter();
            exit(true);
        end;
    end;

    local procedure CalcNumberOfPurchaseInvoices(DateFilter: Text): Integer
    var
        PurchInvHeader: Record "Purch. Inv. Header";
    begin
        PurchInvHeader.SetRange("Buy-From Vendor No.", Rec."No.");
        PurchInvHeader.SetFilter("Posting Date", DateFilter);
        exit(PurchInvHeader.Count());
    end;

    local procedure CalcNumberOfDistinctItemsPurchased(DateFilter: Text) Count: Integer
    var
        DistinctItemsPurchasedQuery: Query "Distinct Items Purchased";
    begin
        DistinctItemsPurchasedQuery.SetFilter(PostingDateFilter, DateFilter);
        DistinctItemsPurchasedQuery.SetRange(VendorNoFilter, Rec."No.");

        if DistinctItemsPurchasedQuery.Open() then
            while DistinctItemsPurchasedQuery.Read() do
                Count += 1;
    end;

    local procedure CalculateDefaultSupplierItemCount(): Integer
    var
        Item: Record Item;
    begin
        Item.ReadIsolation := IsolationLevel::ReadUncommitted;
        Item.SetRange("Vendor No.", Rec."No.");
        Item.SetRange(Blocked, false);
        Item.SetRange("Purchasing Blocked", false);
        exit(Item.Count());
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetDateFilter(var Vendor: Record Vendor)
    begin
    end;
}
