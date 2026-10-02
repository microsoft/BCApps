// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using System.Threading;

codeunit 6913 "EA Corp Card Stats Calculator"
{
    Access = Internal;
    InherentEntitlements = X;

    trigger OnRun()
    var
        Results: Dictionary of [Text, Text];
    begin
        Results.Add(GetTotalBatchesKey(), Format(GetTotalBatches()));
        Results.Add(GetTotalTransactionsKey(), Format(GetTotalTransactions()));
        Results.Add(GetMatchSuccessRateKey(), Format(GetMatchSuccessRate()));
        Results.Add(GetExceptionRateKey(), Format(GetExceptionRate()));
        Results.Add(GetDuplicateRateKey(), Format(GetDuplicateRate()));
        Results.Add(GetUnmatchedCountKey(), Format(GetUnmatchedTransactionCount()));
        Results.Add(GetDraftCountKey(), Format(GetDraftExpenseCount()));
        Results.Add(GetExceptionCountKey(), Format(GetPendingExceptionCount()));
        Results.Add(GetEnabledProvidersKey(), Format(GetEnabledProviderCount()));
        Results.Add(GetScheduledImportsKey(), Format(GetScheduledImportCount()));
        Results.Add(GetTotalActiveCardsKey(), Format(GetActiveCardCount()));
        Page.SetBackgroundTaskResult(Results);
    end;

    internal procedure GetTotalBatchesKey(): Text
    begin
        exit('totalBatches');
    end;

    internal procedure GetTotalTransactionsKey(): Text
    begin
        exit('totalTransactions');
    end;

    internal procedure GetMatchSuccessRateKey(): Text
    begin
        exit('matchSuccessRate');
    end;

    internal procedure GetExceptionRateKey(): Text
    begin
        exit('exceptionRate');
    end;

    internal procedure GetDuplicateRateKey(): Text
    begin
        exit('duplicateRate');
    end;

    internal procedure GetUnmatchedCountKey(): Text
    begin
        exit('unmatchedCount');
    end;

    internal procedure GetDraftCountKey(): Text
    begin
        exit('draftCount');
    end;

    internal procedure GetExceptionCountKey(): Text
    begin
        exit('exceptionCount');
    end;

    internal procedure GetEnabledProvidersKey(): Text
    begin
        exit('enabledProviders');
    end;

    internal procedure GetScheduledImportsKey(): Text
    begin
        exit('scheduledImports');
    end;

    internal procedure GetTotalActiveCardsKey(): Text
    begin
        exit('totalActiveCards');
    end;

    local procedure GetTotalBatches(): Integer
    var
        CorpCardBatch: Record "EA Corp Card Batch";
    begin
        SetRecentBatchFilter(CorpCardBatch);
        exit(CorpCardBatch.Count());
    end;

    local procedure GetTotalTransactions(): Integer
    var
        CorpCardBatch: Record "EA Corp Card Batch";
    begin
        SetRecentBatchFilter(CorpCardBatch);
        CorpCardBatch.CalcSums(Imported);
        exit(CorpCardBatch.Imported);
    end;

    local procedure GetMatchSuccessRate(): Decimal
    var
        CorpCardTrans: Record "EA Corp Card Trans";
        TotalCount: Integer;
        MatchedCount: Integer;
    begin
        CorpCardTrans.SetFilter("Trans Date", '>=%1', Today() - 30);
        TotalCount := CorpCardTrans.Count();
        if TotalCount = 0 then
            exit(0);

        CorpCardTrans.SetFilter(Status, '%1|%2', CorpCardTrans.Status::Matched, CorpCardTrans.Status::DraftCreated);
        MatchedCount := CorpCardTrans.Count();
        exit((MatchedCount / TotalCount) * 100);
    end;

    local procedure GetExceptionRate(): Decimal
    var
        CorpCardTrans: Record "EA Corp Card Trans";
        TotalCount: Integer;
        ExceptionCount: Integer;
    begin
        CorpCardTrans.SetFilter("Trans Date", '>=%1', Today() - 30);
        TotalCount := CorpCardTrans.Count();
        if TotalCount = 0 then
            exit(0);

        CorpCardTrans.SetRange(Status, CorpCardTrans.Status::Exception);
        ExceptionCount := CorpCardTrans.Count();
        exit((ExceptionCount / TotalCount) * 100);
    end;

    local procedure GetDuplicateRate(): Decimal
    var
        CorpCardBatch: Record "EA Corp Card Batch";
        TotalCount: Integer;
        DuplicateCount: Integer;
    begin
        SetRecentBatchFilter(CorpCardBatch);
        CorpCardBatch.CalcSums(Imported, Duplicates);
        TotalCount := CorpCardBatch.Imported;
        if TotalCount = 0 then
            exit(0);

        DuplicateCount := CorpCardBatch.Duplicates;
        exit((DuplicateCount / TotalCount) * 100);
    end;

    local procedure GetUnmatchedTransactionCount(): Integer
    var
        CorpCardTrans: Record "EA Corp Card Trans";
    begin
        CorpCardTrans.SetRange(Status, CorpCardTrans.Status::Imported);
        exit(CorpCardTrans.Count());
    end;

    local procedure GetDraftExpenseCount(): Integer
    var
        CorpCardTrans: Record "EA Corp Card Trans";
    begin
        CorpCardTrans.SetRange(Status, CorpCardTrans.Status::DraftCreated);
        exit(CorpCardTrans.Count());
    end;

    local procedure GetPendingExceptionCount(): Integer
    var
        CorpCardException: Record "EA Corp Card Exception";
    begin
        CorpCardException.SetRange(Resolved, false);
        exit(CorpCardException.Count());
    end;

    local procedure GetEnabledProviderCount(): Integer
    var
        CorpCardProvider: Record "EA Corp Card Provider";
    begin
        CorpCardProvider.SetRange(Enabled, true);
        exit(CorpCardProvider.Count());
    end;

    local procedure GetScheduledImportCount(): Integer
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);
        JobQueueEntry.SetRange("Object ID to Run", Codeunit::"EA Corp Card JQ Runner");
        JobQueueEntry.SetRange("Recurring Job", true);
        exit(JobQueueEntry.Count());
    end;

    local procedure GetActiveCardCount(): Integer
    var
        CorpCard: Record "EA Corp Card";
    begin
        CorpCard.SetRange(Blocked, false);
        CorpCard.SetFilter("Valid From", '%1|..%2', 0D, Today());
        CorpCard.SetFilter("Valid To", '%1|%2..', 0D, Today());
        exit(CorpCard.Count());
    end;

    local procedure SetRecentBatchFilter(var CorpCardBatch: Record "EA Corp Card Batch")
    begin
        CorpCardBatch.SetFilter("Started DT", '>=%1', CreateDateTime(Today() - 30, 0T));
    end;
}
