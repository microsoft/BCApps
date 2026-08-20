// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Processing.Message;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Integration.Interfaces;

codeunit 6534 "E-Doc. Msg. Transport Default" implements IMessageSender
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    procedure SendMessage(var EDocument: Record "E-Document"; var EDocumentService: Record "E-Document Service"; MessageContext: Codeunit "E-Doc. Message Context")
    var
        MessageTransportErrorInfo: ErrorInfo;
    begin
        MessageTransportErrorInfo.Message := StrSubstNo(MessageTransportNotSupportedErr, EDocumentService.Code);
        MessageTransportErrorInfo.RecordId := EDocumentService.RecordId;
        MessageTransportErrorInfo.PageNo := Page::"E-Document Service";
        MessageTransportErrorInfo.AddNavigationAction(ShowEDocumentServiceLbl);
        Error(MessageTransportErrorInfo);
    end;

    var
        MessageTransportNotSupportedErr: Label 'E-Document service %1 does not support sending E-Document messages.', Comment = '%1 = E-Document service code';
        ShowEDocumentServiceLbl: Label 'Open E-Document Service';
}