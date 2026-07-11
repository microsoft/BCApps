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

    local procedure RefreshAllShops()
    var
        Shop: Record "Shpfy Shop";
    begin
        Shop.SetRange(Enabled, true);
        if Shop.FindSet() then
            repeat
                Commit();
                // Each shop runs in its own transaction so one failure does not abort the run.
                if not Codeunit.Run(Codeunit::"Shpfy Token Refresh Shop", Shop) then
                    LogRefreshFailure(Shop.Code, GetLastErrorText());
            until Shop.Next() = 0;
    end;

    local procedure LogRefreshFailure(ShopCode: Code[20]; ErrorText: Text)
    var
        CategoryTok: Label 'Shopify Integration', Locked = true;
        TokenRefreshJobFailedTxt: Label 'The scheduled Shopify token refresh failed for shop %1: %2', Comment = '%1 = shop code, %2 = error text', Locked = true;
    begin
        Session.LogMessage('', StrSubstNo(TokenRefreshJobFailedTxt, ShopCode, ErrorText), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok);
    end;

    /// <summary>
    /// Creates the recurring Job Queue Entry that runs this codeunit, unless one already exists.
    /// </summary>
    internal procedure ScheduleRefreshJob()
    var
        JobQueueEntry: Record "Job Queue Entry";
        JobQueueCategoryLbl: Label 'SHPFY', Locked = true;
        JobDescriptionTxt: Label 'Shopify: refresh expiring access tokens';
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
        Codeunit.Run(Codeunit::"Job Queue - Enqueue", JobQueueEntry);
    end;
}
