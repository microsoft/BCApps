// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Activity;

using Microsoft.Warehouse.Activity.History;
using Microsoft.Warehouse.Comment;
using Microsoft.Warehouse.Journal;

page 9312 "Warehouse Put-aways"
{
    ApplicationArea = Warehouse;
    Caption = 'Warehouse Put-aways';
    CardPageID = "Warehouse Put-away";
    Editable = false;
    PageType = List;
    AboutTitle = 'About Warehouse Put-aways';
    AboutText = 'Organize and record the physical placement of received items in the warehouse by managing put-away activities for specific source documents and locations, to update inventory availability in the destination bins.';
    SourceTable = "Warehouse Activity Header";
    SourceTableView = where(Type = const("Put-away"));
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
            group("Put-&away")
            {
                Caption = 'Put-&away';
                Image = CreatePutAway;
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
                action("Registered Put-aways")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Registered Put-aways';
                    Image = RegisteredDocs;
                    RunObject = Page "Registered Whse. Activity List";
                    RunPageLink = Type = field(Type),
                                  "Whse. Activity No." = field("No.");
                    RunPageView = sorting("Whse. Activity No.");
                    ToolTip = 'View the quantity that has already been put-away.';
                }
            }
        }
        area(processing)
        {
            action("Register Put-away")
            {
                ApplicationArea = Warehouse;
                Caption = 'Register Put-away';
                Image = RegisterPutAway;
                ShortCutKey = 'F9';
                ToolTip = 'Record that the items have been put away.';

                trigger OnAction()
                begin
                    RegisterPutAwayYesNo();
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
                    WhseActPrint.PrintPutAwayHeader(Rec);
                end;
            }
            action("Assign to me")
            {
                ApplicationArea = Warehouse;
                Caption = 'Assign to me';
                Image = User;
                Gesture = LeftSwipe;
                ToolTip = 'Assigns this put-away to the current user.';

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

                actionref("Register Put-away_Promoted"; "Register Put-away")
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

    trigger OnOpenPage()
    var
        WMSManagement: Codeunit "WMS Management";
    begin
        Rec.ErrorIfUserIsNotWhseEmployee();
        Rec.FilterGroup(2); // set group of filters user cannot change
        Rec.SetFilter("Location Code", WMSManagement.GetWarehouseEmployeeLocationFilter(UserId));
        Rec.FilterGroup(0); // set filter group back to standard
    end;

    local procedure RegisterPutAwayYesNo()
    var
        WhseActivLine: Record "Warehouse Activity Line";
        WhseActRegisterYesNo: Codeunit "Whse.-Act.-Register (Yes/No)";
    begin
        GetLinesForRec(WhseActivLine);
        WhseActRegisterYesNo.Run(WhseActivLine);
    end;

    local procedure GetLinesForRec(var WhseActivLine: Record "Warehouse Activity Line")
    begin
        WhseActivLine.SetRange("Activity Type", "Warehouse Activity Type"::"Put-away");
        WhseActivLine.SetRange("No.", Rec."No.");
        WhseActivLine.FindSet();
    end;
}

