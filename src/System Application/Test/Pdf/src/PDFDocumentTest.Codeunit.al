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
    procedure Test_AttachmentFoundViaXMP()
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
    procedure Test_AttachmentFoundByName()
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
    procedure Test_NoAttachmentFound()
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
    procedure Test_MetadataExtractedSuccessfully()
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
    procedure Test_MultipleAttachmentNames()
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
    procedure Test_NoAttachments()
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
    procedure Test_GetPdfPageCount()
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