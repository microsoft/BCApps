// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14Reimplementation;

using Microsoft.DataMigration;

codeunit 46858 "BC14 Migration Status Mgr."
{
    Access = Internal;

    #region Company Status — Public API

    /// <summary>
    /// Transitions a company into Started. Returns false on invalid prior state
    /// (missing row, Completed, or Failed); caller should abort the upgrade.
    /// </summary>
    procedure MarkCompanyStarted(CompanyName: Text[30]) Success: Boolean
    var
        HybridCompanyStatus: Record "Hybrid Company Status";
    begin
        if not TryGetCompanyStatus(CompanyName, HybridCompanyStatus) then
            exit(false);

        case HybridCompanyStatus."Upgrade Status" of
            HybridCompanyStatus."Upgrade Status"::Started:
                exit(true);
            HybridCompanyStatus."Upgrade Status"::Pending:
                begin
                    WriteCompanyStatus(HybridCompanyStatus, HybridCompanyStatus."Upgrade Status"::Started, '');
                    exit(true);
                end;
            else begin
                MarkCompanyFailed(CompanyName, StrSubstNo(UnexpectedStartStateErr, CompanyName, Format(HybridCompanyStatus."Upgrade Status")));
                exit(false);
            end;
        end;
    end;

    procedure MarkCompanyCompleted(CompanyName: Text[30])
    var
        HybridCompanyStatus: Record "Hybrid Company Status";
    begin
        if not TryGetCompanyStatus(CompanyName, HybridCompanyStatus) then
            exit;
        // Failed -> Completed must go through AcquireRerunSlot, never silently here.
        if HybridCompanyStatus."Upgrade Status" = HybridCompanyStatus."Upgrade Status"::Failed then
            exit;
        WriteCompanyStatus(HybridCompanyStatus, HybridCompanyStatus."Upgrade Status"::Completed, '');
    end;

    procedure MarkCompanyFailed(CompanyName: Text[30]; StatusMessage: Text)
    var
        HybridCompanyStatus: Record "Hybrid Company Status";
    begin
        if not TryGetCompanyStatus(CompanyName, HybridCompanyStatus) then
            exit;
        // Terminal-state guard: a stale FailureHandler call (e.g. crashed worker that outlived
        // a successful finalize) must not demote a Completed company back to Failed.
        if HybridCompanyStatus."Upgrade Status" = HybridCompanyStatus."Upgrade Status"::Completed then
            exit;
        WriteCompanyStatus(HybridCompanyStatus, HybridCompanyStatus."Upgrade Status"::Failed, StatusMessage);
    end;

    /// <summary>
    /// Called by FinalizeMigration after Posting + Historical complete. Does not overwrite
    /// an existing Failed (set by FailureHandler) — fail wins.
    /// </summary>
    procedure SetFinalCompanyStatus(CompanyName: Text[30]; HasErrors: Boolean)
    var
        HybridCompanyStatus: Record "Hybrid Company Status";
    begin
        if not TryGetCompanyStatus(CompanyName, HybridCompanyStatus) then
            exit;
        if HybridCompanyStatus."Upgrade Status" = HybridCompanyStatus."Upgrade Status"::Failed then
            exit;

        if HasErrors then
            WriteCompanyStatus(HybridCompanyStatus, HybridCompanyStatus."Upgrade Status"::Failed, '')
        else
            WriteCompanyStatus(HybridCompanyStatus, HybridCompanyStatus."Upgrade Status"::Completed, '');
    end;

    /// <summary>
    /// Writes an informational message to the company's Status Message blob without changing
    /// the Upgrade Status. Use when the upgrade has not failed but we want to surface a
    /// note on the Upgrading Companies page (e.g. "TaskScheduler busy, falling back to StartSession").
    /// </summary>
    procedure UpdateCompanyMessage(CompanyName: Text[30]; MessageText: Text)
    var
        HybridCompanyStatus: Record "Hybrid Company Status";
        StatusMessageOutStream: OutStream;
    begin
        HybridCompanyStatus.ReadIsolation := IsolationLevel::UpdLock;
        if not HybridCompanyStatus.Get(CompanyName) then
            exit;
        if MessageText = '' then
            Clear(HybridCompanyStatus."Upgrade Failure Message")
        else begin
            HybridCompanyStatus."Upgrade Failure Message".CreateOutStream(StatusMessageOutStream);
            StatusMessageOutStream.Write(MessageText);
        end;
        HybridCompanyStatus.Modify();
    end;

    procedure MarkPendingCompaniesAsFailed(StatusMessage: Text)
    var
        HybridCompanyStatus: Record "Hybrid Company Status";
    begin
        HybridCompanyStatus.SetFilter(Name, '<>''''');
        HybridCompanyStatus.SetRange("Upgrade Status", HybridCompanyStatus."Upgrade Status"::Pending);
        if HybridCompanyStatus.FindSet() then
            repeat
                MarkCompanyFailed(CopyStr(HybridCompanyStatus.Name, 1, 30), StatusMessage);
            until HybridCompanyStatus.Next() = 0;
    end;

    /// <summary>
    /// Flips every Failed company back to Pending so the operator can retry them after fixing
    /// the underlying data. Clears the per-row failure message — the durable error history lives
    /// in the BC14 Migration Error table, not on Hybrid Company Status. Returns the number of
    /// rows reset.
    /// </summary>
    procedure ResetFailedCompaniesToPending(): Integer
    var
        HybridCompanyStatus: Record "Hybrid Company Status";
        ResetCount: Integer;
    begin
        HybridCompanyStatus.ReadIsolation := IsolationLevel::UpdLock;
        HybridCompanyStatus.SetFilter(Name, '<>''''');
        HybridCompanyStatus.SetRange("Upgrade Status", HybridCompanyStatus."Upgrade Status"::Failed);
        if HybridCompanyStatus.FindSet() then
            repeat
                WriteCompanyStatus(HybridCompanyStatus, HybridCompanyStatus."Upgrade Status"::Pending, '');
                ResetCount += 1;
            until HybridCompanyStatus.Next() = 0;
        exit(ResetCount);
    end;

    #endregion

    #region Summary Status — Public API

    procedure SetSummaryInProgress(var HybridReplicationSummary: Record "Hybrid Replication Summary")
    var
        OutStr: OutStream;
    begin
        if not ReloadSummary(HybridReplicationSummary) then
            exit;

        if HybridReplicationSummary.Status = HybridReplicationSummary.Status::UpgradeInProgress then
            exit;

        if HybridReplicationSummary."Start Time" = 0DT then
            HybridReplicationSummary."Start Time" := CurrentDateTime();
        HybridReplicationSummary."End Time" := 0DT;
        Clear(HybridReplicationSummary.Details);
        HybridReplicationSummary.Details.CreateOutStream(OutStr, TextEncoding::UTF8);
        OutStr.WriteText(UpgradeInProgressLbl);
        WriteSummaryStatus(HybridReplicationSummary, HybridReplicationSummary.Status::UpgradeInProgress);
    end;

    procedure SetSummaryFailed(var HybridReplicationSummary: Record "Hybrid Replication Summary")
    begin
        if not ReloadSummary(HybridReplicationSummary) then
            exit;
        if IsSummaryInTerminalState(HybridReplicationSummary) then
            exit;

        HybridReplicationSummary."End Time" := CurrentDateTime();
        WriteSummaryDetails(HybridReplicationSummary, UpgradeFailedLbl);
        WriteSummaryStatus(HybridReplicationSummary, HybridReplicationSummary.Status::UpgradeFailed);
    end;

    procedure EvaluateAndSetFinalSummaryStatus(var HybridReplicationSummary: Record "Hybrid Replication Summary")
    begin
        if not ReloadSummary(HybridReplicationSummary) then
            exit;
        if IsSummaryInTerminalState(HybridReplicationSummary) then
            exit;

        if AreAllCompaniesUpgradeCompleted() then begin
            Clear(HybridReplicationSummary.Details);
            HybridReplicationSummary."End Time" := CurrentDateTime();
            WriteSummaryStatus(HybridReplicationSummary, HybridReplicationSummary.Status::Completed);
            exit;
        end;

        if AnyCompanyHasFailedUpgrade() then begin
            HybridReplicationSummary."End Time" := CurrentDateTime();
            WriteSummaryDetails(HybridReplicationSummary, UpgradeFailedLbl);
            WriteSummaryStatus(HybridReplicationSummary, HybridReplicationSummary.Status::UpgradeFailed);
            exit;
        end;

        // Some companies still Pending/Started — don't finalize yet.
    end;

    #endregion

    #region Chain and Finalize — Public API

    /// <summary>
    /// Unified post-company decision used by both the initial run and rerun paths.
    ///   Failure + Stop On First Error -> Company Failed, Summary UpgradeFailed, stop.
    ///   Failure + Continue On Error   -> Company Failed, chain to next pending company;
    ///                                    Summary failure is decided at TryFinalizeOverallStatus.
    ///   Success + Historical done     -> Company Completed, then chain or finalize.
    ///   Success + Historical pending  -> leave Company Started (Historical Worker will complete it),
    ///                                    chain anyway — Historical runs in parallel and must not block.
    /// </summary>
    procedure AfterCompanyMigrationCompleted(CompanyName: Text[30]; HasErrors: Boolean; HistoricalCompleted: Boolean; var HybridReplicationSummary: Record "Hybrid Replication Summary")
    var
        BC14CompanySettings: Record BC14CompanyMigrationInfo;
        BC14MigrationOrchestrator: Codeunit "BC14 Migration Orchestrator";
    begin
        if HasErrors then begin
            // SetFinalCompanyStatus respects an existing Failed, so this is idempotent.
            SetFinalCompanyStatus(CompanyName, true);
            Commit();

            BC14CompanySettings.GetSingleInstance();
            if BC14CompanySettings.GetStopOnFirstTransformationError() then begin
                SetSummaryFailed(HybridReplicationSummary);
                exit;
            end;
            // Continue-on-error: fall through to dispatch the next pending company. The overall
            // Summary status is reconciled in TryFinalizeOverallStatus once every company is
            // processed; AnyCompanyHasFailedUpgrade() will then flip Summary to UpgradeFailed.
        end else
            // Success: only mark Completed when Historical has also finished. Otherwise leave
            // Started so Summary counts reflect ongoing background work — the Historical Worker
            // calls FinalizeMigration -> SetFinalCompanyStatus when it's done.
            if HistoricalCompleted then begin
                SetFinalCompanyStatus(CompanyName, false);
                Commit();
            end;

        BC14MigrationOrchestrator.DispatchNextReadyCompany(HybridReplicationSummary);
    end;

    /// <summary>
    /// Idempotent: the terminal-state check makes repeat calls (e.g. from the main flow and a
    /// late Historical worker) a no-op once the summary has been finalized.
    /// </summary>
    procedure TryFinalizeOverallStatus(var HybridReplicationSummary: Record "Hybrid Replication Summary")
    begin
        if not ReloadSummary(HybridReplicationSummary) then
            exit;
        if IsSummaryInTerminalState(HybridReplicationSummary) then
            exit;
        if not AreAllCompaniesProcessed() then
            exit;

        EvaluateAndSetFinalSummaryStatus(HybridReplicationSummary);
    end;

    #endregion

    #region Rerun Preparation — Public API

    /// <summary>
    /// Atomic rerun guard. Errors if another rerun is already Started, or if the status row was
    /// wiped (e.g. Reset All Cloud Data) — never silently accept a rerun against missing state.
    /// </summary>
    procedure AcquireRerunSlot(CompanyName: Text[30])
    var
        HybridCompanyStatus: Record "Hybrid Company Status";
    begin
        if not TryGetCompanyStatus(CompanyName, HybridCompanyStatus) then
            Error(CompanyStatusMissingErr, CompanyName);
        if HybridCompanyStatus."Upgrade Status" = HybridCompanyStatus."Upgrade Status"::Started then
            Error(MigrationAlreadyRunningErr, CompanyName);

        WriteCompanyStatus(HybridCompanyStatus, HybridCompanyStatus."Upgrade Status"::Started, '');
    end;

    #endregion

    #region Queries — Public API

    procedure IsCompanyRunning(CompanyName: Text[30]): Boolean
    var
        HybridCompanyStatus: Record "Hybrid Company Status";
    begin
        if not HybridCompanyStatus.Get(CompanyName) then
            exit(false);
        exit(HybridCompanyStatus."Upgrade Status" = HybridCompanyStatus."Upgrade Status"::Started);
    end;

    procedure IsCompanyFailed(CompanyName: Text[30]): Boolean
    var
        HybridCompanyStatus: Record "Hybrid Company Status";
    begin
        if not HybridCompanyStatus.Get(CompanyName) then
            exit(false);
        exit(HybridCompanyStatus."Upgrade Status" = HybridCompanyStatus."Upgrade Status"::Failed);
    end;

    procedure HasPendingCompanies(): Boolean
    var
        HybridCompanyStatus: Record "Hybrid Company Status";
    begin
        HybridCompanyStatus.SetFilter(Name, '<>''''');
        HybridCompanyStatus.SetRange("Upgrade Status", HybridCompanyStatus."Upgrade Status"::Pending);
        exit(not HybridCompanyStatus.IsEmpty());
    end;

    procedure AnyCompanyHasFailedUpgrade(): Boolean
    var
        HybridCompanyStatus: Record "Hybrid Company Status";
    begin
        HybridCompanyStatus.SetFilter(Name, '<>''''');
        HybridCompanyStatus.SetRange("Upgrade Status", HybridCompanyStatus."Upgrade Status"::Failed);
        exit(not HybridCompanyStatus.IsEmpty());
    end;

    procedure AreAllCompaniesUpgradeCompleted(): Boolean
    var
        HybridCompanyStatus: Record "Hybrid Company Status";
        HybridCompany: Record "Hybrid Company";
    begin
        HybridCompany.SetRange(Replicate, true);
        if HybridCompany.FindSet() then
            repeat
                if not HybridCompanyStatus.Get(HybridCompany.Name) then
                    exit(false);
                if HybridCompanyStatus."Upgrade Status" <> HybridCompanyStatus."Upgrade Status"::Completed then
                    exit(false);
            until HybridCompany.Next() = 0;
        exit(true);
    end;

    procedure AreAllCompaniesProcessed(): Boolean
    var
        HybridCompanyStatus: Record "Hybrid Company Status";
        HybridCompany: Record "Hybrid Company";
    begin
        HybridCompany.SetRange(Replicate, true);
        if HybridCompany.FindSet() then
            repeat
                if not HybridCompanyStatus.Get(HybridCompany.Name) then
                    exit(false);
                if IsCompanyStillProcessing(HybridCompanyStatus."Upgrade Status") then
                    exit(false);
            until HybridCompany.Next() = 0;
        exit(true);
    end;

    procedure GetCompletedCompanyCount(): Integer
    var
        HybridCompanyStatus: Record "Hybrid Company Status";
    begin
        HybridCompanyStatus.SetFilter(Name, '<>''''');
        HybridCompanyStatus.SetRange("Upgrade Status", HybridCompanyStatus."Upgrade Status"::Completed);
        exit(HybridCompanyStatus.Count());
    end;

    /// <summary>
    /// Excludes the empty-name PerDatabase row so counts match the companies shown on the page.
    /// </summary>
    procedure GetCompanyStatusCounts(var PendingCount: Integer; var StartedCount: Integer; var CompletedCount: Integer; var FailedCount: Integer)
    var
        HybridCompanyStatus: Record "Hybrid Company Status";
    begin
        HybridCompanyStatus.SetFilter(Name, '<>''''');

        HybridCompanyStatus.SetRange("Upgrade Status", HybridCompanyStatus."Upgrade Status"::Pending);
        PendingCount := HybridCompanyStatus.Count();

        HybridCompanyStatus.SetRange("Upgrade Status", HybridCompanyStatus."Upgrade Status"::Started);
        StartedCount := HybridCompanyStatus.Count();

        HybridCompanyStatus.SetRange("Upgrade Status", HybridCompanyStatus."Upgrade Status"::Completed);
        CompletedCount := HybridCompanyStatus.Count();

        HybridCompanyStatus.SetRange("Upgrade Status", HybridCompanyStatus."Upgrade Status"::Failed);
        FailedCount := HybridCompanyStatus.Count();
    end;

    procedure FilterPendingCompanies(var HybridCompanyStatus: Record "Hybrid Company Status")
    begin
        HybridCompanyStatus.Reset();
        HybridCompanyStatus.SetFilter(Name, '<>''''');
        HybridCompanyStatus.SetRange("Upgrade Status", HybridCompanyStatus."Upgrade Status"::Pending);
    end;

    procedure FilterFailedCompanies(var HybridCompanyStatus: Record "Hybrid Company Status")
    begin
        HybridCompanyStatus.Reset();
        HybridCompanyStatus.SetFilter(Name, '<>''''');
        HybridCompanyStatus.SetRange("Upgrade Status", HybridCompanyStatus."Upgrade Status"::Failed);
    end;

    procedure GetFirstPendingCompanyName(): Text[30]
    var
        HybridCompanyStatus: Record "Hybrid Company Status";
    begin
        HybridCompanyStatus.SetFilter(Name, '<>''''');
        HybridCompanyStatus.SetRange("Upgrade Status", HybridCompanyStatus."Upgrade Status"::Pending);
        if HybridCompanyStatus.FindFirst() then
            exit(CopyStr(HybridCompanyStatus.Name, 1, 30));
    end;

    procedure PerDatabaseStatusExists(): Boolean
    var
        HybridCompanyStatus: Record "Hybrid Company Status";
    begin
        exit(HybridCompanyStatus.Get(''));
    end;

    #endregion

    #region Cleanup — Public API

    procedure DeleteAllCompanyStatus()
    var
        HybridCompanyStatus: Record "Hybrid Company Status";
    begin
        if not HybridCompanyStatus.IsEmpty() then
            HybridCompanyStatus.DeleteAll();
    end;

    procedure DeleteCompanyStatus(CompanyName: Text[30])
    var
        HybridCompanyStatus: Record "Hybrid Company Status";
    begin
        if HybridCompanyStatus.Get(CompanyName) then
            HybridCompanyStatus.Delete();
    end;

    #endregion

    #region Internal helpers — Company

    local procedure TryGetCompanyStatus(CompanyName: Text[30]; var HybridCompanyStatus: Record "Hybrid Company Status"): Boolean
    begin
        exit(HybridCompanyStatus.Get(CompanyName));
    end;

    local procedure WriteCompanyStatus(var HybridCompanyStatus: Record "Hybrid Company Status"; NewStatus: Option; StatusMessage: Text)
    var
        FreshCompanyStatus: Record "Hybrid Company Status";
        StatusMessageOutStream: OutStream;
    begin
        FreshCompanyStatus.ReadIsolation := IsolationLevel::UpdLock;
        if not FreshCompanyStatus.Get(HybridCompanyStatus.Name) then
            exit;
        FreshCompanyStatus."Upgrade Status" := NewStatus;
        if StatusMessage = '' then
            Clear(FreshCompanyStatus."Upgrade Failure Message")
        else begin
            FreshCompanyStatus."Upgrade Failure Message".CreateOutStream(StatusMessageOutStream);
            StatusMessageOutStream.Write(StatusMessage);
        end;
        FreshCompanyStatus.Modify();
        HybridCompanyStatus := FreshCompanyStatus;
        Commit();
    end;

    local procedure IsCompanyStillProcessing(UpgradeStatus: Option): Boolean
    var
        HybridCompanyStatus: Record "Hybrid Company Status";
    begin
        exit(UpgradeStatus in [
            HybridCompanyStatus."Upgrade Status"::Pending,
            HybridCompanyStatus."Upgrade Status"::Started]);
    end;

    #endregion

    #region Internal helpers — Summary

    /// <summary>
    /// Re-reads the summary row from the database to pick up writes made by concurrent workers,
    /// and eagerly CalcFields(Details) because BC does not auto-load BLOBs on Find — without it
    /// a Modify would wipe the blob. Returns false if the row no longer exists (caller exits).
    /// </summary>
    local procedure ReloadSummary(var HybridReplicationSummary: Record "Hybrid Replication Summary"): Boolean
    begin
        if not HybridReplicationSummary.Find() then
            exit(false);
        HybridReplicationSummary.CalcFields(Details);
        exit(true);
    end;

    local procedure IsSummaryInTerminalState(var HybridReplicationSummary: Record "Hybrid Replication Summary"): Boolean
    begin
        exit(HybridReplicationSummary.Status in [
            HybridReplicationSummary.Status::Completed,
            HybridReplicationSummary.Status::UpgradeFailed,
            HybridReplicationSummary.Status::Failed]);
    end;

    local procedure WriteSummaryStatus(var HybridReplicationSummary: Record "Hybrid Replication Summary"; NewStatus: Option)
    begin
        HybridReplicationSummary.Status := NewStatus;
        HybridReplicationSummary.Modify();
    end;

    local procedure WriteSummaryDetails(var HybridReplicationSummary: Record "Hybrid Replication Summary"; HeadlineText: Text)
    var
        OutStr: OutStream;
    begin
        Clear(HybridReplicationSummary.Details);
        HybridReplicationSummary.Details.CreateOutStream(OutStr, TextEncoding::UTF8);
        OutStr.WriteText(HeadlineText);
    end;

    #endregion

    var
        MigrationAlreadyRunningErr: Label 'Migration is already running for company %1. Please wait for it to complete before retrying.', Comment = '%1 = Company Name';
        CompanyStatusMissingErr: Label 'No upgrade status row exists for company %1. Run replication first.', Comment = '%1 = Company Name';
        UnexpectedStartStateErr: Label 'Cannot start upgrade for company %1: company is already in state %2. Reset the company state before retrying.', Comment = '%1 = Company Name, %2 = current Upgrade Status';
        UpgradeInProgressLbl: Label 'Upgrade in Progress';
        UpgradeFailedLbl: Label 'Business Central 14 upgrade failed. See the Business Central 14 Migration Errors page for details.';
}
