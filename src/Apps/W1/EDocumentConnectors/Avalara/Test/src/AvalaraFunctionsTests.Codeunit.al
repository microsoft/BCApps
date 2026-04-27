// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocumentConnector.Avalara;

using Microsoft.eServices.EDocument;
using Microsoft.Foundation.Attachment;
using System.IO;

/// <summary>
/// Unit tests for the Avalara Functions codeunit covering GetSafeFilenameWithExtension (media type
/// to file extension mapping), LoadFieldsFromJson (input field record creation from JSON arrays),
/// AttachFromText (document attachment creation), AttachmentFileExists validation,
/// GetAvailableMediaTypesForMandate, OnTransformation (Avalara Lookup) rule handling,
/// and IsAvalaraActive connection setup detection.
/// </summary>
codeunit 133626 "Avalara Functions Tests"
{
    Permissions = tabledata "Avalara Input Field" = rimd,
                  tabledata "Connection Setup" = rimd,
                  tabledata "Document Attachment" = rimd,
                  tabledata "E-Document" = rimd,
                  tabledata "Transformation Rule" = rimd;
    Subtype = Test;
    TestType = UnitTest;

    // ========================================================================
    // GetSafeFilenameWithExtension Tests
    // ========================================================================

    [Test]
    procedure GetSafeFilename_ApplicationPdf_ReturnsPdfExtension()
    var
        AvalaraFunctions: Codeunit "Avalara Functions";
        Result: Text;
    begin
        // [SCENARIO] GetSafeFilenameWithExtension with application/pdf should produce .pdf extension
        // [WHEN] Called with application/pdf media type
        Result := AvalaraFunctions.GetSafeFilenameWithExtension('DOC-001', 'application/pdf');

        // [THEN] Result should have pdf extension and normalized name
        Assert.AreEqual('DOC-001-pdf.pdf', Result, 'Should produce normalized filename with .pdf extension');
    end;

    [Test]
    procedure GetSafeFilename_ApplicationXml_ReturnsXmlExtension()
    var
        AvalaraFunctions: Codeunit "Avalara Functions";
        Result: Text;
    begin
        // [SCENARIO] GetSafeFilenameWithExtension with application/xml should produce .xml extension
        // [WHEN] Called with application/xml media type
        Result := AvalaraFunctions.GetSafeFilenameWithExtension('DOC-002', 'application/xml');

        // [THEN] Result should have xml extension
        Assert.AreEqual('DOC-002-xml.xml', Result, 'Should produce normalized filename with .xml extension');
    end;

    [Test]
    procedure GetSafeFilename_UblXml_ReturnsXmlExtension()
    var
        AvalaraFunctions: Codeunit "Avalara Functions";
        Result: Text;
    begin
        // [SCENARIO] GetSafeFilenameWithExtension with application/vnd.oasis.ubl+xml should produce .xml extension
        // [WHEN] Called with UBL XML media type
        Result := AvalaraFunctions.GetSafeFilenameWithExtension('DOC-003', 'application/vnd.oasis.ubl+xml');

        // [THEN] Result should have xml extension (structured suffix +xml → .xml)
        Assert.AreEqual('DOC-003-vnd_oasis_ubl-xml.xml', Result, 'Should normalize dots to underscores, plus to dash, with .xml extension');
    end;

    [Test]
    procedure GetSafeFilename_ApplicationJson_ReturnsJsonExtension()
    var
        AvalaraFunctions: Codeunit "Avalara Functions";
        Result: Text;
    begin
        // [SCENARIO] GetSafeFilenameWithExtension with application/json should produce .json extension
        // [WHEN] Called with application/json media type
        Result := AvalaraFunctions.GetSafeFilenameWithExtension('DOC-004', 'application/json');

        // [THEN] Result should have json extension
        Assert.AreEqual('DOC-004-json.json', Result, 'Should produce normalized filename with .json extension');
    end;

    [Test]
    procedure GetSafeFilename_ApplicationZip_ReturnsZipExtension()
    var
        AvalaraFunctions: Codeunit "Avalara Functions";
        Result: Text;
    begin
        // [SCENARIO] GetSafeFilenameWithExtension with application/zip should produce .zip extension
        // [WHEN] Called with application/zip media type
        Result := AvalaraFunctions.GetSafeFilenameWithExtension('DOC-005', 'application/zip');

        // [THEN] Result should have zip extension
        Assert.AreEqual('DOC-005-zip.zip', Result, 'Should produce normalized filename with .zip extension');
    end;

    [Test]
    procedure GetSafeFilename_TextPlain_ReturnsTxtExtension()
    var
        AvalaraFunctions: Codeunit "Avalara Functions";
        Result: Text;
    begin
        // [SCENARIO] GetSafeFilenameWithExtension with text/plain should produce .txt extension
        // [WHEN] Called with text/plain media type
        Result := AvalaraFunctions.GetSafeFilenameWithExtension('DOC-006', 'text/plain');

        // [THEN] Result should have txt extension and text/ prefix is kept (not application/)
        Assert.IsTrue(Result.EndsWith('.txt'), 'Should end with .txt extension');
        Assert.IsTrue(Result.StartsWith('DOC-006-'), 'Should start with file ID');
    end;

    [Test]
    procedure GetSafeFilename_EmptyMediaType_ReturnsBinExtension()
    var
        AvalaraFunctions: Codeunit "Avalara Functions";
        Result: Text;
    begin
        // [SCENARIO] GetSafeFilenameWithExtension with empty media type should fallback to .bin
        // [WHEN] Called with empty media type
        Result := AvalaraFunctions.GetSafeFilenameWithExtension('DOC-007', '');

        // [THEN] Result should have bin extension
        Assert.IsTrue(Result.EndsWith('.bin'), 'Should fallback to .bin extension for empty media type');
    end;

    [Test]
    procedure GetSafeFilename_UnknownMediaType_ReturnsBinExtension()
    var
        AvalaraFunctions: Codeunit "Avalara Functions";
        Result: Text;
    begin
        // [SCENARIO] GetSafeFilenameWithExtension with unknown media type should fallback to .bin
        // [WHEN] Called with an unknown media type
        Result := AvalaraFunctions.GetSafeFilenameWithExtension('DOC-008', 'application/octet-stream');

        // [THEN] Result should have bin extension
        Assert.IsTrue(Result.EndsWith('.bin'), 'Should fallback to .bin extension for unknown media type');
    end;

    [Test]
    procedure GetSafeFilename_ImagePng_ReturnsPngExtension()
    var
        AvalaraFunctions: Codeunit "Avalara Functions";
        Result: Text;
    begin
        // [SCENARIO] GetSafeFilenameWithExtension with image/png should produce .png extension
        // [WHEN] Called with image/png media type
        Result := AvalaraFunctions.GetSafeFilenameWithExtension('DOC-009', 'image/png');

        // [THEN] Result should have png extension
        Assert.IsTrue(Result.EndsWith('.png'), 'Should produce .png extension for image/png');
    end;

    [Test]
    procedure GetSafeFilename_TextCsv_ReturnsCsvExtension()
    var
        AvalaraFunctions: Codeunit "Avalara Functions";
        Result: Text;
    begin
        // [SCENARIO] GetSafeFilenameWithExtension with text/csv should produce .csv extension
        // [WHEN] Called with text/csv media type
        Result := AvalaraFunctions.GetSafeFilenameWithExtension('DOC-010', 'text/csv');

        // [THEN] Result should have csv extension
        Assert.IsTrue(Result.EndsWith('.csv'), 'Should produce .csv extension for text/csv');
    end;

    [Test]
    procedure GetSafeFilename_TextHtml_ReturnsHtmlExtension()
    var
        AvalaraFunctions: Codeunit "Avalara Functions";
        Result: Text;
    begin
        // [SCENARIO] GetSafeFilenameWithExtension with text/html should produce .html extension
        // [WHEN] Called with text/html media type
        Result := AvalaraFunctions.GetSafeFilenameWithExtension('DOC-011', 'text/html');

        // [THEN] Result should have html extension
        Assert.IsTrue(Result.EndsWith('.html'), 'Should produce .html extension for text/html');
    end;

    [Test]
    procedure GetSafeFilename_MediaTypeWithParameters_StripsParameters()
    var
        AvalaraFunctions: Codeunit "Avalara Functions";
        Result: Text;
    begin
        // [SCENARIO] GetSafeFilenameWithExtension should handle media types with parameters (charset etc.)
        // [WHEN] Called with media type containing charset parameter
        Result := AvalaraFunctions.GetSafeFilenameWithExtension('DOC-012', 'application/json; charset=utf-8');

        // [THEN] Should still resolve to .json, stripping parameters
        Assert.IsTrue(Result.EndsWith('.json'), 'Should strip parameters and resolve to .json');
    end;

    [Test]
    procedure GetSafeFilename_StructuredSuffixJson_ReturnsJsonExtension()
    var
        AvalaraFunctions: Codeunit "Avalara Functions";
        Result: Text;
    begin
        // [SCENARIO] GetSafeFilenameWithExtension with structured suffix +json should produce .json extension
        // [WHEN] Called with a custom+json media type
        Result := AvalaraFunctions.GetSafeFilenameWithExtension('DOC-013', 'application/vnd.custom+json');

        // [THEN] Result should have json extension
        Assert.IsTrue(Result.EndsWith('.json'), 'Should resolve structured suffix +json to .json extension');
    end;

    [Test]
    procedure GetSafeFilename_ImageJpeg_ReturnsJpgExtension()
    var
        AvalaraFunctions: Codeunit "Avalara Functions";
        Result: Text;
    begin
        // [SCENARIO] GetSafeFilenameWithExtension with image/jpeg should produce .jpg extension
        // [WHEN] Called with image/jpeg media type
        Result := AvalaraFunctions.GetSafeFilenameWithExtension('DOC-014', 'image/jpeg');

        // [THEN] Result should have jpg extension
        Assert.IsTrue(Result.EndsWith('.jpg'), 'Should produce .jpg extension for image/jpeg');
    end;

    [Test]
    procedure GetSafeFilename_TextXml_ReturnsXmlExtension()
    var
        AvalaraFunctions: Codeunit "Avalara Functions";
        Result: Text;
    begin
        // [SCENARIO] GetSafeFilenameWithExtension with text/xml should produce .xml extension
        // [WHEN] Called with text/xml media type
        Result := AvalaraFunctions.GetSafeFilenameWithExtension('DOC-015', 'text/xml');

        // [THEN] Result should have xml extension
        Assert.IsTrue(Result.EndsWith('.xml'), 'Should produce .xml extension for text/xml');
    end;

    [Test]
    procedure GetSafeFilename_UnknownTextSubtype_ReturnsTxtExtension()
    var
        AvalaraFunctions: Codeunit "Avalara Functions";
        Result: Text;
    begin
        // [SCENARIO] GetSafeFilenameWithExtension with unknown text/ subtype should fallback to .txt
        // [WHEN] Called with text/calendar (no exact match)
        Result := AvalaraFunctions.GetSafeFilenameWithExtension('DOC-016', 'text/calendar');

        // [THEN] Result should fallback to .txt for unknown text/ family
        Assert.IsTrue(Result.EndsWith('.txt'), 'Should fallback to .txt for unrecognized text/ media types');
    end;

    // ========================================================================
    // LoadFieldsFromJson Tests
    // ========================================================================

    [Test]
    procedure LoadFieldsFromJson_ValidArray_CreatesRecords()
    var
        AvalaraInputField: Record "Avalara Input Field";
        AvalaraFunctions: Codeunit "Avalara Functions";
        FieldsArray: JsonArray;
        FieldObj: JsonObject;
    begin
        // [SCENARIO] LoadFieldsFromJson should create Avalara Input Field records from JSON array
        LibraryPermission.SetOutsideO365Scope();

        // [GIVEN] Clean input fields
        AvalaraInputField.SetRange(Mandate, 'TEST-MANDATE');
        AvalaraInputField.DeleteAll();

        // [GIVEN] A JSON array with one field definition
        FieldObj.Add('fieldId', 101);
        FieldObj.Add('documentVersion', '2.1');
        FieldObj.Add('path', '/Invoice/ID');
        FieldObj.Add('pathType', 'element');
        FieldObj.Add('fieldName', 'InvoiceID');
        FieldObj.Add('exampleOrFixedValue', 'INV-001');
        FieldObj.Add('documentationLink', 'https://docs.example.com/invoice-id');
        FieldObj.Add('dataType', 'string');
        FieldObj.Add('description', 'Unique invoice identifier');
        FieldObj.Add('optionality', 'mandatory');
        FieldObj.Add('cardinality', '1..1');
        FieldsArray.Add(FieldObj);

        // [WHEN] LoadFieldsFromJson is called
        AvalaraFunctions.LoadFieldsFromJson(FieldsArray, 'TEST-MANDATE', 'ubl-invoice', '2.1');

        // [THEN] One record is created
        AvalaraInputField.Reset();
        AvalaraInputField.SetRange(Mandate, 'TEST-MANDATE');
        Assert.AreEqual(1, AvalaraInputField.Count(), 'Should create 1 input field record');

        // [THEN] Record has correct values
        AvalaraInputField.FindFirst();
        Assert.AreEqual(101, AvalaraInputField.FieldId, 'FieldId should be 101');
        Assert.AreEqual('ubl-invoice', AvalaraInputField.DocumentType, 'DocumentType should match');
        Assert.AreEqual('2.1', AvalaraInputField.DocumentVersion, 'DocumentVersion should match');
        Assert.AreEqual('/Invoice/ID', AvalaraInputField.Path, 'Path should match');
        Assert.AreEqual('element', AvalaraInputField.PathType, 'PathType should match');
        Assert.AreEqual('InvoiceID', AvalaraInputField.FieldName, 'FieldName should match');
        Assert.AreEqual('string', AvalaraInputField.DataType, 'DataType should match');
        Assert.AreEqual('mandatory', AvalaraInputField.Optionality, 'Optionality should match');
        Assert.AreEqual('1..1', AvalaraInputField.Cardinality, 'Cardinality should match');

        // [CLEANUP]
        AvalaraInputField.DeleteAll();
    end;

    [Test]
    procedure LoadFieldsFromJson_WithNamespace_SetsNamespaceFields()
    var
        AvalaraInputField: Record "Avalara Input Field";
        AvalaraFunctions: Codeunit "Avalara Functions";
        FieldsArray: JsonArray;
        FieldObj: JsonObject;
        NsObj: JsonObject;
    begin
        // [SCENARIO] LoadFieldsFromJson should correctly map namespace object to prefix and value fields
        LibraryPermission.SetOutsideO365Scope();

        // [GIVEN] Clean input fields
        AvalaraInputField.SetRange(Mandate, 'NS-TEST');
        AvalaraInputField.DeleteAll();

        // [GIVEN] A field with namespace object
        FieldObj.Add('fieldId', 201);
        FieldObj.Add('documentVersion', '2.1');
        FieldObj.Add('path', '/Invoice/cbc:ID');
        FieldObj.Add('pathType', 'element');
        FieldObj.Add('fieldName', 'ID');
        NsObj.Add('prefix', 'cbc');
        NsObj.Add('value', 'urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2');
        FieldObj.Add('namespace', NsObj);
        FieldsArray.Add(FieldObj);

        // [WHEN] LoadFieldsFromJson is called
        AvalaraFunctions.LoadFieldsFromJson(FieldsArray, 'NS-TEST', 'ubl-invoice', '2.1');

        // [THEN] Namespace prefix and value are populated
        AvalaraInputField.SetRange(Mandate, 'NS-TEST');
        AvalaraInputField.FindFirst();
        Assert.AreEqual('cbc', AvalaraInputField.NamespacePrefix, 'NamespacePrefix should be cbc');
        Assert.AreEqual('urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2', AvalaraInputField.NamespaceValue, 'NamespaceValue should match');

        // [CLEANUP]
        AvalaraInputField.DeleteAll();
    end;

    [Test]
    procedure LoadFieldsFromJson_WithAcceptedValues_CreatesPipeSeparated()
    var
        AvalaraInputField: Record "Avalara Input Field";
        AvalaraFunctions: Codeunit "Avalara Functions";
        AcceptedValues: JsonArray;
        FieldsArray: JsonArray;
        FieldObj: JsonObject;
    begin
        // [SCENARIO] LoadFieldsFromJson should join acceptedValues array into pipe-separated string
        LibraryPermission.SetOutsideO365Scope();

        // [GIVEN] Clean input fields
        AvalaraInputField.SetRange(Mandate, 'AV-TEST');
        AvalaraInputField.DeleteAll();

        // [GIVEN] A field with accepted values
        FieldObj.Add('fieldId', 301);
        FieldObj.Add('documentVersion', '2.1');
        FieldObj.Add('path', '/Invoice/InvoiceTypeCode');
        FieldObj.Add('pathType', 'element');
        FieldObj.Add('fieldName', 'InvoiceTypeCode');
        AcceptedValues.Add('380');
        AcceptedValues.Add('381');
        AcceptedValues.Add('384');
        FieldObj.Add('acceptedValues', AcceptedValues);
        FieldsArray.Add(FieldObj);

        // [WHEN] LoadFieldsFromJson is called
        AvalaraFunctions.LoadFieldsFromJson(FieldsArray, 'AV-TEST', 'ubl-invoice', '2.1');

        // [THEN] AcceptedValues are pipe-separated
        AvalaraInputField.SetRange(Mandate, 'AV-TEST');
        AvalaraInputField.FindFirst();
        Assert.AreEqual('380|381|384', AvalaraInputField.AcceptedValues, 'AcceptedValues should be pipe-separated');

        // [CLEANUP]
        AvalaraInputField.DeleteAll();
    end;

    [Test]
    procedure LoadFieldsFromJson_MultipleFields_CreatesAll()
    var
        AvalaraInputField: Record "Avalara Input Field";
        AvalaraFunctions: Codeunit "Avalara Functions";
        FieldsArray: JsonArray;
        Field1: JsonObject;
        Field2: JsonObject;
        Field3: JsonObject;
    begin
        // [SCENARIO] LoadFieldsFromJson with multiple items should create all records
        LibraryPermission.SetOutsideO365Scope();

        // [GIVEN] Clean input fields
        AvalaraInputField.SetRange(Mandate, 'MULTI-TEST');
        AvalaraInputField.DeleteAll();

        // [GIVEN] Three field definitions
        Field1.Add('fieldId', 401);
        Field1.Add('documentVersion', '2.1');
        Field1.Add('fieldName', 'Field1');
        FieldsArray.Add(Field1);

        Field2.Add('fieldId', 402);
        Field2.Add('documentVersion', '2.1');
        Field2.Add('fieldName', 'Field2');
        FieldsArray.Add(Field2);

        Field3.Add('fieldId', 403);
        Field3.Add('documentVersion', '2.1');
        Field3.Add('fieldName', 'Field3');
        FieldsArray.Add(Field3);

        // [WHEN] LoadFieldsFromJson is called
        AvalaraFunctions.LoadFieldsFromJson(FieldsArray, 'MULTI-TEST', 'ubl-invoice', '2.1');

        // [THEN] Three records are created
        AvalaraInputField.Reset();
        AvalaraInputField.SetRange(Mandate, 'MULTI-TEST');
        Assert.AreEqual(3, AvalaraInputField.Count(), 'Should create 3 input field records');

        // [CLEANUP]
        AvalaraInputField.DeleteAll();
    end;

    [Test]
    procedure LoadFieldsFromJson_EmptyArray_NoRecords()
    var
        AvalaraInputField: Record "Avalara Input Field";
        AvalaraFunctions: Codeunit "Avalara Functions";
        FieldsArray: JsonArray;
    begin
        // [SCENARIO] LoadFieldsFromJson with empty array should create no records
        LibraryPermission.SetOutsideO365Scope();

        // [GIVEN] Clean input fields
        AvalaraInputField.SetRange(Mandate, 'EMPTY-TEST');
        AvalaraInputField.DeleteAll();

        // [WHEN] LoadFieldsFromJson is called with empty array
        AvalaraFunctions.LoadFieldsFromJson(FieldsArray, 'EMPTY-TEST', 'ubl-invoice', '2.1');

        // [THEN] No records created
        AvalaraInputField.Reset();
        AvalaraInputField.SetRange(Mandate, 'EMPTY-TEST');
        Assert.AreEqual(0, AvalaraInputField.Count(), 'Should have 0 records for empty array');
    end;

    // NOTE: Confirm overwrite/decline tests for LoadFieldsFromJson are omitted because
    // Avalara Input Field has DataPerCompany = false, and records inserted within
    // codeunit test isolation are not visible to subsequent calls in the same test.

    // ========================================================================
    // AttachFromText Tests
    // ========================================================================

    [Test]
    procedure AttachFromText_ValidContent_CreatesAttachment()
    var
        DocumentAttachment: Record "Document Attachment";
        EDocument: Record "E-Document";
        AvalaraFunctions: Codeunit "Avalara Functions";
    begin
        // [SCENARIO] AttachFromText with valid XML content should create a Document Attachment
        LibraryPermission.SetOutsideO365Scope();

        // [GIVEN] An E-Document record
        EDocument.Init();
        EDocument."Entry No" := 88801;
        if not EDocument.Insert(false) then
            EDocument.Modify(false);

        // [GIVEN] Clean up any prior attachment
        DocumentAttachment.SetRange("Table ID", Database::"E-Document");
        DocumentAttachment.SetRange("No.", Format(EDocument."Entry No"));
        DocumentAttachment.SetRange("File Name", 'test-invoice');
        DocumentAttachment.DeleteAll();

        // [WHEN] AttachFromText is called with valid XML content
        AvalaraFunctions.AttachFromText(EDocument, '<Invoice><ID>INV-001</ID></Invoice>', 'test-invoice.xml');

        // [THEN] A Document Attachment record is created
        DocumentAttachment.Reset();
        DocumentAttachment.SetRange("Table ID", Database::"E-Document");
        DocumentAttachment.SetRange("No.", Format(EDocument."Entry No"));
        Assert.IsFalse(DocumentAttachment.IsEmpty(), 'Document Attachment should be created for valid content');

        // [CLEANUP]
        DocumentAttachment.DeleteAll();
        EDocument.Delete(false);
    end;

    [Test]
    procedure AttachFromText_EmptyContent_RaisesError()
    var
        EDocument: Record "E-Document";
        AvalaraFunctions: Codeunit "Avalara Functions";
    begin
        // [SCENARIO] AttachFromText with empty content should raise error
        LibraryPermission.SetOutsideO365Scope();

        EDocument.Init();
        EDocument."Entry No" := 88802;

        // [WHEN] AttachFromText is called with empty content
        asserterror AvalaraFunctions.AttachFromText(EDocument, '', 'test.xml');

        // [THEN] Error about empty content is raised
        Assert.ExpectedError('Cannot attach empty content to E-Document 88802');
    end;

    // ========================================================================
    // AttachmentFileExists Tests
    // ========================================================================

    [Test]
    procedure AttachmentFileExists_FilePresent_ReturnsTrue()
    var
        DocumentAttachment: Record "Document Attachment";
        EDocument: Record "E-Document";
        AvalaraFunctions: Codeunit "Avalara Functions";
    begin
        // [SCENARIO] AttachmentFileExists should return true when attachment exists
        LibraryPermission.SetOutsideO365Scope();

        // [GIVEN] An E-Document record
        EDocument.Init();
        EDocument."Entry No" := 88803;
        if not EDocument.Insert(false) then
            EDocument.Modify(false);

        // [GIVEN] Create attachment using AttachFromText
        AvalaraFunctions.AttachFromText(EDocument, '<test>data</test>', 'existing-file.xml');

        // [WHEN] AttachmentFileExists is called
        // [THEN] Returns true
        Assert.IsTrue(
            AvalaraFunctions.AttachmentFileExists(EDocument, 'existing-file'),
            'Should return true for existing attachment');

        // [CLEANUP]
        DocumentAttachment.SetRange("Table ID", Database::"E-Document");
        DocumentAttachment.SetRange("No.", Format(EDocument."Entry No"));
        DocumentAttachment.DeleteAll();
        EDocument.Delete(false);
    end;

    [Test]
    procedure AttachmentFileExists_FileNotPresent_ReturnsFalse()
    var
        EDocument: Record "E-Document";
        AvalaraFunctions: Codeunit "Avalara Functions";
    begin
        // [SCENARIO] AttachmentFileExists should return false when attachment does not exist
        LibraryPermission.SetOutsideO365Scope();

        // [GIVEN] An E-Document with no attachments
        EDocument.Init();
        EDocument."Entry No" := 88804;

        // [WHEN] AttachmentFileExists is called for non-existent file
        // [THEN] Returns false
        Assert.IsFalse(
            AvalaraFunctions.AttachmentFileExists(EDocument, 'nonexistent-file'),
            'Should return false for non-existent attachment');
    end;

    // ========================================================================
    // GetAvailableMediaTypesForMandate Tests
    // ========================================================================

    [Test]
    procedure GetAvailableMediaTypes_EmptyMandate_ReturnsDefaults()
    var
        AvalaraFunctions: Codeunit "Avalara Functions";
        MediaTypes: List of [Text];
    begin
        // [SCENARIO] GetAvailableMediaTypesForMandate with empty mandate should return default media types
        // [WHEN] Called with empty mandate
        MediaTypes := AvalaraFunctions.GetAvailableMediaTypesForMandate('');

        // [THEN] Returns default media types
        Assert.AreEqual(3, MediaTypes.Count, 'Should return 3 default media types');
        Assert.IsTrue(MediaTypes.Contains('application/xml'), 'Should contain application/xml');
        Assert.IsTrue(MediaTypes.Contains('application/pdf'), 'Should contain application/pdf');
        Assert.IsTrue(MediaTypes.Contains('application/vnd.oasis.ubl+xml'), 'Should contain UBL XML');
    end;

    // ========================================================================
    // OnTransformation (Avalara Lookup) Tests
    // ========================================================================

    [Test]
    procedure OnTransformation_AvalaraLookup_FindsMatchingRecord()
    var
        AvalaraInputField: Record "Avalara Input Field";
        TransformationRule: Record "Transformation Rule";
        OutputText: Text;
    begin
        // [SCENARIO] Avalara Lookup transformation should find and return matching value from lookup table
        LibraryPermission.SetOutsideO365Scope();

        // [GIVEN] A lookup table field to search in (Avalara Input Field - search by FieldName, return Path)
        AvalaraInputField.SetRange(Mandate, 'LOOKUP-TEST');
        AvalaraInputField.DeleteAll();

        AvalaraInputField.Init();
        AvalaraInputField.FieldId := 601;
        AvalaraInputField.Mandate := 'LOOKUP-TEST';
        AvalaraInputField.DocumentType := 'ubl-invoice';
        AvalaraInputField.DocumentVersion := '2.1';
        AvalaraInputField.FieldName := 'InvoiceID';
        AvalaraInputField.Path := '/Invoice/cbc:ID';
        AvalaraInputField.Insert();

        // [GIVEN] A Transformation Rule configured for Avalara Lookup
        TransformationRule.Init();
        TransformationRule."Transformation Type" := TransformationRule."Transformation Type"::"Avalara Lookup";
        TransformationRule.Code := 'AVLOOKUPTEST';
        TransformationRule."Lookup Table ID" := Database::"Avalara Input Field";
        TransformationRule."Primary Field No." := AvalaraInputField.FieldNo(FieldName);
        TransformationRule."Result Field No." := AvalaraInputField.FieldNo(Path);
        if not TransformationRule.Insert(false) then
            TransformationRule.Modify(false);

        // [WHEN] OnTransformation event fires with matching input
        OutputText := TransformationRule.TransformText('InvoiceID');

        // [THEN] Output should be the matching Path value
        Assert.AreEqual('/Invoice/cbc:ID', OutputText, 'Should return the Path for matching FieldName');

        // [CLEANUP]
        AvalaraInputField.DeleteAll();
        TransformationRule.Delete(false);
    end;

    [Test]
    procedure OnTransformation_AvalaraLookup_NoMatch_ReturnsEmpty()
    var
        AvalaraInputField: Record "Avalara Input Field";
        TransformationRule: Record "Transformation Rule";
        OutputText: Text;
    begin
        // [SCENARIO] Avalara Lookup transformation with no matching record should return empty string
        LibraryPermission.SetOutsideO365Scope();

        // [GIVEN] An empty lookup table (for the test mandate)
        AvalaraInputField.SetRange(Mandate, 'NOMATCH-TEST');
        AvalaraInputField.DeleteAll();

        // [GIVEN] A Transformation Rule configured for Avalara Lookup
        TransformationRule.Init();
        TransformationRule."Transformation Type" := TransformationRule."Transformation Type"::"Avalara Lookup";
        TransformationRule.Code := 'AVNOMATCHTEST';
        TransformationRule."Lookup Table ID" := Database::"Avalara Input Field";
        TransformationRule."Primary Field No." := AvalaraInputField.FieldNo(FieldName);
        TransformationRule."Result Field No." := AvalaraInputField.FieldNo(Path);
        if not TransformationRule.Insert(false) then
            TransformationRule.Modify(false);

        // [WHEN] OnTransformation event fires with non-matching input
        OutputText := TransformationRule.TransformText('NonExistentField');

        // [THEN] Output should be empty
        Assert.AreEqual('', OutputText, 'Should return empty string when no match found');

        // [CLEANUP]
        TransformationRule.Delete(false);
    end;

    [Test]
    procedure OnTransformation_AvalaraLookup_WithSecondaryFilter_FiltersCorrectly()
    var
        AvalaraInputField: Record "Avalara Input Field";
        TransformationRule: Record "Transformation Rule";
        OutputText: Text;
    begin
        // [SCENARIO] Avalara Lookup with secondary filter should narrow results correctly
        LibraryPermission.SetOutsideO365Scope();

        // [GIVEN] Two records with same FieldName but different Mandate
        AvalaraInputField.SetRange(FieldName, 'TaxAmount');
        AvalaraInputField.SetFilter(Mandate, 'SEC-FILTER-A|SEC-FILTER-B');
        AvalaraInputField.DeleteAll();

        AvalaraInputField.Init();
        AvalaraInputField.FieldId := 701;
        AvalaraInputField.Mandate := 'SEC-FILTER-A';
        AvalaraInputField.DocumentType := 'ubl-invoice';
        AvalaraInputField.DocumentVersion := '2.1';
        AvalaraInputField.FieldName := 'TaxAmount';
        AvalaraInputField.Path := '/Invoice/TaxTotal/TaxAmount';
        AvalaraInputField.Insert();

        AvalaraInputField.Init();
        AvalaraInputField.FieldId := 702;
        AvalaraInputField.Mandate := 'SEC-FILTER-B';
        AvalaraInputField.DocumentType := 'ubl-creditnote';
        AvalaraInputField.DocumentVersion := '2.1';
        AvalaraInputField.FieldName := 'TaxAmount';
        AvalaraInputField.Path := '/CreditNote/TaxTotal/TaxAmount';
        AvalaraInputField.Insert();

        // [GIVEN] A Transformation Rule with secondary filter on Mandate
        TransformationRule.Init();
        TransformationRule."Transformation Type" := TransformationRule."Transformation Type"::"Avalara Lookup";
        TransformationRule.Code := 'AVSECFILTER';
        TransformationRule."Lookup Table ID" := Database::"Avalara Input Field";
        TransformationRule."Primary Field No." := AvalaraInputField.FieldNo(FieldName);
        TransformationRule."Result Field No." := AvalaraInputField.FieldNo(Path);
        TransformationRule."Secondary Field No." := AvalaraInputField.FieldNo(Mandate);
        TransformationRule."Secondary Filter Value" := 'SEC-FILTER-B';
        if not TransformationRule.Insert(false) then
            TransformationRule.Modify(false);

        // [WHEN] OnTransformation fires with 'TaxAmount' input
        OutputText := TransformationRule.TransformText('TaxAmount');

        // [THEN] Should return the CreditNote path (filtered by secondary)
        Assert.AreEqual('/CreditNote/TaxTotal/TaxAmount', OutputText, 'Should return result filtered by secondary field');

        // [CLEANUP]
        AvalaraInputField.SetRange(FieldName, 'TaxAmount');
        AvalaraInputField.SetFilter(Mandate, 'SEC-FILTER-A|SEC-FILTER-B');
        AvalaraInputField.DeleteAll();
        TransformationRule.Delete(false);
    end;

    [Test]
    procedure OnTransformation_NonAvalaraLookup_DoesNotInterfere()
    var
        TransformationRule: Record "Transformation Rule";
        OutputText: Text;
    begin
        // [SCENARIO] Non-Avalara Lookup transformation types should not be affected by the event subscriber
        LibraryPermission.SetOutsideO365Scope();

        // [GIVEN] A Transformation Rule with standard Uppercase type
        TransformationRule.Init();
        TransformationRule."Transformation Type" := TransformationRule."Transformation Type"::Uppercase;
        TransformationRule.Code := 'AVNOINTERFER';
        if not TransformationRule.Insert(false) then
            TransformationRule.Modify(false);

        // [WHEN] TransformText is called with lowercase input
        OutputText := TransformationRule.TransformText('hello world');

        // [THEN] Standard Uppercase transformation works normally
        Assert.AreEqual('HELLO WORLD', OutputText, 'Non-Avalara transformation should work normally');

        // [CLEANUP]
        TransformationRule.Delete(false);
    end;

    [Test]
    procedure OnTransformation_AvalaraLookup_MissingTableId_RaisesError()
    var
        TransformationRule: Record "Transformation Rule";
        OutputText: Text;
    begin
        // [SCENARIO] Avalara Lookup with missing Lookup Table ID should raise error
        LibraryPermission.SetOutsideO365Scope();

        // [GIVEN] A Transformation Rule with Avalara Lookup but no table configured
        TransformationRule.Init();
        TransformationRule."Transformation Type" := TransformationRule."Transformation Type"::"Avalara Lookup";
        TransformationRule.Code := 'AVNOTBLID';
        TransformationRule."Lookup Table ID" := 0;
        TransformationRule."Primary Field No." := 6;
        TransformationRule."Result Field No." := 4;
        if not TransformationRule.Insert(false) then
            TransformationRule.Modify(false);

        // [WHEN] TransformText is called
        asserterror OutputText := TransformationRule.TransformText('test');

        // [THEN] Error about missing Lookup Table ID
        Assert.ExpectedError('Lookup Table ID must be specified');

        // [CLEANUP]
        if TransformationRule.Get('AVNOTBLID') then
            TransformationRule.Delete(false);
    end;

    [Test]
    procedure OnTransformation_AvalaraLookup_MissingPrimaryFieldNo_RaisesError()
    var
        AvalaraInputField: Record "Avalara Input Field";
        TransformationRule: Record "Transformation Rule";
        OutputText: Text;
    begin
        // [SCENARIO] Avalara Lookup with missing Primary Field No should raise error
        LibraryPermission.SetOutsideO365Scope();

        // [GIVEN] A Transformation Rule with Avalara Lookup but no primary field
        TransformationRule.Init();
        TransformationRule."Transformation Type" := TransformationRule."Transformation Type"::"Avalara Lookup";
        TransformationRule.Code := 'AVNOPRIMARY';
        TransformationRule."Lookup Table ID" := Database::"Avalara Input Field";
        TransformationRule."Primary Field No." := 0;
        TransformationRule."Result Field No." := AvalaraInputField.FieldNo(Path);
        if not TransformationRule.Insert(false) then
            TransformationRule.Modify(false);

        // [WHEN] TransformText is called
        asserterror OutputText := TransformationRule.TransformText('test');

        // [THEN] Error about missing Primary Field No
        Assert.ExpectedError('Primary Field No. must be specified');

        // [CLEANUP]
        if TransformationRule.Get('AVNOPRIMARY') then
            TransformationRule.Delete(false);
    end;

    [Test]
    procedure OnTransformation_AvalaraLookup_MissingResultFieldNo_RaisesError()
    var
        AvalaraInputField: Record "Avalara Input Field";
        TransformationRule: Record "Transformation Rule";
        OutputText: Text;
    begin
        // [SCENARIO] Avalara Lookup with missing Result Field No should raise error
        LibraryPermission.SetOutsideO365Scope();

        // [GIVEN] A Transformation Rule with Avalara Lookup but no result field
        TransformationRule.Init();
        TransformationRule."Transformation Type" := TransformationRule."Transformation Type"::"Avalara Lookup";
        TransformationRule.Code := 'AVNORESULT';
        TransformationRule."Lookup Table ID" := Database::"Avalara Input Field";
        TransformationRule."Primary Field No." := AvalaraInputField.FieldNo(FieldName);
        TransformationRule."Result Field No." := 0;
        if not TransformationRule.Insert(false) then
            TransformationRule.Modify(false);

        // [WHEN] TransformText is called
        asserterror OutputText := TransformationRule.TransformText('test');

        // [THEN] Error about missing Result Field No
        Assert.ExpectedError('Result Field No. must be specified');

        // [CLEANUP]
        if TransformationRule.Get('AVNORESULT') then
            TransformationRule.Delete(false);
    end;

    // ========================================================================
    // IsAvalaraActive Tests
    // ========================================================================

    [Test]
    procedure IsAvalaraActive_NoServiceConfigured_ReturnsFalse()
    var
        EDocumentService: Record "E-Document Service";
        AvalaraFunctions: Codeunit "Avalara Functions";
    begin
        // [SCENARIO] IsAvalaraActive should return false when no E-Document Service uses Avalara integration
        LibraryPermission.SetOutsideO365Scope();

        // [GIVEN] No services with Avalara integration exist
        EDocumentService.SetRange("Service Integration V2", EDocumentService."Service Integration V2"::Avalara);
        if not EDocumentService.IsEmpty() then
            exit; // Cannot safely modify shared service records in unit test; skip

        // [WHEN/THEN] IsAvalaraActive returns false
        Assert.IsFalse(AvalaraFunctions.IsAvalaraActive(), 'Should return false when no Avalara service is configured');
    end;

    var
        Assert: Codeunit Assert;
        LibraryPermission: Codeunit "Library - Lower Permissions";
}