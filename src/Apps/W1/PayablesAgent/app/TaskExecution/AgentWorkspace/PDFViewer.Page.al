// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Agent.PayablesAgent;

using System.IO;
using System.Utilities;

page 3335 "PDF Viewer"
{
    Caption = 'PDF Viewer';
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "PA Detailed Task";
    SourceTableTemporary = true;
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
                Visible = CanExtractText;

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
                    Presentation.ViewSourcePdf(Task);
                end;
            }
            action(Download)
            {
                Caption = 'Download';
                ToolTip = 'Download the file.';
                Image = Download;

                trigger OnAction()
                begin
                    Presentation.DownloadSourcePdf(Task);
                end;
            }
            action(ExtractText)
            {
                Caption = 'Extract text';
                ToolTip = 'Extract the text of the file with AI and show it on this page.';
                Image = SparkleFilled;
                Visible = CanExtractText;

                trigger OnAction()
                var
                    PAPdfTextExtraction: Codeunit "PA PDF Text Extraction";
                begin
                    if Task.GetSourceText() <> '' then
                        if not Confirm(ReplaceExtractedTextQst, false) then
                            exit;
                    PAPdfTextExtraction.ExtractText(Task);
                    FileContentAsText := Task.GetSourceText();
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
        PayablesAgent: Codeunit "Payables Agent Metadata";
        AgentTaskID: BigInteger;
    begin
        IsAgentSession := PayablesAgent.IsPayablesAgentSession(AgentTaskID);
        // TODOPAV1V2
        IsAgentSession := true;
        CanExtractText := IsAgentSession and Rec."Can Extract Text";
    end;

    trigger OnAfterGetCurrRecord()
    begin
        LoadPreview();
        FileContentAsText := Task.GetSourceText();
    end;

    local procedure LoadPreview()
    var
        PdfDocument: Codeunit "PDF Document";
        PdfTempBlob: Codeunit "Temp Blob";
        ImageTempBlob: Codeunit "Temp Blob";
        PdfInStream: InStream;
        ImageInStream: InStream;
        SourceFileName: Text;
    begin
        Clear(TempMediaRepository);
        if not Task.GetSourcePdf(PdfTempBlob, SourceFileName) then
            exit;
        PdfTempBlob.CreateInStream(PdfInStream);
        if not PdfDocument.Load(PdfInStream) then
            exit;
        ImageTempBlob.CreateInStream(ImageInStream);
        if PdfDocument.ConvertPdfToImage(ImageInStream, Enum::"Image Format"::Png, 1) then
            TempMediaRepository.Image.ImportStream(ImageInStream, PreviewDescriptionTxt, PngMimeTypeTok);
    end;

    internal procedure SetTask(NewTask: Codeunit "Payables Agent Task")
    var
        Data: Record "PA Detailed Task" temporary;
    begin
        // Pin this page to its own task handle rather than retain the caller's mutable wrapper.
        NewTask.GetRecord(Data);
        if not Task.Load(Data."Task Id") then
            Error(TaskNotFoundErr);
        Rec.Reset();
        Rec.DeleteAll();
        Task.GetRecord(Rec);
        Rec."Entry No." := 1;
        Rec.Insert();
    end;

    var
        Task: Codeunit "Payables Agent Task";
        TaskNotFoundErr: Label 'The task does not exist.';
        Presentation: Codeunit "PA Task Presentation";
        CanExtractText: Boolean;
        TempMediaRepository: Record "Media Repository" temporary;
        FileContentAsText: Text;
        IsAgentSession: Boolean;
        ReplaceExtractedTextQst: Label 'The file already has extracted text. Do you want to replace it?';
        PreviewDescriptionTxt: Label 'PDF preview';
        PngMimeTypeTok: Label 'image/png', Locked = true;
}
