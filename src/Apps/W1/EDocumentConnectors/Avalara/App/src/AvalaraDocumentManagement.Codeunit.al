codeunit 6371 "Avalara Document Management"
{
    var

        // ISO 8601 DateTime parsing constants
        DateTimeSeparatorTok: Label 'T', Locked = true;
        DecimalSeparatorTok: Label '.', Locked = true;

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
        MissingValueArrayErr: Label 'The JSON response is missing the required "value" array.';
        TimeZoneMarkersTok: Label 'Z+-', Locked = true;

    procedure ParseIntoTemp(var TempDocumentBuffer: Record "Avalara Document Buffer" temporary; JsonText: Text)
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
            Session.LogMessage('0000AVL004', 'Failed to insert Avalara Document Buffer', Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', 'Avalara Document Parser');
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

        exit(ParseIso8601DateTime(DateTimeText, ResultDateTime));
    end;

    local procedure ParseIso8601DateTime(DateTimeText: Text; var ResultDateTime: DateTime): Boolean
    var
        DatePart: Date;
        DateTimeSeparatorPos: Integer;
        CleanedTimeText: Text;
        TimePart: Time;
    begin
        // Find 'T' separator between date and time
        DateTimeSeparatorPos := StrPos(DateTimeText, DateTimeSeparatorTok);

        // No time part -> parse as date only
        if DateTimeSeparatorPos = 0 then begin
            if not Evaluate(DatePart, CopyStr(DateTimeText, 1, 10)) then
                exit(false);

            ResultDateTime := CreateDateTime(DatePart, 0T);
            exit(true);
        end;

        // Parse date part (YYYY-MM-DD)
        if not Evaluate(DatePart, CopyStr(DateTimeText, 1, 10)) then
            exit(false);

        // Parse time part
        CleanedTimeText := ExtractTimePart(DateTimeText, DateTimeSeparatorPos);

        if not TryParseTime(CleanedTimeText, TimePart) then
            exit(false);

        ResultDateTime := CreateDateTime(DatePart, TimePart);
        exit(true);
    end;

    local procedure ExtractTimePart(DateTimeText: Text; DateTimeSeparatorPos: Integer): Text
    var
        DecimalPos: Integer;
        TimeZoneMarkerPos: Integer;
        CleanedTimeText: Text;
        TimePartText: Text;
        TimePartWithoutTimezone: Text;
    begin
        // Extract everything after 'T'
        TimePartText := CopyStr(DateTimeText, DateTimeSeparatorPos + 1);

        // Remove timezone markers (Z, +, -)
        TimeZoneMarkerPos := FindFirstIndexOfAny(TimePartText, TimeZoneMarkersTok);
        if TimeZoneMarkerPos > 0 then
            TimePartWithoutTimezone := CopyStr(DateTimeText, DateTimeSeparatorPos + 1, TimeZoneMarkerPos - 1)
        else
            TimePartWithoutTimezone := TimePartText;

        // Extract time component from full string
        CleanedTimeText := CopyStr(TimePartWithoutTimezone, 1, StrLen(TimePartWithoutTimezone));

        // Remove fractional seconds (.ffffff)
        DecimalPos := StrPos(CleanedTimeText, DecimalSeparatorTok);
        if DecimalPos > 0 then
            CleanedTimeText := CopyStr(CleanedTimeText, 1, DecimalPos - 1);

        // Limit to HH:MM:SS format (8 characters)
        if StrLen(CleanedTimeText) > 8 then
            CleanedTimeText := CopyStr(CleanedTimeText, 1, 8);

        exit(CleanedTimeText);
    end;

    local procedure TryParseTime(TimeText: Text; var ResultTime: Time): Boolean
    begin
        // Try full time format (HH:MM:SS)
        if Evaluate(ResultTime, TimeText) then
            exit(true);

        // Fallback: Try short format (HH:MM)
        if StrLen(TimeText) >= 5 then
            if Evaluate(ResultTime, CopyStr(TimeText, 1, 5)) then
                exit(true);

        exit(false);
    end;

    local procedure FindFirstIndexOfAny(SourceText: Text; SearchChars: Text): Integer
    var
        CharIndex: Integer;
        CurrentChar: Text[1];
    begin
        for CharIndex := 1 to StrLen(SourceText) do begin
            CurrentChar := CopyStr(SourceText, CharIndex, 1);
            if StrPos(SearchChars, CurrentChar) > 0 then
                exit(CharIndex);
        end;

        exit(0);
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
    procedure LoadDocumentList(var AvalaraDocBuffer: Record "Avalara Document Buffer" temporary)
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
                Message('No response received from Avalara API');
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
            Session.LogMessage('0000AVL018', 'Document ID is required for download', Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', 'Avalara Document Management');
            exit(false);
        end;

        if MediaType = '' then
            MediaType := 'application/xml'; // Default media type

        // Try to download - if it fails (e.g., 404 not found), return false without rollback
        if not TryDownloadFromApi(DocumentID, MediaType, TempBlob) then begin
            Session.LogMessage('0000AVL019', StrSubstNo('Failed to download document %1 with media type %2', DocumentID, MediaType), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', 'Avalara Document Management');
            exit(false);
        end;

        // Determine filename and attach to E-Document
        FileName := GetFileNameForMediaType(DocumentID, MediaType);

        if not AttachToEDocument(EDocument, TempBlob, FileName) then begin
            Session.LogMessage('0000AVL020', StrSubstNo('Failed to attach document %1 to E-Document', DocumentID), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', 'Avalara Document Management');
            exit(false);
        end;

        Session.LogMessage('0000AVL021', StrSubstNo('Successfully downloaded and attached document %1 with media type %2', DocumentID, MediaType), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', 'Avalara Document Management');
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
        ResponseContent: Text;
    begin
        // Execute download request
        Request.Init();
        Request.Authenticate().CreateDownloadRequest(DocumentID, MediaType);
        ResponseContent := HttpExec.ExecuteHttpRequest(Request);

        if ResponseContent = '' then
            Error('Empty response content');

        // Get response and read content into blob
        Response := HttpExec.GetResponse();
        Response.Content.ReadAs(InStream);

        TempBlob.CreateOutStream(OutStream);
        CopyStream(OutStream, InStream);
    end;

    /// <summary>
    /// Get list of available media types for a specific mandate.
    /// </summary>
    /// <param name="Mandate">Mandate code (e.g., AU-B2B-PEPPOL).</param>
    /// <returns>List of media type strings.</returns>
    procedure GetAvailableMediaTypes(Mandate: Text): List of [Text]
    var
        MediaTypesTable: Record "Media Types";
        MediaTypes: List of [Text];
    begin
        MediaTypesTable.SetRange(Mandate, Mandate);
        if MediaTypesTable.FindSet() then
            repeat
                MediaTypes.Add(MediaTypesTable."Invoice Available Media Types");
            until MediaTypesTable.Next() = 0;

        // Provide defaults if none configured
        if MediaTypes.Count = 0 then begin
            MediaTypes.Add('application/xml');
            MediaTypes.Add('application/pdf');
        end;

        exit(MediaTypes);
    end;

    /// <summary>
    /// Receive document batch from Avalara API using E-Document Service integration.
    /// </summary>
    /// <param name="EDocService">E-Document Service record with integration details.</param>
    /// <param name="ReceivedDocuments">Output list of received document IDs.</param>
    /// <param name="ReceiveContext">Context for the receive operation.</param>
    /// <returns>Number of documents received.</returns>
    procedure ReceiveDocumentBatch(var EDocService: Record "E-Document Service"; var ReceivedDocuments: Codeunit "Temp Blob List"; var ReceiveContext: Codeunit ReceiveContext): Integer
    var
        IDocumentReceiver: Interface IDocumentReceiver;
    begin
        IDocumentReceiver := EDocService."Service Integration V2";
        IDocumentReceiver.ReceiveDocuments(EDocService, ReceivedDocuments, ReceiveContext);

        Session.LogMessage('0000AVL006', StrSubstNo('Received %1 documents from Avalara API', ReceivedDocuments.Count()), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', 'Avalara Document Management');

        exit(ReceivedDocuments.Count());
    end;

    /// <summary>
    /// Download a specific document by ID and attach to E-Document with all available media types.
    /// </summary>
    /// <param name="EDocument">Target E-Document record.</param>
    /// <param name="EDocService">E-Document Service configuration.</param>
    /// <param name="DocumentID">Avalara document ID to download.</param>
    /// <returns>True if at least one media type was downloaded successfully.</returns>
    procedure DownloadDocumentWithAllMediaTypes(var EDocument: Record "E-Document"; var EDocService: Record "E-Document Service"; DocumentID: Text): Boolean
    var
        AvalaraFunctions: Codeunit "Avalara Functions";
        SuccessCount: Integer;
        MediaTypes: List of [Text];
        Mandate: Text;
        MediaType: Text;
    begin
        if DocumentID = '' then begin
            if GuiAllowed then
                Message('Document ID is required');
            exit(false);
        end;

        // Get mandate from service
        Mandate := EDocService."Avalara Mandate";
        MediaTypes := AvalaraFunctions.GetAvailableMediaTypesForMandate(Mandate);

        if MediaTypes.Count = 0 then begin
            Session.LogMessage('0000AVL007', 'No media types available for mandate', Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', 'Avalara Document Management');
            exit(false);
        end;

        // Download for each media type
        SuccessCount := 0;
        foreach MediaType in MediaTypes do
            if DownloadDocument(EDocument, DocumentID, MediaType) then
                SuccessCount += 1;

        Session.LogMessage('0000AVL008', StrSubstNo('Downloaded %1 of %2 media types for document %3', SuccessCount, MediaTypes.Count, DocumentID), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', 'Avalara Document Management');

        exit(SuccessCount > 0);
    end;

    /// <summary>
    /// Process a batch of received document IDs and download them.
    /// </summary>
    /// <param name="TempBlobList">List of document IDs in TempBlob format.</param>
    /// <param name="EDocument">E-Document record for context (can be empty).</param>
    /// <param name="EDocService">E-Document Service configuration.</param>
    /// <returns>Number of documents successfully processed.</returns>
    procedure ProcessDocumentBatch(var TempBlobList: Codeunit "Temp Blob List"; var EDocument: Record "E-Document"; var EDocService: Record "E-Document Service"): Integer
    var
        TempBlob: Codeunit "Temp Blob";
        InStream: InStream;
        i: Integer;
        ProcessedCount: Integer;
        DocumentID: Text;
    begin
        ProcessedCount := 0;

        for i := 1 to TempBlobList.Count() do begin
            TempBlobList.Get(i, TempBlob);
            TempBlob.CreateInStream(InStream, TextEncoding::UTF8);
            InStream.ReadText(DocumentID);

            if DocumentID <> '' then begin
                Clear(EDocument);
                EDocument."Avalara Document Id" := CopyStr(DocumentID, 1, MaxStrLen(EDocument."Avalara Document Id"));

                if DownloadDocumentWithAllMediaTypes(EDocument, EDocService, DocumentID) then
                    ProcessedCount += 1;
            end;
        end;

        Session.LogMessage('0000AVL009', StrSubstNo('Processed %1 of %2 documents from batch', ProcessedCount, TempBlobList.Count()), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', 'Avalara Document Management');

        exit(ProcessedCount);
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
                Message('No XML content to attach');
            exit(false);
        end;

        if FileName = '' then
            FileName := StrSubstNo('%1.xml', EDocument."Entry No");

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
        RecRef: RecordRef;
        AttachmentSuccess: Boolean;
    begin
        AttachmentSuccess := false;

        // Attach to E-Document record
        RecRef.GetTable(EDocument);
        if SaveAttachment(ContentBlob, RecRef, FileName) then
            AttachmentSuccess := true
        else
            Session.LogMessage('0000AVL010', 'Failed to save attachment to E-Document', Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', 'Avalara Document Management');

        // Attach to source document if available
        if AttachToSourceDocument(EDocument, ContentBlob, FileName) then
            AttachmentSuccess := true;

        if not AttachmentSuccess then
            Session.LogMessage('0000AVL005', 'Failed to save document attachment to any location', Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', 'Avalara Document Management');

        exit(AttachmentSuccess);
    end;

    local procedure AttachToSourceDocument(var EDocument: Record "E-Document"; var ContentBlob: Codeunit "Temp Blob"; FileName: Text): Boolean
    var
        SourceRecordID: RecordId;
        RecRef: RecordRef;
    begin
        // Get source document RecordID
        SourceRecordID := EDocument."Document Record ID";

        // Validate we have a valid RecordID
        if Format(SourceRecordID) = '' then begin
            Session.LogMessage('0000AVL011', 'Source document RecordID not available on E-Document', Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', 'Avalara Document Management');
            exit(false);
        end;

        // Try to open the source document using RecordID
        if not RecRef.Get(SourceRecordID) then begin
            Session.LogMessage('0000AVL012', StrSubstNo('Failed to open source document from RecordID: %1', Format(SourceRecordID)), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', 'Avalara Document Management');
            exit(false);
        end;

        // Attach to source document
        if not SaveAttachment(ContentBlob, RecRef, FileName) then begin
            Session.LogMessage('0000AVL013', StrSubstNo('Failed to save attachment to source document: Table %1', RecRef.Number), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', 'Avalara Document Management');
            exit(false);
        end;

        Session.LogMessage('0000AVL014', StrSubstNo('Successfully attached document to source: Table %1, File %2', RecRef.Number, FileName), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', 'Avalara Document Management');
        exit(true);
    end;

    local procedure SaveAttachment(var ContentBlob: Codeunit "Temp Blob"; var RecRef: RecordRef; FileName: Text): Boolean
    var
        DocumentAttachment: Record "Document Attachment";
    begin
        // Check if attachment with identical content already exists to prevent duplicates
        if AttachmentExistsForRecord(RecRef, ContentBlob) then begin
            Session.LogMessage('0000AVL022',
                StrSubstNo('Attachment with identical content already exists for table %1, skipping duplicate', RecRef.Number),
                Verbosity::Normal,
                DataClassification::SystemMetadata,
                TelemetryScope::ExtensionPublisher,
                'Category', 'Avalara Document Management');
            exit(true); // Return true since the attachment already exists
        end;

        DocumentAttachment.SaveAttachment(RecRef, FileName, ContentBlob, true);
        exit(true);
    end;

    local procedure AttachmentExistsForRecord(var RecRef: RecordRef; var ContentBlob: Codeunit "Temp Blob"): Boolean
    var
        DocumentAttachment: Record "Document Attachment";
        TempDocAttachment: Record "Document Attachment" temporary;
        TempBlob: Codeunit "Temp Blob";
        OutStream: OutStream;
    begin
        // Create a minimal blob with content to pass validation
        TempBlob.CreateOutStream(OutStream);
        OutStream.WriteText('temp');

        // Create a temporary attachment to determine what "No." value would be used
        TempDocAttachment.SaveAttachment(RecRef, 'temp', TempBlob, false);

        // Search for all attachments for this record
        DocumentAttachment.SetRange("Table ID", TempDocAttachment."Table ID");
        DocumentAttachment.SetRange("No.", TempDocAttachment."No.");

        if DocumentAttachment.FindSet() then
            repeat
                // Compare content of each attachment with the incoming content
                if AttachmentContentMatches(DocumentAttachment, ContentBlob) then
                    exit(true);
            until DocumentAttachment.Next() = 0;

        exit(false);
    end;

    local procedure AttachmentContentMatches(var DocumentAttachment: Record "Document Attachment"; var ContentBlob: Codeunit "Temp Blob"): Boolean
    var
        TempBlob: Codeunit "Temp Blob";
        ExistingInStream: InStream;
        NewInStream: InStream;
        ExistingOutStream: OutStream;
        ExistingText: Text;
        NewText: Text;
    begin
        // Export existing attachment content to TempBlob
        TempBlob.CreateOutStream(ExistingOutStream);
        if not DocumentAttachment."Document Reference ID".ExportStream(ExistingOutStream) then
            exit(false);

        // Compare sizes first - if different, content is different
        if TempBlob.Length() <> ContentBlob.Length() then
            exit(false);

        // Read both streams and compare content
        ContentBlob.CreateInStream(NewInStream);
        TempBlob.CreateInStream(ExistingInStream);

        NewInStream.Read(NewText);
        ExistingInStream.Read(ExistingText);

        exit(NewText = ExistingText);
    end;

    /// <summary>
    /// Receives and processes E-Documents from Avalara service in a single operation.
    /// </summary>
    /// <param name="EDocService">The E-Document Service to use for receiving documents.</param>
    /// <param name="EDocument">The E-Document record context.</param>
    /// <returns>Number of documents successfully received and processed.</returns>
    procedure ReceiveAndProcessDocuments(var EDocService: Record "E-Document Service"; var EDocument: Record "E-Document"): Integer
    var
        ReceiveContext: Codeunit ReceiveContext;
        ReceivedDocuments: Codeunit "Temp Blob List";
        DocumentCount: Integer;
    begin
        DocumentCount := ReceiveDocumentBatch(EDocService, ReceivedDocuments, ReceiveContext);
        if DocumentCount = 0 then
            exit(0);

        exit(ProcessDocumentBatch(ReceivedDocuments, EDocument, EDocService));
    end;

    /// <summary>
    /// Displays the document status in a Message Response Card page.
    /// </summary>
    /// <param name="EDocument">The E-Document to retrieve status for.</param>
    procedure ShowDocumentStatus(var EDocument: Record "E-Document")
    var
        MessageResponseHeader: Record "Message Response Header";
        HttpExecutor: Codeunit "Http Executor";
        Processing: Codeunit Processing;
        Request: Codeunit Requests;
        MessageResponseCard: Page "Message Response Card";
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

    var
        MessageHeaderNotFoundErr: Label 'Message header not found for document ID %1.', Comment = '%1 = Document ID';
}
