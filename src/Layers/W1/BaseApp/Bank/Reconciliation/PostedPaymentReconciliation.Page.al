// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Reconciliation;

using Microsoft.Foundation.Reporting;

page 1295 "Posted Payment Reconciliation"
{
    Caption = 'Posted Payment Reconciliation';
    Editable = false;
    PageType = Document;
    SaveValues = false;
    SourceTable = "Posted Payment Recon. Hdr";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
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
            }
            part(StmtLine; "Pstd. Pmt. Recon. Subform")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Lines';
                SubPageLink = "Bank Account No." = field("Bank Account No."),
                              "Statement No." = field("Statement No.");
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
        area(processing)
        {
            action(Reverse)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Reverse';
                Image = Undo;
                ToolTip = 'Undo the bank statement, unapply, and reverse the entries created by this journal.';
                Enabled = not Rec."Is Reversed";

                trigger OnAction()
                var
                    ReversePaymentRecJournal: Codeunit "Reverse Payment Rec. Journal";
                begin
                    ReversePaymentRecJournal.RunReversalWizard(Rec);
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
                actionref(Reverse_Promoted; Reverse)
                {
                }
            }
            group(Category_Category4)
            {
                Caption = 'Bank', Comment = 'Generated from the PromotedActionCategories property index 3.';
            }
            group(Category_Category5)
            {
                Caption = 'Matching', Comment = 'Generated from the PromotedActionCategories property index 4.';
            }
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';
            }
        }
    }
}

