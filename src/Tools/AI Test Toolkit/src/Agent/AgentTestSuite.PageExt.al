// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestLibraries.Agents;

using System.Agents;
using System.TestTools.AITestToolkit;

pageextension 149034 "Agent Test Suite" extends "AIT Test Suite"
{
    layout
    {
        modify(TestType)
        {
            trigger OnBeforeValidate()
            begin
                UpdateIsAgentTestType();
            end;
        }
        addafter("Test Runner Id")
        {
            group(AgentSetupGroup)
            {
                ShowCaption = false;
                Visible = IsAgentTestType;

                field(TestSuiteAgent; AgentUserName)
                {
                    ApplicationArea = All;
                    Caption = 'Agent';
                    ToolTip = 'Specifies the agent to be used by the tests. You can use this field to test different configurations without changing the code. If you manually configure the agent and set it on the suite, this instance will be used in the eval runs. If you leave it blank, the system will automatically create an agent for each run.';

                    trigger OnValidate()
                    begin
                        ValidateAgentName();
                    end;

                    trigger OnAssistEdit()
                    begin
                        LookupAgent();
                    end;
                }
            }
        }
        addlast("Latest Run")
        {
            group(AgentMetricsGroup)
            {
                ShowCaption = false;
                Visible = IsAgentTestType;

                field("Copilot Credits"; CopilotCredits)
                {
                    ApplicationArea = All;
                    AutoFormatType = 0;
                    Editable = false;
                    Caption = 'Copilot Credits Consumed';
                    ToolTip = 'Specifies the total Copilot Credits consumed by the Agent Tasks in the current version.';
                    Visible = ConsumedCreditsVisible;
                }
                field("Agent Task Count"; AgentTaskCount)
                {
                    ApplicationArea = All;
                    Editable = false;
                    Caption = 'Agent Tasks Executed';
                    ToolTip = 'Specifies the number of Agent Tasks related to the current version.';

                    trigger OnDrillDown()
                    begin
                        AgentTestContextImpl.OpenAgentTaskList(AgentTaskIDs);
                    end;
                }
            }
        }
    }

    actions
    {
        addlast(Navigation)
        {
            action(CreditLimits)
            {
                ApplicationArea = All;
                Caption = 'Credit Limits';
                ToolTip = 'Configure credit limits for agent test suites.';
                Image = Cost;
                Visible = IsAgentTestType;
                RunObject = page "AIT Credit Limits";
            }
        }
        addlast(Category_Process)
        {
            actionref(CreditLimits_Promoted; CreditLimits)
            {
            }
        }
    }

    trigger OnOpenPage()
    var
        AgentSystemPermissions: Codeunit "Agent System Permissions";
    begin
        ConsumedCreditsVisible := AgentSystemPermissions.CurrentUserCanSeeConsumptionData();
        UpdateIsAgentTestType();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        UpdateAgentTaskMetrics();
        UpdateAgentUserName();
        ShowCreditLimitNotifications();
    end;

    local procedure UpdateIsAgentTestType()
    begin
        IsAgentTestType := Rec."Test Type" = Rec."Test Type"::Agent;
    end;

    local procedure ShowCreditLimitNotifications()
    var
        AITCreditLimitMgt: Codeunit "AIT Credit Limit Mgt.";
        GlobalLimitNotification: Notification;
        SuiteLimitNotification: Notification;
    begin
        if not IsAgentTestType then
            exit;

        // Check and show global credit limit notification
        if AITCreditLimitMgt.IsGlobalCreditLimitExceeded() then begin
            GlobalLimitNotification.Id := GetGlobalCreditLimitNotificationId();
            GlobalLimitNotification.Message := GlobalCreditLimitReachedMsg;
            GlobalLimitNotification.Scope := NotificationScope::LocalScope;
            GlobalLimitNotification.AddAction(OpenCreditLimitsLbl, Codeunit::"AIT Credit Limit Mgt.", 'OpenCreditLimitsPage');
            GlobalLimitNotification.Send();
        end else begin
            GlobalLimitNotification.Id := GetGlobalCreditLimitNotificationId();
            GlobalLimitNotification.Recall();
        end;

        // Check and show suite credit limit notification
        if AITCreditLimitMgt.IsSuiteCreditLimitExceeded(Rec) then begin
            SuiteLimitNotification.Id := GetSuiteCreditLimitNotificationId();
            SuiteLimitNotification.Message := StrSubstNo(SuiteCreditLimitReachedMsg, Rec.Code);
            SuiteLimitNotification.Scope := NotificationScope::LocalScope;
            SuiteLimitNotification.AddAction(OpenCreditLimitsLbl, Codeunit::"AIT Credit Limit Mgt.", 'OpenCreditLimitsPage');
            SuiteLimitNotification.Send();
        end else begin
            SuiteLimitNotification.Id := GetSuiteCreditLimitNotificationId();
            SuiteLimitNotification.Recall();
        end;
    end;

    local procedure GetGlobalCreditLimitNotificationId(): Guid
    begin
        exit('a1b2c3d4-e5f6-7890-abcd-ef1234567890');
    end;

    local procedure GetSuiteCreditLimitNotificationId(): Guid
    begin
        exit('b2c3d4e5-f6a7-8901-bcde-f12345678901');
    end;

    local procedure UpdateAgentTaskMetrics()
    begin
        CopilotCredits := ConsumedCreditsVisible ? AgentTestContextImpl.GetCopilotCredits(Rec.Code, Rec.Version, '', 0) : -1;
        AgentTaskIDs := AgentTestContextImpl.GetAgentTaskIDs(Rec.Code, Rec.Version, '', 0);
        AgentTaskCount := AgentTestContextImpl.GetAgentTaskCount(AgentTaskIDs);
    end;

    local procedure UpdateAgentUserName()
    var
        Agent: Codeunit Agent;
    begin
        AgentUserName := '';

        if IsNullGuid(Rec."Agent User Security ID") then
            exit;

        AgentUserName := Agent.GetUserName(Rec."Agent User Security ID");
    end;

    local procedure LookupAgent()
    var
        AgentSetup: Codeunit "Agent Setup";
        Agent: Codeunit Agent;
        AgentUserSecurityId: Guid;
    begin
        if not AgentSetup.OpenAgentLookup(AgentUserSecurityId) then
            exit;
        Rec."Agent User Security ID" := AgentUserSecurityId;
        AgentUserName := Agent.GetUserName(AgentUserSecurityId);
        Rec.Modify();
    end;

    local procedure ValidateAgentName()
    var
        AgentSetup: Codeunit "Agent Setup";
        Agent: Codeunit Agent;
    begin
        if AgentUserName = '' then begin
            Clear(Rec."Agent User Security ID");
            Rec.Modify();
            exit;
        end;

        if not AgentSetup.FindAgentByUserName(AgentUserName, Rec."Agent User Security ID") then
            Error(AgentWithNameNotFoundErr, AgentUserName);

        AgentUserName := Agent.GetUserName(Rec."Agent User Security ID");
        Rec.Modify();
    end;

    var
        AgentTestContextImpl: Codeunit "Agent Test Context Impl.";
        CopilotCredits: Decimal;
        AgentTaskIDs: Text;
        AgentTaskCount: Integer;
        AgentUserName: Code[50];
        ConsumedCreditsVisible: Boolean;
        IsAgentTestType: Boolean;
        AgentWithNameNotFoundErr: Label 'An agent with the name %1 was not found.', Comment = '%1 - The name of the agent';
        GlobalCreditLimitReachedMsg: Label 'The monthly Copilot credit limit has been reached. New agent tests cannot be started until the limit is increased or the next month begins.';
        SuiteCreditLimitReachedMsg: Label 'The Copilot credit limit for suite %1 has been reached. Tests for this suite cannot be started until the limit is increased.', Comment = '%1 - The test suite code';
        OpenCreditLimitsLbl: Label 'Open Credit Limits';
}