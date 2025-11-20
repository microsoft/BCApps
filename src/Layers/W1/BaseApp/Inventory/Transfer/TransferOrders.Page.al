// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Transfer;

using Microsoft.Finance.Dimension;
using Microsoft.Foundation.Reporting;
using Microsoft.Inventory.Comment;
using Microsoft.Warehouse.Activity;
using Microsoft.Warehouse.Document;
using Microsoft.Warehouse.Request;
using Microsoft.Warehouse.Structure;
using System.Environment.Configuration;
using System.Text;

page 5742 "Transfer Orders"
{
    ApplicationArea = Location;
    Caption = 'Transfer Orders';
    CardPageID = "Transfer Order";
    Editable = false;
    PageType = List;
    AboutTitle = 'About Transfer Orders';
    AboutText = 'Manage and track the movement of inventory items between locations by creating, posting, and monitoring transfer orders, including handling shipment, receipt, and serial or lot number assignments.';
    SourceTable = "Transfer Header";
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
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field("Transfer-from Code"; Rec."Transfer-from Code")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the code of the location that items are transferred from.';
                }
                field("Transfer-to Code"; Rec."Transfer-to Code")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the code of the location that the items are transferred to.';
                }
                field("In-Transit Code"; Rec."In-Transit Code")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the in-transit code for the transfer order, such as a shipping agent.';
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies whether the transfer order is open or has been released for warehouse handling.';
                }
                field("Direct Transfer"; Rec."Direct Transfer")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies that the transfer does not use an in-transit location.';
                }
                field("Shortcut Dimension 1 Code"; Rec."Shortcut Dimension 1 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for Shortcut Dimension 1, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
                    Visible = false;
                }
                field("Shortcut Dimension 2 Code"; Rec."Shortcut Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for Shortcut Dimension 2, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
                    Visible = false;
                }
                field("Assigned User ID"; Rec."Assigned User ID")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the ID of the user who is responsible for the document.';
                    Visible = not IsFoundationEnabled;
                }
                field("Shipment Date"; Rec."Shipment Date")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies when items on the document are shipped or were shipped. A shipment date is usually calculated from a requested delivery date plus lead time.';
                    Visible = false;
                }
                field("Shipment Method Code"; Rec."Shipment Method Code")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the delivery conditions of the related shipment, such as free on board (FOB).';
                    Visible = false;
                }
                field("Shipping Agent Code"; Rec."Shipping Agent Code")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the code for the shipping agent who is transporting the items.';
                    Visible = false;
                }
                field("Shipping Advice"; Rec."Shipping Advice")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies an instruction to the warehouse that ships the items, for example, that it is acceptable to do partial shipment.';
                    Visible = false;
                }
                field("Receipt Date"; Rec."Receipt Date")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the date that you expect the transfer-to location to receive the shipment.';
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
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("O&rder")
            {
                Caption = 'O&rder';
                Image = "Order";
                action(Statistics)
                {
                    ApplicationArea = Suite;
                    Caption = 'Statistics';
                    Image = Statistics;
                    RunObject = Page "Transfer Statistics";
                    RunPageLink = "No." = field("No.");
                    ShortCutKey = 'F7';
                    ToolTip = 'View statistical information about the transfer order, such as the quantity and total weight transferred.';
                }
                action("Co&mments")
                {
                    ApplicationArea = Comments;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "Inventory Comment Sheet";
                    RunPageLink = "Document Type" = const("Transfer Order"),
                                  "No." = field("No.");
                    ToolTip = 'View or add comments for the record.';
                }
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
                        Rec.ShowDocDim();
                        CurrPage.SaveRecord();
                    end;
                }
            }
            group(Documents)
            {
                Caption = 'Documents';
                Image = Documents;
                action("S&hipments")
                {
                    ApplicationArea = Location;
                    Caption = 'S&hipments';
                    Image = Shipment;
                    RunObject = Page "Posted Transfer Shipments";
                    RunPageLink = "Transfer Order No." = field("No.");
                    ToolTip = 'View related posted transfer shipments.';
                }
                action("Re&ceipts")
                {
                    ApplicationArea = Location;
                    Caption = 'Re&ceipts';
                    Image = PostedReceipts;
                    RunObject = Page "Posted Transfer Receipts";
                    RunPageLink = "Transfer Order No." = field("No.");
                    ToolTip = 'View related posted transfer receipts.';
                }
            }
            group(Warehouse)
            {
                Caption = 'Warehouse';
                Image = Warehouse;
                action("Whse. Shi&pments")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Whse. Shi&pments';
                    Image = Shipment;
                    RunObject = Page "Whse. Shipment Lines";
                    RunPageLink = "Source Type" = const(5741),
                                  "Source Subtype" = const("0"),
                                  "Source No." = field("No.");
                    RunPageView = sorting("Source Type", "Source Subtype", "Source No.", "Source Line No.");
                    ToolTip = 'View outbound items that have been shipped with warehouse activities for the transfer order.';
                }
                action("&Whse. Receipts")
                {
                    ApplicationArea = Warehouse;
                    Caption = '&Whse. Receipts';
                    Image = Receipt;
                    RunObject = Page "Whse. Receipt Lines";
                    RunPageLink = "Source Type" = const(5741),
                                  "Source Subtype" = const("1"),
                                  "Source No." = field("No.");
                    RunPageView = sorting("Source Type", "Source Subtype", "Source No.", "Source Line No.");
                    ToolTip = 'View inbound items that have been received with warehouse activities for the transfer order.';
                }
                action("In&vt. Put-away/Pick Lines")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'In&vt. Put-away/Pick Lines';
                    Image = PickLines;
                    RunObject = Page "Warehouse Activity List";
                    RunPageLink = "Source Document" = filter("Inbound Transfer" | "Outbound Transfer"),
                                  "Source No." = field("No.");
                    RunPageView = sorting("Source Document", "Source No.", "Location Code");
                    ToolTip = 'View items that are inbound or outbound on inventory put-away or inventory pick documents for the transfer order.';
                }
                action("Whse. Put-away/Pick Lines")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Warehouse Put-away/Pick Lines';
                    Image = PutawayLines;
                    RunObject = page "Warehouse Activity Lines";
                    RunPageLink = "Source Document" = filter("Inbound Transfer" | "Outbound Transfer"), "Source No." = field("No.");
                    RunPageView = sorting("Source Type", "Source Subtype", "Source No.");
                    ToolTip = 'View items that are inbound or outbound on warehouse put-away or warehouse pick documents for the transfer order.';
                }
                action("Transfer Routes")
                {
                    ApplicationArea = Location;
                    Caption = 'Transfer Routes';
                    Image = Setup;
                    RunObject = Page "Transfer Routes";
                    ToolTip = 'View the list of transfer routes that are set up to transfer items from one location to another.';
                }
            }
        }
        area(processing)
        {
            action("&Print")
            {
                ApplicationArea = Location;
                Caption = '&Print';
                Ellipsis = true;
                Image = Print;
                ToolTip = 'Prepare to print the document. A report request window for the document opens where you can specify what to include on the print-out.';

                trigger OnAction()
                var
                    DocPrint: Codeunit "Document-Print";
                begin
                    DocPrint.PrintTransferHeader(Rec);
                end;
            }
            group(Release)
            {
                Caption = 'Release';
                Image = ReleaseDoc;
                action("Re&lease")
                {
                    ApplicationArea = Location;
                    Caption = 'Re&lease';
                    Image = ReleaseDoc;
                    ShortCutKey = 'Ctrl+F9';
                    ToolTip = 'Release the document to the next stage of processing. You must reopen the document before you can make changes to it.';

                    trigger OnAction()
                    begin
                        Rec.PerformManualRelease();
                    end;
                }
                action("Reo&pen")
                {
                    ApplicationArea = Location;
                    Caption = 'Reo&pen';
                    Image = ReOpen;
                    ToolTip = 'Reopen the transfer order after being released for warehouse handling.';

                    trigger OnAction()
                    var
                        ReleaseTransferDoc: Codeunit "Release Transfer Document";
                    begin
                        ReleaseTransferDoc.Reopen(Rec);
                    end;
                }
            }
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action("Create Whse. S&hipment")
                {
                    AccessByPermission = TableData "Warehouse Shipment Header" = R;
                    ApplicationArea = Warehouse;
                    Caption = 'Create Whse. S&hipment';
                    Image = NewShipment;
                    ToolTip = 'Create a warehouse shipment to start a pick a ship process according to an advanced warehouse configuration.';

                    trigger OnAction()
                    var
                        GetSourceDocOutbound: Codeunit "Get Source Doc. Outbound";
                    begin
                        Rec.PerformManualRelease();
                        GetSourceDocOutbound.CreateFromOutbndTransferOrder(Rec);
                    end;
                }
                action("Create &Whse. Receipt")
                {
                    AccessByPermission = TableData "Warehouse Receipt Header" = R;
                    ApplicationArea = Warehouse;
                    Caption = 'Create &Whse. Receipt';
                    Image = NewReceipt;
                    ToolTip = 'Create a warehouse receipt to start a receive and put-away process according to an advanced warehouse configuration.';

                    trigger OnAction()
                    var
                        GetSourceDocInbound: Codeunit "Get Source Doc. Inbound";
                    begin
                        Rec.PerformManualRelease();
                        GetSourceDocInbound.CreateFromInbndTransferOrder(Rec);
                    end;
                }
                action("Create Inventor&y Put-away/Pick")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Create Inventor&y Put-away/Pick';
                    Ellipsis = true;
                    Image = CreatePutawayPick;
                    ToolTip = 'Create an inventory put-away or inventory pick to handle items on the document according to a basic warehouse configuration that does not require warehouse receipt or shipment documents.';

                    trigger OnAction()
                    begin
                        Rec.PerformManualRelease();
                        Rec.CreateInvtPutAwayPick();
                    end;
                }
                action("Get Bin Content")
                {
                    AccessByPermission = TableData "Bin Content" = R;
                    ApplicationArea = Warehouse;
                    Caption = 'Get Bin Content';
                    Ellipsis = true;
                    Image = GetBinContent;
                    ToolTip = 'Use a function to create transfer lines with items to put away or pick based on the actual content in the specified bin.';

                    trigger OnAction()
                    var
                        BinContent: Record "Bin Content";
                        GetBinContent: Report "Whse. Get Bin Content";
                    begin
                        BinContent.SetRange("Location Code", Rec."Transfer-from Code");
                        GetBinContent.SetTableView(BinContent);
                        GetBinContent.InitializeTransferHeader(Rec);
                        GetBinContent.RunModal();
                    end;
                }
            }
            group("P&osting")
            {
                Caption = 'P&osting';
                Image = Post;
                action(Post)
                {
                    ApplicationArea = Location;
                    Caption = 'P&ost';
                    Ellipsis = true;
                    Image = PostOrder;
                    ShortCutKey = 'F9';
                    ToolTip = 'Finalize the document or journal by posting the amounts and quantities to the related accounts in your company books.';

                    trigger OnAction()
                    begin
                        CODEUNIT.Run(CODEUNIT::"TransferOrder-Post (Yes/No)", Rec);
                    end;
                }
                action(PostAndPrint)
                {
                    ApplicationArea = Location;
                    Caption = 'Post and &Print';
                    Image = PostPrint;
                    ShortCutKey = 'Shift+F9';
                    ToolTip = 'Finalize and prepare to print the document or journal. The values and quantities are posted to the related accounts. A report request window where you can specify what to include on the print-out.';

                    trigger OnAction()
                    begin
                        CODEUNIT.Run(CODEUNIT::"TransferOrder-Post + Print", Rec);
                    end;
                }
                action(PreviewPosting)
                {
                    ApplicationArea = Location;
                    Caption = 'Preview Posting';
                    Image = ViewPostedOrder;
                    ShortCutKey = 'Ctrl+Alt+F9';
                    ToolTip = 'Review the different types of entries that will be created when you post the document or journal.';

                    trigger OnAction()
                    begin
                        ShowPreview();
                        CurrPage.Update(false);
                    end;
                }
                action(BatchPost)
                {
                    ApplicationArea = Location;
                    Caption = 'Post &Batch';
                    Ellipsis = true;
                    Image = PostBatch;
                    ToolTip = 'Post several documents at once. A report request window opens where you can specify which documents to post.';

                    trigger OnAction()
                    var
                        TransferHeader: Record "Transfer Header";
                        SelectionFilterManagement: Codeunit SelectionFilterManagement;
                    begin
                        CurrPage.SetSelectionFilter(TransferHeader);
                        TransferHeader.SetFilter("No.", SelectionFilterManagement.GetSelectionFilterForTransferHeader(TransferHeader));
                        REPORT.RunModal(REPORT::"Batch Post Transfer Orders", true, true, TransferHeader);
                        CurrPage.Update(false);
                    end;
                }

            }
        }
        area(reporting)
        {
            action("Inventory - Inbound Transfer")
            {
                ApplicationArea = Location;
                Caption = 'Inventory - Inbound Transfer';
                Image = "Report";
                RunObject = Report "Inventory - Inbound Transfer";
                ToolTip = 'View which items are currently on inbound transfer orders.';
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';

                actionref("Create Whse. S&hipment_Promoted"; "Create Whse. S&hipment")
                {
                }
                actionref("Create &Whse. Receipt_Promoted"; "Create &Whse. Receipt")
                {
                }
                actionref("Create Inventor&y Put-away/Pick_Promoted"; "Create Inventor&y Put-away/Pick")
                {
                }
                actionref("Get Bin Content_Promoted"; "Get Bin Content")
                {
                }
            }
            group(Category_Category4)
            {
                Caption = 'Release', Comment = 'Generated from the PromotedActionCategories property index 3.';
                ShowAs = SplitButton;

                actionref("Re&lease_Promoted"; "Re&lease")
                {
                }
                actionref("Reo&pen_Promoted"; "Reo&pen")
                {
                }
            }
            group(Category_Category5)
            {
                Caption = 'Posting', Comment = 'Generated from the PromotedActionCategories property index 4.';
                ShowAs = SplitButton;

                actionref(Post_Promoted; Post)
                {
                }
                actionref(PreviewPosting_Promoted; PreviewPosting)
                {
                }
                actionref(PostAndPrint_Promoted; PostAndPrint)
                {
                }
                actionref(BatchPost_Promoted; BatchPost)
                {
                }
            }
            group(Category_Category8)
            {
                Caption = 'Print/Send', Comment = 'Generated from the PromotedActionCategories property index 7.';

                actionref("&Print_Promoted"; "&Print")
                {
                }
            }
            group(Category_Category6)
            {
                Caption = 'Order', Comment = 'Generated from the PromotedActionCategories property index 5.';

                actionref(Dimensions_Promoted; Dimensions)
                {
                }
                actionref(Statistics_Promoted; Statistics)
                {
                }
                actionref("Co&mments_Promoted"; "Co&mments")
                {
                }

                separator(Navigate_Separator)
                {
                }

                actionref("S&hipments_Promoted"; "S&hipments")
                {
                }
                actionref("Re&ceipts_Promoted"; "Re&ceipts")
                {
                }
            }
            group(Category_Category7)
            {
                Caption = 'Documents', Comment = 'Generated from the PromotedActionCategories property index 6.';
            }
            group(Category_Category9)
            {
                Caption = 'Navigate', Comment = 'Generated from the PromotedActionCategories property index 8.';
            }
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';

            }
        }
    }

    trigger OnInit()
    var
        ApplicationAreaMgmtFacade: Codeunit "Application Area Mgmt. Facade";
    begin
        IsFoundationEnabled := ApplicationAreaMgmtFacade.IsFoundationEnabled();
    end;

    var
        IsFoundationEnabled: Boolean;

    local procedure ShowPreview()
    var
        SelectedTransferHeader: Record "Transfer Header";
        TransferOrderPostYesNo: Codeunit "TransferOrder-Post (Yes/No)";
    begin
        CurrPage.SetSelectionFilter(SelectedTransferHeader);
        TransferOrderPostYesNo.MessageIfPostingPreviewMultipleDocuments(SelectedTransferHeader, Rec."No.");
        TransferOrderPostYesNo.Preview(Rec);
    end;
}

