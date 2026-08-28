// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Warehouse.Activity;

tableextension 20572 "Subc. Warehouse Activity Line" extends "Warehouse Activity Line"
{
    fields
    {
        field(20549; "Subc. Purchase Line Type"; Enum "Subc. Purchase Line Type")
        {
            Caption = 'Subcontracting Line Type';
            DataClassification = CustomerContent;
            Editable = false;
            ToolTip = 'Specifies the subcontracting purchase line type associated with the warehouse activity line.';
        }
        field(20560; "Subc. Transfer WIP Item"; Boolean)
        {
            Caption = 'Transfer WIP Item';
            DataClassification = CustomerContent;
            Editable = false;
            ToolTip = 'Specifies whether this activity line represents a WIP item transfer.';
        }
    }
}