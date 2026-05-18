
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Warehouse.Document;

tableextension 99001525 "Subc. Warehouse Receipt Line" extends "Warehouse Receipt Line"
{
    fields
    {
        field(99001549; "Subc. Purchase Line Type"; Enum "Subc. Purchase Line Type")
        {
            Caption = 'Subcontracting Line Type';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(99001560; "Transfer WIP Item"; Boolean)
        {
            Caption = 'Transfer WIP Item';
            DataClassification = CustomerContent;
            Editable = false;
            ToolTip = 'Specifies whether this transfer receipt line represents a WIP item transfer.';
        }
    }
}