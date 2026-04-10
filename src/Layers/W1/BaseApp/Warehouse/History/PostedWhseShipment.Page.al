// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.History;

using Microsoft.Warehouse.Activity;
using Microsoft.Warehouse.Comment;
using Microsoft.Warehouse.Journal;

page 7337 "Posted Whse. Shipment"
{
    Caption = 'Posted Whse. Shipment';
    InsertAllowed = false;
    PageType = Document;
    RefreshOnActivate = true;
    SourceTable = "Posted Whse. Shipment Header";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("No."; Rec."No.")
                {
                    ApplicationArea = Warehouse;
                    Editable = false;
                    Importance = Promoted;
                }
                field("Whse. Shipment No."; Rec."Whse. Shipment No.")
                {
                    ApplicationArea = Warehouse;
                    Editable = false;
                    Importance = Promoted;
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Location;
                    Editable = false;
                }
                field("Zone Code"; Rec."Zone Code")
                {
                    ApplicationArea = Warehouse;
                    Editable = false;
                }
                field("Bin Code"; Rec."Bin Code")
                {
                    ApplicationArea = Warehouse;
                    Editable = false;
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = Warehouse;
                    Editable = false;
                }
                field("Assigned User ID"; Rec."Assigned User ID")
                {
                    ApplicationArea = Warehouse;
                    Editable = false;
                    Importance = Promoted;
                }
                field("Assignment Date"; Rec."Assignment Date")
                {
                    ApplicationArea = Warehouse;
                    Editable = false;
                }
                field("Assignment Time"; Rec."Assignment Time")
                {
                    ApplicationArea = Warehouse;
                    Editable = false;
                }
            }
            part(WhseShptLines; "Posted Whse. Shipment Subform")
            {
                ApplicationArea = Warehouse;
                SubPageLink = "No." = field("No.");
                SubPageView = sorting("No.", "Line No.");
            }
            group(Shipping)
            {
                Caption = 'Shipping';
                field("External Document No."; Rec."External Document No.")
                {
                    ApplicationArea = Warehouse;
                    Editable = false;
                    Importance = Promoted;
                }
                field("Shipment Date"; Rec."Shipment Date")
                {
                    ApplicationArea = Warehouse;
                    Editable = false;
                    Importance = Promoted;
                }
                field("Shipping Agent Code"; Rec."Shipping Agent Code")
                {
                    ApplicationArea = Warehouse;
                    Editable = false;
                }
                field("Shipping Agent Service Code"; Rec."Shipping Agent Service Code")
                {
                    ApplicationArea = Warehouse;
                    Editable = false;
                    Importance = Promoted;
                }
                field("Shipment Method Code"; Rec."Shipment Method Code")
                {
                    ApplicationArea = Warehouse;
                    Editable = false;
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
                action(List)
                {
                    ApplicationArea = Warehouse;
                    Caption = 'List';
                    Image = OpportunitiesList;
                    ToolTip = 'View all warehouse documents of this type that exist.';

                    trigger OnAction()
                    begin
                        Rec.LookupPostedWhseShptHeader(Rec);
                    end;
                }
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
        }
        area(processing)
        {
            action("&Print")
            {
                ApplicationArea = Warehouse;
                Caption = '&Print';
                Ellipsis = true;
                Image = Print;
                ToolTip = 'Prepare to print the document. A report request window for the document opens where you can specify what to include on the print-out.';

                trigger OnAction()
                begin
                    WhseDocPrint.PrintPostedShptHeader(Rec);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';

                actionref("&Print_Promoted"; "&Print")
                {
                }
            }
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

    var
        WhseDocPrint: Codeunit "Warehouse Document-Print";
}

