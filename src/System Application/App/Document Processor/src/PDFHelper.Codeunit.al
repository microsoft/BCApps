
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Reporting;
using System.Utilities;

codeunit 3110 "PDF Helper"
{
    Access = Public;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        PDFHelperImpl: Codeunit "PDF Helper Impl";

    trigger OnRun()
    begin
        PDFHelperImpl.Run();
    end;

    procedure Init()
    begin
        PDFHelperImpl.Init();
    end;

    procedure GetOutputPath(): text
    begin
        exit(PDFHelperImpl.GetOutputPath());
    end;

    procedure SanitizeFilename(FileName: Text): Text
    begin
        exit(PDFHelperImpl.SanitizeFilename(FileName));
    end;

    procedure GetInvoiceAttachmentStream(PdfStream: InStream; TempBlob: Codeunit "Temp Blob"): Boolean
    begin
        exit(PDFHelperImpl.GetInvoiceAttachmentStream(PdfStream, TempBlob));
    end;

    procedure SaveAllAttachments(PdfStream: InStream)
    begin
        PDFHelperImpl.SaveAllAttachments(PdfStream);
    end;

    procedure GetZipArchive(PdfStream: InStream)
    begin
        PDFHelperImpl.GetZipArchive(PdfStream);
    end;

    procedure ShowNames(PdfStream: InStream): Text
    begin
        exit(PDFHelperImpl.ShowNames(PdfStream));
    end;

    procedure GetPdfProperties(DocumentStream: InStream): JsonObject
    begin
        exit(PDFHelperImpl.GetPdfProperties(DocumentStream));
    end;

    procedure SaveFileContent(var DocumentStream: InStream; FileName: Text)
    begin
        PDFHelperImpl.SaveFileContent(DocumentStream, FileName);
    end;
}
