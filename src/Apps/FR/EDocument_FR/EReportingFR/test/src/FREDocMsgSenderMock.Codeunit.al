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

codeunit 148150 "FR E-Doc. Msg. Sender Mock" implements IDocumentSender, IDocumentReceiver, IConsentManager, IMessageSender
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
        TempBlob.CreateInStream(InStream, TextEncoding::UTF8);
        Clear(LastPayload);
        while not InStream.EOS do begin
            InStream.ReadText(PayloadLine);
            LastPayload += PayloadLine;
        end;
        if ReportSuccess then
            MessageContext.Status().SetStatus("E-Document Service Status"::Sent);
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
        Clear(LastResponseType);
        ReportSuccess := true;
        SendCount := 0;
    end;

    procedure SetReportSuccess(NewReportSuccess: Boolean)
    begin
        ReportSuccess := NewReportSuccess;
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

    var
        LastResponseType: Enum "E-Doc. Response Type";
        LastPayload: Text;
        ReportSuccess: Boolean;
        SendCount: Integer;
}