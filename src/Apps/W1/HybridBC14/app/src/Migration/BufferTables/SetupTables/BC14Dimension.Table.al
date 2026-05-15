// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14;

table 50190 "BC14 Dimension"
{
    Caption = 'BC14 Dimension';
    DataClassification = CustomerContent;
    ReplicateData = false;
    Extensible = false;

    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
        }
        field(2; "Name"; Text[30])
        {
            Caption = 'Name';
        }
        field(3; "Code Caption"; Text[80])
        {
            Caption = 'Code Caption';
        }
        field(4; "Filter Caption"; Text[80])
        {
            Caption = 'Filter Caption';
        }
        field(5; "Description"; Text[50])
        {
            Caption = 'Description';
        }
        field(6; "Blocked"; Boolean)
        {
            Caption = 'Blocked';
        }
        field(7; "Consolidation Code"; Code[20])
        {
            Caption = 'Consolidation Code';
        }
        field(8; "Map-to IC Dimension Code"; Code[20])
        {
            Caption = 'Map-to IC Dimension Code';
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
    }
}
