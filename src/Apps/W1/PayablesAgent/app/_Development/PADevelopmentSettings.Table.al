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
            ToolTip = 'Specifies whether the task page presents the controls and source interactions normally available to the Payables Agent. This does not create an agent session or change permissions.';
        }
        field(4; "Evaluation Version Override"; Enum "PA Version")
        {
            Caption = 'Evaluation version override';
            DataClassification = SystemMetadata;
            ToolTip = 'Specifies the Payables Agent version selected by the evaluation harness. Unknown means that the Enable V2 development setting applies.';
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
