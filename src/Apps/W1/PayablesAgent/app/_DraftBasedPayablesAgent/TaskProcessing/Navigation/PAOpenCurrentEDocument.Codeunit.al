// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Agent.PayablesAgent;

using Microsoft.eServices.EDocument;

codeunit 3308 "PA Open Current E-Document"
{
    InherentEntitlements = X;
    InherentPermissions = X;

    trigger OnRun()
    var
        EDocument: Record "E-Document";
        PATask: Codeunit "PA Task";
        InboundEDocuments: Page "Inbound E-Documents";
    begin
        if PATask.LoadCurrentSession() then
            if PATask.GetSourceRecordId().TableNo() = Database::"E-Document" then
                if EDocument.Get(PATask.GetSourceRecordId()) then;
        EDocument.SetRecFilter();
        InboundEDocuments.SetTableView(EDocument);
        InboundEDocuments.Run();
    end;
}