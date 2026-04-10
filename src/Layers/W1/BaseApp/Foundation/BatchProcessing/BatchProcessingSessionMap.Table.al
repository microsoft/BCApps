// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.BatchProcessing;

table 54 "Batch Processing Session Map"
{
    Caption = 'Batch Processing Session Map';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            AutoIncrement = true;
            Caption = 'Entry No.';
            DataClassification = SystemMetadata;
        }
        field(2; "Record ID"; RecordID)
        {
            Caption = 'Record ID';
            DataClassification = CustomerContent;
        }
        field(3; "Batch ID"; Guid)
        {
            Caption = 'Batch ID';
            DataClassification = SystemMetadata;
        }
        field(4; "User ID"; Guid)
        {
            Caption = 'User ID';
            DataClassification = EndUserPseudonymousIdentifiers;
        }
        field(5; "Session ID"; Integer)
        {
            Caption = 'Session ID';
            DataClassification = EndUserPseudonymousIdentifiers;
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Record ID", "User ID", "Session ID")
        {
            MaintainSIFTIndex = false;
        }
    }

    fieldgroups
    {
    }
}

