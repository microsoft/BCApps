// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Agent.PayablesAgent;

using Microsoft.eServices.EDocument;
using System.Agents;

// This legacy page integration owns the historical runtime-message correlation protocol, not a shared wrapper escape hatch.
codeunit 3308 "PA Open Current E-Document"
{
    InherentEntitlements = X;
    InherentPermissions = X;

    trigger OnRun()
    var
        EDocument: Record "E-Document";
        InboundEDocuments: Page "Inbound E-Documents";
    begin
        EDocument.SetRange("Entry No", CurrentDocumentNo());
        InboundEDocuments.SetTableView(EDocument);
        InboundEDocuments.Run();
    end;

    [EventSubscriber(ObjectType::Page, Page::"Inbound E-Documents", OnOpenPageEvent, '', false, false)]
    local procedure ScopeAgentSession(var Rec: Record "E-Document")
    var
        DocumentNo: Integer;
    begin
        DocumentNo := CurrentDocumentNo();
        if DocumentNo <> 0 then
            Rec.SetRange("Entry No", DocumentNo);
    end;

    local procedure CurrentDocumentNo(): Integer
    var
        Message: Record "Agent Task Message";
        AgentSession: Codeunit "Agent Session";
        Provider: Enum "Agent Metadata Provider";
        DocumentNo: Integer;
    begin
        if not AgentSession.IsAgentSession(Provider) then
            exit(0);
        if Provider <> Provider::"Payables Agent" then
            exit(0);
        Message.SetRange("Task ID", AgentSession.GetCurrentSessionAgentTaskId());
        Message.SetFilter("External ID", '<>%1', '');
        if Message.FindFirst() then
            if Evaluate(DocumentNo, Message."External ID") then
                exit(DocumentNo);
        exit(0);
    end;
}
