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
                field("Agent Model Name"; Rec."Agent Model Name")
                {
                    ApplicationArea = All;
                    Caption = 'Model';

                    trigger OnAssistEdit()
                    begin
                        LookupAgentModel();
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
                    CaptionClass = '3,' + AgentTestContextImpl.GetCreditCaption();
                    ToolTip = 'Specifies the total Copilot Credits consumed by the Agent Tasks in the current version.';

                    trigger OnDrillDown()
                    begin
                        AgentTestContextImpl.OpenAgentConsumptionOverview(AgentTaskIDs);
                    end;
                }
                field(PricingPending; PricingPending)
                {
                    ApplicationArea = All;
                    Caption = 'Pricing pending';
                    ToolTip = 'Specifies that AI pricing for one or more linked tasks is incomplete.';
                    Editable = false;
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
                Caption = 'View credit limits';
                ToolTip = 'View and configure credit limits for agent test suites.';
                Image = Cost;
                Visible = IsAgentTestType;

                trigger OnAction()
                var
                    AITEvalLimitProvider: Interface "AIT Eval Limit Provider";
                begin
                    AITEvalLimitProvider := Rec."Test Type";
                    AITEvalLimitProvider.OpenConfigurationPage();
                end;
            }
        }
        addlast(Category_Process)
        {
            actionref(CreditLimits_Promoted; CreditLimits)
            {
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        UpdateIsAgentTestType();
        UpdateAgentTaskMetrics();
        UpdateAgentUserName();
        ShowNotifications();
    end;

    local procedure UpdateIsAgentTestType()
    begin
        IsAgentTestType := Rec."Test Type" = Rec."Test Type"::Agent;
    end;

    local procedure UpdateAgentTaskMetrics()
    begin
        CopilotCredits := AgentTestContextImpl.GetCopilotCredits(Rec.Code, Rec.Version, '', 0);
        AgentTaskIDs := AgentTestContextImpl.GetAgentTaskIDs(Rec.Code, Rec.Version, '', 0);
        AgentTaskCount := AgentTestContextImpl.GetAgentTaskCount(AgentTaskIDs);
        PricingPending := AgentTestContextImpl.IsPricingPendingForTasks(AgentTaskIDs);
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

    local procedure ShowNotifications()
    var
        AITEvalLimitProvider: Interface "AIT Eval Limit Provider";
    begin
        AITEvalLimitProvider := Rec."Test Type";
        AITEvalLimitProvider.ShowNotifications();
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

    local procedure LookupAgentModel()
    var
        AgentModel: Record "Agent Model";
        TempAgentModel: Record "Agent Model" temporary;
    begin
        // A blank row lets the user remove the override from the same lookup.
        TempAgentModel.Init();
        TempAgentModel."Model Name" := NoModelOverrideLbl;
        TempAgentModel.Availability := TempAgentModel.Availability::Available;
        TempAgentModel.Insert();

        AgentModel.SetFilter(Availability, '%1|%2', AgentModel.Availability::Preview, AgentModel.Availability::Available);
        if AgentModel.FindSet() then
            repeat
                TempAgentModel := AgentModel;
                TempAgentModel.Insert();
            until AgentModel.Next() = 0;

        if TempAgentModel.Get(Rec."Agent Model ID") then;
        if Page.RunModal(Page::"Agent Model List", TempAgentModel) <> Action::LookupOK then
            exit;

        Rec.Validate("Agent Model ID", TempAgentModel."Model ID");
        Rec.Modify();
        Rec.CalcFields("Agent Model Name");
        CurrPage.Update(false);
    end;

    var
        AgentTestContextImpl: Codeunit "Agent Test Context Impl.";
        CopilotCredits: Decimal;
        AgentTaskIDs: Text;
        AgentTaskCount: Integer;
        AgentUserName: Code[50];
        IsAgentTestType: Boolean;
        PricingPending: Boolean;
        AgentWithNameNotFoundErr: Label 'An agent with the name %1 was not found.', Comment = '%1 - The name of the agent';
        NoModelOverrideLbl: Label '(None)', Comment = 'Shown in the model lookup for the option that removes the model override.';
}