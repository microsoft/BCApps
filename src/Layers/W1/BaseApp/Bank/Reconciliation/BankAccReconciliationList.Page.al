// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Reconciliation;

page 388 "Bank Acc. Reconciliation List"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Bank Account Reconciliations';
    CardPageID = "Bank Acc. Reconciliation";
    Editable = false;
    PageType = List;
    AboutTitle = 'About Bank Account Reconciliations';
    AboutText = 'Reconcile bank accounts by matching imported bank statement lines with internal ledger entries, using automated suggestions and manual review to ensure your cash records are accurate and up-to-date.';
    SourceTable = "Bank Acc. Reconciliation";
    SourceTableView = where("Statement Type" = const("Bank Reconciliation"));
    UsageCategory = Lists;
    RefreshOnActivate = true;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(BankAccountNo; Rec."Bank Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the bank account that you want to reconcile with the bank''s statement.';
                }
                field("Bank Account Name"; Rec."Bank Account Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the bank account that you want to reconcile.';
                }
                field(StatementNo; Rec."Statement No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the bank account statement.';
                }
                field(StatementDate; Rec."Statement Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date on the bank account statement.';
                }
                field(BalanceLastStatement; Rec."Balance Last Statement")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the ending balance shown on the last bank statement, which was used in the last posted bank reconciliation for this bank account.';
                }
                field(StatementEndingBalance; Rec."Statement Ending Balance")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the ending balance shown on the bank''s statement that you want to reconcile with the bank account.';
                }
                field(AllowDuplicatedTransactions; Rec."Allow Duplicated Transactions")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether to allow bank account reconciliation lines to have the same transaction ID. Although it’s rare, this is useful when your bank statement file contains transactions with duplicate IDs. Most businesses leave this toggle turned off.';
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
        area(processing)
        {
            group("P&osting")
            {
                Caption = 'P&osting';
                Image = Post;
                action(Post)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'P&ost';
                    Image = PostOrder;
                    RunObject = Codeunit "Bank Acc. Recon. Post (Yes/No)";
                    ShortCutKey = 'F9';
                    ToolTip = 'Finalize the document or journal by posting the amounts and quantities to the related accounts in your company books.';
                }
                action(PostAndPrint)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Post and &Print';
                    Image = PostPrint;
                    RunObject = Codeunit "Bank Acc. Recon. Post+Print";
                    ShortCutKey = 'Shift+F9';
                    ToolTip = 'Finalize and prepare to print the document or journal. The values and quantities are posted to the related accounts. A report request window where you can specify what to include on the print-out.';
                }
            }
            action(ChangeStatementNo)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Change Statement No.';
                Ellipsis = true;
                Image = ChangeTo;
                ToolTip = 'Change the statement number of the bank account reconciliation. Typically, this is used when you have created a new reconciliation to correct a mistake, and you want to use the same statement number.';

                trigger OnAction()
                var
                    BankAccReconciliation: Record "Bank Acc. Reconciliation";
                begin
                    BankAccReconciliation := Rec;
                    Codeunit.Run(Codeunit::"Change Bank Rec. Statement No.", BankAccReconciliation);
                    Rec := BankAccReconciliation;
                end;
            }
        }
        area(Prompting)
        {
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                group(Category_Posting)
                {
                    Caption = 'Posting';
                    ShowAs = SplitButton;

                    actionref(Post_Promoted; Post)
                    {
                    }
                    actionref(PostAndPrint_Promoted; PostAndPrint)
                    {
                    }
                }
                actionref(ChangeStatementNo_Promoted; ChangeStatementNo)
                {
                }
            }
        }
    }
}

