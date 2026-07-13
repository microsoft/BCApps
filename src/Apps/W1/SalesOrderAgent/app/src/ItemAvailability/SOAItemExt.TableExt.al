// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Agent.SalesOrderAgent;

using Microsoft.Inventory.Item;

tableextension 4412 "SOA Item Ext" extends Item
{
    fields
    {
        field(4412; "Item Availability Filter"; Text[250])
        {
            Caption = 'Item Availability Filter';
            DataClassification = CustomerContent;
            Editable = false;
            ToolTip = 'Specifies the filter used to determine the availability of the item.';
        }
    }
}
