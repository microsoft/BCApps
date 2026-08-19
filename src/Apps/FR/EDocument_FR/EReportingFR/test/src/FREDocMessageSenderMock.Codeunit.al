// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Formats.Test;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Integration.Interfaces;
using Microsoft.eServices.EDocument.Integration.Receive;
using Microsoft.eServices.EDocument.Integration.Send;
using System.Utilities;

codeunit 148150 "FR E-Doc. Msg. Sender Mock" implements IDocumentSender, IDocumentReceiver, IConsentManager
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
    end;

    procedure GetSendCount(): Integer
    begin
        exit(SendCount);
    end;

    procedure GetLastPayload(): Text
    begin
        exit(LastPayload);
    end;

    procedure Reset()
    begin
        Clear(LastPayload);
        SendCount := 0;
        ShouldFail := false;
        ResultStatus := "E-Document Service Status"::Sent;
    end;

    var
        LastPayload: Text;
        SendCount: Integer;
        ShouldFail: Boolean;
        ResultStatus: Enum "E-Document Service Status";
        SendingFailedErr: Label 'French lifecycle message sending failed.', Locked = true;
}