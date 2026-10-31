// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocumentConnector.Microsoft365;

using System.Environment;
using System.Integration;
using System.Utilities;

#pragma warning disable AS0130
#pragma warning disable PTE0025
codeunit 6384 "Graph Client"
#pragma warning restore AS0130
#pragma warning restore PTE0025
{
    Access = Internal;

    internal procedure InitializeWebRequest(Url: Text; Method: Text; ReturnType: Text; var HttpRequestMessage: HttpRequestMessage; var ClientRequestId: Text)
    var
        GraphAuthentication: Codeunit "Graph Authentication";
        HttpHeaders: HttpHeaders;
        Token: SecretText;
    begin
        if not EnvironmentInformation.IsSaaSInfrastructure() then
            Error(AvailableOnlyOnSaaSErr);

        GraphAuthentication.GetAccessToken(Token);

        if Token.IsEmpty() then begin
            Session.LogMessage('0000OB4', EmptyTokenTelemetryMsg, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryLbl);
            Error(SignInAgainErr);
        end;

        // Graph and SharePoint record client-request-id in their logs, which lets ODSP correlate a failing call (including redirects) with our telemetry.
        ClientRequestId := Format(CreateGuid(), 0, 4).ToLower();

        HttpRequestMessage.Method(Method);
        HttpRequestMessage.SetRequestUri(Url);
        HttpRequestMessage.GetHeaders(HttpHeaders);
        if ReturnType <> '' then
            HttpHeaders.Add('Accept', ReturnType);
        HttpHeaders.Add('client-request-id', ClientRequestId);
        HttpHeaders.Add('return-client-request-id', 'true');
        HttpHeaders.Add('Authorization', SecretStrSubstNo('Bearer %1', Token));
    end;

    [TryFunction]
    [NonDebuggable]
    procedure GetDriveFolderInfo(FolderUrl: Text; var FolderJson: JsonObject)
    var
        HttpClient: HttpClient;
        HttpRequestMessage: HttpRequestMessage;
        HttpResponseMessage: HttpResponseMessage;
        ResponseBody: Text;
        ErrorDetails: Text;
        ClientRequestId: Text;
    begin
        InitializeWebRequest(FolderUrl, 'GET', 'application/json', HttpRequestMessage, ClientRequestId);

        if not HttpClient.Send(HttpRequestMessage, HttpResponseMessage) then begin
            Session.LogMessage('0000VST', GraphSendFailedTelemetryMsg, Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, GetTelemetryDimensions(ClientRequestId));
            Error(RequestFailedErr, GetLastErrorText());
        end;

        HttpResponseMessage.Content.ReadAs(ResponseBody);
        if not HttpResponseMessage.IsSuccessStatusCode() then begin
            ErrorDetails := ResponseBody;
            Session.LogMessage('0000OB5', StrSubstNo(GraphStatusCodeTelemetryMsg, HttpResponseMessage.HttpStatusCode()), Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, GetTelemetryDimensions(ClientRequestId, HttpResponseMessage));

            CheckNoAccessError(HttpResponseMessage.HttpStatusCode(), ErrorDetails);
            Error(UnexpectedStatusCodeErr, HttpResponseMessage.HttpStatusCode());
        end;

        if not FolderJson.ReadFrom(ResponseBody) then
            Error(InvalidJsonErr, ResponseBody);
    end;

    [TryFunction]
    [NonDebuggable]
    procedure GetFileContent(DriveId: Text; var TempDocumentSharing: Record "Document Sharing" temporary)
    var
        TempBlob: Codeunit "Temp Blob";
        HttpClient: HttpClient;
        HttpRequestMessage: HttpRequestMessage;
        HttpResponseMessage: HttpResponseMessage;
        HttpHeaders: HttpHeaders;
        FileUrl: Text;
        ErrorDetails: Text;
        ClientRequestId: Text;
        InStream: InStream;
        OutStream: OutStream;
        TelemetryDimensions: Dictionary of [Text, Text];
    begin
        FileUrl := GetGraphItemByIdUrl(DriveId, TempDocumentSharing."Item Id") + '/content';

        InitializeWebRequest(FileUrl, 'GET', '', HttpRequestMessage, ClientRequestId);
        // Return the content directly instead of redirecting to a pre-authenticated (tempauth) SharePoint URL; tempauth URLs are being retired.
        HttpRequestMessage.GetHeaders(HttpHeaders);
        HttpHeaders.Add('Prefer', 'noredirect');

        if not HttpClient.Send(HttpRequestMessage, HttpResponseMessage) then begin
            Session.LogMessage('0000VSU', GraphSendFailedTelemetryMsg, Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, GetTelemetryDimensions(ClientRequestId));
            Error(RequestFailedErr, GetLastErrorText());
        end;

        if not HttpResponseMessage.IsSuccessStatusCode() then begin
            HttpResponseMessage.Content.ReadAs(ErrorDetails);
            Session.LogMessage('0000OB6', StrSubstNo(GraphStatusCodeTelemetryMsg, HttpResponseMessage.HttpStatusCode()), Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, GetTelemetryDimensions(ClientRequestId, HttpResponseMessage));

            CheckNoAccessError(HttpResponseMessage.HttpStatusCode(), ErrorDetails);
            Error(UnexpectedStatusCodeErr, HttpResponseMessage.HttpStatusCode());
        end;

        HttpResponseMessage.Content.ReadAs(InStream);
        TempBlob.CreateOutStream(OutStream);
        CopyStream(OutStream, InStream);
        TelemetryDimensions := GetTelemetryDimensions(ClientRequestId, HttpResponseMessage);
        if TempBlob.Length() = 0 then
            Session.LogMessage('0000OB7', GraphEmptyFileTelemetryMsg, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, TelemetryDimensions)
        else begin
            Session.LogMessage('0000OB8', StrSubstNo(GraphFileTelemetryMsg, TempBlob.Length()), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, TelemetryDimensions);
            TempDocumentSharing.Data.CreateOutStream(OutStream);
            TempBlob.CreateInStream(InStream);
            CopyStream(OutStream, InStream);
        end;
    end;

    [TryFunction]
    [NonDebuggable]
    procedure MoveDriveItem(DriveId: Text; ItemId: Text; NewFolderId: Text)
    var
        HttpClient: HttpClient;
        HttpRequestMessage: HttpRequestMessage;
        HttpResponseMessage: HttpResponseMessage;
        HttpContent: HttpContent;
        HttpContentHeaders: HttpHeaders;
        ResponseBody: Text;
        ItemUrl: Text;
        BodyTxt: Text;
        ClientRequestId: Text;
    begin
        ItemUrl := GetGraphItemByIdUrl(DriveId, ItemId);
        BodyTxt := '{ "parentReference": { "id": "' + NewFolderId + '" } }';
        InitializeWebRequest(ItemUrl, 'PATCH', '', HttpRequestMessage, ClientRequestId);
        HttpContent.WriteFrom(BodyTxt);
        HttpContent.GetHeaders(HttpContentHeaders);
        HttpContentHeaders.Remove('Content-Type');
        HttpContentHeaders.Add('Content-Type', 'application/json');
        HttpRequestMessage.Content(HttpContent);
        if not HttpClient.Send(HttpRequestMessage, HttpResponseMessage) then begin
            Session.LogMessage('0000VSV', GraphSendFailedTelemetryMsg, Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, GetTelemetryDimensions(ClientRequestId));
            Error(RequestFailedErr, GetLastErrorText());
        end;

        HttpResponseMessage.Content.ReadAs(ResponseBody);
        if not HttpResponseMessage.IsSuccessStatusCode() then begin
            Session.LogMessage('0000N7U', StrSubstNo(GraphStatusCodeTelemetryMsg, HttpResponseMessage.HttpStatusCode()), Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, GetTelemetryDimensions(ClientRequestId, HttpResponseMessage));

            CheckNoAccessError(HttpResponseMessage.HttpStatusCode(), ResponseBody);
            Error(UnexpectedStatusCodeErr, HttpResponseMessage.HttpStatusCode());
        end;
    end;

    local procedure GetGraphItemByIdUrl(DriveId: Text; ItemId: Text): Text
    begin
        exit(StrSubstNo(GraphItemUrlTxt, DriveId, ItemId));
    end;

    local procedure GetTelemetryDimensions(ClientRequestId: Text): Dictionary of [Text, Text]
    var
        TelemetryDimensions: Dictionary of [Text, Text];
    begin
        TelemetryDimensions.Add('Category', CategoryLbl);
        TelemetryDimensions.Add('ClientRequestId', ClientRequestId);
        exit(TelemetryDimensions);
    end;

    local procedure GetTelemetryDimensions(ClientRequestId: Text; var HttpResponseMessage: HttpResponseMessage): Dictionary of [Text, Text]
    var
        TelemetryDimensions: Dictionary of [Text, Text];
    begin
        TelemetryDimensions := GetTelemetryDimensions(ClientRequestId);
        TelemetryDimensions.Add('HttpStatusCode', Format(HttpResponseMessage.HttpStatusCode()));
        TelemetryDimensions.Add('RequestId', GetResponseHeaderValue(HttpResponseMessage, 'request-id'));
        TelemetryDimensions.Add('SPRequestGuid', GetResponseHeaderValue(HttpResponseMessage, 'SPRequestGuid'));
        exit(TelemetryDimensions);
    end;

    local procedure GetResponseHeaderValue(var HttpResponseMessage: HttpResponseMessage; HeaderName: Text): Text
    var
        Values: array[10] of Text;
    begin
        if HttpResponseMessage.Headers().GetValues(HeaderName, Values) then
            exit(Values[1]);
    end;

    local procedure CheckNoAccessError(HttpStatusCode: Integer; HttpErrorDetails: Text)
    var
        ErrorTxt: Text;
    begin
        if HttpStatusCode in [401, 403, 404] then begin
            ErrorTxt := DocumentFolderNotAccessibleErr + '\\' + HttpErrorDetails;
            Error(ErrorTxt);
        end;
    end;

    var
        EnvironmentInformation: Codeunit "Environment Information";
        GraphItemUrlTxt: Label 'https://graph.microsoft.com/v1.0/drives/%1/items/%2', Locked = true;
        EmptyTokenTelemetryMsg: Label 'No Microsoft 365 access token received', Locked = true;
        AvailableOnlyOnSaaSErr: Label 'This functionality is available only when running on Business Central Online environment.';
        SignInAgainErr: Label 'No access token is available. You must sign in to the target resource with the correct credentials. If the problem persists, open a Business Central support request.';
        DocumentFolderNotAccessibleErr: Label 'Unable to access the folder specified on the setup page. Verify that the shared link points to an existing folder and that you have access to it.';
        GraphSendFailedTelemetryMsg: Label 'The HTTP request to Microsoft 365 failed to send.', Locked = true;
        GraphStatusCodeTelemetryMsg: Label 'Microsoft 365 returned an error code: %1.', Locked = true;
        RequestFailedErr: Label 'The request to the remote service failed. Details: %1.', Comment = '%1 = The error text from the failed HTTP request';
        UnexpectedStatusCodeErr: Label 'Remote service returned an unexpected error code: %1.', Comment = '%1 = An error code from OneDrive or Sharepoint, for example 503';
        InvalidJsonErr: Label 'Remote service returned an invalid response. Details: %1.', Comment = '%1 = The response details from OneDrive or Sharepoint (e.g. "Your Drive is not available")';
        CategoryLbl: Label 'EDoc Connector M365', Locked = true;
        GraphEmptyFileTelemetryMsg: Label 'Microsoft 365 returned an empty file.', Locked = true;
        GraphFileTelemetryMsg: Label 'Microsoft 365 file size: %1', Locked = true;

}