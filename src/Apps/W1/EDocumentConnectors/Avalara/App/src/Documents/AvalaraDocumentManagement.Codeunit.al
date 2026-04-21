// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocumentConnector.Avalara;

using Microsoft.eServices.EDocument;
using System.Utilities;

/// <summary>
/// Manages document operations with the Avalara E-Invoicing service, including receiving, downloading, and processing inbound documents.
/// </summary>
codeunit 6371 "Avalara Document Management"
{
    Access = Internal;

    var
        DefaultXmlFileNameMsg: Label '%1.xml', Comment = '%1 = Entry Number', Locked = true;
        EmptyResponseContentErr: Label 'Empty response content';
        FailedToAttachDocumentMsg: Label 'Failed to attach document %1 to E-Document', Comment = '%1 = Document ID';
        FailedToDownloadDocumentMsg: Label 'Failed to download document %1 with media type %2', Comment = '%1 = Document ID, %2 = Media Type';

        // Error messages
        InvalidJsonErr: Label 'The provided JSON is invalid or malformed.';
        JsonFieldCompanyIdTok: Label 'companyId', Locked = true;
        JsonFieldCountryCodeTok: Label 'countryCode', Locked = true;
        JsonFieldCountryMandateTok: Label 'countryMandate', Locked = true;
        JsonFieldCustomerNameTok: Label 'customerName', Locked = true;
        JsonFieldDocumentDateTok: Label 'documentDate', Locked = true;
        JsonFieldDocumentNumberTok: Label 'documentNumber', Locked = true;
        JsonFieldDocumentTypeTok: Label 'documentType', Locked = true;
        JsonFieldDocumentVersionTok: Label 'documentVersion', Locked = true;
        JsonFieldFlowTok: Label 'flow', Locked = true;
        JsonFieldIdTok: Label 'id', Locked = true;
        JsonFieldInterfaceTok: Label 'interface', Locked = true;
        JsonFieldProcessDateTimeTok: Label 'processDateTime', Locked = true;
        JsonFieldReceiverTok: Label 'receiver', Locked = true;
        JsonFieldStatusTok: Label 'status', Locked = true;
        JsonFieldSupplierNameTok: Label 'supplierName', Locked = true;
        // JSON field name constants
        JsonFieldValueTok: Label 'value', Locked = true;
        MessageHeaderNotFoundErr: Label 'Message header not found for document ID %1.', Comment = '%1 = Document ID';
        MissingValueArrayErr: Label 'The JSON response is missing the required "value" array.';
        NoResponseFromAvalaraMsg: Label 'No response received from Avalara API';
        NoXmlContentToAttachMsg: Label 'No XML content to attach';
        SuccessfullyDownloadedMsg: Label 'Successfully downloaded and attached document %1 with media type %2', Comment = '%1 = Document ID, %2 = Media Type';

    internal procedure ParseIntoTemp(var TempDocumentBuffer: Record "Avalara Document Buffer" temporary; JsonText: Text)
    begin
        if JsonText = '' then
            exit;

        ParseDocuments(TempDocumentBuffer, JsonText);
    end;

    local procedure ParseDocuments(var TempDocumentBuffer: Record "Avalara Document Buffer" temporary; JsonText: Text)
    var
        DocumentArray: JsonArray;
        RootObject: JsonObject;
        ItemToken: JsonToken;
        ValueToken: JsonToken;
    begin
        if not RootObject.ReadFrom(JsonText) then
            Error(InvalidJsonErr);

        // Expecting: { "@nextLink": ..., "value": [ ... ] }
        if not RootObject.Get(JsonFieldValueTok, ValueToken) then
            Error(MissingValueArrayErr);

        if not ValueToken.IsArray() then
            Error(MissingValueArrayErr);

        DocumentArray := ValueToken.AsArray();

        foreach ItemToken in DocumentArray do
            ProcessDocumentItem(TempDocumentBuffer, ItemToken);
    end;

    local procedure ProcessDocumentItem(var TempDocumentBuffer: Record "Avalara Document Buffer" temporary; ItemToken: JsonToken)
    var
        ItemObject: JsonObject;
    begin
        if not ItemToken.IsObject() then
            exit;

        ItemObject := ItemToken.AsObject();

        if not PopulateDocumentBuffer(TempDocumentBuffer, ItemObject) then
            exit;

        if not InsertDocumentBuffer(TempDocumentBuffer) then
            exit;
    end;

    local procedure PopulateDocumentBuffer(var TempDocumentBuffer: Record "Avalara Document Buffer" temporary; ItemObject: JsonObject): Boolean
    var
        DocumentDate: Date;
        ProcessDateTime: DateTime;
    begin
        TempDocumentBuffer.Init();

        // Parse core identifiers
        TempDocumentBuffer.Id := CopyStr(GetJsonText(ItemObject, JsonFieldIdTok), 1, MaxStrLen(TempDocumentBuffer.Id));
        TempDocumentBuffer."Company Id" := CopyStr(GetJsonText(ItemObject, JsonFieldCompanyIdTok), 1, MaxStrLen(TempDocumentBuffer."Company Id"));

        // Parse datetime fields
        if TryGetJsonDateTime(ItemObject, JsonFieldProcessDateTimeTok, ProcessDateTime) then
            TempDocumentBuffer."Process DateTime" := ProcessDateTime;

        // Parse document information
        TempDocumentBuffer.Status := CopyStr(GetJsonText(ItemObject, JsonFieldStatusTok), 1, MaxStrLen(TempDocumentBuffer.Status));
        TempDocumentBuffer."Document Number" := CopyStr(GetJsonText(ItemObject, JsonFieldDocumentNumberTok), 1, MaxStrLen(TempDocumentBuffer."Document Number"));
        TempDocumentBuffer."Document Type" := CopyStr(GetJsonText(ItemObject, JsonFieldDocumentTypeTok), 1, MaxStrLen(TempDocumentBuffer."Document Type"));
        TempDocumentBuffer."Document Version" := CopyStr(GetJsonText(ItemObject, JsonFieldDocumentVersionTok), 1, MaxStrLen(TempDocumentBuffer."Document Version"));

        if TryGetJsonDate(ItemObject, JsonFieldDocumentDateTok, DocumentDate) then
            TempDocumentBuffer."Document Date" := DocumentDate;

        // Parse additional metadata
        TempDocumentBuffer.Flow := CopyStr(GetJsonText(ItemObject, JsonFieldFlowTok), 1, MaxStrLen(TempDocumentBuffer.Flow));
        TempDocumentBuffer."Country Code" := CopyStr(GetJsonText(ItemObject, JsonFieldCountryCodeTok), 1, MaxStrLen(TempDocumentBuffer."Country Code"));
        TempDocumentBuffer."Country Mandate" := CopyStr(GetJsonText(ItemObject, JsonFieldCountryMandateTok), 1, MaxStrLen(TempDocumentBuffer."Country Mandate"));
        TempDocumentBuffer.Receiver := CopyStr(GetJsonText(ItemObject, JsonFieldReceiverTok), 1, MaxStrLen(TempDocumentBuffer.Receiver));
        TempDocumentBuffer."Supplier Name" := CopyStr(GetJsonText(ItemObject, JsonFieldSupplierNameTok), 1, MaxStrLen(TempDocumentBuffer."Supplier Name"));
        TempDocumentBuffer."Customer Name" := CopyStr(GetJsonText(ItemObject, JsonFieldCustomerNameTok), 1, MaxStrLen(TempDocumentBuffer."Customer Name"));
        TempDocumentBuffer.Interface := CopyStr(GetJsonText(ItemObject, JsonFieldInterfaceTok), 1, MaxStrLen(TempDocumentBuffer.Interface));

        exit(true);
    end;

    local procedure InsertDocumentBuffer(var TempDocumentBuffer: Record "Avalara Document Buffer" temporary): Boolean
    begin
        if not TempDocumentBuffer.Insert(true) then begin
            Session.LogMessage('', 'Failed to insert Avalara Document Buffer', Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', 'Avalara Document Parser');
            exit(false);
        end;

        exit(true);
    end;

    local procedure GetJsonText(JsonObj: JsonObject; FieldName: Text): Text
    var
        FieldToken: JsonToken;
        FieldValue: JsonValue;
    begin
        if not JsonObj.Get(FieldName, FieldToken) then
            exit('');

        if not FieldToken.IsValue() then
            exit('');

        FieldValue := FieldToken.AsValue();

        if FieldValue.IsNull() then
            exit('');

        exit(FieldValue.AsText());
    end;

    local procedure TryGetJsonDateTime(JsonObj: JsonObject; FieldName: Text; var ResultDateTime: DateTime): Boolean
    var
        AvalaraFunctions: Codeunit "Avalara Functions";
        FieldToken: JsonToken;
        FieldValue: JsonValue;
        DateTimeText: Text;
    begin
        if not JsonObj.Get(FieldName, FieldToken) then
            exit(false);

        if not FieldToken.IsValue() then
            exit(false);

        FieldValue := FieldToken.AsValue();

        if FieldValue.IsNull() then
            exit(false);

        DateTimeText := FieldValue.AsText();

        if DateTimeText = '' then
            exit(false);

        exit(AvalaraFunctions.TryParseIsoDateTime(DateTimeText, ResultDateTime));
    end;

    local procedure TryGetJsonDate(JsonObj: JsonObject; FieldName: Text; var ResultDate: Date): Boolean
    var
        FieldToken: JsonToken;
        FieldValue: JsonValue;
        DateText: Text;
    begin
        if not JsonObj.Get(FieldName, FieldToken) then
            exit(false);

        if not FieldToken.IsValue() then
            exit(false);

        FieldValue := FieldToken.AsValue();

        if FieldValue.IsNull() then
            exit(false);

        DateText := FieldValue.AsText();

        if DateText = '' then
            exit(false);

        // Accept ISO 8601 date format (YYYY-MM-DD) - take first 10 characters
        exit(Evaluate(ResultDate, CopyStr(DateText, 1, 10)));
    end;

    // ============================================================================
    // PUBLIC API - Document Management Operations
    // ============================================================================

    /// <summary>
    /// Load document list from Avalara API into temporary buffer.
    /// </summary>
    /// <param name="AvalaraDocBuffer">Temporary buffer to populate with documents.</param>
    internal procedure LoadDocumentList(var AvalaraDocBuffer: Record "Avalara Document Buffer" temporary)
    var
        HttpExec: Codeunit "Http Executor";
        Request: Codeunit Requests;
        ResponseText: Text;
    begin
        Request.Init();
        Request.Authenticate().CreateGetDocumentListRequest();
        ResponseText := HttpExec.ExecuteHttpRequest(Request);

        if ResponseText = '' then begin
            if GuiAllowed then
                Message(NoResponseFromAvalaraMsg);
            exit;
        end;

        AvalaraDocBuffer.DeleteAll();
        ParseIntoTemp(AvalaraDocBuffer, ResponseText);
    end;

    /// <summary>
    /// Download a document from Avalara and attach it to an E-Document.
    /// </summary>
    /// <param name="EDocument">Target E-Document record.</param>
    /// <param name="DocumentID">Avalara document ID to download.</param>
    /// <param name="MediaType">Media type for download (e.g., application/xml, application/pdf).</param>
    /// <returns>True if download and attachment succeeded, false otherwise.</returns>
    procedure DownloadDocument(var EDocument: Record "E-Document"; DocumentID: Text; MediaType: Text): Boolean
    var
        TempBlob: Codeunit "Temp Blob";
        FileName: Text;
    begin
        // Validate inputs
        if DocumentID = '' then begin
            Session.LogMessage('', 'Document ID is required for download', Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', 'Avalara Document Management');
            exit(false);
        end;

        if MediaType = '' then
            MediaType := 'application/xml'; // Default media type

        // Try to download - if it fails (e.g., 404 not found), return false without rollback
        if not TryDownloadFromApi(DocumentID, MediaType, TempBlob) then begin
            Session.LogMessage('', StrSubstNo(FailedToDownloadDocumentMsg, DocumentID, MediaType), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', 'Avalara Document Management');
            exit(false);
        end;

        // Determine filename and attach to E-Document
        FileName := GetFileNameForMediaType(DocumentID, MediaType);

        if not AttachToEDocument(EDocument, TempBlob, FileName) then begin
            Session.LogMessage('', StrSubstNo(FailedToAttachDocumentMsg, DocumentID), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', 'Avalara Document Management');
            exit(false);
        end;

        Session.LogMessage('', StrSubstNo(SuccessfullyDownloadedMsg, DocumentID, MediaType), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', 'Avalara Document Management');
        exit(true);
    end;

    [TryFunction]
    local procedure TryDownloadFromApi(DocumentID: Text; MediaType: Text; var TempBlob: Codeunit "Temp Blob")
    var
        HttpExec: Codeunit "Http Executor";
        Request: Codeunit Requests;
        Response: HttpResponseMessage;
        InStream: InStream;
        OutStream: OutStream;
    begin
        // Execute download request
        Request.Init();
        Request.Authenticate().CreateDownloadRequest(DocumentID, MediaType);
        HttpExec.ExecuteHttpRequest(Request);

        // Validate response via status code
        Response := HttpExec.GetResponse();
        if not Response.IsSuccessStatusCode() then
            Error(EmptyResponseContentErr);

        // Read binary content directly into blob
        Response.Content().ReadAs(InStream);
        TempBlob.CreateOutStream(OutStream);
        CopyStream(OutStream, InStream);

        if not TempBlob.HasValue() then
            Error(EmptyResponseContentErr);
    end;

    /// <summary>
    /// Attach XML text content to an E-Document record.
    /// </summary>
    /// <param name="EDocument">Target E-Document record.</param>
    /// <param name="XMLText">XML content to attach.</param>
    /// <param name="FileName">File name for the attachment.</param>
    /// <returns>True if attachment succeeded.</returns>
    procedure AttachXMLText(var EDocument: Record "E-Document"; XMLText: Text; FileName: Text): Boolean
    var
        TempBlob: Codeunit "Temp Blob";
        OutStream: OutStream;
    begin
        if XMLText = '' then begin
            if GuiAllowed then
                Message(NoXmlContentToAttachMsg);
            exit(false);
        end;

        if FileName = '' then
            FileName := StrSubstNo(DefaultXmlFileNameMsg, EDocument."Entry No");

        // Write text to blob
        TempBlob.CreateOutStream(OutStream, TextEncoding::UTF8);
        OutStream.WriteText(XMLText);

        exit(AttachToEDocument(EDocument, TempBlob, FileName));
    end;

    // ============================================================================
    // PRIVATE HELPERS - File and Attachment Management
    // ============================================================================

    local procedure GetFileNameForMediaType(DocumentID: Text; MediaType: Text): Text
    var
        FileExtension: Text;
    begin
        case LowerCase(MediaType) of
            'application/pdf':
                FileExtension := 'pdf';
            'application/xml', 'application/vnd.oasis.ubl+xml', 'text/xml':
                FileExtension := 'xml';
            'application/zip':
                FileExtension := 'zip';
            'application/json':
                FileExtension := 'json';
            else
                FileExtension := 'dat';
        end;

        exit(StrSubstNo('%1.%2', DocumentID, FileExtension));
    end;

    local procedure AttachToEDocument(var EDocument: Record "E-Document"; var ContentBlob: Codeunit "Temp Blob"; FileName: Text): Boolean
    var
        EDocAttachmentProcessor: Codeunit "E-Doc. Attachment Processor";
        InStream: InStream;
    begin
        ContentBlob.CreateInStream(InStream);
        EDocAttachmentProcessor.Insert(EDocument, InStream, FileName);
        exit(true);
    end;

    /// <summary>
    /// Displays the document status in a Message Response Card page.
    /// </summary>
    /// <param name="EDocument">The E-Document to retrieve status for.</param>
    procedure ShowDocumentStatus(var EDocument: Record "E-Document")
    var
        MessageResponseHeader: Record "Avl Message Response Header";
        HttpExecutor: Codeunit "Http Executor";
        Processing: Codeunit Processing;
        Request: Codeunit Requests;
        MessageResponseCard: Page "Avl Message Response Card";
        ResponseContent: Text;
    begin
        EDocument.TestField("Avalara Document Id");

        Request.Init();
        Request.Authenticate().CreateGetDocumentStatusRequest(EDocument."Avalara Document Id");
        ResponseContent := HttpExecutor.ExecuteHttpRequest(Request);

        Processing.LoadStatusFromJson(ResponseContent, EDocument);

        MessageResponseHeader.SetRange(id, EDocument."Avalara Document Id");
        if not MessageResponseHeader.FindFirst() then
            Error(MessageHeaderNotFoundErr, EDocument."Avalara Document Id");

        MessageResponseCard.SetRecord(MessageResponseHeader);
        MessageResponseCard.Run();
    end;
}
