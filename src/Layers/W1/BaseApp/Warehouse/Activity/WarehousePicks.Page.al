// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Activity;

using Microsoft.Warehouse.Activity.History;
using Microsoft.Warehouse.Comment;
using Microsoft.Warehouse.Journal;

page 9313 "Warehouse Picks"
{
    ApplicationArea = Warehouse;
    Caption = 'Warehouse Picks';
    CardPageID = "Warehouse Pick";
    Editable = false;
    PageType = List;
    AboutTitle = 'About Warehouse Picks';
    AboutText = 'Manage and optimize the picking of items for warehouse shipments by viewing assigned picks, following detailed pick and place instructions, and sorting or splitting pick lines to streamline warehouse operations.';
    SourceTable = "Warehouse Activity Header";
    SourceTableView = where(Type = const(Pick));
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
                field("Source Document"; Rec."Source Document")
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
                field("Assignment Date"; Rec."Assignment Date")
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
            group("P&ick")
            {
                Caption = 'P&ick';
                Image = CreateInventoryPickup;
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
                action("Registered Picks")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Registered Picks';
                    Image = RegisteredDocs;
                    RunObject = Page "Registered Whse. Activity List";
                    RunPageLink = Type = field(Type),
                                  "Whse. Activity No." = field("No.");
                    RunPageView = sorting("Whse. Activity No.");
                    ToolTip = 'View the quantities that have already been picked.';
                }
            }
        }
        area(processing)
        {
            action(RegisterPick)
            {
                ApplicationArea = Warehouse;
                Caption = 'Register Pick';
                Image = RegisterPick;
                ShortCutKey = 'F9';
                ToolTip = 'Record that the items have been picked.';

                trigger OnAction()
                begin
                    RegisterActivityYesNo();
                end;
            }
            action("Print")
            {
                ApplicationArea = Warehouse;
                Caption = 'Print';
                Ellipsis = true;
                Image = Print;
                ToolTip = 'Prepare to print the document. A report request window for the document opens where you can specify what to include on the print-out.';

                trigger OnAction()
                var
                    WhseActPrint: Codeunit "Warehouse Document-Print";
                begin
                    WhseActPrint.PrintPickHeader(Rec);
                end;
            }
            action("Assign to me")
            {
                ApplicationArea = Warehouse;
                Caption = 'Assign to me';
                Image = User;
                Gesture = LeftSwipe;
                ToolTip = 'Assigns this pick document to the current user.';

                trigger OnAction()
                begin
                    Rec.AssignToCurrentUser();
                    CurrPage.Update();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(RegisterPick_Promoted; RegisterPick)
                {
                }
                actionref("Print_Promoted"; "Print")
                {
                }
                actionref("Assign to me_Promoted"; "Assign to me")
                {
                }
            }
        }
    }

    views
    {
        view(Unassigned)
        {
            Caption = 'Unassigned';
            Filters = where("Assigned User ID" = filter(''));
        }
        view(MyPicks)
        {
            Caption = 'My Picks';
            Filters = where("Assigned User ID" = filter('%user'));
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

    local procedure RegisterActivityYesNo()
    var
        WhseActivLine: Record "Warehouse Activity Line";
        WhseActRegisterYesNo: Codeunit "Whse.-Act.-Register (Yes/No)";
    begin
        GetLinesForRec(WhseActivLine);
        WhseActRegisterYesNo.Run(WhseActivLine);
    end;

    local procedure GetLinesForRec(var WhseActivLine: Record "Warehouse Activity Line")
    begin
        WhseActivLine.SetRange("Activity Type", "Warehouse Activity Type"::Pick);
        WhseActivLine.SetRange("No.", Rec."No.");
        WhseActivLine.FindSet();
    end;
}

