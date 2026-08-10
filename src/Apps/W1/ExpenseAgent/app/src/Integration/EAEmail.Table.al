// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.ExpenseAgent;

using System.Email;

table 6936 "EA Email"
{
    Access = Internal;
    DataClassification = SystemMetadata;
    InherentEntitlements = RIMDX;
    InherentPermissions = RIMDX;
    ReplicateData = false;

    fields
    {
        field(1; "Email Inbox ID"; BigInteger)
        {
            TableRelation = "Email Inbox".Id;
        }
        field(2; Processed; Boolean)
        {
        }
        field(9; "Sender Name"; Text[250])
        {
            DataClassification = EndUserIdentifiableInformation;
        }
        field(10; "Sender Address"; Text[250])
        {
            DataClassification = EndUserIdentifiableInformation;
        }
        field(11; "Received DateTime"; DateTime)
        {
        }
        field(12; "Sent DateTime"; DateTime)
        {
        }
        field(100; "Task ID"; BigInteger)
        {

        }
    }

    keys
    {
        key(Key1; "Email Inbox ID")
        {
            Clustered = true;
        }
    }
}