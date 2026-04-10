// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Document;

/// <summary>
/// Defines the bill-to address options for sales documents.
/// </summary>
enum 421 "Sales Bill-to Options"
{
    Extensible = true;
    AssignmentCompatibility = true;

    /// <summary>
    /// Specifies that the bill-to address is taken from the sell-to customer.
    /// </summary>
    value(0; "Default (Customer)") { Caption = 'Default (Customer)'; }
    /// <summary>
    /// Specifies that the bill-to address is taken from a different customer than the sell-to customer.
    /// </summary>
    value(1; "Another Customer") { Caption = 'Another Customer'; }
    /// <summary>
    /// Specifies that a custom bill-to address is entered manually on the document.
    /// </summary>
    value(2; "Custom Address") { Caption = 'Custom Address'; }
}
