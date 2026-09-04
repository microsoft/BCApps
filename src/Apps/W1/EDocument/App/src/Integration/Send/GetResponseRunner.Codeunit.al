// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Integration.Send;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Integration;
using Microsoft.eServices.EDocument.Integration.Interfaces;

codeunit 6149 "Get Response Runner"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;


    trigger OnRun()
    begin
        if GlobalEDocumentService."Service Integration V2" <> Enum::"Service Integration"::"No Integration" then begin
            IDocumentSender := GlobalEDocumentService."Service Integration V2";
            if IDocumentSender is IDocumentResponseHandler then
                Result := (IDocumentSender as IDocumentResponseHandler).GetResponse(this.GlobalEDocument, this.GlobalEDocumentService, GlobalSendContext);
            exit;
        end;

    end;

    procedure SetDocumentAndService(var EDocument: Record "E-Document"; var EDocumentService: Record "E-Document Service")
    begin
        this.GlobalEDocument.Copy(EDocument);
        this.GlobalEDocumentService.Copy(EDocumentService);
    end;

    procedure SetContext(SendContext: Codeunit SendContext)
    begin
        this.GlobalSendContext := SendContext;
    end;

    procedure GetResponseResult(): Boolean
    begin
        exit(Result);
    end;

    var
        GlobalEDocument: Record "E-Document";
        GlobalEDocumentService: Record "E-Document Service";
        GlobalSendContext: Codeunit SendContext;
        IDocumentSender: Interface IDocumentSender;
        Result: Boolean;
}
