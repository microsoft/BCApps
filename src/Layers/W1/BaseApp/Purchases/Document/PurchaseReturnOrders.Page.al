// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Document;

using Microsoft.Inventory.Item;

page 6643 "Purchase Return Orders"
{
    Caption = 'Purchase Return Orders';
    DataCaptionFields = "No.";
    Editable = false;
    PageType = List;
    SourceTable = "Purchase Line";
    SourceTableView = where("Document Type" = filter("Return Order"));

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Type; Rec.Type)
                {
                    ApplicationArea = PurchReturnOrder;
                }
                field("No."; Rec."No.")
                {
                    ApplicationArea = PurchReturnOrder;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = PurchReturnOrder;
                }
                field("Description 2"; Rec."Description 2")
                {
                    ApplicationArea = PurchReturnOrder;
                    Importance = Additional;
                    Visible = false;
                }
                field("Expected Receipt Date"; Rec."Expected Receipt Date")
                {
                    ApplicationArea = PurchReturnOrder;
                    ToolTip = 'Specifies the date you expect the items to be available in your warehouse. If you leave the field blank, it will be calculated as follows: Planned Receipt Date + Safety Lead Time + Inbound Warehouse Handling Time = Expected Receipt Date.';
                }
                field("Buy-from Vendor No."; Rec."Buy-from Vendor No.")
                {
                    ApplicationArea = PurchReturnOrder;
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = PurchReturnOrder;
                    ToolTip = 'Specifies the number of the document.';
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = PurchReturnOrder;
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = PurchReturnOrder;
                }
                field("Outstanding Quantity"; Rec."Outstanding Quantity")
                {
                    ApplicationArea = PurchReturnOrder;
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ApplicationArea = PurchReturnOrder;
                }
                field(Amount; Rec.Amount)
                {
                    ApplicationArea = PurchReturnOrder;
                }
                field("Direct Unit Cost"; Rec."Direct Unit Cost")
                {
                    ApplicationArea = PurchReturnOrder;
                }
                field("Line Discount %"; Rec."Line Discount %")
                {
                    ApplicationArea = PurchReturnOrder;
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
                Visible = true;
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
                    ApplicationArea = PurchReturnOrder;
                    Caption = 'Show Document';
                    Image = View;
                    RunObject = Page "Purchase Return Order";
                    RunPageLink = "Document Type" = field("Document Type"),
                                  "No." = field("Document No.");
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'Open the document that the selected line exists on.';
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
                action(PurchaseOrderStatistics)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Statistics';
                    Enabled = Rec."No." <> '';
                    Image = Statistics;
                    ShortCutKey = 'F7';
                    Visible = true;
                    ToolTip = 'View statistical information, such as the value of posted entries, for the record.';
                    RunObject = Page "Purchase Order Statistics";
                    RunPageOnRec = true;
                }
            }
        }
    }
}

