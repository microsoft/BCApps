// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.AITestToolkit;

using System.AI;

pageextension 149032 "Agent Run History" extends "AIT Run History"
{
    layout
    {
        addafter("Tokens - By Version")
        {
            field("Copilot Credits - By Version"; VersionCredits)
            {
                ApplicationArea = All;
                AutoFormatType = 0;
                Visible = ViewBy = ViewBy::Version;
                Caption = 'Copilot Credits Consumed';
                CaptionClass = '3,' + AgentTestContextImpl.GetCreditCaption();
                ToolTip = 'Specifies credits consumed by agent tasks in the current version, using the selected monetization generation.';
                Editable = false;

                trigger OnDrillDown()
                var
                    AgentTestContextImpl: Codeunit "Agent Test Context Impl.";
                begin
                    AgentTestContextImpl.OpenAgentConsumptionOverview(Rec."Agent Task IDs");
                end;
            }
            field("AI Pricing Pending - By Version"; Rec."AI Pricing Pending")
            {
                ApplicationArea = All;
                Visible = (ViewBy = ViewBy::Version) and NewMonetization;
                ToolTip = 'Specifies whether pricing is incomplete or task consumption could not be refreshed. Completed credits can increase later.';
                Editable = false;
            }
            field("Agent Task Count - By Version"; AgentTaskCountByVersion)
            {
                ApplicationArea = All;
                Visible = ViewBy = ViewBy::Version;
                Caption = 'Agent Tasks Executed';
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
            field("Copilot Credits - By Tag"; TagCredits)
            {
                ApplicationArea = All;
                AutoFormatType = 0;
                Visible = ViewBy = ViewBy::Tag;
                Caption = 'Copilot Credits Consumed';
                CaptionClass = '3,' + AgentTestContextImpl.GetCreditCaption();
                ToolTip = 'Specifies credits consumed by agent tasks for the tag, using the selected monetization generation.';
                Editable = false;

                trigger OnDrillDown()
                var
                    AgentTestContextImpl: Codeunit "Agent Test Context Impl.";
                begin
                    AgentTestContextImpl.OpenAgentConsumptionOverview(Rec."Agent Task IDs - By Tag");
                end;
            }
            field("AI Pricing Pending - By Tag"; Rec."AI Pricing Pending - By Tag")
            {
                ApplicationArea = All;
                Visible = (ViewBy = ViewBy::Tag) and NewMonetization;
                ToolTip = 'Specifies whether pricing is incomplete or task consumption could not be refreshed. Completed credits can increase later.';
                Editable = false;
            }
            field("Agent Task Count - By Tag"; AgentTaskCountByTag)
            {
                ApplicationArea = All;
                Visible = ViewBy = ViewBy::Tag;
                Caption = 'Agent Tasks Executed';
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
        VersionCredits := Rec."Copilot Credits";
        TagCredits := Rec."Copilot Credits - By Tag";
        NewMonetization := Quota.IsNewMonetizationEnabled();
        if NewMonetization then begin
            VersionCredits := Rec."AI Credits";
            TagCredits := Rec."AI Credits - By Tag";
        end;
        AgentTaskCountByVersion := AgentTestContextImpl.GetAgentTaskCount(Rec."Agent Task IDs");
        AgentTaskCountByTag := AgentTestContextImpl.GetAgentTaskCount(Rec."Agent Task IDs - By Tag");
    end;

    var
        AgentTestContextImpl: Codeunit "Agent Test Context Impl.";
        AgentTaskCountByVersion: Integer;
        AgentTaskCountByTag: Integer;
        Quota: Codeunit "Copilot Quota";
        VersionCredits: Decimal;
        TagCredits: Decimal;
        NewMonetization: Boolean;

}

