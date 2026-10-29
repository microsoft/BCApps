// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

page 7429 "EA Corp Card Stmt. FactBox"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Statement Reconciliation';
    Editable = false;
    PageType = CardPart;
    SourceTable = "EA Corp Card Statement";

    layout
    {
        area(Content)
        {
            group(SummaryProgress)
            {
                ShowCaption = false;
                Visible = not SummaryAvailable;

                field(SummaryStatus; SummaryStatusText)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Reconciliation Summary';
                    ToolTip = 'Specifies whether the reconciliation summary is being calculated or could not be loaded.';
                }
            }
            group(General)
            {
                ShowCaption = false;
                Visible = SummaryAvailable;
                field(SettlementStatus; SettlementStatusText)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Settlement Status';
                    ToolTip = 'Specifies the current status of the settlement that includes this statement.';
                }
                field(ReconciledTransactions; ReconciledTransactions)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Reconciled Transactions';
                    ToolTip = 'Specifies the number of statement transactions matched to valid corporate card bank account ledger entries.';
                }
                field(UnreconciledTransactions; UnreconciledTransactions)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Unreconciled Transactions';
                    ToolTip = 'Specifies the number of statement transactions without a valid corporate card bank account ledger entry.';
                }
                field(ReconciledAmount; ReconciledAmount)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    AutoFormatExpression = Rec."Currency Code";
                    Caption = 'Reconciled Amount';
                    ToolTip = 'Specifies the amount represented by reconciled statement transactions.';
                }
                field(UnreconciledAmount; UnreconciledAmount)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    AutoFormatExpression = Rec."Currency Code";
                    Caption = 'Unreconciled Amount';
                    ToolTip = 'Specifies the amount represented by unreconciled statement transactions.';
                }
            }
        }
    }

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
        Clear(SettlementStatusText);
        SummaryAvailable := false;
    end;

    var
        CalculatingSummaryLbl: Label 'Calculating...';
        SummaryUnavailableLbl: Label 'Unavailable';
        SummaryFailedErr: Label 'The reconciliation summary could not be calculated. %1', Comment = '%1 = background task error message';
        SummaryAvailable: Boolean;
        SummaryStatusText: Text;
        SummaryTaskId: Integer;
        ReconciledAmount: Decimal;
        UnreconciledAmount: Decimal;
        ReconciledTransactions: Integer;
        UnreconciledTransactions: Integer;
        SettlementStatusText: Text[30];
}
