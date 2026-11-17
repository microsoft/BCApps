// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Agent.PayablesAgent;

using System.IO;
using System.Utilities;

/// <summary>
/// Factbox that previews the first page of a work item's source PDF.
/// </summary>
page 3316 "PA Work Item Pdf Preview"
{
    Caption = 'Preview';
    PageType = CardPart;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    LinksAllowed = false;
    Extensible = false;
    InherentEntitlements = X;
    InherentPermissions = X;

    layout
    {
        area(Content)
        {
            field(Picture; TempMediaRepository.Image)
            {
                ApplicationArea = All;
                ShowCaption = false;
                ExtendedDatatype = Document;
                ToolTip = 'Specifies a preview of the PDF file that the work item came from.';
            }
        }
    }

    var
        TempMediaRepository: Record "Media Repository" temporary;
        ShownWorkItemId: Guid;
        PdfPreviewDescriptionLbl: Label 'Pdf Preview', Locked = true;

    /// <summary>
    /// Shows the source PDF of the given work item, or clears the preview when it has none.
    /// </summary>
    /// <param name="WorkItemId">The work item to preview; a null GUID clears the preview.</param>
    internal procedure SetWorkItem(WorkItemId: Guid)
    begin
        if WorkItemId = ShownWorkItemId then
            exit;
        ShownWorkItemId := WorkItemId;
        Clear(TempMediaRepository);
        LoadPdfImage(WorkItemId);
        CurrPage.Update(false);
    end;

    local procedure LoadPdfImage(WorkItemId: Guid)
    var
        WorkItem: Codeunit "PA Work Item";
        PdfDocument: Codeunit "PDF Document";
        PdfBlob: Codeunit "Temp Blob";
        ImageBlob: Codeunit "Temp Blob";
        PdfStream: InStream;
        ImageStream: InStream;
        FileName: Text;
    begin
        if IsNullGuid(WorkItemId) then
            exit;
        if not WorkItem.Load(WorkItemId) then
            exit;
        if not WorkItem.GetSourcePdf(PdfBlob, FileName) then
            exit;
        PdfBlob.CreateInStream(PdfStream);
        if not PdfDocument.Load(PdfStream) then
            exit;
        ImageBlob.CreateInStream(ImageStream);
        if PdfDocument.ConvertPdfToImage(ImageStream, "Image Format"::Png, 1) then
            TempMediaRepository.Image.ImportStream(ImageStream, PdfPreviewDescriptionLbl, 'image/png');
    end;
}
