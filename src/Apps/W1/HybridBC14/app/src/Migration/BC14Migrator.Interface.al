// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14Reimplementation;

/// <summary>
/// Generic interface for all BC14 data migrators.
/// Phase membership is expressed by which enum the implementation is registered in
/// ("BC14 Setup Migrator", "BC14 Master Migrator", "BC14 Transaction Migrator",
/// "BC14 Historical Migrator"); each implementer owns its migration logic via Migrate.
/// </summary>
interface "BC14 Migrator"
{
    /// <summary>
    /// Gets the name of the migrator for display and logging purposes.
    /// </summary>
    procedure GetDisplayName(): Text[250];

    /// <summary>
    /// Registers the source-to-buffer replication table mappings owned by this migrator
    /// for the given company. May register zero, one, or multiple mappings (e.g. a Posted
    /// document migrator registers both Header and Line). Implementations should call
    /// Codeunit "BC14 Migration Setup".InsertPerCompanyMapping for each mapping.
    /// </summary>
    /// <param name="CompanyName">The name of the company to register mappings for.</param>
    procedure RegisterReplicationMappings(CompanyName: Text);

    /// <summary>
    /// Checks if the migrator is enabled based on current settings.
    /// </summary>
    procedure IsEnabled(): Boolean;

    /// <summary>
    /// Runs the migration for all source records.
    /// Implementations own the record loop and data transfer logic.
    /// </summary>
    /// <returns>True if migration succeeded.</returns>
    procedure Migrate(): Boolean;

    /// <summary>
    /// Gets the remaining migration percentage (100 = all remaining, 0 = all migrated).
    /// Percentage-based because a single migrator may handle multiple related entities.
    /// </summary>
    procedure GetRemainingPercentage(): Integer;
}

