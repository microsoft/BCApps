// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Dimension;

/// <summary>
/// Codeunit for managing change global dimension log entries and buffer operations.
/// Provides functionality for tracking and managing global dimension change operations across multiple tables.
/// </summary>
/// <remarks>
/// Manual event subscriber instance that manages temporary log entry buffer for global dimension changes.
/// Supports table exclusion, completion tracking, and child table relationships during global dimension updates.
/// Used by the change global dimensions process to coordinate updates across related tables.
/// </remarks>
codeunit 484 "Change Global Dim. Log Mgt."
{
    EventSubscriberInstance = Manual;

    trigger OnRun()
    begin
    end;

    var
        TempChangeGlobalDimLogEntry: Record "Change Global Dim. Log Entry" temporary;

    /// <summary>
    /// Checks if all global dimension change operations have been completed.
    /// Returns true when all log entries have status Completed.
    /// </summary>
    /// <returns>True if all change operations are completed, false otherwise</returns>
    /// <remarks>
    /// Used to determine when the global dimension change process can be finalized.
    /// Filters for any non-completed status to verify overall completion state.
    /// </remarks>
    procedure AreAllCompleted(): Boolean
    begin
        TempChangeGlobalDimLogEntry.Reset();
        TempChangeGlobalDimLogEntry.SetFilter(Status, '<>%1', TempChangeGlobalDimLogEntry.Status::Completed);
        exit(TempChangeGlobalDimLogEntry.IsEmpty);
    end;

    /// <summary>
    /// Clears the temporary change global dimension log entry buffer.
    /// Removes all buffered log entries to reset the management state.
    /// </summary>
    /// <remarks>
    /// Used to clean up the buffer after global dimension change operations complete.
    /// Ensures clean state for subsequent global dimension change processes.
    /// </remarks>
    procedure ClearBuffer()
    begin
        TempChangeGlobalDimLogEntry.Reset();
        TempChangeGlobalDimLogEntry.DeleteAll();
    end;

    /// <summary>
    /// Checks if the temporary log entry buffer is empty.
    /// Returns true when no log entries are currently buffered.
    /// </summary>
    /// <returns>True if buffer is empty, false otherwise</returns>
    /// <remarks>
    /// Used to verify buffer state before starting new global dimension change operations.
    /// Helps ensure clean starting conditions for dimension change processes.
    /// </remarks>
    procedure IsBufferClear(): Boolean
    begin
        TempChangeGlobalDimLogEntry.Reset();
        exit(TempChangeGlobalDimLogEntry.IsEmpty);
    end;

    /// <summary>
    /// Checks if global dimension change operations have been started.
    /// Returns true when any log entries have non-blank status indicating processing has begun.
    /// </summary>
    /// <returns>True if change operations have started, false otherwise</returns>
    /// <remarks>
    /// Used to determine if global dimension change process is in progress.
    /// Helps prevent multiple concurrent change operations and provides status information.
    /// </remarks>
    procedure IsStarted(): Boolean
    begin
        TempChangeGlobalDimLogEntry.Reset();
        TempChangeGlobalDimLogEntry.SetFilter(Status, '<>%1', TempChangeGlobalDimLogEntry.Status::" ");
        exit(not TempChangeGlobalDimLogEntry.IsEmpty);
    end;

    /// <summary>
    /// Excludes a table from global dimension change processing.
    /// Removes the specified table's log entry from the buffer and clears buffer if all operations complete.
    /// </summary>
    /// <param name="TableId">Table ID to exclude from global dimension changes</param>
    /// <remarks>
    /// Used to skip tables that don't require dimension updates or have completed processing.
    /// Automatically clears the entire buffer when all remaining operations are completed.
    /// </remarks>
    procedure ExcludeTable(TableId: Integer)
    begin
        if TempChangeGlobalDimLogEntry.Get(TableId) then
            TempChangeGlobalDimLogEntry.Delete();
        if AreAllCompleted() then
            ClearBuffer();
    end;

    /// <summary>
    /// Finds child tables related to a specified parent table in the global dimension change log.
    /// Returns log entries for tables that have the specified table as their parent.
    /// </summary>
    /// <param name="ParentTableID">Parent table ID to find child tables for</param>
    /// <param name="TempChildChangeGlobalDimLogEntry">Temporary record to receive child table log entries</param>
    /// <returns>True if child tables are found, false otherwise</returns>
    /// <remarks>
    /// Used to process related tables in correct order during global dimension changes.
    /// Supports hierarchical table processing to maintain referential integrity.
    /// </remarks>
    procedure FindChildTables(ParentTableID: Integer; var TempChildChangeGlobalDimLogEntry: Record "Change Global Dim. Log Entry" temporary): Boolean;
    begin
        TempChildChangeGlobalDimLogEntry.Copy(TempChangeGlobalDimLogEntry, true);
        TempChildChangeGlobalDimLogEntry.SetRange("Parent Table ID", ParentTableID);
        exit(TempChildChangeGlobalDimLogEntry.FindSet());
    end;

    /// <summary>
    /// Fills the temporary buffer with global dimension change log entries from the database.
    /// Loads all relevant log entries into the temporary buffer for processing management.
    /// </summary>
    /// <returns>True if buffer was successfully filled, false otherwise</returns>
    /// <remarks>
    /// Used to initialize the buffer at the start of global dimension change operations.
    /// Provides local working copy of log entries for efficient processing management.
    /// </remarks>
    procedure FillBuffer(): Boolean
    var
        ChangeGlobalDimLogEntry: Record "Change Global Dim. Log Entry";
    begin
        ClearBuffer();
        if ChangeGlobalDimLogEntry.IsEmpty() then
            exit(false);
        ChangeGlobalDimLogEntry.FindSet();
        repeat
            TempChangeGlobalDimLogEntry := ChangeGlobalDimLogEntry;
            TempChangeGlobalDimLogEntry.Insert();
        until ChangeGlobalDimLogEntry.Next() = 0;
        TempChangeGlobalDimLogEntry.SetRange("Total Records", 0);
        TempChangeGlobalDimLogEntry.DeleteAll();
        exit(not IsBufferClear());
    end;
}

