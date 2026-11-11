// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Agent.PayablesAgent;

using System.Email;

codeunit 3322 "PA Email Cleanup"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;
    Permissions = tabledata "Email Inbox" = rd;

    var
        CleanupCompletedTelemetryLbl: Label 'Payables Agent email duplicate cleanup completed.', Locked = true;
        ScanCompletedTelemetryLbl: Label 'Payables Agent email duplicate scan completed.', Locked = true;

    /// <summary>
    /// Scans the Email Inbox and fills the buffer with one row per duplicate group.
    /// </summary>
    procedure BuildDuplicateGroups(var TempDuplicateBuffer: Record "PA Email Duplicate Buffer" temporary) TotalDeletable: Integer
    var
        EmailInbox: Record "Email Inbox";
        GroupMessageIds: List of [Guid];
        CurrentAccountId: Guid;
        CurrentExternalId: Text[2048];
        GroupStarted: Boolean;
        NextEntryNo: Integer;
    begin
        TempDuplicateBuffer.Reset();
        TempDuplicateBuffer.DeleteAll();
        TotalDeletable := 0;

        EmailInbox.ReadIsolation(IsolationLevel::ReadCommitted);
        EmailInbox.SetCurrentKey("Account Id", "External Message Id");
        EmailInbox.Ascending(true);
        EmailInbox.SetFilter("External Message Id", '<>%1', '');
        EmailInbox.SetLoadFields(Id, "Account Id", "External Message Id", "Received DateTime", "Sender Address", Description, "Message Id");
        if not EmailInbox.FindSet() then
            exit(0);

        // The current key orders rows by Account Id, then External Message Id, so all copies of one email arrive consecutively.
        repeat
            if not GroupStarted then begin
                CurrentAccountId := EmailInbox."Account Id";
                CurrentExternalId := EmailInbox."External Message Id";
                StartGroup(TempDuplicateBuffer, EmailInbox, GroupMessageIds);
                GroupStarted := true;
            end else
                if (EmailInbox."Account Id" <> CurrentAccountId) or (EmailInbox."External Message Id" <> CurrentExternalId) then begin
                    TotalDeletable += FlushGroup(TempDuplicateBuffer, NextEntryNo, GroupMessageIds);
                    CurrentAccountId := EmailInbox."Account Id";
                    CurrentExternalId := EmailInbox."External Message Id";
                    StartGroup(TempDuplicateBuffer, EmailInbox, GroupMessageIds);
                end else
                    ExtendGroup(TempDuplicateBuffer, EmailInbox, GroupMessageIds);
        until EmailInbox.Next() = 0;
        if GroupStarted then
            TotalDeletable += FlushGroup(TempDuplicateBuffer, NextEntryNo, GroupMessageIds);

        TempDuplicateBuffer.Reset();
        TempDuplicateBuffer.SetCurrentKey("Redundant Count");
        TempDuplicateBuffer.Ascending(false);

        LogScanTelemetry(TempDuplicateBuffer.Count(), TotalDeletable);
    end;

    procedure GetDuplicateStatistics(var GroupCount: Integer; var RedundantRowCount: Integer; var SkippedRowCount: Integer)
    var
        TempDuplicateBuffer: Record "PA Email Duplicate Buffer" temporary;
    begin
        RedundantRowCount := BuildDuplicateGroups(TempDuplicateBuffer);
        GroupCount := TempDuplicateBuffer.Count();
        SkippedRowCount := 0;
        if TempDuplicateBuffer.FindSet() then
            repeat
                SkippedRowCount += TempDuplicateBuffer."Skipped Count";
            until TempDuplicateBuffer.Next() = 0;
    end;

    /// <summary>
    /// Deletes every safe-to-delete redundant Email Inbox row, keeping the oldest copy of each email and leaving skipped copies untouched.
    /// </summary>
    procedure CleanUpDuplicates() DeletedCount: Integer
    var
        Setup: Record "PA Email Cleanup Setup";
        TempDuplicateBuffer: Record "PA Email Duplicate Buffer" temporary;
        CommitBatchSize: Integer;
        DeleteLimit: Integer;
        SkippedCount: Integer;
        UncommittedCount: Integer;
    begin
        CommitBatchSize := Setup.GetCommitBatchSize();
        DeleteLimit := Setup.GetDeletionLimit();

        BuildDuplicateGroups(TempDuplicateBuffer);

        TempDuplicateBuffer.Reset();
        if TempDuplicateBuffer.FindSet() then
            repeat
                DeleteRedundantRowsOfGroup(TempDuplicateBuffer, CommitBatchSize, DeleteLimit, DeletedCount, SkippedCount, UncommittedCount);
            until (TempDuplicateBuffer.Next() = 0) or ((DeleteLimit > 0) and (DeletedCount >= DeleteLimit));
        if UncommittedCount > 0 then
            Commit();

        RecordLastRun(DeletedCount, SkippedCount);
        LogCleanupTelemetry(DeletedCount, SkippedCount, CommitBatchSize, DeleteLimit);
    end;

    internal procedure DeleteRedundantRowsOfGroup(var TempDuplicateBuffer: Record "PA Email Duplicate Buffer" temporary; CommitBatchSize: Integer; DeleteLimit: Integer; var DeletedCount: Integer; var SkippedCount: Integer; var UncommittedCount: Integer)
    var
        EmailInbox: Record "Email Inbox";
        EmailInboxToDelete: Record "Email Inbox";
        IsFirst: Boolean;
    begin
        EmailInbox.SetRange("Account Id", TempDuplicateBuffer."Account Id");
        EmailInbox.SetRange("External Message Id", TempDuplicateBuffer."External Message Id");
        EmailInbox.SetCurrentKey(Id);
        EmailInbox.SetAscending(Id, true);
        EmailInbox.SetLoadFields(Id, "Message Id");
        if not EmailInbox.FindSet() then
            exit;

        IsFirst := true;
        repeat
            if (DeleteLimit > 0) and (DeletedCount >= DeleteLimit) then
                exit;
            if IsFirst then
                IsFirst := false
            else
                if not IsSafeToDelete(EmailInbox."Message Id") then
                    SkippedCount += 1
                else
                    if EmailInboxToDelete.Get(EmailInbox.Id) then
                        if Codeunit.Run(Codeunit::"PA Email Inbox Row Delete", EmailInboxToDelete) then begin
                            DeletedCount += 1;
                            UncommittedCount += 1;
                            if UncommittedCount >= CommitBatchSize then begin
                                Commit();
                                UncommittedCount := 0;
                            end;
                        end else
                            SkippedCount += 1;
        until EmailInbox.Next() = 0;
    end;

    internal procedure IsSafeToDelete(MessageId: Guid): Boolean
    var
        EmailInbox: Record "Email Inbox";
    begin
        if IsNullGuid(MessageId) then
            exit(true);

        EmailInbox.ReadIsolation(IsolationLevel::ReadCommitted);
        EmailInbox.SetRange("Message Id", MessageId);
        exit(EmailInbox.Count() <= 1);
    end;

    local procedure StartGroup(var TempDuplicateBuffer: Record "PA Email Duplicate Buffer" temporary; var EmailInbox: Record "Email Inbox"; var GroupMessageIds: List of [Guid])
    begin
        TempDuplicateBuffer.Init();
        TempDuplicateBuffer."Account Id" := EmailInbox."Account Id";
        TempDuplicateBuffer."External Message Id" := EmailInbox."External Message Id";
        TempDuplicateBuffer."Keep Email Inbox Id" := EmailInbox.Id;
        TempDuplicateBuffer."Duplicate Count" := 1;
        TempDuplicateBuffer."Sender Address" := EmailInbox."Sender Address";
        TempDuplicateBuffer.Description := EmailInbox.Description;
        TempDuplicateBuffer."Oldest Received DateTime" := EmailInbox."Received DateTime";
        TempDuplicateBuffer."Newest Received DateTime" := EmailInbox."Received DateTime";
        Clear(GroupMessageIds);
        GroupMessageIds.Add(EmailInbox."Message Id");
    end;

    local procedure ExtendGroup(var TempDuplicateBuffer: Record "PA Email Duplicate Buffer" temporary; var EmailInbox: Record "Email Inbox"; var GroupMessageIds: List of [Guid])
    begin
        TempDuplicateBuffer."Duplicate Count" += 1;
        if EmailInbox."Received DateTime" < TempDuplicateBuffer."Oldest Received DateTime" then
            TempDuplicateBuffer."Oldest Received DateTime" := EmailInbox."Received DateTime";
        if EmailInbox."Received DateTime" > TempDuplicateBuffer."Newest Received DateTime" then
            TempDuplicateBuffer."Newest Received DateTime" := EmailInbox."Received DateTime";
        GroupMessageIds.Add(EmailInbox."Message Id");
    end;

    local procedure FlushGroup(var TempDuplicateBuffer: Record "PA Email Duplicate Buffer" temporary; var NextEntryNo: Integer; var GroupMessageIds: List of [Guid]): Integer
    var
        Deletable: Integer;
        Skipped: Integer;
        Index: Integer;
    begin
        if GroupMessageIds.Count() < 2 then
            exit(0);
        for Index := 2 to GroupMessageIds.Count() do
            if IsSafeToDelete(GroupMessageIds.Get(Index)) then
                Deletable += 1
            else
                Skipped += 1;

        NextEntryNo += 1;
        TempDuplicateBuffer."Entry No." := NextEntryNo;
        TempDuplicateBuffer."Redundant Count" := Deletable;
        TempDuplicateBuffer."Skipped Count" := Skipped;
        TempDuplicateBuffer.Insert();
        exit(Deletable);
    end;

    local procedure RecordLastRun(DeletedCount: Integer; SkippedCount: Integer)
    var
        Setup: Record "PA Email Cleanup Setup";
    begin
        Setup.GetSingleton();
        Setup."Last Run At" := CurrentDateTime();
        Setup."Last Deleted Count" := DeletedCount;
        Setup."Last Skipped Count" := SkippedCount;
        Setup.Modify();
    end;

    local procedure LogCleanupTelemetry(DeletedCount: Integer; SkippedCount: Integer; CommitBatchSize: Integer; DeleteLimit: Integer)
    var
        CustomDimensions: Dictionary of [Text, Text];
    begin
        CustomDimensions.Add('DeletedRows', Format(DeletedCount));
        CustomDimensions.Add('SkippedRows', Format(SkippedCount));
        CustomDimensions.Add('CommitBatchSize', Format(CommitBatchSize));
        CustomDimensions.Add('DeleteLimit', Format(DeleteLimit));
        Session.LogMessage('0000VMY', CleanupCompletedTelemetryLbl, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, CustomDimensions);
    end;

    local procedure LogScanTelemetry(GroupCount: Integer; DeletableRowCount: Integer)
    var
        CustomDimensions: Dictionary of [Text, Text];
    begin
        CustomDimensions.Add('DuplicateGroups', Format(GroupCount));
        CustomDimensions.Add('DeletableRows', Format(DeletableRowCount));
        Session.LogMessage('0000VMZ', ScanCompletedTelemetryLbl, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, CustomDimensions);
    end;
}
