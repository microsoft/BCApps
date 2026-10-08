// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
#pragma warning disable AA0247
table 5378 "Synth. Relation Mapping Buffer"
{
    TableType = Temporary;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Synth. Relation Name"; Text[100])
        {
        }
        field(2; "Rel. Native Entity Name"; Text[100])
        {
        }
        field(3; "Rel. Virtual Entity Name"; Text[100])
        {
        }
        field(4; "Virtual Table Caption"; Text[200])
        {
        }
        field(5; "Virtual Table Logical Name"; Text[100])
        {
        }
        field(6; "Syncd. Table Name"; Text[80])
        {
        }
        field(7; "Syncd. Table External Name"; Text[248])
        {
        }
        field(8; "Syncd. Table Id"; Integer)
        {
        }
        field(9; "Syncd. Field 1 Name"; Text[80])
        {
        }
        field(10; "Syncd. Field 1 External Name"; Text[100])
        {
        }
        field(11; "Syncd. Field 1 Id"; Integer)
        {
        }
        field(12; "Virtual Table Column 1 Caption"; Text[200])
        {
        }
        field(13; "Virtual Table Column 1 Name"; Text[100])
        {
        }
        field(14; "Syncd. Field 2 Name"; Text[80])
        {
        }
        field(15; "Syncd. Field 2 External Name"; Text[100])
        {
        }
        field(16; "Syncd. Field 2 Id"; Integer)
        {
        }
        field(17; "Virtual Table Column 2 Caption"; Text[200])
        {
        }
        field(18; "Virtual Table Column 2 Name"; Text[100])
        {
        }
        field(19; "Syncd. Field 3 Name"; Text[80])
        {
        }
        field(20; "Syncd. Field 3 External Name"; Text[100])
        {
        }
        field(21; "Syncd. Field 3 Id"; Integer)
        {
        }
        field(22; "Virtual Table Column 3 Caption"; Text[200])
        {
        }
        field(23; "Virtual Table Column 3 Name"; Text[100])
        {
        }
        field(24; "Relation Id"; Guid)
        {
        }
        field(25; "Relation Created"; Boolean)
        {
        }
        field(26; "Virtual Table Phys. Name"; Text[100])
        {
        }
        field(27; "Virtual Table API Page Id"; Integer)
        {
        }
    }
    keys
    {
        key(PK; "Synth. Relation Name", "Virtual Table Logical Name", "Syncd. Table Id", "Syncd. Field 1 Id", "Syncd. Field 2 Id", "Syncd. Field 3 Id", "Virtual Table Column 1 Name", "Virtual Table Column 2 Name", "Virtual Table Column 3 Name")
        {
            Clustered = true;
        }
    }
}
