// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Location;

enum 7350 "Missing SKU Planning Policy"
{
    Extensible = true;

    value(0; "Minimal")
    {
        Caption = 'Minimal';
    }
    value(1; "Item Card")
    {
        Caption = 'Item Card';
    }
    value(3; "Dont Plan")
    {
        Caption = 'Don''t Plan';
    }
}