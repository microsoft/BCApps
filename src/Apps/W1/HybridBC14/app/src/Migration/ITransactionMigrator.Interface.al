// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14;

interface "ITransactionMigrator"
{
    /// <summary>
    /// Gets the name of the migrator for display purposes.
    /// </summary>
    /// <returns>The name of the migrator.</returns>
    procedure GetName(): Text[250];

    /// <summary>
    /// Checks if the migrator is enabled based on current settings.
    /// </summary>
    /// <returns>True if the migrator should run.</returns>
    procedure IsEnabled(): Boolean;

    /// <summary>
    /// Migrates the transaction data.
    /// </summary>
    /// <param name="StopOnFirstError">If true, stops migration on first error.</param>
    /// <returns>True if migration was successful.</returns>
    procedure Migrate(StopOnFirstError: Boolean): Boolean;

    /// <summary>
    /// Retries migration for failed records.
    /// </summary>
    /// <param name="StopOnFirstError">If true, stops on first error during retry.</param>
    /// <returns>True if retry was successful.</returns>
    procedure RetryFailedRecords(StopOnFirstError: Boolean): Boolean;

    /// <summary>
    /// Gets the count of records to migrate.
    /// </summary>
    /// <returns>The number of records to migrate.</returns>
    procedure GetRecordCount(): Integer;
}
