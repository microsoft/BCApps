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
                RetainedCount := 0;
                RetiredCount := 0;
                RetirementBlockedCount := 0;
                Clear(FirstRetirementFailureReason);

                if GuiAllowed() then
                    Dialog.Open(ProcessingMsg, TotalCount);
            end;

            trigger OnAfterGetRecord()
            var
                SyncSuccess: Boolean;
                DeleteSuccess: Boolean;
                FailureReason: Text;
            begin
                ProcessedCount += 1;

                if GuiAllowed() then
                    Dialog.Update(1, ProcessedCount);

                SyncSuccess := false;
                case SyncDirection of
                    SyncDirection::"To External Storage":
                        begin
                            SyncSuccess := ExternalStorageImpl.UploadToExternalStorage(DocumentAttachment);
                            if SyncSuccess and (Operation = Operation::Move) then begin
                                DeleteSuccess := ExternalStorageImpl.DeleteFromInternalStorage(DocumentAttachment);
                                if not DeleteSuccess then
                                    FailedCount += 1;
                            end;
                        end;
                    SyncDirection::"To Internal Storage":
                        begin
                            if (Operation = Operation::Move) and DocumentAttachment."Stored Internally" then
                                SyncSuccess := ExternalStorageImpl.RetireExternalReference(DocumentAttachment, FailureReason);

                            if SyncSuccess then begin
                                RetainedCount += 1;
                                RetiredCount += 1;
                            end else begin
                                SyncSuccess := ExternalStorageImpl.DownloadFromExternalStorageToInternal(DocumentAttachment);
                                if SyncSuccess and (Operation = Operation::Move) then begin
                                    RetainedCount += 1;
                                    if ExternalStorageImpl.RetireExternalReference(DocumentAttachment, FailureReason) then
                                        RetiredCount += 1
                                    else begin
                                        RetirementBlockedCount += 1;
                                        if FirstRetirementFailureReason = '' then
                                            FirstRetirementFailureReason := FailureReason;
                                    end;
                                end;
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
                    if RetirementBlockedCount > 0 then
                        Message(ProcessedWithBlockedRetirementMsg, ProcessedCount - FailedCount, FailedCount, RetainedCount, RetiredCount, RetirementBlockedCount, FirstRetirementFailureReason)
                    else
                        if RetainedCount > 0 then
                            Message(ProcessedWithRetentionMsg, ProcessedCount - FailedCount, FailedCount, RetainedCount, RetiredCount)
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
                        ToolTip = 'Specifies whether to copy or move files. Copy keeps both references. Move to internal storage restores content and retires local external references only after confirming internal bytes. Remote files are always retained.';
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
        Dialog: Dialog;
        FailedCount: Integer;
        RetainedCount: Integer;
        RetiredCount: Integer;
        RetirementBlockedCount: Integer;
        FirstRetirementFailureReason: Text;
        MaxRecordsToProcess: Integer;
        ProcessedCount: Integer;
        TotalCount: Integer;
        ProcessedMsg: Label 'Processed %1 attachments successfully. %2 failed.', Comment = '%1 - Number of Processed Attachments, %2 - Number of Failed Attachments';
        ProcessedWithRetentionMsg: Label 'Processed %1 attachments successfully. %2 failed. Remote files for %3 attachment(s) were retained. %4 external reference(s) were retired locally.', Comment = '%1 = Number of processed attachments, %2 = Number of failed attachments, %3 = Number of remote files retained, %4 = Number of local references retired';
        ProcessedWithBlockedRetirementMsg: Label 'Processed %1 attachments successfully. %2 failed. Remote files for %3 attachment(s) were retained. %4 external reference(s) were retired locally; %5 could not be retired. %6', Comment = '%1 = Number of processed attachments, %2 = Number of failed attachments, %3 = Number of remote files retained, %4 = Number of local references retired, %5 = Number of blocked retirements, %6 = First blocked reason';
        ProcessingMsg: Label 'Processing #1###### attachments...', Comment = '%1 - Total Number of Attachments';
        SyncDirection: Option "To External Storage","To Internal Storage";
        Operation: Option Copy,Move;

    local procedure SetFilters()
    begin
        case SyncDirection of
            SyncDirection::"To External Storage":
                DocumentAttachment.SetRange("Stored Externally", false);
            SyncDirection::"To Internal Storage":
                DocumentAttachment.SetRange("Stored Externally", true);
        end;
    end;

    local procedure LogSyncTelemetry()
    var
        DAFeatureTelemetry: Codeunit "DA Feature Telemetry";
    begin
        DAFeatureTelemetry.LogSyncRetention(RetainedCount, RetiredCount, RetirementBlockedCount);
        // Log manual sync when run from UI (GuiAllowed), auto sync when run from job queue
        if GuiAllowed() then
            DAFeatureTelemetry.LogManualSync()
        else
            DAFeatureTelemetry.LogAutoSync();
    end;
}
