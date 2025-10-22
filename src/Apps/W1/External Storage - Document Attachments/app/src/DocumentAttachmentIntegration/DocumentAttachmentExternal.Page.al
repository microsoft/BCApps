// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.ExternalStorage.DocumentAttachments;

using Microsoft.Foundation.Attachment;

/// <summary>
/// List page for managing document attachments with external storage information.
/// Provides actions for upload, download, and deletion operations.
/// </summary>
page 8751 "Document Attachment - External"
{
    PageType = List;
    SourceTable = "Document Attachment";
    Caption = 'Document Attachments - External Storage';
    UsageCategory = None;
    ApplicationArea = Basic, Suite;
    Editable = false;
    Extensible = false;

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("Table ID"; Rec."Table ID")
                {
                    ToolTip = 'Specifies the table ID the attachment belongs to.';
                }
                field("No."; Rec."No.")
                {
                    ToolTip = 'Specifies the record number the attachment belongs to.';
                }
                field("File Name"; Rec."File Name")
                {
                    ToolTip = 'Specifies the name of the attached file.';
                }
                field("File Extension"; Rec."File Extension")
                {
                    ToolTip = 'Specifies the file extension of the attached file.';
                }
                field("Attached Date"; Rec."Attached Date")
                {
                    ToolTip = 'Specifies the date the file was attached.';
                }
                field("Attached By"; Rec."Attached By")
                {
                    ToolTip = 'Specifies the user who attached the file.';
                }
                field("Deleted Internally"; Rec."Deleted Internally")
                {
                }
                field("Uploaded to External"; Rec."Uploaded Externally")
                {
                    Caption = 'Uploaded to External';
                }
                field("External Upload Date"; Rec."External Upload Date")
                {
                    Caption = 'Upload Date';
                }
                field("External File Path"; Rec."External File Path")
                {
                    Caption = 'External File Path';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action("Upload to External")
            {
                Enabled = not Rec."Uploaded Externally";
                Caption = 'Upload to External';
                ToolTip = 'Upload the selected file to external storage.';
                Image = Export;

                trigger OnAction()
                var
                    DocumentAttachment: Record "Document Attachment";
                    ExternalStorageImpl: Codeunit "DA External Storage Impl.";
                begin
                    CurrPage.SetSelectionFilter(DocumentAttachment);
                    if DocumentAttachment.FindSet() then
                        repeat
                            if ExternalStorageImpl.UploadToExternalStorage(DocumentAttachment) then
                                Message(FileUploadedMsg)
                            else
                                Message(FailedFileUploadMsg);
                        until DocumentAttachment.Next() = 0;
                end;
            }
            action(Download)
            {
                Caption = 'Download';
                ToolTip = 'Download the selected file from external storage. If the file is not stored externally, it will be exported from internal storage.';
                Image = Import;

                trigger OnAction()
                var
                    ExternalStorageImpl: Codeunit "DA External Storage Impl.";
                begin
                    if Rec."Uploaded Externally" then begin
                        if ExternalStorageImpl.DownloadFromExternalStorage(Rec) then
                            Message(FileDownloadedMsg)
                        else
                            Message(FailedFileDownloadMsg);
                    end else
                        Rec.Export(true);
                end;
            }
            action("Copy from External To Internal")
            {
                Enabled = Rec."Deleted Internally" and Rec."Uploaded Externally";
                Caption = 'Copy from External To Internal';
                ToolTip = 'Copy the file from external storage to internal storage.';
                Image = Import;

                trigger OnAction()
                var
                    ExternalStorageImpl: Codeunit "DA External Storage Impl.";
                begin
                    if ExternalStorageImpl.DownloadFromExternalStorageToInternal(Rec) then
                        Message(FileDownloadedMsg)
                    else
                        Message(FailedFileDownloadMsg);
                end;
            }
            action("Delete from External")
            {
                Enabled = not (Rec."Deleted Internally") and Rec."Uploaded Externally";
                Caption = 'Delete from External';
                ToolTip = 'Delete the file from external storage.';
                Image = Delete;

                trigger OnAction()
                var
                    ExternalStorageImpl: Codeunit "DA External Storage Impl.";
                begin
                    if Confirm(DeleteFileFromExternalStorageQst) then
                        if ExternalStorageImpl.DeleteFromExternalStorage(Rec) then
                            Message(FileDeletedExternalStorageMsg)
                        else
                            Message(FailedFileDeleteExternalStorageMsg);
                end;
            }
            action("Delete from Internal")
            {
                Enabled = Rec."Uploaded Externally" and not Rec."Deleted Internally";
                Caption = 'Delete from Internal';
                ToolTip = 'Delete the file from Internal storage.';
                Image = Delete;

                trigger OnAction()
                var
                    ExternalStorageImpl: Codeunit "DA External Storage Impl.";
                begin
                    if Confirm(DeleteFileFromIntStorageQst) then
                        if ExternalStorageImpl.DeleteFromInternalStorage(Rec) then
                            Message(FileDeletedIntStorageMsg)
                        else
                            Message(FailedFileDeleteIntStorageMsg);
                end;
            }
        }
        area(Navigation)
        {
            action("External Storage Setup")
            {
                Caption = 'External Storage Setup';
                ToolTip = 'Configure external storage settings.';
                Image = Setup;
                RunObject = page "DA External Storage Setup";
            }
        }
        area(Promoted)
        {
            actionref(UploadToExternal_Promoted; "Upload to External") { }
            actionref(DownloadFromExternal_Promoted; Download) { }
            actionref(CopyFromExternalToInternal_Promoted; "Copy from External To Internal") { }
            actionref(DeleteFromExternal_Promoted; "Delete from External") { }
            actionref(DeleteFromInternal_Promoted; "Delete from Internal") { }
        }
    }

    var
        DeleteFileFromExternalStorageQst: Label 'Are you sure you want to delete this file from external storage?';
        DeleteFileFromIntStorageQst: Label 'Are you sure you want to delete this file from Internal storage?';
        FailedFileDeleteExternalStorageMsg: Label 'Failed to delete file from external storage.';
        FailedFileDeleteIntStorageMsg: Label 'Failed to delete file from Internal storage.';
        FailedFileDownloadMsg: Label 'Failed to download file.';
        FailedFileUploadMsg: Label 'Failed to upload file.';
        FileDeletedExternalStorageMsg: Label 'File deleted successfully from external storage.';
        FileDeletedIntStorageMsg: Label 'File deleted successfully from Internal storage.';
        FileDownloadedMsg: Label 'File downloaded successfully.';
        FileUploadedMsg: Label 'File uploaded successfully.';
}
