// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Agents;

page 4316 "Agent List"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Administration;
    SourceTable = Agent;
    Caption = 'Agents', Comment = 'Agents in this page should be translated as AI agents. It is listing the AI agents that users have setup to help with automating tasks.';
    CardPageId = "Agent Card";
    AdditionalSearchTerms = 'Agent, Agents, Copilot, Automation, AI';
    Editable = false;
    InsertAllowed = false;
    DeleteAllowed = false;
    InherentEntitlements = X;
    InherentPermissions = X;

    layout
    {
        area(Content)
        {
            repeater(Main)
            {
                field(UserName; Rec."User Name")
                {
                    Caption = 'User Name';
                }
                field(DisplayName; Rec."Display Name")
                {
                    Caption = 'Display Name';
                }
                field(AgentType; Rec."Agent Metadata Provider")
                {
                    Caption = 'Agent type';
                }
                field(Availability; CopilotAvailabilityTxt)
                {
                    Caption = 'Availability';
                    ToolTip = 'Specifies the availability of the agent.';
                }
                field(State; Rec.State)
                {
                    Caption = 'State';
                }
                field(Substate; Rec.Substate)
                {
                    Caption = 'Substate';
                    ToolTip = 'Specifies whether the agent is archived.';
                    Editable = false;
                }
                field("Can Access Current Company"; Rec."Can Access Current Company")
                {
                    Caption = 'Can Access Current Company';
                    Visible = ShouldShowAllCompanies;
                }
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action(AgentSetup)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Configure';
                ToolTip = 'Configure the agent';
                Image = SetupLines;
                Enabled = Rec."Can Curr. User Configure Agent" and not AgentIsArchived;

                trigger OnAction()
                var
                    Agent: Codeunit Agent;
                begin
                    if Rec.IsEmpty() then
                        Error(NoAgentSetupErr);

                    Agent.OpenSetupPageId(Rec."Agent Metadata Provider", Rec."User Security ID");
                    CurrPage.Update(false);
                end;
            }
            action(ArchiveAgent)
            {
                ApplicationArea = All;
                Caption = 'Archive';
                ToolTip = 'Archive the agent. Archiving removes the agent from active use and cannot be undone.';
                Image = Archive;
                Enabled = ArchiveActionEnabled;

                trigger OnAction()
                var
                    Agent: Codeunit Agent;
                    ArchiveConfirmation: Page "Agent Archive Confirmation";
                begin
                    if Rec.IsEmpty() then
                        Error(NoAgentSetupErr);

                    Rec.TestField("Display Name");
                    ArchiveConfirmation.SetAgentDisplayName(Rec."Display Name");
                    ArchiveConfirmation.RunModal();
                    if not ArchiveConfirmation.IsConfirmed() then
                        exit;

                    Agent.Archive(Rec."User Security ID");
                    CurrPage.Update(false);
                end;
            }
            action(AgentTasks)
            {
                ApplicationArea = All;
                Caption = 'View tasks';
                ToolTip = 'View agent tasks';
                Image = Log;

                trigger OnAction()
                var
                    AgentTask: Record "Agent Task";
                begin
                    if Rec.IsEmpty() then
                        Error(NoAgentSetupErr);
                    AgentTask.SetRange("Agent User Security ID", Rec."User Security ID");
                    Page.Run(Page::"Agent Task List", AgentTask);
                end;
            }
            action(ShowCurrentCompany)
            {
                ApplicationArea = All;
                Caption = 'Show agents for current company';
                ToolTip = 'Show only agents that can access the current company.';
                Image = FilterLines;
                Visible = ShouldShowAllCompanies;

                trigger OnAction()
                begin
                    ShouldShowAllCompanies := false;
                    SetCompanyFilter();
                end;
            }
            action(ShowAllCompanies)
            {
                ApplicationArea = All;
                Caption = 'Show agents for all companies';
                ToolTip = 'Show agents from all companies.';
                Image = RemoveFilterLines;
                Visible = not ShouldShowAllCompanies;

                trigger OnAction()
                begin
                    ShouldShowAllCompanies := true;
                    SetCompanyFilter();
                end;
            }
        }
        area(Navigation)
        {
            action(AgentConfigurationRights)
            {
                ApplicationArea = All;
                Caption = 'Agent configuration rights';
                ToolTip = 'View who can create new agents';
                Image = Permission;
                RunObject = Page "Agent Creation Control";
            }
            action(ShowConsumptionData)
            {
                ApplicationArea = All;
                Caption = 'Consumption data';
                ToolTip = 'View AI consumption data for this agent.';
                Image = BankAccountLedger;

                trigger OnAction()
                var
                    AgentConsumptionOverview: Codeunit "Agent Consumption Overview";
                begin
                    if Rec.IsEmpty() then
                        Error(NoAgentSetupErr);

                    AgentConsumptionOverview.OpenAgentConsumptionOverview(Rec."User Security ID");
                end;
            }
            action(AgentModels)
            {
                ApplicationArea = All;
                Caption = 'Agent models';
                ToolTip = 'View all agent models.';
                Image = ViewPage;
                RunObject = Page "Agent Model List";
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                actionref(AgentSetup_Promoted; AgentSetup)
                {
                }
                actionref(ArchiveAgent_Promoted; ArchiveAgent)
                {
                }
                actionref(AgentTasks_Promoted; AgentTasks)
                {
                }
            }
        }
    }

    trigger OnOpenPage()
    var
        AgentImpl: Codeunit "Agent Impl.";
        AgentUtilities: Codeunit "Agent Utilities";
        AgentMetadataProvider: Enum "Agent Metadata Provider";
    begin
        AgentUtilities.BlockPageFromBeingOpenedByAgent();
        // Check if there are any agents available
        if AgentMetadataProvider.Names().Count() = 0 then
            AgentImpl.ShowNoAgentsAvailableNotification();

        ShouldShowAllCompanies := false;
        // Hide archived agents from the default list; users can filter the Substate column to view them.
        Rec.SetRange(Substate, Rec.Substate::None);
        SetCompanyFilter();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        UpdateControls();
    end;

    trigger OnAfterGetRecord()
    begin
        UpdateControls();
    end;

    local procedure UpdateControls()
    var
        AgentImpl: Codeunit "Agent Impl.";
    begin
        CopilotAvailabilityTxt := AgentImpl.GetCopilotAvailabilityDisplayText(Rec);
        AgentIsArchived := Rec.Substate = Rec.Substate::Archived;
        ArchiveActionEnabled := (Rec.State = Rec.State::Disabled) and (not AgentIsArchived);
    end;

    local procedure SetCompanyFilter()
    begin
        if ShouldShowAllCompanies then
            Rec.SetRange("Can Access Current Company")
        else
            Rec.SetRange("Can Access Current Company", true);
        CurrPage.Update(false);
    end;

    var
        CopilotAvailabilityTxt: Text;
        ShouldShowAllCompanies: Boolean;
        ArchiveActionEnabled: Boolean;
        AgentIsArchived: Boolean;
        NoAgentSetupErr: Label 'No agents have been setup. You must set up an agent first.';
}