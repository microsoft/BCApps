// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.Bank.Ledger;

page 7444 "EA Corp Card Statement"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Corporate Card Statement';
    PageType = Document;
    SourceTable = "EA Corp Card Statement";

    layout
    {
        area(Content)
        {
            group(General)
            {
                field("Provider Code"; Rec."Provider Code")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the corporate card provider that issued the statement.';
                }
                field("Statement No."; Rec."Statement No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = Rec.Status = Rec.Status::Imported;
                    ToolTip = 'Specifies the statement identifier assigned by the provider.';
                }
                field("Statement Date"; Rec."Statement Date")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = Rec.Status = Rec.Status::Imported;
                    ToolTip = 'Specifies the date of the provider statement.';
                }
                field("Period Start Date"; Rec."Period Start Date")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = Rec.Status = Rec.Status::Imported;
                    ToolTip = 'Specifies the first transaction date covered by the statement.';
                }
                field("Period End Date"; Rec."Period End Date")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = Rec.Status = Rec.Status::Imported;
                    ToolTip = 'Specifies the last transaction date covered by the statement.';
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = Rec.Status = Rec.Status::Imported;
                    ToolTip = 'Specifies the currency of the provider statement.';
                }
                field("Statement Total"; Rec."Statement Total")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = Rec.Status = Rec.Status::Imported;
                    ToolTip = 'Specifies the total amount reported by the provider.';
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether the provider statement is open or validated.';
                }
            }
            group(Statistics)
            {
                Caption = 'Statistics';

                field("Transaction Total"; Rec."Transaction Total")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the total amount of the statement lines.';
                }
                field("Matched Transactions"; Rec."Matched Transactions")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of statement lines linked to imported corporate card transactions.';
                }
                field("Imported Transactions"; Rec."Imported Transactions")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the total number of statement lines.';
                }
                field(Exceptions; Rec.Exceptions)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the number of unresolved import and post-import processing exceptions. Choose the number to review the errors.';

                    trigger OnDrillDown()
                    var
                        CorpCardException: Record "EA Corp Card Exception";
                    begin
                        CorpCardException.SetRange("Statement Entry No.", Rec."Statement Entry No.");
                        CorpCardException.SetRange(Resolved, false);
                        Page.Run(Page::"EA Corp Card Exceptions", CorpCardException);
                    end;
                }
                field("Settlement Entry No."; Rec."Settlement Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the settlement that includes this statement.';
                }
                group(SummaryProgress)
                {
                    ShowCaption = false;
                    Visible = not SummaryAvailable;

                    field(SummaryStatus; SummaryStatusText)
                    {
                        ApplicationArea = Basic, Suite;
                        Editable = false;
                        Caption = 'Reconciliation Summary';
                        ToolTip = 'Specifies whether the reconciliation summary is being calculated or could not be loaded.';
                    }
                }
                group(ReconciliationSummary)
                {
                    ShowCaption = false;
                    Visible = SummaryAvailable;

                    field(SettlementStatus; SettlementStatusText)
                    {
                        ApplicationArea = Basic, Suite;
                        Editable = false;
                        Caption = 'Settlement Status';
                        ToolTip = 'Specifies the current status of the settlement that includes this statement.';
                    }
                    field(ReconciledTransactions; ReconciledTransactions)
                    {
                        ApplicationArea = Basic, Suite;
                        Editable = false;
                        Caption = 'Reconciled Transactions';
                        ToolTip = 'Specifies the number of statement transactions matched to valid corporate card bank account ledger entries.';
                    }
                    field(UnreconciledTransactions; UnreconciledTransactions)
                    {
                        ApplicationArea = Basic, Suite;
                        Editable = false;
                        Caption = 'Unreconciled Transactions';
                        ToolTip = 'Specifies the number of statement transactions without a valid corporate card bank account ledger entry.';
                    }
                    field(ReconciledAmount; ReconciledAmount)
                    {
                        ApplicationArea = Basic, Suite;
                        Editable = false;
                        AutoFormatType = 1;
                        AutoFormatExpression = "Currency Code";
                        Caption = 'Reconciled Amount';
                        ToolTip = 'Specifies the amount represented by reconciled statement transactions.';
                    }
                    field(UnreconciledAmount; UnreconciledAmount)
                    {
                        ApplicationArea = Basic, Suite;
                        Editable = false;
                        AutoFormatType = 1;
                        AutoFormatExpression = "Currency Code";
                        Caption = 'Unreconciled Amount';
                        ToolTip = 'Specifies the amount represented by unreconciled statement transactions.';
                    }
                    field(UnlinkedBankEntries; UnlinkedBankEntries)
                    {
                        ApplicationArea = Basic, Suite;
                        Editable = false;
                        Caption = 'Bank Entries Without Transaction';
                        ToolTip = 'Specifies the number of open bank account ledger entries on the corporate card bank account within the statement period that are not linked to any corporate card transaction or settlement. Choose the field to view them.';

                        trigger OnDrillDown()
                        var
                            BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
                            CorpCardStatementMgt: Codeunit "EA Corp Card Statement Mgt";
                        begin
                            CorpCardStatementMgt.SetUnlinkedBankEntryFilters(Rec, BankAccountLedgerEntry);
                            Page.Run(Page::"Bank Account Ledger Entries", BankAccountLedgerEntry);
                        end;
                    }
                    field(UnlinkedBankAmount; UnlinkedBankAmount)
                    {
                        ApplicationArea = Basic, Suite;
                        Editable = false;
                        AutoFormatType = 1;
                        AutoFormatExpression = "Currency Code";
                        Caption = 'Bank Amount Without Transaction';
                        ToolTip = 'Specifies the total amount of the bank account ledger entries that are not linked to any corporate card transaction or settlement.';
                    }
                }
            }
            group(Reconciliation)
            {
                Caption = 'Reconciliation';

                field("Closed At"; Rec."Closed At")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies when reconciliation of the statement was closed.';
                }
                field("Closed By User ID"; Rec."Closed By User ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the user who closed reconciliation of the statement.';
                }
                field("Previous Closed At"; Rec."Previous Closed At")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies when the previous reconciliation closure occurred.';
                }
                field("Previous Closed By User ID"; Rec."Previous Closed By User ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the user who completed the previous reconciliation closure.';
                }
                field("Prev. Reconciled Transactions"; Rec."Prev. Reconciled Transactions")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the reconciled transaction count captured before invalidation.';
                }
                field("Prev. Reconciled Amount"; Rec."Prev. Reconciled Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the reconciled amount captured before invalidation.';
                }
                field("Reconciliation Invalidated At"; Rec."Reconciliation Invalidated At")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies when reconciliation was invalidated.';
                }
                field("Reconciliation Invalidated By"; Rec."Reconciliation Invalidated By")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the user who invalidated reconciliation.';
                }
                field("Recon. Invalidation Reason"; Rec."Recon. Invalidation Reason")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies why reconciliation must be performed again.';
                }
            }
            part(Transactions; "EA Corp Card Statement Trans")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "Statement Entry No." = field("Statement Entry No.");
                UpdatePropagation = Both;
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ProcessTransactions)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Process transactions';
                Enabled = Rec.Status = Rec.Status::Imported;
                Image = Process;
                ToolTip = 'Matches imported transactions and creates draft expenses. Retries transactions whose post-import processing failed after their setup has been corrected.';

                trigger OnAction()
                var
                    PostImportOrch: Codeunit "EA Corp Card Post Import Orch";
                    ExpenseWriter: Codeunit "EA Corp Card Expense Writer";
                begin
                    CurrPage.SaveRecord();
                    PostImportOrch.ProcessStatementPostImport(Rec."Statement Entry No.", ExpenseWriter);
                    Rec.Get(Rec."Statement Entry No.");
                    CurrPage.Update(false);
                end;
            }
            action(ValidateStatement)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Validate statement';
                Enabled = Rec.Status = Rec.Status::Imported;
                Image = Approve;
                ToolTip = 'Validates import completeness, statement identity, dates, currency, total, and expense matching.';

                trigger OnAction()
                var
                    CorpCardStatementMgt: Codeunit "EA Corp Card Statement Mgt";
                begin
                    CorpCardStatementMgt.ValidateStatement(Rec);
                    CurrPage.Update(false);
                end;
            }
            action(Reopen)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Reopen';
                Enabled = CanReopen;
                Image = ReOpen;
                ToolTip = 'Reopens the validated statement so that it can be corrected.';

                trigger OnAction()
                var
                    CorpCardStatementMgt: Codeunit "EA Corp Card Statement Mgt";
                begin
                    CorpCardStatementMgt.ReopenStatement(Rec);
                    CurrPage.Update(false);
                end;
            }
            action(OpenSettlement)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Settlement';
                Image = Payment;
                ToolTip = 'Opens the settlement that includes this statement.';

                trigger OnAction()
                var
                    CorpCardSettlement: Record "EA Corp Card Settlement";
                begin
                    Rec.CalcFields("Settlement Entry No.");
                    if Rec."Settlement Entry No." = 0 then
                        Error(NoSettlementErr);

                    CorpCardSettlement.Get(Rec."Settlement Entry No.");
                    Page.RunModal(Page::"EA Corp Card Settlement", CorpCardSettlement);
                end;
            }
            action(CloseReconciliation)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Close reconciliation';
                Enabled = CanCloseReconciliation;
                Image = ClosePeriod;
                ToolTip = 'Verifies every statement transaction and the posted settlement entries, then closes the statement period.';

                trigger OnAction()
                var
                    CorpCardStatementMgt: Codeunit "EA Corp Card Statement Mgt";
                begin
                    if not Confirm(CloseReconciliationQst, false, Rec."Statement No.") then
                        exit;

                    CorpCardStatementMgt.CloseStatement(Rec);
                    CurrPage.Update(false);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Home)
            {
                Caption = 'Home';

                actionref(ProcessTransactions_Promoted; ProcessTransactions)
                {
                }
                group(Category_Validation)
                {
                    Caption = 'Validation';
                    ShowAs = SplitButton;

                    actionref(ValidateStatement_Promoted; ValidateStatement)
                    {
                    }
                    actionref(Reopen_Promoted; Reopen)
                    {
                    }
                }
                actionref(CloseReconciliation_Promoted; CloseReconciliation)
                {
                }
            }
            group(Category_Statement)
            {
                Caption = 'Statement';

                actionref(OpenSettlement_Promoted; OpenSettlement)
                {
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        CanCloseReconciliation := Rec.Status in [Rec.Status::Validated, Rec.Status::ReconciliationRequired];
        Rec.CalcFields("Settlement Entry No.");
        CanReopen := (Rec.Status = Rec.Status::Validated) and (Rec."Settlement Entry No." = 0);
    end;

    trigger OnAfterGetCurrRecord()
    var
        CorpCardStmtSummary: Codeunit "EA Corp Card Stmt Summary";
        Parameters: Dictionary of [Text, Text];
    begin
        if SummaryTaskId <> 0 then
            CurrPage.CancelBackgroundTask(SummaryTaskId);
        Clear(SummaryTaskId);
        ClearReconciliationSummary();
        Clear(SummaryStatusText);
        if Rec."Statement Entry No." = 0 then
            exit;

        SummaryStatusText := CalculatingSummaryLbl;
        Parameters.Add(CorpCardStmtSummary.GetStatementEntryNoKey(), Format(Rec."Statement Entry No."));
        CurrPage.EnqueueBackgroundTask(SummaryTaskId, Codeunit::"EA Corp Card Stmt Summary", Parameters, 60000, PageBackgroundTaskErrorLevel::Warning);
    end;

    trigger OnPageBackgroundTaskCompleted(TaskId: Integer; Results: Dictionary of [Text, Text])
    var
        CorpCardStmtSummary: Codeunit "EA Corp Card Stmt Summary";
    begin
        if TaskId <> SummaryTaskId then
            exit;

        Evaluate(ReconciledTransactions, Results.Get(CorpCardStmtSummary.GetReconciledTransactionsKey()));
        Evaluate(ReconciledAmount, Results.Get(CorpCardStmtSummary.GetReconciledAmountKey()));
        Evaluate(UnreconciledTransactions, Results.Get(CorpCardStmtSummary.GetUnreconciledTransactionsKey()));
        Evaluate(UnreconciledAmount, Results.Get(CorpCardStmtSummary.GetUnreconciledAmountKey()));
        Evaluate(UnlinkedBankEntries, Results.Get(CorpCardStmtSummary.GetUnlinkedBankEntriesKey()));
        Evaluate(UnlinkedBankAmount, Results.Get(CorpCardStmtSummary.GetUnlinkedBankAmountKey()));
        SettlementStatusText := CopyStr(Results.Get(CorpCardStmtSummary.GetSettlementStatusKey()), 1, MaxStrLen(SettlementStatusText));
        SummaryAvailable := true;
        Clear(SummaryTaskId);
    end;

    trigger OnPageBackgroundTaskError(TaskId: Integer; ErrorCode: Text; ErrorText: Text; ErrorCallStack: Text; var IsHandled: Boolean)
    var
        SummaryErrorNotification: Notification;
    begin
        if TaskId <> SummaryTaskId then
            exit;

        ClearReconciliationSummary();
        SummaryStatusText := SummaryUnavailableLbl;
        SummaryErrorNotification.Message(StrSubstNo(SummaryFailedErr, ErrorText));
        SummaryErrorNotification.Scope(NotificationScope::LocalScope);
        SummaryErrorNotification.Send();
        Clear(SummaryTaskId);
        IsHandled := true;
    end;

    local procedure ClearReconciliationSummary()
    begin
        Clear(ReconciledTransactions);
        Clear(ReconciledAmount);
        Clear(UnreconciledTransactions);
        Clear(UnreconciledAmount);
        Clear(UnlinkedBankEntries);
        Clear(UnlinkedBankAmount);
        Clear(SettlementStatusText);
        SummaryAvailable := false;
    end;

    var
        CloseReconciliationQst: Label 'Do you want to close reconciliation for corporate card statement %1?', Comment = '%1 = statement number';
        CanCloseReconciliation: Boolean;
        CanReopen: Boolean;
        NoSettlementErr: Label 'The statement is not included in a settlement.';
        CalculatingSummaryLbl: Label 'Calculating...';
        SummaryUnavailableLbl: Label 'Unavailable';
        SummaryFailedErr: Label 'The reconciliation summary could not be calculated. %1', Comment = '%1 = background task error message';
        SummaryAvailable: Boolean;
        SummaryStatusText: Text;
        SummaryTaskId: Integer;
        ReconciledAmount: Decimal;
        UnreconciledAmount: Decimal;
        UnlinkedBankAmount: Decimal;
        ReconciledTransactions: Integer;
        UnlinkedBankEntries: Integer;
        UnreconciledTransactions: Integer;
        SettlementStatusText: Text[30];
}
