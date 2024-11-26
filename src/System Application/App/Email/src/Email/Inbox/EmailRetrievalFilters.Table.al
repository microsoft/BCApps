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
    DataClassification = SystemMetadata;
    InherentEntitlements = RIMDX;
    InherentPermissions = RIMDX;

    fields
    {
        field(1; Id; Integer)
        {
            AutoIncrement = true;
        }

        field(2; "Load Attachments"; Boolean)
        {
        }

        field(3; "Unread Emails"; Boolean)
        {
        }

        field(4; "Draft Emails"; Boolean)
        {
        }

        field(5; "Max No. of Emails"; Integer)
        {
            InitValue = 20;
        }

        field(6; "Body Type"; Option)
        {
            OptionMembers = "HTML","Text";
            InitValue = "HTML";
        }

        field(7; "Earliest Email"; DateTime)
        {
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