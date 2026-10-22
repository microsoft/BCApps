// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Test.Agents.PayablesAgent;

using Microsoft.Agent.PayablesAgent;
using Microsoft.eServices.EDocument;
using System.Agents;

// Contract tests of the wrappers over their draft-based (e-document) backing. Delete together with the draft-based agent.
codeunit 133736 "PA Draft Based Contract Tests"
{
    Access = Internal;
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure DraftBasedUploadRemainsUploadAndMatchesOnlyItsOwnResult()
    var
        AgentTask: Record "Agent Task";
        AgentTaskMessage: Record "Agent Task Message";
        Document: Record "E-Document";
        Service: Record "E-Document Service";
        OtherDocument: Record "E-Document";
        Source: Codeunit "PA Task Source";
        Task: Codeunit "Payables Agent Task";
    begin
        if not Service.Get('AGENT') then begin
            Service.Code := 'AGENT';
            Service.Insert();
        end;
        Document.Service := Service.Code;
        Document."Source Details" := 'fixture.pdf';
        Document.Insert();
        OtherDocument.Insert();
        Check(Source.Load(Document.SystemId), 'The draft-based source must load through its source identity.');
        Check(Source.GetSourceType() = "PA Source Type"::Upload, 'A draft-based upload must not be treated as email.');

        AgentTask."Company Name" := CopyStr(CompanyName(), 1, MaxStrLen(AgentTask."Company Name"));
        AgentTask."External ID" := Format(Document."Entry No");
        AgentTask.Insert();
        AgentTaskMessage.ID := CreateGuid();
        AgentTaskMessage."Task ID" := AgentTask.ID;
        AgentTaskMessage."External ID" := Format(Document."Entry No");
        AgentTaskMessage.Insert();

        Check(Task.Load(AgentTask.ID), 'The draft-based task must load through its Agent Framework task identity.');
        Check(Task.GetVersion() = "PA Version"::V1, 'The e-document backing must identify a v1 task.');
        Check(Task.IsResultRecord(Document.RecordId()), 'The source document is the draft-based review result.');
        Check(not Task.IsResultRecord(OtherDocument.RecordId()), 'A different source of the same table is not this task result.');
    end;

    [Test]
    [CommitBehavior(CommitBehavior::Error)]
    procedure DeactivationStopsBackingImporter()
    var
        Service: Record "E-Document Service";
        Proposal: Codeunit "PA Setup";
        Stored: Codeunit "PA Setup";
    begin
        if not Service.Get('AGENT') then begin
            Service.Code := 'AGENT';
            Service.Insert();
        end;
        // Seed configured state without scheduling a real background task.
        Service."Auto Import" := true;
        Clear(Service."Import Recurrent Job Id");
        Service.Modify();
        Proposal.GetSetup();
        Proposal.SetMonitorOutlook(true);
        Proposal.ApplySetup(false);
        Stored.GetSetup();
        Service.Get('AGENT');
        Check(not Stored.GetMonitorOutlook(), 'Deactivation must persist monitoring off.');
        Check(not Service."Auto Import", 'Deactivation must also turn the backing importer off.');
    end;

    local procedure Check(Condition: Boolean; Message: Text)
    begin
        if not Condition then
            Error(Message);
    end;
}
