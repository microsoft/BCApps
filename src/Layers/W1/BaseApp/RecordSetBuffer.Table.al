// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.IO;

table 8402 "Record Set Buffer"
{
    Caption = 'Record Set Buffer';
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; No; Integer)
        {
            AutoIncrement = true;
            Caption = 'No';
            DataClassification = SystemMetadata;
        }
        field(2; "Value RecordID"; RecordID)
        {
            Caption = 'Value RecordID';
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(Key1; No)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

