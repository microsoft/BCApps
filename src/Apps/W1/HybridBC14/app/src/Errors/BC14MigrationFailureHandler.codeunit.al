// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14Reimplementation;

using Microsoft.DataMigration;
using System.Integration;
using System.Reflection;

codeunit 46860 "BC14 Migration Failure Handler"
{
    Access = Internal;
    TableNo = "Hybrid Replication Summary";

    var
        BC14Telemetry: Codeunit "BC14 Telemetry";

    trigger OnRun()
    var
        BC14MigrationRunner: Codeunit "BC14 Migration Runner";
        BC14MigrationOrchestrator: Codeunit "BC14 Migration Orchestrator";
        BC14StatusMgr: Codeunit "BC14 Migration Status Mgr.";
        IsMainMigrationTask: Boolean;
    begin
        IsMainMigrationTask := Rec."Run ID" <> '';

        MarkUpgradeFailed(Rec);

        Commit();
        BC14MigrationRunner.FailMigration();

        Commit();
        if IsMainMigrationTask then
            BC14StatusMgr.SetSummaryFailed(Rec)
        else
            BC14MigrationOrchestrator.TryFinalizeOverallUpgrade();
    end;

    internal procedure MarkUpgradeFailed(var HybridReplicationSummary: Record "Hybrid Replication Summary")
    var
        BC14CompanySettings: Record BC14CompanyMigrationInfo;
        BC14MigrationOrchestrator: Codeunit "BC14 Migration Orchestrator";
        BC14StatusMgr: Codeunit "BC14 Migration Status Mgr.";
        ErrorText: Text;
        ErrorCallStack: Text;
        DetailedError: Text;
    begin
        ErrorText := GetLastErrorText();
        ErrorCallStack := GetLastErrorCallStack();
        LogUnhandledErrorToErrorPage(ErrorText);

        DetailedError := GetDetailedUpgradeErrorSummary();

        if ErrorText = '' then
            ErrorText := DetailedError
        else
            ErrorText := ErrorText + NewLine() + DetailedError;

        BC14StatusMgr.MarkCompanyFailed(CopyStr(CompanyName(), 1, 30), ErrorText);
        Commit();

        if not HybridReplicationSummary.Find() then begin
            BC14CompanySettings.ReadIsolation := IsolationLevel::UpdLock;
            BC14CompanySettings.GetSingleInstance();
            if not BC14CompanySettings."Historical Dispatched" then begin
                Commit();
                exit;
            end;
            if BC14StatusMgr.IsCompanyFailed(CopyStr(CompanyName(), 1, 30)) then
                BC14CompanySettings.ClearHistoricalDispatched()
            else
                BC14CompanySettings.SetHistoricalCompleted();
            Commit();

            if not BC14MigrationOrchestrator.FindLatestReplicationSummary(HybridReplicationSummary) then begin
                Session.LogMessage('0000TV5', UpgradeFailedMsg, Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', BC14Telemetry.GetCategory());
                exit;
            end;
        end;

        // Write error details to the Summary's Details blob for diagnostics.
        AppendDetailsToSummary(HybridReplicationSummary, ErrorText, ErrorCallStack);

        Session.LogMessage('0000TV6', UpgradeFailedMsg, Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', BC14Telemetry.GetCategory());
    end;

    local procedure LogUnhandledErrorToErrorPage(ErrorText: Text)
    var
        DataMigrationError: Record "Data Migration Error";
        ErrorCallStack: Text;
    begin
        if ErrorText = '' then
            exit;

        DataMigrationError.SetRange("Error Dismissed", false);
        if not DataMigrationError.IsEmpty() then
            exit;

        ErrorCallStack := GetLastErrorCallStack();

        if ErrorCallStack <> '' then
            ErrorText := ErrorText + ' | Call Stack: ' + ErrorCallStack;

        DataMigrationError.Init();
        DataMigrationError."Migration Type" := UnhandledUpgradeErrorLbl;
        DataMigrationError."Source Table ID" := 0;
        DataMigrationError."Source Table Name" := UnhandledUpgradeErrorLbl;
        DataMigrationError."Error Message" := CopyStr(ErrorText, 1, MaxStrLen(DataMigrationError."Error Message"));
        DataMigrationError."Created On" := CurrentDateTime();
        DataMigrationError."Company Name" := CopyStr(CompanyName(), 1, MaxStrLen(DataMigrationError."Company Name"));
        if not DataMigrationError.Insert(false) then
            Session.LogMessage('0000TV7', FailedToInsertErrorRecordLbl, Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', BC14Telemetry.GetCategory());

        Session.LogMessage('0000TV8', StrSubstNo(UnhandledErrorTelemetryLbl, ErrorText), Verbosity::Error, DataClassification::CustomerContent, TelemetryScope::ExtensionPublisher, 'Category', BC14Telemetry.GetCategory());
    end;

    local procedure GetDetailedUpgradeErrorSummary(): Text
    var
        DataMigrationError: Record "Data Migration Error";
    begin
        DataMigrationError.SetRange("Error Dismissed", false);

        if DataMigrationError.IsEmpty() then
            exit(UnknownUpgradeErr);

        exit(StrSubstNo(ErrorCountSummaryTxt, DataMigrationError.Count()));
    end;

    local procedure AppendDetailsToSummary(var HybridReplicationSummary: Record "Hybrid Replication Summary"; ErrorText: Text; ErrorCallStack: Text)
    var
        DetailsInStream: InStream;
        DetailsOutStream: OutStream;
        ExistingDetails: Text;
        NewEntry: Text;
    begin
        HybridReplicationSummary.ReadIsolation := IsolationLevel::UpdLock;
        if not HybridReplicationSummary.Find() then
            exit;

        // Read existing details
        if HybridReplicationSummary.Details.HasValue() then begin
            HybridReplicationSummary.Details.CreateInStream(DetailsInStream);
            DetailsInStream.Read(ExistingDetails);
        end;

        // Build new entry with company name. Use real newline characters so the
        // text renders as multiple lines in MultiLine page fields.
        if ErrorCallStack <> '' then
            NewEntry := StrSubstNo(UpgradeFailedCompanyDetailsTxt, CompanyName(), ErrorText + NewLine() + 'Call Stack:' + NewLine() + ErrorCallStack)
        else
            NewEntry := StrSubstNo(UpgradeFailedCompanyDetailsTxt, CompanyName(), ErrorText);

        // Append to existing (blank line between entries)
        if ExistingDetails <> '' then
            NewEntry := ExistingDetails + NewLine() + NewLine() + NewEntry;

        HybridReplicationSummary.Details.CreateOutStream(DetailsOutStream);
        DetailsOutStream.Write(NewEntry);
        HybridReplicationSummary.Modify();
    end;

    local procedure NewLine(): Text
    var
        TypeHelper: Codeunit "Type Helper";
    begin
        exit(TypeHelper.CRLFSeparator());
    end;

    var
        UpgradeFailedMsg: Label 'Business Central 14 upgrade failed.', Locked = true;
        UpgradeFailedCompanyDetailsTxt: Label 'Upgrade failed for company %1: %2', Comment = '%1 = Company Name, %2 = Error message';
        UnknownUpgradeErr: Label 'Upgrade failed with unknown error. Check Business Central 14 Migration Errors page for details.';
        ErrorCountSummaryTxt: Label 'Upgrade failed. Number of errors: %1. See Business Central 14 Migration Errors page for details.', Comment = '%1 = Number of errors';
        UnhandledUpgradeErrorLbl: Label 'Unhandled Upgrade Error';
        UnhandledErrorTelemetryLbl: Label 'Unhandled upgrade error: %1', Locked = true, Comment = '%1 = Error text with call stack';
        FailedToInsertErrorRecordLbl: Label 'Failed to insert unhandled error record to Data Migration Error table.', Locked = true;
}
