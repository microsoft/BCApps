// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Email;

/// <summary>Holds information about the filters for retrieving emails.</summary>
table 8885 "Email Retrieval Filters"
{
    Access = Public;
    TableType = Temporary;

    fields
    {
        field(1; Id; Integer)
        {
            DataClassification = SystemMetadata;
            AutoIncrement = true;
        }

        field(2; "Load Attachments"; Boolean)
        {
            DataClassification = SystemMetadata;
        }

        field(3; "Unread Emails"; Boolean)
        {
            DataClassification = SystemMetadata;
        }

        field(4; "Draft Emails"; Boolean)
        {
            DataClassification = SystemMetadata;
        }

        field(5; "Max No. of Emails"; Integer)
        {
            DataClassification = SystemMetadata;
            InitValue = 20;
        }

        field(6; "Body Type"; Option)
        {
            OptionMembers = "HTML","Text";
            DataClassification = SystemMetadata;
            InitValue = "HTML";
        }

        field(7; "Earliest Email"; DateTime)
        {
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(PK; Id)
        {
            Clustered = true;
        }
    }
}