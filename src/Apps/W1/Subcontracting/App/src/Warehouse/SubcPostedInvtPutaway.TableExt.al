// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Warehouse.InventoryDocument;

tableextension 20575 "Subc. Posted Invt. Put-away" extends "Posted Invt. Put-away Line"
{
    fields
    {
        field(20549; "Subc. Purchase Line Type"; Enum "Subc. Purchase Line Type")
        {
            Caption = 'Subcontracting Line Type';
            DataClassification = CustomerContent;
            Editable = false;
            ToolTip = 'Specifies the subcontracting purchase line type associated with the posted inventory put-away line.';
        }
        field(20560; "Transfer WIP Item"; Boolean)
        {
            Caption = 'Transfer WIP Item';
            DataClassification = CustomerContent;
            Editable = false;
            ToolTip = 'Specifies whether this posted inventory put-away line represents a WIP item transfer.';
        }
    }
}