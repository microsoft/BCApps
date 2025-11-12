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
using Microsoft.Warehouse.Request;
using Microsoft.Warehouse.Setup;

page 7335 "Warehouse Shipment"
{
    Caption = 'Warehouse Shipment';
    PageType = Document;
    PopulateAllFields = true;
    RefreshOnActivate = true;
    SourceTable = "Warehouse Shipment Header";

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
                    Importance = Promoted;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';

                    trigger OnAssistEdit()
                    begin
                        if Rec.AssistEdit(xRec) then
                            CurrPage.Update();
                    end;
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Location;
                    ShowMandatory = true;
                    ToolTip = 'Specifies the code of the location from which the items are being shipped.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        CurrPage.SaveRecord();
                        Rec.LookupLocation(Rec);
                        CurrPage.Update(true);
                        SetBinFieldsVisibility(true);
                    end;

                    trigger OnValidate()
                    begin
                        CurrPage.Update(true);
                        SetBinFieldsVisibility(true);
                    end;
                }
                group(BinFields)
                {
                    ShowCaption = false;
                    Visible = not HideBinFields;
                    field("Zone Code"; Rec."Zone Code")
                    {
                        ApplicationArea = Warehouse;
                        ToolTip = 'Specifies the code of the zone on this shipment header.';
                    }
                    field("Bin Code"; Rec."Bin Code")
                    {
                        ApplicationArea = Warehouse;
                        ToolTip = 'Specifies the bin where the items are picked or put away.';
                    }
                }
                field("Document Status"; Rec."Document Status")
                {
                    ApplicationArea = Warehouse;
                    Importance = Promoted;
                    ToolTip = 'Specifies the progress level of warehouse handling on lines in the warehouse shipment.';
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the status of the shipment and is filled in by the program.';
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies a posting date. If you enter a date, the posting date of the source documents is updated during posting.';
                }
                field("Assigned User ID"; Rec."Assigned User ID")
                {
                    ApplicationArea = Warehouse;
                    Importance = Promoted;
                    ToolTip = 'Specifies the ID of the user who is responsible for the document.';
                }
                field("Assignment Date"; Rec."Assignment Date")
                {
                    ApplicationArea = Warehouse;
                    Editable = false;
                    ToolTip = 'Specifies the date when the user was assigned the activity.';
                }
                field("Assignment Time"; Rec."Assignment Time")
                {
                    ApplicationArea = Warehouse;
                    Editable = false;
                    ToolTip = 'Specifies the time when the user was assigned the activity.';
                }
                field("Sorting Method"; Rec."Sorting Method")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the method by which the shipments are sorted.';

                    trigger OnValidate()
                    begin
                        SortingMethodOnAfterValidate();
                    end;
                }
            }
            part(WhseShptLines; "Whse. Shipment Subform")
            {
                ApplicationArea = Warehouse;
                Editable = IsShipmentLinesEditable;
                Enabled = IsShipmentLinesEditable;
                SubPageLink = "No." = field("No.");
                SubPageView = sorting("No.", "Sorting Sequence No.");
            }
            group(Shipping)
            {
                Caption = 'Shipping';
                field("External Document No."; Rec."External Document No.")
                {
                    ApplicationArea = Warehouse;
                    Importance = Promoted;
                    ToolTip = 'Specifies a document number that refers to the customer''s or vendor''s numbering system. If you enter a value, the source document will be updated during posting. If this field is blank, the original document number is used.';
                }
                field("Shipment Date"; Rec."Shipment Date")
                {
                    ApplicationArea = Warehouse;
                    Importance = Promoted;
                    ToolTip = 'Specifies the shipment date of the warehouse shipment. If you enter a date, the source document will be updated during posting. If this field is blank, the original shipment date of the source document is used.';
                }
                field("Shipping Agent Code"; Rec."Shipping Agent Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the code for the shipping agent who is transporting the items. This value is not carried over from the source documents because one warehouse shipment can contain lines from many source documents. If you enter a value, the source document will be updated during posting. If this field is blank, the original shipping agent of the source document is used.';
                }
                field("Shipping Agent Service Code"; Rec."Shipping Agent Service Code")
                {
                    ApplicationArea = Warehouse;
                    Importance = Promoted;
                    ToolTip = 'Specifies the code for the service, such as a one-day delivery, that is offered by the shipping agent. This value is not carried over from the source documents because one warehouse shipment can contain lines from many source documents. If you enter a value, the source document will be updated during posting. If this field is blank, the original shipping agent service of the source document is used.';
                }
                field("Shipment Method Code"; Rec."Shipment Method Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the delivery conditions of the related shipment, such as free on board (FOB). This value is not carried over from the source documents because one warehouse shipment can contain lines from many source documents. If you enter a code, the source document will be updated during posting. If this field is blank, the original shipment method of the source document is used.';
                }
            }
        }
        area(factboxes)
        {
            part(Control1901796907; "Item Warehouse FactBox")
            {
                ApplicationArea = Warehouse;
                Provider = WhseShptLines;
                SubPageLink = "No." = field("Item No.");
                Visible = true;
            }
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
                    ApplicationArea = Comments;
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
                action("Posted &Whse. Shipments")
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
                action("Use Filters to Get Src. Docs.")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Use Filters to Get Src. Docs.';
                    Ellipsis = true;
                    Image = UseFilters;
                    ToolTip = 'retrieve the released source document lines that define which items to receive or ship.';

                    trigger OnAction()
                    var
                        GetSourceDocOutbound: Codeunit "Get Source Doc. Outbound";
                    begin
                        OnBeforeOnActionUseFilterstoGetSrcDocs(Rec);
                        Rec.TestField(Status, Rec.Status::Open);
                        GetSourceDocOutbound.GetOutboundDocs(Rec);
                    end;
                }
                action("Get Source Documents")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Get Source Documents';
                    Ellipsis = true;
                    Image = GetSourceDoc;
                    ShortCutKey = 'Shift+F11';
                    ToolTip = 'Open the list of released source documents, such as sales orders, to select the document to ship items for. ';

                    trigger OnAction()
                    var
                        GetSourceDocOutbound: Codeunit "Get Source Doc. Outbound";
                    begin
                        Rec.TestField(Status, Rec.Status::Open);
                        GetSourceDocOutbound.GetSingleOutboundDoc(Rec);
                    end;
                }
                separator(Action44)
                {
                }
                action("Re&lease")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Re&lease';
                    Enabled = Rec.Status <> Rec.Status::Released;
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
                    Enabled = Rec.Status <> Rec.Status::Open;
                    Image = ReOpen;
                    ToolTip = 'Reopen the document for additional warehouse activity.';

                    trigger OnAction()
                    var
                        ReleaseWhseShptDoc: Codeunit "Whse.-Shipment Release";
                    begin
                        ReleaseWhseShptDoc.Reopen(Rec);
                    end;
                }
                separator(Action17)
                {
                }
                action("Autofill Qty. to Ship")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Autofill Qty. to Ship';
                    Image = AutofillQtyToHandle;
                    ToolTip = 'Have the system enter the outstanding quantity in the Qty. to Ship field.';

                    trigger OnAction()
                    begin
                        AutofillQtyToHandle();
                    end;
                }
                action("Delete Qty. to Ship")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Delete Qty. to Ship';
                    Image = DeleteQtyToHandle;
                    ToolTip = 'Have the system clear the value in the Qty. To Ship field. ';

                    trigger OnAction()
                    begin
                        DeleteQtyToHandle();
                    end;
                }
                separator(Action51)
                {
                }
                action("Create Pick")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Create Pick';
                    Ellipsis = true;
                    Image = CreateInventoryPickup;
                    ToolTip = 'Create a warehouse pick for the items to be shipped.';

                    trigger OnAction()
                    begin
                        CurrPage.Update(true);
                        CurrPage.WhseShptLines.PAGE.PickCreate();
                    end;
                }
            }
            group("P&osting")
            {
                Caption = 'P&osting';
                Image = Post;
                action("P&ost Shipment")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'P&ost Shipment';
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
                action("Post and &Print")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Post and &Print';
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
            action("&Print")
            {
                ApplicationArea = Warehouse;
                Caption = '&Print';
                Ellipsis = true;
                Image = Print;
                ToolTip = 'Prepare to print the document. A report request window for the document opens where you can specify what to include on the print-out.';

                trigger OnAction()
                begin
                    WhseDocPrint.PrintShptHeader(Rec);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';

                actionref("Create Pick_Promoted"; "Create Pick")
                {
                }
                group(Category_Category6)
                {
                    Caption = 'Posting', Comment = 'Generated from the PromotedActionCategories property index 5.';
                    ShowAs = SplitButton;

                    actionref("P&ost Shipment_Promoted"; "P&ost Shipment")
                    {
                    }
                    actionref(PreviewPosting_Promoted; PreviewPosting)
                    {
                    }
                    actionref("Post and &Print_Promoted"; "Post and &Print")
                    {
                    }
                }
                group(Category_Category5)
                {
                    Caption = 'Release', Comment = 'Generated from the PromotedActionCategories property index 4.';
                    ShowAs = SplitButton;

                    actionref("Re&lease_Promoted"; "Re&lease")
                    {
                    }
                    actionref("Re&open_Promoted"; "Re&open")
                    {
                    }
                }
                group("Category_Qty. to Ship")
                {
                    Caption = 'Qty. to Ship';
                    ShowAs = SplitButton;

                    actionref("Autofill Qty. to Ship_Promoted"; "Autofill Qty. to Ship")
                    {
                    }
                    actionref("Delete Qty. to Ship_Promoted"; "Delete Qty. to Ship")
                    {
                    }
                }
            }
            group(Category_Prepare)
            {
                Caption = 'Prepare';

                actionref("Get Source Documents_Promoted"; "Get Source Documents")
                {
                }
                actionref("Use Filters to Get Src. Docs._Promoted"; "Use Filters to Get Src. Docs.")
                {
                }
            }
            group(Category_Category4)
            {
                Caption = 'Print/Send', Comment = 'Generated from the PromotedActionCategories property index 3.';

                actionref("&Print_Promoted"; "&Print")
                {
                }
            }
            group(Category_Category7)
            {
                Caption = 'Shipment', Comment = 'Generated from the PromotedActionCategories property index 6.';

                actionref("Co&mments_Promoted"; "Co&mments")
                {
                }

                separator(Navigate_Separator)
                {
                }

                actionref("Posted &Whse. Shipments_Promoted"; "Posted &Whse. Shipments")
                {
                }
                actionref("Pick Lines_Promoted"; "Pick Lines")
                {
                }
                actionref("Registered P&ick Lines_Promoted"; "Registered P&ick Lines")
                {
                }
            }
            group(Category_Category8)
            {
                Caption = 'Navigate', Comment = 'Generated from the PromotedActionCategories property index 7.';
            }
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';
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

        ActivateControls();
        SetBinFieldsVisibility(false); // Don't allow procedure to update page since it's not even loaded yet
    end;

    trigger OnAfterGetCurrRecord()
    begin
        ActivateControls();
        SetBinFieldsVisibility(true);
    end;

    var
        WhseDocPrint: Codeunit "Warehouse Document-Print";
        IsShipmentLinesEditable: Boolean;
        HideBinFields: Boolean;
        LocationCodeWhenHideBinLastChecked: Code[20];

    local procedure SetBinFieldsVisibility(AllowSubFormUpdate: Boolean)
    var
        BinVisiblityNeedsUpdate: Boolean;
    begin
        BinVisiblityNeedsUpdate := CheckBinFieldsVisibility();
        CurrPage.WhseShptLines.Page.SetHideBinFields(HideBinFields);
        if not BinVisiblityNeedsUpdate or not AllowSubFormUpdate then
            exit;

        CurrPage.WhseShptLines.Page.Update(false); // Visibility on the subform must be updated via. page update, since fields are in repeater
    end;

    local procedure CheckBinFieldsVisibility() BinVisiblityNeedsUpdate: Boolean
    var
        HideBinFieldsLocal: Boolean;
    begin
        if (Rec."Location Code" = LocationCodeWhenHideBinLastChecked) then
            exit(false);

        if Rec."Location Code" <> '' then
            HideBinFieldsLocal := not Rec.BinCodeMandatory();

        LocationCodeWhenHideBinLastChecked := Rec."Location Code";
        BinVisiblityNeedsUpdate := HideBinFieldsLocal <> HideBinFields;
        HideBinFields := HideBinFieldsLocal; // Visibility on this page is automatically updated via. field group visibility
    end;

    local procedure ActivateControls()
    begin
        IsShipmentLinesEditable := Rec.ShipmentLinesEditable();
    end;

    local procedure AutofillQtyToHandle()
    begin
        CurrPage.WhseShptLines.PAGE.AutofillQtyToHandle();
    end;

    local procedure DeleteQtyToHandle()
    begin
        CurrPage.WhseShptLines.PAGE.DeleteQtyToHandle();
    end;

    local procedure PostShipmentYesNo()
    begin
        CurrPage.WhseShptLines.PAGE.PostShipmentYesNo();
    end;

    local procedure ShowPreview()
    begin
        CurrPage.WhseShptLines.Page.Preview();
    end;

    local procedure PostShipmentPrintYesNo()
    begin
        CurrPage.WhseShptLines.PAGE.PostShipmentPrintYesNo();
    end;

    local procedure SortingMethodOnAfterValidate()
    begin
        CurrPage.Update();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnActionUseFilterstoGetSrcDocs(var WarehouseShipmentHeader: Record "Warehouse Shipment Header")
    begin
    end;
}

