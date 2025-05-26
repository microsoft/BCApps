
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

    /// <summary>
    /// This procedure is used to initialize the PDF helper.
    /// </summary>
    procedure Init()
    begin
        PDFHelperImpl.Init();
    end;

    /// <summary>
    /// Get the output path for temporary files.
    /// </summary>
    /// <returns>Output path as text.</returns>
    procedure GetOutputPath(): text
    begin
        exit(PDFHelperImpl.GetOutputPath());
    end;

    /// <summary>
    /// This procedure is used to sanitize a file name by replacing invalid characters.
    /// </summary>
    /// <param name="FileName">The file name to be sanitized.</param>
    /// <returns>Sanitized file name.</returns>
    procedure SanitizeFilename(FileName: Text): Text
    begin
        exit(PDFHelperImpl.SanitizeFilename(FileName));
    end;

    /// <summary>
    /// This procedure is used to get the invoice attachment stream from a PDF file.
    /// </summary>
    /// <param name="PdfStream">Input stream of the PDF file.</param>
    /// <param name="TempBlob">Temporary blob to store the attachment.</param>
    procedure GetInvoiceAttachmentStream(PdfStream: InStream; TempBlob: Codeunit "Temp Blob"): Boolean
    begin
        exit(PDFHelperImpl.GetInvoiceAttachmentStream(PdfStream, TempBlob));
    end;

    /// <summary>
    /// Get the zip archive from the PDF stream.
    /// </summary>
    /// <param name="PdfStream">Input stream of the PDF file.</param>
    procedure GetZipArchive(PdfStream: InStream)
    begin
        PDFHelperImpl.GetZipArchive(PdfStream);
    end;

    /// <summary>
    /// This procedure is used to get the names of the attachments in a PDF file.
    /// </summary>
    /// <param name="PdfStream">Input stream of the PDF file.</param>
    /// <returns>Names as comma-separated string.</returns>
    procedure ShowNames(PdfStream: InStream): Text
    begin
        exit(PDFHelperImpl.ShowNames(PdfStream));
    end;

    /// <summary>
    /// This procedure is used to get the properties of a PDF file.
    /// </summary>
    /// <param name="DocumentStream">Input stream of the PDF file.</param>
    /// <returns>Properties of the PDF file in JSON format.</returns>
    procedure GetPdfProperties(DocumentStream: InStream): JsonObject
    begin
        exit(PDFHelperImpl.GetPdfProperties(DocumentStream));
    end;

    /// <summary>
    /// This procedure is used to convert a PDF file to an image.
    /// </summary>
    /// <param name="PdfInStream">Input stream of the PDF file.</param>
    /// <param name="ImageOutStream">Output stream of the image file.</param>
    /// <param name="ImageFormat">Image format to convert the PDF to.</param>
    /// <param name="DPI">Bitmap resolution in dots per inch.</param>
    /// <param name="Width">Width of the image in pixels.</param>
    /// <param name="Height">>Height of the image in pixels.</param>
    /// <param name="PageNumber">Page number to convert.</param>
    procedure ConvertPdfToImage(PdfInStream: InStream; ImageOutStream: OutStream; ImageFormat: Enum "Image Format"; PageNumber: Integer)
    begin
        PDFHelperImpl.ConvertPdfToImage(PdfInStream, ImageOutStream, ImageFormat, PageNumber);
    end;
}
