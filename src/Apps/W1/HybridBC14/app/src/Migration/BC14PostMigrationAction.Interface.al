// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14Reimplementation;

/// <summary>
/// Interface for post-migration actions such as journal posting.
/// Unlike BC14 Migrator which handles data migration with progress tracking,
/// actions represent one-time operations that run after data migration completes.
/// </summary>
interface "BC14 Post Migration Action"
{
    /// <summary>
    /// Gets the name of the action for display and logging purposes.
    /// </summary>
    procedure GetDisplayName(): Text[250];

    /// <summary>
    /// Checks if the action should run based on current settings.
    /// </summary>
    procedure IsEnabled(): Boolean;

    /// <summary>
    /// Runs the action.
    /// </summary>
    /// <returns>True if the action succeeded.</returns>
    procedure RunAction(): Boolean;
}
