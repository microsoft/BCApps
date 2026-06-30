// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.IO;

table 8401 "Record Set Tree"
{
    Caption = 'Record Set Tree';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Table No."; Integer)
        {
            Caption = 'Table No.';
        }
        field(3; "Node ID"; Integer)
        {
            AutoIncrement = true;
            Caption = 'Node ID';
        }
        field(10; Value; RecordID)
        {
            Caption = 'Value';
            DataClassification = CustomerContent;
        }
        field(11; "Parent Node ID"; Integer)
        {
            Caption = 'Parent Node ID';
        }
    }

    keys
    {
        key(Key1; "Table No.", "Node ID")
        {
            Clustered = true;
        }
        key(Key2; "Table No.", "Parent Node ID", Value)
        {
        }
    }

    fieldgroups
    {
    }
}

