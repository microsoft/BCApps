// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Setup;

/// <summary>
/// Specifies the position of the company logo on documents.
/// </summary>
enum 313 "Logo Position on Documents"
{
    Extensible = true;
    AssignmentCompatibility = true;

    /// <summary>
    /// Specifies that the logo is not displayed.
    /// </summary>
    value(0; "No Logo") { Caption = 'No Logo'; }
    /// <summary>
    /// Specifies that the logo is displayed on the left.
    /// </summary>
    value(1; Left) { Caption = 'Left'; }
    /// <summary>
    /// Specifies that the logo is displayed in the center.
    /// </summary>
    value(2; Center) { Caption = 'Center'; }
    /// <summary>
    /// Specifies that the logo is displayed on the right.
    /// </summary>
    value(3; Right) { Caption = 'Right'; }
}
