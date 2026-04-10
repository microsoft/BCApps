// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Pricing.Calculation;

enum 7000 "Price Calculation Method"
{
    Extensible = true;

    value(0; " ")
    {
    }
    value(1; "Lowest Price")
    {
        Caption = 'Lowest Price';
    }
}