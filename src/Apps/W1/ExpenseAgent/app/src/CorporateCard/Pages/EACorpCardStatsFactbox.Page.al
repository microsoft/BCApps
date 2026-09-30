// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

page 7442 "EA Corp Card Stats Factbox"
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

                field(TotalBatches; TotalBatches)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Total Batches';
                    ToolTip = 'Specifies the total number of import batches in the last 30 days.';
                }
                field(TotalTransactions; TotalTransactions)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Total Transactions';
                    ToolTip = 'Specifies the total number of transactions imported in the last 30 days.';
                }
                field(MatchSuccessRate; MatchSuccessRate)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 0;
                    Caption = 'Match Success Rate (%)';
                    ToolTip = 'Specifies the percentage of transactions successfully matched to expenses.';
                    DecimalPlaces = 1;
                }
                field(ExceptionRate; ExceptionRate)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 0;
                    Caption = 'Exception Rate (%)';
                    ToolTip = 'Specifies the percentage of transactions with exceptions.';
                    DecimalPlaces = 1;
                }
                field(DuplicateRate; DuplicateRate)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 0;
                    Caption = 'Duplicate Rate (%)';
                    ToolTip = 'Specifies the percentage of duplicate transactions detected.';
                    DecimalPlaces = 1;
                }
            }

            group(PendingActions)
            {
                Caption = 'Pending Actions';
                ShowCaption = true;
                Enabled = false;

                field(UnmatchedCount; UnmatchedCount)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Unmatched Transactions';
                    ToolTip = 'Specifies the number of transactions awaiting manual matching.';
                }
                field(DraftCount; DraftCount)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Draft Expenses';
                    ToolTip = 'Specifies the number of auto-created draft expenses awaiting submission.';
                }
                field(ExceptionCount; ExceptionCount)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Unresolved Exceptions';
                    ToolTip = 'Specifies the number of exceptions awaiting resolution.';
                }
            }

            group(ProviderStatus)
            {
                Caption = 'Provider Status';
                ShowCaption = true;
                Enabled = false;

                field(EnabledProviders; EnabledProviders)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Enabled Providers';
                    ToolTip = 'Specifies the number of enabled providers ready for import.';
                }
                field(ScheduledImports; ScheduledImports)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Scheduled Imports';
                    ToolTip = 'Specifies the number of providers with scheduled imports.';
                }
                field(TotalActiveCards; TotalActiveCards)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Total Active Cards';
                    ToolTip = 'Specifies the number of active corporate cards that are not blocked and are valid on the current date.';
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        CurrPage.EnqueueBackgroundTask(StatisticsTaskId, Codeunit::"EA Corp Card Stats Calculator", StatisticsTaskParameters, 60000, PageBackgroundTaskErrorLevel::Warning);
    end;

    trigger OnPageBackgroundTaskCompleted(TaskId: Integer; Results: Dictionary of [Text, Text])
    var
        CorpCardStatsCalculator: Codeunit "EA Corp Card Stats Calculator";
    begin
        if TaskId <> StatisticsTaskId then
            exit;

        Evaluate(TotalBatches, Results.Get(CorpCardStatsCalculator.GetTotalBatchesKey()));
        Evaluate(TotalTransactions, Results.Get(CorpCardStatsCalculator.GetTotalTransactionsKey()));
        Evaluate(MatchSuccessRate, Results.Get(CorpCardStatsCalculator.GetMatchSuccessRateKey()));
        Evaluate(ExceptionRate, Results.Get(CorpCardStatsCalculator.GetExceptionRateKey()));
        Evaluate(DuplicateRate, Results.Get(CorpCardStatsCalculator.GetDuplicateRateKey()));
        Evaluate(UnmatchedCount, Results.Get(CorpCardStatsCalculator.GetUnmatchedCountKey()));
        Evaluate(DraftCount, Results.Get(CorpCardStatsCalculator.GetDraftCountKey()));
        Evaluate(ExceptionCount, Results.Get(CorpCardStatsCalculator.GetExceptionCountKey()));
        Evaluate(EnabledProviders, Results.Get(CorpCardStatsCalculator.GetEnabledProvidersKey()));
        Evaluate(ScheduledImports, Results.Get(CorpCardStatsCalculator.GetScheduledImportsKey()));
        Evaluate(TotalActiveCards, Results.Get(CorpCardStatsCalculator.GetTotalActiveCardsKey()));
    end;

    var
        StatisticsTaskParameters: Dictionary of [Text, Text];
        DuplicateRate: Decimal;
        ExceptionRate: Decimal;
        MatchSuccessRate: Decimal;
        DraftCount: Integer;
        EnabledProviders: Integer;
        ExceptionCount: Integer;
        ScheduledImports: Integer;
        TotalActiveCards: Integer;
        TotalBatches: Integer;
        TotalTransactions: Integer;
        UnmatchedCount: Integer;
        StatisticsTaskId: Integer;
}
