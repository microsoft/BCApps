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
    ApplicationArea = All;
    Editable = false;
    Extensible = false;

    layout
    {
        area(Content)
        {
            group(Statistics)
            {
                ShowCaption = false;
                field(ExternalStorageStatistics; ExternalStorageStatsText)
                {
                    ApplicationArea = All;
                    Editable = false;
                    ShowCaption = false;
                    Style = Strong;
                    StyleExpr = true;
                    ToolTip = 'Shows the percentage of files uploaded to external storage.';
                }
            }
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
                field("Stored Internally"; Rec."Stored Internally")
                {
                }
                field("Uploaded to External"; Rec."Stored Externally")
                {
                }
                field("External Upload Date"; Rec."External Upload Date")
                {
                }
                field("External File Path"; Rec."External File Path")
                {
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
                Enabled = UploadActionEnabled;
                Caption = 'Upload to External';
                ToolTip = 'Upload the selected file(s) to external storage.';
                Image = Export;

                trigger OnAction()
                var
                    DocumentAttachment: Record "Document Attachment";
                    ExternalStorageImpl: Codeunit "DA External Storage Impl.";
                    SuccessCount: Integer;
                    FailedCount: Integer;
                begin
                    CurrPage.SetSelectionFilter(DocumentAttachment);
                    SuccessCount := 0;
                    FailedCount := 0;
                    if DocumentAttachment.FindSet() then
                        repeat
                            if ExternalStorageImpl.UploadToExternalStorage(DocumentAttachment) then
                                SuccessCount += 1
                            else
                                FailedCount += 1;
                        until DocumentAttachment.Next() = 0;

                    if SuccessCount + FailedCount > 0 then
                        Message(FilesUploadedMsg, SuccessCount, FailedCount);
                end;
            }
            action(Download)
            {
                Caption = 'Download';
                ToolTip = 'Download the selected file(s) from external storage. If the file is not stored externally, it will be exported from internal storage.';
                Image = Import;

                trigger OnAction()
                var
                    DocumentAttachment: Record "Document Attachment";
                    ExternalStorageImpl: Codeunit "DA External Storage Impl.";
                    SuccessCount: Integer;
                    FailedCount: Integer;
                begin
                    CurrPage.SetSelectionFilter(DocumentAttachment);
                    SuccessCount := 0;
                    FailedCount := 0;
                    if DocumentAttachment.FindSet() then
                        repeat
                            if DocumentAttachment."Stored Externally" then begin
                                if ExternalStorageImpl.DownloadFromExternalStorage(DocumentAttachment) then
                                    SuccessCount += 1
                                else
                                    FailedCount += 1;
                            end else
                                DocumentAttachment.Export(true);
                        until DocumentAttachment.Next() = 0;

                    if SuccessCount > 0 then
                        Message(FilesDownloadedMsg, SuccessCount, FailedCount);
                end;
            }
            action("Copy from External To Internal")
            {
                Enabled = not Rec."Stored Internally" and Rec."Stored Externally";
                Caption = 'Copy from External To Internal';
                ToolTip = 'Copy the selected file(s) from external storage to internal storage.';
                Image = Import;

                trigger OnAction()
                var
                    DocumentAttachment: Record "Document Attachment";
                    ExternalStorageImpl: Codeunit "DA External Storage Impl.";
                    SuccessCount: Integer;
                    FailedCount: Integer;
                begin
                    CurrPage.SetSelectionFilter(DocumentAttachment);
                    DocumentAttachment.SetRange("Stored Internally", false);
                    DocumentAttachment.SetRange("Stored Externally", true);
                    SuccessCount := 0;
                    FailedCount := 0;
                    if DocumentAttachment.FindSet() then
                        repeat
                            if ExternalStorageImpl.DownloadFromExternalStorageToInternal(DocumentAttachment) then
                                SuccessCount += 1
                            else
                                FailedCount += 1;
                        until DocumentAttachment.Next() = 0;

                    if SuccessCount + FailedCount > 0 then
                        Message(FilesCopiedMsg, SuccessCount, FailedCount);
                end;
            }
            action("Delete from External")
            {
                Enabled = Rec."Stored Internally" and Rec."Stored Externally";
                Caption = 'Delete from External';
                ToolTip = 'Delete the selected file(s) from external storage.';
                Image = Delete;

                trigger OnAction()
                var
                    DocumentAttachment: Record "Document Attachment";
                    ExternalStorageImpl: Codeunit "DA External Storage Impl.";
                    SuccessCount: Integer;
                    FailedCount: Integer;
                begin
                    if not Confirm(DeleteFilesFromExternalStorageQst) then
                        exit;

                    CurrPage.SetSelectionFilter(DocumentAttachment);
                    DocumentAttachment.SetRange("Stored Internally", true);
                    DocumentAttachment.SetRange("Stored Externally", true);
                    SuccessCount := 0;
                    FailedCount := 0;
                    if DocumentAttachment.FindSet() then
                        repeat
                            if ExternalStorageImpl.DeleteFromExternalStorage(DocumentAttachment) then
                                SuccessCount += 1
                            else
                                FailedCount += 1;
                        until DocumentAttachment.Next() = 0;

                    if SuccessCount + FailedCount > 0 then
                        Message(FilesDeletedExternalStorageMsg, SuccessCount, FailedCount);
                end;
            }
            action("Delete from Internal")
            {
                Enabled = Rec."Stored Externally" and Rec."Stored Internally";
                Caption = 'Delete from Internal';
                ToolTip = 'Delete the selected file(s) from Internal storage.';
                Image = Delete;

                trigger OnAction()
                var
                    DocumentAttachment: Record "Document Attachment";
                    ExternalStorageImpl: Codeunit "DA External Storage Impl.";
                    SuccessCount: Integer;
                    FailedCount: Integer;
                begin
                    if not Confirm(DeleteFilesFromIntStorageQst) then
                        exit;

                    CurrPage.SetSelectionFilter(DocumentAttachment);
                    DocumentAttachment.SetRange("Stored Externally", true);
                    DocumentAttachment.SetRange("Stored Internally", true);
                    SuccessCount := 0;
                    FailedCount := 0;
                    if DocumentAttachment.FindSet() then
                        repeat
                            if ExternalStorageImpl.DeleteFromInternalStorage(DocumentAttachment) then
                                SuccessCount += 1
                            else
                                FailedCount += 1;
                        until DocumentAttachment.Next() = 0;

                    if SuccessCount + FailedCount > 0 then
                        Message(FilesDeletedIntStorageMsg, SuccessCount, FailedCount);
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
        DeleteFilesFromExternalStorageQst: Label 'Are you sure you want to delete the selected file(s) from external storage?';
        DeleteFilesFromIntStorageQst: Label 'Are you sure you want to delete the selected file(s) from internal storage?';
        FilesCopiedMsg: Label '%1 file(s) copied successfully to internal storage. %2 failed.', Comment = '%1 = Success count, %2 = Failed count';
        FilesDeletedExternalStorageMsg: Label '%1 file(s) deleted successfully from external storage. %2 failed.', Comment = '%1 = Success count, %2 = Failed count';
        FilesDeletedIntStorageMsg: Label '%1 file(s) deleted successfully from internal storage. %2 failed.', Comment = '%1 = Success count, %2 = Failed count';
        FilesDownloadedMsg: Label '%1 file(s) downloaded successfully. %2 failed.', Comment = '%1 = Success count, %2 = Failed count';
        FilesUploadedMsg: Label '%1 file(s) uploaded successfully to external storage. %2 failed.', Comment = '%1 = Success count, %2 = Failed count';
        ExternalStorageStatsTxt: Label '%1% (%2/%3) files are uploaded to external storage', Comment = '%1 = Percentage, %2 = External count, %3 = Total count';
        UploadActionEnabled: Boolean;
        ExternalStorageStatsText: Text;

    trigger OnAfterGetRecord()
    var
        ExternalStorageSetup: Record "DA External Storage Setup";
    begin
        UploadActionEnabled := (not Rec."Stored Externally") and ExternalStorageSetup.Get() and ExternalStorageSetup.Enabled;
    end;

    trigger OnOpenPage()
    begin
        UpdateExternalStorageStats();
    end;

    local procedure UpdateExternalStorageStats()
    var
        DocumentAttachment: Record "Document Attachment";
        TotalCount: Integer;
        ExternalCount: Integer;
        Percentage: Decimal;
    begin
        TotalCount := DocumentAttachment.Count();
        DocumentAttachment.SetRange("Stored Externally", true);
        ExternalCount := DocumentAttachment.Count();

        if TotalCount > 0 then
            Percentage := Round((ExternalCount / TotalCount) * 100, 0.01)
        else
            Percentage := 0;

        ExternalStorageStatsText := StrSubstNo(ExternalStorageStatsTxt, Percentage, ExternalCount, TotalCount);
    end;
}
