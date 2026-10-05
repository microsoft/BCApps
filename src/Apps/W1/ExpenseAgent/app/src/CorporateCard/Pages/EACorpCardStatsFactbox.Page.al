// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

page 7442 "EA Corp Card Stats Factbox"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Corporate Card Statistics';
    PageType = CardPart;

    layout
    {
        area(Content)
        {
            group(ImportStatistics)
            {
                Caption = 'Import Statistics (Last 30 Days)';
                ShowCaption = true;
                field(TotalStatements; TotalStatements)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Total Statements';
                    DrillDown = true;
                    Editable = false;
                    ToolTip = 'Specifies the total number of imported statements in the last 30 days.';

                    trigger OnDrillDown()
                    var
                        CorpCardStatement: Record "EA Corp Card Statement";
                    begin
                        CorpCardStatement.SetFilter("Started DT", '>=%1', CreateDateTime(Today() - 30, 0T));
                        Page.Run(Page::"EA Corp Card Statements", CorpCardStatement);
                    end;
                }
                field(TotalTransactions; TotalTransactions)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Total Transactions';
                    DrillDown = true;
                    Editable = false;
                    ToolTip = 'Specifies the total number of transactions imported in the last 30 days.';

                    trigger OnDrillDown()
                    var
                        CorpCardTrans: Record "EA Corp Card Trans";
                    begin
                        CorpCardTrans.SetFilter("Trans Date", '>=%1', Today() - 30);
                        Page.Run(Page::"EA Corp Card Trans List", CorpCardTrans);
                    end;
                }
                field(MatchSuccessRate; MatchSuccessRate)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 0;
                    Caption = 'Match Success Rate (%)';
                    DecimalPlaces = 1;
                    DrillDown = true;
                    Editable = false;
                    ToolTip = 'Specifies the percentage of transactions successfully matched to expenses. Select the value to view the matched transactions.';

                    trigger OnDrillDown()
                    var
                        CorpCardTrans: Record "EA Corp Card Trans";
                    begin
                        CorpCardTrans.SetFilter("Trans Date", '>=%1', Today() - 30);
                        CorpCardTrans.SetFilter(Status, '%1|%2', CorpCardTrans.Status::Matched, CorpCardTrans.Status::DraftCreated);
                        Page.Run(Page::"EA Corp Card Trans List", CorpCardTrans);
                    end;
                }
                field(ExceptionRate; ExceptionRate)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 0;
                    Caption = 'Exception Rate (%)';
                    DecimalPlaces = 1;
                    DrillDown = true;
                    Editable = false;
                    ToolTip = 'Specifies the percentage of transactions with exceptions. Select the value to view the transactions.';

                    trigger OnDrillDown()
                    var
                        CorpCardTrans: Record "EA Corp Card Trans";
                    begin
                        CorpCardTrans.SetFilter("Trans Date", '>=%1', Today() - 30);
                        CorpCardTrans.SetRange(Status, CorpCardTrans.Status::Exception);
                        Page.Run(Page::"EA Corp Card Trans List", CorpCardTrans);
                    end;
                }
                field(DuplicateRate; DuplicateRate)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 0;
                    Caption = 'Duplicate Rate (%)';
                    ToolTip = 'Specifies the percentage of duplicate transactions detected.';
                    DecimalPlaces = 1;
                    Editable = false;
                }
            }

            group(PendingActions)
            {
                Caption = 'Pending Actions';
                ShowCaption = true;
                field(UnmatchedCount; UnmatchedCount)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Unmatched Transactions';
                    DrillDown = true;
                    Editable = false;
                    ToolTip = 'Specifies the number of transactions awaiting manual matching. Select the value to view the transactions.';

                    trigger OnDrillDown()
                    var
                        CorpCardTrans: Record "EA Corp Card Trans";
                    begin
                        CorpCardTrans.SetRange(Status, CorpCardTrans.Status::Imported);
                        Page.Run(Page::"EA Corp Card Trans List", CorpCardTrans);
                    end;
                }
                field(DraftCount; DraftCount)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Draft Expenses';
                    DrillDown = true;
                    Editable = false;
                    ToolTip = 'Specifies the number of auto-created draft expenses awaiting submission. Select the value to view the related transactions.';

                    trigger OnDrillDown()
                    var
                        CorpCardTrans: Record "EA Corp Card Trans";
                    begin
                        CorpCardTrans.SetRange(Status, CorpCardTrans.Status::DraftCreated);
                        Page.Run(Page::"EA Corp Card Trans List", CorpCardTrans);
                    end;
                }
                field(ExceptionCount; ExceptionCount)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Unresolved Exceptions';
                    DrillDown = true;
                    Editable = false;
                    ToolTip = 'Specifies the number of exceptions awaiting resolution. Select the value to view the exceptions.';

                    trigger OnDrillDown()
                    var
                        CorpCardException: Record "EA Corp Card Exception";
                    begin
                        CorpCardException.SetRange(Resolved, false);
                        Page.Run(Page::"EA Corp Card Exceptions", CorpCardException);
                    end;
                }
            }

            group(ProviderStatus)
            {
                Caption = 'Provider Status';
                ShowCaption = true;
                field(EnabledProviders; EnabledProviders)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Enabled Providers';
                    DrillDown = true;
                    Editable = false;
                    ToolTip = 'Specifies the number of enabled providers ready for import. Select the value to view the providers.';

                    trigger OnDrillDown()
                    var
                        CorpCardProvider: Record "EA Corp Card Provider";
                    begin
                        CorpCardProvider.SetRange(Enabled, true);
                        Page.Run(Page::"EA Corp Card Providers", CorpCardProvider);
                    end;
                }
                field(ScheduledImports; ScheduledImports)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Scheduled Imports';
                    DrillDown = true;
                    Editable = false;
                    ToolTip = 'Specifies the number of scheduled corporate card imports. Select the value to view the schedule.';

                    trigger OnDrillDown()
                    begin
                        Page.Run(Page::"EA Corp Card JQ Schedule");
                    end;
                }
                field(TotalActiveCards; TotalActiveCards)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Total Active Cards';
                    DrillDown = true;
                    Editable = false;
                    ToolTip = 'Specifies the number of active corporate cards that are not blocked and are valid on the current date. Select the value to view the cards.';

                    trigger OnDrillDown()
                    var
                        CorpCard: Record "EA Corp Card";
                    begin
                        CorpCard.SetRange(Blocked, false);
                        CorpCard.SetFilter("Valid From", '%1|..%2', 0D, Today());
                        CorpCard.SetFilter("Valid To", '%1|%2..', 0D, Today());
                        Page.Run(Page::"EA Corp Card Cards", CorpCard);
                    end;
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

        Evaluate(TotalStatements, Results.Get(CorpCardStatsCalculator.GetTotalStatementsKey()));
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
        TotalStatements: Integer;
        TotalTransactions: Integer;
        UnmatchedCount: Integer;
        StatisticsTaskId: Integer;
}
