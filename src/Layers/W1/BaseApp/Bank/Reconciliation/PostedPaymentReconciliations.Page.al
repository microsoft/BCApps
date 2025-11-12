// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Reconciliation;

using Microsoft.Foundation.Reporting;

page 1299 "Posted Payment Reconciliations"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Posted Payment Reconciliations';
    CardPageID = "Posted Payment Reconciliation";
    Editable = false;
    PageType = List;
    SourceTable = "Posted Payment Recon. Hdr";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Bank Account No."; Rec."Bank Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the bank account that the posted payment was processed for.';
                }
                field("Statement No."; Rec."Statement No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the bank statement that contained the line that represented the posted payment.';
                }
                field("Is Reversed"; Rec."Is Reversed")
                {
                    ApplicationArea = Basic, Suite;
                    Tooltip = 'Specifies if this posted payment reconciliation journal has been previously reversed.';
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
        area(Processing)
        {
            action(Undo)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Reverse';
                Image = Undo;
                ToolTip = 'Undo the bank statement, unapply, and reverse the entries created by this journal.';

                trigger OnAction()
                var
                    ReversePaymentRecJournal: Codeunit "Reverse Payment Rec. Journal";
                begin
                    ReversePaymentRecJournal.RunReversalWizard(Rec);
                end;
            }
        }
        area(reporting)
        {
            action(Print)
            {
                ApplicationArea = Basic, Suite;
                Caption = '&Print';
                Ellipsis = true;
                Image = Print;
                Scope = Repeater;
                ToolTip = 'Prepare to print the document. A report request window for the document opens where you can specify what to include on the print-out.';

                trigger OnAction()
                var
                    DocPrint: Codeunit "Document-Print";
                begin
                    DocPrint.PrintPostedPaymentReconciliation(Rec);
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
                actionref(Undo_Promoted; Undo)
                {
                }
            }
        }
    }
}

