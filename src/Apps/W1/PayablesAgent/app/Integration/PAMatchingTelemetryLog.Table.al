// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Agent.PayablesAgent;

table 3309 "PA Matching Telemetry Log"
{
    Access = Internal;
    DataClassification = SystemMetadata;
    ReplicateData = false;
    InherentEntitlements = RIMD;
    InherentPermissions = RIMD;

    fields
    {
        field(1; "Agent Task ID"; BigInteger)
        {
            Caption = 'Agent Task ID';
        }
        field(2; "E-Document System ID"; Guid)
        {
            Caption = 'E-Document System ID';
        }
        field(3; "Emitted At"; DateTime)
        {
            Caption = 'Emitted At';
        }
    }

    keys
    {
        key(PK; "Agent Task ID")
        {
            Clustered = true;
        }
    }
}
