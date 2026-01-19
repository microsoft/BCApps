// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.ExternalStorage.DocumentAttachments;

using Microsoft.Foundation.Attachment;

/// <summary>
/// Report for synchronizing document attachments between internal and external storage.
/// Supports bulk upload, download, and cleanup operations.
/// </summary>
report 8752 "DA External Storage Sync"
{
    Caption = 'External Storage Synchronization';
    ProcessingOnly = true;
    UseRequestPage = true;
    Extensible = false;
    ApplicationArea = Basic, Suite;
    UsageCategory = None;
    Permissions = tabledata "DA External Storage Setup" = r,
                  tabledata "Document Attachment" = r;

    dataset
    {
        dataitem(DocumentAttachment; "Document Attachment")
        {
            trigger OnPreDataItem()
            begin
                SetFilters();
                TotalCount := Count();

                if TotalCount = 0 then begin
                    if GuiAllowed() then
                        Message(NoRecordsMsg);
                    CurrReport.Break();
                end;

                if MaxRecordsToProcess > 0 then
                    if TotalCount > MaxRecordsToProcess then
                        TotalCount := MaxRecordsToProcess;

                ProcessedCount := 0;
                FailedCount := 0;
                DeleteCount := 0;
                DeleteFailedCount := 0;

                if GuiAllowed() then
                    Dialog.Open(ProcessingMsg, TotalCount);
            end;

            trigger OnAfterGetRecord()
            var
                DateFormulaLbl: Label '<+%1>', Locked = true;
            begin
                ProcessedCount += 1;

                if GuiAllowed() then
                    Dialog.Update(1, ProcessedCount);

                case SyncDirection of
                    SyncDirection::"To External Storage":
                        if not ExternalStorageImpl.UploadToExternalStorage(DocumentAttachment) then
                            FailedCount += 1;
                    SyncDirection::"From External Storage":

                        if not ExternalStorageImpl.DownloadFromExternalStorage(DocumentAttachment) then
                            FailedCount += 1;
                end;
                if (DocumentAttachment."Uploaded Externally") and (DocumentAttachment."Deleted Internally" = false) then
                    if ExternalStorageImpl.DeleteFromInternalStorage(DocumentAttachment) then
                        DeleteCount += 1
                    else
                        DeleteFailedCount += 1;
                Commit(); // Commit after each record to avoid lost in communication error with external storage service

                if (MaxRecordsToProcess > 0) and (ProcessedCount >= MaxRecordsToProcess) then
                    CurrReport.Break();
            end;

            trigger OnPostDataItem()
            begin
                LogSyncTelemetry();

                if GuiAllowed() then begin
                    if TotalCount <> 0 then
                        Dialog.Close();
                    if DeleteExpiredFiles then
                        Message(DeletedExpiredFilesMsg, ProcessedCount - FailedCount, FailedCount, DeleteCount)
                    else
                        Message(ProcessedMsg, ProcessedCount - FailedCount, FailedCount);
                end;
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(Content)
            {
                group(General)
                {
                    Caption = 'General';
                    field(SyncDirectionField; SyncDirection)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Sync Direction';
                        OptionCaption = 'To External Storage,From External Storage';
                        ToolTip = 'Specifies whether to sync to external storage or from external storage.';
                    }
                    field(DeleteExpiredFilesField; DeleteExpiredFiles)
                    {
                        ApplicationArea = Basic, Suite;
                        Enabled = SyncDirection = SyncDirection::"To External Storage";
                        Caption = 'Delete Expired Files';
                        ToolTip = 'Specifies whether to delete expired files from internal storage.';
                    }
                    field(MaxRecordsToProcessField; MaxRecordsToProcess)
                    {
                        ApplicationArea = Basic, Suite;
                        Enabled = SyncDirection = SyncDirection::"To External Storage";
                        Caption = 'Maximum Records to Process';
                        ToolTip = 'Specifies the maximum number of records to process in one run. Leave 0 for unlimited.';
                        MinValue = 0;
                    }
                }
            }
        }
    }

    var
        ExternalStorageImpl: Codeunit "DA External Storage Impl.";
        DeleteExpiredFiles: Boolean;
        Dialog: Dialog;
        DeleteCount, DeleteFailedCount : Integer;
        FailedCount: Integer;
        MaxRecordsToProcess: Integer;
        ProcessedCount: Integer;
        TotalCount: Integer;
        DeletedExpiredFilesMsg: Label 'Processed %1 attachments successfully. %2 failed.//Deleted %3 expired files.', Comment = '%1 - Number of Processed Attachments, %2 - Number of Failed Attachments, %3 - Number of Deleted Expired Files';
        NoRecordsMsg: Label 'No records found to process.';
        ProcessedMsg: Label 'Processed %1 attachments successfully. %2 failed.', Comment = '%1 - Number of Processed Attachments, %2 - Number of Failed Attachments';
        ProcessingMsg: Label 'Processing #1###### attachments...', Comment = '%1 - Total Number of Attachments';
        SyncDirection: Option "To External Storage","From External Storage";

    local procedure SetFilters()
    begin
        case SyncDirection of
            SyncDirection::"To External Storage":
                DocumentAttachment.SetRange("Uploaded Externally", false);
            SyncDirection::"From External Storage":
                DocumentAttachment.SetRange("Uploaded Externally", true);
        end;
    end;

    local procedure LogSyncTelemetry()
    var
        DAFeatureTelemetry: Codeunit "DA Feature Telemetry";
    begin
        // Log manual sync when run from UI (GuiAllowed), auto sync when run from job queue
        if GuiAllowed() then
            DAFeatureTelemetry.LogManualSync()
        else
            DAFeatureTelemetry.LogAutoSync();
    end;
}
