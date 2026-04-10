// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Item.Catalog;

enum 5726 "Item Reference Type"
{
    Extensible = true;

    value(0; " ") { Caption = ' '; }
    value(1; "Customer") { Caption = 'Customer'; }
    value(2; "Vendor") { Caption = 'Vendor'; }
    value(3; "Bar Code") { Caption = 'Bar Code'; }

}
