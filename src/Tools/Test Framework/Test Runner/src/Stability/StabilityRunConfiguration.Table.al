// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.TestRunner;

/// <summary>
/// Stores the stability preset combinations that are executed for a base test suite. Each row is a
/// single configuration string (see codeunit "Stability Preset"). When a base suite has no
/// configuration rows, the orchestrator seeds a default, editable set.
/// </summary>
table 130466 "Stability Run Configuration"
{
    DataClassification = SystemMetadata;
    ReplicateData = false;
    Caption = 'Stability Run Configuration';
    LookupPageId = "Stability Run Configuration";
    DrillDownPageId = "Stability Run Configuration";

    fields
    {
        field(1; "Base Suite"; Code[10])
        {
            Caption = 'Base Suite';
            TableRelation = "AL Test Suite".Name;
            NotBlank = true;
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(3; "Configuration"; Text[250])
        {
            Caption = 'Configuration';
            ToolTip = 'Specifies the stability preset combination, for example SEED-2+WORKDATEFUTURE-1YEAR.';
        }
        field(4; "Enabled"; Boolean)
        {
            Caption = 'Enabled';
            InitValue = true;
            ToolTip = 'Specifies whether this combination is executed when the stability run starts.';
        }
    }

    keys
    {
        key(Key1; "Base Suite", "Line No.")
        {
            Clustered = true;
        }
    }
}
