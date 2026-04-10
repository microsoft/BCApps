#if not CLEAN26
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Test;

using Microsoft.eServices.EDocument;
using System.Utilities;

#pragma warning disable AL0432
codeunit 139619 "E-Doc. Integration Mock" implements "E-Document Integration"
{
    ObsoleteTag = '26.0';
    ObsoleteState = Pending;
    ObsoleteReason = 'Obsolete in 26.0';
#pragma warning restore AL0432

    procedure Send(var EDocument: Record "E-Document"; var TempBlob: Codeunit "Temp Blob"; var IsAsync: Boolean; var HttpRequest: HttpRequestMessage; var HttpResponse: HttpResponseMessage);
    begin
        OnSend(EDocument, TempBlob, IsAsync, HttpRequest, HttpResponse);
    end;

    procedure ReceiveDocument(var TempBlob: codeunit "Temp Blob"; var HttpRequest: HttpRequestMessage; var HttpResponse: HttpResponseMessage);
    begin
        OnReceiveDocument(TempBlob, HttpRequest, HttpResponse);
    end;

    procedure GetDocumentCountInBatch(var TempBlob: codeunit "Temp Blob"): Integer;
    var
        Count: Integer;
    begin
        OnGetDocumentCountInBatch(Count);
        exit(Count);
    end;

#pragma warning disable AA0150
    procedure SendBatch(var EDocuments: Record "E-Document"; var TempBlob: codeunit System.Utilities."Temp Blob"; var IsAsync: Boolean; var HttpRequest: HttpRequestMessage; var HttpResponse: HttpResponseMessage);
#pragma warning restore AA0150
    begin

    end;

    procedure GetResponse(var EDocument: Record "E-Document"; var HttpRequest: HttpRequestMessage; var HttpResponse: HttpResponseMessage): Boolean
    var
        Success: Boolean;
    begin
        OnGetResponse(EDocument, HttpRequest, HttpResponse, Success);
        exit(Success);
    end;

    procedure GetApproval(var EDocument: Record "E-Document"; var HttpRequest: HttpRequestMessage; var HttpResponse: HttpResponseMessage): Boolean
    var
        Success: Boolean;
    begin
        OnGetApproval(EDocument, HttpRequest, HttpResponse, Success);
        exit(Success);
    end;

    procedure Cancel(var EDocument: Record "E-Document"; var HttpRequest: HttpRequestMessage; var HttpResponse: HttpResponseMessage): Boolean
    begin

    end;

#pragma warning disable AA0150
    procedure GetIntegrationSetup(var SetupPage: Integer; var SetupTable: Integer);
#pragma warning restore AA0150
    begin

    end;

    [IntegrationEvent(false, false)]
    local procedure OnSend(var EDocument: Record "E-Document"; var TempBlob: Codeunit "Temp Blob"; var IsAsync: Boolean; var HttpRequest: HttpRequestMessage; var HttpResponse: HttpResponseMessage)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnReceiveDocument(var TempBlob: codeunit "Temp Blob"; var HttpRequest: HttpRequestMessage; var HttpResponse: HttpResponseMessage);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetDocumentCountInBatch(var Count: Integer);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetResponse(var EDocument: Record "E-Document"; var HttpRequest: HttpRequestMessage; var HttpResponse: HttpResponseMessage; var Success: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetApproval(var EDocument: Record "E-Document"; var HttpRequest: HttpRequestMessage; var HttpResponse: HttpResponseMessage; var Success: Boolean);
    begin
    end;

}
#endif