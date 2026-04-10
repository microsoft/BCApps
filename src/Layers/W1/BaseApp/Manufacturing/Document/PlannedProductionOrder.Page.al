// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Document;

using Microsoft.Finance.Dimension;
using Microsoft.Foundation.Attachment;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Requisition;
using Microsoft.Manufacturing.Reports;

page 99000813 "Planned Production Order"
{
    Caption = 'Planned Production Order';
    PageType = Document;
    RefreshOnActivate = true;
    SourceTable = "Production Order";
    SourceTableView = where(Status = const(Planned));

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("No."; Rec."No.")
                {
                    ApplicationArea = Manufacturing;
                    Importance = Promoted;
                    Lookup = false;

                    trigger OnAssistEdit()
                    begin
                        if Rec.AssistEdit(xRec) then
                            CurrPage.Update();
                    end;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Manufacturing;
                    Importance = Promoted;
                }
                field("Description 2"; Rec."Description 2")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies an additional part of the production order description.';
                }
                field("Source Type"; Rec."Source Type")
                {
                    ApplicationArea = Manufacturing;

                    trigger OnValidate()
                    begin
                        if xRec."Source Type" <> Rec."Source Type" then
                            Rec."Source No." := '';
                    end;
                }
                field("Source No."; Rec."Source No.")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the item number or number of the source document that the entry originates from.';

                    trigger OnValidate()
                    var
                        Item: Record "Item";
                    begin
                        if Rec."Variant Code" = '' then
                            VariantCodeMandatory := Item.IsVariantMandatory(Rec."Source Type" = Rec."Source Type"::Item, Rec."Source No.");
                    end;
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = Manufacturing;
                    Visible = false;
                    ShowMandatory = VariantCodeMandatory;

                    trigger OnValidate()
                    var
                        Item: Record "Item";
                    begin
                        if Rec."Variant Code" = '' then
                            VariantCodeMandatory := Item.IsVariantMandatory(Rec."Source Type" = Rec."Source Type"::Item, Rec."Source No.");
                    end;
                }
                field("Search Description"; Rec."Search Description")
                {
                    ApplicationArea = Manufacturing;
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = Manufacturing;
                    Importance = Promoted;
                }
                field("Due Date"; Rec."Due Date")
                {
                    ApplicationArea = Manufacturing;

                    trigger OnValidate()
                    begin
                        CurrPage.Update(false);
                    end;
                }
                field("Assigned User ID"; Rec."Assigned User ID")
                {
                    ApplicationArea = Manufacturing;
                }
                field("Last Date Modified"; Rec."Last Date Modified")
                {
                    ApplicationArea = Manufacturing;
                }
                field("Manual Scheduling"; Rec."Manual Scheduling")
                {
                    ApplicationArea = Manufacturing;
                    Importance = Additional;
                }
            }
            part(ProdOrderLines; "Planned Prod. Order Lines")
            {
                ApplicationArea = Manufacturing;
                SubPageLink = "Prod. Order No." = field("No.");
                UpdatePropagation = Both;
            }
            group(Schedule)
            {
                Caption = 'Schedule';
                field("Starting Date-Time"; Rec."Starting Date-Time")
                {
                    ApplicationArea = Manufacturing;
                    Importance = Promoted;

                    trigger OnValidate()
                    begin
                        CurrPage.Update(true);
                    end;
                }
                field("Ending Date-Time"; Rec."Ending Date-Time")
                {
                    ApplicationArea = Manufacturing;
                    Importance = Promoted;

                    trigger OnValidate()
                    begin
                        CurrPage.Update(true);
                    end;
                }
            }
            group(Posting)
            {
                Caption = 'Posting';
                field("Inventory Posting Group"; Rec."Inventory Posting Group")
                {
                    ApplicationArea = Manufacturing;
                    Importance = Promoted;
                }
                field("Gen. Prod. Posting Group"; Rec."Gen. Prod. Posting Group")
                {
                    ApplicationArea = Manufacturing;
                }
                field("Gen. Bus. Posting Group"; Rec."Gen. Bus. Posting Group")
                {
                    ApplicationArea = Manufacturing;
                }
                field("Shortcut Dimension 1 Code"; Rec."Shortcut Dimension 1 Code")
                {
                    ApplicationArea = Dimensions;

                    trigger OnValidate()
                    begin
                        ShortcutDimension1CodeOnAfterV();
                    end;
                }
                field("Shortcut Dimension 2 Code"; Rec."Shortcut Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;

                    trigger OnValidate()
                    begin
                        ShortcutDimension2CodeOnAfterV();
                    end;
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Location;
                    Importance = Promoted;
                }
                field("Bin Code"; Rec."Bin Code")
                {
                    ApplicationArea = Warehouse;
                    Importance = Promoted;
                }
            }
        }
        area(factboxes)
        {
            part("Attached Documents List"; "Doc. Attachment List Factbox")
            {
                ApplicationArea = Manufacturing;
                Caption = 'Documents';
                UpdatePropagation = Both;
                SubPageLink = "Table ID" = const(Database::"Production Order"),
                              "Document Type" = const("Planned Production Order"),
                              "No." = field("No.");
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
            group("O&rder")
            {
                Caption = 'O&rder';
                Image = "Order";
                action("Co&mments")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "Prod. Order Comment Sheet";
                    RunPageLink = Status = field(Status),
                                  "Prod. Order No." = field("No.");
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
                action(Statistics)
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Statistics';
                    Image = Statistics;
                    RunObject = Page "Production Order Statistics";
                    RunPageLink = Status = field(Status),
                                  "No." = field("No."),
                                  "Date Filter" = field("Date Filter");
                    ShortCutKey = 'F7';
                    ToolTip = 'View statistical information, such as the value of posted entries, for the record.';
                }
                action("Plannin&g")
                {
                    ApplicationArea = Planning;
                    Caption = 'Plannin&g';
                    Image = Planning;
                    ToolTip = 'Plan supply orders for the production order order by order.';

                    trigger OnAction()
                    var
                        OrderPlanning: Page "Order Planning";
                    begin
                        OrderPlanning.SetProdOrderDemand(Rec.Status.AsInteger(), Rec."No.");
                        OrderPlanning.RunModal();
                    end;
                }
                action(DocAttach)
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Attachments';
                    Image = Attach;
                    ToolTip = 'Add a file as an attachment. You can attach images as well as documents.';

                    trigger OnAction()
                    var
                        DocumentAttachmentDetails: Page "Document Attachment Details";
                        RecRef: RecordRef;
                    begin
                        RecRef.GetTable(Rec);
                        DocumentAttachmentDetails.OpenForRecRef(RecRef);
                        DocumentAttachmentDetails.RunModal();
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
                action("Re&fresh Production Order")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Re&fresh Production Order';
                    Ellipsis = true;
                    Image = Refresh;
                    ToolTip = 'Calculate changes made to the production order header without involving production BOM levels. The function calculates and initiates the values of the component lines and routing lines based on the master data defined in the assigned production BOM and routing, according to the order quantity and due date on the production order''s header.';

                    trigger OnAction()
                    var
                        ProdOrder: Record "Production Order";
                    begin
                        ProdOrder.SetRange(Status, Rec.Status);
                        ProdOrder.SetRange("No.", Rec."No.");
                        REPORT.RunModal(REPORT::"Refresh Production Order", true, true, ProdOrder);
                    end;
                }
                action("Re&plan")
                {
                    ApplicationArea = Planning;
                    Caption = 'Re&plan';
                    Ellipsis = true;
                    Image = Replan;
                    ToolTip = 'Calculate changes made to components and routings lines including items on lower production BOM levels for which it may generate new production orders.';

                    trigger OnAction()
                    var
                        ProdOrder: Record "Production Order";
                    begin
                        ProdOrder.SetRange(Status, Rec.Status);
                        ProdOrder.SetRange("No.", Rec."No.");
                        REPORT.RunModal(REPORT::"Replan Production Order", true, true, ProdOrder);
                    end;
                }
                action("Change &Status")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Change &Status';
                    Ellipsis = true;
                    Image = ChangeStatus;
                    ToolTip = 'Change the production order to another status, such as Released.';

                    trigger OnAction()
                    begin
                        CurrPage.Update();
                        CODEUNIT.Run(CODEUNIT::"Prod. Order Status Management", Rec);
                    end;
                }
                action("&Update Unit Cost")
                {
                    ApplicationArea = Manufacturing;
                    Caption = '&Update Unit Cost';
                    Ellipsis = true;
                    Image = UpdateUnitCost;
                    ToolTip = 'Update the cost of the parent item per changes to the production BOM or routing.';

                    trigger OnAction()
                    var
                        ProdOrder: Record "Production Order";
                    begin
                        ProdOrder.SetRange(Status, Rec.Status);
                        ProdOrder.SetRange("No.", Rec."No.");

                        REPORT.RunModal(REPORT::"Update Unit Cost", true, true, ProdOrder);
                    end;
                }
                action("C&opy Prod. Order Document")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'C&opy Prod. Order Document';
                    Ellipsis = true;
                    Image = CopyDocument;
                    ToolTip = 'Copy information from an existing production order record to a new one. This can be done regardless of the status type of the production order. You can, for example, copy from a released production order to a new planned production order. Note that before you start to copy, you have to create the new record.';

                    trigger OnAction()
                    var
                        CopyProdOrderDoc: Report "Copy Production Order Document";
                    begin
                        CopyProdOrderDoc.SetProdOrder(Rec);
                        CopyProdOrderDoc.RunModal();
                        Clear(CopyProdOrderDoc);
                    end;
                }
            }
        }
        area(reporting)
        {
            action("Subcontractor - Dispatch List")
            {
                ApplicationArea = Manufacturing;
                Caption = 'Subcontractor - Dispatch List';
                Image = "Report";
                RunObject = Report "Subcontractor - Dispatch List";
                ToolTip = 'View the list of material to be sent to manufacturing subcontractors.';
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';

                actionref("Re&fresh Production Order_Promoted"; "Re&fresh Production Order")
                {
                }
                actionref("Change &Status_Promoted"; "Change &Status")
                {
                }
                actionref("Re&plan_Promoted"; "Re&plan")
                {
                }
            }
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';

                actionref("Subcontractor - Dispatch List_Promoted"; "Subcontractor - Dispatch List")
                {
                }
            }
            group(Category_Category4)
            {
                Caption = 'Order', Comment = 'Generated from the PromotedActionCategories property index 3.';

                actionref(Dimensions_Promoted; Dimensions)
                {
                }
                actionref(Statistics_Promoted; Statistics)
                {
                }
                actionref("Co&mments_Promoted"; "Co&mments")
                {
                }
                actionref(DocAttach_Promoted; DocAttach)
                {
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    var
        Item: Record Item;
    begin
        if Rec."Variant Code" = '' then
            VariantCodeMandatory := Item.IsVariantMandatory(Rec."Source Type" = Rec."Source Type"::Item, Rec."Source No.");
    end;

    var
        VariantCodeMandatory: Boolean;

    local procedure ShortcutDimension1CodeOnAfterV()
    begin
        CurrPage.ProdOrderLines.PAGE.UpdateForm(true);
    end;

    local procedure ShortcutDimension2CodeOnAfterV()
    begin
        CurrPage.ProdOrderLines.PAGE.UpdateForm(true);
    end;
}

