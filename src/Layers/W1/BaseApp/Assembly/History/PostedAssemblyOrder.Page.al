// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Assembly.History;

using Microsoft.Assembly.Comment;
using Microsoft.Finance.Dimension;

page 920 "Posted Assembly Order"
{
    Caption = 'Posted Assembly Order';
    Editable = true;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = Document;
    SourceTable = "Posted Assembly Header";

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
                }
                field("Order No."; Rec."Order No.")
                {
                    ApplicationArea = Assembly;
                }
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Assembly;
                }
                group(Control8)
                {
                    ShowCaption = false;
                    field(Quantity; Rec.Quantity)
                    {
                        ApplicationArea = Assembly;
                    }
                    field("Unit of Measure Code"; Rec."Unit of Measure Code")
                    {
                        ApplicationArea = Assembly;
                    }
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = Assembly;
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

                    trigger OnDrillDown()
                    begin
                        Rec.ShowAsmToOrder();
                    end;
                }
                field(Reversed; Rec.Reversed)
                {
                    ApplicationArea = Assembly;
                }
            }
            part(Lines; "Posted Assembly Order Subform")
            {
                ApplicationArea = Assembly;
                SubPageLink = "Document No." = field("No.");
            }
            group(Posting)
            {
                Caption = 'Posting';
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = Planning;
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Location;
                }
                field("Bin Code"; Rec."Bin Code")
                {
                    ApplicationArea = Warehouse;
                }
                field("Unit Cost"; Rec."Unit Cost")
                {
                    ApplicationArea = Assembly;
                }
                field("Cost Amount"; Rec."Cost Amount")
                {
                    ApplicationArea = Assembly;
                }
                field("User ID"; Rec."User ID")
                {
                    ApplicationArea = Assembly;
                    Visible = false;
                }
                field("Gen. Bus. Posting Group"; Rec."Gen. Bus. Posting Group")
                {
                    ApplicationArea = Assembly;
                }
            }
        }
        area(factboxes)
        {
            systempart(Control21; Links)
            {
                ApplicationArea = RecordLinks;
            }
            systempart(Control22; Notes)
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
                RunObject = Page "Posted Asm. Order Statistics";
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
            action("Item &Tracking Lines")
            {
                ApplicationArea = ItemTracking;
                Caption = 'Item &Tracking Lines';
                Image = ItemTrackingLines;
                ShortCutKey = 'Ctrl+Alt+I';
                ToolTip = 'View or edit serial, lot and package numbers that are assigned to the item on the document or journal line.';

                trigger OnAction()
                begin
                    Rec.ShowItemTrackingLines();
                end;
            }
            action(Comments)
            {
                ApplicationArea = Comments;
                Caption = 'Co&mments';
                Image = ViewComments;
                RunObject = Page "Assembly Comment Sheet";
                RunPageLink = "Document Type" = const("Posted Assembly"),
                              "Document No." = field("No."),
                              "Document Line No." = const(0);
                ToolTip = 'View or add comments for the record.';
            }
        }
        area(processing)
        {
            action(Print)
            {
                ApplicationArea = Assembly;
                Caption = 'Print';
                Image = Print;
                ToolTip = 'Print the information in the window. A print request window opens where you can specify what to include on the print-out.';

                trigger OnAction()
                var
                    PostedAssemblyHeader: Record "Posted Assembly Header";
                begin
                    CurrPage.SetSelectionFilter(PostedAssemblyHeader);
                    PostedAssemblyHeader.PrintRecords(true);
                end;
            }
            action(Navigate)
            {
                ApplicationArea = Assembly;
                Caption = 'Find entries...';
                Image = Navigate;
                ShortCutKey = 'Ctrl+Alt+Q';
                ToolTip = 'Find entries and documents that exist for the document number and posting date on the selected document. (Formerly this action was named Navigate.)';

                trigger OnAction()
                begin
                    Rec.Navigate();
                end;
            }
            action("Undo Post")
            {
                ApplicationArea = Assembly;
                Caption = 'Undo Assembly';
                Enabled = UndoPostEnabledExpr;
                Image = Undo;
                ToolTip = 'Cancel the posting of the assembly order. A set of corrective item ledger entries is created to reverse the original entries. Each positive output entry for the assembly item is reversed by a negative output entry. Each negative consumption entry for an assembly component is reversed by a positive consumption entry. Fixed cost application is automatically created between the corrective and original entries to ensure exact cost reversal.';

                trigger OnAction()
                begin
                    CODEUNIT.Run(CODEUNIT::"Pstd. Assembly - Undo (Yes/No)", Rec);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';

                actionref(Print_Promoted; Print)
                {
                }
                actionref(Navigate_Promoted; Navigate)
                {
                }
                actionref("Undo Post_Promoted"; "Undo Post")
                {
                }
                actionref("Item &Tracking Lines_Promoted"; "Item &Tracking Lines")
                {
                }
            }
            group(Category_Category5)
            {
                Caption = 'Print/Send', Comment = 'Generated from the PromotedActionCategories property index 4.';
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
                actionref(Comments_Promoted; Comments)
                {
                }
            }
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        UndoPostEnabledExpr := not Rec.Reversed and not Rec.IsAsmToOrder();
    end;

    var
        UndoPostEnabledExpr: Boolean;
}
