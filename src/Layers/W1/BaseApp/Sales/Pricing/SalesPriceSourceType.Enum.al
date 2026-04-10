// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Pricing;

/// <summary>
/// Defines the source types for sales pricing, such as All Customers, Customer, Customer Price Group, Campaign, or Contact.
/// </summary>
enum 7006 "Sales Price Source Type"
{
    Extensible = true;
    value(10; "All Customers")
    {
        /// <summary>
        /// Specifies that the price applies to all customers without restriction.
        /// </summary>
        Caption = 'All Customers';
    }
    value(11; Customer)
    {
        /// <summary>
        /// Specifies that the price applies to a specific individual customer.
        /// </summary>
        Caption = 'Customer';
    }
    value(12; "Customer Price Group")
    {
        /// <summary>
        /// Specifies that the price applies to all customers assigned to a specific customer price group.
        /// </summary>
        Caption = 'Customer Price Group';
    }
    value(13; "Customer Disc. Group")
    {
        /// <summary>
        /// Specifies that the price applies to all customers assigned to a specific customer discount group.
        /// </summary>
        Caption = 'Customer Disc. Group';
    }
    value(50; Campaign)
    {
        /// <summary>
        /// Specifies that the price applies during an active sales campaign.
        /// </summary>
        Caption = 'Campaign';
    }
    value(51; Contact)
    {
        /// <summary>
        /// Specifies that the price applies to a specific contact from the relationship management module.
        /// </summary>
        Caption = 'Contact';
    }
}
