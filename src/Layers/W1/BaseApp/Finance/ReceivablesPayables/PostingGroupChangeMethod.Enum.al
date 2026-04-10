// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.ReceivablesPayables;

/// <summary>
/// Defines methods for changing customer and vendor posting groups with validation and data migration.
/// Implements posting group change interface to provide extensible posting group modification strategies.
/// </summary>
/// <remarks>
/// Used by posting group change management to control how posting groups are updated.
/// Supports alternative group suggestions and validation of posting group changes.
/// Extensible to allow custom posting group change implementations and validation logic.
/// </remarks>
enum 960 "Posting Group Change Method" implements "Posting Group Change Method"
{
    Extensible = true;

    /// <summary>
    /// Alternative groups method providing suggestions for valid posting group replacements.
    /// </summary>
    value(0; "Alternative Groups")
    {
        Caption = 'Alternative Groups';
        Implementation = "Posting Group Change Method" = "Posting Group Change";
    }
}
