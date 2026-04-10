// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Intrastat;

table 286 Territory
{
    Caption = 'Territory';
    DrillDownPageID = Territories;
    LookupPageID = Territories;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
            ToolTip = 'Specifies a territory code.';
            NotBlank = true;
        }
        field(2; Name; Text[50])
        {
            Caption = 'Name';
            ToolTip = 'Specifies a description of the territory.';
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

