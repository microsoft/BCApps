// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Outlook;

using Microsoft.EServices.EDocument;
using System;

codeunit 1631 "Office Host Management"
{
    var
        OfficeHostNotInitializedErr: Label 'The Office host has not been initialized.';

    [Scope('OnPrem')]
    procedure InitializeHost(NewOfficeHost: DotNet OfficeHost; NewHostType: Text)
    begin
        OnInitializeHost(NewOfficeHost, NewHostType);
    end;

    [Scope('OnPrem')]
    procedure InitializeContext(TempNewOfficeAddinContext: Record "Office Add-in Context" temporary)
    begin
        CheckHost();
        OnInitializeContext(TempNewOfficeAddinContext);
    end;

    [Scope('OnPrem')]
    procedure InitializeExchangeObject()
    begin
        CheckHost();
        OnInitializeExchangeObject();
    end;

    [Scope('OnPrem')]
    procedure GetHostName(): Text
    var
        HostName: Text;
    begin
        CheckHost();
        OnGetHostName(HostName);
        exit(HostName);
    end;

    [Scope('OnPrem')]
    procedure GetHostType(): Text
    var
        HostType: Text;
    begin
        CheckHost();
        OnGetHostType(HostType);
        exit(HostType);
    end;

    [Scope('OnPrem')]
    procedure CloseCurrentPage()
    begin
        OnCloseCurrentPage();
    end;

    [Scope('OnPrem')]
    procedure InvokeExtension(FunctionName: Text; Parameter1: Variant; Parameter2: Variant; Parameter3: Variant; Parameter4: Variant)
    begin
        CheckHost();
        OnInvokeExtension(FunctionName, Parameter1, Parameter2, Parameter3, Parameter4);
    end;

    [Scope('OnPrem')]
    procedure IsAvailable(): Boolean
    var
        Result: Boolean;
    begin
        OnIsAvailable(Result);
        exit(Result);
    end;

    [Scope('OnPrem')]
    procedure GetTempOfficeAddinContext(var TempOfficeAddinContext: Record "Office Add-in Context" temporary)
    begin
        OnGetTempOfficeAddinContext(TempOfficeAddinContext);
    end;

    [Scope('OnPrem')]
    procedure SendToOCR(IncomingDocument: Record "Incoming Document")
    begin
        OnSendToOCR(IncomingDocument);
    end;

    [Scope('OnPrem')]
    procedure EmailHasAttachments(): Boolean
    var
        Result: Boolean;
    begin
        OnEmailHasAttachments(Result);
        exit(Result);
    end;

    [Scope('OnPrem')]
    procedure GetEmailAndAttachments(var TempExchangeObject: Record "Exchange Object" temporary; "Action": Option InitiateSendToOCR,InitiateSendToIncomingDocuments,InitiateSendToWorkFlow,InitiateSendToAttachments; RecRef: RecordRef)
    begin
        OnGetEmailAndAttachmentsForEntity(TempExchangeObject, Action, RecRef);
    end;

    [Scope('OnPrem')]
    procedure GetEmailBody(OfficeAddinContext: Record "Office Add-in Context") EmailBody: Text
    begin
        OnGetEmailBody(OfficeAddinContext."Item ID", EmailBody);
    end;

    [Scope('OnPrem')]
    procedure GetFinancialsDocument(OfficeAddinContext: Record "Office Add-in Context") DocumentJSON: Text
    begin
        OnGetFinancialsDocument(OfficeAddinContext."Item ID", DocumentJSON);
    end;

    [Scope('OnPrem')]
    procedure CheckHost()
    var
        Result: Boolean;
    begin
        OnIsHostInitialized(Result);
        if not Result then
            Error(OfficeHostNotInitializedErr);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitializeHost(NewOfficeHost: DotNet OfficeHost; NewHostType: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitializeContext(TempNewOfficeAddinContext: Record "Office Add-in Context" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitializeExchangeObject()
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetHostName(var HostName: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetHostType(var HostType: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCloseCurrentPage()
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInvokeExtension(FunctionName: Text; Parameter1: Variant; Parameter2: Variant; Parameter3: Variant; Parameter4: Variant)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnIsHostInitialized(var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnIsAvailable(var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetTempOfficeAddinContext(var TempOfficeAddinContext: Record "Office Add-in Context" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSendToOCR(IncomingDocument: Record "Incoming Document")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnEmailHasAttachments(var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetEmailAndAttachmentsForEntity(var TempExchangeObject: Record "Exchange Object" temporary; "Action": Option InitiateSendToOCR,InitiateSendToIncomingDocuments,InitiateSendToWorkFlow; RecRef: RecordRef)
    begin
    end;


    [IntegrationEvent(false, false)]
    local procedure OnGetEmailBody(ItemID: Text[250]; var EmailBody: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetFinancialsDocument(ItemID: Text[250]; var DocumentJSON: Text)
    begin
    end;
}

