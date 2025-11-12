// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Document;

using Microsoft.Warehouse.Activity;
using Microsoft.Warehouse.Activity.History;
using Microsoft.Warehouse.Comment;
using Microsoft.Warehouse.History;
using Microsoft.Warehouse.Journal;

page 7339 "Warehouse Shipment List"
{
    ApplicationArea = Warehouse;
    Caption = 'Warehouse Shipments';
    CardPageID = "Warehouse Shipment";
    DataCaptionFields = "No.";
    Editable = false;
    PageType = List;
    AboutTitle = 'About Warehouse Shipments';
    AboutText = 'Create, organize, and post outbound warehouse shipments by selecting source documents, assigning locations and users, managing picking activities, and tracking shipment status and delivery details.';
    SourceTable = "Warehouse Shipment Header";
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
                    ToolTip = 'Specifies the code of the location from which the items are being shipped.';
                }
                field("Assigned User ID"; Rec."Assigned User ID")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the ID of the user who is responsible for the document.';
                }
                field("Sorting Method"; Rec."Sorting Method")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the method by which the shipments are sorted.';
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the status of the shipment and is filled in by the program.';
                }
                field("Zone Code"; Rec."Zone Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the code of the zone on this shipment header.';
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
                    ToolTip = 'Specifies the progress level of warehouse handling on lines in the warehouse shipment.';
                    Visible = false;
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies a posting date. If you enter a date, the posting date of the source documents is updated during posting.';
                    Visible = false;
                }
                field("Assignment Date"; Rec."Assignment Date")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the date when the user was assigned the activity.';
                    Visible = false;
                }
                field("Shipment Date"; Rec."Shipment Date")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies when items on the document are shipped or were shipped. A shipment date is usually calculated from a requested delivery date plus lead time.';
                    Visible = false;
                }
                field("Shipping Agent Code"; Rec."Shipping Agent Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the code for the shipping agent who is transporting the items.';
                    Visible = false;
                }
                field("Shipping Agent Service Code"; Rec."Shipping Agent Service Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the code for the service, such as a one-day delivery, that is offered by the shipping agent.';
                    Visible = false;
                }
                field("Shipment Method Code"; Rec."Shipment Method Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the delivery conditions of the related shipment, such as free on board (FOB).';
                    Visible = false;
                }
                field("Completely Picked"; Rec."Completely Picked")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies whether all items on the warehouse shipment have been completely picked.';
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
                    RunPageLink = "Table Name" = const("Whse. Shipment"),
                                  Type = const(" "),
                                  "No." = field("No.");
                    ToolTip = 'View or add comments for the record.';
                }
                action("Pick Lines")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Pick Lines';
                    Image = PickLines;
                    RunObject = Page "Warehouse Activity Lines";
                    RunPageLink = "Whse. Document Type" = const(Shipment),
                                  "Whse. Document No." = field("No.");
                    RunPageView = sorting("Whse. Document No.", "Whse. Document Type", "Activity Type")
                                  where("Activity Type" = const(Pick));
                    ToolTip = 'View the related picks.';
                }
                action("Registered P&ick Lines")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Registered P&ick Lines';
                    Image = RegisteredDocs;
                    RunObject = Page "Registered Whse. Act.-Lines";
                    RunPageLink = "Whse. Document No." = field("No.");
                    RunPageView = sorting("Whse. Document Type", "Whse. Document No.", "Whse. Document Line No.")
                                  where("Whse. Document Type" = const(Shipment));
                    ToolTip = 'View the list of warehouse picks that have been made for the order.';
                }
                action("Posted &Warehouse Shipments")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Posted &Warehouse Shipments';
                    Image = PostedReceipt;
                    RunObject = Page "Posted Whse. Shipment List";
                    RunPageLink = "Whse. Shipment No." = field("No.");
                    RunPageView = sorting("Whse. Shipment No.");
                    ToolTip = 'View the quantity that has been posted as shipped.';
                }
            }
        }
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action("Re&lease")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Re&lease';
                    Image = ReleaseDoc;
                    ShortCutKey = 'Ctrl+F9';
                    ToolTip = 'Release the document to the next stage of processing. You must reopen the document before you can make changes to it.';

                    trigger OnAction()
                    var
                        ReleaseWhseShptDoc: Codeunit "Whse.-Shipment Release";
                    begin
                        CurrPage.Update(true);
                        if Rec.Status = Rec.Status::Open then
                            ReleaseWhseShptDoc.Release(Rec);
                    end;
                }
                action("Re&open")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Re&open';
                    Image = ReOpen;
                    ToolTip = 'Reopen the document for additional warehouse activity.';

                    trigger OnAction()
                    var
                        ReleaseWhseShptDoc: Codeunit "Whse.-Shipment Release";
                    begin
                        ReleaseWhseShptDoc.Reopen(Rec);
                    end;
                }
            }
            group("Posting")
            {
                Caption = 'Posting';
                Image = Post;
                action("Post Shipment")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Post Shipment';
                    Ellipsis = true;
                    Image = PostOrder;
                    ShortCutKey = 'F9';
                    ToolTip = 'Post the items as shipped. Related pick documents are registered automatically.';

                    trigger OnAction()
                    begin
                        PostShipmentYesNo();
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
                        CurrPage.Update(false);
                    end;
                }
                action("Post and Print")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Post and Print';
                    Ellipsis = true;
                    Image = PostPrint;
                    ShortCutKey = 'Shift+F9';
                    ToolTip = 'Finalize and prepare to print the document or journal. The values and quantities are posted to the related accounts. A report request window where you can specify what to include on the print-out.';

                    trigger OnAction()
                    begin
                        PostShipmentPrintYesNo();
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                group(Category_Category4)
                {
                    Caption = 'Release', Comment = 'Generated from the PromotedActionCategories property index 3.';
                    ShowAs = SplitButton;

                    actionref("Re&lease_Promoted"; "Re&lease")
                    {
                    }
                    actionref("Re&open_Promoted"; "Re&open")
                    {
                    }
                }
                group(Category_Posting)
                {
                    Caption = 'Posting';
                    ShowAs = SplitButton;

                    actionref("Post Shipment_Promoted"; "Post Shipment")
                    {
                    }
                    actionref(PreviewPosting_Promoted; PreviewPosting)
                    {
                    }
                    actionref("Post and Print_Promoted"; "Post and Print")
                    {
                    }
                }
                group(Category_Shipment)
                {
                    Caption = 'Shipment';

                    actionref("Co&mments_Promoted"; "Co&mments")
                    {
                    }
                    actionref("Pick Lines_Promoted"; "Pick Lines")
                    {
                    }
                    actionref("Registered P&ick Lines_Promoted"; "Registered P&ick Lines")
                    {
                    }
                    actionref("Posted &Warehouse Shipments_Promoted"; "Posted &Warehouse Shipments")
                    {
                    }
                }
            }
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';
            }
        }
    }

    views
    {
        view(Released)
        {
            Caption = 'Released';
            Filters = where(Status = const(Released));
        }
        view(PartiallyPicked)
        {
            Caption = 'Partially Picked';
            Filters = where("Document Status" = const("Partially Picked"));
        }
        view(CompletelyPicked)
        {
            Caption = 'Completely Picked';
            Filters = where("Document Status" = const("Completely Picked"));
        }
        view(ShipmentsToday)
        {
            Caption = 'Shipments Today';
            Filters = where("Shipment Date" = filter('%workdate'), "Status" = const(Released));
        }
        view(PickedShipmentsToday)
        {
            Caption = 'Picked Shipments Today';
            Filters = where("Shipment Date" = filter('%workdate'), "Document Status" = filter('Partially Picked' | 'Completely Picked'));
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

    local procedure PostShipmentYesNo()
    var
        WhseShptLine: Record "Warehouse Shipment Line";
        WhsePostShipmentYesNo: Codeunit "Whse.-Post Shipment (Yes/No)";
    begin
        GetLinesForRec(WhseShptLine);
        WhsePostShipmentYesNo.Run(WhseShptLine);
    end;

    local procedure ShowPreview()
    var
        WhseShptLine: Record "Warehouse Shipment Line";
        SelectedWarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WhsePostShipmentYesNo: Codeunit "Whse.-Post Shipment (Yes/No)";
    begin
        CurrPage.SetSelectionFilter(SelectedWarehouseShipmentHeader);
        WhsePostShipmentYesNo.MessageIfPostingPreviewMultipleDocuments(SelectedWarehouseShipmentHeader, Rec."No.");
        GetLinesForRec(WhseShptLine);
        WhsePostShipmentYesNo.Preview(WhseShptLine);
    end;

    local procedure PostShipmentPrintYesNo()
    var
        WhseShptLine: Record "Warehouse Shipment Line";
        WhsePostShipmentAndPrint: Codeunit "Whse.-Post Shipment + Print";
    begin
        GetLinesForRec(WhseShptLine);
        WhsePostShipmentAndPrint.Run(WhseShptLine);
    end;

    local procedure GetLinesForRec(var WhseShptLine: Record "Warehouse Shipment Line")
    begin
        WhseShptLine.SetRange("No.", Rec."No.");
        WhseShptLine.FindSet();
    end;
}

