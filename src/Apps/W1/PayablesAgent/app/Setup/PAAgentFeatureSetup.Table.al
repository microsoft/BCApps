// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

#pragma warning disable AS0007
namespace Microsoft.Agent.PayablesAgent;

table 3325 "PA Agent Feature Setup"
{
    Access = Internal;
    Caption = 'Payables Agent Feature Setup';
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
            DataClassification = SystemMetadata;
        }
        field(2; "Use Business Skills"; Boolean)
        {
            Caption = 'Use Business Skills';
            DataClassification = SystemMetadata;
            InitValue = false;
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
