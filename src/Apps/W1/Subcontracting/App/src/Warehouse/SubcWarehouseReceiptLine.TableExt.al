
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Warehouse.Document;

tableextension 8149 "Subc. Warehouse Receipt Line" extends "Warehouse Receipt Line"
{
    fields
    {
        field(8173; "Subc. Purchase Line Type"; Enum "Subc. Purchase Line Type")
        {
            Caption = 'Subcontracting Line Type';
            DataClassification = CustomerContent;
            Editable = false;
            ToolTip = 'Specifies the subcontracting purchase line type associated with the warehouse receipt line.';
        }
        field(8184; "Transfer WIP Item"; Boolean)
        {
            Caption = 'Transfer WIP Item';
            DataClassification = CustomerContent;
            Editable = false;
            ToolTip = 'Specifies whether this transfer receipt line represents a WIP item transfer.';
        }
    }
}