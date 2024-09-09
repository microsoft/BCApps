// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestLibraries.DataAdministration;

using System.DataAdministration;

codeunit 138709 "Retention Policy Test Library"
{
    EventSubscriberInstance = Manual;
    Permissions = tabledata "Retention Policy Log Entry" = r;

    var
        RecordLimitExceededSubscriberCount: Integer;

    procedure GetRecordLimitExceededSubscriberCount(): Integer
    begin
        exit(RecordLimitExceededSubscriberCount);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Apply Retention Policy", 'OnApplyRetentionPolicyRecordLimitExceeded', '', false, false)]
    local procedure OnApplyRetentionPolicyRecordLimitExceeded(CurrTableId: Integer; NumberOfRecordsRemainingToBeDeleted: Integer)
    begin
        RecordLimitExceededSubscriberCount += 1;
    end;

    procedure MaxNumberOfRecordsToDelete(): Integer
    var
        ApplyRetentionPolicyImpl: Codeunit "Apply Retention Policy Impl.";
    begin
        exit(ApplyRetentionPolicyImpl.MaxNumberOfRecordsToDelete());
    end;

    procedure MaxNumberOfRecordsToDeleteBuffer(): Integer
    var
        ApplyRetentionPolicyImpl: Codeunit "Apply Retention Policy Impl.";
    begin
        exit(ApplyRetentionPolicyImpl.NumberOfRecordsToDeleteBuffer());
    end;

    procedure RetentionPolicyLogEntryTableId(): Integer
    begin
        exit(Database::"Retention Policy Log Entry")
    end;

    procedure RetentionPolicyLogEntrySystemCreatedAtFieldNo(): Integer
    var
        RetentionPolicyLogEntry: Record "Retention Policy Log Entry";
    begin
        exit(RetentionPolicyLogEntry.FieldNo(SystemCreatedAt))
    end;

    procedure RetenionPolicyLogLastEntryNo(): Integer
    var
        RetentionPolicyLogEntry: Record "Retention Policy Log Entry";
    begin
        if RetentionPolicyLogEntry.FindLast() then;
        exit(RetentionPolicyLogEntry."Entry No.");
    end;

    procedure GetRetentionPolicyLogEntry(EntryNo: Integer) FieldValues: Dictionary of [Text, Text]
    var
        RetentionPolicyLogEntry: Record "Retention Policy Log Entry";
    begin
        SelectLatestVersion(Database::"Retention Policy Log Entry");
        RetentionPolicyLogEntry.Get(EntryNo);
        FieldValues.Add('MessageType', Format(RetentionPolicyLogEntry."Message Type"));
        FieldValues.Add('Category', Format(RetentionPolicyLogEntry.Category));
        FieldValues.Add('Message', RetentionPolicyLogEntry.Message);
    end;

}