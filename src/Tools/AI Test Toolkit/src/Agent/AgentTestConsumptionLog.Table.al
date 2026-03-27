// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.AITestToolkit;

table 149049 "Agent Test Consumption Log"
{
    Caption = 'Agent Eval Task Consumption Log';
    DataClassification = SystemMetadata;
    Access = Internal;
    ReplicateData = false;
    DataPerCompany = false;
    InherentEntitlements = RIMDX;
    InherentPermissions = RIMDX;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            AutoIncrement = true;
            ToolTip = 'Specifies the Log Entry No..';
        }
        field(2; "Agent Task ID"; BigInteger)
        {
            Caption = 'Agent Task ID';
            NotBlank = true;
            ToolTip = 'Specifies the Agent Task ID.';
        }
        field(3; "Copilot Credits"; Decimal)
        {
            Caption = 'Copilot Credits';
            ToolTip = 'Specifies the Copilot Credits consumed.';
            NotBlank = true;
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Agent Task ID")
        {
        }
    }
}
