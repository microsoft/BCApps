// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.SyncEngine;

table 5337 "Temp Integration Field Mapping"
{
    Caption = 'Temp Integration Field Mapping';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Integer)
        {
            AutoIncrement = true;
            Caption = 'No.';
        }
        field(2; "Integration Table Mapping Name"; Code[20])
        {
            Caption = 'Integration Table Mapping Name';
            TableRelation = "Integration Table Mapping".Name;
        }
        field(3; "Source Field No."; Integer)
        {
            Caption = 'Source Field No.';
        }
        field(4; "Destination Field No."; Integer)
        {
            Caption = 'Destination Field No.';
        }
        field(5; "Validate Destination Field"; Boolean)
        {
            Caption = 'Validate Destination Field';
        }
        field(6; Bidirectional; Boolean)
        {
            Caption = 'Bidirectional';
        }
        field(7; "Constant Value"; Text[100])
        {
            Caption = 'Constant Value';
        }
        field(8; "Not Null"; Boolean)
        {
            Caption = 'Not Null';
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

