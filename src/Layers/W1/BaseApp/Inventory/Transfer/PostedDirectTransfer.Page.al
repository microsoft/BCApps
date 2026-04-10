// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Transfer;

using Microsoft.Inventory.Comment;

page 6781 "Posted Direct Transfer"
{
    Caption = 'Posted Direct Transfer';
    InsertAllowed = false;
    PageType = Document;
    RefreshOnActivate = true;
    SourceTable = "Direct Trans. Header";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("No."; Rec."No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                }
                field("Transfer-from Code"; Rec."Transfer-from Code")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                }
                field("Transfer-to Code"; Rec."Transfer-to Code")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                }
                field("Transfer Order No."; Rec."Transfer Order No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    Lookup = false;
                }
                field("Transfer Order Date"; Rec."Transfer Order Date")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                }
                field("Shortcut Dimension 1 Code"; Rec."Shortcut Dimension 1 Code")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                }
                field("Shortcut Dimension 2 Code"; Rec."Shortcut Dimension 2 Code")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                }
            }
            part(TransferMovementLines; "Posted Direct Transfer Subform")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "Document No." = field("No.");
            }
            group("Transfer-from")
            {
                Caption = 'Transfer-from';
                field("Transfer-from Name"; Rec."Transfer-from Name")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                }
                field("Transfer-from Name 2"; Rec."Transfer-from Name 2")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                }
                field("Transfer-from Address"; Rec."Transfer-from Address")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                }
                field("Transfer-from Address 2"; Rec."Transfer-from Address 2")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                }
                field("Transfer-from Post Code"; Rec."Transfer-from Post Code")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Transfer-from Post Code/City';
                    Editable = false;
                }
                field("Transfer-from City"; Rec."Transfer-from City")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                }
                field("Transfer-from Contact"; Rec."Transfer-from Contact")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                }
            }
            group("Transfer-to")
            {
                Caption = 'Transfer-to';
                field("Transfer-to Name"; Rec."Transfer-to Name")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                }
                field("Transfer-to Name 2"; Rec."Transfer-to Name 2")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                }
                field("Transfer-to Address"; Rec."Transfer-to Address")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                }
                field("Transfer-to Address 2"; Rec."Transfer-to Address 2")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                }
                field("Transfer-to Post Code"; Rec."Transfer-to Post Code")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                }
                field("Transfer-to City"; Rec."Transfer-to City")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                }
                field("Transfer-to Contact"; Rec."Transfer-to Contact")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
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
            group("&Transfer")
            {
                Caption = '&Transfer';
                action(Statistics)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Statistics';
                    Image = Statistics;
                    RunObject = Page "Direct Transfer Statistics";
                    RunPageLink = "No." = field("No.");
                    ShortCutKey = 'F7';
                    ToolTip = 'View statistical information, such as the value of posted entries, for the record.';
                }
                action("Co&mments")
                {
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "Inventory Comment Sheet";
                    RunPageLink = "Document Type" = const("Posted Direct Transfer"),
                                  "No." = field("No.");
                    ToolTip = 'View or add comments for the record.';
                }
                action(Dimensions)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    ShortCutKey = 'Alt+D';
                    ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to sales and purchase documents to distribute costs and analyze transaction history.';

                    trigger OnAction()
                    begin
                        Rec.ShowDimensions();
                    end;
                }
            }
        }
        area(processing)
        {
            action("&Print")
            {
                ApplicationArea = Basic, Suite;
                Caption = '&Print';
                Ellipsis = true;
                Image = Print;
                ToolTip = 'Prepare to print the document. A report request window for the document opens where you can specify what to include on the print-out.';

                trigger OnAction()
                var
                    DirectTransHeader: Record "Direct Trans. Header";
                begin
                    DirectTransHeader := Rec;
                    CurrPage.SetSelectionFilter(DirectTransHeader);
                    DirectTransHeader.PrintRecords(true);
                end;
            }
            action("&Navigate")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Find entries...';
                Image = Navigate;
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

                actionref("&Print_Promoted"; "&Print")
                {
                }
                actionref("&Navigate_Promoted"; "&Navigate")
                {
                }
            }
            group(Category_Transfer)
            {
                Caption = 'Transfer';

                actionref(Dimensions_Promoted; Dimensions)
                {
                }
                actionref(Statistics_Promoted; Statistics)
                {
                }
                actionref("Co&mments_Promoted"; "Co&mments")
                {
                }
            }
        }
    }
}

