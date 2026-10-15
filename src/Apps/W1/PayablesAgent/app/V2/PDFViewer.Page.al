// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Agent.PayablesAgent;

using System.IO;
using System.Utilities;

/// <summary>
/// Shows a PDF file and its extracted text. The extracted text and the extraction action are shown only in an agent session.
/// </summary>
page 3335 "PDF Viewer"
{
    Caption = 'PDF Viewer';
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "Payables Agent Task Data";
    DataCaptionFields = "File Name";
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
            group(General)
            {
                Caption = 'File';

                field("File Name"; Rec."File Name")
                {
                    ToolTip = 'Specifies the name of the file.';
                }
            }
            group(Preview)
            {
                Caption = 'Preview';

                field(PdfPreview; TempMediaRepository.Image)
                {
                    ShowCaption = false;
                    ToolTip = 'Specifies a preview of the first page of the file.';
                }
            }
            group(ExtractedText)
            {
                Caption = 'Text';
                Visible = IsAgentSession;

                field(FileContentAsText; FileContentAsText)
                {
                    ShowCaption = false;
                    MultiLine = true;
                    Editable = false;
                    ToolTip = 'Specifies the text extracted from the file.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Open)
            {
                Caption = 'Open';
                ToolTip = 'Open the file in the file viewer.';
                Image = View;

                trigger OnAction()
                begin
                    Rec.ViewFileContent();
                end;
            }
            action(Download)
            {
                Caption = 'Download';
                ToolTip = 'Download the file.';
                Image = Download;

                trigger OnAction()
                begin
                    Rec.DownloadFileContent();
                end;
            }
            action(ExtractText)
            {
                Caption = 'Extract text';
                ToolTip = 'Extract the text of the file with AI and show it on this page.';
                Image = SparkleFilled;
                Visible = IsAgentSession;

                trigger OnAction()
                var
                    PAPdfTextExtraction: Codeunit "PA PDF Text Extraction";
                begin
                    if Rec.HasFileContentAsText() then
                        if not Confirm(ReplaceExtractedTextQst, false) then
                            exit;
                    PAPdfTextExtraction.ExtractText(Rec);
                    FileContentAsText := Rec.GetFileContentAsText();
                    CurrPage.Update(false);
                end;
            }
        }
        area(Promoted)
        {
            actionref(Open_Promoted; Open)
            {
            }
            actionref(Download_Promoted; Download)
            {
            }
            actionref(ExtractText_Promoted; ExtractText)
            {
            }
        }
    }

    trigger OnOpenPage()
    var
        PayablesAgent: Codeunit "Payables Agent";
        AgentTaskID: BigInteger;
    begin
        IsAgentSession := PayablesAgent.IsPayablesAgentSession(AgentTaskID);
    end;

    trigger OnAfterGetCurrRecord()
    begin
        LoadPreview();
        FileContentAsText := Rec.GetFileContentAsText();
    end;

    local procedure LoadPreview()
    var
        PdfDocument: Codeunit "PDF Document";
        PdfTempBlob: Codeunit "Temp Blob";
        ImageTempBlob: Codeunit "Temp Blob";
        PdfInStream: InStream;
        ImageInStream: InStream;
    begin
        Clear(TempMediaRepository);
        if not Rec."File Content".HasValue() then
            exit;

        Rec.GetFileContent(PdfTempBlob);
        PdfTempBlob.CreateInStream(PdfInStream);
        if not PdfDocument.Load(PdfInStream) then
            exit;
        ImageTempBlob.CreateInStream(ImageInStream);
        if PdfDocument.ConvertPdfToImage(ImageInStream, Enum::"Image Format"::Png, 1) then
            TempMediaRepository.Image.ImportStream(ImageInStream, PreviewDescriptionTxt, PngMimeTypeTok);
    end;

    var
        TempMediaRepository: Record "Media Repository" temporary;
        FileContentAsText: Text;
        IsAgentSession: Boolean;
        ReplaceExtractedTextQst: Label 'The file already has extracted text. Do you want to replace it?';
        PreviewDescriptionTxt: Label 'PDF preview';
        PngMimeTypeTok: Label 'image/png', Locked = true;
}
