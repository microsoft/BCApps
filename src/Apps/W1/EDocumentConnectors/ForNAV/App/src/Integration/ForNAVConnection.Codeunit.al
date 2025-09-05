// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocumentConnector.ForNAV;

using Microsoft.EServices.EDocument;
using System.Utilities;
using System.Environment;
using Microsoft.eServices.EDocument.Integration.Send;
using Microsoft.eServices.EDocument.Integration.Receive;
codeunit 6416 "ForNAV Connection"
{
    Access = Internal;
    Permissions = tabledata "E-Document" = m;

    procedure HandleSendFilePostRequest(var EDocument: Record "E-Document"; SendContext: Codeunit SendContext): Boolean
    begin
        ForNAVAPIRequests.SendFilePostRequest(EDocument, SendContext);
        exit(CheckIfSuccessfulRequest(EDocument, SendContext.Http().GetHttpResponseMessage()));
    end;

    procedure HandleSendActionRequest(var EDocument: Record "E-Document"; SendContext: Codeunit SendContext; ActionName: Text): Boolean
    begin
        ForNAVAPIRequests.SendActionPostRequest(EDocument, ActionName, SendContext);
        exit(CheckIfSuccessfulRequest(EDocument, SendContext.Http().GetHttpResponseMessage()));
    end;

    procedure GetReceivedDocuments(ReceiveContext: Codeunit ReceiveContext; DocumentsMetadata: Codeunit "Temp Blob List"): Boolean
    var
        EnvironmentInformation: Codeunit "Environment Information";
    begin
        if not EnvironmentInformation.IsSaaSInfrastructure() then
            if not ForNAVAPIRequests.SendDocumentsGetRequest() then
                exit(false);

        exit(ForNAVAPIRequests.GetReceivedDocumentsRequest(ReceiveContext, DocumentsMetadata));
    end;

    procedure HandleGetTargetDocumentRequest(DocumentId: Text; ReceiveContext: Codeunit ReceiveContext): Boolean
    begin
        ForNAVAPIRequests.GetTargetDocumentRequest(DocumentId, ReceiveContext);
        if ReceiveContext.Http().GetHttpResponseMessage().IsSuccessStatusCode then
            exit(true);
    end;

    procedure HandleSendFetchDocumentRequest(DocumentId: JsonArray; SendContext: Codeunit SendContext): Boolean
    begin
        ForNAVAPIRequests.SendFetchDocumentRequest(DocumentId, SendContext);
        if SendContext.Http().GetHttpResponseMessage().IsSuccessStatusCode then
            exit(true);
    end;

    local procedure CheckIfSuccessfulRequest(EDocument: Record "E-Document"; HttpResponse: HttpResponseMessage): Boolean
    var
        EDocumentErrorHelper: Codeunit "E-Document Error Helper";
    begin
        if HttpResponse.IsSuccessStatusCode then
            exit(true);

        if HttpResponse.IsBlockedByEnvironment then
            EDocumentErrorHelper.LogSimpleErrorMessage(EDocument, EnvironmentBlocksErr)
        else
            EDocumentErrorHelper.LogSimpleErrorMessage(EDocument, StrSubstNo(UnsuccessfulResponseErr, HttpResponse.HttpStatusCode, HttpResponse.ReasonPhrase));
    end;

    var
        ForNAVAPIRequests: Codeunit "ForNAV API Requests";
        UnsuccessfulResponseErr: Label 'There was an error sending the request. Response code: %1 and error message: %2', Comment = '%1 - http response status code, e.g. 400, %2- error message';
        EnvironmentBlocksErr: Label 'The request to send documents has been blocked. To resolve the problem, enable outgoing HTTP requests for the E-Document apps on the Extension Management page.';
}