// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.AITestToolkit;

tableextension 149030 "Agent Run History" extends "AIT Run History"
{
    fields
    {
        field(15; "Copilot Credits"; Decimal)
        {
            DataClassification = SystemMetadata;
            AutoFormatType = 0;
            Caption = 'Copilot credits';
            ToolTip = 'Specifies the total Copilot Credits consumed by the Agent Tasks in the current version.';
            Editable = false;
        }
        field(16; "Agent Task IDs"; Text[2048])
        {
            DataClassification = SystemMetadata;
            Caption = 'Agent tasks';
            ToolTip = 'Specifies the comma-separated list of Agent Task IDs related to the current version.';
            Editable = false;
        }
        field(25; "Copilot Credits - By Tag"; Decimal)
        {
            DataClassification = SystemMetadata;
            AutoFormatType = 0;
            Caption = 'Copilot credits';
            ToolTip = 'Specifies the total Copilot Credits consumed by the Agent Tasks for the tag.';
            Editable = false;
        }
        field(26; "Agent Task IDs - By Tag"; Text[2048])
        {
            DataClassification = SystemMetadata;
            Caption = 'Agent tasks';
            ToolTip = 'Specifies the comma-separated list of Agent Task IDs related to the tag.';
            Editable = false;
        }
    }
}
