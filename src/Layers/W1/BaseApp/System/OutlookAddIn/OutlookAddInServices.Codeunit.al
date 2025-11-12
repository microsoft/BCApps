// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Integration;

using Microsoft.CRM.Outlook;

/// <summary>
/// The codeunit to provide internal services for Outlook Add-In code inside BaseApp.
/// </summary>
/// <remarks>
/// Code inspired from EmailOutlookAPIClient codeunit from 'Email - Outlook REST API' app.
/// </remarks>
codeunit 6999 "Outlook Add-In Services"
{
    Access = Internal;

    trigger OnRun()
    begin
    end;

    var
        OutlookCategoryLbl: Label 'AL Outlook Add-In', Locked = true;
        // Please note UrlHelper cannot be used here as it does not provide right URL on-prem
        RetrieveEmailMeUriTxt: Label 'https://graph.microsoft.com/v1.0/me/messages/%1', Locked = true;
        RetrieveEmailAttachmentsUriTxt: Label 'https://graph.microsoft.com/v1.0/me/messages/%1/attachments', Locked = true;
        FailedToRetrieveEmailBodyErr: Label 'Failed to retrieve message body.';
        FailedToRetrieveEmailAttachmentsErr: Label 'Failed to retrieve email attachments.';
        FailedToReadResponseContentErr: Label 'Failed to read the response content.';
        ConnectionErr: Label 'Could not establish the connection to the remote service for reading email. Try again later.';
        TelemetryRetrievingMyEmailTxt: Label 'Retrieving my email.', Locked = true;
        TelemetryRetrievingMyEmailAttachmentsTxt: Label 'Retrieving email attachments.', Locked = true;

    /// <summary>
    /// Enables getting email and attachments for Outlook Add-In.
    /// </summary>
    /// <param name="ItemID">REST ID of email</param>
    /// <param name="TempExchangeObject">Temporary record for the email and attachments</param>
    /// <param name="Action">Action to be initiated for attachments</param>
    /// <param name="RecRef">Record reference for the record to which email/attachments</param>
    /// <param name="AccessToken">Access token for Graph API (callback token from platform)</param>
    [Scope('OnPrem')]
    procedure GetEmailAndAttachments(ItemID: Text[250]; var TempExchangeObject: Record "Exchange Object" temporary; "Action": Option InitiateSendToOCR,InitiateSendToIncomingDocuments,InitiateSendToWorkFlow,IntiateSendToAttachments; RecRef: RecordRef; AccessToken: SecretText)
    var
        StreamEmailContentText: InStream;
        StreamAttachmentContentText: InStream;
        AttachmentsArray: JsonArray;
        AttachmentObject: JsonObject;
        MessageJson: JsonObject;
        AttachmentJson: JsonObject;
        BodyJson: JsonObject;
        Jtoken: JsonToken;
        hasAttachmentsToken: JsonToken;
        CurrentAttachment: JsonToken;
        SubjectToken: JsonToken;
        WebLinkToken: JsonToken;
        BodyContextText: Text;
        AttachmentContextText: Text;
    begin
        MessageJson := GetMessage(ItemID, AccessToken);
        MessageJson.Get('subject', SubjectToken);
        MessageJson.Get('webLink', WebLinkToken);
        MessageJson.Get('hasAttachments', hasAttachmentsToken);
        MessageJson.Get('body', JToken);
        BodyJson := JToken.AsObject();
        BodyJson.Get('content', JToken);
        BodyContextText := JToken.AsValue().AsText();
        StreamEmailContentText.ReadText(BodyContextText);

        TempExchangeObject.Init();
        TempExchangeObject.Validate("Item ID", ItemID);
        TempExchangeObject.Validate(Type, TempExchangeObject.Type::Email);
        TempExchangeObject.Validate(Name, SubjectToken.AsValue().AsText());
        TempExchangeObject.Validate(Owner, UserSecurityId());
        TempExchangeObject.SetBody(BodyContextText);
        TempExchangeObject.SetContent(StreamEmailContentText);
        TempExchangeObject.SetViewLink(WebLinkToken.AsValue().AsText());
        if not TempExchangeObject.Insert(true) then
            TempExchangeObject.Modify(true);

        if not hasAttachmentsToken.AsValue().AsBoolean() then
            exit;

        AttachmentJson := GetAttachments(ItemID, AccessToken);
        AttachmentJson.Get('value', Jtoken);
        AttachmentsArray := Jtoken.AsArray();
        foreach CurrentAttachment in AttachmentsArray do begin
            AttachmentObject := CurrentAttachment.AsObject();

            TempExchangeObject.Init();
            TempExchangeObject.Validate(Type, TempExchangeObject.Type::Attachment);
            TempExchangeObject.Validate("Parent ID", ItemID);
            TempExchangeObject.Validate(InitiatedAction, Action);
            TempExchangeObject.Validate(RecId, RecRef.RecordId());

            AttachmentObject.Get('id', Jtoken);
            TempExchangeObject.Validate("Item ID", Jtoken.AsValue().AsText());

            AttachmentObject.Get('name', Jtoken);
            TempExchangeObject.Validate(Name, Jtoken.AsValue().AsText());

            AttachmentObject.Get('contentType', Jtoken);
            TempExchangeObject.Validate("Content Type", Jtoken.AsValue().AsText());

            AttachmentObject.Get('isInline', Jtoken);
            TempExchangeObject.Validate(IsInline, Jtoken.AsValue().AsBoolean());

            AttachmentObject.Get('contentBytes', Jtoken);
            AttachmentContextText := Jtoken.AsValue().AsText();
            StreamAttachmentContentText.ReadText(AttachmentContextText);
            TempExchangeObject.SetContent(StreamAttachmentContentText);
            if not TempExchangeObject.Insert(true) then
                TempExchangeObject.Modify(true);
        end;
    end;

    /// <summary>
    /// Enables getting email body via Microsoft Graph for Outlook Add-In.
    /// </summary>
    /// <param name="ExternalMessageId">REST ID of email</param>
    /// <param name="AccessToken">Access token for Graph API (callback token from platform)</param>
    [Scope('OnPrem')]
    procedure GetEmailBodyViaGraph(ExternalMessageId: Text; AccessToken: SecretText): Text
    var
        ResponseJson: JsonObject;
        BodyJson: JsonObject;
        JToken: JsonToken;
    begin
        ResponseJson := GetMessage(ExternalMessageId, AccessToken);
        ResponseJson.Get('body', JToken);
        BodyJson := JToken.AsObject();
        BodyJson.Get('content', JToken);
        exit(JToken.AsValue().AsText());
    end;

    /// <summary>
    /// Checks if email has attachments via Microsoft Graph for Outlook Add-In.
    /// </summary>
    /// <param name="ExternalMessageId">REST ID of email</param>
    /// <param name="AccessToken">Access token for Graph API (callback token from platform)</param>
    [Scope('OnPrem')]
    procedure EmailHasAttachments(ExternalMessageId: Text[250]; AccessToken: SecretText): Boolean
    var
        ResponseJson: JsonObject;
        JToken: JsonToken;
    begin
        ResponseJson := GetMessage(ExternalMessageId, AccessToken);
        ResponseJson.Get('hasAttachments', JToken);
        exit(JToken.AsValue().AsBoolean());
    end;

    [NonDebuggable]
    local procedure CreateRequest(Method: Text; RequestUri: Text; AccessToken: SecretText; var MailHttpRequestMessage: HttpRequestMessage)
    var
        MailRequestHeaders: HttpHeaders;
    begin
        MailHttpRequestMessage.Method(Method);
        MailHttpRequestMessage.SetRequestUri(RequestUri);
        MailHttpRequestMessage.GetHeaders(MailRequestHeaders);
        MailRequestHeaders.Add('Authorization', SecretStrSubstNo('Bearer %1', AccessToken));
    end;

    [NonDebuggable]
    local procedure SendRequest(var MailHttpRequestMessage: HttpRequestMessage; var MailHttpResponseMessage: HttpResponseMessage)
    var
        MailHttpClient: HttpClient;
    begin
        if not MailHttpClient.Send(MailHttpRequestMessage, MailHttpResponseMessage) then
            Error(ConnectionErr);
    end;

    /// <summary>
    /// Enables getting full information about the email via Microsoft Graph for Outlook Add-In.
    /// </summary>
    /// <remarks>
    /// Based on this call https://learn.microsoft.com/en-us/graph/api/message-get.
    /// </remarks>
    /// <param name="ExternalMessageId">REST ID of email</param>
    /// <param name="AccessToken">Access token for Graph API (callback token from platform)</param>
    local procedure GetMessage(ExternalMessageId: Text; AccessToken: SecretText): JsonObject
    var
        MailHttpRequestMessage: HttpRequestMessage;
        MailHttpResponseMessage: HttpResponseMessage;
        MailRequestHeaders: HttpHeaders;
        ResponseJson: JsonObject;
        ResponseJsonText: Text;
        RequestUri: Text;
    begin
        Session.LogMessage('0000QGW', TelemetryRetrievingMyEmailTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', OutlookCategoryLbl);
        RequestUri := StrSubstNo(RetrieveEmailMeUriTxt, ExternalMessageId);
        CreateRequest('GET', RequestUri, AccessToken, MailHttpRequestMessage);
        MailHttpRequestMessage.GetHeaders(MailRequestHeaders);
        MailRequestHeaders.Add('Prefer', 'outlook.body-content-type="text"');
        SendRequest(MailHttpRequestMessage, MailHttpResponseMessage);
        if MailHttpResponseMessage.HttpStatusCode <> 200 then
            Session.LogMessage('0000QGX', FailedToRetrieveEmailBodyErr, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', OutlookCategoryLbl);
        if not MailHttpResponseMessage.Content.ReadAs(ResponseJsonText) then
            Error(FailedToReadResponseContentErr);
        if not ResponseJson.ReadFrom(ResponseJsonText) then
            Error(FailedToReadResponseContentErr);
        exit(ResponseJson);
    end;

    /// <summary>
    /// Enables getting full information about the email attachments via Microsoft Graph for Outlook Add-In.
    /// </summary>
    /// <remarks>
    /// Based on this call https://learn.microsoft.com/en-us/graph/api/message-list-attachments.
    /// </remarks>
    /// <param name="ExternalMessageId">REST ID of email</param>
    /// <param name="AccessToken">Access token for Graph API (callback token from platform)</param>
    local procedure GetAttachments(ExternalMessageId: Text; AccessToken: SecretText): JsonObject
    var
        MailHttpRequestMessage: HttpRequestMessage;
        MailHttpResponseMessage: HttpResponseMessage;
        MailRequestHeaders: HttpHeaders;
        ResponseJson: JsonObject;
        ResponseJsonText: Text;
        RequestUri: Text;
    begin
        Session.LogMessage('0000QGY', TelemetryRetrievingMyEmailAttachmentsTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', OutlookCategoryLbl);
        RequestUri := StrSubstNo(RetrieveEmailAttachmentsUriTxt, ExternalMessageId);
        CreateRequest('GET', RequestUri, AccessToken, MailHttpRequestMessage);
        MailHttpRequestMessage.GetHeaders(MailRequestHeaders);
        MailRequestHeaders.Add('Prefer', 'outlook.body-content-type="text"');
        SendRequest(MailHttpRequestMessage, MailHttpResponseMessage);
        if MailHttpResponseMessage.HttpStatusCode <> 200 then
            Session.LogMessage('0000QGZ', FailedToRetrieveEmailAttachmentsErr, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', OutlookCategoryLbl);
        if not MailHttpResponseMessage.Content.ReadAs(ResponseJsonText) then
            Error(FailedToReadResponseContentErr);
        if not ResponseJson.ReadFrom(ResponseJsonText) then
            Error(FailedToReadResponseContentErr);
        exit(ResponseJson);
    end;
}
