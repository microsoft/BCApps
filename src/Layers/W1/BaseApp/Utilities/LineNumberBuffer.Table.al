// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Utilities;

table 283 "Line Number Buffer"
{
    Caption = 'Line Number Buffer';
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Old Line Number"; Integer)
        {
            Caption = 'Old Line Number';
            DataClassification = SystemMetadata;
        }
        field(2; "New Line Number"; Integer)
        {
            Caption = 'New Line Number';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; "Old Line Number")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

