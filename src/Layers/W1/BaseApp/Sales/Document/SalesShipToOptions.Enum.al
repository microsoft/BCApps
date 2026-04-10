// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Document;

/// <summary>
/// Defines the ship-to address options for sales documents.
/// </summary>
enum 422 "Sales Ship-to Options"
{
    Extensible = true;
    AssignmentCompatibility = true;

    /// <summary>
    /// Specifies that the ship-to address is taken from the sell-to customer address.
    /// </summary>
    value(0; "Default (Sell-to Address)") { Caption = 'Default (Sell-to Address)'; }
    /// <summary>
    /// Specifies that the ship-to address is taken from an alternate shipping address defined for the customer.
    /// </summary>
    value(1; "Alternate Shipping Address") { Caption = 'Alternate Shipping Address'; }
    /// <summary>
    /// Specifies that a custom ship-to address is entered manually on the document.
    /// </summary>
    value(2; "Custom Address") { Caption = 'Custom Address'; }
}
