
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Warehouse.Document;

tableextension 99001527 "Subc. Warehouse Shipment Line" extends "Warehouse Shipment Line"
{
    fields
    {
        field(99001560; "Transfer WIP Item"; Boolean)
        {
            Caption = 'Transfer WIP Item';
            DataClassification = CustomerContent;
            Editable = false;
            ToolTip = 'Specifies whether this transfer shipment line represents a WIP item transfer.';
        }
    }
}