// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Assembly.History;

using Microsoft.Assembly.Comment;
using Microsoft.Finance.Dimension;

page 924 "Posted Assembly Lines"
{
    ApplicationArea = Assembly;
    Caption = 'Posted Assembly Lines';
    Editable = false;
    PageType = List;
    SourceTable = "Posted Assembly Line";
    UsageCategory = History;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Document No."; Rec."Document No.")
                {
                }
                field("Line No."; Rec."Line No.")
                {
                    Visible = false;
                }
                field("Order No."; Rec."Order No.")
                {
                }
                field("Order Line No."; Rec."Order Line No.")
                {
                    Visible = false;
                }
                field(Type; Rec.Type)
                {
                }
                field("No."; Rec."No.")
                {
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = Planning;
                }
                field(Description; Rec.Description)
                {
                }
                field("Description 2"; Rec."Description 2")
                {
                    Visible = false;
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Location;
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                }
                field(Quantity; Rec.Quantity)
                {
                }
                field("Quantity per"; Rec."Quantity per")
                {
                }
                field("Bin Code"; Rec."Bin Code")
                {
                    ApplicationArea = Warehouse;
                    Visible = false;
                }
                field("Inventory Posting Group"; Rec."Inventory Posting Group")
                {
                    Visible = false;
                }
                field("Unit Cost"; Rec."Unit Cost")
                {
                }
                field("Cost Amount"; Rec."Cost Amount")
                {
                }
                field("Resource Usage Type"; Rec."Resource Usage Type")
                {
                }
                field("Gen. Bus. Posting Group"; Rec."Gen. Bus. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Qty. per Unit of Measure"; Rec."Qty. per Unit of Measure")
                {
                }
                field("Shortcut Dimension 1 Code"; Rec."Shortcut Dimension 1 Code")
                {
                    ApplicationArea = Dimensions;
                    Visible = false;
                }
                field("Shortcut Dimension 2 Code"; Rec."Shortcut Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;
                    Visible = false;
                }
            }
        }
        area(FactBoxes)
        {
            systempart(RecordLinks; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(RecordNotes; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
        area(Navigation)
        {
            group(Line)
            {
                Caption = 'Line';
                Image = Line;

                action("Show Document")
                {
                    ApplicationArea = Assembly;
                    Caption = 'Show Document';
                    Image = View;
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'Open the document that the selected line exists on.';

                    trigger OnAction()
                    begin
                        Rec.ShowAssemblyDocument();
                    end;
                }
                action("Item Tracking Lines")
                {
                    ApplicationArea = ItemTracking;
                    Caption = 'Item Tracking Lines';
                    Image = ItemTrackingLines;
                    ShortCutKey = 'Ctrl+Alt+I';
                    ToolTip = 'View or edit serial, lot and package numbers that are assigned to the item on the document or journal line.';

                    trigger OnAction()
                    begin
                        Rec.ShowItemTrackingLines();
                    end;
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
                action(Comments)
                {
                    ApplicationArea = Comments;
                    Caption = 'Comments';
                    Image = ViewComments;
                    RunObject = Page "Assembly Comment Sheet";
                    RunPageLink = "Document Type" = const("Posted Assembly"),
                                  "Document No." = field("Document No."),
                                  "Document Line No." = field("Line No.");
                    ToolTip = 'View or add comments for the record.';
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("Show Document_Promoted"; "Show Document")
                {
                }
                actionref("Item Tracking Lines_Promoted"; "Item Tracking Lines")
                {
                }
                actionref("Dimensions_Promoted"; "Dimensions")
                {
                }
                actionref("Comments_Promoted"; "Comments")
                {
                }
            }
        }
    }
}

