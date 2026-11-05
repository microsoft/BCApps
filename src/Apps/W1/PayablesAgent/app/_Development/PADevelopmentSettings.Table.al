#if DEVELOPMENT
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Agent.PayablesAgent;

table 3309 "PA Development Settings"
{
    Caption = 'Payables Agent Development Settings';
    Access = Internal;
    DataClassification = SystemMetadata;
    Extensible = false;
    InherentEntitlements = RIMDX;
    InherentPermissions = RIMDX;
    ReplicateData = false;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
            DataClassification = SystemMetadata;
        }
        field(2; "Enable V2"; Boolean)
        {
            Caption = 'Enable V2';
            DataClassification = SystemMetadata;
            ToolTip = 'Specifies whether the development environment uses version 2 of the Payables Agent.';
        }
        field(3; "Simulate Agent Experience"; Boolean)
        {
            Caption = 'Simulate agent experience';
            DataClassification = SystemMetadata;
            ToolTip = 'Specifies whether pages behave as they do for the Payables Agent: agent-only controls are shown, supervisor actions are hidden, and work item lists are scoped to the simulated agent task. This does not create an agent session or change permissions.';
        }
        field(4; "Evaluation Version Override"; Option)
        {
            Caption = 'Evaluation version override';
            OptionMembers = Default,V1,V2;
            OptionCaption = 'Use configured setting,Version 1,Version 2';
            DataClassification = SystemMetadata;
            ToolTip = 'Specifies the Payables Agent version selected by the evaluation harness. Use configured setting means that the Enable V2 development setting applies.';
        }
        field(5; "Simulated Agent Task ID"; BigInteger)
        {
            Caption = 'Simulated agent task ID';
            DataClassification = SystemMetadata;
            ToolTip = 'Specifies the Payables Agent task that the simulated agent experience works on, as the agent runtime would. With no task, the simulation sees no work items.';
        }
    }

    keys
    {
        key(PK; "Primary Key")
        {
            Clustered = true;
        }
    }
}
#endif
