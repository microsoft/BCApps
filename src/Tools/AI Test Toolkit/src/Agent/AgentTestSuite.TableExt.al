// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.AITestToolkit;

using System.Agents;

tableextension 149050 "Agent Test Suite" extends "AIT Test Suite"
{
    fields
    {
        field(4900; "Agent User Security ID"; Guid)
        {
            DataClassification = SystemMetadata;
            Caption = 'Agent User Security ID';
            ToolTip = 'Specifies the agent to be used by the test suite.';
        }
        field(4901; "Agent Model ID"; Code[30])
        {
            DataClassification = SystemMetadata;
            Caption = 'Agent Model ID';
            ToolTip = 'Specifies the model to use for agent tasks created by the test suite. A selected model overrides the model set by the test. Leave blank to use the agent model, or the default model.';
            TableRelation = "Agent Model"."Model ID" where(Availability = filter(Preview | Available));
        }
        field(4902; "Agent Model Name"; Text[70])
        {
            Caption = 'Agent Model Name';
            ToolTip = 'Specifies the model to use for agent tasks created by the test suite. A selected model overrides the model set by the test. Leave blank to use the agent model, or the default model.';
            FieldClass = FlowField;
            CalcFormula = lookup("Agent Model"."Model Name" where("Model ID" = field("Agent Model ID")));
            Editable = false;
        }
    }
}