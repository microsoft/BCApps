// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Pricing;

enum 7007 "Purchase Price Source Type"
{
    Extensible = true;
    value(20; "All Vendors")
    {
        Caption = 'All Vendors';
    }
    value(21; Vendor)
    {
        Caption = 'Vendor';
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
