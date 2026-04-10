// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Activity;

using Microsoft.Warehouse.Comment;
using Microsoft.Warehouse.InventoryDocument;
using Microsoft.Warehouse.Journal;

page 9316 "Inventory Picks"
{
    ApplicationArea = Warehouse;
    Caption = 'Inventory Picks';
    CardPageID = "Inventory Pick";
    Editable = false;
    PageType = List;
    AboutTitle = 'About Inventory Picks';
    AboutText = 'Record, manage, and post inventory picking activities for outbound orders, including selecting bins, handling quantities, splitting lines for multiple bins, and updating warehouse records.';
    RefreshOnActivate = true;
    SourceTable = "Warehouse Activity Header";
    SourceTableView = where(Type = const("Invt. Pick"));
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
                field("Shipment Date"; Rec."Shipment Date")
                {
                    ApplicationArea = Warehouse;
                    Editable = false;
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
                action("Posted Picks")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Posted Picks';
                    Image = PostedInventoryPick;
                    RunObject = Page "Posted Invt. Pick List";
                    RunPageLink = "Invt Pick No." = field("No.");
                    RunPageView = sorting("Invt Pick No.");
                    ToolTip = 'View any quantities that have already been picked.';
                }
                action("Source Document")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Show Source Document';
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
            group("Posting")
            {
                Caption = 'Posting';
                Image = Post;
                action("Post")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Post';
                    Ellipsis = true;
                    Image = PostOrder;
                    ShortCutKey = 'F9';
                    ToolTip = 'Finalize the document or journal by posting the amounts and quantities to the related accounts in your company books.';

                    trigger OnAction()
                    begin
                        PostPickYesNo();
                    end;
                }
                action(PreviewPosting)
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Preview Posting';
                    Image = ViewPostedOrder;
                    ShortCutKey = 'Ctrl+Alt+F9';
                    ToolTip = 'Review the different types of entries that will be created when you post the document or journal.';

                    trigger OnAction()
                    begin
                        PreviewPostPick();
                    end;
                }
                action(PostAndPrint)
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Post and Print';
                    Ellipsis = true;
                    Image = PostPrint;
                    ShortCutKey = 'Shift+F9';
                    ToolTip = 'Finalize and prepare to print the document or journal. The values and quantities are posted to the related accounts. A report request window where you can specify what to include on the print-out.';

                    trigger OnAction()
                    begin
                        PostAndPrintPick();
                    end;
                }
            }
            action("Assign to me")
            {
                ApplicationArea = Warehouse;
                Caption = 'Assign to me';
                Image = User;
                Gesture = LeftSwipe;
                Scope = Repeater;
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

                group(Category_Posting)
                {
                    Caption = 'Posting';
                    ShowAs = SplitButton;

                    actionref("Post_Promoted"; "Post")
                    {
                    }
                    actionref(PreviewPosting_Promoted; PreviewPosting)
                    {
                    }
                    actionref(PostAndPrint_Promoted; PostAndPrint)
                    {
                    }
                }
                actionref("Source Document_Promoted"; "Source Document")
                {
                }
                actionref("Co&mments_Promoted"; "Co&mments")
                {
                }
                actionref("Posted Picks_Promoted"; "Posted Picks")
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

    local procedure PostPickYesNo()
    var
        WhseActivLine: Record "Warehouse Activity Line";
        WhseActPostYesNo: Codeunit "Whse.-Act.-Post (Yes/No)";
    begin
        GetLinesForRec(WhseActivLine);
        WhseActPostYesNo.Run(WhseActivLine);
    end;

    local procedure PreviewPostPick()
    var
        WhseActivLine: Record "Warehouse Activity Line";
        SelectedWarehouseActivityHeader: Record "Warehouse Activity Header";
        WhseActPostYesNo: Codeunit "Whse.-Act.-Post (Yes/No)";
    begin
        CurrPage.SetSelectionFilter(SelectedWarehouseActivityHeader);
        WhseActPostYesNo.MessageIfPostingPreviewMultipleDocuments(SelectedWarehouseActivityHeader, Rec."No.");
        GetLinesForRec(WhseActivLine);
        WhseActPostYesNo.Preview(WhseActivLine);
    end;

    local procedure PostAndPrintPick()
    var
        WhseActivLine: Record "Warehouse Activity Line";
        WhseActivPostYesNo: Codeunit "Whse.-Act.-Post (Yes/No)";
    begin
        GetLinesForRec(WhseActivLine);
        WhseActivPostYesNo.PrintDocument(true);
        WhseActivPostYesNo.Run(WhseActivLine);
    end;

    local procedure GetLinesForRec(var WhseActivLine: Record "Warehouse Activity Line")
    begin
        WhseActivLine.SetRange("Activity Type", WhseActivLine."Activity Type"::"Invt. Pick");
        WhseActivLine.SetRange("No.", Rec."No.");
        WhseActivLine.FindSet();
    end;
}

