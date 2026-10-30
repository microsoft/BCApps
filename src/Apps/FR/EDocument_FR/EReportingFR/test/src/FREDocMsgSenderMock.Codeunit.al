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
using System.Text;
using System.Threading;
using System.Utilities;

codeunit 148150 "FR E-Doc. Msg. Sender Mock" implements IDocumentSender, IDocumentReceiver, IConsentManager, IMessageSender, IMessageResponseHandler
{
    Access = Internal;
    SingleInstance = true;

    procedure Send(var EDocument: Record "E-Document"; var EDocumentService: Record "E-Document Service"; SendContext: Codeunit SendContext)
    begin
    end;

    procedure SendMessage(var EDocument: Record "E-Document"; var EDocumentService: Record "E-Document Service"; MessageContext: Codeunit "E-Doc. Message Context")
    var
        TempBlob: Codeunit "Temp Blob";
        PayloadLine: Text;
        InStream: InStream;
    begin
        SendCount += 1;
        LastResponseType := MessageContext.GetResponseType();
        TempBlob := MessageContext.GetTempBlob();
        LastPayloadBase64 := EncodePayload(TempBlob);
        TempBlob.CreateInStream(InStream, TextEncoding::UTF8);
        Clear(LastPayload);
        while not InStream.EOS do begin
            InStream.ReadText(PayloadLine);
            LastPayload += PayloadLine;
        end;
        if not ReportFailure then
            if AsyncResponse then
                MessageContext.Status().SetStatus("E-Document Service Status"::"Pending Response")
            else
                MessageContext.Status().SetStatus("E-Document Service Status"::Sent);
    end;

    procedure GetResponse(var EDocument: Record "E-Document"; var EDocumentService: Record "E-Document Service"; MessageContext: Codeunit "E-Doc. Message Context"): Boolean
    begin
        PollCount += 1;
        LastPollPayloadBase64 := EncodePayload(MessageContext.GetTempBlob());
        if ResponseFailure then
            Error('TEST FR POLLING FAILURE');
        if ResponseReceived then
            MessageContext.Status().SetStatus("E-Document Service Status"::Sent)
        else
            MessageContext.Status().SetStatus("E-Document Service Status"::"Pending Response");
        exit(ResponseReceived);
    end;

    procedure SetAsyncResponse()
    begin
        AsyncResponse := true;
    end;

    procedure SetResponseReceived()
    begin
        ResponseReceived := true;
    end;

    procedure SetResponseFailure(NewResponseFailure: Boolean)
    begin
        ResponseFailure := NewResponseFailure;
    end;

    procedure CaptureScheduledMessageJobs()
    begin
        CaptureJobs := true;
        Clear(LastScheduledJob);
    end;

    procedure GetScheduledJob(var JobQueueEntry: Record "Job Queue Entry")
    begin
        JobQueueEntry := LastScheduledJob;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Job Queue Entry", 'OnAfterInsertEvent', '', false, false)]
    local procedure OnAfterInsertJob(var Rec: Record "Job Queue Entry"; RunTrigger: Boolean)
    begin
        if not CaptureJobs or Rec.IsTemporary() then
            exit;
        if Rec."Record ID to Process".TableNo() = 0 then
            exit;
        LastScheduledJob := Rec;
    end;

    procedure GetPollCount(): Integer
    begin
        exit(PollCount);
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

    procedure Reset()
    begin
        Clear(LastPayload);
        Clear(LastPayloadBase64);
        Clear(LastPollPayloadBase64);
        Clear(LastResponseType);
        ReportFailure := false;
        SendCount := 0;
        AsyncResponse := false;
        ResponseReceived := false;
        PollCount := 0;
        ResponseFailure := false;
        CaptureJobs := false;
        Clear(LastScheduledJob);
    end;

    procedure SetReportSuccess(NewReportSuccess: Boolean)
    begin
        ReportFailure := not NewReportSuccess;
    end;

    procedure GetSendCount(): Integer
    begin
        exit(SendCount);
    end;

    procedure GetLastPayload(): Text
    begin
        exit(LastPayload);
    end;

    procedure GetLastResponseType(): Enum "E-Doc. Response Type"
    begin
        exit(LastResponseType);
    end;

    procedure GetLastPayloadBase64(): Text
    begin
        exit(LastPayloadBase64);
    end;

    procedure GetLastPollPayloadBase64(): Text
    begin
        exit(LastPollPayloadBase64);
    end;

    local procedure EncodePayload(TempBlob: Codeunit "Temp Blob"): Text
    var
        Base64Convert: Codeunit "Base64 Convert";
        PayloadStream: InStream;
    begin
        TempBlob.CreateInStream(PayloadStream);
        exit(Base64Convert.ToBase64(PayloadStream));
    end;

    var
        LastResponseType: Enum "E-Doc. Response Type";
        LastPayload: Text;
        LastPayloadBase64: Text;
        LastPollPayloadBase64: Text;
        ReportFailure: Boolean;
        SendCount: Integer;
        AsyncResponse: Boolean;
        ResponseReceived: Boolean;
        PollCount: Integer;
        ResponseFailure: Boolean;
        CaptureJobs: Boolean;
        LastScheduledJob: Record "Job Queue Entry";
}