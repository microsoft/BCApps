// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Location.AddressPrototype;

enum 17700 "Sales Address Role"
{
    Extensible = false;

    value(0; SellTo)
    {
        Caption = 'Sell-to';
    }
    value(1; BillTo)
    {
        Caption = 'Bill-to';
    }
    value(2; ShipTo)
    {
        Caption = 'Ship-to';
    }
}
