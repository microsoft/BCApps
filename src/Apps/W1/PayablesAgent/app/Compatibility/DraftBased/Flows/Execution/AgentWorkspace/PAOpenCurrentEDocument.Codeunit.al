// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
#if not CLEAN27
#pragma warning disable AS0049
#endif

namespace Microsoft.Agent.PayablesAgent;

using Microsoft.eServices.EDocument;

// V1 page navigation uses the accepted task wrapper to resolve the current source.
codeunit 3308 "PA Open Current E-Document"
{
    Access = Internal;
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
        EDocument: Record "E-Document";
        Task: Codeunit "Payables Agent Task";
    begin
        if not Task.LoadCurrentSession() then
            exit(0);
        if Task.GetVersion() <> "PA Version"::V1 then
            exit(0);
        if EDocument.GetBySystemId(Task.GetSourceId()) then
            exit(EDocument."Entry No");
        exit(0);
    end;
}
#if not CLEAN27
#pragma warning restore AS0049
#endif