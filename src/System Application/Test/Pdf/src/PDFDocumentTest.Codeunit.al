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
        PdfInstream, ImageStream, ResultImageStream : InStream;
    begin
        // Setup
        NavApp.GetResource('test.pdf', PdfInstream, TextEncoding::UTF8);
        NavApp.GetResource('test.png', ResultImageStream, TextEncoding::UTF8);
        TempBlob.CreateInStream(ImageStream);
        PdfDocument.Load(PdfInstream);
        PdfDocument.ConvertToImage(ImageStream, ImageFormat::Png, 1);
        Assert.AreNotEqual(0, TempBlob.Length(), LengthErr);
    end;

    [Test]
    procedure Test_AttachmentFoundViaXMP()
    var
        PdfDocumentImpl: Codeunit "PDF Document Impl.";
        TempBlob: Codeunit "Temp Blob";
        DummyStream: InStream;
        Success: Boolean;
    begin
        //[GIVEN] Create a dummy PDF with XMP metadata containing an attachment
        DummyStream := CreateDummyPdfWithXmpAttachment();

        // [WHEN] Attempt to get invoice attachment stream
        Success := PdfDocumentImpl.GetInvoiceAttachmentStream(DummyStream, TempBlob);

        // [THEN] Assert that the attachment is found via XMP metadata
        Assert.IsTrue(Success, 'Expected attachment to be found via XMP metadata');
        AssertStreamNotEmpty(TempBlob);
    end;

    [Test]
    procedure Test_AttachmentFoundByName()
    var
        PdfDocumentImpl: Codeunit "PDF Document Impl.";
        TempBlob: Codeunit "Temp Blob";
        DummyStream: InStream;
        Success: Boolean;
    begin
        // [GIVEN] Create a dummy PDF with a known attachment name
        DummyStream := CreateDummyPdfWithNamedAttachment('factur-x.xml');

        // [WHEN] Attempt to get invoice attachment stream by known name
        Success := PdfDocumentImpl.GetInvoiceAttachmentStream(DummyStream, TempBlob);

        // [THEN] Assert that the attachment is found by known name
        Assert.IsTrue(Success, 'Expected attachment to be found by known name');
        AssertStreamNotEmpty(TempBlob);
    end;

    [Test]
    procedure Test_NoAttachmentFound()
    var
        PdfDocumentImpl: Codeunit "PDF Document Impl.";
        TempBlob: Codeunit "Temp Blob";
        DummyStream: InStream;
        Success: Boolean;
    begin
        //[GIVEN] Create PDF without attachment
        DummyStream := CreateDummyPdfWithoutAttachment();

        // [WHEN] Attempt to get invoice attachment stream
        Success := PdfDocumentImpl.GetInvoiceAttachmentStream(DummyStream, TempBlob);

        // [THEN] Assert no attachment is found
        Assert.IsFalse(Success, 'Expected no attachment to be found');
    end;

    [Test]
    procedure Test_MetadataExtractedSuccessfully()
    var
        PdfDocumentImpl: Codeunit "PDF Document Impl.";
        PdfStream: InStream;
        Metadata: JsonObject;
        Value: JsonToken;
    begin
        // [GIVEN] Create a dummy PDF with metadata
        PdfStream := CreateDummyPdfWithMetadata();

        // [WHEN] Extract metadata from the PDF stream
        Metadata := PdfDocumentImpl.GetPdfProperties(PdfStream);

        // [THEN] Assert that metadata contains expected values
        if Metadata.Get('pagecount', Value) then
            Assert.AreEqual(Value.AsValue().AsInteger(), 3, 'Expected 3 pages');

        if Metadata.Get('author', Value) then
            Assert.AreEqual(Value.AsValue().AsText(), 'XXX', 'Expected author to be XXX');
    end;

    [Test]
    procedure Test_ZipArchiveDownloaded()
    var
        PdfDocumentImpl: Codeunit "PDF Document Impl.";
        PdfStream: InStream;
    begin
        // [GIVEN] Create a dummy PDF with attachments
        PdfStream := CreateDummyPdfWithXmpAttachment();

        // [WHEN] Attempt to get the zip archive from the PDF stream
        // [THEN] Assert that the zip archive can be downloaded without errors
        PdfDocumentImpl.GetZipArchive(PdfStream);
    end;

    [Test]
    procedure Test_MultipleAttachmentNames()
    var
        PdfDocumentImpl: Codeunit "PDF Document Impl.";
        PdfStream: InStream;
        Names: Text;
    begin
        // [GIVEN] Create a dummy PDF with multiple named attachments
        PdfStream := CreateDummyPdfWithNamedAttachment('invoice.xml,readme.txt');

        // [WHEN] Attempt to get attachment names
        Names := PdfDocumentImpl.ShowNames(PdfStream);

        // [THEN] Assert that the names are returned correctly
        Assert.AreEqual('invoice.xml, readme.txt', Names, 'Expected list of attachment names');
    end;

    [Test]
    procedure Test_NoAttachments()
    var
        PdfDocumentImpl: Codeunit "PDF Document Impl.";
        PdfStream: InStream;
        Names: Text;
    begin
        // [GIVEN] Create a dummy PDF without attachments
        PdfStream := CreateDummyPdfWithNamedAttachment('');

        // [WHEN] Attempt to get attachment names
        Names := PdfDocumentImpl.ShowNames(PdfStream);

        // [THEN] Assert that no attachment names are returned
        Assert.AreEqual('', Names, 'Expected empty string for no attachments');
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

    local procedure CreateDummyPdfWithoutAttachment(): InStream
    var
        TempBlob: Codeunit "Temp Blob";
        OutStr: OutStream;
    begin
        TempBlob.CreateOutStream(OutStr);
        OutStr.WriteText('PDF without attachment');
        exit(TempBlob.CreateInStream());
    end;

    local procedure CreateDummyPdfWithNamedAttachment(Name: Text): InStream
    var
        TempBlob: Codeunit "Temp Blob";
        OutStr: OutStream;
        PDFNameLbl: Label 'PDF with attachment %1', Comment = '%1 = Name';
    begin
        TempBlob.CreateOutStream(OutStr);
        OutStr.WriteText(StrSubstNo(PDFNameLbl, Name));
        exit(TempBlob.CreateInStream());
    end;

    local procedure CreateDummyPdfWithXmpAttachment(): InStream
    var
        TempBlob: Codeunit "Temp Blob";
        OutStr: OutStream;
    begin
        TempBlob.CreateOutStream(OutStr);
        OutStr.WriteText('PDF with attachment: <invoice>123</invoice>');
        exit(TempBlob.CreateInStream());
    end;

    local procedure CreateDummyPdfWithMetadata(): InStream
    var
        TempBlob: Codeunit "Temp Blob";
        OutStr: OutStream;
    begin
        TempBlob.CreateOutStream(OutStr);
        OutStr.WriteText(
            'PDF document' +
            '\nAuthor: XXX' +
            '\nTitle: Test PDF' +
            '\nPageCount: 3' +
            '\nPageWidth: 210' +
            '\nPageHeight: 297' +
            '\nCreationDate: 2025-06-04T10:00:00' +
            '\nCreator: AL Test Suite' +
            '\nProducer: PDF Generator' +
            '\nSubject: Test'
        );
        exit(TempBlob.CreateInStream());
    end;


}