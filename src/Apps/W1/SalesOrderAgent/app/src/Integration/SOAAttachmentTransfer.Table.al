// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

#pragma warning disable AS0007
namespace Microsoft.Agent.SalesOrderAgent;

using Microsoft.Sales.Document;
using System.Agents;

table 4590 "SOA Attachment Transfer"
{
    Access = Internal;
    DataClassification = SystemMetadata;
    InherentEntitlements = RIMDX;
    InherentPermissions = RIMDX;
    ReplicateData = false;

    fields
    {
        field(1; "Attachment ID"; Guid)
        {
            TableRelation = "Agent Task Message Attachment".SystemId;
        }
        field(2; "Sales Header ID"; Guid)
        {
            TableRelation = "Sales Header".SystemId;
        }
        field(3; "Task ID"; BigInteger)
        {
            TableRelation = "Agent Task".ID;
        }
        field(4; "Task Message ID"; Guid)
        {
        }
    }

    keys
    {
        key(Key1; "Attachment ID", "Sales Header ID")
        {
            Clustered = true;
        }
        key(Key2; "Task ID", "Task Message ID")
        {
        }
    }
}
