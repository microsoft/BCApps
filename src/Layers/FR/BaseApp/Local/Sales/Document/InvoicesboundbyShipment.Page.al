// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Document;

using Microsoft.Sales.History;

page 10837 "Invoices bound by Shipment"
{
    Caption = 'Invoices bound by Shipment';
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    SourceTable = "Shipment Invoiced";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Invoice No."; Rec."Invoice No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the invoice number bounded to the shipment.';
                }
                field("Qty. to Invoice"; Rec."Qty. to Invoice")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the quantity of invoiced items that have been shipped.';
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date when the invoice was posted.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action("&Invoice")
            {
                ApplicationArea = Basic, Suite;
                Caption = '&Invoice';
                Image = SalesInvoice;
                RunObject = Page "Posted Sales Invoice";
                RunPageLink = "No." = field("Invoice No.");
                ToolTip = 'View a list of invoices for the items that were included in a shipment.';
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("&Invoice_Promoted"; "&Invoice")
                {
                }
            }
        }
    }
}

