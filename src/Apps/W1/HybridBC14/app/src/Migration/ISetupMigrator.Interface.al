// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14;

interface "ISetupMigrator"
{
    /// <summary>
    /// Returns the name of the migrator for logging and display purposes.
    /// </summary>
    procedure GetName(): Text[250];

    /// <summary>
    /// Returns whether this migrator is enabled based on company settings.
    /// </summary>
    procedure IsEnabled(): Boolean;

    /// <summary>
    /// Executes the migration logic for setup data.
    /// </summary>
    /// <param name="StopOnFirstError">If true, migration stops on first error. If false, all errors are collected.</param>
    /// <returns>True if migration completed without errors, false otherwise.</returns>
    procedure Migrate(StopOnFirstError: Boolean): Boolean;
}
