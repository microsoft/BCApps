// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.AITestToolkit;

pageextension 149032 "Agent Run History" extends "AIT Run History"
{
    layout
    {
        addafter("Tokens - By Version")
        {
            field("Copilot Credits - By Version"; Rec."Copilot Credits")
            {
                ApplicationArea = All;
                AutoFormatType = 0;
                Visible = ViewBy = ViewBy::Version;
                Caption = 'Copilot credits';
                ToolTip = 'Specifies the total Copilot Credits consumed by the Agent Tasks in the current version.';
                Editable = false;
            }
            field("Agent Task Count - By Version"; AgentTaskCountByVersion)
            {
                ApplicationArea = All;
                Visible = ViewBy = ViewBy::Version;
                Caption = 'Agent tasks';
                ToolTip = 'Specifies the number of Agent Tasks related to the current version.';
                Editable = false;

                trigger OnDrillDown()
                var
                    AgentTestContextImpl: Codeunit "Agent Test Context Impl.";
                begin
                    AgentTestContextImpl.OpenAgentTaskList(Rec."Agent Task IDs");
                end;
            }
        }
        addafter("Tokens - By Tag")
        {
            field("Copilot Credits - By Tag"; Rec."Copilot Credits - By Tag")
            {
                ApplicationArea = All;
                AutoFormatType = 0;
                Visible = ViewBy = ViewBy::Tag;
                Caption = 'Copilot credits';
                ToolTip = 'Specifies the total Copilot Credits consumed by the Agent Tasks for the tag.';
                Editable = false;
            }
            field("Agent Task Count - By Tag"; AgentTaskCountByTag)
            {
                ApplicationArea = All;
                Visible = ViewBy = ViewBy::Tag;
                Caption = 'Agent tasks';
                ToolTip = 'Specifies the number of Agent Tasks related to the tag.';
                Editable = false;

                trigger OnDrillDown()
                var
                    AgentTestContextImpl: Codeunit "Agent Test Context Impl.";
                begin
                    AgentTestContextImpl.OpenAgentTaskList(Rec."Agent Task IDs - By Tag");
                end;
            }
        }
    }

    var
        AgentTestContextImpl: Codeunit "Agent Test Context Impl.";
        AgentTaskCountByVersion: Integer;
        AgentTaskCountByTag: Integer;

    trigger OnAfterGetRecord()
    begin
        UpdateAgentTaskCounts();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        UpdateAgentTaskCounts();
    end;

    local procedure UpdateAgentTaskCounts()
    begin
        AgentTaskCountByVersion := AgentTestContextImpl.GetAgentTaskCount(Rec."Agent Task IDs");
        AgentTaskCountByTag := AgentTestContextImpl.GetAgentTaskCount(Rec."Agent Task IDs - By Tag");
    end;
}

