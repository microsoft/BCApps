// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Agent.PayablesAgent;

using Microsoft.eServices.EDocument;

codeunit 3333 "PA Draft Work Item Intake"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;
    Permissions = tabledata "E-Document" = RM;

    internal procedure TryProcessIncomingWorkItem(WorkItemId: Guid): Boolean
    var
        EDocument: Record "E-Document";
        DraftBasedWorkItem: Codeunit "PA Draft Based Work Item";
        EDocImport: Codeunit "E-Doc. Import";
    begin
        if not DraftBasedWorkItem.Load(WorkItemId) then
            exit(false);
        EDocument.GetBySystemId(WorkItemId);
        EDocImport.ProcessAutomaticallyIncomingEDocument(EDocument);
        exit(true);
    end;

    internal procedure TryGetAgentTaskMessage(WorkItemId: Guid; var Message: Text): Boolean
    var
        WorkItem: Codeunit "PA Draft Based Work Item";
        MessageLbl: Label 'A new electronic document %1 has been received. Your task is to create the purchase document for it in Business Central: a Purchase Invoice, or a Purchase Credit Memo when the draft''s Document Type is Purchase Credit Memo.', Locked = true, Comment = '%1 = e-document entry number';
    begin
        Clear(Message);
        if not WorkItem.Load(WorkItemId) then
            exit(false);
        Message := StrSubstNo(MessageLbl, WorkItem.GetAgentTaskExternalId());
        exit(true);
    end;
}
