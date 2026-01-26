// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Document;

using Microsoft.Sales.History;

page 10838 "Shipments bound by Invoice"
{
    Caption = 'Shipments bound by Invoice';
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
                field("Shipment No."; Rec."Shipment No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the shipment number bounded to the invoice.';
                }
                field("Qty. to Ship"; Rec."Qty. to Ship")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the quantity of shipped items that have been invoiced.';
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
            action("&Shipment")
            {
                ApplicationArea = Basic, Suite;
                Caption = '&Shipment';
                Image = Shipment;
                RunObject = Page "Posted Sales Shipment";
                RunPageLink = "No." = field("Shipment No.");
                ToolTip = 'View details about the posted shipment related to the selected invoice.';
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("&Shipment_Promoted"; "&Shipment")
                {
                }
            }
        }
    }
}

