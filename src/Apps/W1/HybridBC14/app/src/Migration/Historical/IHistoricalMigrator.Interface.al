// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14;

/// <summary>
/// Interface for historical data migrators (Posted Sales Invoices, etc.).
/// Runner drives the migration loop; implementers handle single-record transformation.
/// </summary>
interface "IHistoricalMigrator"
{
    /// <summary>
    /// Gets the name of the migrator for display and logging purposes.
    /// </summary>
    procedure GetName(): Text[250];

    /// <summary>
    /// Checks if the migrator is enabled based on current settings.
    /// </summary>
    procedure IsEnabled(): Boolean;

    /// <summary>
    /// Gets the source buffer table ID for this migrator.
    /// </summary>
    procedure GetSourceTableId(): Integer;

    /// <summary>
    /// Initializes and filters the source records to migrate.
    /// Called once before the migration loop starts.
    /// </summary>
    /// <param name="SourceRecordRef">RecordRef to the source buffer table, already opened.</param>
    procedure InitializeSourceRecords(var SourceRecordRef: RecordRef);

    /// <summary>
    /// Migrates a single source record to the target table.
    /// </summary>
    /// <param name="SourceRecordRef">The source record to migrate.</param>
    /// <returns>True if migration succeeded.</returns>
    procedure MigrateRecord(var SourceRecordRef: RecordRef): Boolean;

    /// <summary>
    /// Gets the unique key for a source record (used for progress tracking).
    /// For composite keys, concatenate with underscore: "Field1_Field2_Field3"
    /// </summary>
    /// <param name="SourceRecordRef">The source record.</param>
    /// <returns>The record key as text.</returns>
    procedure GetSourceRecordKey(var SourceRecordRef: RecordRef): Text[250];

    /// <summary>
    /// Gets the count of records to migrate (for progress display).
    /// </summary>
    procedure GetRecordCount(): Integer;
}
