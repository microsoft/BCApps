// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Integration.Send;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Integration.Interfaces;

#if not CLEAN26
using System.Utilities;
using Microsoft.eServices.EDocument.Integration;
#endif

codeunit 6146 "Send Runner"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    trigger OnRun()
    begin
#if not CLEAN26
        if GlobalEDocumentService."Service Integration V2" <> Enum::"Service Integration"::"No Integration" then
            SendV2()
        else
            if GlobalEDocumentService."Use Batch Processing" then
                SendBatch()
            else
                Send();
#else
        SendV2();
#endif
    end;

#if not CLEAN26
    local procedure Send()
    begin
        this.TempBlob := GlobalSendContext.GetTempBlob();
#pragma warning disable AL0432
        IEDocIntegration := this.GlobalEDocumentService."Service Integration";
        IEDocIntegration.Send(this.GlobalEDocument, this.TempBlob, this.IsAsyncValue, this.HttpRequestMessage, this.HttpResponseMessage);
#pragma warning restore AL0432
    end;

    local procedure SendBatch()
    begin
        this.TempBlob := GlobalSendContext.GetTempBlob();
#pragma warning disable AL0432
        IEDocIntegration := this.GlobalEDocumentService."Service Integration";
        IEDocIntegration.SendBatch(this.GlobalEDocument, this.TempBlob, this.IsAsyncValue, this.HttpRequestMessage, this.HttpResponseMessage);
#pragma warning restore AL0432
    end;
#endif

    local procedure SendV2()
    begin
        IDocumentSender := this.GlobalEDocumentService."Service Integration V2";
        IDocumentSender.Send(this.GlobalEDocument, this.GlobalEDocumentService, GlobalSendContext);
        this.IsAsyncValue := IDocumentSender is IDocumentResponseHandler;
    end;

    procedure SetContext(SendContext: Codeunit SendContext)
    begin
        this.GlobalSendContext := SendContext;
    end;

    procedure SetDocumentAndService(var EDocument: Record "E-Document"; var EDocumentService: Record "E-Document Service")
    begin
        this.GlobalEDocument.Copy(EDocument);
        this.GlobalEDocumentService.Copy(EDocumentService);
    end;

    procedure GetIsAsync(): Boolean
    begin
        exit(this.IsAsyncValue);
    end;

#if not CLEAN26
    procedure GetSendContext(var SendContext: Codeunit SendContext);
    begin
        // For Service integration V1 the HTTP request and resposne should be specifically set after calling the send method 
        if GlobalEDocumentService."Service Integration V2" = Enum::"Service Integration"::"No Integration" then begin
            this.GlobalSendContext.Http().SetHttpRequestMessage(this.HttpRequestMessage);
            this.GlobalSendContext.Http().SetHttpResponseMessage(this.HttpResponseMessage);
            SendContext := this.GlobalSendContext;
        end;
    end;
#endif

    var
        GlobalEDocument: Record "E-Document";
        GlobalEDocumentService: Record "E-Document Service";
        GlobalSendContext: Codeunit SendContext;
#if not CLEAN26
        TempBlob: Codeunit "Temp Blob";
        HttpRequestMessage: HttpRequestMessage;
        HttpResponseMessage: HttpResponseMessage;
#pragma warning disable AL0432
        IEDocIntegration: Interface "E-Document Integration";
#pragma warning restore AL0432
#endif
        IDocumentSender: Interface IDocumentSender;
        IsAsyncValue: Boolean;
}
