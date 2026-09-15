// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.IO;

table 8400 "Record Set Definition"
{
    Caption = 'Record Set Definition';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Table No."; Integer)
        {
            Caption = 'Table No.';
        }
        field(2; "Set ID"; Integer)
        {
            AutoIncrement = true;
            Caption = 'Set ID';
            InitValue = 1;
        }
        field(3; "Node ID"; Integer)
        {
            Caption = 'Node ID';
        }
        field(10; Value; RecordID)
        {
            CalcFormula = lookup ("Record Set Tree".Value where("Table No." = field("Table No."),
                                                                "Node ID" = field("Node ID")));
            Caption = 'Value';
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; "Table No.", "Set ID", "Node ID")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

