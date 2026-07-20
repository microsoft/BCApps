// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify;

using System.Threading;

/// <summary>
/// Codeunit Shpfy Token Refresh (ID 30431).
/// Proactive backstop that keeps expiring offline access tokens (and their 90-day refresh tokens)
/// alive for shops that are otherwise idle, and completes the one-time migration of legacy
/// non-expiring tokens. It complements the on-demand refresh performed before every API call.
/// Scheduled as a recurring Job Queue Entry; each shop is processed in its own transaction (via the
/// "Shpfy Token Refresh Shop" worker) so a single failing shop does not abort the whole run.
/// </summary>
codeunit 30431 "Shpfy Token Refresh"
{
    Access = Internal;
    TableNo = "Job Queue Entry";

    trigger OnRun()
    begin
        RefreshAllShops();
    end;

    var
        CategoryTok: Label 'Shopify Integration', Locked = true;
        TokenRefreshJobFailedTxt: Label 'The scheduled Shopify token refresh failed for a store.', Locked = true;
        ScheduleFailedTxt: Label 'Failed to schedule the Shopify token refresh job.', Locked = true;
        JobQueueCategoryLbl: Label 'SHPFYAUTH', Locked = true;
        JobDescriptionTxt: Label 'Shopify: refresh expiring access tokens';

    local procedure RefreshAllShops()
    var
        Shop: Record "Shpfy Shop";
    begin
        Shop.SetRange(Enabled, true);
        Shop.SetLoadFields("Shopify URL");
        if Shop.FindSet() then
            repeat
                // Each shop runs in its own transaction (Codeunit.Run) so one failure does not abort the run.
                if not Codeunit.Run(Codeunit::"Shpfy Token Refresh Shop", Shop) then
                    LogRefreshFailure(Shop.Code, GetLastErrorText());
            until Shop.Next() = 0;
    end;

    local procedure LogRefreshFailure(ShopCode: Code[20]; ErrorText: Text)
    var
        Dimensions: Dictionary of [Text, Text];
    begin
        // Keep the message generic; the error detail (which may carry customer content) goes into a
        // custom dimension and the whole event is classified accordingly.
        Dimensions.Add('Category', CategoryTok);
        Dimensions.Add('ShopCode', ShopCode);
        Dimensions.Add('ErrorText', ErrorText);
        Session.LogMessage('0000UIV', TokenRefreshJobFailedTxt, Verbosity::Warning, DataClassification::CustomerContent, TelemetryScope::ExtensionPublisher, Dimensions);
    end;

    local procedure LogScheduleFailure(ErrorText: Text)
    var
        Dimensions: Dictionary of [Text, Text];
    begin
        Dimensions.Add('Category', CategoryTok);
        Dimensions.Add('ErrorText', ErrorText);
        Session.LogMessage('0000UJ6', ScheduleFailedTxt, Verbosity::Warning, DataClassification::CustomerContent, TelemetryScope::ExtensionPublisher, Dimensions);
    end;

    /// <summary>
    /// Creates the recurring Job Queue Entry that runs this codeunit, unless one already exists.
    /// </summary>
    internal procedure ScheduleRefreshJob()
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);
        JobQueueEntry.SetRange("Object ID to Run", Codeunit::"Shpfy Token Refresh");
        if not JobQueueEntry.IsEmpty() then
            exit;

        Clear(JobQueueEntry);
        JobQueueEntry.Init();
        JobQueueEntry."Object Type to Run" := JobQueueEntry."Object Type to Run"::Codeunit;
        JobQueueEntry."Object ID to Run" := Codeunit::"Shpfy Token Refresh";
        JobQueueEntry."Recurring Job" := true;
        JobQueueEntry."Run on Mondays" := true;
        JobQueueEntry."Run on Tuesdays" := true;
        JobQueueEntry."Run on Wednesdays" := true;
        JobQueueEntry."Run on Thursdays" := true;
        JobQueueEntry."Run on Fridays" := true;
        JobQueueEntry."Run on Saturdays" := true;
        JobQueueEntry."Run on Sundays" := true;
        JobQueueEntry."No. of Minutes between Runs" := 720;
        JobQueueEntry."No. of Attempts to Run" := 5;
        JobQueueEntry.Description := CopyStr(JobDescriptionTxt, 1, MaxStrLen(JobQueueEntry.Description));
        JobQueueEntry."Job Queue Category Code" := JobQueueCategoryLbl;
        // This runs from the install/upgrade flow, where COMMIT (explicit or implicit) is not allowed.
        // "Job Queue - Enqueue" performs no implicit commit, so no prior commit is needed; the guarded
        // Codeunit.Run keeps an enqueue failure from aborting the install/upgrade.
        if not Codeunit.Run(Codeunit::"Job Queue - Enqueue", JobQueueEntry) then
            LogScheduleFailure(GetLastErrorText());
    end;
}
