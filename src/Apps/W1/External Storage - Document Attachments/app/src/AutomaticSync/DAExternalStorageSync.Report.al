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
    ApplicationArea = All;
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

                if TotalCount = 0 then
                    CurrReport.Break();

                if MaxRecordsToProcess > 0 then
                    if TotalCount > MaxRecordsToProcess then
                        TotalCount := MaxRecordsToProcess;

                ProcessedCount := 0;
                FailedCount := 0;
                InternalCleanupBlockedCount := 0;

                if GuiAllowed() then
                    Dialog.Open(ProcessingMsg, TotalCount);
            end;

            trigger OnAfterGetRecord()
            var
                SyncSuccess: Boolean;
                DeleteSuccess: Boolean;
            begin
                ProcessedCount += 1;

                if GuiAllowed() then
                    Dialog.Update(1, ProcessedCount);

                SyncSuccess := false;
                case SyncDirection of
                    SyncDirection::"To External Storage":
                        begin
                            if (Operation = Operation::Move) and DocumentAttachment."Stored Externally" then
                                SyncSuccess := true
                            else
                                SyncSuccess := ExternalStorageImpl.UploadToExternalStorage(DocumentAttachment);
                            if SyncSuccess and (Operation = Operation::Move) then begin
                                DeleteSuccess := CleanupManagement.RequestCleanup(DocumentAttachment, Enum::"DA Internal Cleanup Origin"::Move);
                                if not DeleteSuccess then
                                    InternalCleanupBlockedCount += 1;
                            end;
                        end;
                    SyncDirection::"To Internal Storage":
                        begin
                            SyncSuccess := ExternalStorageImpl.DownloadFromExternalStorageToInternal(DocumentAttachment);
                            if SyncSuccess and (Operation = Operation::Move) then begin
                                DocumentAttachment.SetRange("Stored Internally");
                                DocumentAttachment.Find();
                                DeleteSuccess := ExternalStorageImpl.DeleteFromExternalStorage(DocumentAttachment);
                                if not DeleteSuccess then
                                    FailedCount += 1;
                                DocumentAttachment.SetRange("Stored Internally", false);
                            end;
                        end;
                end;

                if not SyncSuccess then
                    FailedCount += 1;

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
                    Message(ProcessedMsg, ProcessedCount - FailedCount - InternalCleanupBlockedCount, FailedCount, InternalCleanupBlockedCount);
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
                        ApplicationArea = All;
                        Caption = 'Sync Direction';
                        OptionCaption = 'To External Storage,To Internal Storage';
                        ToolTip = 'Specifies whether to sync to external storage or to internal storage.';
                    }
                    field(OperationField; Operation)
                    {
                        ApplicationArea = All;
                        Caption = 'Operation';
                        OptionCaption = 'Copy,Move';
                        ToolTip = 'Specifies whether to copy files or request a move. Internal cleanup for Move to External is blocked even after successful upload or readback. Internal references and content remain; no database storage is reclaimed.';
                    }
                    field(MaxRecordsToProcessField; MaxRecordsToProcess)
                    {
                        ApplicationArea = All;
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
        CleanupManagement: Codeunit "DA Internal Cleanup Mgt.";
        Dialog: Dialog;
        FailedCount: Integer;
        MaxRecordsToProcess: Integer;
        ProcessedCount: Integer;
        TotalCount: Integer;
        InternalCleanupBlockedCount: Integer;
        ProcessedMsg: Label 'Processed %1 attachments successfully. %2 operations failed. Internal cleanup was blocked for %3 attachments; their internal references and content are retained and no database storage is reclaimed.', Comment = '%1 - Successful operations excluding blocked moves, %2 - Failed operations, %3 - Blocked internal cleanup requests';
        ProcessingMsg: Label 'Processing #1###### attachments...', Comment = '%1 - Total Number of Attachments';
        SyncDirection: Option "To External Storage","To Internal Storage";
        Operation: Option Copy,Move;

    local procedure SetFilters()
    begin
        case SyncDirection of
            SyncDirection::"To External Storage":
                if Operation = Operation::Move then
                    DocumentAttachment.SetRange("Stored Internally", true)
                else
                    DocumentAttachment.SetRange("Stored Externally", false);
            SyncDirection::"To Internal Storage":
                begin
                    DocumentAttachment.SetRange("Stored Externally", true);
                    if Operation = Operation::Move then
                        DocumentAttachment.SetRange("Stored Internally", false);
                end;
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
