// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocumentConnector.Avalara;

using Microsoft.eServices.EDocument;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Foundation.Attachment;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using Microsoft.Sales.Posting;
using Microsoft.Utilities;
using System.IO;
using System.Threading;
using System.Utilities;

/// <summary>
/// Provides utility functions for Avalara E-Document operations including document attachments,
/// job queue management, mandate field loading, and media type retrieval.
/// </summary>
codeunit 6800 "Avalara Functions"
{
    var
        AvalaraCategoryTok: Label 'Avalara', Locked = true;
        CannotAttachEmptyErr: Label 'Cannot attach empty content to E-Document %1', Comment = '%1 = E-Document Entry No';
        ConfirmOverwriteFieldsQst: Label 'The fields exist for %1. Do you want to over-write?', Comment = '%1 = Mandate code';

        // Format strings for StrSubstNo
        FailedToRetrieveMediaTypesMsg: Label 'Failed to retrieve media types for mandate %1', Comment = '%1 = Mandate';
        FetchAvalaraDocsDescTxt: Label 'Fetch Avalara documents for E-Documents';
        FieldsLoadedMsg: Label 'Loaded %1 fields for mandate %2', Comment = '%1 = Field count, %2 = Mandate code';
        InvalidJsonAtIndexErr: Label 'Invalid JSON at index %1: expected object.', Comment = '%1 = Array index';
        InvalidJsonResponseMsg: Label 'Invalid JSON response for mandate %1', Comment = '%1 = Mandate';
        JobQueueCreatedMsg: Label 'Job Queue Entry %1 created and set to Ready to run Codeunit %2 every %3 minutes.', Comment = '%1 = Job Queue Entry ID, %2 = Codeunit ID, %3 = Frequency in minutes';
        JobQueueExistsMsg: Label 'Job Queue Entry %1 already exists for Codeunit %2.', Comment = '%1 = Job Queue Entry ID, %2 = Codeunit ID';
        JsonFieldAcceptedValuesTok: Label 'acceptedValues', Locked = true;
        JsonFieldFieldIdTok: Label 'fieldId', Locked = true;
        JsonFieldGetInvoiceMediaTypeTok: Label 'getInvoiceAvailableMediaType', Locked = true;
        JsonFieldNamespaceTok: Label 'namespace', Locked = true;
        JsonFieldPrefixTok: Label 'prefix', Locked = true;
        JsonFieldValueTok: Label 'value', Locked = true;
        LookupTableIdRequiredErr: Label 'Lookup Table ID must be specified for Advanced Lookup transformation %1.', Comment = '%1 = Transformation Code';
        MediaTypePdfTok: Label 'application/pdf', Locked = true;
        MediaTypeUblXmlTok: Label 'application/vnd.oasis.ubl+xml', Locked = true;
        MediaTypeXmlTok: Label 'application/xml', Locked = true;
        PrimaryFieldNoRequiredErr: Label 'Primary Field No. must be specified for Advanced Lookup transformation %1.', Comment = '%1 = Transformation Code';
        ResultFieldNoRequiredErr: Label 'Result Field No. must be specified for Advanced Lookup transformation %1.', Comment = '%1 = Transformation Code';
        RetrievedMediaTypesMsg: Label 'Retrieved %1 media types for mandate %2', Comment = '%1 = Count, %2 = Mandate';
        SafeFilenameFormatMsg: Label '%1-%2%3', Comment = '%1 = File ID, %2 = Normalized media type, %3 = File extension', Locked = true;
        SetIntegerFieldTypeErr: Label 'SetIntegerField called on non-integer field %1.', Comment = '%1 = Field No.';

    procedure AttachFromText(EDocument: Record "E-Document"; XmlText: Text; FileName: Text)
    var
        DocumentAttachment: Record "Document Attachment";
        TempBlob: Codeunit "Temp Blob";
        RecRef: RecordRef;
        InStr: InStream;
        OutStr: OutStream;
    begin
        if XmlText = '' then
            Error(CannotAttachEmptyErr, EDocument."Entry No");

        // Put the XML text into a stream
        TempBlob.CreateOutStream(OutStr, TextEncoding::UTF8);
        OutStr.WriteText(XmlText);
        TempBlob.CreateInStream(InStr, TextEncoding::UTF8);

        RecRef.GetTable(EDocument);

        // AllowDuplicateFileName = true to avoid name collisions
        DocumentAttachment.SaveAttachmentFromStream(InStr, RecRef, FileName, true);
    end;

    procedure AttachmentFileExists(EDocument: Record "E-Document"; FileName: Text): Boolean
    var
        DocumentAttachment: Record "Document Attachment";
    begin
        DocumentAttachment.SetRange("File Name", FileName);
        DocumentAttachment.SetRange("Table ID", Database::"E-Document");
        DocumentAttachment.SetRange("No.", EDocument."Entry No".ToText());
        if not DocumentAttachment.IsEmpty then
            exit(true);
        exit(false);
    end;

    procedure LoadFieldsFromJson(FieldsArray: JsonArray; MandateInput: Text[40]; DocumentTypeInput: Text; DocumentVersionInput: Text)
    var
        AvalaraInputField: Record "Avalara Input Field";
        i: Integer;
        ItemObj: JsonObject;
        ItemToken: JsonToken;
    begin

        AvalaraInputField.SetRange(Mandate, MandateInput);
        AvalaraInputField.SetRange(DocumentType, DocumentTypeInput);
        AvalaraInputField.SetRange(DocumentVersion, DocumentVersionInput);

        if not AvalaraInputField.IsEmpty() then
            if Confirm(StrSubstNo(ConfirmOverwriteFieldsQst, MandateInput), true) then
                AvalaraInputField.DeleteAll()
            else
                exit;

        for i := 0 to FieldsArray.Count() - 1 do begin
            FieldsArray.Get(i, ItemToken);
            if not ItemToken.IsObject then
                Error(InvalidJsonAtIndexErr, i + 1);

            ItemObj := ItemToken.AsObject();

            AvalaraInputField.Init();

            // fieldId
            SetIntegerField(
                AvalaraInputField,
                AvalaraInputField.FieldNo(FieldId),
                GetInt(ItemObj, JsonFieldFieldIdTok));

            // Straight mappings
            SetTextField(
                AvalaraInputField,
                AvalaraInputField.FieldNo(DocumentType),
                DocumentTypeInput);

            SetTextField(
                AvalaraInputField,
                AvalaraInputField.FieldNo(DocumentVersion),
                GetText(ItemObj, 'documentVersion'));

            SetTextField(
                AvalaraInputField,
                AvalaraInputField.FieldNo(Path),
                GetText(ItemObj, 'path'));

            SetTextField(
                AvalaraInputField,
                AvalaraInputField.FieldNo(PathType),
                GetText(ItemObj, 'pathType'));

            SetTextField(
                AvalaraInputField,
                AvalaraInputField.FieldNo(FieldName),
                GetText(ItemObj, 'fieldName'));

            SetTextField(
                AvalaraInputField,
                AvalaraInputField.FieldNo(ExampleOrFixedValue),
                GetText(ItemObj, 'exampleOrFixedValue'));

            SetTextField(
                AvalaraInputField,
                AvalaraInputField.FieldNo(DocumentationLink),
                GetText(ItemObj, 'documentationLink'));

            SetTextField(
                AvalaraInputField,
                AvalaraInputField.FieldNo(DataType),
                GetText(ItemObj, 'dataType'));

            SetTextField(
                AvalaraInputField,
                AvalaraInputField.FieldNo(Description),
                GetText(ItemObj, 'description'));

            SetTextField(
                AvalaraInputField,
                AvalaraInputField.FieldNo(Optionality),
                GetText(ItemObj, 'optionality'));

            SetTextField(
                AvalaraInputField,
                AvalaraInputField.FieldNo(Cardinality),
                GetText(ItemObj, 'cardinality'));

            // namespace -> namespacePrefix / namespaceValue
            SetNamespace(ItemObj, AvalaraInputField);

            // acceptedValues[] -> pipe-separated
            SetTextField(
                AvalaraInputField,
                AvalaraInputField.FieldNo(AcceptedValues),
                GetAcceptedValues(ItemObj));

            SetTextField(
                AvalaraInputField,
                AvalaraInputField.FieldNo(Mandate),
                MandateInput);

            AvalaraInputField.Insert();
        end;

        Session.LogMessage('', StrSubstNo(FieldsLoadedMsg, FieldsArray.Count(), MandateInput), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', AvalaraCategoryTok);
    end;

    /// <summary>
    /// Get available media types for a specific mandate from Avalara API.
    /// Modern implementation using List of [Text] return type.
    /// </summary>
    /// <param name="Mandate">Mandate code (e.g., AU-B2B-PEPPOL).</param>
    /// <returns>List of unique media type strings (e.g., application/xml, application/pdf).</returns>
    procedure GetAvailableMediaTypesForMandate(Mandate: Text): List of [Text]
    var
        HttpExecutor: Codeunit "Http Executor";
        Request: Codeunit Requests;
        ValueArray: JsonArray;
        ResponseJson: JsonObject;
        MediaTypeList: List of [Text];
        ResponseContent: Text;
    begin
        // Validate input
        if Mandate = '' then begin
            Session.LogMessage('', 'Empty mandate provided to GetAvailableMediaTypesForMandate', Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', AvalaraCategoryTok);
            exit(GetDefaultMediaTypes());
        end;

        // Call Avalara API
        Request.Init();
        Request.Authenticate().CreateGetMandates(Mandate);
        ResponseContent := HttpExecutor.ExecuteHttpRequest(Request);

        // Handle API failure
        if ResponseContent = '' then begin
            Session.LogMessage('', StrSubstNo(FailedToRetrieveMediaTypesMsg, Mandate), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', AvalaraCategoryTok);
            exit(GetDefaultMediaTypes());
        end;

        // Parse JSON response
        if not TryParseMediaTypesResponse(ResponseContent, ResponseJson, ValueArray) then begin
            Session.LogMessage('', StrSubstNo(InvalidJsonResponseMsg, Mandate), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', AvalaraCategoryTok);
            exit(GetDefaultMediaTypes());
        end;

        // Extract media types from response
        MediaTypeList := ExtractMediaTypesFromArray(ValueArray);

        // Fallback to defaults if no media types found
        if MediaTypeList.Count = 0 then
            exit(GetDefaultMediaTypes());

        Session.LogMessage('', StrSubstNo(RetrievedMediaTypesMsg, MediaTypeList.Count, Mandate), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', AvalaraCategoryTok);

        exit(MediaTypeList);
    end;

    local procedure TryParseMediaTypesResponse(ResponseContent: Text; var ResponseJson: JsonObject; var ValueArray: JsonArray): Boolean
    var
        ValueToken: JsonToken;
    begin
        // Parse root JSON object
        if not ResponseJson.ReadFrom(ResponseContent) then
            exit(false);

        // Get 'value' array from response
        if not ResponseJson.Get(JsonFieldValueTok, ValueToken) then
            exit(false);

        if not ValueToken.IsArray() then
            exit(false);

        ValueArray := ValueToken.AsArray();
        exit(true);
    end;

    local procedure ExtractMediaTypesFromArray(ValueArray: JsonArray): List of [Text]
    var
        ItemObject: JsonObject;
        ItemToken: JsonToken;
        MediaTypeList: List of [Text];
    begin
        foreach ItemToken in ValueArray do
            if ItemToken.IsObject() then begin
                ItemObject := ItemToken.AsObject();
                ExtractMediaTypesFromItem(ItemObject, MediaTypeList);
            end;

        exit(MediaTypeList);
    end;

    local procedure ExtractMediaTypesFromItem(ItemObject: JsonObject; var MediaTypeList: List of [Text])
    var
        ArrayElementToken: JsonToken;
        MediaTypeToken: JsonToken;
    begin
        // Look for 'getInvoiceAvailableMediaType' field
        if not ItemObject.Get(JsonFieldGetInvoiceMediaTypeTok, MediaTypeToken) then
            exit;

        // Handle array of media types
        if MediaTypeToken.IsArray() then begin
            foreach ArrayElementToken in MediaTypeToken.AsArray() do
                AddMediaTypeIfValid(ArrayElementToken, MediaTypeList);
            exit;
        end;

        // Handle single media type value
        if MediaTypeToken.IsValue() then
            AddMediaTypeIfValid(MediaTypeToken, MediaTypeList);
    end;

    local procedure AddMediaTypeIfValid(MediaTypeToken: JsonToken; var MediaTypeList: List of [Text])
    var
        MediaTypeValue: JsonValue;
        MediaTypeText: Text;
    begin
        if not MediaTypeToken.IsValue() then
            exit;

        MediaTypeValue := MediaTypeToken.AsValue();

        if MediaTypeValue.IsNull() then
            exit;

        MediaTypeText := MediaTypeValue.AsText();

        if MediaTypeText = '' then
            exit;

        // List.Contains handles duplicate checking automatically
        if not MediaTypeList.Contains(MediaTypeText) then
            MediaTypeList.Add(MediaTypeText);
    end;

    local procedure GetDefaultMediaTypes(): List of [Text]
    var
        DefaultMediaTypes: List of [Text];
    begin
        // Provide sensible defaults when API fails or returns no data
        DefaultMediaTypes.Add(MediaTypeXmlTok);
        DefaultMediaTypes.Add(MediaTypePdfTok);
        DefaultMediaTypes.Add(MediaTypeUblXmlTok);

        exit(DefaultMediaTypes);
    end;

    // -------- JSON helpers --------

    local procedure GetInt(var Obj: JsonObject; Name: Text): Integer
    var
        IntVal: Integer;
        T: JsonToken;
        V: JsonValue;
    begin
        if Obj.Get(Name, T) and T.IsValue then begin
            V := T.AsValue();

            if V.IsNull then
                exit(0);

            // Works for:
            // - JSON number (e.g. 123)
            // - JSON string containing digits (e.g. "123")
            if Evaluate(IntVal, V.AsText()) then
                exit(IntVal);
        end;

        exit(0);
    end;

    local procedure GetText(var Obj: JsonObject; Name: Text): Text
    var
        T: JsonToken;
        V: JsonValue;
    begin
        if Obj.Get(Name, T) and T.IsValue then begin
            V := T.AsValue();
            if V.IsNull then
                exit('');
            exit(V.AsText());
        end;
        exit('');
    end;

    local procedure GetAcceptedValues(var Obj: JsonObject): Text
    var
        i: Integer;
        Arr: JsonArray;
        ElemTok: JsonToken;
        T: JsonToken;
        V: JsonValue;
        ResultTxt: Text;
    begin
        if Obj.Get(JsonFieldAcceptedValuesTok, T) and T.IsArray then begin
            Arr := T.AsArray();
            for i := 0 to Arr.Count() - 1 do begin
                Arr.Get(i, ElemTok);
                if ElemTok.IsValue then begin
                    V := ElemTok.AsValue();
                    if not V.IsNull then begin
                        if ResultTxt <> '' then
                            ResultTxt += '|';
                        ResultTxt += V.AsText();
                    end;
                end;
            end;
        end;
        exit(ResultTxt);
    end;

    // -------- Namespace mapping --------

    local procedure SetNamespace(var ItemObj: JsonObject; var AvalaraInputField: Record "Avalara Input Field")
    var
        NsObj: JsonObject;
        T: JsonToken;
    begin
        if ItemObj.Get(JsonFieldNamespaceTok, T) and T.IsObject then begin
            NsObj := T.AsObject();

            SetTextField(
                AvalaraInputField,
                AvalaraInputField.FieldNo(NamespacePrefix),
                GetText(NsObj, JsonFieldPrefixTok));

            SetTextField(
                AvalaraInputField,
                AvalaraInputField.FieldNo(NamespaceValue),
                GetText(NsObj, 'value'));
        end;
    end;

    // -------- Generic setter with length safety --------

    local procedure SetTextField(var AvalaraInputField: Record "Avalara Input Field"; FieldNo: Integer; Value: Text)
    var
        RecRef: RecordRef;
        FRef: FieldRef;
        MaxLen: Integer;
    begin
        RecRef.GetTable(AvalaraInputField);
        FRef := RecRef.Field(FieldNo);

        if FRef.Type in [FieldType::Text, FieldType::Code] then begin
            MaxLen := FRef.Length;
            if StrLen(Value) > MaxLen then
                Value := CopyStr(Value, 1, MaxLen);
        end;

        FRef.Value := Value;
        RecRef.SetTable(AvalaraInputField);
    end;

    local procedure SetIntegerField(var AvalaraInputField: Record "Avalara Input Field"; FieldNo: Integer; Value: Integer)
    var
        RecRef: RecordRef;
        FRef: FieldRef;
    begin
        RecRef.GetTable(AvalaraInputField);
        FRef := RecRef.Field(FieldNo);

        // Only set if the field is an Integer or BigInteger type
        case FRef.Type of
            FieldType::Integer,
            FieldType::BigInteger:
                FRef.Value := Value;
            else
                Error(SetIntegerFieldTypeErr, FieldNo);
        end;

        RecRef.SetTable(AvalaraInputField);
    end;

    procedure CreateBaseDefinitions(Mandate: Text)
    var
        ProgressDialog: Dialog;
        CreatingDefsMsg: Label 'Creating Data Exchange Definitions...\\#1##################', Comment = '#1 = current definition name';
        DefsCreatedMsg: Label 'Data Exchange Definitions for mandate %1 have been created successfully.', Comment = '%1 = Mandate code';
        PurchCrMemoDefCodeLbl: Label 'AVA%1PCM', Locked = true;
        PurchCrMemoDisplayNameLbl: Label 'Avalara %1 Purchase Credit Memo', Comment = '%1 = Mandate code';
        PurchCrMemoImportResLbl: Label 'DataExchDefs/AvalaraPurchaseCrMemoImport.xml', Locked = true;
        PurchInvDefCodeLbl: Label 'AVA%1PINV', Locked = true;
        PurchInvDisplayNameLbl: Label 'Avalara %1 Purchase Invoice', Comment = '%1 = Mandate code';
        PurchInvImportResLbl: Label 'DataExchDefs/AvalaraPurchaseInvoiceImport.xml', Locked = true;
        SalesCrMemoDefCodeLbl: Label 'AVA%1SCM', Locked = true;
        SalesCrMemoDisplayNameLbl: Label 'Avalara %1 Sales Credit Memo', Comment = '%1 = Mandate code';
        SalesCrMemoExportResLbl: Label 'DataExchDefs/AvalaraSalesCrMemoExport.xml', Locked = true;
        SalesInvDefCodeLbl: Label 'AVA%1SINV', Locked = true;
        SalesInvDisplayNameLbl: Label 'Avalara %1 Sales Invoice', Comment = '%1 = Mandate code';
        SalesInvExportResLbl: Label 'DataExchDefs/AvalaraSalesInvoiceExport.xml', Locked = true;
    begin
        ProgressDialog.Open(CreatingDefsMsg);

        CreateSingleDataExchDef(ProgressDialog, Mandate, SalesInvDefCodeLbl, SalesInvDisplayNameLbl, SalesInvExportResLbl);
        CreateSingleDataExchDef(ProgressDialog, Mandate, SalesCrMemoDefCodeLbl, SalesCrMemoDisplayNameLbl, SalesCrMemoExportResLbl);
        CreateSingleDataExchDef(ProgressDialog, Mandate, PurchInvDefCodeLbl, PurchInvDisplayNameLbl, PurchInvImportResLbl);
        CreateSingleDataExchDef(ProgressDialog, Mandate, PurchCrMemoDefCodeLbl, PurchCrMemoDisplayNameLbl, PurchCrMemoImportResLbl);

        ProgressDialog.Close();
        Message(StrSubstNo(DefsCreatedMsg, Mandate));
    end;

    local procedure CreateSingleDataExchDef(var ProgressDialog: Dialog; Mandate: Text; DefCodeTemplate: Text; DisplayNameTemplate: Text; ResourcePath: Text)
    var
        DisplayName: Text;
        XmlTemplate: Text;
    begin
        DisplayName := StrSubstNo(DisplayNameTemplate, Mandate);
        ProgressDialog.Update(1, DisplayName);
        DeleteDataExchDefIfExists(StrSubstNo(DefCodeTemplate, Mandate));
        XmlTemplate := NavApp.GetResourceAsText(ResourcePath, TextEncoding::UTF8);
        ImportDataExchDefFromXmlTemplate(XmlTemplate, Mandate, DisplayName);
    end;

    local procedure DeleteDataExchDefIfExists(DefCodeText: Text)
    var
        DataExchDef: Record "Data Exch. Def";
        DefCode: Code[20];
    begin
        DefCode := CopyStr(DefCodeText, 1, MaxStrLen(DefCode));
        if DataExchDef.Get(DefCode) then
            DataExchDef.Delete(true);
    end;

    local procedure ImportDataExchDefFromXmlTemplate(XmlTemplate: Text; Mandate: Text; DisplayName: Text)
    var
        TempBlob: Codeunit "Temp Blob";
        XMLInStream: InStream;
        XMLOutStream: OutStream;
        DxTxt: Text;
    begin
        DxTxt := StrSubstNo(XmlTemplate, Mandate, DisplayName);
        TempBlob.CreateOutStream(XMLOutStream);
        XMLOutStream.WriteText(DxTxt);
        TempBlob.CreateInStream(XMLInStream);
        Xmlport.Import(Xmlport::"Imp / Exp Data Exch Def & Map", XMLInStream);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Document Attachment", OnBeforeInsertAttachment, '', false, false)]
    local procedure DocumentAttachmentOnBeforeInsertAttachment(var DocumentAttachment: Record "Document Attachment"; var RecRef: RecordRef)
    var
        EDocument: Record "E-Document";
    begin
        if RecRef.Number <> Database::"E-Document" then
            exit;

        RecRef.SetTable(EDocument);

        if not IsEDocumentLinkedToAvalara(EDocument."Entry No") then
            exit;

        DocumentAttachment."E-Document Attachment" := true;
        DocumentAttachment."E-Document Entry No." := EDocument."Entry No";
    end;

    local procedure IsEDocumentLinkedToAvalara(EDocEntryNo: Integer): Boolean
    var
        EDocumentService: Record "E-Document Service";
        EDocumentServiceStatus: Record "E-Document Service Status";
    begin
        EDocumentServiceStatus.SetRange("E-Document Entry No", EDocEntryNo);
        if EDocumentServiceStatus.FindSet() then
            repeat
                if EDocumentService.Get(EDocumentServiceStatus."E-Document Service Code") then
                    if EDocumentService."Service Integration V2" = EDocumentService."Service Integration V2"::Avalara then
                        exit(true);
            until EDocumentServiceStatus.Next() = 0;
        exit(false);
    end;

    procedure EnsureMaintenanceJobQueueEntry()
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        // Look for an existing entry for Codeunit 6373
        JobQueueEntry.Reset();
        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);
        JobQueueEntry.SetRange("Object ID to Run", Codeunit::Maintenance);

        if not JobQueueEntry.IsEmpty then begin
            Message(
              JobQueueExistsMsg,
              JobQueueEntry."Entry No.", JobQueueEntry."Object ID to Run");
            exit;
        end;

        // Create a new Job Queue Entry
        JobQueueEntry.Init();
        JobQueueEntry.Insert(true);

        JobQueueEntry.Validate("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);
        JobQueueEntry.Validate("Object ID to Run", Codeunit::Maintenance);
        JobQueueEntry.Description := FetchAvalaraDocsDescTxt;

        JobQueueEntry."User ID" := CopyStr(UserId(), 1, MaxStrLen(JobQueueEntry."User ID"));
        JobQueueEntry."Earliest Start Date/Time" := CurrentDateTime;
        JobQueueEntry."Recurring Job" := true;
        JobQueueEntry."Run on Mondays" := true;
        JobQueueEntry."Run on Tuesdays" := true;
        JobQueueEntry."Run on Wednesdays" := true;
        JobQueueEntry."Run on Thursdays" := true;
        JobQueueEntry."Run on Fridays" := true;
        JobQueueEntry."Run on Saturdays" := true;
        JobQueueEntry."Run on Sundays" := true;
        JobQueueEntry."No. of Minutes between Runs" := 5; // ← change interval here
        JobQueueEntry."Maximum No. of Attempts to Run" := 3;

        JobQueueEntry.Validate(Status, JobQueueEntry.Status::Ready);

        JobQueueEntry.Modify(true);

        Message(
          JobQueueCreatedMsg,
          JobQueueEntry."Entry No.", JobQueueEntry."Object ID to Run", JobQueueEntry."No. of Minutes between Runs");
    end;

    procedure GetSafeFilenameWithExtension(FileId: Text; MediaType: Text): Text
    var
        FileExt: Text;
        Normalized: Text;
    begin
        // Normalize media subtype (strip "application/")
        if MediaType.StartsWith('application/') then
            Normalized := MediaType.Substring(13)
        else
            Normalized := MediaType;

        // Replace invalid filename chars
        Normalized := Normalized.Replace('.', '_');
        Normalized := Normalized.Replace('+', '-');

        // Determine file extension
        FileExt := GetFileExtensionFromMediaType(MediaType);

        exit(StrSubstNo(SafeFilenameFormatMsg, FileId, Normalized, FileExt));
    end;

    local procedure GetFileExtensionFromMediaType(MediaType: Text): Text
    var
        SemiPos: Integer;
        BaseType: Text;
    begin
        // Normalise (trim + lower)
        BaseType := LowerCase(DelChr(MediaType, '<>', ' '));

        // Strip parameters e.g. "application/json; charset=utf-8"
        SemiPos := StrPos(BaseType, ';');
        if SemiPos > 0 then
            BaseType := CopyStr(BaseType, 1, SemiPos - 1);

        // Some services send empty / unknown
        if BaseType = '' then
            exit('.bin');

        // Exact matches (most common)
        case BaseType of
            'application/pdf':
                exit('.pdf');

            'application/zip', 'application/x-zip-compressed':
                exit('.zip');

            'application/xml', 'text/xml':
                exit('.xml');

            'application/json':
                exit('.json');

            'image/png':
                exit('.png');

            'image/jpeg', 'image/jpg':
                exit('.jpg');

            'image/gif':
                exit('.gif');

            'text/plain':
                exit('.txt');

            'text/csv':
                exit('.csv');

            'text/html':
                exit('.html');
        end;

        // Structured syntax suffixes: application/*+xml, application/*+json
        if BaseType.EndsWith('+xml') then
            exit('.xml');

        if BaseType.EndsWith('+json') then
            exit('.json');

        // Text family fallback (e.g. text/markdown, text/calendar, etc.)
        if BaseType.StartsWith('text/') then
            exit('.txt');

        // Conservative default
        exit('.bin');
    end;

    [EventSubscriber(ObjectType::Table, Database::"Transformation Rule", 'OnTransformation', '', false, false)]
    local procedure OnTransformation(TransformationCode: Code[20]; InputText: Text; var OutputText: Text)
    var
        TransformationRule: Record "Transformation Rule";
        RecRef: RecordRef;
        PrimaryFieldRef: FieldRef;
        ResultFieldRef: FieldRef;
        SecondaryFieldRef: FieldRef;
    begin
        if not TransformationRule.Get(TransformationCode) then
            exit;

        if TransformationRule."Transformation Type" <> TransformationRule."Transformation Type"::"Avalara Lookup" then
            exit;

        // Validate configuration
        if TransformationRule."Lookup Table ID" = 0 then
            Error(LookupTableIdRequiredErr, TransformationCode);

        if TransformationRule."Primary Field No." = 0 then
            Error(PrimaryFieldNoRequiredErr, TransformationCode);

        if TransformationRule."Result Field No." = 0 then
            Error(ResultFieldNoRequiredErr, TransformationCode);

        // Perform the lookup
        RecRef.Open(TransformationRule."Lookup Table ID");

        // Set filter on primary field (match input value)
        PrimaryFieldRef := RecRef.Field(TransformationRule."Primary Field No.");
        PrimaryFieldRef.SetRange(InputText);

        // Set filter on secondary field if configured (match key)
        if (TransformationRule."Secondary Field No." <> 0) and (TransformationRule."Secondary Filter Value" <> '') then begin
            SecondaryFieldRef := RecRef.Field(TransformationRule."Secondary Field No.");
            SecondaryFieldRef.SetRange(TransformationRule."Secondary Filter Value");
        end;

        // Find first match
        if RecRef.FindFirst() then begin
            ResultFieldRef := RecRef.Field(TransformationRule."Result Field No.");
            OutputText := Format(ResultFieldRef.Value);
        end else
            OutputText := ''; // Return blank if no match found

        RecRef.Close();
    end;

    local procedure GetAvalaraDocumentId(AppliesToDocNo: Code[20]; AppliesToDocType: Enum "Gen. Journal Document Type"): Text[50]
    var
        EDocument: Record "E-Document";
    begin
        EDocument.SetLoadFields("Avalara Document Id");
        EDocument.SetRange("Document No.", AppliesToDocNo);

        case AppliesToDocType of
            AppliesToDocType::Invoice:
                EDocument.SetRange("Document Type", EDocument."Document Type"::"Sales Invoice");
        end;

        if EDocument.FindFirst() then
            exit(EDocument."Avalara Document Id");
    end;

    internal procedure IsAvalaraActive(): Boolean
    var
        EDocumentService: Record "E-Document Service";
    begin
        EDocumentService.SetLoadFields("Service Integration V2");
        EDocumentService.SetRange("Service Integration V2", EDocumentService."Service Integration V2"::Avalara);
        if not EDocumentService.IsEmpty then
            exit(true);
    end;


    [EventSubscriber(ObjectType::Table, Database::"Sales Header", 'OnAfterValidateEvent', 'Applies-to Doc. No.', true, true)]
    local procedure OnAfterValidateAppliesToDocNo(var Rec: Record "Sales Header")
    begin
        Rec."Avalara Doc. ID" := GetAvalaraDocumentId(Rec."Applies-to Doc. No.", Rec."Applies-to Doc. Type");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Copy Document Mgt.", OnBeforeModifySalesHeader, '', false, false)]
    local procedure OnBeforeModifySalesHeader(var ToSalesHeader: Record "Sales Header"; FromDocNo: Code[20]; FromDocType: Option)
    var
        AppliesToDocType: Enum "Gen. Journal Document Type";
        SalesDocumentTypeFrom: Enum "Sales Document Type From";
    begin
        case FromDocType of
            SalesDocumentTypeFrom::Invoice.AsInteger():
                AppliesToDocType := AppliesToDocType::Invoice;
        end;

        ToSalesHeader."Avalara Doc. ID" := GetAvalaraDocumentId(FromDocNo, AppliesToDocType);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Header", OnAfterAppliesToDocNoOnLookup, '', false, false)]
    local procedure OnAfterAppliesToDocNoOnLookup(var SalesHeader: Record "Sales Header")
    begin
        SalesHeader."Avalara Doc. ID" := GetAvalaraDocumentId(SalesHeader."Applies-to Doc. No.", SalesHeader."Applies-to Doc. Type");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnBeforeSalesCrMemoHeaderInsert', '', false, false)]
    local procedure OnBeforeSalesCrMemoHeaderInsert(var SalesCrMemoHeader: Record "Sales Cr.Memo Header"; SalesHeader: Record "Sales Header")
    begin
        SalesCrMemoHeader."Avalara Doc. ID" := SalesHeader."Avalara Doc. ID";
    end;

    /// <summary>
    /// Parse an ISO 8601 datetime string (e.g. 2025-04-16T14:30:00.123Z, 2025-04-16T14:30:00+02:00)
    /// into a BC DateTime value.
    /// </summary>
    procedure TryParseIsoDateTime(IsoText: Text; var Result: DateTime): Boolean
    var
        DotPos: Integer;
        OffsetPos: Integer;
        Normalized: Text;
    begin
        Normalized := IsoText;

        // Strip trailing 'Z' (UTC indicator) if present
        if (StrLen(Normalized) > 0) and ((Normalized[StrLen(Normalized)] = 'Z') or (Normalized[StrLen(Normalized)] = 'z')) then
            Normalized := CopyStr(Normalized, 1, StrLen(Normalized) - 1);

        // Strip timezone offset (+HH:MM or -HH:MM) after the time part
        // Look for +/- after the T separator to avoid matching the date's hyphens
        OffsetPos := FindTimezoneOffsetPos(Normalized);
        if OffsetPos > 0 then
            Normalized := CopyStr(Normalized, 1, OffsetPos - 1);

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

    local procedure FindTimezoneOffsetPos(DateTimeText: Text): Integer
    var
        TSeparatorFound: Boolean;
        I: Integer;
    begin
        for I := 1 to StrLen(DateTimeText) do begin
            if DateTimeText[I] = 'T' then
                TSeparatorFound := true;
            if TSeparatorFound and ((DateTimeText[I] = '+') or (DateTimeText[I] = '-')) then
                exit(I);
        end;
        exit(0);
    end;
}
