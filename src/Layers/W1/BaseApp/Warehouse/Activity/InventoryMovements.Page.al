// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Activity;

using Microsoft.Warehouse.Comment;
using Microsoft.Warehouse.InventoryDocument;
using Microsoft.Warehouse.Journal;

page 9330 "Inventory Movements"
{
    ApplicationArea = Warehouse;
    Caption = 'Inventory Movements';
    CardPageID = "Inventory Movement";
    Editable = false;
    PageType = List;
    SourceTable = "Warehouse Activity Header";
    SourceTableView = where(Type = const("Invt. Movement"));
    UsageCategory = Lists;

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
                field(SourceDocument; Rec."Source Document")
                {
                    ApplicationArea = Warehouse;
                }
                field("Source No."; Rec."Source No.")
                {
                    ApplicationArea = Warehouse;
                }
                field(Type; Rec.Type)
                {
                    ApplicationArea = Warehouse;
                    Visible = false;
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Warehouse;
                }
                field("Destination Type"; Rec."Destination Type")
                {
                    ApplicationArea = Warehouse;
                }
                field("Destination No."; Rec."Destination No.")
                {
                    ApplicationArea = Warehouse;
                }
                field("External Document No."; Rec."External Document No.")
                {
                    ApplicationArea = Warehouse;
                }
                field("Assigned User ID"; Rec."Assigned User ID")
                {
                    ApplicationArea = Warehouse;
                    Visible = false;
                }
                field("No. of Lines"; Rec."No. of Lines")
                {
                    ApplicationArea = Warehouse;
                }
                field("Sorting Method"; Rec."Sorting Method")
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
            group("&Movement")
            {
                Caption = '&Movement';
                Image = CreateMovement;
                action("Co&mments")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "Warehouse Comment Sheet";
                    RunPageLink = "Table Name" = const("Whse. Activity Header"),
                                  Type = field(Type),
                                  "No." = field("No.");
                    ToolTip = 'View or add comments for the record.';
                }
                action("&Registered Invt. Movement")
                {
                    ApplicationArea = Warehouse;
                    Caption = '&Registered Invt. Movement';
                    Image = RegisteredDocs;
                    RunObject = Page "Registered Invt. Movement";
                    RunPageLink = "Invt. Movement No." = field("No.");
                    RunPageView = sorting("Invt. Movement No.");
                    ToolTip = 'View any quantities that have already been moved.';
                }
                action("Source Document")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Source Document';
                    Image = "Order";
                    ToolTip = 'View the source document of the warehouse activity.';

                    trigger OnAction()
                    var
                        WMSMgt: Codeunit "WMS Management";
                    begin
                        WMSMgt.ShowSourceDocCard(Rec."Source Type", Rec."Source Subtype", Rec."Source No.");
                    end;
                }
            }
        }
        area(processing)
        {
            action("Assign to me")
            {
                ApplicationArea = Warehouse;
                Caption = 'Assign to me';
                Image = User;
                Gesture = LeftSwipe;
                ToolTip = 'Assigns this movement document to the current user.';

                trigger OnAction()
                begin
                    Rec.AssignToCurrentUser();
                    CurrPage.Update();
                end;
            }
        }
        area(Promoted)
        {
            actionref("Assign to me_Promoted"; "Assign to me")
            {
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
}

