// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Agent.PayablesAgent;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Processing.Import;
using System.Agents;

/// <summary>
/// SDK for sets of Payables Agent tasks: populates the enriched "PA Detailed Task" records for lists, counts tasks by
/// state and scopes lists to the current agent session, adapting to whether tasks are backed by e-documents (v1) or
/// Payables Agent tasks (v2). Per-task resolution is delegated to "PA Task".
/// </summary>
codeunit 3342 "PA Task Collection"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;
    Permissions = tabledata Agent = R, tabledata "Agent Task" = R, tabledata "Agent Task Message" = R, tabledata "E-Document" = R, tabledata "Payables Agent Task" = R;

    /// <summary>
    /// Fills a temporary set with every task of the agent. In a Payables Agent session only the session's task is
    /// included.
    /// </summary>
    internal procedure GetTasks(var TempPADetailedTask: Record "PA Detailed Task" temporary)
    var
        PayablesAgentTask: Record "Payables Agent Task";
        Agent: Record Agent;
        AgentTask: Record "Agent Task";
        PayablesAgent: Codeunit "Payables Agent Metadata";
        PayablesAgentSetup: Codeunit "Payables Agent Setup";
        SessionAgentTaskId: BigInteger;
    begin
        TempPADetailedTask.Reset();
        TempPADetailedTask.DeleteAll();
        if PayablesAgent.IsPayablesAgentSession(SessionAgentTaskId) then begin
            if PATask.LoadCurrentSession() then
                InsertLoadedTask(TempPADetailedTask);
            exit;
        end;
        if PAV1V2Flag.IsV2Active() then begin
            if PayablesAgentTask.FindSet() then
                repeat
                    PATask.LoadFromPayablesAgentTask(PayablesAgentTask);
                    InsertLoadedTask(TempPADetailedTask);
                until PayablesAgentTask.Next() = 0;
            exit;
        end;
        if not PayablesAgentSetup.GetAgent(Agent, false) then
            exit;
        AgentTask.SetRange("Agent User Security ID", Agent."User Security ID");
        AgentTask.SetRange("Company Name", CompanyName());
        AgentTask.SetLoadFields(ID);
        if AgentTask.FindSet() then
            repeat
                if PATask.Load(AgentTask.ID) then
                    InsertLoadedTask(TempPADetailedTask);
            until AgentTask.Next() = 0;
    end;

    /// <summary>
    /// Number of tasks in a state.
    /// </summary>
    internal procedure CountByState(PATaskState: Enum "PA Task State"): Integer
    var
        EDocument: Record "E-Document";
        PayablesAgentTask: Record "Payables Agent Task";
    begin
        if PAV1V2Flag.IsV2Active() then
            // TODOPAV2: define "Needs Attention" and "Ready For Review" for v2 tasks.
            case PATaskState of
                "PA Task State"::"Pending Processing":
                    begin
                        PayablesAgentTask.SetRange("Completed At", 0DT);
                        exit(PayablesAgentTask.Count());
                    end;
                "PA Task State"::Processed:
                    begin
                        PayablesAgentTask.SetFilter("Completed At", '<>%1', 0DT);
                        exit(PayablesAgentTask.Count());
                    end;
                else
                    exit(0);
            end;

        EDocument.SetRange("Import Processing Status", GetEDocumentImportStatus(PATaskState));
        exit(EDocument.Count());
    end;

    /// <summary>
    /// Opens the list of tasks in a state.
    /// </summary>
    internal procedure DrillDownByState(PATaskState: Enum "PA Task State")
    var
        EDocument: Record "E-Document";
        InboundEDocuments: Page "Inbound E-Documents";
    begin
        if PAV1V2Flag.IsV2Active() then begin
            // TODOPAV2: filter the task list by state.
            Page.Run(Page::"Payables Agent Tasks");
            exit;
        end;

        EDocument.SetRange("Import Processing Status", GetEDocumentImportStatus(PATaskState));
        InboundEDocuments.SetTableView(EDocument);
        InboundEDocuments.Run();
    end;

    local procedure InsertLoadedTask(var TempPADetailedTask: Record "PA Detailed Task" temporary)
    begin
        TempPADetailedTask.Init();
        PATask.GetRecord(TempPADetailedTask);
        if TempPADetailedTask.Insert() then;
    end;

    local procedure GetEDocumentImportStatus(PATaskState: Enum "PA Task State"): Enum "Import E-Doc. Proc. Status"
    begin
        case PATaskState of
            "PA Task State"::"Needs Attention":
                exit(Enum::"Import E-Doc. Proc. Status"::"Draft Ready");
            "PA Task State"::"Ready For Review":
                exit(Enum::"Import E-Doc. Proc. Status"::"Ready for draft");
            "PA Task State"::Processed:
                exit(Enum::"Import E-Doc. Proc. Status"::Processed);
            else
                exit(Enum::"Import E-Doc. Proc. Status"::Readable);
        end;
    end;

    /// <summary>
    /// Scopes the Inbound E-Documents list to the e-document of the current agent session (v1). Under v2 the agent
    /// does not work from that page, so no filter is applied.
    /// </summary>
    [EventSubscriber(ObjectType::Page, Page::"Inbound E-Documents", OnOpenPageEvent, '', false, false)]
    local procedure OnOpenInboundEDocumentsPage(var Rec: Record "E-Document")
    var
        EDocument: Record "E-Document";
        SessionPATask: Codeunit "PA Task";
    begin
        if PAV1V2Flag.IsV2Active() then
            exit;
        if not SessionPATask.LoadCurrentSession() then
            exit;
        if SessionPATask.GetSourceRecordId().TableNo() <> Database::"E-Document" then
            exit;
        if not EDocument.Get(SessionPATask.GetSourceRecordId()) then
            exit;
        Rec.SetRange("Entry No", EDocument."Entry No");
    end;

    var
        PATask: Codeunit "PA Task";
        PAV1V2Flag: Codeunit "PA V1V2 Flag";
}
