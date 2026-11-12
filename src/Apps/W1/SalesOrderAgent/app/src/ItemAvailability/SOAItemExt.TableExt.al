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
        // Carrier FlowField: it only exists so SOA has a filterable field on Item. The lookup target
        // ("Block Reason") is arbitrary - the value is never used, we just need a field we can set a
        // filter on. Caption is marked SOA-internal so users don't mistake it for a real Item field.
        field(4412; "SOA Item Availability Filter"; Text[250])
        {
            CalcFormula = Lookup(Item."Block Reason" where("No." = field("No.")));
            Caption = 'SOA Internal - Item Availability Filter', Locked = true;
            Editable = false;
            FieldClass = FlowField;
            ToolTip = 'Specifies the filter used to determine the availability of the item.';
        }
    }
}