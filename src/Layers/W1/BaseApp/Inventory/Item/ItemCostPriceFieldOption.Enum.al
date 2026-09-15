// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Item;

enum 502 ItemCostPriceFieldOption
{
    Extensible = true;

    value(0; "Unit Price")
    {
        Caption = 'Unit Price';
    }
    value(1; "Profit %")
    {
        Caption = 'Profit %';
    }
    value(2; "Indirect Cost %")
    {
        Caption = 'Indirect Cost %';
    }
    value(3; "Last Direct Cost")
    {
        Caption = 'Last Direct Cost';
    }
    value(4; "Standard Cost")
    {
        Caption = 'Standard Cost';
    }
}