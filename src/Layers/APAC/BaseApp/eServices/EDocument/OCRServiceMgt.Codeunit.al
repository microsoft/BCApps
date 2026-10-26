#pragma warning disable AA0217, AA0139 // Legacy implementation restored with its original analyzer debt.
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

using Microsoft.CRM.Outlook;
using Microsoft.Purchases.Vendor;
using Microsoft.Utilities;
using System;
using System.Integration;
using System.IO;
using System.Telemetry;
using System.Utilities;

codeunit 1294 "OCR Service Mgt."
{

    trigger OnRun()
    begin
    end;

    var
        MissingCredentialsQst: Label '%1\ Do you want to open %2 to specify the missing values?', Comment = '%1=error message. %2=OCR Service Setup';
        MissingCredentialsErr: Label 'You must fill the User Name, Password, and Authorization Key fields.', Comment = '%1 = OCR Service Setup';
        OCRServiceSetup: Record "OCR Service Setup";
        AuthCookie: DotNet Cookie;
        ConnectionSuccessMsg: Label 'Connection succeeded.';
        ConnectionFailedErr: Label 'The connection failed. Check that the User Name, Password, and Authorization Key fields are filled correctly.';
        NoFileContentErr: Label 'The file is empty.';
        InitiateUploadMsg: Label 'Initiate document upload.';
        GetDocumentConfirmMsg: Label 'Acknowledge document receipt.';
        DocumentDownloadedTxt: Label 'The document was downloaded. Document ID: %1, Track ID: %2', Comment = '%1 = Document Identifier (usually a guid), %2 = Track ID';
        UploadFileMsg: Label 'Send to OCR service.';
        AuthenticateMsg: Label 'Log in to OCR service.';
        GetNewDocumentsMsg: Label 'Get received OCR documents.';
        GetDocumentMsg: Label 'Receive OCR document.';
        UploadFileFailedMsg: Label 'The document failed to upload. Service Error: %1', Comment = '%1 = Response from OCR service, this will probably be an XML string';
        UploadFileFailedTelemetryMsg: Label 'The document failed to upload. Service Error: %1', Locked = true;
        UploadFileFailedWithNoResponseMsg: Label 'The document failed to upload. The OCR service returned no response.', Locked = true;
        UploadTotalSuccessMsg: Label 'Notify OCR service that %1 documents are ready for upload.', Comment = '%1 = Number of documents to be uploaded';
        NewDocumentsTotalMsg: Label 'Downloaded %1 of %2 documents.', Comment = '%1 = Number of documents downloaded (e.g. 5), %2 = Number of documents processed';
        DocumentNotDownloadedTxt: Label 'Could not download the document from the OCR service. Document ID: %1, Track ID: %2', Comment = '%1 = Document ID, %2 = Track ID';
        DownloadNotRegisteredTxt: Label 'Could not register that the document was downloaded from the OCR service. Document ID: %1, Track ID: %2', Comment = '%1 = Document ID, %2 = Track ID';
        ImportSuccessMsg: Label 'The document was successfully received.';
        DocumentNotReadyMsg: Label 'The document cannot be received yet. Try again in a few moments.';
        NotUploadedErr: Label 'You must upload the image first.';
        NotValidDocIDErr: Label 'Received document ID %1 contains invalid characters.', Comment = '%1 is the value.';
        LoggingConstTxt: Label 'OCR Service';
        UploadSuccessMsg: Label 'The document was successfully sent to the OCR service.';
        NoOCRDataCorrectionMsg: Label 'You have made no OCR data corrections.';
        VerifyMsg: Label 'The document is awaiting your manual verification on the OCR service site.\\Choose the Awaiting Verification link in the OCR Status field.';
        FailedMsg: Label 'The document failed to be processed.';
        MethodGetTok: Label 'GET', Locked = true;
        MethodPutTok: Label 'PUT', Locked = true;
        MethodPostTok: Label 'POST', Locked = true;
        MethodDeleteTok: Label 'DELETE', Locked = true;
        OCRServiceUserSuccessfullyUploadedDocumentTxt: Label 'A document was successfully uploaded to OCR service.', Locked = true;
        OCRServiceUserFailedToUploadDocumentTxt: Label 'A document upload to OCR Service failed.', Locked = true;
        OCRServiceUserSuccessfullyUploadedLearningDocumentTxt: Label 'A learning document was successfully uploaded to OCR service.', Locked = true;
        OCRServiceUserFailedToUploadLearningDocumentTxt: Label 'A learning document upload to OCR Service failed.', Locked = true;
        OCRServiceUserSuccessfullyDownloadedDocumentTxt: Label 'A document was successfully downloaded from OCR service.', Locked = true;
        OCRServiceUserFailedToDownloadDocumentTxt: Label 'A document download from OCR service failed.', Locked = true;
        OCRServiceUserCreatedGenJnlLineOutOfOCRedDocumentTxt: Label 'A general journal line was successfully created out of an OCRed incoming document.', Locked = true;
        OCRServiceUserCreatedInvoiceOutOfOCRedDocumentTxt: Label 'An invoice was successfully created out of an OCRed incoming document.', Locked = true;
        ConnectionFailedTxt: Label 'Connection to OCR service failed.', Locked = true;
        ConnectionSucceedTxt: Label 'Successfully connected to OCR service.', Locked = true;
        GettingCurrentCustomerFailedTxt: Label 'Getting current customer from OCR service failed.', Locked = true;
        GettingCurrentUserFailedTxt: Label 'Getting current user from OCR service failed.', Locked = true;
        GettingUserConfigurationFailedTxt: Label 'Getting user configuration from OCR service failed.', Locked = true;
        InitializingUploadFailedTxt: Label 'Initializing upload to OCR service failed.', Locked = true;
        NoFileContentTxt: Label 'The file is empty.', Locked = true;
        GettingDocumentsForUserFailedTxt: Label 'Getting documents for the user from OCR service failed.', Locked = true;
        GettingDocumentsForCustomerFailedTxt: Label 'Getting documents for the customer from OCR service failed.', Locked = true;
        GettingBatchDocumentsFailedTxt: Label 'Getting batch documents from OCR service failed.', Locked = true;
        GettingBatchesFailedTxt: Label 'Getting batches from OCR service failed.', Locked = true;
        RegisteringDownloadFailedTxt: Label 'Registering download to OCR service failed.', Locked = true;
        RegisteringDownloadSucceedTxt: Label 'Registering download to OCR service succeed.', Locked = true;
        InsertingIncomingDocumentTxt: Label 'Inserting incoming document.', Locked = true;
        UpdatingIncomingDocumentTxt: Label 'Updating incoming document.', Locked = true;
        InvalidDocumentIdTxt: Label 'Invalid document ID was received from OCR service.', Locked = true;
        DocumentsDownloadedTxt: Label '%1 of %2 documents were successfully downloaded from OCR service.', Locked = true;
        DocumentNotUploadedTxt: Label 'The document is not uploaded.', Locked = true;
        CannotFindAttachmentTxt: Label 'Cannot find attachment.', Locked = true;
        UploadFileSucceedTxt: Label 'A document was successfully uploaded to OCR service.', Locked = true;
        FailedRequestResultTxt: Label 'Request to OCR service failed. Status code: %1. Message: %2. Details: %3.', Locked = true;
        FailedRequestBodyTxt: Label 'Request to OCR service failed. Method: %1. URL: %2. Body: %3', Locked = true;
        TelemetryCategoryTok: Label 'AL OCR Service', Locked = true;

    procedure SetURLsToDefaultRSO(var OCRServiceSetup: Record "OCR Service Setup")
    begin
        OCRServiceSetup."Sign-up URL" := 'https://store.readsoftonline.com/nav';
        OCRServiceSetup."Service URL" := 'https://services.readsoftonline.com';
        OCRServiceSetup."Sign-in URL" := 'https://nav.readsoftonline.com';
    end;

    procedure CheckCredentials()
    var
        OCRServiceSetup: Record "OCR Service Setup";
    begin
        if not HasCredentials(OCRServiceSetup) then
            if Confirm(StrSubstNo(GetCredentialsQstText()), true) then begin
                Commit();
                PAGE.RunModal(PAGE::"OCR Service Setup", OCRServiceSetup);
            end;

        if not HasCredentials(OCRServiceSetup) then
            Error(GetCredentialsErrText());
    end;

    local procedure HasCredentials(OCRServiceSetup: Record "OCR Service Setup"): Boolean
    begin
        exit(
              OCRServiceSetup.Get() and
              OCRServiceSetup.HasPassword(OCRServiceSetup."Password Key") and
              OCRServiceSetup.HasPassword(OCRServiceSetup."Authorization Key") and
              (OCRServiceSetup."User Name" <> ''));
    end;

    procedure GetCredentialsErrText(): Text
    begin
        exit(MissingCredentialsErr);
    end;

    procedure GetCredentialsQstText(): Text
    var
        OCRServiceSetup: Record "OCR Service Setup";
    begin
        exit(StrSubstNo(MissingCredentialsQst, GetCredentialsErrText(), OCRServiceSetup.TableCaption()));
    end;

    [Scope('OnPrem')]
    procedure Authenticate(): Boolean
    var
        AuthenticationSucceeded: Boolean;
    begin
        if not TryAuthenticate(AuthenticationSucceeded) then begin
            Session.LogMessage('00008K8', ConnectionFailedTxt, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryTok);
            exit(false);
        end;

        if not AuthenticationSucceeded then begin
            Session.LogMessage('00008K9', ConnectionFailedTxt, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryTok);
            LogActivityFailed(OCRServiceSetup.RecordId, AuthenticateMsg, ConnectionFailedErr); // throws error
        end;

        Session.LogMessage('00008KA', ConnectionSucceedTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryTok);

        LogActivitySucceeded(OCRServiceSetup.RecordId, AuthenticateMsg, '');
        exit(true);
    end;

    [TryFunction]
    [NonDebuggable]
    local procedure TryAuthenticate(var AuthenticationSucceeded: Boolean)
    var
        TempBlob: Codeunit "Temp Blob";
        HttpWebRequestMgt: Codeunit "Http Web Request Mgt.";
        HttpStatusCode: DotNet HttpStatusCode;
        ResponseHeaders: DotNet NameValueCollection;
        InStr: InStream;
        ResponseString: Text;
        ResponseReceived: Boolean;
    begin
        GetOcrServiceSetup(false);
        HttpWebRequestMgt.Initialize(StrSubstNo('%1/authentication/rest/authenticate', OCRServiceSetup."Service URL"));
        HttpWebRequestMgt.DisableUI();
        RsoAddHeaders(HttpWebRequestMgt);
        HttpWebRequestMgt.SetMethod(MethodPostTok);
        HttpWebRequestMgt.AddBodyAsText(
          StrSubstNo(
            '<AuthenticationCredentials><UserName>%1</UserName><Password>%2</Password>' +
            '<AuthenticationType>SetCookie</AuthenticationType></AuthenticationCredentials>',
            OCRServiceSetup."User Name", OCRServiceSetup.GetPasswordAsSecretText(OCRServiceSetup."Password Key").Unwrap()));
        TempBlob.CreateInStream(InStr);
        ResponseReceived := HttpWebRequestMgt.GetResponse(InStr, HttpStatusCode, ResponseHeaders);

        if ResponseReceived then begin
            InStr.ReadText(ResponseString);
            AuthenticationSucceeded := StrPos(ResponseString, '<Status>Success</Status>') >= 1;
        end else
            Error(GetLastErrorText);

        if AuthenticationSucceeded then
            HttpWebRequestMgt.GetCookie(AuthCookie);
    end;

    [Scope('OnPrem')]
    procedure UpdateOrganizationInfo(var OCRServiceSetup: Record "OCR Service Setup")
    var
        XmlRootNode: XmlNode;
        FoundXmlNode: XmlNode;
        ResponseStr: InStream;
    begin
        if not RsoGetRequest('accounts/rest/currentcustomer', ResponseStr) then begin
            Session.LogMessage('00008KB', GettingCurrentCustomerFailedTxt, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryTok);
            Error(GetLastErrorText);
        end;
        // Called without using the return value so that a parse error is raised, as before.
        TryLoadXmlRootNode(ResponseStr, XmlRootNode);
        if XmlRootNode.SelectSingleNode('Id', FoundXmlNode) then
            OCRServiceSetup."Customer ID" := CopyStr(GetNodeInnerText(FoundXmlNode), 1, MaxStrLen(OCRServiceSetup."Customer ID"));
        if XmlRootNode.SelectSingleNode('Name', FoundXmlNode) then
            OCRServiceSetup."Customer Name" := CopyStr(GetNodeInnerText(FoundXmlNode), 1, MaxStrLen(OCRServiceSetup."Customer Name"));
        if XmlRootNode.SelectSingleNode('ActivationStatus', FoundXmlNode) then
            OCRServiceSetup."Customer Status" := CopyStr(GetNodeInnerText(FoundXmlNode), 1, MaxStrLen(OCRServiceSetup."Customer Status"));
        if not RsoGetRequest('users/rest/currentuser', ResponseStr) then
            Session.LogMessage('00008KC', GettingCurrentUserFailedTxt, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryTok);
        // Called without using the return value so that a parse error is raised, as before.
        TryLoadXmlRootNode(ResponseStr, XmlRootNode);

        if XmlRootNode.SelectSingleNode('OrganizationId', FoundXmlNode) then
            OCRServiceSetup."Organization ID" := CopyStr(GetNodeInnerText(FoundXmlNode), 1, MaxStrLen(OCRServiceSetup."Organization ID"));
        OCRServiceSetup.Modify();
    end;

    [Scope('OnPrem')]
    procedure UpdateOcrDocumentTemplates()
    var
        OCRServiceDocumentTemplate: Record "OCR Service Document Template";
        XmlRootNode: XmlNode;
        DocumentTypeXmlNode: XmlNode;
        ChildXmlNode: XmlNode;
        DocumentTypeXmlNodeList: XmlNodeList;
        ResponseStr: InStream;
    begin
        GetOcrServiceSetup(false);
        OCRServiceSetup.TestField("Organization ID");

        if not RsoGetRequest(StrSubstNo('accounts/rest/customers/%1/userconfiguration', OCRServiceSetup."Organization ID"), ResponseStr) then
            Session.LogMessage('00008KD', GettingUserConfigurationFailedTxt, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryTok);
        TryLoadXmlRootNode(ResponseStr, XmlRootNode);

        OCRServiceDocumentTemplate.LockTable();
        OCRServiceDocumentTemplate.DeleteAll();
        XmlRootNode.SelectNodes('AvailableDocumentTypes/UserConfigurationDocumentType', DocumentTypeXmlNodeList);
        foreach DocumentTypeXmlNode in DocumentTypeXmlNodeList do begin
            OCRServiceDocumentTemplate.Init();
            DocumentTypeXmlNode.SelectSingleNode('SystemName', ChildXmlNode);
            OCRServiceDocumentTemplate.Code := CopyStr(GetNodeInnerText(ChildXmlNode), 1, MaxStrLen(OCRServiceDocumentTemplate.Code));
            DocumentTypeXmlNode.SelectSingleNode('Name', ChildXmlNode);
            OCRServiceDocumentTemplate.Name := CopyStr(GetNodeInnerText(ChildXmlNode), 1, MaxStrLen(OCRServiceDocumentTemplate.Name));
            OCRServiceDocumentTemplate.Insert();
        end;
    end;

    [Scope('OnPrem')]
    procedure RsoGetRequest(PathQuery: Text; var ResponseStr: InStream): Boolean
    begin
        exit(RsoRequest(PathQuery, MethodGetTok, '', ResponseStr));
    end;

    [TryFunction]
    [Scope('OnPrem')]
    procedure RsoGetRequestBinary(PathQuery: Text; var ResponseStr: InStream; var ContentType: Text)
    var
        HttpWebRequestMgt: Codeunit "Http Web Request Mgt.";
        HttpStatusCode: DotNet HttpStatusCode;
        ResponseHeaders: DotNet NameValueCollection;
    begin
        GetOcrServiceSetup(true);

        HttpWebRequestMgt.Initialize(StrSubstNo('%1/%2', OCRServiceSetup."Service URL", PathQuery));
        HttpWebRequestMgt.DisableUI();
        RsoAddCookie(HttpWebRequestMgt);
        RsoAddHeaders(HttpWebRequestMgt);
        HttpWebRequestMgt.SetMethod(MethodGetTok);
        HttpWebRequestMgt.CreateInstream(ResponseStr);
        HttpWebRequestMgt.GetResponse(ResponseStr, HttpStatusCode, ResponseHeaders);
        ContentType := ResponseHeaders.Item('Content-Type');
    end;

    [Scope('OnPrem')]
    procedure RsoPutRequest(PathQuery: Text; Data: Text; var ResponseStr: InStream): Boolean
    begin
        exit(RsoRequest(PathQuery, MethodPutTok, Data, ResponseStr));
    end;

    [Scope('OnPrem')]
    procedure RsoPostRequest(PathQuery: Text; Data: Text; var ResponseStr: InStream): Boolean
    begin
        exit(RsoRequest(PathQuery, MethodPostTok, Data, ResponseStr));
    end;

    [Scope('OnPrem')]
    procedure RsoDeleteRequest(PathQuery: Text; Data: Text; var ResponseStr: InStream): Boolean
    begin
        exit(RsoRequest(PathQuery, MethodDeleteTok, Data, ResponseStr));
    end;

    [Scope('OnPrem')]
    procedure RsoRequest(PathQuery: Text; RequestAction: Code[6]; BodyText: Text; var ResponseStr: InStream): Boolean
    var
        HttpWebRequestMgt: Codeunit "Http Web Request Mgt.";
        HttpStatusCode: DotNet HttpStatusCode;
        ResponseHeaders: DotNet NameValueCollection;
    begin
        GetOcrServiceSetup(true);

        HttpWebRequestMgt.Initialize(StrSubstNo('%1/%2', OCRServiceSetup."Service URL", PathQuery));
        HttpWebRequestMgt.DisableUI();
        RsoAddCookie(HttpWebRequestMgt);
        RsoAddHeaders(HttpWebRequestMgt);
        HttpWebRequestMgt.SetMethod(RequestAction);
        if BodyText <> '' then
            HttpWebRequestMgt.AddBodyAsText(BodyText);
        HttpWebRequestMgt.CreateInstream(ResponseStr);
        exit(HttpWebRequestMgt.GetResponse(ResponseStr, HttpStatusCode, ResponseHeaders));
    end;

    [Scope('OnPrem')]
    procedure RsoRequest(PathQuery: Text; RequestAction: Code[6]; RequestBody: Text; var ResponseBody: Text; var ErrorMessage: Text; var ErrorDetails: Text; var StatusCode: Integer): Boolean
    var
        HttpWebRequestMgt: Codeunit "Http Web Request Mgt.";
        ResponseHeaders: DotNet NameValueCollection;
        HttpStatusCode: DotNet HttpStatusCode;
        RequestUrl: Text;
        Result: Boolean;
    begin
        GetOcrServiceSetup(true);

        RequestUrl := StrSubstNo('%1/%2', OCRServiceSetup."Service URL", PathQuery);
        HttpWebRequestMgt.Initialize(RequestUrl);
        HttpWebRequestMgt.DisableUI();
        RsoAddCookie(HttpWebRequestMgt);
        RsoAddHeaders(HttpWebRequestMgt);
        HttpWebRequestMgt.SetMethod(RequestAction);
        if RequestBody <> '' then
            HttpWebRequestMgt.AddBodyAsText(RequestBody);

        Result := HttpWebRequestMgt.SendRequestAndReadTextResponse(ResponseBody, ErrorMessage, ErrorDetails, HttpStatusCode, ResponseHeaders);
        if not Result then begin
            StatusCode := HttpStatusCode;
            Session.LogMessage('0000BBJ', StrSubstNo(FailedRequestResultTxt, StatusCode, ErrorMessage, ErrorDetails), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryTok);
            Session.LogMessage('0000BBK', StrSubstNo(FailedRequestBodyTxt, RequestAction, RequestUrl, RequestBody), Verbosity::Warning, DataClassification::CustomerContent, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryTok);
        end;
        exit(Result);
    end;

    local procedure RsoAddHeaders(var HttpWebRequestMgt: Codeunit "Http Web Request Mgt.")
    begin
        HttpWebRequestMgt.AddHeader('x-rs-version', '2011-10-14');
        HttpWebRequestMgt.AddHeader('x-rs-key', OCRServiceSetup.GetPasswordAsSecretText(OCRServiceSetup."Authorization Key"));
        HttpWebRequestMgt.AddHeader('x-rs-culture', 'en-US');
        HttpWebRequestMgt.AddHeader('x-rs-uiculture', 'en-US');
    end;

    local procedure RsoAddCookie(var HttpWebRequestMgt: Codeunit "Http Web Request Mgt.")
    begin
        if IsNull(AuthCookie) then
            if not Authenticate() then
                Error(GetLastErrorText);
        if AuthCookie.Expired then
            if not Authenticate() then
                Error(GetLastErrorText);

        HttpWebRequestMgt.SetCookie(AuthCookie);
    end;

    local procedure GetNodeInnerText(Node: XmlNode): Text
    begin
        case true of
            Node.IsXmlElement():
                exit(Node.AsXmlElement().InnerText());
            Node.IsXmlAttribute():
                exit(Node.AsXmlAttribute().Value());
            Node.IsXmlText():
                exit(Node.AsXmlText().Value());
        end;
        exit('');
    end;

    [TryFunction]
    local procedure TryLoadXmlRootNode(var InStr: InStream; var XmlRootNode: XmlNode)
    var
        XmlDoc: XmlDocument;
        RootXmlElement: XmlElement;
    begin
        XmlDocument.ReadFrom(InStr, XmlDoc);
        XmlDoc.GetRoot(RootXmlElement);
        XmlRootNode := RootXmlElement.AsXmlNode();
    end;

    local procedure FindNodeText(XmlRootNode: XmlNode; NodePath: Text): Text
    var
        FoundXmlNode: XmlNode;
    begin
        if XmlRootNode.SelectSingleNode(NodePath, FoundXmlNode) then
            exit(GetNodeInnerText(FoundXmlNode));
        exit('');
    end;

    local procedure URLEncode(InText: Text): Text
    var
        SystemWebHttpUtility: DotNet HttpUtility;
    begin
        SystemWebHttpUtility := SystemWebHttpUtility.HttpUtility();
        exit(SystemWebHttpUtility.UrlEncode(InText));
    end;

    procedure DateConvertYYYYMMDD2XML(YYYYMMDD: Text): Text
    begin
        if StrLen(YYYYMMDD) <> 8 then
            exit(YYYYMMDD);
        exit(StrSubstNo('%1-%2-%3', CopyStr(YYYYMMDD, 1, 4), CopyStr(YYYYMMDD, 5, 2), CopyStr(YYYYMMDD, 7, 2)));
    end;

    procedure DateConvertXML2YYYYMMDD(XMLDate: Text): Text
    begin
        exit(DelChr(XMLDate, '=', '-'))
    end;

    internal procedure GetFeatureTelemetryName(): Text
    var
        OCRServiceTelemetryNameTxt: Label 'Document Exchange', Locked = true;
    begin
        exit(OCRServiceTelemetryNameTxt);
    end;

    local procedure GetOcrServiceSetup(VerifyEnable: Boolean)
    begin
        GetOcrServiceSetupExtended(OCRServiceSetup, VerifyEnable);
    end;

    procedure GetOcrServiceSetupExtended(var OCRServiceSetup: Record "OCR Service Setup"; VerifyEnable: Boolean)
    begin
        OCRServiceSetup.Get();
        if OCRServiceSetup."Service URL" <> '' then
            exit;
        if VerifyEnable then
            OCRServiceSetup.CheckEnabled();
        OCRServiceSetup.TestField("User Name");
        OCRServiceSetup.TestField("Service URL");
    end;

    [Scope('OnPrem')]
    procedure StartUpload(NumberOfUploads: Integer): Boolean
    var
        ResponseStr: InStream;
        ResponseText: Text;
    begin
        if NumberOfUploads < 1 then begin
            Session.LogMessage('00008L9', InitializingUploadFailedTxt, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryTok);
            exit(false);
        end;

        // Initialize upload
        if not RsoGetRequest(StrSubstNo('files/rest/requestupload?targetCount=%1', NumberOfUploads), ResponseStr) then begin
            Session.LogMessage('00008KE', InitializingUploadFailedTxt, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryTok);
            LogActivityFailed(OCRServiceSetup.RecordId, InitiateUploadMsg, '');
            exit(false); // in case error text is empty
        end;
        ResponseStr.ReadText(ResponseText);
        if ResponseText = '' then begin
            Session.LogMessage('00008KF', InitializingUploadFailedTxt, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryTok);
            LogActivityFailed(OCRServiceSetup.RecordId, InitiateUploadMsg, '');
            exit(false); // in case error text is empty
        end;

        Session.LogMessage('00008KG', StrSubstNo(UploadTotalSuccessMsg, NumberOfUploads), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryTok);
        LogActivitySucceeded(OCRServiceSetup.RecordId, InitiateUploadMsg, StrSubstNo(UploadTotalSuccessMsg, NumberOfUploads));
        exit(true);
    end;

    [Scope('OnPrem')]
    procedure UploadImage(var TempBlob: Codeunit "Temp Blob"; FileName: Text; ExternalReference: Text[50]; Template: Code[20]; LoggingRecordId: RecordID): Boolean
    var
        HttpRequestURL: Text;
        APIPart: Text;
    begin
        GetOcrServiceSetup(true);
        APIPart := StrSubstNo(
            'files/rest/image2?filename=%1&customerid=&batchexternalid=%2&buyerid=&documenttype=%3&sortingmethod=OneDocumentPerFile',
            URLEncode(FileName), ExternalReference, Template);
        HttpRequestURL := StrSubstNo('%1/%2', OCRServiceSetup."Service URL", APIPart);
        if UploadFile(TempBlob, HttpRequestURL, '*/*', 'application/octet-stream', LoggingRecordId) then begin
            Session.LogMessage('000089H', OCRServiceUserSuccessfullyUploadedDocumentTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryTok);
            exit(true)
        end;
        Session.LogMessage('000089I', OCRServiceUserFailedToUploadDocumentTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryTok);
        exit(false);
    end;

    [Scope('OnPrem')]
    procedure UploadLearningDocument(var TempBlob: Codeunit "Temp Blob"; DocumentId: Text; LoggingRecordId: RecordID): Boolean
    var
        HttpRequestURL: Text;
        APIPart: Text;
    begin
        GetOcrServiceSetup(true);
        APIPart := StrSubstNo('documents/rest/%1/learningdocument', DocumentId);
        HttpRequestURL := StrSubstNo('%1/%2', OCRServiceSetup."Service URL", APIPart);
        if UploadFile(TempBlob, HttpRequestURL, '', '', LoggingRecordId) then begin
            Session.LogMessage('000089J', OCRServiceUserSuccessfullyUploadedLearningDocumentTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryTok);
            exit(true)
        end;
        Session.LogMessage('000089K', OCRServiceUserFailedToUploadLearningDocumentTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryTok);
        exit(false);
    end;

    local procedure UploadFile(var TempBlob: Codeunit "Temp Blob"; HttpRequestURL: Text; HttpRequestReturnType: Text; HttpRequestContentType: Text; LoggingRecordId: RecordID): Boolean
    var
        HttpWebRequestMgt: Codeunit "Http Web Request Mgt.";
        OfficeMgt: Codeunit "Office Management";
        HttpStatusCode: DotNet HttpStatusCode;
        ResponseHeaders: DotNet NameValueCollection;
        ResponseStr: InStream;
        ResponseText: Text;
    begin
        if not TempBlob.HasValue() then begin
            Session.LogMessage('00008KH', NoFileContentTxt, Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryTok);
            LogActivityFailedNoError(OCRServiceSetup.RecordId, UploadFileMsg, NoFileContentErr);
            LogActivityFailed(LoggingRecordId, UploadFileMsg, NoFileContentErr); // throws error
        end;

        GetOcrServiceSetup(true);

        HttpWebRequestMgt.Initialize(HttpRequestURL);
        HttpWebRequestMgt.SetTraceLogEnabled(false); // Activity Log will log for us
        HttpWebRequestMgt.DisableUI();
        RsoAddCookie(HttpWebRequestMgt);
        RsoAddHeaders(HttpWebRequestMgt);
        if HttpRequestReturnType <> '' then
            HttpWebRequestMgt.SetReturnType(HttpRequestReturnType);
        if HttpRequestContentType <> '' then
            HttpWebRequestMgt.SetContentType(HttpRequestContentType);
        HttpWebRequestMgt.SetMethod(MethodPostTok);
        HttpWebRequestMgt.AddBodyBlob(TempBlob);
        HttpWebRequestMgt.CreateInstream(ResponseStr);

        if not HttpWebRequestMgt.GetResponse(ResponseStr, HttpStatusCode, ResponseHeaders) then begin
            if HttpWebRequestMgt.ProcessFaultXMLResponse('', '/ServiceError/Message', '', '') then;
            Session.LogMessage('000089L', UploadFileFailedWithNoResponseMsg, Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryTok);
            LogActivityFailedNoError(OCRServiceSetup.RecordId, UploadFileMsg, '');
            LogActivityFailed(LoggingRecordId, UploadFileMsg, '');
            exit(false); // in case error text is empty
        end;

        ResponseStr.ReadText(ResponseText);

        if ResponseText = '<BoolValue xmlns:i="http://www.w3.org/2001/XMLSchema-instance"><Value>true</Value></BoolValue>' then begin
            Session.LogMessage('00008KI', UploadFileSucceedTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryTok);
            LogActivitySucceeded(OCRServiceSetup.RecordId, UploadFileMsg, '');
            LogActivitySucceeded(LoggingRecordId, UploadFileMsg, '');
            if GuiAllowed and (not OfficeMgt.IsAvailable()) then
                Message(UploadSuccessMsg);
            exit(true);
        end;

        Session.LogMessage('000089M', StrSubstNo(UploadFileFailedTelemetryMsg, ResponseText), Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryTok);
        LogActivityFailedNoError(OCRServiceSetup.RecordId, UploadFileMsg, StrSubstNo(UploadFileFailedMsg, ResponseText));
        LogActivityFailed(LoggingRecordId, UploadFileMsg, StrSubstNo(UploadFileFailedMsg, ResponseText)); // throws error
    end;

    [Scope('OnPrem')]
    procedure UploadAttachment(var TempBlob: Codeunit "Temp Blob"; FileName: Text; ExternalReference: Text[50]; Template: Code[20]; RelatedRecordId: RecordID): Boolean
    begin
        if not TempBlob.HasValue() then begin
            Session.LogMessage('00008LA', NoFileContentTxt, Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryTok);
            Error(NoFileContentErr);
        end;

        if not StartUpload(1) then
            exit(false);

        exit(UploadImage(TempBlob, FileName, ExternalReference, Template, RelatedRecordId));
    end;

    [Scope('OnPrem')]
    procedure UploadCorrectedOCRFile(IncomingDocument: Record "Incoming Document"): Boolean
    var
        TempBlob: Codeunit "Temp Blob";
        DocumentId: Text;
    begin
        if not IncomingDocument."OCR Data Corrected" then begin
            Message(NoOCRDataCorrectionMsg);
            exit;
        end;

        DocumentId := GetOCRServiceDocumentReference(IncomingDocument);
        CorrectOCRFile(IncomingDocument, TempBlob);
        if not TempBlob.HasValue() then
            Error(NoFileContentErr);

        if not StartUpload(1) then
            exit(false);

        exit(UploadLearningDocument(TempBlob, DocumentId, IncomingDocument.RecordId));
    end;

    procedure CorrectOCRFile(IncomingDocument: Record "Incoming Document"; var TempBlob: Codeunit "Temp Blob")
    var
        OCRFileXmlRootNode: XmlNode;
        OCRFileXmlDocument: XmlDocument;
        OCRFileXmlDeclaration: XmlDeclaration;
        OutStream: OutStream;
        OCRFileXmlText: Text;
    begin
        ValidateUpdatedOCRFields(IncomingDocument);

        GetOriginalOCRXMLRootNode(IncomingDocument, OCRFileXmlRootNode);

        CorrectOCRFileNode(OCRFileXmlRootNode, IncomingDocument, IncomingDocument.FieldNo("Vendor Name"));
        CorrectOCRFileNode(OCRFileXmlRootNode, IncomingDocument, IncomingDocument.FieldNo("Vendor Invoice No."));
        CorrectOCRFileNode(OCRFileXmlRootNode, IncomingDocument, IncomingDocument.FieldNo("Order No."));
        CorrectOCRFileNode(OCRFileXmlRootNode, IncomingDocument, IncomingDocument.FieldNo("Document Date"));
        CorrectOCRFileNode(OCRFileXmlRootNode, IncomingDocument, IncomingDocument.FieldNo("Due Date"));
        CorrectOCRFileNode(OCRFileXmlRootNode, IncomingDocument, IncomingDocument.FieldNo("Amount Excl. VAT"));
        CorrectOCRFileNode(OCRFileXmlRootNode, IncomingDocument, IncomingDocument.FieldNo("Amount Incl. VAT"));
        CorrectOCRFileNode(OCRFileXmlRootNode, IncomingDocument, IncomingDocument.FieldNo("VAT Amount"));
        CorrectOCRFileNode(OCRFileXmlRootNode, IncomingDocument, IncomingDocument.FieldNo("Currency Code"));
        CorrectOCRFileNode(OCRFileXmlRootNode, IncomingDocument, IncomingDocument.FieldNo("Vendor VAT Registration No."));
        CorrectOCRFileNode(OCRFileXmlRootNode, IncomingDocument, IncomingDocument.FieldNo("Vendor IBAN"));
        CorrectOCRFileNode(OCRFileXmlRootNode, IncomingDocument, IncomingDocument.FieldNo("Vendor Bank Branch No."));
        CorrectOCRFileNode(OCRFileXmlRootNode, IncomingDocument, IncomingDocument.FieldNo("Vendor Bank Account No."));
        CorrectOCRFileNode(OCRFileXmlRootNode, IncomingDocument, IncomingDocument.FieldNo("Vendor Phone No."));
#if not CLEAN30
        RaiseOnCorrectOCRFileOnAfterCorrectOCRFileNodes(OCRFileXmlRootNode, IncomingDocument);
#endif
        OnCorrectOCRFileOnAfterCorrectOCRFileXmlNodes(OCRFileXmlRootNode, IncomingDocument);
        Clear(TempBlob);
        TempBlob.CreateOutStream(OutStream);
        OCRFileXmlRootNode.GetDocument(OCRFileXmlDocument);
        if OCRFileXmlDocument.GetDeclaration(OCRFileXmlDeclaration) then
            OCRFileXmlDocument.WriteTo(OutStream)
        else begin
            // XmlDocument.WriteTo always adds a declaration, so write only the root element when the original file has none.
            OCRFileXmlRootNode.WriteTo(OCRFileXmlText);
            Clear(TempBlob);
            TempBlob.CreateOutStream(OutStream, TextEncoding::UTF8);
            OutStream.WriteText(OCRFileXmlText);
        end;
    end;

#if not CLEAN30
    [Scope('OnPrem')]
    [Obsolete('Use CorrectOCRFileNode with a native XmlNode parameter instead.', '30.0')]
    procedure CorrectOCRFileNode(var OCRFileXMLRootNode: DotNet XmlNode; IncomingDocument: Record "Incoming Document"; FieldNo: Integer)
    var
        CorrectionXMLNode: DotNet XmlNode;
        EmptyCorrectionXMLNode: DotNet XmlNode;
        CorrectionXMLNodeParent: DotNet XmlNode;
        PositionXMLNode: DotNet XmlNode;
        XPath: Text;
        CorrectionValue: Text;
    begin
        XPath := IncomingDocument.GetDataExchangePath(FieldNo);
        if XPath = '' then
            exit;
        if IsNull(OCRFileXMLRootNode) then
            exit;
        CorrectionXMLNode := OCRFileXMLRootNode.SelectSingleNode(XPath);
        if IsNull(CorrectionXMLNode) then
            exit;
        if not IsOCRFileCorrectionNeeded(IncomingDocument, FieldNo, CorrectionXMLNode.InnerText, CorrectionValue) then
            exit;

        PositionXMLNode := CorrectionXMLNode.SelectSingleNode('../Position');
        if not IsNull(PositionXMLNode) then
            PositionXMLNode.InnerText := '0, 0, 0, 0';
        if CorrectionValue = '' then begin
            CorrectionXMLNodeParent := CorrectionXMLNode.ParentNode;
            EmptyCorrectionXMLNode := CorrectionXMLNodeParent.OwnerDocument.CreateElement(CorrectionXMLNode.Name);
            CorrectionXMLNodeParent.ReplaceChild(EmptyCorrectionXMLNode, CorrectionXMLNode);
        end else
            CorrectionXMLNode.InnerText := CorrectionValue
    end;
#endif

    [Scope('OnPrem')]
    procedure CorrectOCRFileNode(var OCRFileXmlRootNode: XmlNode; IncomingDocument: Record "Incoming Document"; FieldNo: Integer)
    var
        CorrectionXmlNode: XmlNode;
        PositionXmlNode: XmlNode;
        XPath: Text;
        CorrectionValue: Text;
    begin
        XPath := IncomingDocument.GetDataExchangePath(FieldNo);
        if XPath = '' then
            exit;
        if not OCRFileXmlRootNode.SelectSingleNode(XPath, CorrectionXmlNode) then
            exit;
        if not IsOCRFileCorrectionNeeded(IncomingDocument, FieldNo, GetNodeInnerText(CorrectionXmlNode), CorrectionValue) then
            exit;

        if CorrectionXmlNode.SelectSingleNode('../Position', PositionXmlNode) then
            SetNodeInnerText(PositionXmlNode, '0, 0, 0, 0');
        if (CorrectionValue = '') and CorrectionXmlNode.IsXmlElement() then
            CorrectionXmlNode.ReplaceWith(
                XmlElement.Create(CorrectionXmlNode.AsXmlElement().LocalName(), CorrectionXmlNode.AsXmlElement().NamespaceUri()))
        else
            SetNodeInnerText(CorrectionXmlNode, CorrectionValue);
    end;

    local procedure IsOCRFileCorrectionNeeded(IncomingDocument: Record "Incoming Document"; FieldNo: Integer; OriginalValue: Text; var CorrectionValue: Text) CorrectionNeeded: Boolean
    var
        IncomingDocumentRecRef: RecordRef;
        IncomingDocumentFieldRef: FieldRef;
        CorrectionValueAsDecimal: Decimal;
        OriginalValueAsDecimal: Decimal;
    begin
        IncomingDocumentRecRef.GetTable(IncomingDocument);
        IncomingDocumentFieldRef := IncomingDocumentRecRef.Field(FieldNo);

        case IncomingDocumentFieldRef.Type of
            FieldType::Date:
                begin
                    CorrectionValue := DateConvertXML2YYYYMMDD(Format(IncomingDocumentFieldRef.Value, 0, 9));
                    CorrectionNeeded := OriginalValue <> CorrectionValue;
                end;
            FieldType::Decimal:
                begin
                    CorrectionValueAsDecimal := IncomingDocumentFieldRef.Value();
                    CorrectionValue := Format(IncomingDocumentFieldRef.Value, 0, 9);
                    if Evaluate(OriginalValueAsDecimal, OriginalValue, 9) then;
                    CorrectionNeeded := OriginalValueAsDecimal <> CorrectionValueAsDecimal;
                end;
            else begin
                CorrectionValue := Format(IncomingDocumentFieldRef.Value, 0, 9);
                CorrectionNeeded := OriginalValue <> CorrectionValue;
            end;
        end;
    end;

    local procedure SetNodeInnerText(Node: XmlNode; NewText: Text)
    var
        NodeXmlElement: XmlElement;
    begin
        case true of
            Node.IsXmlElement():
                begin
                    NodeXmlElement := Node.AsXmlElement();
                    NodeXmlElement.RemoveNodes();
                    NodeXmlElement.Add(XmlText.Create(NewText));
                end;
            Node.IsXmlAttribute():
                Node.AsXmlAttribute().Value(NewText);
            Node.IsXmlText():
                Node.AsXmlText().Value(NewText);
        end;
    end;

    procedure ValidateUpdatedOCRFields(IncomingDocument: Record "Incoming Document")
    begin
        IncomingDocument.TestField("Vendor Name");
    end;

#if not CLEAN30
    [Scope('OnPrem')]
    [Obsolete('Use GetOriginalOCRXMLRootNode with a native XmlNode parameter instead.', '30.0')]
    procedure GetOriginalOCRXMLRootNode(IncomingDocument: Record "Incoming Document"; var OriginalXMLRootNode: DotNet XmlNode)
    var
        OriginalXmlNode: XmlNode;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetOriginalOCRXMLRootNode(IncomingDocument, OriginalXMLRootNode, IsHandled);
        if IsHandled then
            exit;

        if LoadOriginalOCRXmlRootNode(IncomingDocument, OriginalXmlNode) then
            ConvertToDotNetXmlNode(OriginalXmlNode, OriginalXMLRootNode);
    end;
#endif

    [Scope('OnPrem')]
    procedure GetOriginalOCRXMLRootNode(IncomingDocument: Record "Incoming Document"; var OriginalXmlRootNode: XmlNode)
#if not CLEAN30
    var
        OriginalXMLRootNodeDotNet: DotNet XmlNode;
        IsHandled: Boolean;
#endif
    begin
#if not CLEAN30
        IsHandled := false;
#pragma warning disable AL0432
        OnBeforeGetOriginalOCRXMLRootNode(IncomingDocument, OriginalXMLRootNodeDotNet, IsHandled);
#pragma warning restore AL0432
        if IsHandled then begin
            if not IsNull(OriginalXMLRootNodeDotNet) then
                ConvertFromDotNetXmlNode(OriginalXMLRootNodeDotNet, OriginalXmlRootNode);
            exit;
        end;
#endif
        LoadOriginalOCRXmlRootNode(IncomingDocument, OriginalXmlRootNode);
    end;

    local procedure LoadOriginalOCRXmlRootNode(IncomingDocument: Record "Incoming Document"; var OriginalXmlRootNode: XmlNode): Boolean
    var
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
        TempBlob: Codeunit "Temp Blob";
        InStream: InStream;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetOriginalOCRXmlNode(IncomingDocument, OriginalXmlRootNode, IsHandled);
        if IsHandled then
            exit(true);

        IncomingDocument.TestField(Posted, false);
        IncomingDocumentAttachment.SetRange("Incoming Document Entry No.", IncomingDocument."Entry No.");
        IncomingDocumentAttachment.SetRange("Generated from OCR", true);
        IncomingDocumentAttachment.SetRange(Default, true);
        if not IncomingDocumentAttachment.FindFirst() then
            exit(false);

        TempBlob.FromRecord(IncomingDocumentAttachment, IncomingDocumentAttachment.FieldNo(Content));
        TempBlob.CreateInStream(InStream);
        // Called without using the return value so that a parse error is raised, as before.
        TryLoadXmlRootNode(InStream, OriginalXmlRootNode);
        exit(true);
    end;
#if not CLEAN30
    local procedure RaiseOnCorrectOCRFileOnAfterCorrectOCRFileNodes(var OCRFileXmlRootNode: XmlNode; var IncomingDocument: Record "Incoming Document")
    var
        OCRFileXMLRootNodeDotNet: DotNet XmlNode;
    begin
        ConvertToDotNetXmlNode(OCRFileXmlRootNode, OCRFileXMLRootNodeDotNet);
#pragma warning disable AL0432
        OnCorrectOCRFileOnAfterCorrectOCRFileNodes(OCRFileXMLRootNodeDotNet, IncomingDocument);
#pragma warning restore AL0432
        ConvertFromDotNetXmlNode(OCRFileXMLRootNodeDotNet, OCRFileXmlRootNode);
    end;

    local procedure ConvertToDotNetXmlNode(NativeXmlNode: XmlNode; var DotNetXmlNode: DotNet XmlNode)
    var
        NativeXmlDocument: XmlDocument;
        DotNetXmlDocument: DotNet XmlDocument;
        XmlText: Text;
    begin
        // Convert the supplied node itself, not only the document root, so that relative XPaths keep working.
        if NativeXmlNode.IsXmlDocument() then
            NativeXmlDocument := NativeXmlNode.AsXmlDocument()
        else
            NativeXmlNode.GetDocument(NativeXmlDocument);
        NativeXmlDocument.WriteTo(XmlText);
        DotNetXmlDocument := DotNetXmlDocument.XmlDocument();
        DotNetXmlDocument.LoadXml(XmlText);
        if NativeXmlNode.IsXmlDocument() then
            DotNetXmlNode := DotNetXmlDocument
        else
            DotNetXmlNode := DotNetXmlDocument.SelectSingleNode(GetNativeXmlNodePath(NativeXmlNode));
    end;

    local procedure GetNativeXmlNodePath(NativeXmlNode: XmlNode) NodePath: Text
    var
        CurrentXmlElement: XmlElement;
        ParentXmlElement: XmlElement;
        PrecedingSiblingXmlNodeList: XmlNodeList;
        HasParent: Boolean;
    begin
        // Positional path such as /*[1]/*[3]/@*[name()='id'], which identifies the node regardless of namespaces.
        if NativeXmlNode.IsXmlElement() then
            CurrentXmlElement := NativeXmlNode.AsXmlElement()
        else begin
            if NativeXmlNode.IsXmlAttribute() then
                NodePath := '/@*[name()=''' + NativeXmlNode.AsXmlAttribute().Name() + ''']';
            NativeXmlNode.GetParent(CurrentXmlElement);
        end;
        repeat
            CurrentXmlElement.SelectNodes('preceding-sibling::*', PrecedingSiblingXmlNodeList);
            NodePath := '/*[' + Format(PrecedingSiblingXmlNodeList.Count() + 1, 0, 9) + ']' + NodePath;
            HasParent := CurrentXmlElement.GetParent(ParentXmlElement);
            CurrentXmlElement := ParentXmlElement;
        until not HasParent;
    end;

    local procedure ConvertFromDotNetXmlNode(DotNetXmlNode: DotNet XmlNode; var NativeXmlNode: XmlNode)
    var
        DotNetXmlNodeType: DotNet XmlNodeType;
        NativeXmlDocument: XmlDocument;
        RootXmlElement: XmlElement;
        NodePath: Text;
    begin
        // Convert the supplied node itself, not only the document root, so that relative XPaths keep working.
        if DotNetXmlNode.NodeType.Equals(DotNetXmlNodeType.Document) then begin
            XmlDocument.ReadFrom(DotNetXmlNode.OuterXml(), NativeXmlDocument);
            NativeXmlNode := NativeXmlDocument.AsXmlNode();
            exit;
        end;
        if GetDotNetXmlNodePath(DotNetXmlNode, NodePath) then begin
            XmlDocument.ReadFrom(DotNetXmlNode.OwnerDocument.OuterXml(), NativeXmlDocument);
            NativeXmlDocument.SelectSingleNode(NodePath, NativeXmlNode);
            exit;
        end;
        // The node is not part of its owner document's tree: convert it as a document of its own.
        XmlDocument.ReadFrom(DotNetXmlNode.OuterXml(), NativeXmlDocument);
        NativeXmlDocument.GetRoot(RootXmlElement);
        NativeXmlNode := RootXmlElement.AsXmlNode();
    end;

    local procedure GetDotNetXmlNodePath(DotNetXmlNode: DotNet XmlNode; var NodePath: Text): Boolean
    var
        DotNetXmlNodeType: DotNet XmlNodeType;
        CurrentDotNetXmlNode: DotNet XmlNode;
    begin
        // Positional path such as /*[1]/*[3]/@*[name()='id'], which identifies the node regardless of namespaces.
        NodePath := '';
        CurrentDotNetXmlNode := DotNetXmlNode;
        if CurrentDotNetXmlNode.NodeType.Equals(DotNetXmlNodeType.Attribute) then begin
            NodePath := '/@*[name()=''' + CurrentDotNetXmlNode.Name + ''']';
            CurrentDotNetXmlNode := CurrentDotNetXmlNode.SelectSingleNode('..');
        end else
            if not CurrentDotNetXmlNode.NodeType.Equals(DotNetXmlNodeType.Element) then
                CurrentDotNetXmlNode := CurrentDotNetXmlNode.ParentNode;
        while not IsNull(CurrentDotNetXmlNode) do begin
            if not CurrentDotNetXmlNode.NodeType.Equals(DotNetXmlNodeType.Element) then
                exit(CurrentDotNetXmlNode.NodeType.Equals(DotNetXmlNodeType.Document) and (NodePath <> ''));
            NodePath := '/*[' + Format(CurrentDotNetXmlNode.SelectNodes('preceding-sibling::*').Count + 1, 0, 9) + ']' + NodePath;
            CurrentDotNetXmlNode := CurrentDotNetXmlNode.ParentNode;
        end;
        exit(false);
    end;
#endif

    procedure GetOCRServiceDocumentReference(IncomingDocument: Record "Incoming Document"): Text[50]
    var
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
    begin
        IncomingDocumentAttachment.SetRange("Incoming Document Entry No.", IncomingDocument."Entry No.");
        IncomingDocumentAttachment.SetRange("Generated from OCR", true);
        if not IncomingDocumentAttachment.FindFirst() then
            exit('');
        exit(IncomingDocumentAttachment."OCR Service Document Reference");
    end;

    [Scope('OnPrem')]
    procedure GetDocumentList(var ResponseStr: InStream): Boolean
    begin
        if not RsoGetRequest('currentuser/documents?pageIndex=0&pageSize=1000', ResponseStr) then begin
            Session.LogMessage('00008KJ', GettingDocumentsForUserFailedTxt, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryTok);
            exit(false);
        end;
        exit(true);
    end;

    [Scope('OnPrem')]
    procedure GetDocuments(ExternalBatchFilter: Text): Integer
    var
        Regex: Codeunit Regex;
        XmlRootNode: XmlNode;
        BatchXmlNode: XmlNode;
        ChildXmlNode: XmlNode;
        DocumentIdXmlNodeList: XmlNodeList;
        ResponseStr: InStream;
        ExternalBatchId: Text[50];
        DocId: Text[50];
        CountProcessed: Integer;
        CountDownloaded: Integer;
    begin
        GetOcrServiceSetup(true);

        if not RsoGetRequest(StrSubstNo('documents/rest/customers/%1/outputdocuments', OCRServiceSetup."Customer ID"), ResponseStr) then
            Session.LogMessage('00008KK', GettingDocumentsForCustomerFailedTxt, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryTok);

        TryLoadXmlRootNode(ResponseStr, XmlRootNode);

        foreach BatchXmlNode in XmlRootNode.AsXmlElement().GetChildElements() do begin
            BatchXmlNode.SelectSingleNode('BatchExternalId', ChildXmlNode);
            ExternalBatchId := CopyStr(GetNodeInnerText(ChildXmlNode), 1, MaxStrLen(ExternalBatchId));
            if (ExternalBatchFilter = '') or (ExternalBatchFilter = ExternalBatchId) then begin
                BatchXmlNode.SelectNodes('DocumentId', DocumentIdXmlNodeList);
                foreach ChildXmlNode in DocumentIdXmlNodeList do begin
                    CountProcessed += 1;
                    DocId := CopyStr(GetNodeInnerText(ChildXmlNode), 1, MaxStrLen(DocId));

                    if not Regex.IsMatch(DocId, '^[a-zA-Z0-9\-\{\}]*$') then begin
                        Session.LogMessage('00008LB', InvalidDocumentIdTxt, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryTok);
                        LogActivityFailed(OCRServiceSetup.RecordId, GetNewDocumentsMsg, StrSubstNo(NotValidDocIDErr, DocId));
                    end;

                    CountDownloaded += DownloadDocument(ExternalBatchId, DocId);

                    if CountDownloaded > GetMaxDocDownloadCount() then begin
                        Session.LogMessage('00008KL', StrSubstNo(DocumentsDownloadedTxt, CountDownloaded, CountProcessed), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryTok);
                        LogActivitySucceeded(OCRServiceSetup.RecordId, GetNewDocumentsMsg, StrSubstNo(NewDocumentsTotalMsg, CountDownloaded, CountProcessed));
                        exit(CountDownloaded);
                    end;
                end;
            end;
        end;

        Session.LogMessage('00008KM', StrSubstNo(DocumentsDownloadedTxt, CountDownloaded, CountProcessed), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryTok);

        LogActivitySucceeded(OCRServiceSetup.RecordId, GetNewDocumentsMsg, StrSubstNo(NewDocumentsTotalMsg, CountDownloaded, CountProcessed));

        if (ExternalBatchFilter <> '') and (CountDownloaded > 0) then
            exit(CountDownloaded);

        if ExternalBatchFilter <> '' then
            GetDocumentStatus(ExternalBatchFilter)
        else
            GetDocumentsExcludeProcessed();

        exit(CountDownloaded);
    end;

    [Scope('OnPrem')]
    procedure GetDocumentsExcludeProcessed()
    var
        IncomingDocument: Record "Incoming Document";
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
        TempIncomingDocumentAttachment: Record "Incoming Document Attachment" temporary;
    begin
        GetOcrServiceSetup(true);

        IncomingDocument.SetRange("OCR Status", IncomingDocument."OCR Status"::Sent);
        if not IncomingDocument.FindSet() then
            exit;

        repeat
            IncomingDocumentAttachment.SetRange("Incoming Document Entry No.", IncomingDocument."Entry No.");
            IncomingDocumentAttachment.SetRange(Default, true);
            IncomingDocumentAttachment.FindFirst();
            TempIncomingDocumentAttachment := IncomingDocumentAttachment;
            TempIncomingDocumentAttachment.Insert();
        until IncomingDocument.Next() = 0;

        GetBatches(TempIncomingDocumentAttachment, '');
    end;

    [Scope('OnPrem')]
    procedure GetDocumentStatus(ExternalBatchFilter: Text)
    var
        IncomingDocument: Record "Incoming Document";
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
        TempIncomingDocumentAttachment: Record "Incoming Document Attachment" temporary;
    begin
        GetOcrServiceSetup(true);

        IncomingDocumentAttachment.SetRange("External Document Reference", ExternalBatchFilter);
        IncomingDocumentAttachment.SetRange(Default, true);
        IncomingDocumentAttachment.FindFirst();

        IncomingDocument.Get(IncomingDocumentAttachment."Incoming Document Entry No.");
        if (IncomingDocument."OCR Status" <> IncomingDocument."OCR Status"::Sent) and
           (IncomingDocument."OCR Status" <> IncomingDocument."OCR Status"::"Awaiting Verification")
        then
            exit;

        TempIncomingDocumentAttachment := IncomingDocumentAttachment;
        TempIncomingDocumentAttachment.Insert();

        GetBatches(TempIncomingDocumentAttachment, ExternalBatchFilter);
    end;

    [Scope('OnPrem')]
    procedure GetDocumentForAttachment(var IncomingDocumentAttachment: Record "Incoming Document Attachment"): Integer
    var
        IncomingDocument: Record "Incoming Document";
        Status: Integer;
    begin
        if IncomingDocumentAttachment."External Document Reference" = '' then begin
            Session.LogMessage('00008LC', DocumentNotUploadedTxt, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryTok);
            Error(NotUploadedErr);
        end;

        if GetDocuments(IncomingDocumentAttachment."External Document Reference") > 0 then
            Status := IncomingDocument."OCR Status"::Success
        else begin
            IncomingDocument.Get(IncomingDocumentAttachment."Incoming Document Entry No.");
            Status := IncomingDocument."OCR Status";
        end;

        case Status of
            IncomingDocument."OCR Status"::Success:
                Message(ImportSuccessMsg);
            IncomingDocument."OCR Status"::"Awaiting Verification":
                Message(VerifyMsg);
            IncomingDocument."OCR Status"::Error:
                Message(FailedMsg);
            IncomingDocument."OCR Status"::Sent: // Pending Result
                Message(DocumentNotReadyMsg);
            else
                Message(DocumentNotReadyMsg);
        end;

        exit(Status);
    end;

    local procedure GetBatchDocuments(var XmlRootNode: XmlNode; BatchFilter: Text): Boolean
    var
        ResponseStr: InStream;
        Path: Text;
        PageSize: Integer;
        CurrentPage: Integer;
    begin
        PageSize := 200;
        CurrentPage := 0;
        Path := StrSubstNo(
            'documents/rest/customers/%1/batches/%2/documents?pageIndex=%3&pageSize=%4', OCRServiceSetup."Customer ID",
            BatchFilter, CurrentPage, PageSize);
        if not RsoGetRequest(Path, ResponseStr) then begin
            Session.LogMessage('00008KN', GettingBatchDocumentsFailedTxt, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryTok);
            exit(false);
        end;
        // Called without using the return value so that a parse error is raised, as before.
        TryLoadXmlRootNode(ResponseStr, XmlRootNode);
        exit(true);
    end;

    local procedure GetBatchesApi(var XmlRootNode: XmlNode; ExternalBatchFilter: Text): Boolean
    var
        ResponseStr: InStream;
        Path: Text;
        PageSize: Integer;
        CurrentPage: Integer;
    begin
        PageSize := 200;
        CurrentPage := 0;
        if ExternalBatchFilter <> '' then
            Path := StrSubstNo(
                'documents/rest/customers/%1/batches?pageIndex=%2&pageSize=%3&externalId=%4', OCRServiceSetup."Customer ID",
                CurrentPage, PageSize, ExternalBatchFilter)
        else
            Path := StrSubstNo(
                'documents/rest/customers/%1/batches?pageIndex=%2&pageSize=%3&excludeProcessed=1', OCRServiceSetup."Customer ID",
                CurrentPage, PageSize);

        if not RsoGetRequest(Path, ResponseStr) then begin
            Session.LogMessage('00008KO', GettingBatchesFailedTxt, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryTok);
            exit(false);
        end;

        // Called without using the return value so that a parse error is raised, as before.
        TryLoadXmlRootNode(ResponseStr, XmlRootNode);
        exit(true);
    end;

    local procedure GetBatches(var TempIncomingDocumentAttachment: Record "Incoming Document Attachment" temporary; ExternalBatchFilter: Text): Boolean
    var
        IncomingDocument: Record "Incoming Document";
        SendIncomingDocumentToOCR: Codeunit "Send Incoming Document to OCR";
        XmlRootNode: XmlNode;
        BatchesXmlNode: XmlNode;
        CurrentPage: Integer;
        TotalPages: Integer;
    begin
        repeat
            if not GetBatchesApi(XmlRootNode, ExternalBatchFilter) then
                exit(false);

            if not Evaluate(TotalPages, FindNodeText(XmlRootNode, '//PageCount')) then begin
                Session.LogMessage('00008LD', GettingBatchesFailedTxt, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryTok);
                exit(false);
            end;

            XmlRootNode.SelectSingleNode('//Batches', BatchesXmlNode);
            FindDocumentFromList(BatchesXmlNode, TempIncomingDocumentAttachment);

            CurrentPage += 1;
        until (TempIncomingDocumentAttachment.Count = 0) or (CurrentPage > TotalPages);

        if TempIncomingDocumentAttachment.FindSet() then
            repeat
                IncomingDocument.Get(TempIncomingDocumentAttachment."Incoming Document Entry No.");
                SendIncomingDocumentToOCR.SetStatusToFailed(IncomingDocument);
            until TempIncomingDocumentAttachment.Next() = 0;

        exit(true);
    end;

    [Scope('OnPrem')]
    procedure GetDocumentId(ExternalBatchFilter: Text): Text
    var
        XmlRootNode: XmlNode;
        BatchID: Text;
        DocumentID: Text;
    begin
        GetOcrServiceSetup(true);

        if not GetBatchesApi(XmlRootNode, ExternalBatchFilter) then
            exit('');

        BatchID := FindNodeText(XmlRootNode, '/PagedBatches/Batches/Batch/Id');

        if not GetBatchDocuments(XmlRootNode, BatchID) then
            exit('');

        DocumentID := FindNodeText(XmlRootNode, '/PagedDocuments/Documents/Document/Id');

        exit(DocumentID);
    end;

    local procedure DownloadDocument(ExternalBatchId: Text[50]; DocId: Text[50]): Integer
    var
        IncomingDocument: Record "Incoming Document";
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
        SendIncomingDocumentToOCR: Codeunit "Send Incoming Document to OCR";
        FeatureTelemetry: Codeunit "Feature Telemetry";
        ImageInStr: InStream;
        ResponseStr: InStream;
        XmlRootNode: XmlNode;
        AttachmentName: Text[250];
        ContentType: Text[50];
        TrackId: Text;
        IsHandled: Boolean;
        Result: Integer;
    begin
        IsHandled := false;
        Result := 0;
        OnBeforeDownloadDocument(ExternalBatchId, DocId, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if not RsoGetRequest(StrSubstNo('documents/rest/%1', DocId), ResponseStr) then begin
            Session.LogMessage('00008KP', OCRServiceUserFailedToDownloadDocumentTxt, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryTok);
            LogActivityFailedNoError(OCRServiceSetup.RecordId, StrSubstNo(DocumentNotDownloadedTxt, DocId, ''), '');
            exit(0);
        end;
        if not TryLoadXmlRootNode(ResponseStr, XmlRootNode) then begin
            Session.LogMessage('000089N', OCRServiceUserFailedToDownloadDocumentTxt, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryTok);
            LogActivityFailedNoError(OCRServiceSetup.RecordId, StrSubstNo(DocumentNotDownloadedTxt, DocId, ''), '');
            exit(0);
        end;
        FeatureTelemetry.LogUptake('0000IMN', TelemetryCategoryTok, Enum::"Feature Uptake Status"::Used);
        FeatureTelemetry.LogUsage('0000IMO', TelemetryCategoryTok, 'Document imported');

        TrackId := FindNodeText(XmlRootNode, 'TrackId');

        if ExternalBatchId <> '' then
            IncomingDocumentAttachment.SetRange("External Document Reference", ExternalBatchId);
        if (ExternalBatchId <> '') and IncomingDocumentAttachment.FindFirst() then begin
            Session.LogMessage('00008KQ', UpdatingIncomingDocumentTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryTok);
            IncomingDocument.Get(IncomingDocumentAttachment."Incoming Document Entry No.");
            AttachmentName := IncomingDocumentAttachment.Name;
        end else begin  // New Incoming Document
            Session.LogMessage('00008KR', InsertingIncomingDocumentTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryTok);
            AttachmentName := CopyStr(FindNodeText(XmlRootNode, 'OriginalFilename'), 1, MaxStrLen(AttachmentName));
            IncomingDocument.Init();
            IncomingDocument.CreateIncomingDocument(AttachmentName, '');
            IncomingDocumentAttachment.SetRange("External Document Reference");
            if not RsoGetRequestBinary(StrSubstNo('documents/rest/file/%1/image', DocId), ImageInStr, ContentType) then begin
                Session.LogMessage('00008KS', OCRServiceUserFailedToDownloadDocumentTxt, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryTok);
                LogActivityFailedNoError(OCRServiceSetup.RecordId, StrSubstNo(DocumentNotDownloadedTxt, DocId, TrackId), '');
                exit(0);
            end;

            IncomingDocument.AddAttachmentFromStream(
              IncomingDocumentAttachment, AttachmentName, GetExtensionFromContentType(AttachmentName, ContentType), ImageInStr);
        end;
        IncomingDocument.CheckNotCreated();
        IncomingDocumentAttachment.SetRange("External Document Reference");
        IncomingDocument.AddAttachmentFromStream(IncomingDocumentAttachment, AttachmentName, 'xml', ResponseStr);
        IncomingDocumentAttachment."Generated from OCR" := true;
        IncomingDocumentAttachment."OCR Service Document Reference" := DocId;
        IncomingDocumentAttachment.Validate(Default, true);
        IncomingDocumentAttachment.Modify();

        IncomingDocument.Get(IncomingDocument."Entry No.");
        SendIncomingDocumentToOCR.SetStatusToReceived(IncomingDocument);

        UpdateIncomingDocWithOCRData(IncomingDocument, XmlRootNode);
        Session.LogMessage('000089O', OCRServiceUserSuccessfullyDownloadedDocumentTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryTok);
        LogActivitySucceeded(OCRServiceSetup.RecordId, GetDocumentMsg, StrSubstNo(DocumentDownloadedTxt, DocId, TrackId));
        LogActivitySucceeded(IncomingDocument.RecordId, GetDocumentMsg, StrSubstNo(DocumentDownloadedTxt, DocId, TrackId));

        if not RsoPutRequest(
             StrSubstNo('documents/rest/%1/downloaded', DocId),
             '<UploadDataCollection xmlns:i="http://www.w3.org/2001/XMLSchema-instance" />', ResponseStr)
        then begin
            Session.LogMessage('00008KU', RegisteringDownloadFailedTxt, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryTok);
            LogActivityFailedNoError(OCRServiceSetup.RecordId, StrSubstNo(DownloadNotRegisteredTxt, DocId, TrackId), '');
            LogActivityFailedNoError(IncomingDocument.RecordId, StrSubstNo(DownloadNotRegisteredTxt, DocId, TrackId), '');
            exit(0);
        end;

        Session.LogMessage('00008KV', RegisteringDownloadSucceedTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryTok);
        LogActivitySucceeded(OCRServiceSetup.RecordId, GetDocumentConfirmMsg, StrSubstNo(DocumentDownloadedTxt, DocId, TrackId));
        LogActivitySucceeded(IncomingDocument.RecordId, GetDocumentConfirmMsg, StrSubstNo(DocumentDownloadedTxt, DocId, TrackId));
        Commit();
        exit(1);
    end;

#if not CLEAN30
    [Scope('OnPrem')]
    [Obsolete('Use UpdateIncomingDocWithOCRData with a native XmlNode parameter instead.', '30.0')]
    procedure UpdateIncomingDocWithOCRData(var IncomingDocument: Record "Incoming Document"; var XMLRootNode: DotNet XmlNode)
    var
        XmlRootNodeNative: XmlNode;
    begin
        if not IsNull(XMLRootNode) then
            ConvertFromDotNetXmlNode(XMLRootNode, XmlRootNodeNative);
        UpdateIncomingDocWithOCRData(IncomingDocument, XmlRootNodeNative);
    end;
#endif

    [Scope('OnPrem')]
    procedure UpdateIncomingDocWithOCRData(var IncomingDocument: Record "Incoming Document"; var XmlRootNode: XmlNode)
    var
        Vendor: Record Vendor;
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
        VendorFound: Boolean;
    begin
        if IncomingDocument."Data Exchange Type" = '' then
            exit;

        IncomingDocumentAttachment.SetRange("Incoming Document Entry No.", IncomingDocument."Entry No.");
        IncomingDocumentAttachment.SetRange("Generated from OCR", true);
        IncomingDocumentAttachment.SetRange(Default, true);
        if not IncomingDocumentAttachment.FindFirst() then begin
            Session.LogMessage('00008KT', CannotFindAttachmentTxt, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryTok);
            exit;
        end;

        IncomingDocumentAttachment.ExtractHeaderFields(XmlRootNode, IncomingDocument);
        IncomingDocument.Get(IncomingDocument."Entry No.");

        if FindNodeText(XmlRootNode, 'HeaderFields/HeaderField/Text[../Type/text() = "creditinvoice"]') =
           'true'
        then
            IncomingDocument."Document Type" := IncomingDocument."Document Type"::"Purchase Credit Memo";

        IncomingDocument."OCR Track ID" := CopyStr(FindNodeText(XmlRootNode, 'TrackId'), 1, MaxStrLen(IncomingDocument."OCR Track ID"));

        if not IsNullGuid(IncomingDocument."Vendor Id") then
            VendorFound := Vendor.GetBySystemId(IncomingDocument."Vendor Id");
        if (not VendorFound) and (IncomingDocument."Vendor No." <> '') then
            VendorFound := Vendor.Get(IncomingDocument."Vendor No.");
        if (not VendorFound) and (IncomingDocument."Vendor VAT Registration No." <> '') then begin
            Vendor.SetCurrentKey(Blocked);
            Vendor.SetRange("VAT Registration No.", IncomingDocument."Vendor VAT Registration No.");
            VendorFound := Vendor.FindFirst();
            if not VendorFound then begin
                Vendor.SetRange("VAT Registration No.");
                Vendor.SetRange(ABN, IncomingDocument."Vendor VAT Registration No.");
                VendorFound := Vendor.FindFirst();
            end;
        end;
        if VendorFound then begin
            if IncomingDocument."Vendor Id" <> Vendor.SystemId then
                IncomingDocument.Validate(IncomingDocument."Vendor Id", Vendor.SystemId);
            if IncomingDocument."Vendor No." <> Vendor."No." then
                IncomingDocument.Validate(IncomingDocument."Vendor No.", Vendor."No.");
        end;

        IncomingDocument.Modify();
    end;

    procedure LogActivitySucceeded(RelatedRecordID: RecordID; ActivityDescription: Text; ActivityMessage: Text)
    var
        ActivityLog: Record "Activity Log";
    begin
        ActivityLog.LogActivity(RelatedRecordID, ActivityLog.Status::Success, LoggingConstTxt,
          ActivityDescription, ActivityMessage);
    end;

    procedure LogActivityFailed(RelatedRecordID: RecordID; ActivityDescription: Text; ActivityMessage: Text)
    begin
        LogActivityFailed(RelatedRecordID, ActivityDescription, ActivityMessage, false);
    end;

    local procedure LogActivityFailedNoError(RelatedRecordID: RecordID; ActivityDescription: Text; ActivityMessage: Text)
    begin
        LogActivityFailed(RelatedRecordID, ActivityDescription, ActivityMessage, true);
    end;

    local procedure LogActivityFailed(RelatedRecordID: RecordID; ActivityDescription: Text; ActivityMessage: Text; IgnoreError: Boolean)
    var
        ActivityLog: Record "Activity Log";
    begin
        ActivityMessage := GetLastErrorText + ' ' + ActivityMessage;
        ClearLastError();

        ActivityLog.LogActivity(RelatedRecordID, ActivityLog.Status::Failed, LoggingConstTxt,
          ActivityDescription, ActivityMessage);

        Commit();

        if IgnoreError then
            exit;

        if DelChr(ActivityMessage, '<>', ' ') <> '' then
            Error(ActivityMessage);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Service Connection", 'OnRegisterServiceConnection', '', false, false)]
    procedure HandleOCRRegisterServiceConnection(var ServiceConnection: Record "Service Connection")
    var
        OCRServiceSetup: Record "OCR Service Setup";
        RecRef: RecordRef;
    begin
        if not OCRServiceSetup.Get() then begin
            OCRServiceSetup.Init();
            OCRServiceSetup.Insert(true);
        end;
        RecRef.GetTable(OCRServiceSetup);

        if OCRServiceSetup.Enabled then
            ServiceConnection.Status := ServiceConnection.Status::Enabled
        else
            ServiceConnection.Status := ServiceConnection.Status::Disabled;
        ServiceConnection.InsertServiceConnection(
            ServiceConnection, RecRef.RecordId, OCRServiceSetup.TableCaption(), OCRServiceSetup."Service URL", PAGE::"OCR Service Setup");
    end;

    local procedure GetMaxDocDownloadCount(): Integer
    begin
        exit(1000);
    end;

    local procedure GetDocumentSimplifiedStatus(ObjectStatus: Integer): Integer
    var
        IncomingDocument: Record "Incoming Document";
    begin
        // Status definitions can be found at http://docs.readsoftonline.com/help/eng/partner/#reference/batch-statuses.htm%3FTocPath%3DReference%7C_____6
        // Status codes can be found at https://services.readsoftonline.com/documentation/rest?s=-940536891&m=173766930
        case ObjectStatus of
            0: // 'BATCHCREATED'
                exit(IncomingDocument."OCR Status"::Sent);
            1: // 'BATCHINPUTVALIDATIONFAILED'
                exit(IncomingDocument."OCR Status"::Error);
            3: // 'BATCHPENDINGPROCESSSTART'
                exit(IncomingDocument."OCR Status"::Sent);
            7: // 'BATCHCLASSIFICATIONINPROGRESS'
                exit(IncomingDocument."OCR Status"::Sent);
            10: // 'BATCHPENDINGCORRECTION'
                exit(IncomingDocument."OCR Status"::"Awaiting Verification");
            15: // 'BATCHEXTRACTIONINPROGRESS'
                exit(IncomingDocument."OCR Status"::Sent);
            20: // 'BATCHMANUALVERIFICATION'
                exit(IncomingDocument."OCR Status"::"Awaiting Verification");
            23: // 'BATCHREQUESTINFORMATION'
                exit(IncomingDocument."OCR Status"::"Awaiting Verification");
            25: // 'BATCHAPPROVALINPROGRESS'
                exit(IncomingDocument."OCR Status"::Sent);
            26: // 'BATCHPENDINGREGISTRATION'
                exit(IncomingDocument."OCR Status"::Sent);
            27: // 'BATCHREGISTRATIONINPROGRESS'
                exit(IncomingDocument."OCR Status"::Sent);
            28: // 'BATCHPENDINGPOST'
                exit(IncomingDocument."OCR Status"::Sent);
            29: // 'BATCHPOSTINPROGRESS'
                exit(IncomingDocument."OCR Status"::Sent);
            30: // 'BATCHPENDINGEXPORT'
                exit(IncomingDocument."OCR Status"::Sent);
            33: // 'BATCHEXPORTINPROGRESS'
                exit(IncomingDocument."OCR Status"::Success);
            35: // 'BATCHEXPORTFAILED'
                exit(IncomingDocument."OCR Status"::Error);
            40: // 'BATCHSUCCESSFULLYPROCESSED'
                exit(IncomingDocument."OCR Status"::Success);
            50: // 'BATCHREJECTED'
                exit(IncomingDocument."OCR Status"::Error);
            100: // 'BATCHDELETED'
                exit(IncomingDocument."OCR Status"::Error);
            200: // 'BATCHPREPROCESSINGINPROGRESS'
                exit(IncomingDocument."OCR Status"::Sent);
            13: // 'BATCHMANUALSEPERATION'
                exit(IncomingDocument."OCR Status"::"Awaiting Verification");
            14: // 'BATCHSEPERATIONINPROGRESS'
                exit(IncomingDocument."OCR Status"::Sent);
            95: // 'BATCHDELETEINPROGRESS'
                exit(IncomingDocument."OCR Status"::Error);
            else
                exit(IncomingDocument."OCR Status"::" ");
        end;
    end;

    local procedure FindDocumentFromList(var XmlRootNode: XmlNode; var TempIncomingDocumentAttachment: Record "Incoming Document Attachment" temporary)
    var
        IncomingDocument: Record "Incoming Document";
        SendIncomingDocumentToOCR: Codeunit "Send Incoming Document to OCR";
        DocumentXmlNode: XmlNode;
        DocId: Text;
        DocStatus: Integer;
        StatusAsInt: Integer;
    begin
        foreach DocumentXmlNode in XmlRootNode.AsXmlElement().GetChildElements() do begin
            if TempIncomingDocumentAttachment.IsEmpty() then
                exit;

            DocId := FindNodeText(DocumentXmlNode, './ExternalId');
            TempIncomingDocumentAttachment.SetRange("External Document Reference", DocId);
            if TempIncomingDocumentAttachment.FindSet() then
                repeat
                    Evaluate(StatusAsInt, FindNodeText(DocumentXmlNode, './StatusAsInt'));
                    DocStatus := GetDocumentSimplifiedStatus(StatusAsInt);
                    IncomingDocument.Get(TempIncomingDocumentAttachment."Incoming Document Entry No.");
                    case DocStatus of
                        IncomingDocument."OCR Status"::Error:
                            SendIncomingDocumentToOCR.SetStatusToFailed(IncomingDocument);
                        IncomingDocument."OCR Status"::"Awaiting Verification":
                            SendIncomingDocumentToOCR.SetStatusToVerify(IncomingDocument);
                    end;

                    TempIncomingDocumentAttachment.Delete();
                until TempIncomingDocumentAttachment.Next() = 0;

            // Remove filter
            TempIncomingDocumentAttachment.SetRange("External Document Reference");
            if TempIncomingDocumentAttachment.FindSet() then;
        end;
    end;

    [Scope('OnPrem')]
    procedure TestConnection(var OCRServiceSetup: Record "OCR Service Setup")
    begin
        if SetupConnection(OCRServiceSetup) then
            Message(ConnectionSuccessMsg);
    end;

    [Scope('OnPrem')]
    procedure SetupConnection(var OCRServiceSetup: Record "OCR Service Setup"): Boolean
    begin
        if not HasCredentials(OCRServiceSetup) then
            Error(GetCredentialsErrText());
        if not Authenticate() then
            Error(ConnectionFailedErr);
        UpdateOrganizationInfo(OCRServiceSetup);
        UpdateOcrDocumentTemplates();
        exit(true);
    end;

    [EventSubscriber(ObjectType::Page, Page::"Incoming Document", 'OnCloseIncomingDocumentFromAction', '', false, false)]
    local procedure OnCloseIncomingDocumentHandler(var IncomingDocument: Record "Incoming Document")
    begin
        PAGE.Run(PAGE::"Incoming Document", IncomingDocument);
    end;

    [EventSubscriber(ObjectType::Page, Page::"Incoming Documents", 'OnCloseIncomingDocumentsFromActions', '', false, false)]
    local procedure OnCloseIncomingDocumentsHandler(var IncomingDocument: Record "Incoming Document")
    begin
        PAGE.Run(PAGE::"Incoming Documents", IncomingDocument);
    end;

    procedure OcrServiceIsEnable(): Boolean
    begin
        if not OCRServiceSetup.Get() then
            exit(false);

        if
           (OCRServiceSetup."Service URL" = '') or
           (OCRServiceSetup.Enabled = false)
        then
            exit(false);

        exit(true);
    end;

    [Scope('OnPrem')]
    procedure GetStatusHyperLink(IncomingDocument: Record "Incoming Document"): Text
    var
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
        DocumentID: Text;
    begin
        if IncomingDocument."OCR Status" = IncomingDocument."OCR Status"::"Awaiting Verification" then begin
            IncomingDocument.GetMainAttachment(IncomingDocumentAttachment);
            if IncomingDocumentAttachment."External Document Reference" = '' then
                exit('');

            DocumentID := GetDocumentId(IncomingDocumentAttachment."External Document Reference");
            exit(StrSubstNo('%1/documents/%2', OCRServiceSetup."Sign-in URL", DocumentID));
        end;

        if OCRServiceSetup.Enabled and (OCRServiceSetup."Sign-in URL" <> '') then
            exit(OCRServiceSetup."Sign-in URL");
    end;

    local procedure GetExtensionFromContentType(AttachmentName: Text; ContentType: Text): Text
    var
        FileManagement: Codeunit "File Management";
    begin
        if StrPos(ContentType, 'application/pdf') <> 0 then
            exit('pdf');
        exit(FileManagement.GetExtension(AttachmentName));
    end;

    [EventSubscriber(ObjectType::Table, Database::"Incoming Document", 'OnAfterCreateGenJnlLineFromIncomingDocSuccess', '', false, false)]
    local procedure LogTelemetryOnAfterCreateGenJnlLineFromIncomingDocSuccess(var IncomingDocument: Record "Incoming Document")
    begin
        if IncomingDocument."OCR Status" = IncomingDocument."OCR Status"::Success then
            Session.LogMessage('000089P', OCRServiceUserCreatedGenJnlLineOutOfOCRedDocumentTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryTok);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Release Incoming Document", 'OnAfterCreateDocFromIncomingDocSuccess', '', false, false)]
    local procedure LogTelemetryOnAfterCreateDocFromIncomingDocSuccess(var IncomingDocument: Record "Incoming Document")
    begin
        if IncomingDocument."OCR Status" = IncomingDocument."OCR Status"::Success then
            Session.LogMessage('000089Q', OCRServiceUserCreatedInvoiceOutOfOCRedDocumentTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategoryTok);
    end;

#if not CLEAN30
    [IntegrationEvent(false, false)]
    [Obsolete('Use OnBeforeGetOriginalOCRXmlNode instead.', '30.0')]
    local procedure OnBeforeGetOriginalOCRXMLRootNode(IncomingDocument: Record "Incoming Document"; var OriginalXMLRootNode: DotNet XmlNode; var IsHandled: Boolean)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetOriginalOCRXmlNode(IncomingDocument: Record "Incoming Document"; var OriginalXmlRootNode: XmlNode; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDownloadDocument(ExternalBatchId: Text[50]; DocId: Text[50]; var Result: Integer; var IsHandled: Boolean)
    begin
    end;

#if not CLEAN30
    [IntegrationEvent(false, false)]
    [Obsolete('Use OnCorrectOCRFileOnAfterCorrectOCRFileXmlNodes instead.', '30.0')]
    local procedure OnCorrectOCRFileOnAfterCorrectOCRFileNodes(var OCRFileXMLRootNode: DotNet XmlNode; var IncomingDocument: Record "Incoming Document")
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnCorrectOCRFileOnAfterCorrectOCRFileXmlNodes(var OCRFileXmlRootNode: XmlNode; var IncomingDocument: Record "Incoming Document")
    begin
    end;
}
