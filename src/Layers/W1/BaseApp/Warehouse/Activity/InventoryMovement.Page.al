// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Activity;

using Microsoft.Warehouse.Comment;
using Microsoft.Warehouse.InventoryDocument;
using Microsoft.Warehouse.Journal;
using Microsoft.Warehouse.Reports;
using Microsoft.Warehouse.Structure;

page 7382 "Inventory Movement"
{
    Caption = 'Inventory Movement';
    PageType = Document;
    RefreshOnActivate = true;
    SaveValues = true;
    SourceTable = "Warehouse Activity Header";
    SourceTableView = where(Type = const("Invt. Movement"));

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
                    ToolTip = 'Specifies the code for the location where the warehouse activity takes place.';
                }
                field(SourceDocument; Rec."Source Document")
                {
                    ApplicationArea = Warehouse;
                    DrillDown = false;
                    Lookup = false;
                    ToolTip = 'Specifies the type of document that the line relates to.';
                }
                field("Source No."; Rec."Source No.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the number of the source document that the entry originates from.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        CreateInvtPickMovement: Codeunit "Create Inventory Pick/Movement";
                    begin
                        if Rec.LineExist() then
                            Error(Text001);

                        CreateInvtPickMovement.SetInvtMovement(true);
                        CreateInvtPickMovement.Run(Rec);
                        CurrPage.Update();
                        CurrPage.WhseActivityLines.PAGE.UpdateForm();
                    end;

                    trigger OnValidate()
                    begin
                        SourceNoOnAfterValidate();
                    end;
                }
                field("Destination No."; Rec."Destination No.")
                {
                    ApplicationArea = Warehouse;
                    CaptionClass = Format(WMSMgt.GetCaptionClass(Rec."Destination Type", Rec."Source Document", 0));
                    Editable = false;
                    ToolTip = 'Specifies the number or the code of the customer or vendor that the line is linked to.';
                }
#pragma warning disable AA0100
                field("WMSMgt.GetDestinationName(""Destination Type"",""Destination No."")"; WMSMgt.GetDestinationEntityName(Rec."Destination Type", Rec."Destination No."))
#pragma warning restore AA0100
                {
                    ApplicationArea = Warehouse;
                    CaptionClass = Format(WMSMgt.GetCaptionClass(Rec."Destination Type", Rec."Source Document", 1));
                    Caption = 'Name';
                    Editable = false;
                    ToolTip = 'Specifies the name of the destination for the inventory movement.';
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the date when the warehouse activity should be recorded as being posted.';
                }
                field("External Document No."; Rec."External Document No.")
                {
                    ApplicationArea = Warehouse;
                    CaptionClass = Format(WMSMgt.GetCaptionClass(Rec."Destination Type", Rec."Source Document", 2));
                    ToolTip = 'Specifies a document number that refers to the customer''s or vendor''s numbering system.';
                }
                field("External Document No.2"; Rec."External Document No.2")
                {
                    ApplicationArea = Warehouse;
                    CaptionClass = Format(WMSMgt.GetCaptionClass(Rec."Destination Type", Rec."Source Document", 3));
                    ToolTip = 'Specifies an additional part of the document number that refers to the customer''s or vendor''s numbering system.';
                }
                field("Sorting Method"; Rec."Sorting Method")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the method by which the lines are sorted on the warehouse header, such as Item or Document.';

                    trigger OnValidate()
                    begin
                        SortingMethodOnAfterValidate();
                    end;
                }
                field("Assigned User ID"; Rec."Assigned User ID")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the ID of the user who is responsible for the document.';
                    Visible = false;
                }
            }
            part(WhseActivityLines; "Invt. Movement Subform")
            {
                ApplicationArea = Warehouse;
                SubPageLink = "Activity Type" = field(Type),
                              "No." = field("No.");
                SubPageView = sorting("Activity Type", "No.", "Sorting Sequence No.")
                              where(Breakbulk = const(false));
            }
        }
        area(factboxes)
        {
            part(Control3; "Lot Numbers by Bin FactBox")
            {
                ApplicationArea = ItemTracking;
                Provider = WhseActivityLines;
                SubPageLink = "Item No." = field("Item No."),
                              "Variant Code" = field("Variant Code"),
                              "Location Code" = field("Location Code");
                Visible = false;
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
                action("Registered Invt. Movements")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Registered Invt. Movements';
                    Image = RegisteredDocs;
                    RunObject = Page "Registered Invt. Movement List";
                    RunPageLink = "Invt. Movement No." = field("No.");
                    RunPageView = sorting("Invt. Movement No.");
                    ToolTip = 'View the list of completed inventory movements.';
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
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action(GetSourceDocument)
                {
                    ApplicationArea = Warehouse;
                    Caption = '&Get Source Document';
                    Ellipsis = true;
                    Image = GetSourceDoc;
                    ShortCutKey = 'Ctrl+F7';
                    ToolTip = 'Select the source document that you want to move items for.';

                    trigger OnAction()
                    var
                        CreateInvtPickMovement: Codeunit "Create Inventory Pick/Movement";
                    begin
                        if Rec.LineExist() then
                            Error(Text001);
                        CreateInvtPickMovement.SetInvtMovement(true);
                        CreateInvtPickMovement.Run(Rec);
                    end;
                }
                action("Autofill Qty. to Handle")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Autofill Qty. to Handle';
                    Image = AutofillQtyToHandle;
                    ToolTip = 'Have the system enter the outstanding quantity in the Qty. to Handle field.';

                    trigger OnAction()
                    begin
                        AutofillQtyToHandle();
                    end;
                }
                action("Delete Qty. to Handle")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Delete Qty. to Handle';
                    Image = DeleteQtyToHandle;
                    ToolTip = 'Have the system clear the value in the Qty. To Handle field. ';

                    trigger OnAction()
                    begin
                        DeleteQtyToHandle();
                    end;
                }
            }
            group("&Registering")
            {
                Caption = '&Registering';
                Image = PostOrder;
                action("&Register Invt. Movement")
                {
                    ApplicationArea = Warehouse;
                    Caption = '&Register Invt. Movement';
                    Image = RegisterPutAway;
                    ShortCutKey = 'F9';
                    ToolTip = 'Register the movement of items between bins in a basic warehouse configuration.';

                    trigger OnAction()
                    begin
                        RegisterActivityYesNo();
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
                    WhseDocPrint.PrintInvtMovementHeader(Rec, false);
                end;
            }
        }
        area(reporting)
        {
            action("Movement List")
            {
                ApplicationArea = Warehouse;
                Caption = 'Movement List';
                Image = "Report";
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = "Report";
                RunObject = Report "Movement List";
                ToolTip = 'View the list of ongoing movements between bins according to a basic warehouse configuration.';
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';

                actionref("&Register Invt. Movement_Promoted"; "&Register Invt. Movement")
                {
                }
                group("Category_Qty. to Handle")
                {
                    Caption = 'Qty. to Handle';
                    ShowAs = SplitButton;

                    actionref("Autofill Qty. to Handle_Promoted"; "Autofill Qty. to Handle")
                    {
                    }
                    actionref("Delete Qty. to Handle_Promoted"; "Delete Qty. to Handle")
                    {
                    }
                }
                actionref("&Print_Promoted"; "&Print")
                {
                }
                actionref(GetSourceDocument_Promoted; GetSourceDocument)
                {
                }
            }
            group(Category_Category4)
            {
                Caption = 'Print/Send', Comment = 'Generated from the PromotedActionCategories property index 3.';

            }
            group(Category_Category5)
            {
                Caption = 'Movement', Comment = 'Generated from the PromotedActionCategories property index 4.';

                actionref("Co&mments_Promoted"; "Co&mments")
                {
                }
            }
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';
            }
        }
    }

    trigger OnDeleteRecord(): Boolean
    begin
        CurrPage.Update();
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Rec."Location Code" := xRec."Location Code";
    end;

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
        WMSMgt: Codeunit "WMS Management";
#pragma warning disable AA0074
        Text001: Label 'You cannot use this function if the lines already exist.';
#pragma warning restore AA0074

    local procedure AutofillQtyToHandle()
    begin
        CurrPage.WhseActivityLines.PAGE.AutofillQtyToHandle();
    end;

    local procedure DeleteQtyToHandle()
    begin
        CurrPage.WhseActivityLines.PAGE.DeleteQtyToHandle();
    end;

    local procedure RegisterActivityYesNo()
    begin
        CurrPage.WhseActivityLines.PAGE.RegisterActivityYesNo();
    end;

    local procedure SourceNoOnAfterValidate()
    begin
        CurrPage.Update();
        CurrPage.WhseActivityLines.PAGE.UpdateForm();
    end;

    local procedure SortingMethodOnAfterValidate()
    begin
        CurrPage.Update();
    end;
}

