// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Assembly.Document;

using Microsoft.Inventory.Item;

page 903 "Assembly Lines"
{
    ApplicationArea = Basic, Suite;
    AutoSplitKey = true;
    Caption = 'Assembly Lines';
    Editable = false;
    PageType = List;
    PopulateAllFields = true;
    SourceTable = "Assembly Line";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Document Type"; Rec."Document Type")
                {
                    ApplicationArea = Assembly;
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = Assembly;
                }
                field(Type; Rec.Type)
                {
                    ApplicationArea = Assembly;
                }
                field("No."; Rec."No.")
                {
                    ApplicationArea = Assembly;
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = Planning;
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
                field("Shortcut Dimension 1 Code"; Rec."Shortcut Dimension 1 Code")
                {
                    ApplicationArea = Dimensions;
                    Visible = false;
                }
                field("Shortcut Dimension 2 Code"; Rec."Shortcut Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;
                    Visible = false;
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Location;
                }
                field("Bin Code"; Rec."Bin Code")
                {
                    ApplicationArea = Warehouse;
                    Visible = false;
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ApplicationArea = Assembly;
                }
                field("Quantity per"; Rec."Quantity per")
                {
                    ApplicationArea = Assembly;
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = Assembly;
                }
                field("Consumed Quantity"; Rec."Consumed Quantity")
                {
                    ApplicationArea = Assembly;
                }
                field("Remaining Quantity"; Rec."Remaining Quantity")
                {
                    ApplicationArea = Assembly;
                }
                field("Due Date"; Rec."Due Date")
                {
                    ApplicationArea = Assembly;
                    Visible = false;
                }
                field("Reserved Quantity"; Rec."Reserved Quantity")
                {
                    ApplicationArea = Reservation;
                }
                field("Qty. per Unit of Measure"; Rec."Qty. per Unit of Measure")
                {
                    ApplicationArea = Assembly;
                }
            }
        }
        area(factboxes)
        {
            systempart(Control9; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control7; Notes)
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
            group(Line)
            {
                Caption = 'Line';
                Image = Line;
                action("Show Document")
                {
                    ApplicationArea = Assembly;
                    Caption = '&Show Document';
                    Image = View;
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'Open the document that the information on the line comes from.';

                    trigger OnAction()
                    begin
                        Rec.ShowAssemblyDocument();
                    end;
                }
                action("Reservation Entries")
                {
                    AccessByPermission = TableData Item = R;
                    ApplicationArea = Reservation;
                    Caption = 'Reservation Entries';
                    Image = ReservationLedger;
                    ToolTip = 'View the entries for every reservation that is made, either manually or automatically.';

                    trigger OnAction()
                    begin
                        Rec.ShowReservationEntries(true);
                    end;
                }
                action("Item &Tracking Lines")
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
                action(ReserveFromInventory)
                {
                    ApplicationArea = Reservation;
                    Caption = 'Reserve from Inventory';
                    Image = LineReserve;
                    ToolTip = 'Reserve items for the selected line from inventory.';

                    trigger OnAction()
                    var
                        AssemblyLine: Record "Assembly Line";
                    begin
                        CurrPage.SetSelectionFilter(AssemblyLine);
                        Rec.ReserveFromInventory(AssemblyLine);
                    end;
                }
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
                actionref("Item &Tracking Lines_Promoted"; "Item &Tracking Lines")
                {
                }
            }
        }
    }
}

