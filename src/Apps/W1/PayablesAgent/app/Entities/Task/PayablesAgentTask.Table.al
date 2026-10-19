// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Agent.PayablesAgent;

using System.Agents;

/// <summary>
/// Anchor record for one unit of Payables Agent v2 work. It can exist before any Agent-framework task is created.
/// </summary>
table 3327 "Payables Agent Task"
{
    Caption = 'Payables Agent Task';
    Access = Internal;
    DataClassification = CustomerContent;
    Extensible = false;
    InherentEntitlements = RIMDX;
    InherentPermissions = RIMDX;
    ReplicateData = false;

    fields
    {
        field(1; "Entry No."; BigInteger)
        {
            Caption = 'Entry No.';
            DataClassification = SystemMetadata;
            AutoIncrement = true;
        }
        field(2; "Source Data No."; BigInteger)
        {
            Caption = 'Source Data No.';
            DataClassification = SystemMetadata;
            TableRelation = "Payables Agent Task Source"."Entry No.";
        }
        field(3; "Task Data No."; BigInteger)
        {
            Caption = 'Task Data No.';
            DataClassification = SystemMetadata;
            TableRelation = "Payables Agent Task Data"."Entry No.";
        }
        field(4; "Agent Task ID"; BigInteger)
        {
            Caption = 'Agent Task ID';
            DataClassification = SystemMetadata;
            TableRelation = "Agent Task".ID;
        }
        field(5; Outcome; RecordId)
        {
            Caption = 'Outcome';
            DataClassification = CustomerContent;
        }
        field(6; "Received At"; DateTime)
        {
            Caption = 'Received At';
            DataClassification = SystemMetadata;
        }
        field(7; "Completed At"; DateTime)
        {
            Caption = 'Completed At';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        key(AgentTaskID; "Agent Task ID")
        {
        }
    }
}
