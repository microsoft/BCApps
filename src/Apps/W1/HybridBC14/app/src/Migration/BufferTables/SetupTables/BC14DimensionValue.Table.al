// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14;

table 50185 "BC14 Dimension Value"
{
    Caption = 'BC14 Dimension Value';
    DataClassification = CustomerContent;
    ReplicateData = false;
    Extensible = false;

    fields
    {
        field(1; "Dimension Code"; Code[20])
        {
            Caption = 'Dimension Code';
        }
        field(2; "Code"; Code[20])
        {
            Caption = 'Code';
        }
        field(3; "Name"; Text[50])
        {
            Caption = 'Name';
        }
        field(4; "Value Type"; Option)
        {
            Caption = 'Dimension Value Type';
            OptionMembers = Standard,Heading,"Begin-Total","End-Total";
            OptionCaption = 'Standard,Heading,Begin-Total,End-Total';
        }
        field(5; "Totaling"; Text[250])
        {
            Caption = 'Totaling';
        }
        field(6; "Blocked"; Boolean)
        {
            Caption = 'Blocked';
        }
        field(7; "Consolidation Code"; Code[20])
        {
            Caption = 'Consolidation Code';
        }
        field(8; "Indentation"; Integer)
        {
            Caption = 'Indentation';
            MinValue = 0;
        }
        field(9; "Global Dimension No."; Integer)
        {
            Caption = 'Global Dimension No.';
        }
        field(10; "Map-to IC Dimension Code"; Code[20])
        {
            Caption = 'Map-to IC Dimension Code';
        }
        field(11; "Map-to IC Dimension Value Code"; Code[20])
        {
            Caption = 'Map-to IC Dimension Value Code';
        }
        // Note: "Dimension Value ID" is NOT included - it's an identity column in BC Online
        // BC Online will auto-generate this value when we insert via AL code
    }

    keys
    {
        key(Key1; "Dimension Code", "Code")
        {
            Clustered = true;
        }
    }
}
