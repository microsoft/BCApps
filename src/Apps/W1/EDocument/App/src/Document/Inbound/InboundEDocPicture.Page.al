// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument;

using System.IO;
using System.Utilities;

page 6111 "Inbound E-Doc. Picture"
{
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    Extensible = false;
    PageType = CardPart;
    SourceTable = "E-Doc. Data Storage";

    layout
    {
        area(content)
        {
            field(Picture; TempMediaRepository.Image)
            {
                ApplicationArea = All;
                ShowCaption = false;
                ExtendedDatatype = Document;
                ToolTip = 'Picture associated to the e-document like the preview of the PDF.';
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        LoadPdfImage();
    end;

    local procedure LoadPdfImage()
    var
        PdfDocument: Codeunit "PDF Document";
        TempBlob: Codeunit "Temp Blob";
        PdfStream, ImageStream : InStream;
        EDocDataStorageImageDescriptionLbl: Label 'Pdf Preview';
    begin
        Clear(TempMediaRepository);
        if Rec."Entry No." <> xRec."Entry No." then
            PdfLoaded := false;

        if Rec."File Format" <> Enum::"E-Doc. File Format"::PDF then
            exit;

        if PdfLoaded then
            exit;


        Rec.CalcFields("Data Storage");
        Rec."Data Storage".CreateInStream(PdfStream, TextEncoding::UTF8);
        if PdfDocument.Load(PdfStream) then begin
            TempBlob.CreateInStream(ImageStream, TextEncoding::UTF8);
            if PdfDocument.ConvertPdfToImage(ImageStream, "Image Format"::Png, 1) then
                TempMediaRepository.Image.ImportStream(ImageStream, EDocDataStorageImageDescriptionLbl, 'image/png');
        end;
    end;

    var
        TempMediaRepository: Record "Media Repository" temporary;
        PdfLoaded: Boolean;

}

