// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Pricing;

/// <summary>
/// Defines the sales type for pricing, indicating whether prices apply to a Customer, Customer Price Group, All Customers, or Campaign.
/// </summary>
enum 7023 "Sales Price Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    /// <summary>
    /// Specifies that the price is defined for a specific individual customer.
    /// </summary>
    value(0; "Customer") { Caption = 'Customer'; }
    /// <summary>
    /// Specifies that the price is defined for all customers in a specific customer price group.
    /// </summary>
    value(1; "Customer Price Group") { Caption = 'Customer Price Group'; }
    /// <summary>
    /// Specifies that the price applies to all customers without restriction.
    /// </summary>
    value(2; "All Customers") { Caption = 'All Customers'; }
    /// <summary>
    /// Specifies that the price is associated with a specific sales campaign.
    /// </summary>
    value(3; "Campaign") { Caption = 'Campaign'; }
}
