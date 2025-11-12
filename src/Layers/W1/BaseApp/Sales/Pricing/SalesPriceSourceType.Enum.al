// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Pricing;

enum 7006 "Sales Price Source Type"
{
    Extensible = true;
    value(10; "All Customers")
    {
        Caption = 'All Customers';
    }
    value(11; Customer)
    {
        Caption = 'Customer';
    }
    value(12; "Customer Price Group")
    {
        Caption = 'Customer Price Group';
    }
    value(13; "Customer Disc. Group")
    {
        Caption = 'Customer Disc. Group';
    }
    value(50; Campaign)
    {
        Caption = 'Campaign';
    }
    value(51; Contact)
    {
        Caption = 'Contact';
    }
}
