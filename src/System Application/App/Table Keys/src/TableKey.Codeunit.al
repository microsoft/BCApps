// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Reflection;

/// <summary>
/// Provides functionality for disabling and re-enabling table indexes.
/// </summary>
codeunit 9557 "Table Key"
{
    /// <summary>
    /// Disables all keys on the provided table. Disabling keys before bulk table write operations can significantly improve performance.
    /// </summary>
    /// <param name="TableNo">The table to disable all of the keys for.</param>
    /// <returns>True, if the keys were disabled successfully, false otherwise.</returns>
    /// <remarks>
    /// System tables and non-sql based tables are not supported for this operation.
    /// Clustered keys, unique keys, SIFT keys, Nonclustered Columnstore Indexes are not affected by this operation.
    /// The keys are automatically re-enabled when a Commit() is called, or at the end of AL code execution.
    /// </remarks>
    [Scope('OnPrem')]
    procedure DisableAll(TableNo: Integer): Boolean
    var
        TableKeyImpl: Codeunit "Table Key Impl.";
    begin
        exit(TableKeyImpl.DisableAll(TableNo));
    end;

    /// <summary>
    /// Re-enables all keys that have been disabled on the provided table.
    /// </summary>
    /// <param name="TableNo">The table to re-enable all of the keys for.</param>
    /// <returns>True, if the keys were re-enabled successfully, false otherwise.</returns>
    /// <remarks>This method can be used when keys need to be re-enabled (for example, for searching) before a Commit() is called.</remarks>
    [Scope('OnPrem')]
    procedure EnableAll(TableNo: Integer): Boolean
    var
        TableKeyImpl: Codeunit "Table Key Impl.";
    begin
        exit(TableKeyImpl.EnableAll(TableNo));
    end;
}