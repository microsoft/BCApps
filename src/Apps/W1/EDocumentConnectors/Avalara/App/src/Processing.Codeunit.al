// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocumentConnector.Avalara;

using Microsoft.EServices.EDocument;
using Microsoft.eServices.EDocument.Integration;
using Microsoft.eServices.EDocument.Integration.Receive;
using Microsoft.eServices.EDocument.Integration.Send;
using Microsoft.EServices.EDocumentConnector.Avalara.Models;

using System.Utilities;

codeunit 6379 Processing
{
    Access = Internal;
    Permissions = tabledata "Connection Setup" = rm,
                  tabledata "E-Document" = m,
                  tabledata "E-Document Service Status" = m;

    /// <summary>
    /// Call Avalara Shared API for list of companies
    /// </summary>
    /// <param name="AvalaraCompany">Records to contain returned compaines.</param>
    procedure GetCompanyList(var AvalaraCompany: Record "Avalara Company" temporary)
    var
        HttpExecutor: Codeunit "Http Executor";
        Request: Codeunit Requests;
        ResponseContent: Text;
    begin
        Request.Init();
        Request.Authenticate().CreateGetCompaniesRequest();
        ResponseContent := HttpExecutor.ExecuteHttpRequest(Request);

        ParseCompanyList(AvalaraCompany, ResponseContent);
    end;

    /// <summary>
    /// Call Avalara Shared API for list of companies
    /// </summary>
    /// <param name="AvalaraCompany">Records to contain returned compaines.</param>
    procedure GetRegistrationList(): Text;
    var
        TempAvalaraCompany: Record "Avalara Company" temporary;
        HttpExecutor: Codeunit "Http Executor";
        Request: Codeunit Requests;
        ResponseContent: Text;
    begin
        Request.Init();
        Request.Authenticate().CreateGetRegistrationsRequest(TempAvalaraCompany);
        ResponseContent := HttpExecutor.ExecuteHttpRequest(Request);
        exit(ResponseContent);
    end;

    /// <summary>
    /// Let user pick Avalara company for connection setup.
    /// </summary>
    procedure UpdateCompanyId(ConnectionSetup: Record "Connection Setup")
    var
        AvalaraCompanyList: Page "Company List";
    begin
        if TempAvalaraCompanies.IsEmpty() then
            GetCompanyList(TempAvalaraCompanies);

        Commit();
        AvalaraCompanyList.SetRecords(TempAvalaraCompanies);
        AvalaraCompanyList.LookupMode(true);
        if AvalaraCompanyList.RunModal() = Action::LookupOK then begin
            AvalaraCompanyList.GetRecord(TempAvalaraCompanies);
            ConnectionSetup.Get();
            ConnectionSetup."Company Id" := TempAvalaraCompanies."Company Id";
            ConnectionSetup."Company Name" := TempAvalaraCompanies."Company Name";
            ConnectionSetup.Modify();
        end
    end;

    /// <summary>
    /// Let user select Avalara Mandate for e-document service
    /// </summary>
    procedure UpdateMandate(var MandateSelected: Text)
    var
        EDocService: Record "E-Document Service";
        EDocumentServices: Page "E-Document Services";
        MandateList: Page "Mandate List";
    begin
        Commit();
        EDocService.SetRange("Service Integration V2", Enum::"Service Integration"::Avalara);
        EDocumentServices.SetTableView(EDocService);
        EDocumentServices.LookupMode := true;
        EDocumentServices.Caption(AvalaraPickMandateMsg);
        if EDocumentServices.RunModal() <> Action::LookupOK then
            exit;

        EDocumentServices.GetRecord(EDocService);

        if TempMandates.IsEmpty() then
            GetMandates(TempMandates);

        MandateList.SetTempRecords(TempMandates);
        MandateList.LookupMode(true);
        if MandateList.RunModal() <> Action::LookupOK then
            exit;

        MandateList.GetRecord(TempMandates);
        EDocService."Avalara Mandate" := TempMandates."Country Mandate";
        MandateSelected := TempMandates."Country Mandate";
        EDocService.Modify();
    end;

    /// <summary>
    /// Calls Avalara API for SubmitDocument.
    /// </summary>
    procedure SendEDocument(var EDocument: Record "E-Document"; var EDocumentService: Record "E-Document Service"; SendContext: Codeunit SendContext)
    var
        ActivationMandate: Record "Activation Mandate";
        ConnectionSetup: Record "Connection Setup";
        HttpExecutor: Codeunit "Http Executor";
        MetaData: Codeunit Metadata;
        Request: Codeunit Requests;
        TempBlob: Codeunit "Temp Blob";
        InStream: InStream;
        AvalaraMandate: Text;
        MandateType: Text;
        RequestContent: Text;
        ResponseContent: Text;
    begin
        if not ConnectionSetup.Get() then
            exit;

        TempBlob := SendContext.GetTempBlob();
        AvalaraMandate := EDocumentService."Avalara Mandate";
        MandateType := GetMandateTypeFromName(AvalaraMandate);
        ActivationMandate.SetRange("Company Id", ConnectionSetup."Company Id");
        ActivationMandate.SetRange("Country Mandate", AvalaraMandate);
        ActivationMandate.SetRange("Mandate Type", MandateType);

        if ActivationMandate.IsEmpty() then begin
            EDocumentErrorHelper.LogSimpleErrorMessage(EDocument, MandateNotFoundErr);
            exit;
        end;

        ActivationMandate.FindFirst();

        if not ActivationMandate.Activated then begin
            EDocumentErrorHelper.LogSimpleErrorMessage(EDocument, MandateNotCompleteErr);
            exit;
        end;

        if ActivationMandate.Blocked then begin
            EDocumentErrorHelper.LogSimpleErrorMessage(EDocument, MandateBlockedErr);
            exit;
        end;

        MetaData.SetWorkflowId(WorkflowIdTok).SetDataFormat(DataFormatInvoiceTok).SetDataFormatVersion(DataFormatVersionTok);
        case EDocument."Document Type" of
            Enum::"E-Document Type"::"Sales Credit Memo",
            Enum::"E-Document Type"::"Service Credit Memo":
                MetaData.SetDataFormat(DataFormatCreditNoteTok);
        end;

        SetMandateForMetaData(EDocumentService, MetaData);

        TempBlob.CreateInStream(InStream, TextEncoding::UTF8);
        InStream.Read(RequestContent);

        Request.Init();
        Request.Authenticate().CreateSubmitDocumentRequest(MetaData, RequestContent);
        ResponseContent := HttpExecutor.ExecuteHttpRequest(Request);
        SendContext.Http().SetHttpRequestMessage(Request.GetRequest());
        SendContext.Http().SetHttpResponseMessage(HttpExecutor.GetResponse());

        EDocument.Get(EDocument."Entry No");
        EDocument."Avalara Document Id" := ParseDocumentId(ResponseContent);
        EDocument.Modify(true);
    end;

    /// <summary>
    /// Calls Avalara API for GetDocumentStatus.
    /// If request is successful, but status is Error, then errors are logged and error is thrown to set document to Sending Error state
    /// </summary>
    /// <returns>False if status is Pending, True if status is Complete.</returns>
    procedure GetDocumentStatus(var EDocument: Record "E-Document"; SendContext: Codeunit SendContext): Boolean
    var
        HttpExecutor: Codeunit "Http Executor";
        Request: Codeunit Requests;
        ResponseContent: Text;
    begin
        EDocument.TestField("Avalara Document Id");

        Request.Init();
        Request.Authenticate().CreateGetDocumentStatusRequest(EDocument."Avalara Document Id");
        ResponseContent := HttpExecutor.ExecuteHttpRequest(Request);
        SendContext.Http().SetHttpRequestMessage(Request.GetRequest());
        SendContext.Http().SetHttpResponseMessage(HttpExecutor.GetResponse());
        exit(ParseGetDocumentStatusResponse(EDocument, ResponseContent));
    end;

    /// <summary>
    /// Lookup documents for last XX days.
    /// </summary>
    procedure ReceiveDocuments(var EDocumentService: Record "E-Document Service"; ReceivedEDocuments: Codeunit "Temp Blob List"; ReceiveContext: Codeunit ReceiveContext)
    var
        TempBlob: Codeunit "Temp Blob";
        HttpRequest: HttpRequestMessage;
        HttpResponse: HttpResponseMessage;
        I: Integer;
        Response: JsonArray;
        OutStream: OutStream;
    begin
        Response := ReceiveDocumentInner(TempBlob, HttpRequest, HttpResponse, AvalaraGetDocsPathTxt);
        ReceiveContext.Http().SetHttpRequestMessage(HttpRequest);
        ReceiveContext.Http().SetHttpResponseMessage(HttpResponse);

        RemoveExistingDocumentsFromResponse(Response);
        for I := 1 to Response.Count() do begin
            Clear(TempBlob);
            TempBlob.CreateOutStream(OutStream, TextEncoding::UTF8);
            OutStream.Write(Response.GetText(I - 1));
            ReceivedEDocuments.Add(TempBlob);
        end;
    end;

    /// <summary>
    /// Recursive function to keep following next link from API.
    /// Ensures we get all documents within Start and End time that we requested.
    /// </summary>
    /// <returns>List of Json Objects with data about document that belong to selected avalara company.</returns>
    procedure ReceiveDocumentInner(var TempBlob: Codeunit "Temp Blob"; HttpRequest: HttpRequestMessage; HttpResponse: HttpResponseMessage; Path: Text): JsonArray
    var
        ConnectionSetup: Record "Connection Setup";
        HttpExecutor: Codeunit "Http Executor";
        Request: Codeunit Requests;
        Values: JsonArray;
        DocObject,
        ResponseJson : JsonObject;
        CompanyId,
        ValueJson,
ValueObject : JsonToken;
        NextLink: Text;
        ResponseContent: Text;
    begin
        if Path = '' then
            exit; // Stop recursion

        Request.Init();
        Request.Authenticate().CreateReceiveDocumentsRequest(Path);
        HttpRequest := Request.GetRequest();
        ResponseContent := HttpExecutor.ExecuteHttpRequest(Request, HttpResponse);

        ResponseJson.ReadFrom(ResponseContent);

        ResponseJson.Get(JsonFieldNextLinkTok, ValueJson);
        if not ValueJson.AsValue().IsNull() then
            NextLink := ValueJson.AsValue().AsText();
        if NextLink <> '' then begin
            Path := NextLink.Substring(StrLen(Request.GetBaseUrl()) + 1);
            Values := ReceiveDocumentInner(TempBlob, HttpRequest, HttpResponse, Path);
        end;

        // No more pagination.
        // Accumulate results
        ConnectionSetup.Get();
        ResponseJson.Get(JsonFieldValueTok, ValueJson);
        if ValueJson.IsArray then
            foreach ValueObject in ValueJson.AsArray() do begin
                DocObject := ValueObject.AsObject();
                DocObject.Get(JsonFieldCompanyIdTok, CompanyId);
                if ConnectionSetup."Company Id" = CompanyId.AsValue().AsText() then
                    Values.Add(DocObject);
            end;

        exit(Values);
    end;

    /// <summary>
    /// Download document XML from Avalara API
    /// </summary>
    procedure DownloadDocument(var EDocument: Record "E-Document"; var EDocumentService: Record "E-Document Service"; DocumentMetadata: Codeunit "Temp Blob"; ReceiveContext: Codeunit ReceiveContext)
    var
        AvalaraFunctions: Codeunit "Avalara Functions";
        HttpExecutor: Codeunit "Http Executor";
        Request: Codeunit Requests;
        InStream: InStream;
        MediaTypes: List of [Text];
        OutStream: OutStream;
        CountryCode: Text;
        DocumentId: Text;
        Mandate: Text;
        ResponseContent: Text;
    begin
        Mandate := EDocumentService."Avalara Mandate";
        CountryCode := Mandate.Split('-').Get(1);
        MediaTypes := AvalaraFunctions.GetAvailableMediaTypesForMandate(Mandate);

        DocumentMetadata.CreateInStream(InStream, TextEncoding::UTF8);
        InStream.ReadText(DocumentId);

        if DocumentId = '' then begin
            EDocumentErrorHelper.LogSimpleErrorMessage(EDocument, DocumentIdNotFoundErr);
            exit;
        end;

        EDocument."Avalara Document Id" := CopyStr(DocumentId, 1, MaxStrLen(EDocument."Avalara Document Id"));
        EDocument.Modify();

        Request.Init();
        Request.Authenticate().CreateDownloadRequest(DocumentId);
        ResponseContent := HttpExecutor.ExecuteHttpRequest(Request);
        ReceiveContext.Http().SetHttpRequestMessage(Request.GetRequest());
        ReceiveContext.Http().SetHttpResponseMessage(HttpExecutor.GetResponse());

        ReceiveContext.GetTempBlob().CreateOutStream(OutStream, TextEncoding::UTF8);
        OutStream.WriteText(ResponseContent);
    end;

    /// <summary>
    /// Remove document ids from array that are already created as E-Documents.
    /// </summary>
    local procedure RemoveExistingDocumentsFromResponse(var Documents: JsonArray)
    var
        I: Integer;
        NewArray: JsonArray;
        DocumentId: Text;
    begin
        for I := 0 to Documents.Count() - 1 do begin
            DocumentId := GetDocumentIdFromArray(Documents, I);
            if not DocumentExists(DocumentId) then
                NewArray.Add(DocumentId);
        end;
        Documents := NewArray;
    end;

    /// <summary>
    /// Check if E-Document with Document Id exists in E-Document table
    /// </summary>
    local procedure DocumentExists(DocumentId: Text): Boolean
    var
        EDocument: Record "E-Document";
    begin
        EDocument.SetRange("Avalara Document Id", DocumentId);
        exit(not EDocument.IsEmpty());
    end;

    /// <summary>
    /// Takes "Avalara Mandate" and computes country code and mandate
    /// </summary>
    local procedure SetMandateForMetaData(EDocumentService: Record "E-Document Service"; var Metadata: Codeunit Metadata)
    var
        County,
        Mandate : Text;
    begin
        EDocumentService.TestField("Avalara Mandate");
        Mandate := EDocumentService."Avalara Mandate";
        County := Mandate.Split('-').Get(1);
        Metadata.SetCountry(County).SetMandate(Mandate);
    end;

    /// <summary>
    /// Create and send http call for mandates and parse response to mandate table
    /// </summary>
    local procedure GetMandates(var TempMandatesLocal: Record Mandate temporary)
    var
        HttpExecutor: Codeunit "Http Executor";
        Request: Codeunit Requests;
        ResponseContent: Text;
    begin
        Request.Init();
        Request.Authenticate().CreateGetMandates();
        ResponseContent := HttpExecutor.ExecuteHttpRequest(Request);

        ParseMandates(TempMandatesLocal, ResponseContent, false);
    end;

    procedure GetSingleMandate(var TempMandatesLocal: Record Mandate temporary; MandateText: Text)
    var
        HttpExecutor: Codeunit "Http Executor";
        Request: Codeunit Requests;
        ResponseContent: Text;

    begin
        Request.Init();

        Request.Authenticate().CreateGetMandates(MandateText);
        ResponseContent := HttpExecutor.ExecuteHttpRequest(Request);

        ParseMandates(TempMandatesLocal, ResponseContent, true);
    end;

    /// <summary>
    /// Parse mandates from json into table
    /// </summary>
    local procedure ParseMandates(var TempMandatesLocal: Record Mandate temporary; ResponseContent: Text; ShouldParseFields: Boolean)
    var
        Processing: Codeunit Processing;
        InputFormatsArray: JsonArray;
        FormatObj: JsonObject;
        ResponseJson: JsonObject;
        FormatToken,
        MandateToken,
        ParsintToken,
        ValueToken,
        VersionItem,
        VersionToken : JsonToken;
        CountryCode,
        CountryMandate,
        CreditFormatStr,
        Description,
        FormatName,
        InvoiceFormatStr,
        VersionValue : Text;
    begin
        ResponseJson.ReadFrom(ResponseContent);
        ResponseJson.Get(JsonFieldValueTok, ValueToken);

        Clear(TempMandatesLocal);
        foreach MandateToken in ValueToken.AsArray() do begin
            MandateToken.AsObject().Get(JsonFieldCountryMandateTok, ParsintToken);
            CountryMandate := ParsintToken.AsValue().AsText();
            MandateToken.AsObject().Get(JsonFieldCountryCodeTok, ParsintToken);
            CountryCode := ParsintToken.AsValue().AsText();
            MandateToken.AsObject().Get(JsonFieldDescriptionTok, ParsintToken);
            Description := ParsintToken.AsValue().AsText();
            MandateToken.AsObject().Get(JsonFieldInputDataFormatsTok, ParsintToken);
            InputFormatsArray := ParsintToken.AsArray();
            foreach FormatToken in InputFormatsArray do begin
                FormatObj := FormatToken.AsObject();
                if FormatObj.Get(JsonFieldFormatTok, VersionToken) then begin
                    FormatName := VersionToken.AsValue().AsText();
                    if FormatObj.Get(JsonFieldVersionsTok, VersionToken) then
                        foreach VersionItem in VersionToken.AsArray() do begin
                            VersionValue := VersionItem.AsValue().AsText();
                            if ShouldParseFields then
                                Processing.GetInvoiceFieldsForMandate(CountryMandate, FormatName, VersionValue);

                            if FormatName.Contains('invoice') then
                                InvoiceFormatStr := VersionValue;

                            if FormatName.Contains('creditnote') then
                                CreditFormatStr := VersionValue;
                        end;
                end;
            end;

            if StrLen(CountryMandate) > MaxStrLen(TempMandatesLocal."Country Mandate") then
                Error(AvalaraCountryMandateLongerErr);

            if StrLen(CountryCode) > MaxStrLen(TempMandatesLocal."Country Code") then
                Error(AvalaraCountryMandateCodeErr);

            if StrLen(Description) > MaxStrLen(TempMandatesLocal.Description) then
                Error(AvalaraCountryMandateDescLongerErr);

            if not ShouldParseFields then begin
                TempMandatesLocal.Init();
                TempMandatesLocal."Country Mandate" := CopyStr(CountryMandate, 1, MaxStrLen(TempMandatesLocal."Country Mandate"));
                TempMandatesLocal."Country Code" := CopyStr(CountryCode, 1, MaxStrLen(TempMandatesLocal."Country Code"));
                TempMandatesLocal.Description := CopyStr(Description, 1, MaxStrLen(TempMandatesLocal.Description));
                TempMandatesLocal."Invoice Format" := CopyStr(InvoiceFormatStr, 1, MaxStrLen(TempMandatesLocal."Invoice Format"));
                TempMandatesLocal."Credit Note Format" := CopyStr(CreditFormatStr, 1, MaxStrLen(TempMandatesLocal."Credit Note Format"));
                TempMandatesLocal.Insert(true);
            end;
        end;
    end;

    procedure GetInvoiceFieldsForMandate(Mandate: Text; DocumentType: Text; DocumentVersion: Text)
    var
        Request: Codeunit Requests;
        HttpClient: HttpClient;
        Response: HttpResponseMessage;
        //HttpExecutor: Codeunit "Http Executor";
        ResponseContent: Text;

    begin
        Request.Init();
        Request.Authenticate().CreateGetFields(Mandate, DocumentType, DocumentVersion);
        HttpClient.Send(Request.GetRequest(), Response);
        Response.Content.ReadAs(ResponseContent);
        if Response.HttpStatusCode = 200 then
            ParseFields(ResponseContent, Mandate, DocumentType, DocumentVersion);
    end;

    local procedure ParseFields(ResponseContent: Text; Mandate: Text; DocumentType: Text; DocumentVersion: Text)
    var
        AvalaraFunctions: Codeunit "Avalara Functions";
        ResponseJsonArray: JsonArray;
    begin
        ResponseJsonArray.ReadFrom(ResponseContent);
        AvalaraFunctions.LoadFieldsFromJson(ResponseJsonArray, CopyStr(Mandate, 1, 40), documentType, documentVersion);
    end;

    /// <summary>
    /// Parse companies from json into table
    /// </summary>
    local procedure ParseCompanyList(var AvalaraCompany: Record "Avalara Company" temporary; ResponseContent: Text)
    var
        Id: Integer;
        ResponseJson: JsonObject;
        CompanyJson,
ParsintToken,
        ValueJson : JsonToken;
        CompanyId, CompanyName : Text;
    begin
        ResponseJson.ReadFrom(ResponseContent);
        ResponseJson.Get(JsonFieldValueTok, ValueJson);

        Id := 1;
        foreach CompanyJson in ValueJson.AsArray() do begin
            Clear(AvalaraCompany);
            AvalaraCompany.Init();
            AvalaraCompany.Id := Id;
            CompanyJson.AsObject().Get(JsonFieldIdTok, ParsintToken);
            CompanyId := ParsintToken.AsValue().AsText();
            CompanyJson.AsObject().Get(JsonFieldCompanyNameTok, ParsintToken);
            CompanyName := ParsintToken.AsValue().AsText();

            if StrLen(CompanyId) > MaxStrLen(AvalaraCompany."Company Id") then
                Error(AvalaraCountryIdLongerErr);

            if StrLen(CompanyName) > MaxStrLen(AvalaraCompany."Company Name") then
                Error(AvaralaCountryNameLongerErr);

            AvalaraCompany."Company Id" := CopyStr(CompanyId, 1, MaxStrLen(AvalaraCompany."Company Id"));
            AvalaraCompany."Company Name" := CopyStr(CompanyName, 1, MaxStrLen(AvalaraCompany."Company Name"));
            AvalaraCompany.Insert(true);
            Id += 1;
        end;
    end;

    /// <summary>
    /// Parse company id
    /// </summary>
    local procedure ParseDocumentId(ResponseMsg: Text): Text[50]
    var
        ResponseJson: JsonObject;
        ValueJson: JsonToken;
        DocumentId: Text;
    begin
        ResponseJson.ReadFrom(ResponseMsg);
        ResponseJson.Get(JsonFieldIdTok, ValueJson);

        DocumentId := ValueJson.AsValue().AsText();
        if StrLen(DocumentId) > 50 then
            Error(AvalaraIdLongerErr);

        exit(CopyStr(DocumentId, 1, 50));
    end;

    /// <summary>
    /// Parse Document Response. If erros log all events
    /// </summary>
    local procedure ParseGetDocumentStatusResponse(var EDocument: Record "E-Document"; ResponseMsg: Text): Boolean
    var
        Events: JsonArray;
        EventObject,
        ResponseJson : JsonObject;
        EventToken,
MessageToken,
        ValueJson : JsonToken;
    begin
        ResponseJson.ReadFrom(ResponseMsg);
        ResponseJson.Get(JsonFieldIdTok, ValueJson);
        if EDocument."Avalara Document Id" <> ValueJson.AsValue().AsText() then
            Error(IncorrectDocumentIdInResponseErr);

        if ResponseJson.Get(JsonFieldEventsTok, ValueJson) then
            Events := ValueJson.AsArray();

        ResponseJson.Get(JsonFieldStatusTok, ValueJson);
        case ValueJson.AsValue().AsText() of
            StatusCompleteTok:
                exit(true);
            StatusPendingTok:
                exit(false);
            StatusErrorTok:
                begin
                    if ResponseJson.Get(JsonFieldEventsTok, ValueJson) then
                        Events := ValueJson.AsArray();
                    foreach EventToken in Events do begin
                        EventObject := EventToken.AsObject();
                        EventObject.Get(JsonFieldMessageTok, MessageToken);
                        EDocumentErrorHelper.LogSimpleErrorMessage(EDocument, MessageToken.AsValue().AsText());
                    end;
                    EDocumentErrorHelper.LogSimpleErrorMessage(EDocument, AvalaraProcessingDocFailedErr);
                    exit(false);
                end;
            else
                exit(false);
        end;
    end;

    procedure LoadStatusFromJson(ResponseText: Text; EDocument: Record "E-Document")
    var
        MessageEvent: Record "Message Event";
        MessageResponseHeader: Record "Message Response Header";
        i: Integer;
        EventsArray: JsonArray;
        EventObj: JsonObject;
        JsonObj: JsonObject;
        EventDateTimeToken: JsonToken;
        EventsToken: JsonToken;
        EventToken: JsonToken;
        MessageToken: JsonToken;
        ResponseKeyToken: JsonToken;
        ResponseValueToken: JsonToken;
        RootToken: JsonToken;
        EventDateTimeTxt, ResponseKeyText, ResponseValueText : Text;
    begin
        MessageResponseHeader.Init();
        MessageEvent.Init();

        if not JsonObj.ReadFrom(ResponseText) then
            Error(InvalidJsonResponseErr);

        // --- Header ---
        if JsonObj.Get(JsonFieldIdTok, RootToken) and RootToken.IsValue() then
            MessageResponseHeader.Id := CopyStr(RootToken.AsValue().AsText(), 1, MaxStrLen(MessageResponseHeader.Id));

        if MessageResponseHeader.Id = '' then
            Error(MissingIdInResponseErr);

        if JsonObj.Get(JsonFieldCompanyIdTok, RootToken) and RootToken.IsValue() then
            MessageResponseHeader.CompanyId := CopyStr(RootToken.AsValue().AsText(), 1, MaxStrLen(MessageResponseHeader.CompanyId));

        if JsonObj.Get(JsonFieldStatusTok, RootToken) and RootToken.IsValue() then
            MessageResponseHeader.Status := CopyStr(RootToken.AsValue().AsText(), 1, MaxStrLen(MessageResponseHeader.Status));

        if not MessageResponseHeader.Get(MessageResponseHeader.Id) then
            MessageResponseHeader.Insert();

        // --- Events Array ---

        if JsonObj.Get(JsonFieldEventsTok, EventsToken) and EventsToken.IsArray() then begin
            EventsArray := EventsToken.AsArray();

            for i := 0 to EventsArray.Count() - 1 do begin
                EventsArray.Get(i, EventToken);
                if not EventToken.IsObject() then
                    continue;

                EventObj := EventToken.AsObject();

                MessageEvent.Init();
                MessageEvent.Id := MessageResponseHeader.Id;
                MessageEvent.MessageRow := i + 1;

                // eventDateTime
                if EventObj.Get(JsonFieldEventDateTimeTok, EventDateTimeToken) and EventDateTimeToken.IsValue() then begin
                    EventDateTimeTxt := EventDateTimeToken.AsValue().AsText();
                    if not TryParseIsoDateTime(EventDateTimeTxt, MessageEvent.EventDateTime) then
                        MessageEvent.EventDateTime := 0DT;
                end;

                // responseKey
                if EventObj.Get(JsonFieldResponseKeyTok, ResponseKeyToken) and ResponseKeyToken.IsValue() then begin
                    ResponseKeyText := ResponseKeyToken.AsValue().AsText();
                    MessageEvent.ResponseKey := CopyStr(ResponseKeyText, 1, MaxStrLen(MessageEvent.ResponseKey));
                end;

                // responseValue
                if EventObj.Get(JsonFieldResponseValueTok, ResponseValueToken) and ResponseValueToken.IsValue() then begin
                    ResponseValueText := ResponseValueToken.AsValue().AsText();
                    MessageEvent.ResponseValue := CopyStr(ResponseValueText, 1, MaxStrLen(MessageEvent.ResponseValue));
                end;

                // message
                if EventObj.Get(JsonFieldMessageTok, MessageToken) and MessageToken.IsValue() then
                    MessageEvent.Message := CopyStr(MessageToken.AsValue().AsText(), 1, MaxStrLen(MessageEvent.Message));

                MessageEvent.PostedDocument := EDocument."Document No.";
                MessageEvent.EDocEntryNo := EDocument."Entry No";
                if not MessageEvent.Get(MessageEvent.Id, MessageEvent.MessageRow) then
                    MessageEvent.Insert();
            end;
        end;
    end; //end of procedure

    local procedure TryParseIsoDateTime(IsoText: Text; var Result: DateTime): Boolean
    var
        DotPos: Integer;
        Normalized: Text;
    begin
        Normalized := IsoText;

        // Strip trailing 'Z' (UTC indicator) if present
        if (StrLen(Normalized) > 0) and ((Normalized[StrLen(Normalized)] = 'Z') or (Normalized[StrLen(Normalized)] = 'z')) then
            Normalized := CopyStr(Normalized, 1, StrLen(Normalized) - 1);

        // Replace 'T' with space for BC Evaluate compatibility
        Normalized := Normalized.Replace('T', ' ');

        // First try full value (Evaluate in BC can usually handle millis with space separator)
        if Evaluate(Result, Normalized) then
            exit(true);

        // If that failed, remove fractional seconds and try again
        DotPos := StrPos(Normalized, '.');
        if DotPos > 0 then begin
            Normalized := CopyStr(Normalized, 1, DotPos - 1);
            if Evaluate(Result, Normalized) then
                exit(true);
        end;

        exit(false);
    end;

    /// <summary>
    /// Returns id from json array
    /// </summary>
    local procedure GetDocumentIdFromArray(DocumentArray: JsonArray; Index: Integer): Text
    var
        DocumentJsonToken, IdToken : JsonToken;
    begin
        DocumentArray.Get(Index, DocumentJsonToken);
        DocumentJsonToken.AsObject().Get(JsonFieldIdTok, IdToken);
        exit(IdToken.AsValue().AsText());
    end;

    /// <summary>
    /// Format specific date with the current time, for Avalara API
    /// </summary>
    procedure FormatDateTime(InputDate: Date): Text
    var
        CurrentDateTime: DateTime;
        FormattedDateTime: Text;
    begin
        // Convert the input date to DateTime with the current time
        CurrentDateTime := CreateDateTime(InputDate, Time());

        // Format the DateTime in the desired format
        FormattedDateTime := Format(CurrentDateTime, 0, '<Year4>-<Month,2>-<Day,2>T<Hours24,2>:<Minutes,2>:<Seconds,2>');

        exit(FormattedDateTime);
    end;

    procedure GetAvalaraTok(): Text
    begin
        exit(AvalaraTok);
    end;

    procedure CreateBatch(EDocService: Record "E-Document Service"; var EDocument: Record "E-Document"; var SourceDocumentHeaders: RecordRef; var SourceDocumentsLines: RecordRef; var TempBlob: Codeunit "Temp Blob");
    begin
        Message('Implementation Coming soon');
    end;

    procedure GetMandateTypeFromName(MandateText: Text): Text
    begin
        if MandateText.Contains(MandateTypeB2BTok) then
            exit(MandateTypeB2BTok);

        if MandateText.Contains(MandateTypeB2GTok) then
            exit(MandateTypeB2GTok);

        // Default to empty if no mandate type found
        exit('');
    end;

    var
        TempAvalaraCompanies: Record "Avalara Company" temporary;
        TempMandates: Record Mandate temporary;
        EDocumentErrorHelper: Codeunit "E-Document Error Helper";

        // Error messages
        AvalaraCountryIdLongerErr: Label 'Avalara company id is longer than what is supported by framework.';
        AvalaraCountryMandateCodeErr: Label 'Avalara country code is longer than what is supported by framework.';
        AvalaraCountryMandateDescLongerErr: Label 'Avalara mandate description is longer than what is supported by framework.';
        AvalaraCountryMandateLongerErr: Label 'Avalara country mandate is longer than what is supported by framework.';
        AvalaraGetDocsPathTxt: Label '/einvoicing/documents?flow=in&count=true&filter=status eq Complete', Locked = true;
        AvalaraIdLongerErr: Label 'Avalara returned id longer than supported by framework.';

        //   AvalaraGetDocsPathTxt: Label '/einvoicing/documents?flow=in&count=true&filter=status eq Complete&startDate=%1&endDate=%2', Locked = true;
        AvalaraPickMandateMsg: Label 'Select which Avalara service you want to update mandate for.';
        AvalaraProcessingDocFailedErr: Label 'An error has been identified in the submitted document.';
        AvalaraTok: Label 'E-Document - Avalara', Locked = true;
        AvaralaCountryNameLongerErr: Label 'Avalara company name is longer than what is supported by framework.';
        DataFormatCreditNoteTok: Label 'ubl-creditnote', Locked = true;
        DataFormatInvoiceTok: Label 'ubl-invoice', Locked = true;
        DataFormatVersionTok: Label '2.1', Locked = true;
        DocumentIdNotFoundErr: Label 'Document ID not found in response.';
        IncorrectDocumentIdInResponseErr: Label 'Document ID returned by API does not match E-Document.';
        InvalidJsonResponseErr: Label 'Invalid JSON response.';
        JsonFieldCompanyIdTok: Label 'companyId', Locked = true;
        JsonFieldCompanyNameTok: Label 'companyName', Locked = true;
        JsonFieldCountryCodeTok: Label 'countryCode', Locked = true;
        JsonFieldCountryMandateTok: Label 'countryMandate', Locked = true;
        JsonFieldDescriptionTok: Label 'description', Locked = true;
        JsonFieldEventDateTimeTok: Label 'eventDateTime', Locked = true;
        JsonFieldEventsTok: Label 'events', Locked = true;
        JsonFieldFormatTok: Label 'format', Locked = true;

        // JSON field name constants
        JsonFieldIdTok: Label 'id', Locked = true;
        JsonFieldInputDataFormatsTok: Label 'inputDataFormats', Locked = true;
        JsonFieldMessageTok: Label 'message', Locked = true;
        JsonFieldNextLinkTok: Label '@nextLink', Locked = true;
        JsonFieldResponseKeyTok: Label 'responseKey', Locked = true;
        JsonFieldResponseValueTok: Label 'responseValue', Locked = true;
        JsonFieldStatusTok: Label 'status', Locked = true;
        JsonFieldValueTok: Label 'value', Locked = true;
        JsonFieldVersionsTok: Label 'versions', Locked = true;
        MandateBlockedErr: Label 'Mandate is set to blocked could not send.';
        MandateNotCompleteErr: Label 'Status of Activation process for this mandate not complete could not send. Please go to Avalara ELR portal to complete activation.';
        MandateNotFoundErr: Label 'Activation process for this mandate not found could not send. Please go to Avalara ELR portal to initiate and complete activation.';

        // Mandate type constants
        MandateTypeB2BTok: Label 'B2B', Locked = true;
        MandateTypeB2GTok: Label 'B2G', Locked = true;
        MissingIdInResponseErr: Label 'Missing "id" in response.';

        // Status value constants
        StatusCompleteTok: Label 'Complete', Locked = true;
        StatusErrorTok: Label 'Error', Locked = true;
        StatusPendingTok: Label 'Pending', Locked = true;

        // Workflow and format constants
        WorkflowIdTok: Label 'partner-einvoicing', Locked = true;
}