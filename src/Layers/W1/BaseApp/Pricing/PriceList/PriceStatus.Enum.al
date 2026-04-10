// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Pricing.PriceList;

enum 7005 "Price Status"
{
    Extensible = true;
    value(0; Draft)
    {
        Caption = 'Draft';
    }
    value(1; Active)
    {
        Caption = 'Active';
    }
    value(2; Inactive)
    {
        Caption = 'Inactive';
    }
}