// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Agent.PayablesAgent;

using Microsoft.Purchases.Document;
using System.Agents;
using System.Agents.TaskPane;

pageextension 3309 "PA Purchase Invoice List" extends "Purchase Invoices"
{
    actions
    {
        addlast(processing)
        {
            action(PANewInvoice)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'New from PDF';
                Image = Sparkle;
                ToolTip = 'Upload a PDF invoice to create a purchase invoice with agent assistance.';
                Visible = IsAgentActionVisible;
                trigger OnAction()
                begin
                    UploadInvoiceWithAgent();
                    ShowTaskPaneForLatestAgentTask();
                end;
            }
        }
        addlast(Prompting)
        {
            action(PANewInvoicePrompting)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'New from PDF';
                Image = Sparkle;
                ToolTip = 'Upload a PDF invoice to create a purchase invoice with agent assistance.';
                Visible = IsAgentActionVisible;
                trigger OnAction()
                begin
                    UploadInvoiceWithAgent();
                    ShowTaskPaneForLatestAgentTask();
                end;
            }
        }
        addlast(Category_New)
        {
            actionref(PANewInvoice_Promoted; PANewInvoice)
            {
            }
        }
        modify(Category_New)
        {
            ShowAs = SplitButton;
        }
    }
    trigger OnOpenPage()
    begin
        IsAgentActionVisible := PAAgentAccess.CanShowAgentActions();
    end;

    local procedure UploadInvoiceWithAgent()
    var
        PayablesAgent: Codeunit "Payables Agent Metadata";
        PASetupUpdate: Codeunit "PA Setup Update";
        PATaskIntake: Codeunit "PA Task Intake";
        PATrialGuide: Page "PA Trial Guide";
        FileName: Text;
        InStream: InStream;
        AlreadyActivated: Boolean;
        AgentExistInEnvironment: Boolean;
    begin
        IsAgentActionVisible := PAAgentAccess.CanShowAgentActions();
        if not IsAgentActionVisible then
            exit;
        if not UploadIntoStream(SelectFileLbl, '', PdfFileFilterLbl, FileName, InStream) then
            exit;

        AgentExistInEnvironment := PayablesAgent.PayablesAgentExistsAcrossAllCompanies();
        PASetupUpdate.EnsureActivated(AlreadyActivated);
        PATaskIntake.CreateTask(FileName, InStream);
        Session.LogMessage('0000SEJ', NewWithAgentTok, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, PayablesAgent.GetCustomDimensions());
        if AgentExistInEnvironment then
            exit;

        Commit();
        PATrialGuide.RunModal();
    end;

    local procedure ShowTaskPaneForLatestAgentTask()
    var
        Agent: Record Agent;
        TaskPane: Codeunit "Task Pane";
    begin
        if not PAAgentConfiguration.GetAgent(Agent) then
            exit;

        // An archived agent is not resolvable in the task pane, so the agent card is opened instead,
        // which keeps the agent reachable for auditing.
        if Agent.Substate = Agent.Substate::Archived then begin
            Agent.SetRecFilter();
            Page.Run(Page::"Agent Card", Agent);
            exit;
        end;

        TaskPane.ShowAgent(Agent."User Security ID");
    end;

    var
        PAAgentConfiguration: Codeunit "PA Agent Configuration";
        PAAgentAccess: Codeunit "PA Agent Access";
        IsAgentActionVisible: Boolean;
        SelectFileLbl: Label 'Select file';
        PdfFileFilterLbl: Label 'PDF Files (*.pdf)|*.pdf';
        NewWithAgentTok: Label 'User uploaded invoice via New with agent action.', Locked = true;
}