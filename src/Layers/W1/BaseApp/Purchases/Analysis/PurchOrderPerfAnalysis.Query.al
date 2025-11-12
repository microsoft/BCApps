// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Analysis;

using Microsoft.CRM.Team;
using Microsoft.Purchases.Document;

query 488 "Purch. Order Perf. Analysis"
{
    QueryType = Normal;
    DataAccessIntent = ReadOnly;
    UsageCategory = ReportsAndAnalysis;
    Caption = 'Purchase Order Performance Analysis';
    AboutTitle = 'About Purchase Order Performance Analysis';
    AboutText = 'The Purchase Order Performance Analysis is a query that joins data from purchase order lines with vendor master data.';

    elements
    {
        dataitem(PurchaseHeader; "Purchase Header")
        {
            DataItemTableFilter = "Document Type" = const(Order);
            column(DocumentNo; "No.")
            {
                Caption = 'No.';
            }
            column(Status; Status)
            {
                Caption = 'Status';
            }
            column(VendorOrderNo; "Vendor Order No.")
            {
                Caption = 'Vendor Order No.';
            }
            column(PurchaserCode; "Purchaser Code")
            {
                Caption = 'Purchaser Code';
            }
            column(OrderDate; "Order Date")
            {
                Caption = 'Order Date';
            }
            column(DueDate; "Due Date")
            {
                Caption = 'Due Date';
            }
            column(DocumentDate; "Document Date")
            {
                Caption = 'Document Date';
            }
            column(PostingDate; "Posting Date")
            {
                Caption = 'Posting Date';
            }
            column(BuyFromVendorNo; "Buy-from Vendor No.")
            {
                Caption = 'Buy-from Vendor No.';
            }
            column(BuyFromVendorName; "Buy-from Vendor Name")
            {
                Caption = 'Buy-from Vendor Name';
            }
            column(PayToVendorNo; "Pay-to Vendor No.")
            {
                Caption = 'Pay-to Vendor No.';
            }
            column(PayToVendorName; "Pay-to Name")
            {
                Caption = 'Pay-to Vendor Name';
            }
            dataitem(PurchaseLine; "Purchase Line")
            {
                DataItemLink = "Document Type" = PurchaseHeader."Document Type", "Document No." = PurchaseHeader."No.";
                SqlJoinType = InnerJoin;
                column(Type; Type)
                {
                    Caption = 'Type';
                }
                column(No; "No.")
                {
                    Caption = 'No.';
                }
                column(Description; Description)
                {
                    Caption = 'Description';
                }
                column(Quantity; Quantity)
                {
                    Caption = 'Quantity';
                }
                column(UnitOfMeasureCode; "Unit of Measure Code")
                {
                    Caption = 'Unit of Measure Code';
                }
                column(LocationCode; "Location Code")
                {
                    Caption = 'Location Code';
                }
                column(VariantCode; "Variant Code")
                {
                    Caption = 'Variant Code';
                }
                column(LineDiscountAmount; "Line Discount Amount")
                {
                    Caption = 'Line Discount Amount';
                }
                column(InvDiscountAmount; "Inv. Discount Amount")
                {
                    Caption = 'Inv. Discount Amount';
                }
                column(Amount; Amount)
                {
                    Caption = 'Amount';
                }
                column(AmountIncludingVAT; "Amount Including VAT")
                {
                    Caption = 'Amount Including VAT';
                }
                column(CurrencyCode; "Currency Code")
                {
                    Caption = 'Currency Code';
                }
                column(RequestedReceiptDate; "Requested Receipt Date")
                {
                    Caption = 'Requested Receipt Date';
                }
                column(PromisedReceiptDate; "Promised Receipt Date")
                {
                    Caption = 'Promised Receipt Date';
                }
                column(ExpectedReceiptDate; "Expected Receipt Date")
                {
                    Caption = 'Expected Receipt Date';
                }
                column(QuantityReceived; "Quantity Received")
                {
                    Caption = 'Quantity Received';
                }
                column(QuantityInvoiced; "Quantity Invoiced")
                {
                    Caption = 'Quantity Invoiced';
                }
                column(OutstandingQuantity; "Outstanding Quantity")
                {
                    Caption = 'Outstanding Quantity';
                }
                column(QtyRcdNotInvoiced; "Qty. Rcd. Not Invoiced")
                {
                    Caption = 'Qty. Rcd. Not Invoiced';
                }
                column(OutstandingQtyBase; "Outstanding Qty. (Base)")
                {
                    Caption = 'Outstanding Qty. (Base)';
                }
                column(QtyRcdNotInvoicedBase; "Qty. Rcd. Not Invoiced (Base)")
                {
                    Caption = 'Qty. Rcd. Not Invoiced (Base)';
                }
                column(OutstandingAmount; "Outstanding Amount")
                {
                    Caption = 'Outstanding Amount';
                }
                column(AmtRcdNotInvoiced; "Amt. Rcd. Not Invoiced")
                {
                    Caption = 'Amt. Rcd. Not Invoiced';
                }
                column(OutstandingAmountLCY; "Outstanding Amount (LCY)")
                {
                    Caption = 'Outstanding Amount (LCY)';
                }
                column(AmtRcdNotInvoicedLCY; "Amt. Rcd. Not Invoiced (LCY)")
                {
                    Caption = 'Amt. Rcd. Not Invoiced (LCY)';
                }
                column(ShortcutDimension1Code; "Shortcut Dimension 1 Code")
                {
                    Caption = 'Shortcut Dimension 1 Code';
                }
                column(ShortcutDimension2Code; "Shortcut Dimension 2 Code")
                {
                    Caption = 'Shortcut Dimension 2 Code';
                }
                dataitem(SalespersonPurchaser; "Salesperson/Purchaser")
                {
                    DataItemLink = Code = PurchaseHeader."Purchaser Code";
                    SqlJoinType = InnerJoin;
                    column(PurchaserName; Name)
                    {
                        Caption = 'Purchaser Name';
                    }
                }
            }
        }
    }
}