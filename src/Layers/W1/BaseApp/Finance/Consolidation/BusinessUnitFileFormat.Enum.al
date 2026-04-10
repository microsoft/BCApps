// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Consolidation;

/// <summary>
/// Defines file format options for importing and exporting business unit consolidation data.
/// Supports multiple file format versions for backward compatibility with different Business Central versions.
/// </summary>
/// <remarks>
/// Used by consolidation import/export processes to determine the appropriate file parser and data structure.
/// Maintains compatibility across different Business Central versions through format version selection.
/// </remarks>
enum 220 "Business Unit File Format"
{
    Extensible = true;
    AssignmentCompatibility = true;

    /// <summary>
    /// Modern XML-based file format used in Business Central version 4.00 and later for consolidation data exchange.
    /// </summary>
    value(0; "Version 4.00 or Later (.xml)") { Caption = 'Version 4.00 or Later (.xml)'; }
    /// <summary>
    /// Legacy text-based file format used in Business Central version 3.70 and earlier for consolidation data exchange.
    /// </summary>
    value(1; "Version 3.70 or Earlier (.txt)") { Caption = 'Version 3.70 or Earlier (.txt)'; }
}