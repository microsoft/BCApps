// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Agent.SalesOrderAgent;

using Microsoft.Foundation.Attachment;
using Microsoft.Sales.Document;
using System.Agents;
using System.Telemetry;

codeunit 4600 "SOA Document Events"
{
    EventSubscriberInstance = Manual;
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;
    Permissions = tabledata "Agent Task Message" = r,
                  tabledata "SOA Attachment Transfer" = RID;

    [EventSubscriber(ObjectType::Table, Database::"Sales Header", OnAfterModifyEvent, '', false, false)]
    local procedure OnChangeSalesHeader(var Rec: Record "Sales Header")
    var
        SOABilling: Codeunit "SOA Billing";
    begin
        if Rec.IsTemporary() then
            exit;
        if Rec."Document Type" = Rec."Document Type"::Order then
            SOABilling.LogOrderModified(Rec.SystemId, AgentTaskID);
        if Rec."Document Type" = Rec."Document Type"::Quote then begin
            SOABilling.LogQuoteModified(Rec.SystemId, AgentTaskID);
            AddAttachmentsToDocument(Rec);
        end;
    end;

    local procedure AddAttachmentsToDocument(var Rec: Record "Sales Header")
    var
        AgentTaskMessage: Record "Agent Task Message";
        AgentTaskMessageAttachment: Record "Agent Task Message Attachment";
        FeatureTelemetry: Codeunit "Feature Telemetry";
        SOASetupCU: Codeunit "SOA Setup";
        TelemetryDimensions: Dictionary of [Text, Text];
        CopiedAttachments: Integer;
    begin
        AgentTaskMessage.SetRange("Task ID", AgentTaskID);
        AgentTaskMessage.SetRange(Type, AgentTaskMessage.Type::Input);
        if not AgentTaskMessage.FindSet() then
            exit;

        TelemetryDimensions.Add('TaskId', Format(AgentTaskID));
        repeat
            CopiedAttachments := 0;
            AgentTaskMessageAttachment.SetRange("Task ID", AgentTaskID);
            AgentTaskMessageAttachment.SetRange("Message ID", AgentTaskMessage.ID);
            AgentTaskMessageAttachment.SetRange(Ignored, false);
            if AgentTaskMessageAttachment.FindSet() then
                repeat
                    if CopyAttachmentToDocument(AgentTaskMessageAttachment, Rec) then
                        CopiedAttachments += 1;
                until AgentTaskMessageAttachment.Next() = 0;
            if CopiedAttachments > 0 then begin
                TelemetryDimensions.Set('TaskMessageId', Format(AgentTaskMessage.ID));
                TelemetryDimensions.Set('CopiedAttachments', Format(CopiedAttachments, 0, 9));
                FeatureTelemetry.LogUsage('0000QF5', SOASetupCU.GetFeatureName(), AttachmentsTransferredToDocLbl, TelemetryDimensions);
            end;
        until AgentTaskMessage.Next() = 0;
    end;

    local procedure CopyAttachmentToDocument(AgentTaskMessageAttachment: Record "Agent Task Message Attachment"; SalesHeader: Record "Sales Header"): Boolean
    var
        SOAAttachmentTransfer: Record "SOA Attachment Transfer";
        DocumentAttachment: Record "Document Attachment";
        AgentTaskFile: Record "Agent Task File";
        FileInStream: InStream;
    begin
        SOAAttachmentTransfer.LockTable();
        if SOAAttachmentTransfer.Get(AgentTaskMessageAttachment.SystemId, SalesHeader.SystemId) then begin
            DocumentAttachment.SetRange(SystemId, SOAAttachmentTransfer."Document Attachment ID");
            DocumentAttachment.SetRange("Table ID", Database::"Sales Header");
            DocumentAttachment.SetRange("Document Type", DocumentAttachment."Document Type"::Quote);
            DocumentAttachment.SetRange("No.", SalesHeader."No.");
            DocumentAttachment.SetRange("Line No.", 0);
            if not DocumentAttachment.IsEmpty() then
                exit(false);

            SOAAttachmentTransfer.Delete();
        end;

        AgentTaskFile.SetRange(ID, AgentTaskMessageAttachment."File ID");
        if not AgentTaskFile.FindFirst() then begin
            LogSkippedAttachment(AgentTaskMessageAttachment, AttachmentFileMissingTxt);
            exit(false);
        end;

        AgentTaskFile.CalcFields(Content);
        if not AgentTaskFile.Content.HasValue() then begin
            LogSkippedAttachment(AgentTaskMessageAttachment, AttachmentContentEmptyTxt);
            exit(false);
        end;

        AgentTaskFile.Content.CreateInStream(FileInStream);
        SOAAttachmentTransfer.Init();
        SOAAttachmentTransfer."Attachment ID" := AgentTaskMessageAttachment.SystemId;
        SOAAttachmentTransfer."Sales Header ID" := SalesHeader.SystemId;
        SOAAttachmentTransfer."Task ID" := AgentTaskMessageAttachment."Task ID";
        SOAAttachmentTransfer."Task Message ID" := AgentTaskMessageAttachment."Message ID";
        SOAAttachmentTransfer."Document Attachment ID" := CopyToDocument(FileInStream, SalesHeader, AgentTaskFile."File Name");
        SOAAttachmentTransfer.Insert();
        exit(true);
    end;

    local procedure LogSkippedAttachment(AgentTaskMessageAttachment: Record "Agent Task Message Attachment"; Reason: Text)
    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
        SOASetupCU: Codeunit "SOA Setup";
        TelemetryDimensions: Dictionary of [Text, Text];
    begin
        TelemetryDimensions.Add('TaskId', Format(AgentTaskMessageAttachment."Task ID"));
        TelemetryDimensions.Add('TaskMessageId', Format(AgentTaskMessageAttachment."Message ID"));
        TelemetryDimensions.Add('FileId', Format(AgentTaskMessageAttachment."File ID", 0, 9));
        FeatureTelemetry.LogError('0000WB2', SOASetupCU.GetFeatureName(), 'Copy attachment to sales quote', Reason, '', TelemetryDimensions);
    end;

    local procedure CopyToDocument(FileInStream: InStream; SalesHeader: Record "Sales Header"; FileName: Text): Guid
    var
        DocumentAttachment: Record "Document Attachment";
    begin
        DocumentAttachment.Init();
        DocumentAttachment.SaveAttachmentFromStream(FileInStream, SalesHeader, FileName);
        exit(DocumentAttachment.SystemId);
    end;

    procedure SetAgentTaskID(NewAgentTaskID: BigInteger)
    begin
        AgentTaskID := NewAgentTaskID;
    end;

    var
        AgentTaskID: BigInteger;
        AttachmentsTransferredToDocLbl: Label 'Attachments successfully transferred to the document.';
        AttachmentFileMissingTxt: Label 'The agent task attachment file could not be found. The attachment was not marked as transferred.', Locked = true;
        AttachmentContentEmptyTxt: Label 'The agent task attachment file has no content. The attachment was not marked as transferred.', Locked = true;
}