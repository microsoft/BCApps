// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Formats.Test;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Integration.Interfaces;
using Microsoft.eServices.EDocument.Integration.Receive;
using Microsoft.eServices.EDocument.Integration.Send;
using Microsoft.eServices.EDocument.Processing.Message;
using System.Utilities;

codeunit 148150 "FR E-Doc. Msg. Sender Mock" implements IDocumentSender, IDocumentReceiver, IConsentManager, IMessageSender, IMessageResponseHandler
{
    Access = Internal;
    SingleInstance = true;

    procedure Send(var EDocument: Record "E-Document"; var EDocumentService: Record "E-Document Service"; SendContext: Codeunit SendContext)
    var
        TempBlob: Codeunit "Temp Blob";
        InStream: InStream;
    begin
        SendCount += 1;
        TempBlob := SendContext.GetTempBlob();
        TempBlob.CreateInStream(InStream, TextEncoding::UTF8);
        InStream.ReadText(LastPayload);
        if ShouldFail then
            Error(SendingFailedErr);
        SendContext.Status().SetStatus(ResultStatus);
    end;

    procedure SendMessage(var EDocument: Record "E-Document"; var EDocumentService: Record "E-Document Service"; MessageContext: Codeunit "E-Doc. Message Context")
    var
        TempBlob: Codeunit "Temp Blob";
        InStream: InStream;
    begin
        SendCount += 1;
        MessageSendCount += 1;
        TempBlob := MessageContext.GetTempBlob();
        TempBlob.CreateInStream(InStream, TextEncoding::UTF8);
        InStream.ReadText(LastPayload);
        LastResponseType := MessageContext.GetResponseType();
        LastServiceCode := EDocumentService.Code;
        if ShouldFail then
            Error(SendingFailedErr);
        MessageContext.Status().SetStatus(MessageResultStatus);
    end;

    procedure GetMessageResponse(var EDocument: Record "E-Document"; var EDocumentService: Record "E-Document Service"; MessageContext: Codeunit "E-Doc. Message Context")
    begin
        MessageResponseCount += 1;
        MessageContext.Status().SetStatus(MessageResponseStatus);
    end;

    procedure ReceiveDocuments(var EDocumentService: Record "E-Document Service"; DocumentsMetadata: Codeunit "Temp Blob List"; ReceiveContext: Codeunit ReceiveContext)
    begin
    end;

    procedure DownloadDocument(var EDocument: Record "E-Document"; var EDocumentService: Record "E-Document Service"; DocumentMetadata: Codeunit "Temp Blob"; ReceiveContext: Codeunit ReceiveContext)
    begin
    end;

    procedure ObtainPrivacyConsent(): Boolean
    begin
        exit(true);
    end;

    procedure SetShouldFail(NewShouldFail: Boolean)
    begin
        ShouldFail := NewShouldFail;
    end;

    procedure SetResultStatus(NewResultStatus: Enum "E-Document Service Status")
    begin
        ResultStatus := NewResultStatus;
        MessageResultStatus := NewResultStatus;
    end;

    procedure GetSendCount(): Integer
    begin
        exit(SendCount);
    end;

    procedure GetLastPayload(): Text
    begin
        exit(LastPayload);
    end;

    procedure SetMessageResultStatus(NewResultStatus: Enum "E-Document Service Status")
    begin
        MessageResultStatus := NewResultStatus;
    end;

    procedure SetMessageResponseStatus(NewResultStatus: Enum "E-Document Service Status")
    begin
        MessageResponseStatus := NewResultStatus;
    end;

    procedure GetMessageSendCount(): Integer
    begin
        exit(MessageSendCount);
    end;

    procedure GetMessageResponseCount(): Integer
    begin
        exit(MessageResponseCount);
    end;

    procedure GetLastResponseType(): Enum "E-Doc. Response Type"
    begin
        exit(LastResponseType);
    end;

    procedure GetLastServiceCode(): Code[20]
    begin
        exit(LastServiceCode);
    end;

    procedure Reset()
    begin
        Clear(LastPayload);
        SendCount := 0;
        ShouldFail := false;
        ResultStatus := "E-Document Service Status"::Sent;
        MessageResultStatus := "E-Document Service Status"::Sent;
        MessageResponseStatus := "E-Document Service Status"::Sent;
        MessageSendCount := 0;
        MessageResponseCount := 0;
        LastResponseType := LastResponseType::None;
        Clear(LastServiceCode);
    end;

    var
        LastPayload: Text;
        SendCount: Integer;
        MessageSendCount: Integer;
        MessageResponseCount: Integer;
        ShouldFail: Boolean;
        ResultStatus: Enum "E-Document Service Status";
        MessageResultStatus: Enum "E-Document Service Status";
        MessageResponseStatus: Enum "E-Document Service Status";
        LastResponseType: Enum "E-Doc. Response Type";
        LastServiceCode: Code[20];
        SendingFailedErr: Label 'French lifecycle message sending failed.', Locked = true;
}