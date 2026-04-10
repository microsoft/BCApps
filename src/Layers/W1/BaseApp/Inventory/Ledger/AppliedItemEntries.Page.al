// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Ledger;

using Microsoft.Finance.Dimension;
using Microsoft.Foundation.Navigate;
using Microsoft.Inventory.Item;

page 5804 "Applied Item Entries"
{
    Caption = 'Applied Item Entries';
    Editable = false;
    PageType = List;
    SourceTable = "Item Ledger Entry";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Entry Type"; Rec."Entry Type")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = Planning;
                    Visible = false;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Global Dimension 1 Code"; Rec."Global Dimension 1 Code")
                {
                    ApplicationArea = Dimensions;
                    Visible = false;
                }
                field("Global Dimension 2 Code"; Rec."Global Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;
                    Visible = false;
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Location;
                }
                field(ApplQty; ApplQty)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 0;
                    Caption = 'Applied Quantity';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies how many units of the item that have been applied.';
                }
                field(Qty; Qty)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 0;
                    Caption = 'Quantity';
                    ToolTip = 'Specifies the total quantity of items that have been applied.';
                }
                field("Invoiced Quantity"; Rec."Invoiced Quantity")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = true;
                }
                field("Remaining Quantity"; Rec."Remaining Quantity")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = true;
                }
                field("Reserved Quantity"; Rec."Reserved Quantity")
                {
                    ApplicationArea = Reservation;
                    Visible = false;

                    trigger OnDrillDown()
                    begin
                        Rec.ShowReservationEntries(true);
                    end;
                }
                field(Open; Rec.Open)
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Qty. per Unit of Measure"; Rec."Qty. per Unit of Measure")
                {
                    ApplicationArea = Suite;
                    Visible = false;
                }
                field("Drop Shipment"; Rec."Drop Shipment")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Applied Entry to Adjust"; Rec."Applied Entry to Adjust")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Order Type"; Rec."Order Type")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Order No."; Rec."Order No.")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = Basic, Suite;
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
            group("Ent&ry")
            {
                Caption = 'Ent&ry';
                Image = Entry;
                action(Dimensions)
                {
                    AccessByPermission = TableData Dimension = R;
                    ApplicationArea = Dimensions;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    ShortCutKey = 'Alt+D';
                    ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to sales and purchase documents to distribute costs and analyze transaction history.';

                    trigger OnAction()
                    begin
                        Rec.ShowDimensions();
                    end;
                }
                action("&Value Entries")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '&Value Entries';
                    Image = ValueLedger;
                    RunObject = Page "Value Entries";
                    RunPageLink = "Item Ledger Entry No." = field("Entry No.");
                    RunPageView = sorting("Item Ledger Entry No.");
                    ShortCutKey = 'Ctrl+F7';
                    ToolTip = 'View the history of posted amounts that affect the value of the item. Value entries are created for every transaction with the item.';
                }
            }
            group("&Application")
            {
                Caption = '&Application';
                Image = Apply;
                action("Applied E&ntries")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Applied E&ntries';
                    Image = Approve;
                    ToolTip = 'View the ledger entries that have been applied to this record.';

                    trigger OnAction()
                    begin
                        CODEUNIT.Run(CODEUNIT::"Show Applied Entries", Rec);
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
            }
        }
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action("Order &Tracking")
                {
                    ApplicationArea = ItemTracking;
                    Caption = 'Order &Tracking';
                    Image = OrderTracking;
                    ToolTip = 'Tracks the connection of a supply to its corresponding demand. This can help you find the original demand that created a specific production order or purchase order.';

                    trigger OnAction()
                    var
                        OrderTracking: Page "Order Tracking";
                    begin
                        OrderTracking.SetItemLedgEntry(Rec);
                        OrderTracking.RunModal();
                    end;
                }
            }
            action("&Navigate")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Find entries...';
                Image = Navigate;
                ShortCutKey = 'Ctrl+Alt+Q';
                ToolTip = 'Find entries and documents that exist for the document number and posting date on the selected document. (Formerly this action was named Navigate.)';

                trigger OnAction()
                begin
                    Navigate.SetDoc(Rec."Posting Date", Rec."Document No.");
                    Navigate.Run();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("&Navigate_Promoted"; "&Navigate")
                {
                }
                actionref("Order &Tracking_Promoted"; "Order &Tracking")
                {
                }
            }
            group(Category_Entry)
            {
                Caption = 'Entry';

                actionref(Dimensions_Promoted; Dimensions)
                {
                }
                actionref("&Value Entries_Promoted"; "&Value Entries")
                {
                }
            }
            group(Category_Application)
            {
                Caption = 'Application';

                actionref("Applied E&ntries_Promoted"; "Applied E&ntries")
                {
                }
                actionref("Reservation Entries_Promoted"; "Reservation Entries")
                {
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        GetApplQty();
    end;

    var
        Navigate: Page Navigate;

    protected var
        ApplQty: Decimal;
        Qty: Decimal;

    local procedure GetApplQty()
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.Get(Rec."Entry No.");
        ApplQty := Rec.Quantity;
        Qty := ItemLedgerEntry.Quantity;
    end;
}

