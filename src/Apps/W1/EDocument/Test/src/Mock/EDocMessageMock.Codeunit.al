// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Test;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Integration.Interfaces;
using Microsoft.eServices.EDocument.Processing.Message;
using System.Utilities;

codeunit 133519 "E-Doc. Message Mock" implements IMessageSender, IMessageResponseHandler
{
    Access = Internal;
    SingleInstance = true;

    procedure SendMessage(var EDocument: Record "E-Document"; var EDocumentService: Record "E-Document Service"; MessageContext: Codeunit "E-Doc. Message Context")
    begin
        CaptureContext(EDocument, EDocumentService, MessageContext);
        MessageContext.Status().SetStatus(SendStatus);
        SendCount += 1;
    end;

    procedure GetMessageResponse(var EDocument: Record "E-Document"; var EDocumentService: Record "E-Document Service"; MessageContext: Codeunit "E-Doc. Message Context")
    begin
        CaptureContext(EDocument, EDocumentService, MessageContext);
        MessageContext.Status().SetStatus(ResponseStatus);
        ResponseCount += 1;
    end;

    internal procedure Reset()
    begin
        ClearAll();
        SendStatus := SendStatus::Sent;
        ResponseStatus := ResponseStatus::"Pending Response";
    end;

    internal procedure SetSendStatus(NewSendStatus: Enum "E-Document Service Status")
    begin
        SendStatus := NewSendStatus;
    end;

    internal procedure SetResponseStatus(NewResponseStatus: Enum "E-Document Service Status")
    begin
        ResponseStatus := NewResponseStatus;
    end;

    internal procedure GetLastPayload(): Text
    var
        InStream: InStream;
        PayloadText: Text;
    begin
        LastPayload.CreateInStream(InStream);
        InStream.ReadText(PayloadText);
        exit(PayloadText);
    end;

    internal procedure GetLastMessageEntryNo(): Integer
    begin
        exit(LastMessageEntryNo);
    end;

    internal procedure GetLastEDocumentEntryNo(): Integer
    begin
        exit(LastEDocumentEntryNo);
    end;

    internal procedure GetLastServiceCode(): Code[20]
    begin
        exit(LastServiceCode);
    end;

    internal procedure GetSendCount(): Integer
    begin
        exit(SendCount);
    end;

    internal procedure GetResponseCount(): Integer
    begin
        exit(ResponseCount);
    end;

    local procedure CaptureContext(EDocument: Record "E-Document"; EDocumentService: Record "E-Document Service"; MessageContext: Codeunit "E-Doc. Message Context")
    begin
        LastEDocumentEntryNo := EDocument."Entry No";
        LastServiceCode := EDocumentService.Code;
        LastMessageEntryNo := MessageContext.GetMessageEntryNo();
        LastPayload := MessageContext.GetTempBlob();
    end;

    var
        LastPayload: Codeunit "Temp Blob";
        SendStatus: Enum "E-Document Service Status";
        ResponseStatus: Enum "E-Document Service Status";
        LastServiceCode: Code[20];
        LastEDocumentEntryNo: Integer;
        LastMessageEntryNo: Integer;
        SendCount: Integer;
        ResponseCount: Integer;
}