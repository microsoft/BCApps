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
                Visible = IsAgentActionVisible and not IsNewInvoiceAIVariant;
                trigger OnAction()
                begin
                    RunNewInvoiceAction(false);
                end;
            }
            action(PANewInvoiceAIVariant)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Draft from PDF with AI';
                Image = Sparkle;
                ToolTip = 'Upload a PDF invoice to create a purchase invoice with agent assistance.';
                Visible = IsAgentActionVisible and IsNewInvoiceAIVariant;
                trigger OnAction()
                begin
                    RunNewInvoiceAction(true);
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
                Visible = IsAgentActionVisible and not IsNewInvoiceAIVariant;
                trigger OnAction()
                begin
                    RunNewInvoiceAction(false);
                end;
            }
            action(PANewInvoicePromptingAIVariant)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Draft from PDF with AI';
                Image = Sparkle;
                ToolTip = 'Upload a PDF invoice to create a purchase invoice with agent assistance.';
                Visible = IsAgentActionVisible and IsNewInvoiceAIVariant;
                trigger OnAction()
                begin
                    RunNewInvoiceAction(true);
                end;
            }
        }
        addlast(Category_New)
        {
            actionref(PANewInvoice_Promoted; PANewInvoice)
            {
            }
            actionref(PANewInvoiceAIVariant_Promoted; PANewInvoiceAIVariant)
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
        IsAgentActionVisible := PayablesAgentSetup.CanShowAgentActions();
        IsNewInvoiceAIVariant := PayablesAgentSetup.IsNewInvoiceAIVariant();
    end;

    local procedure RunNewInvoiceAction(UseAIVariant: Boolean)
    begin
        UploadInvoiceWithAgent(UseAIVariant);
        ShowTaskPaneForLatestAgentTask();
    end;

    local procedure UploadInvoiceWithAgent(UseAIVariant: Boolean)
    var
        PayablesAgent: Codeunit "Payables Agent";
        PATrialGuide: Page "PA Trial Guide";
        FileName: Text;
        InStream: InStream;
        AlreadyActivated: Boolean;
        AgentExistInEnvironment: Boolean;
    begin
        IsAgentActionVisible := PayablesAgentSetup.CanShowAgentActions();
        if not IsAgentActionVisible then
            exit;
        if not UploadIntoStream(SelectFileLbl, '', PdfFileFilterLbl, FileName, InStream) then
            exit;

        AgentExistInEnvironment := PayablesAgent.PayablesAgentExistsAcrossAllCompanies();
        PayablesAgentSetup.EnsureAgentActivated(AlreadyActivated);
        PayablesAgentSetup.ImportInvoiceFile(FileName, InStream);
        if UseAIVariant then
            Session.LogMessage('0000V8J', NewInvoiceAIVariantTok, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, PayablesAgent.GetCustomDimensions())
        else
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
        if not PayablesAgentSetup.GetAgent(Agent) then
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
        PayablesAgentSetup: Codeunit "Payables Agent Setup";
        IsAgentActionVisible: Boolean;
        IsNewInvoiceAIVariant: Boolean;
        SelectFileLbl: Label 'Select file';
        PdfFileFilterLbl: Label 'PDF Files (*.pdf)|*.pdf';
        NewWithAgentTok: Label 'User uploaded invoice via New with agent action.', Locked = true;
        NewInvoiceAIVariantTok: Label 'User uploaded invoice via Draft from PDF with AI action.', Locked = true;
}