// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.AITestToolkit;

table 149050 "Agent Task Log"
{
    Caption = 'AI Agent Task Log';
    DataClassification = SystemMetadata;
    Extensible = true;
    Access = Public;
    ReplicateData = false;
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
        field(2; "Test Suite Code"; Code[100])
        {
            Caption = 'Eval Suite Code';
            NotBlank = true;
            TableRelation = "AIT Test Suite";
            ToolTip = 'Specifies the Eval Suite Code.';
        }
        field(3; "Test Method Line No."; Integer)
        {
            Caption = 'Line No.';
            ToolTip = 'Specifies the Test Method Line No.';
        }
        field(10; Status; Option)
        {
            Caption = 'Status';
            OptionMembers = Success,Error;
            ToolTip = 'Specifies the status of the iteration.';
        }
        field(11; Operation; Text[100])
        {
            Caption = 'Operation';
            ToolTip = 'Specifies the operation.';
        }
        field(13; Version; Integer)
        {
            Caption = 'Version';
            ToolTip = 'Specifies the Version No. of the eval run.';
        }
        field(15; Tag; Text[20])
        {
            DataClassification = CustomerContent;
            Caption = 'Tag';
            ToolTip = 'Specifies the Tag that we entered in the AI Eval Suite.';
        }
        field(17; "Procedure Name"; Text[128])
        {
            Caption = 'Procedure Name';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the name of the procedure being executed.';
        }
        field(5001; "Test Log Entry ID"; Integer)
        {
            Caption = 'Test Log Entry ID';
            ToolTip = 'Specifies the AIT Log Entry ID that this agent task is associated with.';
        }
        field(5000; "Agent Task ID"; BigInteger)
        {
            Caption = 'Agent Task ID';
            NotBlank = true;
            ToolTip = 'Specifies the Agent Task ID.';
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Test Suite Code", Version, "Test Method Line No.", "Agent Task ID", Operation, "Procedure Name")
        {
            IncludedFields = Status;
        }
        key(Key3; "Test Log Entry ID", "Agent Task ID")
        {
        }
    }
}
