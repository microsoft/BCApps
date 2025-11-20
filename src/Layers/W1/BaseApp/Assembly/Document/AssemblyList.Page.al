// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Assembly.Document;

using Microsoft.Inventory.Item;

page 904 "Assembly List"
{
    Caption = 'Assembly List';
    DataCaptionFields = "Document Type", "No.";
    Editable = false;
    LinksAllowed = true;
    PageType = List;
    SourceTable = "Assembly Header";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Document Type"; Rec."Document Type")
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies the type of assembly document the record represents in assemble-to-order scenarios.';
                }
                field("No."; Rec."No.")
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies the description of the assembly item.';
                }
                field("Description 2"; Rec."Description 2")
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies information in addition to the description.';
                    Visible = false;
                }
                field("Due Date"; Rec."Due Date")
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies the date when the assembled item is due to be available for use.';
                }
                field("Starting Date"; Rec."Starting Date")
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies the date when the assembly order is expected to start.';
                }
                field("Ending Date"; Rec."Ending Date")
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies the date when the assembly order is expected to finish.';
                }
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the item that is being assembled with the assembly order.';
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies how many units of the assembly item that you expect to assemble with the assembly order.';
                }
                field("Unit Cost"; Rec."Unit Cost")
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies the cost of one unit of the item or resource on the line.';
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the location to which you want to post output of the assembly item.';
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the variant of the item on the line.';
                }
                field("Bin Code"; Rec."Bin Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the bin the assembly item is posted to as output and from where it is taken to storage or shipped if it is assembled to a sales order.';
                }
                field("Remaining Quantity"; Rec."Remaining Quantity")
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies how many units of the assembly item remain to be posted as assembled output.';
                }
            }
        }
        area(factboxes)
        {
            systempart(Control103; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control104; Notes)
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
            action("Show Document")
            {
                ApplicationArea = Assembly;
                Caption = '&Show Document';
                Image = View;
                ShortCutKey = 'Shift+F7';
                ToolTip = 'Open the document that the information on the line comes from.';

                trigger OnAction()
                begin
                    case Rec."Document Type" of
                        Rec."Document Type"::Quote:
                            PAGE.Run(PAGE::"Assembly Quote", Rec);
                        Rec."Document Type"::Order:
                            PAGE.Run(PAGE::"Assembly Order", Rec);
                        Rec."Document Type"::"Blanket Order":
                            PAGE.Run(PAGE::"Blanket Assembly Order", Rec);
                    end;
                end;
            }
            action("Reservation Entries")
            {
                AccessByPermission = TableData Item = R;
                ApplicationArea = Reservation;
                Caption = '&Reservation Entries';
                Image = ReservationLedger;
                ToolTip = 'View all reservations that are made for the item, either manually or automatically.';

                trigger OnAction()
                begin
                    Rec.ShowReservationEntries(true);
                end;
            }
            action("Item Tracking Lines")
            {
                ApplicationArea = ItemTracking;
                Caption = 'Item &Tracking Lines';
                Image = ItemTrackingLines;
                ShortCutKey = 'Ctrl+Alt+I';
                ToolTip = 'View or edit serial, lot and package numbers that are assigned to the item on the document or journal line.';

                trigger OnAction()
                begin
                    Rec.OpenItemTrackingLines();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("Show Document_Promoted"; "Show Document")
                {
                }
                actionref("Reservation Entries_Promoted"; "Reservation Entries")
                {
                }
                actionref("Item Tracking Lines_Promoted"; "Item Tracking Lines")
                {
                }
            }
        }
    }
}

