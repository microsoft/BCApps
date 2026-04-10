// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Pricing.PriceList;

enum 7009 "Price Type"
{
    Extensible = true;
    value(0; Any)
    {
        Caption = 'Any';
    }
    value(1; Sale)
    {
        Caption = 'Sale';
    }
    value(2; Purchase)
    {
        Caption = 'Purchase';
    }
}