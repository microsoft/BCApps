// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Device.UniversalPrint;

using System.Azure.Identity;
using System.Device;
using System.Utilities;

/// <summary>
///  Provides helper functionality related to Graph Api
/// </summary>
codeunit 2752 "Universal Print Graph Helper"
{
    /// <summary>
    /// Retrieves the list of user print shares.
    /// </summary>
    [Scope('OnPrem')]
    procedure GetPrintSharesList(var PrintShares: JsonArray; var ErrorMessage: Text): Boolean
    var
        PrintShareJsonObject: JsonObject;
        PrintShareJsonArrayToken: JsonToken;
        NextLinkJsonToken: JsonToken;
        JArrayElement: JsonToken;
        ResponseContent: Text;
        RequestURL: Text;
        MorePrintSharesExist: Boolean;
    begin
        RequestURL := this.GetGraphPrintSharesUrl();
        repeat
            if not this.InvokeRequest(RequestURL, 'GET', '', ResponseContent, ErrorMessage) then
                exit(false);

            if not PrintShareJsonObject.ReadFrom(ResponseContent) then
                exit(false);

            if not PrintShareJsonObject.SelectToken('value', PrintShareJsonArrayToken) then
                exit(false);

            if not PrintShareJsonArrayToken.IsArray() then
                exit(false);

            foreach JArrayElement in PrintShareJsonArrayToken.AsArray() do
                PrintShares.add(JArrayElement);

            MorePrintSharesExist := PrintShareJsonObject.Get('@odata.nextLink', NextLinkJsonToken);
            if MorePrintSharesExist then
                RequestURL := NextLinkJsonToken.AsValue().AsText();
        until not MorePrintSharesExist;
        exit(true);
    end;

    /// <summary>
    /// Retrieves the user print share.
    /// </summary>
    [Scope('OnPrem')]
    procedure GetPrintShare(ID: Guid; var PrintShare: JsonObject; var ErrorMessage: Text): Boolean
    var
        ResponseContent: Text;
    begin
        if not this.InvokeRequest(this.GetGraphPrintShareSelectUrl(ID), 'GET', '', ResponseContent, ErrorMessage) then
            exit(false);

        if not PrintShare.ReadFrom(ResponseContent) then
            exit(false);

        exit(true);
    end;

    /// <summary>
    /// Retrieves whether the user has license and access.
    /// </summary>
    [Scope('OnPrem')]
    procedure CheckLicense(): Boolean
    var
        ResponseContent: Text;
        ErrorMessage: Text;
        StatusCode: Integer;
    begin
        if this.InvokeRequest(this.GetGraphPrintSharesUrl(), 'GET', '', ResponseContent, ErrorMessage, StatusCode) then
            exit(true);

        if StatusCode <> 0 then
            exit(not (StatusCode in [401, 403, 404]));

        exit(false);
    end;

    [Scope('OnPrem')]
    procedure CreatePrintJobRequest(UniversalPrinterSettings: Record "Universal Printer Settings"; var JobId: Text; var DocumentId: Text; var ErrorMessage: Text): Boolean
    var
        ResponseJsonObject: JsonObject;
        BodyJsonObject: JsonObject;
        BodyConfigJsonObject: JsonObject;
        DocumentsJsonToken: JsonToken;
        Documents: JsonArray;
        DocumentJsonToken: JsonToken;
        FirstDocument: JsonObject;
        ResponseContent: Text;
    begin
        BodyConfigJsonObject.Add('outputBin', UniversalPrinterSettings."Paper Tray");
        if UniversalPrinterSettings.Landscape then
            BodyConfigJsonObject.Add('orientation', this.GetOrientationName(Enum::"Universal Printer Orientation"::landscape));

        BodyJsonObject.Add('configuration', BodyConfigJsonObject);
        if not this.InvokeRequest(this.GetGraphPrintShareJobsUrl(UniversalPrinterSettings."Print Share ID"), 'POST', Format(BodyJsonObject), ResponseContent, ErrorMessage) then
            exit(false);

        if not ResponseJsonObject.ReadFrom(ResponseContent) then
            exit(false);

        if not this.GetJsonKeyValue(ResponseJsonObject, 'id', JobId) then
            exit(false);

        if not ResponseJsonObject.SelectToken('documents', DocumentsJsonToken) then
            exit(false);

        Documents := DocumentsJsonToken.AsArray();
        if not Documents.Get(0, DocumentJsonToken) then
            exit(false);

        FirstDocument := DocumentJsonToken.AsObject();
        if not this.GetJsonKeyValue(FirstDocument, 'id', DocumentId) then
            exit(false);

        exit(true);
    end;

    local procedure GetOrientationName(Orientation: Enum "Universal Printer Orientation"): Text
    begin
        exit(Orientation.Names.Get(Orientation.Ordinals.IndexOf(Orientation.AsInteger())));
    end;

    procedure CreateUploadSessionRequest(PrintShareId: Text; FileName: Text; DocumentType: Text; Size: BigInteger; JobId: Text; DocumentId: Text; var UploadUrl: Text; var ErrorMessage: Text): Boolean
    var
        BodyPropertiesJsonObject: JsonObject;
        BodyJsonObject: JsonObject;
        ResponseContent: Text;
        ResponseJsonObject: JsonObject;
    begin
        FileName := JobId + '_' + FileName;
        BodyPropertiesJsonObject.Add('documentName', FileName);
        BodyPropertiesJsonObject.Add('contentType', DocumentType);
        BodyPropertiesJsonObject.Add('size', Size);
        BodyJsonObject.Add('properties', BodyPropertiesJsonObject);

        if not this.InvokeRequest(this.GetGraphDocumentCreateUploadSessionUrl(PrintShareId, JobId, DocumentId), 'POST', Format(BodyJsonObject), ResponseContent, ErrorMessage) then
            exit(false);

        if not ResponseJsonObject.ReadFrom(ResponseContent) then
            exit(false);

        if not this.GetJsonKeyValue(ResponseJsonObject, 'uploadUrl', UploadUrl) then
            exit(false);

        exit(true);
    end;

    procedure UploadDataRequest(PrintShareId: Text; UploadUrl: Text; TempBlob: Codeunit "Temp Blob"; From: BigInteger; "To": BigInteger; TotalSize: BigInteger; JobId: Text; DocumentId: Text; var ErrorMessage: Text): Boolean
    var
        HttpContent: HttpContent;
        HttpContentHeaders: HttpHeaders;
        HttpRequestMessage: HttpRequestMessage;
        BlobInStream: InStream;
        StatusCode: Integer;
        ContentRange: Text;
        ResponseContent: Text;
    begin
        if not this.InitializeRequest(UploadUrl, 'PUT', HttpRequestMessage) then
            exit(false);

        // E.g. value for 'Content-Range' is 'bytes 0-72796/4533322'
        // Content-Length is computed by the platform from the request body.
        ContentRange := 'bytes ' + Format(From) + '-' + Format("To") + '/' + Format(TotalSize);
        TempBlob.CreateInStream(BlobInStream);
        HttpContent.WriteFrom(BlobInStream);
        HttpContent.GetHeaders(HttpContentHeaders);
        HttpContentHeaders.Remove('Content-Type');
        HttpContentHeaders.Add('Content-Type', 'application/xml');
        HttpContentHeaders.Add('Content-Range', ContentRange);
        HttpRequestMessage.Content(HttpContent);

        exit(this.InvokeRequestAndReadResponse(HttpRequestMessage, ResponseContent, ErrorMessage, StatusCode));
    end;

    procedure StartPrintJobRequest(PrintShareId: Text; JobId: Text; var JobStateDescription: Text; var ErrorMessage: Text): Boolean
    var
        ResponseJsonObject: JsonObject;
        ResponseContent: Text;
    begin
        if not this.InvokeRequest(this.GetGraphStartPrintJobUrl(PrintShareId, JobId), 'POST', '', ResponseContent, ErrorMessage) then
            exit(false);

        if not ResponseJsonObject.ReadFrom(ResponseContent) then
            exit(false);

        if not this.GetJsonKeyValue(ResponseJsonObject, 'description', JobStateDescription) then
            exit(false);

        exit(true);
    end;

    procedure GetJsonKeyValue(var JObject: JsonObject; KeyName: Text; var KeyValue: Text): Boolean
    var
        JToken: JsonToken;
    begin
        if not JObject.Get(KeyName, JToken) then
            exit(false);

        KeyValue := JToken.AsValue().AsText();
        exit(true);
    end;

    [TryFunction]
    internal procedure TryGetAccessToken(var AccessToken: SecretText; ShowDialog: Boolean)
    var
        AzureADMgt: Codeunit "Azure AD Mgt.";
    begin
        AccessToken := AzureADMgt.GetAccessTokenAsSecretText(this.GetGraphDomain(), '', ShowDialog);
        if AccessToken.IsEmpty() then begin
            Session.LogMessage('0000EFG', this.NoTokenTelemetryTxt, Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', this.UniversalPrintTelemetryCategoryTxt);
            Error(this.UserNotAuthenticatedTxt);
        end;
    end;

    local procedure InvokeRequest(Url: Text; Verb: Text; Body: Text; var ResponseContent: Text; var ErrorMessage: Text): Boolean
    var
        StatusCode: Integer;
    begin
        exit(InvokeRequest(Url, Verb, Body, ResponseContent, ErrorMessage, StatusCode));
    end;

    local procedure InvokeRequest(Url: Text; Verb: Text; Body: Text; var ResponseContent: Text; var ErrorMessage: Text; var StatusCode: Integer): Boolean
    var
        HttpContent: HttpContent;
        HttpContentHeaders: HttpHeaders;
        HttpRequestMessage: HttpRequestMessage;
    begin
        if not this.InitializeRequest(Url, Verb, HttpRequestMessage) then
            exit(false);

        if Verb <> 'GET' then begin
            HttpContent.WriteFrom(Body);
            HttpContent.GetHeaders(HttpContentHeaders);
            HttpContentHeaders.Remove('Content-Type');
            HttpContentHeaders.Add('Content-Type', 'application/json');
            HttpRequestMessage.Content(HttpContent);
        end;

        exit(this.InvokeRequestAndReadResponse(HttpRequestMessage, ResponseContent, ErrorMessage, StatusCode));
    end;

    local procedure InvokeRequestAndReadResponse(var HttpRequestMessage: HttpRequestMessage; var ResponseContent: Text; var ErrorMessage: Text; var StatusCode: Integer): Boolean
    var
        CustomDimensions: Dictionary of [Text, Text];
        HttpClient: HttpClient;
        HttpResponseMessage: HttpResponseMessage;
        RequestId: Text;
        ResponseErrorDetails: Text;
        ResponseErrorMessage: Text;
        TraceId: Text;
    begin
        Clear(StatusCode);
        Clear(ResponseContent);
        RequestId := this.NotFoundTelemetryTxt;
        TraceId := this.NotFoundTelemetryTxt;

        if HttpClient.Send(HttpRequestMessage, HttpResponseMessage) then begin
            StatusCode := HttpResponseMessage.HttpStatusCode();
            if HttpResponseMessage.IsSuccessStatusCode() then begin
                HttpResponseMessage.Content.ReadAs(ResponseContent);
                exit(true);
            end;

            HttpResponseMessage.Content.ReadAs(ResponseErrorDetails);
            ResponseErrorMessage := StrSubstNo(this.HttpErrorStatusErr, StatusCode, HttpResponseMessage.ReasonPhrase());
            RequestId := this.GetResponseHeaderValue(HttpResponseMessage, 'Request-Id');
            TraceId := this.GetResponseHeaderValue(HttpResponseMessage, 'X-MSEdge-Ref');
        end else
            ResponseErrorMessage := GetLastErrorText();

        CustomDimensions.Add('Category', this.UniversalPrintTelemetryCategoryTxt);
        CustomDimensions.Add('ErrorText', ResponseErrorMessage);
        Session.LogMessage('0000EG1', StrSubstNo(this.InvokeWebRequestFailedTelemetryTxt, StatusCode, RequestId, TraceId),
            Verbosity::Error, DataClassification::CustomerContent, TelemetryScope::ExtensionPublisher, CustomDimensions);

        Clear(ErrorMessage);
        if StatusCode in [401, 403, 404] then begin
            ErrorMessage := this.NoAccessTxt;
            exit(false);
        end;

        if ErrorMessage = '' then
            ErrorMessage := this.GetMessageFromErrorJSON(ResponseErrorDetails);

        if ErrorMessage = '' then
            ErrorMessage := ResponseErrorMessage;

        exit(false);
    end;

    local procedure GetResponseHeaderValue(var HttpResponseMessage: HttpResponseMessage; HeaderName: Text): Text
    var
        HeaderValues: List of [Text];
    begin
        if HttpResponseMessage.Headers().Contains(HeaderName) then
            if HttpResponseMessage.Headers().GetValues(HeaderName, HeaderValues) then
                if HeaderValues.Count() > 0 then
                    exit(HeaderValues.Get(1));

        exit(this.NotFoundTelemetryTxt);
    end;

    internal procedure GetPaperSizeFromUniversalPrintMediaSize(textValue: Text): Enum "Printer Paper Kind"
    var
        PrinterPaperKind: Enum "Printer Paper Kind";
        OrdinalValue: Integer;
        Index: Integer;
    begin
        // For universal print supported media sizes, refer https://learn.microsoft.com/en-us/graph/api/resources/printercapabilities?view=graph-rest-1.0#mediasizes-values
        case textValue of
            JPNHagakiSizeTxt:
                PrinterPaperKind := Enum::"Printer Paper Kind"::JapanesePostcard;
            NorthAmericaExecutiveSizeTxt:
                PrinterPaperKind := PrinterPaperKind::Executive;
            NorthAmericaLedgerSizeTxt:
                PrinterPaperKind := PrinterPaperKind::Ledger;
            NorthAmericaLegalSizeTxt:
                PrinterPaperKind := PrinterPaperKind::Legal;
            NorthAmericaLetterSizeTxt:
                PrinterPaperKind := PrinterPaperKind::Letter;
            NorthAmericaInvoiceSizeTxt:
                PrinterPaperKind := PrinterPaperKind::Statement;
            else begin
                Index := PrinterPaperKind.Names.IndexOf(textValue);
                if Index = 0 then
                    exit(Enum::"Printer Paper Kind"::A4);

                OrdinalValue := PrinterPaperKind.Ordinals.Get(Index);
                PrinterPaperKind := Enum::"Printer Paper Kind".FromInteger(OrdinalValue);
            end;
        end;
        exit(PrinterPaperKind);
    end;

    local procedure GetMessageFromErrorJSON(ErrorResponseContent: Text): Text
    var
        ResponseJsonObject: JsonObject;
        PropertyBag: JsonToken;
        ErrorJsonObject: JsonObject;
        MessageValue: Text;
    begin
        if ErrorResponseContent = '' then
            exit;

        if not ResponseJsonObject.ReadFrom(ErrorResponseContent) then
            exit;

        if not ResponseJsonObject.Get('error', PropertyBag) then
            exit;

        ErrorJsonObject := PropertyBag.AsObject();
        if this.GetJsonKeyValue(ErrorJsonObject, 'message', MessageValue) then
            exit(MessageValue);
    end;

    [NonDebuggable]
    local procedure InitializeRequest(Url: Text; Verb: Text; var HttpRequestMessage: HttpRequestMessage): Boolean
    var
        HttpHeaders: HttpHeaders;
        AccessToken: SecretText;
    begin
        if not this.TryGetAccessToken(AccessToken, false) then
            exit(false);
        HttpRequestMessage.Method(Verb);
        HttpRequestMessage.SetRequestUri(Url);
        HttpRequestMessage.GetHeaders(HttpHeaders);
        HttpHeaders.Add('Accept', 'application/json');
        HttpHeaders.Add('Authorization', SecretStrSubstNo('Bearer %1', AccessToken));
        exit(true);
    end;

    procedure GetUniversalPrintTelemetryCategory(): Text
    begin
        exit(this.UniversalPrintTelemetryCategoryTxt);
    end;

    procedure GetUniversalPrintFeatureTelemetryName(): Text
    begin
        exit(this.UniversalPrintFeatureTelemetryNameTxt);
    end;

    procedure GetUniversalPrintPortalUrl(): Text
    begin
        exit(this.UniversalPrintPortalUrlTxt);
    end;

    local procedure GetGuidAsString(GuidValue: Guid): Text
    begin
        // Converts guid to string
        // Example: Converts {21EC2020-3AEA-4069-A2DD-08002B30309D} to 21ec2020-3aea-4069-a2dd-08002b30309d
        exit(LowerCase(Format(GuidValue, 0, 4)));
    end;

    local procedure GetGraphDomain(): Text
    var
        UrlHelper: Codeunit "Url Helper";
        Domain: Text;
    begin
        Domain := UrlHelper.GetGraphUrl();
        if Domain <> '' then
            exit(Domain);

        exit('https://graph.microsoft.com/');
    end;

    local procedure GetGraphAPIVersion(): Text
    begin
        exit('v1.0');
    end;

    local procedure GetGraphPrintSharesUrl(): Text
    begin
        // https://graph.microsoft.com/v1.0/print/shares/?$top=1000
        // NOTE: by default universal print returns 10 records only, which is too low for some customers.
        exit(this.GetGraphDomain() + this.GetGraphAPIVersion() + '/print/shares/?$top=1000');
    end;

    local procedure GetGraphPrintShareSelectUrl(PrintShareID: Text): Text
    begin
        // https://graph.microsoft.com/v1.0/print/shares/{PrintShareID}?$select=id,displayName,defaults,capabilities
        exit(this.GetGraphDomain() + this.GetGraphAPIVersion() + '/print/shares/' + this.GetGuidAsString(PrintShareID) + '?$select=id,displayName,defaults,capabilities');
    end;

    local procedure GetGraphPrintShareUrl(PrintShareID: Text): Text
    begin
        // https://graph.microsoft.com/v1.0/print/shares/{PrintShareID}
        exit(this.GetGraphDomain() + this.GetGraphAPIVersion() + '/print/shares/' + this.GetGuidAsString(PrintShareID));
    end;

    local procedure GetGraphPrintShareJobsUrl(PrintShareID: Text): Text
    begin
        // https://graph.microsoft.com/v1.0/print/shares/{PrintShareID}/jobs
        exit(this.GetGraphPrintShareUrl(this.GetGuidAsString(PrintShareID)) + '/jobs');
    end;

    local procedure GetGraphDocumentCreateUploadSessionUrl(PrintShareID: Text; PrintJobID: Text; PrintDocumentID: Text): Text
    begin
        // https://graph.microsoft.com/v1.0/print/shares/{PrintShareID}/jobs/{PrintJobID}/documents/{PrintDocumentID}/createUploadSession'
        exit(this.GetGraphPrintShareJobsUrl(this.GetGuidAsString(PrintShareID)) + '/' + PrintJobID + '/documents/' + PrintDocumentID + '/createUploadSession');
    end;

    local procedure GetGraphStartPrintJobUrl(PrintShareID: Text; PrintJobID: Text): Text
    begin
        // https://graph.microsoft.com/v1.0/print/shares/{PrintShareID}/jobs/{PrintJobID}/start
        exit(this.GetGraphPrintShareJobsUrl(this.GetGuidAsString(PrintShareID)) + '/' + PrintJobID + '/start');
    end;

    var
        UserNotAuthenticatedTxt: Label 'User cannot be authenticated with Microsoft Entra.';
        NoAccessTxt: Label 'You don''t have access to the data. Make sure your account has been assigned a Universal Print license and you have the required permissions.';
        UniversalPrintTelemetryCategoryTxt: Label 'Universal Print AL', Locked = true;
        UniversalPrintFeatureTelemetryNameTxt: Label 'Universal Print', Locked = true;
        NoTokenTelemetryTxt: Label 'Access token could not be retrieved.', Locked = true;
        InvokeWebRequestFailedTelemetryTxt: Label 'Invoking web request has failed. Status %1, RequestId %2, TraceId %3', Locked = true;
        NotFoundTelemetryTxt: Label 'Not Found.', Locked = true;
        HttpErrorStatusErr: Label 'The remote service returned an error: (%1) %2.', Comment = '%1 = HTTP status code, for example 500; %2 = HTTP reason phrase, for example Internal Server Error';
        UniversalPrintPortalUrlTxt: Label 'https://go.microsoft.com/fwlink/?linkid=2153618', Locked = true;
        JPNHagakiSizeTxt: Label 'JPN Hagaki', Locked = true;
        NorthAmericaExecutiveSizeTxt: Label 'North America Executive', Locked = true;
        NorthAmericaInvoiceSizeTxt: Label 'North America Invoice', Locked = true;
        NorthAmericaLedgerSizeTxt: Label 'North America Ledger', Locked = true;
        NorthAmericaLegalSizeTxt: Label 'North America Legal', Locked = true;
        NorthAmericaLetterSizeTxt: Label 'North America Letter', Locked = true;
}

