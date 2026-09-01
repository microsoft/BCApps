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
            ToolTip = 'Specifies the Log Entry No.';
        }
        field(2; "Agent Task ID"; BigInteger)
        {
            Caption = 'Agent Task ID';
            NotBlank = true;
            ToolTip = 'Specifies the ID of the agent task executed.';
        }
        field(3; Company; Text[50])
        {
            Caption = 'Company';
            NotBlank = false;
            ToolTip = 'Specifies the Company in which the agent task was executed.';
        }
        field(4; "Copilot Credits"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Copilot Credits';
            ToolTip = 'Specifies the Copilot Credits consumed.';
            NotBlank = true;
        }
        field(5; "Test Suite Code"; Code[100])
        {
            Caption = 'Test Suite Code';
            ToolTip = 'Specifies the code of the test suite that generated this consumption.';
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
        key(Key3; "Test Suite Code", Company)
        {
            SumIndexFields = "Copilot Credits";
        }
    }
}
