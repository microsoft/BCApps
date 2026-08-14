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
        // Only physical field filters are preserved in the URL when opening this page from the agent timeline.
        field(4412; "Item Availability Filter"; Text[150])
        {
            Caption = 'Item Availability Filter';
            DataClassification = SystemMetadata;
            Editable = false;
            ToolTip = 'Specifies the filter used to determine the availability of the item.';
        }
    }
}
