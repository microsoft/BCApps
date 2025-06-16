// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.IO;

using System.Utilities;
using System.TestLibraries.Utilities;


codeunit 132601 "PDF Document Test"
{
    Access = Internal;
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";
        LengthErr: Label 'Outstream length should have length 0';

    [Test]
    procedure ValidPdfToPngImage()
    var
        PdfDocument: Codeunit "PDF Document";
        TempBlob: Codeunit "Temp Blob";
        ImageFormat: Enum "Image Format";
        PdfInstream, ImageStream : InStream;
    begin
        // Setup
        NavApp.GetResource('test.pdf', PdfInstream, TextEncoding::UTF8);
        TempBlob.CreateInStream(ImageStream);
        PdfDocument.Load(PdfInstream);
        PdfDocument.ConvertToImage(ImageStream, ImageFormat::Png, 1);
        Assert.AreNotEqual(0, TempBlob.Length(), LengthErr);
    end;

    [Test]
    procedure AttachmentFoundViaXMP()
    var
        PdfDocument: Codeunit "PDF Document";
        TempBlob: Codeunit "Temp Blob";
        PdfInstream: InStream;
        Success: Boolean;
    begin
        // [GIVEN] Load XRechnung.pdf with XMP metadata
        NavApp.GetResource('XRechnung.pdf', PdfInstream, TextEncoding::UTF8);

        // [WHEN] Attempt to get invoice attachment stream
        Success := PdfDocument.GetDocumentAttachmentStream(PdfInstream, TempBlob);

        // [THEN] Assert that the attachment is found via XMP metadata
        Assert.IsTrue(Success, 'Expected attachment to be found via XMP metadata');
        AssertStreamNotEmpty(TempBlob);
    end;

    [Test]
    procedure AttachmentFoundByName()
    var
        PdfDocument: Codeunit "PDF Document";
        TempBlob: Codeunit "Temp Blob";
        PdfInstream: InStream;
        Success: Boolean;
    begin
        // [GIVEN] Load XRechnung.pdf with known attachment name
        NavApp.GetResource('XRechnung.pdf', PdfInstream, TextEncoding::UTF8);

        // [WHEN] Attempt to get invoice attachment stream by known name
        Success := PdfDocument.GetDocumentAttachmentStream(PdfInstream, TempBlob);

        // [THEN] Assert that the attachment is found by known name
        Assert.IsTrue(Success, 'Expected attachment to be found by known name');
        AssertStreamNotEmpty(TempBlob);
    end;

    [Test]
    procedure NoAttachmentFound()
    var
        PdfDocument: Codeunit "PDF Document";
        TempBlob: Codeunit "Temp Blob";
        PdfInstream: InStream;
        Success: Boolean;
    begin
        // [GIVEN] Load test.pdf without valid attachment
        NavApp.GetResource('test.pdf', PdfInstream, TextEncoding::UTF8);

        // [WHEN] Attempt to get invoice attachment stream
        Success := PdfDocument.GetDocumentAttachmentStream(PdfInstream, TempBlob);

        // [THEN] Assert no attachment is found
        Assert.IsFalse(Success, 'Expected no attachment to be found');
    end;

    [Test]
    procedure MetadataExtractedSuccessfully()
    var
        PdfDocument: Codeunit "PDF Document";
        PdfInstream: InStream;
        Metadata: JsonObject;
        Value: JsonToken;
    begin
        // [GIVEN] Load XRechnung.pdf with metadata
        NavApp.GetResource('XRechnung.pdf', PdfInstream, TextEncoding::UTF8);

        // [WHEN] Extract metadata from the PDF stream
        Metadata := PdfDocument.GetPdfProperties(PdfInstream);

        // [THEN] Assert that metadata contains expected values
        if Metadata.Get('pagecount', Value) then
            Assert.AreEqual(Value.AsValue().AsInteger(), 2, 'Expected 2 pages');

        if Metadata.Get('author', Value) then
            Assert.AreEqual(Value.AsValue().AsText(), 'ELEKTRON Industrieservice GmbH', 'Expected author to be XXX');
    end;

    [Test]
    procedure MultipleAttachmentNames()
    var
        PdfDocument: Codeunit "PDF Document";
        PdfInstream: InStream;
        Names: List of [Text];
        ExpectedNames: List of [Text];
        i: Integer;
        ExpectedNameLbl: Label 'Expected name at position %1 to be %2', Comment = '%1 = Position, %2 = Expected Name';
    begin
        // [GIVEN] Load XRechnung.pdf with multiple named attachments
        NavApp.GetResource('XRechnung.pdf', PdfInstream, TextEncoding::UTF8);

        // [WHEN] Attempt to get attachment names
        Names := PdfDocument.GetAttachmentNames(PdfInstream);

        // [THEN] Assert that the names are returned correctly
        ExpectedNames.Add('EN16931_Elektron_Aufmass.png');
        ExpectedNames.Add('EN16931_Elektron_ElektronRapport.pdf');
        ExpectedNames.Add('xrechnung.xml');

        Assert.AreEqual(ExpectedNames.Count(), Names.Count(), 'Expected number of attachment names does not match');

        for i := 1 to ExpectedNames.Count() do
            Assert.AreEqual(ExpectedNames.Get(i), Names.Get(i), StrSubstNo(ExpectedNameLbl, i, ExpectedNames.Get(i)));
    end;

    [Test]
    procedure NoAttachments()
    var
        PdfDocument: Codeunit "PDF Document";
        PdfInstream: InStream;
        Names: List of [Text];
    begin
        // [GIVEN] Load test.pdf without attachments
        NavApp.GetResource('test.pdf', PdfInstream, TextEncoding::UTF8);

        // [WHEN] Attempt to get attachment names
        Names := PdfDocument.GetAttachmentNames(PdfInstream);

        // [THEN] Assert that no attachment names are returned
        Assert.AreEqual(0, Names.Count(), 'Expected no attachment names');
    end;

    [Test]
    procedure GetPdfPageCount()
    var
        PdfDocument: Codeunit "PDF Document";
        PdfInstream: InStream;
        PageCount: Integer;
    begin
        // [GIVEN] Load XRechnung.pdf
        NavApp.GetResource('XRechnung.pdf', PdfInstream, TextEncoding::UTF8);

        // [WHEN] Get the page count from the PDF document
        PageCount := PdfDocument.GetPdfPageCount(PdfInstream);

        // [THEN] Assert that the page count is correct
        Assert.AreEqual(2, PageCount, 'Expected 2 pages in the test PDF.');
    end;

    [Test]
    procedure AddAttachment_Success()
    var
        PDFDocument: Codeunit "PDF Document";
        AttachmentName: Text;
        MimeType: Text;
        FileName: Text;
        Description: Text;
        Count: Integer;
    begin
        // [GIVEN] A valid attachment definition
        AttachmentName := 'factur-x.xml';
        MimeType := 'application/xml';
        FileName := 'factur-x.xml';
        Description := 'Test e-invoice attachment';

        // [WHEN] Add the attachment
        PDFDocument.Initialize();
        PDFDocument.AddAttachment(
            AttachmentName,
            Enum::"PDF Attach. Data Relationship"::Data,
            MimeType,
            FileName,
            Description,
            false);

        // [THEN] Assert that the attachment count is 1
        Count := PDFDocument.AttachmentCount();
        Assert.AreEqual(1, Count, 'Expected one attachment to be added.');
    end;

    [Test]
    procedure AddAttachment_DuplicateName_ThrowsError()
    var
        PDFDocument: Codeunit "PDF Document";
        AttachmentName: Text;
    begin
        // [GIVEN] A valid attachment added once
        AttachmentName := 'duplicate.xml';
        PDFDocument.Initialize();
        PDFDocument.AddAttachment(
            AttachmentName,
            Enum::"PDF Attach. Data Relationship"::Data,
            'application/xml',
            'duplicate.xml',
            'First instance',
            false);

        // [WHEN/THEN] Adding the same attachment again should throw an error
        asserterror
            PDFDocument.AddAttachment(
                AttachmentName,
                Enum::"PDF Attach. Data Relationship"::Data,
                'application/xml',
                'duplicate.xml',
                'Second instance',
                false);
    end;

    [Test]
    procedure AddFilesToAppend_AddsFile()
    var
        PDFDocument: Codeunit "PDF Document";
        FileName: Text;
        Count: Integer;
    begin
        // [GIVEN] A valid file name to append
        FileName := 'appendix.pdf';
        PDFDocument.Initialize();

        // [WHEN] Add the file to append list
        PDFDocument.AddFilesToAppend(FileName);

        // [THEN] Assert that the file was added
        Count := PDFDocument.AppendCount();
        Assert.AreEqual(1, Count, 'Expected one file to be appended.');
    end;

    [Test]
    procedure AddFilesToAppend_EmptyNameWithExistingFiles_ClearsList()
    var
        PDFDocument: Codeunit "PDF Document";
    begin
        // [GIVEN] One file already appended
        PDFDocument.Initialize();
        PDFDocument.AddFilesToAppend('appendix.pdf');
        Assert.AreEqual(1, PDFDocument.AppendCount(), 'Expected one file before reset.');

        // [WHEN] Add an empty file name
        PDFDocument.AddFilesToAppend('');

        // [THEN] Assert that the list is cleared
        Assert.AreEqual(0, PDFDocument.AppendCount(), 'Expected file list to be cleared.');
    end;

    [Test]
    procedure AddStreamToAppend_AddsFile()
    var
        PDFDocument: Codeunit "PDF Document";
        TempBlob: Codeunit "Temp Blob";
        FileOutStream: OutStream;
        FileInStream: InStream;
        Count: Integer;
    begin
        // [GIVEN] A non-empty stream
        TempBlob.CreateOutStream(FileOutStream);
        FileOutStream.WriteText('Test content');
        TempBlob.CreateInStream(FileInStream);

        // [WHEN] Add the stream to append list
        PDFDocument.Initialize();
        PDFDocument.AddStreamToAppend(FileInStream);

        // [THEN] Assert that the file was added
        Count := PDFDocument.AppendCount();
        Assert.AreEqual(1, Count, 'Expected one file to be appended from stream.');
    end;

    [Test]
    procedure AttachmentCount_ReturnsCorrectCount()
    var
        PDFDocument: Codeunit "PDF Document";
        Count: Integer;
    begin
        // [GIVEN] One valid attachment
        PDFDocument.Initialize();
        PDFDocument.AddAttachment(
            'invoice.xml',
            Enum::"PDF Attach. Data Relationship"::Data,
            'application/xml',
            'invoice.xml',
            'Test invoice',
            false);

        // [WHEN] Count attachments
        Count := PDFDocument.AttachmentCount();

        // [THEN] Assert count is 1
        Assert.AreEqual(1, Count, 'Expected one attachment to be counted.');
    end;

    [Test]
    procedure ToJson_SerializesAttachmentsAndAdditionalDocs()
    var
        PDFDocument: Codeunit "PDF Document";
        JsonOut: JsonObject;
        JsonAttachments: JsonArray;
        AttachmentCount: Integer;
        JsonToken: JsonToken;
    begin
        // [GIVEN] A PDF document with attachments
        PDFDocument.Initialize();
        PDFDocument.AddAttachment('invoice.xml', Enum::"PDF Attach. Data Relationship"::Data, 'application/xml', 'invoice.xml', 'Test invoice', false);

        // [WHEN] Convert to JSON
        JsonOut := PDFDocument.ToJson(JsonOut);

        // [THEN] Verify JSON output
        if JsonOut.Contains('attachments') then begin
            JsonOut.Get('attachments', JsonToken);
            JsonAttachments := JsonToken.AsArray();
            AttachmentCount := JsonAttachments.Count();
            Assert.AreEqual(1, AttachmentCount, 'Expected one attachment in the JSON output.');
        end else
            Error('Missing attachments array in JSON output.');
    end;


    local procedure AssertStreamNotEmpty(TempBlob: Codeunit "Temp Blob")
    var
        InStr: InStream;
        TextLine: Text;
    begin
        TempBlob.CreateInStream(InStr);
        InStr.ReadText(TextLine);
        Assert.AreNotEqual('', TextLine, 'Expected stream to contain data');
    end;
}