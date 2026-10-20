// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Agent.SalesOrderAgent;

table 4597 "SOA Agent Feature Setup"
{
    Access = Internal;
    Caption = 'Sales Order Agent Feature Setup';
    DataClassification = SystemMetadata;
    DataPerCompany = false;
    ReplicateData = false;
    InherentEntitlements = RIMDX;
    InherentPermissions = RIMDX;

    fields
    {
        field(1; "Agent User ID"; Guid)
        {
            Caption = 'Agent User ID';
        }
        field(2; "Use Business IQ"; Boolean)
        {
            Caption = 'Use Business IQ';
        }
    }

    keys
    {
        key(PK; "Agent User ID")
        {
            Clustered = true;
        }
    }
}
