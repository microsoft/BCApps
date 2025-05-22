// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestLibraries.Email;
using System.Email;

table 134686 "Test Email Account"
{
    DataClassification = SystemMetadata;
    ReplicateData = false;

    fields
    {
        field(1; Id; Guid)
        {
            Caption = 'Primary Key';
        }

        field(2; Email; Text[250])
        {
            Caption = 'Email';
        }

        field(3; Name; Text[250])
        {
            Caption = 'Name';
        }

        field(4; Connector; Enum "Email Connector")
        {
            Caption = 'Connector';
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