// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestLibraries.Email;

table 134687 "Test Email Connector Setup"
{
    DataClassification = SystemMetadata;
    ReplicateData = false;

    fields
    {
        field(1; Id; Guid)
        {
            Caption = 'Primary Key';
        }
        field(2; "Fail On Send"; Boolean)
        {
            Caption = 'Fail On Send';
        }
        field(3; "Fail On Register Account"; Boolean)
        {
            Caption = 'Fail On Register Account';
        }
        field(4; "Unsuccessful Register"; Boolean)
        {
            Caption = 'Unsuccessful Register';
        }
        field(5; "Email Message ID"; Guid)
        {
            Caption = 'Email Message ID';
        }
        field(6; "Fail On Reply"; Boolean)
        {
            Caption = 'Fail On Reply';
        }
        field(7; "Fail On Retrieve Emails"; Boolean)
        {
            Caption = 'Fail On Retrieve Emails';
        }
        field(8; "Fail On Mark As Read"; Boolean)
        {
            Caption = 'Fail On Retrieve Emails';
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
