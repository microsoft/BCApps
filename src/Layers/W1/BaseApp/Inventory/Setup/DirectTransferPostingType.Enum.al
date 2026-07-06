// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Setup;

enum 314 "Direct Transfer Posting Type"
{
    Extensible = false;

    value(0; " ")
    {
        Caption = '';
    }
    value(10; "Shipment and Receipt")
    {
        Caption = 'Shipment and Receipt';
    }
    value(20; "Direct Transfer")
    {
        Caption = 'Direct Transfer';
    }
}
