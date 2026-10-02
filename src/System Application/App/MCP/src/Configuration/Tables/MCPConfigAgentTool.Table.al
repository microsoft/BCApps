// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.MCP;

using System.Agents;

table 8376 "MCP Config Agent Tool"
{
    Access = Internal;
    Extensible = false;
    Caption = 'MCP Configuration Agent Tool';
    DataClassification = SystemMetadata;
    ReplicateData = false;
    InherentEntitlements = RIMDX;
    InherentPermissions = RIMDX;

    fields
    {
        field(1; ID; Guid)
        {
            Caption = 'Configuration ID';
            ToolTip = 'Specifies the ID of the MCP configuration.';
            TableRelation = "MCP Configuration".SystemId;
        }
        field(2; "Agent User Security ID"; Guid)
        {
            Caption = 'Agent User Security ID';
            ToolTip = 'Specifies the security ID of the agent configured for the MCP server.';
            TableRelation = Agent."User Security ID";

            trigger OnValidate()
            var
                MCPConfigImplementation: Codeunit "MCP Config Implementation";
            begin
                MCPConfigImplementation.ValidateAgentTool("Agent User Security ID");
            end;
        }
        field(3; "Agent User Name"; Code[50])
        {
            Caption = 'Agent User Name';
            ToolTip = 'Specifies the user name of the configured agent.';
            FieldClass = FlowField;
            CalcFormula = lookup(Agent."User Name" where("User Security ID" = field("Agent User Security ID")));
        }
        field(4; "Agent Display Name"; Text[80])
        {
            Caption = 'Agent Display Name';
            ToolTip = 'Specifies the display name of the configured agent.';
            FieldClass = FlowField;
            CalcFormula = lookup(Agent."Display Name" where("User Security ID" = field("Agent User Security ID")));
        }
        field(5; "Agent Publisher Type"; Enum "Agent Publisher Type")
        {
            Caption = 'Agent Publisher Type';
            ToolTip = 'Specifies the publisher type of the configured agent.';
            FieldClass = FlowField;
            CalcFormula = lookup(Agent."Publisher Type" where("User Security ID" = field("Agent User Security ID")));
        }
    }

    keys
    {
        key(PK; ID, "Agent User Security ID")
        {
            Clustered = true;
        }
    }
}
