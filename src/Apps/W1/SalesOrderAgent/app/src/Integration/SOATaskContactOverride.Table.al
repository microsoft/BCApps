// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

#pragma warning disable AS0007
namespace Microsoft.Agent.SalesOrderAgent;

using Microsoft.CRM.Contact;
using System.Agents;

table 4588 "SOA Task Contact Override"
{
    Access = Internal;
    DataClassification = SystemMetadata;
    InherentEntitlements = X;
    InherentPermissions = X;
    ReplicateData = false;

    fields
    {
        field(1; "Task ID"; BigInteger)
        {
            TableRelation = "Agent Task".ID;
        }
        field(2; "Task Message ID"; Guid)
        {
        }
        field(3; "Contact No."; Code[20])
        {
            DataClassification = EndUserPseudonymousIdentifiers;
            TableRelation = Contact."No.";
        }
    }

    keys
    {
        key(Key1; "Task ID", "Task Message ID")
        {
            Clustered = true;
        }
    }
}
