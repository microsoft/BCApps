// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Agent.PayablesAgent;

using System.Agents;
using System.Agents.TaskPane;

codeunit 3327 "PA Task Upload"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    internal procedure UploadInvoiceWithAgent(): Boolean
    var
        PayablesAgent: Codeunit "Payables Agent Metadata";
        PAAgentAccess: Codeunit "PA Agent Access";
        PASetupUpdate: Codeunit "PA Setup Update";
        PATaskIntake: Codeunit "PA Task Intake";
        PATrialGuide: Page "PA Trial Guide";
        FileName: Text;
        InStream: InStream;
        AlreadyActivated: Boolean;
        AgentExistInEnvironment: Boolean;
    begin
        if not PAAgentAccess.CanShowAgentActions() then
            exit(false);
        if not UploadIntoStream(SelectFileLbl, '', PdfFileFilterLbl, FileName, InStream) then
            exit(false);

        AgentExistInEnvironment := PayablesAgent.PayablesAgentExistsAcrossAllCompanies();
        PASetupUpdate.EnsureActivated(AlreadyActivated);
        PATaskIntake.CreateTask(FileName, InStream);
        Session.LogMessage('0000SEJ', InvoiceUploadTok, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, PayablesAgent.GetCustomDimensions());

        if not AgentExistInEnvironment then begin
            Commit();
            PATrialGuide.RunModal();
        end;

        ShowTaskPane();
        exit(true);
    end;

    local procedure ShowTaskPane()
    var
        Agent: Record Agent;
        PAAgentConfiguration: Codeunit "PA Agent Configuration";
        TaskPane: Codeunit "Task Pane";
    begin
        if not PAAgentConfiguration.GetAgent(Agent) then
            exit;

        // An archived agent is not resolvable in the task pane, so its card remains the audit entry point.
        if Agent.Substate = Agent.Substate::Archived then begin
            Agent.SetRecFilter();
            Page.Run(Page::"Agent Card", Agent);
            exit;
        end;

        TaskPane.ShowAgent(Agent."User Security ID");
    end;

    var
        SelectFileLbl: Label 'Select file';
        PdfFileFilterLbl: Label 'PDF Files (*.pdf)|*.pdf';
        InvoiceUploadTok: Label 'User uploaded an invoice for Payables Agent processing.', Locked = true;
}
