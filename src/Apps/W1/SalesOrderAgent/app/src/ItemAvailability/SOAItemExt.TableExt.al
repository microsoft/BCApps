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
            CalcFormula = Lookup(Item."Block Reason" where("No." = field("No.")));
            Caption = 'Item Availability Filter';
            Editable = false;
            FieldClass = FlowField;
            ToolTip = 'Specifies the filter used to determine the availability of the item.';
        }
    }
}