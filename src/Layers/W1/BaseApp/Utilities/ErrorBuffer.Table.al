// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Utilities;

table 5890 "Error Buffer"
{
    Caption = 'Error Buffer';
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Error No."; Integer)
        {
            Caption = 'Error No.';
            DataClassification = SystemMetadata;
        }
        field(2; "Error Text"; Text[250])
        {
            Caption = 'Error Text';
            DataClassification = SystemMetadata;
        }
        field(3; "Source Table"; Integer)
        {
            Caption = 'Source Table';
            DataClassification = SystemMetadata;
        }
        field(4; "Source No."; Code[20])
        {
            Caption = 'Source No.';
            DataClassification = SystemMetadata;
        }
        field(5; "Source Ref. No."; Integer)
        {
            Caption = 'Source Ref. No.';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; "Error No.")
        {
            Clustered = true;
        }
        key(Key2; "Source Table", "Source No.", "Source Ref. No.")
        {
        }
    }

    fieldgroups
    {
    }
}

