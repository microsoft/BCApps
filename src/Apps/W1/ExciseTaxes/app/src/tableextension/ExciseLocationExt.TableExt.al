// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExciseTaxes;

using Microsoft.Inventory.Location;

tableextension 7419 "Excise Location Ext" extends Location
{
    fields
    {
        field(7412; "Excise Bonded Location"; Enum "Excise Bonded Handling")
        {
            Caption = 'Excise Bonded Location';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies whether this location is treated as non-bonded, bonded, or customs for excise duty purposes, to control whether excise tax is suspended or becomes due for inventory movements through this location.';
        }
        field(7413; "Excise Bond Identifier"; Code[20])
        {
            Caption = 'Excise Bond Identifier';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the identifier of the excise bond or bonded warehouse that this location belongs to, for reporting, audit, and traceability of excise-suspended inventory.';
        }
        field(7414; "Bond Authorization No."; Text[100])
        {
            Caption = 'Bond Authorization No.';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the official bond authorization or permit number assigned by customs or excise authorities for this bonded location.';
        }
    }
}