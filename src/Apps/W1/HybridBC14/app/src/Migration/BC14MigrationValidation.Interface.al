// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14Reimplementation;

/// <summary>
/// Interface for post-migration validations.
/// Validations run after migration completes to verify data integrity.
/// </summary>
interface "BC14 Migration Validation"
{
    /// <summary>
    /// Gets the name of the validation for display and logging purposes.
    /// </summary>
    procedure GetDisplayName(): Text[250];

    /// <summary>
    /// Checks if the validation should run based on current settings.
    /// </summary>
    procedure IsEnabled(): Boolean;

    /// <summary>
    /// Executes the validation.
    /// </summary>
    procedure Execute();
}
