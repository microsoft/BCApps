// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14Reimplementation;

using Microsoft.DataMigration;

codeunit 46853 "BC14 Company Upgrade Task"
{
    Access = Internal;
    TableNo = "Hybrid Replication Summary";

    var
        BC14Telemetry: Codeunit "BC14 Telemetry";
        MigrationErrorOccurredLbl: Label 'An error occurred during Business Central 14 cloud migration.', Locked = true;
        CompanySetupNotCompletedFailureLbl: Label 'BC14 Company Upgrade Task aborted: company setup was not completed before the upgrade attempt. Failing the company upgrade.', Locked = true;
        RunMigrationLbl: Label 'Running Business Central 14 Migration for company.', Locked = true;
        MigrationAlreadyStartedSkippingLbl: Label 'Migration has already been started for this company. Skipping to prevent duplicate data.', Locked = true;
        MigrationRerunLbl: Label 'Previous migration did not complete. Re-running migration runner to continue/retry.', Locked = true;
        StartMigrationLbl: Label 'Starting Business Central 14 data migration: Setup -> Master -> Transactions -> Historical -> Post Journals.', Locked = true;
        MarkCompanyStartedRefusedLbl: Label 'BC14 Company Upgrade Task aborted: MarkCompanyStarted refused — status row missing or prior Upgrade Status was Completed/Failed. Reset company state before retrying.', Locked = true;

    trigger OnRun()
    begin
        ExecuteCompanyUpgrade(Rec);
    end;

    local procedure ExecuteCompanyUpgrade(var HybridReplicationSummary: Record "Hybrid Replication Summary")
    var
        BC14CompanySettings: Record BC14CompanyMigrationInfo;
        BC14MigrationErrorHandler: Codeunit "BC14 Migration Error Handler";
        BC14MigrationFailureHandler: Codeunit "BC14 Migration Failure Handler";
        BC14MigrationOrchestrator: Codeunit "BC14 Migration Orchestrator";
        BC14StatusMgr: Codeunit "BC14 Migration Status Mgr.";
        Success: Boolean;
    begin
        if BC14MigrationOrchestrator.IsCompanySetupCompleted(CopyStr(CompanyName(), 1, 50)) then begin
            BC14CompanySettings.GetSingleInstance();
            if (BC14CompanySettings.GetMigrationState() = "BC14 Migration Step"::Completed)
                and not BC14MigrationErrorHandler.ErrorOccurredInCurrentCompany() then
                BC14StatusMgr.MarkCompanyCompleted(CopyStr(CompanyName(), 1, 30))
            else
                if not BC14StatusMgr.MarkCompanyStarted(CopyStr(CompanyName(), 1, 30)) then begin
                    // MarkCompanyStarted refused (missing row or illegal prior state). It has
                    // already flagged the company on the Upgrading Companies page where possible;
                    // bail out so we don't run the migration against an invalid state.
                    Session.LogMessage('0000TU3', MarkCompanyStartedRefusedLbl, Verbosity::Error, DataClassification::OrganizationIdentifiableInformation, TelemetryScope::ExtensionPublisher, 'Category', BC14Telemetry.GetCategory());
                    BC14MigrationFailureHandler.MarkUpgradeFailed(HybridReplicationSummary);
                    Commit();
                    exit;
                end;
        end else begin
            Session.LogMessage('0000TU5', CompanySetupNotCompletedFailureLbl, Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', BC14Telemetry.GetCategory());
            BC14MigrationFailureHandler.MarkUpgradeFailed(HybridReplicationSummary);
            Commit();
            exit;
        end;
        Commit();

        BC14MigrationErrorHandler.ClearErrorOccurred();
        OnUpgradeBC14Company(Success);

        if not Success then begin
            BC14MigrationFailureHandler.MarkUpgradeFailed(HybridReplicationSummary);
            LogLastError();
            BC14MigrationErrorHandler.ClearErrorOccurred();
            Commit();
        end;

        // Defer Completed mark until Historical finishes (Worker -> TryFinalizeCompanyMigration);
        // chain advances regardless so the next company can start in parallel.
        BC14CompanySettings.GetSingleInstance();
        BC14StatusMgr.AfterCompanyMigrationCompleted(
            CopyStr(CompanyName(), 1, 30),
            not Success,
            BC14CompanySettings.IsReadyToFinalize(),
            HybridReplicationSummary);

        // Safety net: closes the gap where the last finisher is an abandoned Historical worker
        // (id mismatch) that skips TryFinalizeOverallUpgrade. Idempotent.
        Commit();
    end;

    /// <summary>
    /// Self-published event whose only subscriber is HandleOnUpgradeBC14Company below.
    /// The publish/subscribe boundary forces the subscriber to run in a fresh event-call
    /// frame so any AL error inside the migration is captured (GetLastErrorText) and turned
    /// into Success=false instead of bubbling up out of OnRun.
    /// </summary>
    [IntegrationEvent(false, false, true)]
    internal procedure OnUpgradeBC14Company(var Success: Boolean)
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"BC14 Company Upgrade Task", 'OnUpgradeBC14Company', '', false, false)]
    local procedure HandleOnUpgradeBC14Company(var Success: Boolean)
    var
        BC14MigrationErrorHandler: Codeunit "BC14 Migration Error Handler";
    begin
        BC14MigrationErrorHandler.ClearErrorOccurred();
        RunBC14Migration();
        Commit();
        Success := not BC14MigrationErrorHandler.GetErrorOccurred();
    end;

    local procedure RunBC14Migration()
    var
        BC14CompanySettings: Record BC14CompanyMigrationInfo;
        BC14MigrationErrorHandler: Codeunit "BC14 Migration Error Handler";
        BC14MigrationRunner: Codeunit "BC14 Migration Runner";
    begin
        Session.LogMessage('0000TU7', RunMigrationLbl, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', BC14Telemetry.GetCategory());

        SelectLatestVersion();
        BC14CompanySettings.GetSingleInstance();

        if BC14CompanySettings.GetMigrationState() <> "BC14 Migration Step"::NotStarted then begin
            if BC14CompanySettings.GetMigrationState() = "BC14 Migration Step"::Completed then
                if not BC14MigrationErrorHandler.ErrorOccurredInCurrentCompany() then begin
                    Session.LogMessage('0000TU8', MigrationAlreadyStartedSkippingLbl, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', BC14Telemetry.GetCategory());
                    exit;
                end;

            Session.LogMessage('0000TU9', MigrationRerunLbl, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', BC14Telemetry.GetCategory());
        end else
            Session.LogMessage('0000TUA', StartMigrationLbl, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', BC14Telemetry.GetCategory());

        BC14MigrationRunner.RunMigration();
    end;

    local procedure LogLastError()
    begin
        if GetLastErrorText() <> '' then
            Session.LogMessage('0000TUB', MigrationErrorOccurredLbl, Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', BC14Telemetry.GetCategory());
    end;
}