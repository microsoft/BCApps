// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Preview;

/// <summary>
/// Defines the preview scope for posting operations in Business Central.
/// Controls the level of detail shown in posting preview screens.
/// Used by posting preview system to determine which entries and validation results are displayed.
/// Extensible for custom preview behaviors and additional detail levels.
/// </summary>
enum 1570 "Posting Preview Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    /// <summary>
    /// Standard preview showing essential posting entries and basic validation results.
    /// </summary>
    value(0; Standard) { Caption = 'Standard'; }

    /// <summary>
    /// Extended preview including detailed entries, dimensions, and comprehensive validation results.
    /// </summary>
    value(1; Extended) { Caption = 'Extended'; }
}
