// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Analysis;

/// <summary>
/// Defines the available dimension types for sales analysis matrix display.
/// </summary>
#pragma warning disable AL0659
enum 7158 "Sales Analysis Matrix Dimensions"
#pragma warning restore AL0659
{
    AssignmentCompatibility = true;
    Extensible = false;

    /// <summary>
    /// Specifies that the matrix displays data grouped by item.
    /// </summary>
    value(0; "Item") { Caption = 'Item'; }
    /// <summary>
    /// Specifies that the matrix displays data grouped by time period.
    /// </summary>
    value(1; "Period") { Caption = 'Period'; }
    /// <summary>
    /// Specifies that the matrix displays data grouped by location.
    /// </summary>
    value(2; "Location") { Caption = 'Location'; }
    /// <summary>
    /// Specifies that the matrix displays data grouped by the first analysis dimension.
    /// </summary>
    value(3; "Dimension 1") { Caption = 'Dimension 1'; }
    /// <summary>
    /// Specifies that the matrix displays data grouped by the second analysis dimension.
    /// </summary>
    value(4; "Dimension 2") { Caption = 'Dimension 2'; }
    /// <summary>
    /// Specifies that the matrix displays data grouped by the third analysis dimension.
    /// </summary>
    value(5; "Dimension 3") { Caption = 'Dimension 3'; }
    /// <summary>
    /// Represents an undefined or unassigned dimension type.
    /// </summary>
    value(99; "Undefined") { Caption = 'Undefined'; }
}
