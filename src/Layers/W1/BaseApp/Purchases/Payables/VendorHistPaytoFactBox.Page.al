// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Payables;

using Microsoft.Purchases.Document;
using Microsoft.Purchases.Vendor;


page 9096 "Vendor Hist. Pay-to FactBox"
{
    Caption = 'Pay-to Vendor History';
    PageType = CardPart;
    SourceTable = Vendor;

    layout
    {
        area(content)
        {
            field("No."; Rec."No.")
            {
                ApplicationArea = All;
                Caption = 'Vendor No.';
                ToolTip = 'Specifies the number of the vendor. The field is either filled automatically from a defined number series, or you enter the number manually because you have enabled manual number entry in the number-series setup.';

                trigger OnDrillDown()
                begin
                    ShowDetails();
                end;
            }
            group(Control1)
            {
                ShowCaption = false;
                Visible = false;
                field("Pay-to No. of Quotes"; Rec."Pay-to No. of Quotes")
                {
                    ApplicationArea = Suite;
                    Caption = 'Quotes';
                    DrillDownPageID = "Purchase Quotes";
                    ToolTip = 'Specifies the number of quotes that exist for the vendor.';
                }
                field("Pay-to No. of Blanket Orders"; Rec."Pay-to No. of Blanket Orders")
                {
                    ApplicationArea = Suite;
                    Caption = 'Blanket Orders';
                    DrillDownPageID = "Blanket Purchase Orders";
                    ToolTip = 'Specifies the number of blanket orders.';
                }
                field("Pay-to No. of Orders"; Rec."Pay-to No. of Orders")
                {
                    ApplicationArea = Suite;
                    Caption = 'Orders';
                    DrillDownPageID = "Purchase Order List";
                    ToolTip = 'Specifies the number of posted orders that exist for the vendor.';
                }
                field("Pay-to No. of Invoices"; Rec."Pay-to No. of Invoices")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Invoices';
                    DrillDownPageID = "Purchase Invoices";
                    ToolTip = 'Specifies the amount that relates to invoices.';
                }
                field("Pay-to No. of Return Orders"; Rec."Pay-to No. of Return Orders")
                {
                    ApplicationArea = PurchReturnOrder;
                    Caption = 'Return Orders';
                    DrillDownPageID = "Purchase Return Order List";
                    ToolTip = 'Specifies how many return orders have been registered for the customer when the customer acts as the pay-to customer.';
                }
                field("Pay-to No. of Credit Memos"; Rec."Pay-to No. of Credit Memos")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Credit Memos';
                    DrillDownPageID = "Purchase Credit Memos";
                    ToolTip = 'Specifies the amount that relates to credit memos.';
                }
                field("Pay-to No. of Pstd. Return S."; Rec."Pay-to No. of Pstd. Return S.")
                {
                    ApplicationArea = PurchReturnOrder;
                    Caption = 'Pstd. Return Shipments';
                    ToolTip = 'Specifies the number of posted return shipments that exist for the vendor.';
                }
                field("Pay-to No. of Pstd. Receipts"; Rec."Pay-to No. of Pstd. Receipts")
                {
                    ApplicationArea = Suite;
                    Caption = 'Pstd. Receipts';
                    ToolTip = 'Specifies the number of posted receipts that exist for the vendor.';
                }
                field("Pay-to No. of Pstd. Invoices"; Rec."Pay-to No. of Pstd. Invoices")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Pstd. Invoices';
                    ToolTip = 'Specifies the amount that relates to posted invoices.';
                }
                field("Pay-to No. of Pstd. Cr. Memos"; Rec."Pay-to No. of Pstd. Cr. Memos")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Pstd. Credit Memos';
                    ToolTip = 'Specifies the amount that relates to credit memos.';
                }
            }
            cuegroup(Control23)
            {
                ShowCaption = false;
                field(NoOfQuotesTile; Rec."Pay-to No. of Quotes")
                {
                    ApplicationArea = Suite;
                    Caption = 'Quotes';
                    DrillDownPageID = "Purchase Quotes";
                    ToolTip = 'Specifies the number of quotes that exist for the vendor.';
                }
                field(NoOfBlanketOrdersTile; Rec."Pay-to No. of Blanket Orders")
                {
                    ApplicationArea = Suite;
                    Caption = 'Blanket Orders';
                    DrillDownPageID = "Blanket Purchase Orders";
                    ToolTip = 'Specifies the number of blanket orders.';
                }
                field(NoOfOrdersTile; Rec."Pay-to No. of Orders")
                {
                    ApplicationArea = Suite;
                    Caption = 'Orders';
                    DrillDownPageID = "Purchase Order List";
                    ToolTip = 'Specifies the number of posted orders that exist for the customer.';
                }
                field(NoOfInvoicesTile; Rec."Pay-to No. of Invoices")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Invoices';
                    DrillDownPageID = "Purchase Invoices";
                    ToolTip = 'Specifies the amount that relates to invoices.';
                }
                field(NoOfReturnOrdersTile; Rec."Pay-to No. of Return Orders")
                {
                    ApplicationArea = PurchReturnOrder;
                    Caption = 'Return Orders';
                    DrillDownPageID = "Purchase Return Order List";
                    ToolTip = 'Specifies how many return orders have been registered for the customer when the customer acts as the pay-to customer.';
                }
                field(NoOfCreditMemosTile; Rec."Pay-to No. of Credit Memos")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Credit Memos';
                    DrillDownPageID = "Purchase Credit Memos";
                    ToolTip = 'Specifies the amount that relates to credit memos.';
                }
                field(NoOfPostedReturnShipmentsTile; Rec."Pay-to No. of Pstd. Return S.")
                {
                    ApplicationArea = PurchReturnOrder;
                    Caption = 'Pstd. Return Shipments';
                    ToolTip = 'Specifies the number of posted return shipments that exist for the vendor.';
                }
                field(NoOfPostedReceiptsTile; Rec."Pay-to No. of Pstd. Receipts")
                {
                    ApplicationArea = Suite;
                    Caption = 'Pstd. Receipts';
                    ToolTip = 'Specifies the number of posted receipts that exist for the vendor.';
                }
                field(NoOfPostedInvoicesTile; Rec."Pay-to No. of Pstd. Invoices")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Pstd. Invoices';
                    ToolTip = 'Specifies the amount that relates to posted invoices.';
                }
                field(NoOfPostedCreditMemosTile; Rec."Pay-to No. of Pstd. Cr. Memos")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Pstd. Credit Memos';
                    ToolTip = 'Specifies the amount that relates to credit memos.';
                }
            }
        }
    }

    actions
    {
    }

    local procedure ShowDetails()
    begin
        PAGE.Run(PAGE::"Vendor Card", Rec);
    end;
}

