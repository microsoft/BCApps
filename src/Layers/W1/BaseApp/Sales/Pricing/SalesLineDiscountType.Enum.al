// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Pricing;

enum 7021 "Sales Line Discount Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; Item)
    {
        Caption = 'Item';
    }
    value(1; "Item Disc. Group")
    {
        Caption = 'Item Discount Group';
    }
}
