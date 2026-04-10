// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Assembly.Document;

using Microsoft.Assembly.Comment;
using Microsoft.Finance.Dimension;

page 942 "Blanket Assembly Orders"
{
    ApplicationArea = Assembly;
    Caption = 'Blanket Assembly Orders';
    CardPageID = "Blanket Assembly Order";
    DataCaptionFields = "No.";
    Editable = false;
    PageType = List;
    SourceTable = "Assembly Header";
    SourceTableView = where("Document Type" = filter("Blanket Order"));
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Document Type"; Rec."Document Type")
                {
                    ApplicationArea = Assembly;
                }
                field("No."; Rec."No.")
                {
                    ApplicationArea = Assembly;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Assembly;
                }
                field("Description 2"; Rec."Description 2")
                {
                    ApplicationArea = Assembly;
                    Visible = false;
                }
                field("Due Date"; Rec."Due Date")
                {
                    ApplicationArea = Assembly;
                }
                field("Starting Date"; Rec."Starting Date")
                {
                    ApplicationArea = Assembly;
                }
                field("Ending Date"; Rec."Ending Date")
                {
                    ApplicationArea = Assembly;
                }
                field("Assemble to Order"; Rec."Assemble to Order")
                {
                    ApplicationArea = Assembly;
                }
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = Assembly;
                }
                field("Unit Cost"; Rec."Unit Cost")
                {
                    ApplicationArea = Assembly;
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Location;
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = Planning;
                }
                field("Bin Code"; Rec."Bin Code")
                {
                    ApplicationArea = Warehouse;
                }
                field("Remaining Quantity"; Rec."Remaining Quantity")
                {
                    ApplicationArea = Assembly;
                }
            }
        }
        area(factboxes)
        {
            systempart(RecordLinks; Links)
            {
                ApplicationArea = RecordLinks;
                Caption = 'RecordLinks';
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
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
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        IsUnitCostEditable := not Rec.IsStandardCostItem();
    end;

    trigger OnOpenPage()
    begin
        IsUnitCostEditable := true;
    end;

    var
        IsUnitCostEditable: Boolean;
}
