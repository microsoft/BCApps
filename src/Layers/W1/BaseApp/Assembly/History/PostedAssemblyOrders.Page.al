// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Assembly.History;

using Microsoft.Assembly.Comment;
using Microsoft.Finance.Dimension;

page 922 "Posted Assembly Orders"
{
    ApplicationArea = Assembly;
    Caption = 'Posted Assembly Orders';
    CardPageID = "Posted Assembly Order";
    DataCaptionFields = "No.";
    Editable = false;
    PageType = List;
    SourceTable = "Posted Assembly Header";
    SourceTableView = sorting("Posting Date")
                      order(descending);
    UsageCategory = History;

    layout
    {
        area(content)
        {
            repeater(Control2)
            {
                ShowCaption = false;
                field("No."; Rec."No.")
                {
                    ApplicationArea = Assembly;
                }
                field("Order No."; Rec."Order No.")
                {
                    ApplicationArea = Assembly;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Assembly;
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
            }
        }
        area(factboxes)
        {
            systempart(Control11; Links)
            {
                ApplicationArea = RecordLinks;
            }
            systempart(Control12; Notes)
            {
                ApplicationArea = Notes;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group(Line)
            {
                Caption = '&Line';
                Image = Line;
                action("Show Document")
                {
                    ApplicationArea = Assembly;
                    Caption = '&Show Document';
                    Image = View;
                    RunObject = Page "Posted Assembly Order";
                    RunPageLink = "No." = field("No.");
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'Open the document that the information on the line comes from.';
                }
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
        }
        area(processing)
        {
            action(Print)
            {
                ApplicationArea = Assembly;
                Caption = '&Print';
                Image = Print;
                ToolTip = 'Prepare to print the document. A report request window for the document opens where you can specify what to include on the print-out.';

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
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(Print_Promoted; Print)
                {
                }
                actionref(Navigate_Promoted; Navigate)
                {
                }
                group(Category_Order)
                {
                    Caption = 'Order';

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
                actionref("Show Document_Promoted"; "Show Document")
                {
                }
            }
        }
    }
}
