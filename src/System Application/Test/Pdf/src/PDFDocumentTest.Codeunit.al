// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.IO;

using System.Utilities;
using System.Text;
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
        Base64Convert: Codeunit "Base64 Convert";
        ImageFormat: Enum "Image Format";
        PdfInstream, ImageStream, ResultImageStream : InStream;
        fileName: Text;
    begin
        fileName := 'test.png';
        // Setup
        NavApp.GetResource('test.pdf', PdfInstream, TextEncoding::UTF8);
        NavApp.GetResource('test.png', ResultImageStream, TextEncoding::UTF8);
        TempBlob.CreateInStream(ImageStream);
        PdfDocument.Load(PdfInstream);
        PdfDocument.ConvertToImage(ImageStream, ImageFormat::Png, 1);
        DownloadFromStream(ImageStream, '', '', '', fileName);
        Assert.AreNotEqual(0, TempBlob.Length(), LengthErr);

        Assert.AreEqual(Base64Convert.ToBase64(ResultImageStream),
                        Base64Convert.ToBase64(ImageStream),
                        'The converted image does not match the expected result.');

    end;

}