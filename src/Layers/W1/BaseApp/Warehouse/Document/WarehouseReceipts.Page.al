// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Document;

using Microsoft.Warehouse.Comment;
using Microsoft.Warehouse.History;
using Microsoft.Warehouse.Journal;

page 7332 "Warehouse Receipts"
{
    ApplicationArea = Warehouse;
    Caption = 'Warehouse Receipts';
    CardPageID = "Warehouse Receipt";
    DataCaptionFields = "No.";
    Editable = false;
    PageType = List;
    AboutTitle = 'About Warehouse Receipts';
    AboutText = 'Manage and post the receipt of items from purchase orders and other source documents, adjust received quantities, assign bins and locations, and track the status of warehouse receipts to update inventory records.';
    SourceTable = "Warehouse Receipt Header";
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
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the code of the location in which the items are being received.';
                }
                field("Assigned User ID"; Rec."Assigned User ID")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the ID of the user who is responsible for the document.';
                }
                field("Sorting Method"; Rec."Sorting Method")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the method by which the receipts are sorted.';
                }
                field("Zone Code"; Rec."Zone Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the zone in which the items are being received if you are using directed put-away and pick.';
                    Visible = false;
                }
                field("Bin Code"; Rec."Bin Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the bin where the items are picked or put away.';
                    Visible = false;
                }
                field("Document Status"; Rec."Document Status")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the status of the warehouse receipt.';
                    Visible = false;
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the posting date of the warehouse receipt.';
                    Visible = false;
                }
                field("Assignment Date"; Rec."Assignment Date")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the date when the user was assigned the activity.';
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
            group("&Receipt")
            {
                Caption = '&Receipt';
                Image = Receipt;
                action("Co&mments")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "Warehouse Comment Sheet";
                    RunPageLink = "Table Name" = const("Whse. Receipt"),
                                  Type = const(" "),
                                  "No." = field("No.");
                    ToolTip = 'View or add comments for the record.';
                }
                action("Posted &Whse. Receipts")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Posted &Whse. Receipts';
                    Image = PostedReceipts;
                    RunObject = Page "Posted Whse. Receipt List";
                    RunPageLink = "Whse. Receipt No." = field("No.");
                    RunPageView = sorting("Whse. Receipt No.");
                    ToolTip = 'View the quantity that has been posted as received.';
                }
            }
        }
        area(processing)
        {
            group("Posting")
            {
                Caption = 'Posting';
                Image = Post;
                action("Post Receipt")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Post Receipt';
                    Image = PostOrder;
                    ShortCutKey = 'F9';
                    ToolTip = 'Post the items as received. A put-away document is created automatically.';

                    trigger OnAction()
                    begin
                        WhsePostRcptYesNo();
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
                        ShowPreview();
                    end;
                }
                action("Post and Print")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Post and Print';
                    Image = PostPrint;
                    ShortCutKey = 'Shift+F9';
                    ToolTip = 'Finalize and prepare to print the document or journal. The values and quantities are posted to the related accounts. A report request window where you can specify what to include on the print-out.';

                    trigger OnAction()
                    begin
                        WhsePostRcptPrintPostedRcpt();
                    end;
                }
                action("Post and Print Put-away")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Post and Print Put-away';
                    Image = PostPrint;
                    ShortCutKey = 'Shift+Ctrl+F9';
                    ToolTip = 'Post the items as received and print the put-away document.';

                    trigger OnAction()
                    begin
                        WhsePostAndPrintPutAway();
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {

                group(Category_Posting)
                {
                    Caption = 'Posting';
                    ShowAs = SplitButton;

                    actionref("Post Shipment_Promoted"; "Post Receipt")
                    {
                    }
                    actionref(PreviewPosting_Promoted; PreviewPosting)
                    {
                    }
                    actionref("Post and Print_Promoted"; "Post and Print")
                    {
                    }
                    actionref("Post and Print Put-away_Promoted"; "Post and Print Put-away")
                    {
                    }
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

    local procedure WhsePostRcptYesNo()
    var
        WhseRcptLine: Record "Warehouse Receipt Line";
        WhsePostReceipt: Codeunit "Whse.-Post Receipt (Yes/No)";
    begin
        GetLinesForRec(WhseRcptLine);
        WhsePostReceipt.Run(WhseRcptLine);
    end;

    local procedure ShowPreview()
    var
        WhseRcptLine: Record "Warehouse Receipt Line";
        SelectedWarehouseReceiptHeader: Record "Warehouse Receipt Header";
        WhsePostReceiptYesNo: Codeunit "Whse.-Post Receipt (Yes/No)";
    begin
        CurrPage.SetSelectionFilter(SelectedWarehouseReceiptHeader);
        WhsePostReceiptYesNo.MessageIfPostingPreviewMultipleDocuments(SelectedWarehouseReceiptHeader, Rec."No.");
        GetLinesForRec(WhseRcptLine);
        WhsePostReceiptYesNo.Preview(WhseRcptLine);
    end;

    local procedure WhsePostRcptPrintPostedRcpt()
    var
        WhseRcptLine: Record "Warehouse Receipt Line";
        WhsePostReceiptAndPrint: Codeunit "Whse.-Post Receipt + Print";
    begin
        GetLinesForRec(WhseRcptLine);
        WhsePostReceiptAndPrint.Run(WhseRcptLine);
    end;

    procedure WhsePostAndPrintPutAway()
    var
        WhseRcptLine: Record "Warehouse Receipt Line";
        WhsePostReceiptAndPrint: Codeunit "Whse.-Post Receipt + Print";
    begin
        GetLinesForRec(WhseRcptLine);
        WhsePostReceiptAndPrint.Run(WhseRcptLine);
    end;

    local procedure GetLinesForRec(var WhseRcptLine: Record "Warehouse Receipt Line")
    begin
        WhseRcptLine.SetRange("No.", Rec."No.");
        WhseRcptLine.FindSet();
    end;
}

