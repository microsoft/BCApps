// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Integration.Send;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Integration.Interfaces;

codeunit 6146 "Send Runner"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    trigger OnRun()
    begin
        SendV2();
    end;

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

    var
        GlobalEDocument: Record "E-Document";
        GlobalEDocumentService: Record "E-Document Service";
        GlobalSendContext: Codeunit SendContext;
        IDocumentSender: Interface IDocumentSender;
        IsAsyncValue: Boolean;
}
