// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Transfer;

#if not CLEAN27
using Microsoft.Manufacturing.Document;
#endif

page 5749 "Transfer Lines"
{
    Caption = 'Transfer Lines';
    Editable = false;
    PageType = List;
    SourceTable = "Transfer Line";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the document number that is associated with the line or entry.';
                }
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the number of the item that is transferred.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies a description of the item.';
                }
                field("Description 2"; Rec."Description 2")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies information in addition to the description of the item being transferred.';
                    Visible = false;
                }
                field("Shipment Date"; Rec."Shipment Date")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies when items on the document are shipped or were shipped. A shipment date is usually calculated from a requested delivery date plus lead time.';
                }
                field("Return Order"; Rec."Return Order")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies if a component of the transfer line is a return.';
                }
                field("Transfer-from Code"; Rec."Transfer-from Code")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the code of the location that you are transferring items from.';
                }
                field("Transfer-to Code"; Rec."Transfer-to Code")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the code of the location that you are transferring items to.';
                }
                field("Qty. in Transit"; Rec."Qty. in Transit")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the quantity of the item that is in transit.';
                }
                field("Quantity Received"; Rec."Quantity Received")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the number of items that have been received.';
                }
                field("Outstanding Quantity"; Rec."Outstanding Quantity")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the quantity of the items that remains to be shipped.';
                }
                field("WIP Qty. Shipped"; Rec."WIP Qty. Shipped")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the number of work in process (WIP) items that have shipped on a subcontractor transfer order.';
                }
                field("WIP Outstanding Qty."; Rec."WIP Outstanding Qty.")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the number of work in process (WIP) items that will be shipped on a subcontractor transfer order.';
                }
                field("Unit of Measure"; Rec."Unit of Measure")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the name of the item or resource''s unit of measure, such as piece or hour.';
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Line")
            {
                Caption = '&Line';
                Image = Line;
                action("Show Document")
                {
                    ApplicationArea = Location;
                    Caption = 'Show Document';
                    Image = View;
                    ToolTip = 'Show the related source document.';

                    trigger OnAction()
                    var
                        TransferHeader: Record "Transfer Header";
                    begin
                        TransferHeader.Get(Rec."Document No.");
                        TransferHeader.CalcFields("Subcontracting Order");
#if not CLEAN27
                        if TransferHeader."Subcontracting Order" then
                            PAGE.Run(PAGE::"Subcontr. Transfer Order", TransferHeader)
                        else
#endif
                        PAGE.Run(PAGE::"Transfer Order", TransferHeader);
                    end;
                }
            }
        }
        area(Promoted)
        {
        }
    }
}

