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

    /// <summary>
    /// Returns how many times the subscriber to the OnApplyRetentionPolicyRecordLimitExceeded event was raised.
    /// </summary>
    /// <returns>Returns how many times the subscriber to the OnApplyRetentionPolicyRecordLimitExceeded event was raised.</returns>
    procedure GetRecordLimitExceededSubscriberCount(): Integer
    begin
        exit(RecordLimitExceededSubscriberCount);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Apply Retention Policy", 'OnApplyRetentionPolicyRecordLimitExceeded', '', false, false)]
    local procedure OnApplyRetentionPolicyRecordLimitExceeded(CurrTableId: Integer; NumberOfRecordsRemainingToBeDeleted: Integer)
    begin
        RecordLimitExceededSubscriberCount += 1;
    end;

    /// <summary>
    /// Gets the value for maximum number of records to delete in one retention policy run.
    /// </summary>
    /// <returns>The maximum number of records to delete.</returns>
    procedure MaxNumberOfRecordsToDelete(): Integer
    var
        ApplyRetentionPolicyImpl: Codeunit "Apply Retention Policy Impl.";
    begin
        exit(ApplyRetentionPolicyImpl.MaxNumberOfRecordsToDelete());
    end;

    /// <summary>
    /// Gets the value of the buffer added to the max number of records to delete.
    /// </summary>
    /// <returns>The maximum number of records to delete buffer.</returns>
    procedure MaxNumberOfRecordsToDeleteBuffer(): Integer
    var
        ApplyRetentionPolicyImpl: Codeunit "Apply Retention Policy Impl.";
    begin
        exit(ApplyRetentionPolicyImpl.NumberOfRecordsToDeleteBuffer());
    end;

    /// <summary>
    /// Gets the table ID for the Retention Policy Log Entry.
    /// </summary>
    /// <returns>The table ID for the Retention Policy Log Entry.</returns>
    procedure RetentionPolicyLogEntryTableId(): Integer
    begin
        exit(Database::"Retention Policy Log Entry")
    end;

    /// <summary>
    /// Gets the field number for the SystemCreatedAt field in the Retention Policy Log Entry table.
    /// </summary>
    /// <returns>The field number for the SystemCreatedAt field.</returns>
    procedure RetentionPolicyLogEntrySystemCreatedAtFieldNo(): Integer
    var
        RetentionPolicyLogEntry: Record "Retention Policy Log Entry";
    begin
        exit(RetentionPolicyLogEntry.FieldNo(SystemCreatedAt))
    end;

    /// <summary>
    /// Gets the entry number of the last record in the Retention Policy Log Entry table.
    /// </summary>
    /// <returns>The entry number of the last record.</returns>
    procedure RetentionPolicyLogLastEntryNo(): Integer
    var
        RetentionPolicyLogEntry: Record "Retention Policy Log Entry";
    begin
        if RetentionPolicyLogEntry.FindLast() then;
        exit(RetentionPolicyLogEntry."Entry No.");
    end;

    /// <summary>
    /// Gets the field values of a specific Retention Policy Log Entry.
    /// </summary>
    /// <param name="EntryNo">The entry number of the log entry.</param>
    /// <returns>A dictionary containing the field values of the log entry.</returns>
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

    /// <summary>
    /// Gets the field values of the Retention Policy Log Entry with EntryNo or the closest higher EntryNo.
    /// </summary>
    /// <param name="EntryNo">The entry number of the log entry.</param>
    /// <returns>A dictionary containing the field values of the log entry.</returns>
    procedure GetNextRetentionPolicyLogEntry(EntryNo: Integer) FieldValues: Dictionary of [Text, Text]
    var
        RetentionPolicyLogEntry: Record "Retention Policy Log Entry";
    begin
        SelectLatestVersion(Database::"Retention Policy Log Entry");
        RetentionPolicyLogEntry.SetFilter("Entry No.", '%1..', EntryNo);
        RetentionPolicyLogEntry.FindFirst();
        FieldValues.Add('MessageType', Format(RetentionPolicyLogEntry."Message Type"));
        FieldValues.Add('Category', Format(RetentionPolicyLogEntry.Category));
        FieldValues.Add('Message', RetentionPolicyLogEntry.Message);
    end;

    /// <summary>
    /// Raises the OnRefreshAllowedTables event in the Reten. Pol. Allowed Tables codeunit.
    /// </summary>
    procedure RaiseOnRefreshAllowedTables()
    var
        RetenPolAllowedTables: Codeunit "Reten. Pol. Allowed Tables";
    begin
        RetenPolAllowedTables.OnRefreshAllowedTables();
    end;

    /// <summary>
    /// Runs the Apply Retention Policy Implementation codeunit.
    /// </summary>
    /// <param name="RetentionPolicySetup">The Retention Policy Setup record.</param>
    /// <returns>True if the codeunit runs successfully; otherwise, false.</returns>
    procedure RunApplyRetentionPolicyImpl(var RetentionPolicySetup: Record "Retention Policy Setup"): Boolean
    begin
        exit(Codeunit.Run(Codeunit::"Apply Retention Policy Impl.", RetentionPolicySetup))
    end;

    /// <summary>
    /// Sets the Locked field on a Retention Policy Setup Line record.
    /// </summary>
    /// <param name="RetentionPolicySetupLine">The Retention Policy Setup Line record.</param>
    /// <param name="Locked">The value to set for the Locked field.</param>
    procedure SetLockedFieldOnRetentionPolicySetupLine(var RetentionPolicySetupLine: Record "Retention Policy Setup Line"; Locked: Boolean)
    begin
        RetentionPolicySetupLine.Locked := Locked;
    end;

    /// <summary>
    /// Sets a range filter on the Locked field of a Retention Policy Setup Line record.
    /// </summary>
    /// <param name="RetentionPolicySetupLine">The Retention Policy Setup Line record.</param>
    /// <param name="Locked">The value to set for the range filter on the Locked field.</param>
    procedure SetRangeFilterOnLockedFieldOnRetentionPolicySetupLine(var RetentionPolicySetupLine: Record "Retention Policy Setup Line"; Locked: Boolean)
    begin
#pragma warning disable AA0210 // The table Retention Policy Setup Line does not contain a key with the field Locked.
        RetentionPolicySetupLine.SetRange(Locked, Locked);
#pragma warning restore AA0210
    end;
}