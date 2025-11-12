// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Intercompany.Inbox;

using Microsoft.Intercompany;
using Microsoft.Intercompany.Comment;
using Microsoft.Intercompany.Outbox;

page 617 "Handled IC Inbox Transactions"
{
    ApplicationArea = Intercompany;
    Caption = 'Handled Intercompany Inbox Transactions';
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    SourceTable = "Handled IC Inbox Trans.";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Transaction No."; Rec."Transaction No.")
                {
                    ApplicationArea = Intercompany;
                    Editable = false;
                    ToolTip = 'Specifies the transaction''s entry number.';
                }
                field("IC Partner Code"; Rec."IC Partner Code")
                {
                    ApplicationArea = Intercompany;
                    Editable = false;
                    ToolTip = 'Specifies the code of the intercompany partner that the transaction is related to if the entry was created from an intercompany transaction.';
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = Intercompany;
                    Editable = false;
                    ToolTip = 'Specifies what action has been taken on the transaction.';
                }
#if not CLEAN27
                field("Source Type"; Rec."Source Type")
                {
                    ApplicationArea = Intercompany;
                    Editable = false;
                    ToolTip = 'Specifies whether the transaction was created in a journal, a sales document, or a purchase document.';
                    ObsoleteReason = 'Replaced with IC Source Type for consistent naming.';
                    ObsoleteState = Pending;
                    ObsoleteTag = '27.0';
                }
#endif
                field("IC Source Type"; Rec."IC Source Type")
                {
                    ApplicationArea = Intercompany;
                    Editable = false;
                    ToolTip = 'Specifies whether the transaction was created in a journal, a sales document, or a purchase document.';
                }
                field("Document Type"; Rec."Document Type")
                {
                    ApplicationArea = Intercompany;
                    Editable = false;
                    ToolTip = 'Specifies the type of the related document.';
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = Intercompany;
                    Editable = false;
                    ToolTip = 'Specifies the number of the related document.';
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = Intercompany;
                    Editable = false;
                    ToolTip = 'Specifies the entry''s posting date.';
                }
                field("Transaction Source"; Rec."Transaction Source")
                {
                    ApplicationArea = Intercompany;
                    Editable = false;
                    ToolTip = 'Specifies which company created the transaction.';
                }
                field("Document Date"; Rec."Document Date")
                {
                    ApplicationArea = Intercompany;
                    Editable = false;
                    ToolTip = 'Specifies the date when the related document was created.';
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
                Visible = false;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Inbox Transaction")
            {
                Caption = '&Inbox Transaction';
                Image = Import;
                action(GoToDocument)
                {
                    ApplicationArea = Intercompany;
                    Caption = 'Go to Document';
                    Image = GetSourceDoc;
                    Tooltip = 'Navigate to the document created.';

                    trigger OnAction()
                    var
                        ICNavigation: Codeunit "IC Navigation";
                    begin
                        ICNavigation.NavigateToDocument(Rec);
                    end;
                }
                action(GoToInbox)
                {
                    ApplicationArea = Intercompany;
                    Caption = 'Go to Inbox';
                    Tooltip = 'Navigate to the intercompany inbox transactions.';
                    RunObject = page "IC Inbox Transactions";
                    Image = SendTo;
                }
                action(GoToOutbox)
                {
                    ApplicationArea = Intercompany;
                    Caption = 'Go to Outbox';
                    Tooltip = 'Navigate to the intercompany outbox transactions.';
                    RunObject = page "IC Outbox Transactions";
                    Image = ExportMessage;
                }
                action(GoToHandledOutbox)
                {
                    ApplicationArea = Intercompany;
                    Caption = 'Go to Handled Outbox';
                    Tooltip = 'Navigate to the intercompany handled outbox transactions.';
                    RunObject = page "Handled IC Outbox Transactions";
                    RunPageMode = View;
                    Image = ExportMessage;
                }
                action(Details)
                {
                    ApplicationArea = Intercompany;
                    Caption = 'Details';
                    Image = View;
                    ToolTip = 'View transaction details.';

                    trigger OnAction()
                    begin
                        Rec.ShowDetails();
                    end;
                }
                action(Comments)
                {
                    ApplicationArea = Intercompany;
                    Caption = 'Comments';
                    Image = ViewComments;
                    RunObject = Page "IC Comment Sheet";
                    RunPageLink = "Table Name" = const("Handled IC Inbox Transaction"),
                                  "Transaction No." = field("Transaction No."),
                                  "IC Partner Code" = field("IC Partner Code"),
                                  "Transaction Source" = field("Transaction Source");
                    ToolTip = 'View or add comments for the record.';
                }
            }
        }
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action("Re-create Inbox Transaction")
                {
                    ApplicationArea = Intercompany;
                    Caption = 'Re-create Inbox Transaction';
                    Image = NewStatusChange;
                    ToolTip = 'Re-creates a transaction in the inbox. For example, if you accepted a transaction in your inbox but then deleted the document or journal instead of posting it, you can re-create the inbox entry and accept it again.';

                    trigger OnAction()
                    var
                        InboxOutboxMgt: Codeunit ICInboxOutboxMgt;
                    begin
                        InboxOutboxMgt.RecreateInboxTransaction(Rec);
                        CurrPage.Update();
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Category4)
            {
                Caption = 'Functions', Comment = 'Generated from the PromotedActionCategories property index 3.';

                actionref("Re-create Inbox Transaction_Promoted"; "Re-create Inbox Transaction")
                {
                }
            }
            group(Category_Category5)
            {
                Caption = 'Inbox Transaction', Comment = 'Generated from the PromotedActionCategories property index 4.';

                actionref(Details_Promoted; Details)
                {
                }
                actionref(Comments_Promoted; Comments)
                {
                }
            }
            group(Category_Navigation)
            {
                Caption = 'Navigate';

                actionref(GoToDocument_Promoted; GoToDocument)
                {
                }
                actionref(GoToInbox_Promoted; GoToInbox)
                {
                }
                actionref(GoToOutbox_Promoted; GoToOutbox)
                {
                }
                actionref(GoToHandledOutbox_Promoted; GoToHandledOutbox)
                {
                }
            }
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';
            }
        }
    }
}

