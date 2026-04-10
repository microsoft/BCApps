// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.History;

using Microsoft.Warehouse.Comment;
using Microsoft.Warehouse.Journal;

page 7340 "Posted Whse. Shipment List"
{
    ApplicationArea = Warehouse;
    Caption = 'Posted Warehouse Shipments';
    CardPageID = "Posted Whse. Shipment";
    DataCaptionFields = "No.";
    Editable = false;
    PageType = List;
    AboutTitle = 'About Posted Warehouse Shipments';
    AboutText = 'Review and track completed warehouse shipments, including shipment details, quantities shipped, locations, and related sales shipments for audit and operational purposes.';
    SourceTable = "Posted Whse. Shipment Header";
    SourceTableView = sorting("Posting Date")
                      order(descending);
    UsageCategory = History;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("No."; Rec."No.")
                {
                    ApplicationArea = Warehouse;
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Location;
                }
                field("Assigned User ID"; Rec."Assigned User ID")
                {
                    ApplicationArea = Warehouse;
                }
                field("No. Series"; Rec."No. Series")
                {
                    ApplicationArea = Warehouse;
                }
                field("Whse. Shipment No."; Rec."Whse. Shipment No.")
                {
                    ApplicationArea = Warehouse;
                }
                field("Zone Code"; Rec."Zone Code")
                {
                    ApplicationArea = Warehouse;
                    Visible = false;
                }
                field("Bin Code"; Rec."Bin Code")
                {
                    ApplicationArea = Warehouse;
                    Visible = false;
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = Warehouse;
                    Visible = false;
                }
                field("Assignment Date"; Rec."Assignment Date")
                {
                    ApplicationArea = Warehouse;
                    Visible = false;
                }
                field("Shipment Date"; Rec."Shipment Date")
                {
                    ApplicationArea = Warehouse;
                    Visible = false;
                }
                field("Shipping Agent Code"; Rec."Shipping Agent Code")
                {
                    ApplicationArea = Warehouse;
                    Visible = false;
                }
                field("Shipping Agent Service Code"; Rec."Shipping Agent Service Code")
                {
                    ApplicationArea = Warehouse;
                    Visible = false;
                }
                field("Shipment Method Code"; Rec."Shipment Method Code")
                {
                    ApplicationArea = Warehouse;
                    Visible = false;
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
            group("&Shipment")
            {
                Caption = '&Shipment';
                Image = Shipment;
                action("Co&mments")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "Warehouse Comment Sheet";
                    RunPageLink = "Table Name" = const("Posted Whse. Shipment"),
                                  Type = const(" "),
                                  "No." = field("No.");
                    ToolTip = 'View or add comments for the record.';
                }
            }
            group("&Line")
            {
                Caption = '&Line';
                Image = Line;
                action(Card)
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Card';
                    Image = EditLines;
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'View or change detailed information about the record on the document or journal line.';

                    trigger OnAction()
                    begin
                        PAGE.Run(PAGE::"Posted Whse. Shipment", Rec);
                    end;
                }
            }
        }
        area(Promoted)
        {
        }
    }

    trigger OnOpenPage()
    var
        WMSManagement: Codeunit "WMS Management";
    begin
        Rec.ErrorIfUserIsNotWhseEmployee();
        Rec.FilterGroup(2); // set group of filters user cannot change
        Rec.SetFilter("Location Code", WMSManagement.GetWarehouseEmployeeLocationFilter(UserId));
        Rec.FilterGroup(0); // set filter group back to standard
    end;
}

