// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Tooling;

table 6280 "Database Activity Log"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Transaction Order"; Integer)
        {
            AutoIncrement = true;
            DataClassification = SystemMetadata;
        }
        field(2; "Trigger Name"; Text[50])
        {
            DataClassification = SystemMetadata;
        }
        field(3; "Table ID"; Integer)
        {
            DataClassification = SystemMetadata;
        }
        field(4; "Table Name"; Text[250])
        {
            DataClassification = SystemMetadata;
        }
        field(5; "Call Stack"; Text[2048]) // TODO: Save as blob
        {
            DataClassification = SystemMetadata; // TODO: Is this CustomerContent? E.g. Job Queue Log Entry has SystemMetadata
        }
        field(6; "App Name"; Text[250])
        {
            DataClassification = SystemMetadata;
        }
        field(7; "Publisher Name"; Text[250])
        {
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; "Transaction Order")
        {
            Clustered = true;
        }
    }
}