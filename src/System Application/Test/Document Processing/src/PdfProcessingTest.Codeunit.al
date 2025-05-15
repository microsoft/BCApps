// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.IO;

using System.Utilities;
using System.TestLibraries.Utilities;


codeunit 132601 "Pdf Processing Test"
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
        PdfProcessing: Codeunit "Pdf Processing";
        TempBlob: Codeunit "Temp Blob";
        Instream: InStream;
        Outstream: OutStream;
    begin
        // Setup
        NavApp.GetResource('pdfs/test.pdf', Instream, TextEncoding::UTF8);
        TempBlob.CreateOutStream(Outstream);
        PdfProcessing.ConvertPdfToImage(Instream, Outstream, Enum::"Image Format"::PNG, 300, 800, 1000, 1);
        Assert.AreNotEqual(0, TempBlob.Length(), LengthErr);
    end;


}