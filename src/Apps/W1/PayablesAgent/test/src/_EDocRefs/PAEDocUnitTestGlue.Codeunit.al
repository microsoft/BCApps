// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Test.Agents.PayablesAgent;

using Microsoft.Agent.PayablesAgent;
using Microsoft.eServices.EDocument;
using Microsoft.EServices.EDocumentConnector.Microsoft365;

/// <summary>
/// The only place of the Payables Agent unit tests that references e-documents. It fabricates what the app cannot
/// receive on its own in a test: an email that arrived in the monitored mailbox. Only the draft-based agent (v1)
/// receives emails today, through the E-Document Microsoft 365 connector; the task-based agent (v2) has no email intake
/// yet. Everything after receipt goes through "PA Test Fixtures" and the app's entities.
/// </summary>
codeunit 133723 "PA EDoc Unit Test Glue"
{
    Access = Internal;

    /// <summary>
    /// Receives an email from a sender, without handing it to the agent, and loads the task it became.
    /// </summary>
    internal procedure ReceiveEmail(SenderEmail: Text; Subject: Text; var PATaskSource: Codeunit "PA Task Source"): Boolean
    var
        EDocument: Record "E-Document";
        PADraftBasedSetup: Codeunit "PA Draft Based Setup";
    begin
        EDocument.Service := PADraftBasedSetup.GetOrCreateAgentEDocumentService().Code;
        EDocument.Direction := EDocument.Direction::Incoming;
        EDocument."Source Details" := CopyStr(SenderEmail, 1, MaxStrLen(EDocument."Source Details"));
        EDocument."Additional Source Details" := CopyStr(Subject, 1, MaxStrLen(EDocument."Additional Source Details"));
        EDocument."Outlook Mail Message Id" := CopyStr(Format(CreateGuid()), 1, MaxStrLen(EDocument."Outlook Mail Message Id"));
        EDocument.Insert();
        exit(PATaskSource.Load(EDocument.SystemId));
    end;
}
