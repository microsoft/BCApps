// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Document;

using Microsoft.Inventory.Item;

/// <summary>
/// Displays sales return order lines for lookup and selection purposes.
/// </summary>
page 6633 "Sales Return Orders"
{
    Caption = 'Sales Return Orders';
    DataCaptionFields = "No.";
    Editable = false;
    PageType = List;
    SourceTable = "Sales Line";
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
                    ApplicationArea = SalesReturnOrder;
                    ToolTip = 'Specifies the type of entity that will be posted for this sales line, such as Item, Resource, or G/L Account.';
                }
                field("No."; Rec."No.")
                {
                    ApplicationArea = SalesReturnOrder;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = SalesReturnOrder;
                    ToolTip = 'Specifies a description of the entry.';
                }
                field("Return Reason Code"; Rec."Return Reason Code")
                {
                    ApplicationArea = SalesReturnOrder;
                }
                field("Shipment Date"; Rec."Shipment Date")
                {
                    ApplicationArea = SalesReturnOrder;
                }
                field("Sell-to Customer No."; Rec."Sell-to Customer No.")
                {
                    ApplicationArea = SalesReturnOrder;
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = SalesReturnOrder;
                    ToolTip = 'Specifies the number of the document.';
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = SalesReturnOrder;
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = SalesReturnOrder;
                }
                field("Outstanding Quantity"; Rec."Outstanding Quantity")
                {
                    ApplicationArea = SalesReturnOrder;
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ApplicationArea = SalesReturnOrder;
                }
                field(Amount; Rec.Amount)
                {
                    ApplicationArea = SalesReturnOrder;
                }
                field("Unit Price"; Rec."Unit Price")
                {
                    ApplicationArea = SalesReturnOrder;
                    ToolTip = 'Specifies the price of one unit of the item or resource. You can enter a price manually or have it entered according to the Price/Profit Calculation field on the related card.';
                }
                field("Line Discount %"; Rec."Line Discount %")
                {
                    ApplicationArea = SalesReturnOrder;
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
                action("Show Order")
                {
                    ApplicationArea = SalesReturnOrder;
                    Caption = 'Show Order';
                    Image = ViewOrder;
                    RunObject = Page "Sales Return Order";
                    RunPageLink = "Document Type" = field("Document Type"),
                                  "No." = field("Document No.");
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'View the selected sales return order';
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
    }
}

