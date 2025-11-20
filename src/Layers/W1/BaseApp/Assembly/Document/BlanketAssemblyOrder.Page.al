// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Assembly.Document;

using Microsoft.Assembly.Comment;
using Microsoft.Finance.Dimension;
using Microsoft.Inventory.Item;

page 940 "Blanket Assembly Order"
{
    Caption = 'Blanket Assembly Order';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = Document;
    SourceTable = "Assembly Header";
    SourceTableView = sorting("Document Type", "No.")
                      order(ascending)
                      where("Document Type" = const("Blanket Order"));

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("No."; Rec."No.")
                {
                    ApplicationArea = Assembly;
                    AssistEdit = true;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';

                    trigger OnAssistEdit()
                    begin
                        if Rec.AssistEdit(xRec) then
                            CurrPage.Update();
                    end;
                }
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = IsAsmToOrderEditable;
                    Importance = Promoted;
                    TableRelation = Item."No." where("Assembly BOM" = const(true));
                    ToolTip = 'Specifies the number of the item that is being assembled with the assembly order.';

                    trigger OnValidate()
                    var
                        Item: Record "Item";
                    begin
                        if Rec."Variant Code" = '' then
                            VariantCodeMandatory := Item.IsVariantMandatory(true, Rec."Item No.");
                    end;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies the description of the assembly item.';
                }
                field("Description 2"; Rec."Description 2")
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies information in addition to the description.';
                    Visible = false;
                }
                group(Control33)
                {
                    ShowCaption = false;
                    field(Quantity; Rec.Quantity)
                    {
                        ApplicationArea = Assembly;
                        Editable = IsAsmToOrderEditable;
                        Importance = Promoted;
                        ToolTip = 'Specifies how many units of the assembly item that you expect to assemble with the assembly order.';
                    }
                    field("Unit of Measure Code"; Rec."Unit of Measure Code")
                    {
                        ApplicationArea = Assembly;
                        Editable = IsAsmToOrderEditable;
                        ToolTip = 'Specifies how each unit of the item or resource is measured, such as in pieces or hours. By default, the value in the Base Unit of Measure field on the item or resource card is inserted.';
                    }
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = Assembly;
                    Importance = Promoted;
                    ToolTip = 'Specifies the date on which the assembly order is posted.';
                }
                field("Due Date"; Rec."Due Date")
                {
                    ApplicationArea = Assembly;
                    Editable = IsAsmToOrderEditable;
                    Importance = Promoted;
                    ToolTip = 'Specifies the date when the assembled item is due to be available for use.';
                }
                field("Starting Date"; Rec."Starting Date")
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies the date when the assembly order is expected to start.';
                }
                field("Ending Date"; Rec."Ending Date")
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies the date when the assembly order is expected to finish.';
                }
                field("Assemble to Order"; Rec."Assemble to Order")
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies if the assembly order is linked to a sales order, which indicates that the item is assembled to order.';

                    trigger OnDrillDown()
                    begin
                        Rec.ShowAsmToOrder();
                    end;
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies if the document is open, waiting to be approved, invoiced for prepayment, or released to the next stage of processing.';
                }
            }
            part(Lines; "Blanket Assembly Order Subform")
            {
                ApplicationArea = Assembly;
                Caption = 'Lines';
                SubPageLink = "Document Type" = field("Document Type"),
                              "Document No." = field("No.");
            }
            group(Posting)
            {
                Caption = 'Posting';
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = Planning;
                    Editable = IsAsmToOrderEditable;
                    Importance = Promoted;
                    ToolTip = 'Specifies the variant of the item on the line.';
                    ShowMandatory = VariantCodeMandatory;

                    trigger OnValidate()
                    var
                        Item: Record "Item";
                    begin
                        if Rec."Variant Code" = '' then
                            VariantCodeMandatory := Item.IsVariantMandatory(true, Rec."Item No.");
                    end;
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Location;
                    Editable = IsAsmToOrderEditable;
                    Importance = Promoted;
                    ToolTip = 'Specifies the location to which you want to post output of the assembly item.';
                }
                field("Bin Code"; Rec."Bin Code")
                {
                    ApplicationArea = Warehouse;
                    Editable = IsAsmToOrderEditable;
                    ToolTip = 'Specifies the bin the assembly item is posted to as output and from where it is taken to storage or shipped if it is assembled to a sales order.';
                }
                field("Unit Cost"; Rec."Unit Cost")
                {
                    ApplicationArea = Assembly;
                    Editable = IsUnitCostEditable;
                    ToolTip = 'Specifies the cost of one unit of the item or resource on the line.';
                }
                field("Cost Amount"; Rec."Cost Amount")
                {
                    ApplicationArea = Assembly;
                    Editable = IsUnitCostEditable;
                    ToolTip = 'Specifies the total unit cost of the assembly order.';
                }
                field("Assigned User ID"; Rec."Assigned User ID")
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies the ID of the user who is responsible for the document.';
                    Visible = false;
                }
                field("Shortcut Dimension 1 Code"; Rec."Shortcut Dimension 1 Code")
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies the code for Shortcut Dimension 1, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
                }
                field("Shortcut Dimension 2 Code"; Rec."Shortcut Dimension 2 Code")
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies the code for Shortcut Dimension 2, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
                }
            }
        }
        area(factboxes)
        {
            part(Control11; "Assembly Item - Details")
            {
                ApplicationArea = Assembly;
                SubPageLink = "No." = field("Item No.");
            }
            part(Control44; "Component - Item Details")
            {
                ApplicationArea = Assembly;
                Provider = Lines;
                SubPageLink = "No." = field("No.");
            }
            part(Control43; "Component - Resource Details")
            {
                ApplicationArea = Assembly;
                Provider = Lines;
                SubPageLink = "No." = field("No.");
            }
            systempart(Control8; Links)
            {
                ApplicationArea = RecordLinks;
            }
            systempart(Control9; Notes)
            {
                ApplicationArea = Notes;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            action(Statistics)
            {
                ApplicationArea = Assembly;
                Caption = 'Statistics';
                Image = Statistics;
                ShortCutKey = 'F7';
                ToolTip = 'View statistical information, such as the value of posted entries, for the record.';
                RunObject = Page "Assembly Order Statistics";
                RunPageOnRec = true;
            }
            action(Dimensions)
            {
                AccessByPermission = TableData Dimension = R;
                ApplicationArea = Dimensions;
                Caption = 'Dimensions';
                Enabled = Rec."No." <> '';
                Image = Dimensions;
                ShortCutKey = 'Alt+D';
                ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to sales and purchase documents to distribute costs and analyze transaction history.';

                trigger OnAction()
                begin
                    Rec.ShowDimensions();
                end;
            }
            action("Assembly BOM")
            {
                ApplicationArea = Assembly;
                Caption = 'Assembly BOM';
                Image = AssemblyBOM;
                ToolTip = 'View or edit the bill of material that specifies which items and resources are required to assemble the assembly item.';

                trigger OnAction()
                begin
                    Rec.ShowAssemblyList();
                end;
            }
            action(Comments)
            {
                ApplicationArea = Comments;
                Caption = 'Comments';
                Image = ViewComments;
                RunObject = Page "Assembly Comment Sheet";
                RunPageLink = "Document Type" = field("Document Type"),
                              "Document No." = field("No."),
                              "Document Line No." = const(0);
                ToolTip = 'View or add comments for the record.';
            }
        }
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action("Update Unit Cost")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Update Unit Cost';
                    Enabled = IsUnitCostEditable;
                    Image = UpdateUnitCost;
                    ToolTip = 'Update the cost of the parent item per changes to the assembly BOM.';

                    trigger OnAction()
                    begin
                        Rec.UpdateUnitCost();
                    end;
                }
                action("Refresh Lines")
                {
                    ApplicationArea = Assembly;
                    Caption = 'Refresh Lines';
                    Image = RefreshLines;
                    ToolTip = 'Update information on the lines according to changes that you made on the header.';

                    trigger OnAction()
                    begin
                        Rec.RefreshBOM();
                        CurrPage.Update();
                    end;
                }
                action("Show Availability")
                {
                    ApplicationArea = Assembly;
                    Caption = 'Show Availability';
                    Image = ItemAvailbyLoc;
                    ToolTip = 'View how many of the assembly order quantity can be assembled by the due date based on availability of the required components. This is shown in the Able to Assemble field. ';

                    trigger OnAction()
                    begin
                        Rec.ShowAvailability();
                    end;
                }
                action("Refresh availability warnings")
                {
                    ApplicationArea = Assembly;
                    Caption = 'Refresh Availability';
                    Image = RefreshLines;
                    ToolTip = 'Check items availability and refresh warnings';
                    trigger OnAction()
                    begin
                        Rec.UpdateWarningOnLines();
                    end;
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    var
        Item: Record Item;
    begin
        IsUnitCostEditable := not Rec.IsStandardCostItem();
        IsAsmToOrderEditable := not Rec.IsAsmToOrder();
        if Rec."Variant Code" = '' then
            VariantCodeMandatory := Item.IsVariantMandatory(true, Rec."Item No.");
    end;

    trigger OnOpenPage()
    begin
        IsUnitCostEditable := true;
        IsAsmToOrderEditable := true;
    end;

    var
        VariantCodeMandatory: Boolean;

    protected var
        IsUnitCostEditable: Boolean;
        IsAsmToOrderEditable: Boolean;
}
