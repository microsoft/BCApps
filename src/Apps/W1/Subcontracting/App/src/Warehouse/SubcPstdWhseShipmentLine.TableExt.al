
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Warehouse.History;

#pragma warning disable AS0072, AS0136
tableextension 20528 "Subc. Pstd. Whse Shipment Line" extends "Posted Whse. Shipment Line"
{
    fields
    {
        field(20560; "Transfer WIP Item"; Boolean)
        {
            Caption = 'Transfer WIP Item';
            DataClassification = CustomerContent;
            Editable = false;
            ToolTip = 'Specifies whether this transfer shipment line represents a WIP item transfer.';
        }
    }
}
#pragma warning restore AS0072, AS0136
