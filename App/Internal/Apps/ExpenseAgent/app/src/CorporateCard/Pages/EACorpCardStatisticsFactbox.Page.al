// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using System.Threading;

page 7232 "EACorpCardStatisticsFactbox"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Corp Card Statistics';
    PageType = CardPart;

    layout
    {
        area(Content)
        {
            group(ImportStatistics)
            {
                Caption = 'Import Statistics (Last 30 Days)';
                ShowCaption = true;
                Enabled = false;

                field(TotalBatches; GetTotalBatches())
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Total Batches';
                    ToolTip = 'Total number of import batches in the last 30 days.';
                }
                field(TotalTransactions; GetTotalTransactions())
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Total Transactions';
                    ToolTip = 'Total transactions imported in the last 30 days.';
                }
                field(MatchSuccessRate; GetMatchSuccessRate())
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Match Success Rate (%)';
                    ToolTip = 'Percentage of transactions successfully matched to expenses.';
                    DecimalPlaces = 1;
                }
                field(ExceptionRate; GetExceptionRate())
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Exception Rate (%)';
                    ToolTip = 'Percentage of transactions with exceptions.';
                    DecimalPlaces = 1;
                }
                field(DuplicateRate; GetDuplicateRate())
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Duplicate Rate (%)';
                    ToolTip = 'Percentage of duplicate transactions detected.';
                    DecimalPlaces = 1;
                }
            }

            group(PendingActions)
            {
                Caption = 'Pending Actions';
                ShowCaption = true;
                Enabled = false;

                field(UnmatchedCount; GetUnmatchedTransactionCount())
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Unmatched Transactions';
                    ToolTip = 'Number of transactions awaiting manual matching.';
                }
                field(DraftCount; GetDraftExpenseCount())
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Draft Expenses';
                    ToolTip = 'Number of auto-created draft expenses awaiting submission.';
                }
                field(ExceptionCount; GetPendingExceptionCount())
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Unresolved Exceptions';
                    ToolTip = 'Number of exceptions awaiting resolution.';
                }
            }

            group(ProviderStatus)
            {
                Caption = 'Provider Status';
                ShowCaption = true;
                Enabled = false;

                field(EnabledProviders; GetEnabledProviderCount())
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Enabled Providers';
                    ToolTip = 'Number of enabled providers ready for import.';
                }
                field(ScheduledImports; GetScheduledImportCount())
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Scheduled Imports';
                    ToolTip = 'Number of providers with scheduled imports.';
                }
            }
        }
    }

    local procedure GetTotalBatches(): Integer
    var
        CorpCardBatch: Record EACorpCardBatch;
        DateFilter: DateTime;
    begin
        DateFilter := CreateDateTime(Today() - 30, 0T);
        CorpCardBatch.SetFilter("Started DT", '>=%1', DateFilter);
        exit(CorpCardBatch.Count());
    end;

    local procedure GetTotalTransactions(): Integer
    var
        CorpCardBatch: Record EACorpCardBatch;
        DateFilter: DateTime;
    begin
        DateFilter := CreateDateTime(Today() - 30, 0T);
        CorpCardBatch.SetFilter("Started DT", '>=%1', DateFilter);
        CorpCardBatch.CalcSums(Imported);
        exit(CorpCardBatch.Imported);
    end;

    local procedure GetMatchSuccessRate(): Decimal
    var
        CorpCardTrans: Record EACorpCardTrans;
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
        CorpCardTrans: Record EACorpCardTrans;
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
        CorpCardTrans: Record EACorpCardTrans;
        CorpCardBatch: Record EACorpCardBatch;
        TotalCount: Integer;
        DuplicateCount: Integer;
        DateFilter: DateTime;
    begin
        DateFilter := CreateDateTime(Today() - 30, 0T);
        CorpCardBatch.SetFilter("Started DT", '>=%1', DateFilter);
        CorpCardBatch.CalcSums(Imported, Duplicates);
        TotalCount := CorpCardBatch.Imported;

        if TotalCount = 0 then
            exit(0);

        DuplicateCount := CorpCardBatch.Duplicates;
        exit((DuplicateCount / TotalCount) * 100);
    end;

    local procedure GetUnmatchedTransactionCount(): Integer
    var
        CorpCardTrans: Record EACorpCardTrans;
    begin
        CorpCardTrans.SetRange(Status, CorpCardTrans.Status::Imported);
        exit(CorpCardTrans.Count());
    end;

    local procedure GetDraftExpenseCount(): Integer
    var
        CorpCardTrans: Record EACorpCardTrans;
    begin
        CorpCardTrans.SetRange(Status, CorpCardTrans.Status::DraftCreated);
        exit(CorpCardTrans.Count());
    end;

    local procedure GetPendingExceptionCount(): Integer
    var
        CorpCardException: Record EACorpCardException;
    begin
        CorpCardException.SetRange(Resolved, false);
        exit(CorpCardException.Count());
    end;

    local procedure GetEnabledProviderCount(): Integer
    var
        CorpCardProvider: Record EACorpCardProvider;
    begin
        CorpCardProvider.SetRange(Enabled, true);
        exit(CorpCardProvider.Count());
    end;

    local procedure GetScheduledImportCount(): Integer
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);
        JobQueueEntry.SetRange("Object ID to Run", Codeunit::EACorpCardJQRunner);
        JobQueueEntry.SetRange("Recurring Job", true);
        exit(JobQueueEntry.Count());
    end;
}
