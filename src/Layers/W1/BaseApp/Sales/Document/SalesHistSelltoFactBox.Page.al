// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Document;

using Microsoft.Sales.Customer;
using Microsoft.Sales.History;

page 9080 "Sales Hist. Sell-to FactBox"
{
    Caption = 'Sell-to Customer Sales History';
    PageType = CardPart;
    SourceTable = Customer;

    layout
    {
        area(content)
        {
            field("No."; Rec."No.")
            {
                ApplicationArea = All;
                Caption = 'Customer No.';
                ToolTip = 'Specifies the number of the customer. The field is either filled automatically from a defined number series, or you enter the number manually because you have enabled manual number entry in the number-series setup.';

                trigger OnDrillDown()
                begin
                    ShowDetails();
                end;
            }
            group(Control23)
            {
                ShowCaption = false;
                Visible = false;
                field("No. of Quotes"; Rec."No. of Quotes")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Ongoing Sales Quotes';
                    DrillDownPageID = "Sales Quotes";
                    ToolTip = 'Specifies the number of sales quotes that have been registered for the customer.';
                }
                field("No. of Blanket Orders"; Rec."No. of Blanket Orders")
                {
                    ApplicationArea = Suite;
                    Caption = 'Ongoing Sales Blanket Orders';
                    DrillDownPageID = "Blanket Sales Orders";
                    ToolTip = 'Specifies the number of sales blanket orders that have been registered for the customer.';
                }
                field("No. of Orders"; Rec."No. of Orders")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Ongoing Sales Orders';
                    DrillDownPageID = "Sales Order List";
                    ToolTip = 'Specifies the number of sales orders that have been registered for the customer.';
                }
                field("No. of Invoices"; Rec."No. of Invoices")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Ongoing Sales Invoices';
                    DrillDownPageID = "Sales Invoice List";
                    ToolTip = 'Specifies the number of unposted sales invoices that have been registered for the customer.';
                }
                field("No. of Return Orders"; Rec."No. of Return Orders")
                {
                    ApplicationArea = SalesReturnOrder;
                    Caption = 'Ongoing Sales Return Orders';
                    DrillDownPageID = "Sales Return Order List";
                    ToolTip = 'Specifies the number of sales return orders that have been registered for the customer.';
                }
                field("No. of Credit Memos"; Rec."No. of Credit Memos")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Ongoing Sales Credit Memos';
                    DrillDownPageID = "Sales Credit Memos";
                    ToolTip = 'Specifies the number of unposted sales credit memos that have been registered for the customer.';
                }
                field("No. of Pstd. Shipments"; Rec."No. of Pstd. Shipments")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Posted Sales Shipments';
                    DrillDownPageID = "Posted Sales Shipments";
                    ToolTip = 'Specifies the number of posted sales shipments that have been registered for the customer.';
                }
                field("No. of Pstd. Invoices"; Rec."No. of Pstd. Invoices")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Posted Sales Invoices';
                    DrillDownPageID = "Posted Sales Invoices";
                    ToolTip = 'Specifies the number of posted sales invoices that have been registered for the customer.';
                }
                field("No. of Pstd. Return Receipts"; Rec."No. of Pstd. Return Receipts")
                {
                    ApplicationArea = SalesReturnOrder;
                    Caption = 'Posted Sales Return Receipts';
                    DrillDownPageID = "Posted Return Receipts";
                    ToolTip = 'Specifies the number of posted sales return receipts that have been registered for the customer.';
                }
                field("No. of Pstd. Credit Memos"; Rec."No. of Pstd. Credit Memos")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Posted Sales Credit Memos';
                    DrillDownPageID = "Posted Sales Credit Memos";
                    ToolTip = 'Specifies the number of posted sales credit memos that have been registered for the customer.';
                }
            }
            cuegroup(Control2)
            {
                ShowCaption = false;
                field(NoofQuotesTile; Rec."No. of Quotes")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Ongoing Sales Quotes';
                    DrillDownPageID = "Sales Quotes";
                    ToolTip = 'Specifies the number of sales quotes that have been registered for the customer.';
                }
                field(NoofBlanketOrdersTile; Rec."No. of Blanket Orders")
                {
                    ApplicationArea = Suite;
                    Caption = 'Ongoing Sales Blanket Orders';
                    DrillDownPageID = "Blanket Sales Orders";
                    ToolTip = 'Specifies the number of sales blanket orders that have been registered for the customer.';
                }
                field(NoofOrdersTile; Rec."No. of Orders")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Ongoing Sales Orders';
                    DrillDownPageID = "Sales Order List";
                    ToolTip = 'Specifies the number of sales orders that have been registered for the customer.';
                }
                field(NoofInvoicesTile; Rec."No. of Invoices")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Ongoing Sales Invoices';
                    DrillDownPageID = "Sales Invoice List";
                    ToolTip = 'Specifies the number of unposted sales invoices that have been registered for the customer.';
                }
                field(NoofReturnOrdersTile; Rec."No. of Return Orders")
                {
                    ApplicationArea = SalesReturnOrder;
                    Caption = 'Ongoing Sales Return Orders';
                    DrillDownPageID = "Sales Return Order List";
                    ToolTip = 'Specifies the number of sales return orders that have been registered for the customer.';
                }
                field(NoofCreditMemosTile; Rec."No. of Credit Memos")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Ongoing Sales Credit Memos';
                    DrillDownPageID = "Sales Credit Memos";
                    ToolTip = 'Specifies the number of unposted sales credit memos that have been registered for the customer.';
                }
                field(NoofPstdShipmentsTile; Rec."No. of Pstd. Shipments")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Posted Sales Shipments';
                    DrillDownPageID = "Posted Sales Shipments";
                    ToolTip = 'Specifies the number of posted sales shipments that have been registered for the customer.';
                }
                field(NoofPstdInvoicesTile; Rec."No. of Pstd. Invoices")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Posted Sales Invoices';
                    DrillDownPageID = "Posted Sales Invoices";
                    ToolTip = 'Specifies the number of posted sales invoices that have been registered for the customer.';
                }
                field(NoofPstdReturnReceiptsTile; Rec."No. of Pstd. Return Receipts")
                {
                    ApplicationArea = SalesReturnOrder;
                    Caption = 'Posted Sales Return Receipts';
                    DrillDownPageID = "Posted Return Receipts";
                    ToolTip = 'Specifies the number of posted sales return receipts that have been registered for the customer.';
                }
                field(NoofPstdCreditMemosTile; Rec."No. of Pstd. Credit Memos")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Posted Sales Credit Memos';
                    DrillDownPageID = "Posted Sales Credit Memos";
                    ToolTip = 'Specifies the number of posted sales credit memos that have been registered for the customer.';
                }
            }
        }
    }

    actions
    {
    }

    local procedure ShowDetails()
    begin
        PAGE.Run(PAGE::"Customer Card", Rec);
    end;
}

