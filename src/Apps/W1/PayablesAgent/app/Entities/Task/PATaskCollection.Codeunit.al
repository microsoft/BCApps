// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Agent.PayablesAgent;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Processing.Import;
using System.Agents;

// Supplies semantic task projections; row ordinals never identify a backing record.
codeunit 3342 "PA Task Collection"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;
    Permissions = tabledata Agent = R, tabledata "Agent Task" = R, tabledata "E-Document" = R;

    internal procedure GetTasks(var TempTasks: Record "PA Detailed Task" temporary)
    var
        StoredTask: Record "Payables Agent Task";
        Agent: Record Agent;
        AgentTask: Record "Agent Task";
        SessionTask: Codeunit "Payables Agent Task";
    begin
        TempTasks.Reset();
        TempTasks.DeleteAll();
        if IsAgentSession() then begin
            if SessionTask.LoadCurrentSession() then
                InsertTask(TempTasks, SessionTask);
            exit;
        end;
        if PAV1V2Flag.IsV2Active() then begin
            if StoredTask.FindSet() then
                repeat
                    if SessionTask.Load(StoredTask.SystemId) then
                        InsertTask(TempTasks, SessionTask);
                until StoredTask.Next() = 0;
            exit;
        end;
        AgentTask.SetRange("Company Name", CompanyName());
        if AgentTask.FindSet() then
            repeat
                if Agent.Get(AgentTask."Agent User Security ID") then
                    if Agent."Agent Metadata Provider" = "Agent Metadata Provider"::"Payables Agent" then
                        if SessionTask.Load(AgentTask.ID) then
                            InsertTask(TempTasks, SessionTask);
            until AgentTask.Next() = 0;
    end;

    internal procedure GetTasksByState(State: Enum "PA Task State"; var TempTasks: Record "PA Detailed Task" temporary)
    var
        EDocument: Record "E-Document";
        StoredTask: Record "Payables Agent Task";
        Task: Codeunit "Payables Agent Task";
    begin
        TempTasks.Reset();
        TempTasks.DeleteAll();
        if IsAgentSession() then begin
            GetTasks(TempTasks);
            TempTasks.SetRange(State, State);
            exit;
        end;
        if PAV1V2Flag.IsV2Active() then begin
            case State of
                State::"Pending Processing":
                    StoredTask.SetRange("Completed At", 0DT);
                State::Processed:
                    StoredTask.SetFilter("Completed At", '<>%1', 0DT);
                else
                    exit;
            end;
            if StoredTask.FindSet() then
                repeat
                    if Task.Load(StoredTask.SystemId) then
                        InsertTask(TempTasks, Task);
                until StoredTask.Next() = 0;
            exit;
        end;
        EDocument.SetRange("Import Processing Status", GetEDocumentImportStatus(State));
        if EDocument.FindSet() then
            repeat
                if Task.Load(EDocument.SystemId) then
                    InsertTask(TempTasks, Task);
            until EDocument.Next() = 0;
    end;

    internal procedure CountByState(State: Enum "PA Task State"): Integer
    var
        EDocument: Record "E-Document";
        StoredTask: Record "Payables Agent Task";
    begin
        if PAV1V2Flag.IsV2Active() then
            case State of
                State::"Pending Processing":
                    begin
                        StoredTask.SetRange("Completed At", 0DT);
                        exit(StoredTask.Count());
                    end;
                State::Processed:
                    begin
                        StoredTask.SetFilter("Completed At", '<>%1', 0DT);
                        exit(StoredTask.Count());
                    end;
                else
                    exit(0);
            end;
        EDocument.SetRange("Import Processing Status", GetEDocumentImportStatus(State));
        exit(EDocument.Count());
    end;

    local procedure InsertTask(var TempTasks: Record "PA Detailed Task" temporary; Task: Codeunit "Payables Agent Task")
    var
        NextRow: BigInteger;
    begin
        NextRow := TempTasks.Count() + 1;
        Task.GetRecord(TempTasks);
        TempTasks."Entry No." := NextRow;
        TempTasks.Insert();
    end;

    local procedure IsAgentSession(): Boolean
    var
        AgentSession: Codeunit "Agent Session";
        Provider: Enum "Agent Metadata Provider";
    begin
        if not AgentSession.IsAgentSession(Provider) then
            exit(false);
        exit(Provider = Provider::"Payables Agent");
    end;

    local procedure GetEDocumentImportStatus(State: Enum "PA Task State"): Enum "Import E-Doc. Proc. Status"
    begin
        case State of
            State::"Needs Attention":
                exit("Import E-Doc. Proc. Status"::"Draft Ready");
            State::"Ready For Review":
                exit("Import E-Doc. Proc. Status"::"Ready for draft");
            State::Processed:
                exit("Import E-Doc. Proc. Status"::Processed);
            else
                exit("Import E-Doc. Proc. Status"::Readable);
        end;
    end;

    var
        PAV1V2Flag: Codeunit "PA V1V2 Flag";
}
