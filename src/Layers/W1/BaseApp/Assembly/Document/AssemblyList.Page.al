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
                }
                field("No."; Rec."No.")
                {
                    ApplicationArea = Assembly;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Assembly;
                }
                field("Description 2"; Rec."Description 2")
                {
                    ApplicationArea = Assembly;
                    Visible = false;
                }
                field("Due Date"; Rec."Due Date")
                {
                    ApplicationArea = Assembly;
                }
                field("Starting Date"; Rec."Starting Date")
                {
                    ApplicationArea = Assembly;
                }
                field("Ending Date"; Rec."Ending Date")
                {
                    ApplicationArea = Assembly;
                }
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = Assembly;
                }
                field("Unit Cost"; Rec."Unit Cost")
                {
                    ApplicationArea = Assembly;
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Location;
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = Planning;
                }
                field("Bin Code"; Rec."Bin Code")
                {
                    ApplicationArea = Warehouse;
                }
                field("Remaining Quantity"; Rec."Remaining Quantity")
                {
                    ApplicationArea = Assembly;
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

