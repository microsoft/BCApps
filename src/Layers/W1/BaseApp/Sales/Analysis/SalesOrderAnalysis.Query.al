// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Analysis;

using Microsoft.CRM.Team;
using Microsoft.Sales.Document;

query 124 "Sales Order Analysis"
{
    QueryType = Normal;
    DataAccessIntent = ReadOnly;
    UsageCategory = ReportsAndAnalysis;
    Caption = 'Sales Order Performance Analysis';
    AboutTitle = 'Sales Order Performance Analysis';
    AboutText = 'The Sales Order Performance Analysis is a query that joins data from Sales Header to Sales Lines.';

    elements
    {
        dataitem(Sales_Header; "Sales Header")
        {
            DataItemTableFilter = "Document Type" = const(Order);
            column(DocumentNo; "No.")
            {
                Caption = 'Document No.';
            }
            column(Status; Status)
            {
                Caption = 'Status';
            }
            column(ExternalDocumentNo; "External Document No.")
            {
                Caption = 'External Document No.';
            }
            column(SalespersonCode; "Salesperson Code")
            {
                Caption = 'Salesperson Code';
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
            column(SellToCustomerNo; "Sell-to Customer No.")
            {
                Caption = 'Sell-to Customer No.';
            }
            column(SellToCustomerName; "Sell-to Customer Name")
            {
                Caption = 'Sell-to Customer Name';
            }
            column(BillToCustomerNo; "Bill-to Customer No.")
            {
                Caption = 'Bill-to Customer No.';
            }
            column(BillToCustomerName; "Bill-to Name")
            {
                Caption = 'Bill-to Customer Name';
            }
            dataitem(Sales_Line; "Sales Line")
            {
                DataItemLink = "Document Type" = Sales_Header."Document Type", "Document No." = Sales_Header."No.";
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
                column(PlannedDeliveryDate; "Planned Delivery Date")
                {
                    Caption = 'Planned Delivery Date';
                }
                column(PlannedShipmentDate; "Planned Shipment Date")
                {
                    Caption = 'Planned Shipment Date';
                }
                column(ShipmentDate; "Shipment Date")
                {
                    Caption = 'Shipment Date';
                }
                column(QuantityShipped; "Quantity Shipped")
                {
                    Caption = 'Quantity Shipped';
                }
                column(QuantityInvoiced; "Quantity Invoiced")
                {
                    Caption = 'Quantity Invoiced';
                }
                column(OutstandingQty; "Outstanding Quantity")
                {
                    Caption = 'Outstanding Qty.';
                }
                column(QtyShippedNotInvoiced; "Qty. Shipped Not Invoiced")
                {
                    Caption = 'Qty. Shipped Not Invoiced';
                }
                column(OutstandingQtyBase; "Outstanding Qty. (Base)")
                {
                    Caption = 'Outstanding Qty. (Base)';
                }
                column(QtyShippedNotInvdBase; "Qty. Shipped Not Invd. (Base)")
                {
                    Caption = 'Qty. Shipped Not Invd. (Base)';
                }
                column(OutstandingAmount; "Outstanding Amount")
                {
                    Caption = 'Outstanding Amount';
                }
                column(ShippedNotInvoiced; "Shipped Not Invoiced")
                {
                    Caption = 'Shipped Not Invoiced';
                }
                column(OutstandingAmountLCY; "Outstanding Amount (LCY)")
                {
                    Caption = 'Outstanding Amount (LCY)';
                }
                column(ShippedNotInvoicedLCY; "Shipped Not Invoiced (LCY)")
                {
                    Caption = 'Shipped Not Invoiced (LCY)';
                }
                column(ShortcutDimension1Code; "Shortcut Dimension 1 Code")
                {
                    Caption = 'Shortcut Dimension 1 Code';
                }
                column(ShortcutDimension2Code; "Shortcut Dimension 2 Code")
                {
                    Caption = 'Shortcut Dimension 2 Code';
                }
                dataitem(Salesperson_Purchaser; "Salesperson/Purchaser")
                {
                    DataItemLink = Code = Sales_Header."Salesperson Code";
                    SqlJoinType = InnerJoin;
                    column(Name; Name)
                    {
                        Caption = 'Salesperson Name';
                    }
                }
            }
        }
    }
}