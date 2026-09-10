// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.Foundation.Attachment;
using System.IO;
using System.Utilities;

page 6956 "Expense Picture"
{
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    Extensible = false;
    PageType = CardPart;
    SourceTable = "Document Attachment";

    layout
    {
        area(content)
        {
            field(Picture; TempMediaRepository.Image)
            {
                ApplicationArea = All;
                ShowCaption = false;
                ExtendedDatatype = Document;
                ToolTip = 'Picture associated to the expense like the preview of the PDF.';
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        LoadPdfImage();
    end;

    var
        TempMediaRepository: Record "Media Repository" temporary;

    local procedure LoadPdfImage()
    var
        PdfDocument: Codeunit "PDF Document";
        TempBlob: Codeunit "Temp Blob";
        PdfStream, ImageStream : InStream;
        ImageDescriptionLbl: Label 'Pdf Preview';
    begin
        Clear(TempMediaRepository);
        if Rec."File Type" <> Rec."File Type"::PDF then
            exit;

        Rec.GetAsTempBlob(TempBlob);
        TempBlob.CreateInStream(PdfStream, TextEncoding::UTF8);
        if PdfDocument.Load(PdfStream) then begin
            TempBlob.CreateInStream(ImageStream, TextEncoding::UTF8);
            if PdfDocument.ConvertPdfToImage(ImageStream, "Image Format"::Png, 1) then
                TempMediaRepository.Image.ImportStream(ImageStream, ImageDescriptionLbl, 'image/png');
        end;
    end;
}