// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

codeunit 7446 "EA Corp Card Stmt Summary"
{
    Access = Internal;
    InherentEntitlements = X;

    trigger OnRun()
    var
        CorpCardStatement: Record "EA Corp Card Statement";
        CorpCardStatementMgt: Codeunit "EA Corp Card Statement Mgt";
        Parameters: Dictionary of [Text, Text];
        Results: Dictionary of [Text, Text];
        SettlementStatus: Enum "EA Corp Card Settle Status";
        ReconciledAmount: Decimal;
        UnreconciledAmount: Decimal;
        UnlinkedBankAmount: Decimal;
        StatementEntryNo: Integer;
        ReconciledTransactions: Integer;
        UnreconciledTransactions: Integer;
        UnlinkedBankEntries: Integer;
        SettlementStatusText: Text;
    begin
        Parameters := Page.GetBackgroundParameters();
        Evaluate(StatementEntryNo, Parameters.Get(GetStatementEntryNoKey()));
        CorpCardStatement.Get(StatementEntryNo);
        CorpCardStatementMgt.GetReconciliationSummary(
            CorpCardStatement, ReconciledTransactions, ReconciledAmount,
            UnreconciledTransactions, UnreconciledAmount, SettlementStatus);
        CorpCardStatementMgt.GetUnlinkedBankEntrySummary(CorpCardStatement, UnlinkedBankEntries, UnlinkedBankAmount);
        CorpCardStatement.CalcFields("Settlement Entry No.");
        if CorpCardStatement."Settlement Entry No." <> 0 then
            SettlementStatusText := Format(SettlementStatus);

        Results.Add(GetReconciledTransactionsKey(), Format(ReconciledTransactions));
        Results.Add(GetReconciledAmountKey(), Format(ReconciledAmount));
        Results.Add(GetUnreconciledTransactionsKey(), Format(UnreconciledTransactions));
        Results.Add(GetUnreconciledAmountKey(), Format(UnreconciledAmount));
        Results.Add(GetUnlinkedBankEntriesKey(), Format(UnlinkedBankEntries));
        Results.Add(GetUnlinkedBankAmountKey(), Format(UnlinkedBankAmount));
        Results.Add(GetSettlementStatusKey(), SettlementStatusText);
        Page.SetBackgroundTaskResult(Results);
    end;

    internal procedure GetStatementEntryNoKey(): Text
    begin
        exit('statementEntryNo');
    end;

    internal procedure GetReconciledTransactionsKey(): Text
    begin
        exit('reconciledTransactions');
    end;

    internal procedure GetReconciledAmountKey(): Text
    begin
        exit('reconciledAmount');
    end;

    internal procedure GetUnreconciledTransactionsKey(): Text
    begin
        exit('unreconciledTransactions');
    end;

    internal procedure GetUnreconciledAmountKey(): Text
    begin
        exit('unreconciledAmount');
    end;

    internal procedure GetUnlinkedBankEntriesKey(): Text
    begin
        exit('unlinkedBankEntries');
    end;

    internal procedure GetUnlinkedBankAmountKey(): Text
    begin
        exit('unlinkedBankAmount');
    end;

    internal procedure GetSettlementStatusKey(): Text
    begin
        exit('settlementStatus');
    end;
}
