// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Costing;

enum 5804 "Average Cost Calculation Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; " ")
    {
        Caption = ' ';
    }
    value(1; Item)
    {
        Caption = 'Item';
    }
    value(2; "Item & Location & Variant")
    {
        Caption = 'Item & Location & Variant';
    }
}
