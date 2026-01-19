// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

enum 99001500 "Subcontracting Type"
{
    Extensible = true;
    value(0; Empty)
    {
        Caption = ' ', Locked = true;
    }
    value(1; Purchase)
    {
        Caption = 'Purchase with Service';
    }
    value(2; InventoryByVendor)
    {
        Caption = 'Inventory by Vendor';
    }
    value(3; Transfer)
    {
        Caption = 'Transfer';
    }
}