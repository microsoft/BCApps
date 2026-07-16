// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

#pragma warning disable AS0007
namespace Microsoft.Agent.SalesOrderAgent;

using System.Agents;

table 4589 "SOA Reply Attempt"
{
    Access = Internal;
    DataClassification = SystemMetadata;
    InherentEntitlements = RIMDX;
    InherentPermissions = RIMDX;
    ReplicateData = false;

    fields
    {
        field(1; "Task ID"; BigInteger)
        {
            TableRelation = "Agent Task".ID;
        }
        field(2; "Message ID"; Guid)
        {
        }
        field(3; "Attempt Count"; Integer)
        {
        }
    }

    keys
    {
        key(Key1; "Task ID", "Message ID")
        {
            Clustered = true;
        }
    }
}
