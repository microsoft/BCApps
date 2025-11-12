// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Payables;

using Microsoft.Purchases.Document;
using Microsoft.Purchases.Vendor;

page 9095 "Vendor Hist. Buy-from FactBox"
{
    Caption = 'Buy-from Vendor History';
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
            group(Control23)
            {
                ShowCaption = false;
                Visible = false;
                field("No. of Quotes"; Rec."No. of Quotes")
                {
                    ApplicationArea = Suite;
                    Caption = 'Quotes';
                    DrillDownPageID = "Purchase Quotes";
                    ToolTip = 'Specifies the number of purchase quotes that exist for the vendor.';
                }
                field("No. of Blanket Orders"; Rec."No. of Blanket Orders")
                {
                    ApplicationArea = Suite;
                    Caption = 'Blanket Orders';
                    DrillDownPageID = "Blanket Purchase Orders";
                    ToolTip = 'Specifies the number of purchase blanket orders that exist for the vendor.';
                }
                field("No. of Orders"; Rec."No. of Orders")
                {
                    ApplicationArea = Suite;
                    Caption = 'Orders';
                    DrillDownPageID = "Purchase Order List";
                    ToolTip = 'Specifies the number of purchase orders that exist for the vendor.';
                }
                field("No. of Invoices"; Rec."No. of Invoices")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Invoices';
                    DrillDownPageID = "Purchase Invoices";
                    ToolTip = 'Specifies the number of unposted purchase invoices that exist for the vendor.';
                }
                field("No. of Return Orders"; Rec."No. of Return Orders")
                {
                    ApplicationArea = PurchReturnOrder;
                    Caption = 'Return Orders';
                    DrillDownPageID = "Purchase Return Order List";
                    ToolTip = 'Specifies the number of purchase return orders that exist for the vendor.';
                }
                field("No. of Credit Memos"; Rec."No. of Credit Memos")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Credit Memos';
                    DrillDownPageID = "Purchase Credit Memos";
                    ToolTip = 'Specifies the number of unposted purchase credit memos that exist for the vendor.';
                }
                field("No. of Pstd. Return Shipments"; Rec."No. of Pstd. Return Shipments")
                {
                    ApplicationArea = PurchReturnOrder;
                    Caption = 'Pstd. Return Shipments';
                    ToolTip = 'Specifies the number of posted return shipments that exist for the vendor.';
                }
                field("No. of Pstd. Receipts"; Rec."No. of Pstd. Receipts")
                {
                    ApplicationArea = Suite;
                    Caption = 'Pstd. Receipts';
                    ToolTip = 'Specifies the number of posted purchase receipts that exist for the vendor.';
                }
                field("No. of Pstd. Invoices"; Rec."No. of Pstd. Invoices")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Pstd. Invoices';
                    ToolTip = 'Specifies the number of posted purchase invoices that exist for the vendor.';
                }
                field("No. of Pstd. Credit Memos"; Rec."No. of Pstd. Credit Memos")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Pstd. Credit Memos';
                    ToolTip = 'Specifies the number of posted purchase credit memos that exist for the vendor.';
                }
                field(NoOfIncomingDocuments; Rec."No. of Incoming Documents")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Incoming Documents';
                    ToolTip = 'Specifies incoming documents, such as vendor invoices in PDF or as image files, that you can manually or automatically convert to document records, such as purchase invoices. The external files that represent incoming documents can be attached at any process stage, including to posted documents and to the resulting vendor, customer, and general ledger entries.';
                }
            }
            cuegroup(Control1)
            {
                ShowCaption = false;
                field(CueQuotes; Rec."No. of Quotes")
                {
                    ApplicationArea = Suite;
                    Caption = 'Quotes';
                    DrillDownPageID = "Purchase Quotes";
                    ToolTip = 'Specifies the number of purchase quotes that exist for the vendor.';
                }
                field(CueBlanketOrders; Rec."No. of Blanket Orders")
                {
                    ApplicationArea = Suite;
                    Caption = 'Blanket Orders';
                    DrillDownPageID = "Blanket Purchase Orders";
                    ToolTip = 'Specifies the number of purchase blanket orders that exist for the vendor.';
                }
                field(CueOrders; Rec."No. of Orders")
                {
                    ApplicationArea = Suite;
                    Caption = 'Orders';
                    DrillDownPageID = "Purchase Order List";
                    ToolTip = 'Specifies the number of purchase orders that exist for the vendor.';
                }
                field(CueInvoices; Rec."No. of Invoices")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Invoices';
                    DrillDownPageID = "Purchase Invoices";
                    ToolTip = 'Specifies the number of unposted purchase invoices that exist for the vendor.';
                }
                field(CueReturnOrders; Rec."No. of Return Orders")
                {
                    ApplicationArea = PurchReturnOrder;
                    Caption = 'Return Orders';
                    DrillDownPageID = "Purchase Return Order List";
                    ToolTip = 'Specifies the number of purchase return orders that exist for the vendor.';
                }
                field(CueCreditMemos; Rec."No. of Credit Memos")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Credit Memos';
                    DrillDownPageID = "Purchase Credit Memos";
                    ToolTip = 'Specifies the number of unposted purchase credit memos that exist for the vendor.';
                }
                field(CuePostedRetShip; Rec."No. of Pstd. Return Shipments")
                {
                    ApplicationArea = PurchReturnOrder;
                    Caption = 'Pstd. Return Shipments';
                    ToolTip = 'Specifies the number of posted return shipments that exist for the vendor.';
                }
                field(CuePostedReceipts; Rec."No. of Pstd. Receipts")
                {
                    ApplicationArea = Suite;
                    Caption = 'Pstd. Receipts';
                    ToolTip = 'Specifies the number of posted purchase receipts that exist for the vendor.';
                }
                field(CuePostedInvoices; Rec."No. of Pstd. Invoices")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Pstd. Invoices';
                    ToolTip = 'Specifies the number of posted purchase invoices that exist for the vendor.';
                }
                field(CuePostedCreditMemos; Rec."No. of Pstd. Credit Memos")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Pstd. Credit Memos';
                    ToolTip = 'Specifies the number of posted purchase credit memos that exist for the vendor.';
                }
                field(CueIncomingDocuments; Rec."No. of Incoming Documents")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Incoming Documents';
                    ToolTip = 'Specifies incoming documents, such as vendor invoices in PDF or as image files, that you can manually or automatically convert to document records, such as purchase invoices. The external files that represent incoming documents can be attached at any process stage, including to posted documents and to the resulting vendor, customer, and general ledger entries.';
                }
            }
        }
    }

    actions
    {
    }

    local procedure ShowDetails()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeShowDetails(Rec, IsHandled);
        if not IsHandled then
            PAGE.Run(PAGE::"Vendor Card", Rec);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowDetails(var Vendor: Record Vendor; var IsHandled: Boolean)
    begin
    end;
}

