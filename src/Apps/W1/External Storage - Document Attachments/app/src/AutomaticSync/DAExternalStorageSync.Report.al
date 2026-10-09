// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.ExternalStorage.DocumentAttachments;

using Microsoft.Foundation.Attachment;
using System.Utilities;

/// <summary>
/// Report for synchronizing document attachments between internal and external storage.
/// Supports bulk upload, download, and cleanup operations.
/// Records every failed attachment and its reason in the Error Message Register and logs it to telemetry.
/// Isolates each attachment step so a runtime error is reported for that attachment and the batch continues.
/// Interactive runs also show the failures; background runs complete without raising an error.
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
                  tabledata "Document Attachment" = r,
                  tabledata "Error Message" = ri,
                  tabledata "Error Message Register" = ri;

    dataset
    {
        dataitem(DocumentAttachment; "Document Attachment")
        {
            trigger OnPreDataItem()
            begin
                TempErrorMessage.Reset();
                TempErrorMessage.DeleteAll();
                SetFilters();
                DocumentAttachment.AddLoadFields("Document Reference ID", "File Name", "File Extension", "Stored Externally", "Stored Internally", "External File Path", "External Upload Date", "Source Environment Hash");
                TotalCount := Count();

                if TotalCount = 0 then
                    CurrReport.Break();

                if MaxRecordsToProcess > 0 then
                    if TotalCount > MaxRecordsToProcess then
                        TotalCount := MaxRecordsToProcess;

                ProcessedCount := 0;
                FailedCount := 0;
                InternalCleanupBlockedCount := 0;
                ExternalCopyCount := 0;
                RetainedCount := 0;
                RetiredCount := 0;
                RetirementBlockedCount := 0;

                if IsInteractive then
                    Dialog.Open(ProcessingMsg, TotalCount);

                Commit(); // Commit before the first isolated worker run.
            end;

            trigger OnAfterGetRecord()
            var
                FailureDocumentAttachment: Record "Document Attachment";
                FailureReason: Text;
                TelemetryErrorText: Text;
                TelemetryErrorCallStack: Text;
                CreatedExternalFilePath: Text[2048];
                SyncSuccess: Boolean;
                DeleteSuccess: Boolean;
            begin
                ProcessedCount += 1;

                if IsInteractive then
                    Dialog.Update(1, ProcessedCount);

                SyncSuccess := false;
                case SyncDirection of
                    SyncDirection::"To External Storage":
                        begin
                            if (Operation = Operation::Move) and DocumentAttachment."Stored Externally" then
                                SyncSuccess := true
                            else
                                SyncSuccess := RunSyncWorker(DocumentAttachment, SyncWorkerStep::Upload, FailureReason, TelemetryErrorText, TelemetryErrorCallStack, CreatedExternalFilePath);
                            if SyncSuccess then
                                ExternalCopyCount += 1;
                            if SyncSuccess and (Operation = Operation::Move) then begin
                                DeleteSuccess := RunSyncWorker(DocumentAttachment, SyncWorkerStep::BlockInternalCleanup, FailureReason, TelemetryErrorText, TelemetryErrorCallStack, CreatedExternalFilePath);
                                if not DeleteSuccess then begin
                                    GetPersistedDocumentAttachment(DocumentAttachment, FailureDocumentAttachment);
                                    LogFailure(FailureDocumentAttachment, StrSubstNo(SourceCleanupFailedErr, FailureReason), TelemetryErrorText, TelemetryErrorCallStack, 'BlockInternalCleanup');
                                end;
                            end;
                        end;
                    SyncDirection::"To Internal Storage":
                        begin
                            if (Operation = Operation::Move) and DocumentAttachment."Stored Internally" then
                                SyncSuccess := RunSyncWorker(DocumentAttachment, SyncWorkerStep::RetireExternalReference, FailureReason, TelemetryErrorText, TelemetryErrorCallStack, CreatedExternalFilePath);
                            if SyncSuccess then begin
                                RetainedCount += 1;
                                RetiredCount += 1;
                            end else begin
                                SyncSuccess := RunSyncWorker(DocumentAttachment, SyncWorkerStep::Download, FailureReason, TelemetryErrorText, TelemetryErrorCallStack, CreatedExternalFilePath);
                                if SyncSuccess and (Operation = Operation::Move) then begin
                                    RetainedCount += 1;
                                    DeleteSuccess := RunSyncWorker(DocumentAttachment, SyncWorkerStep::RetireExternalReference, FailureReason, TelemetryErrorText, TelemetryErrorCallStack, CreatedExternalFilePath);
                                    if DeleteSuccess then
                                        RetiredCount += 1
                                    else begin
                                        GetPersistedDocumentAttachment(DocumentAttachment, FailureDocumentAttachment);
                                        LogFailure(FailureDocumentAttachment, StrSubstNo(ReferenceRetirementBlockedErr, FailureReason), TelemetryErrorText, TelemetryErrorCallStack, 'RetireExternalReference');
                                    end;
                                end;
                            end;
                        end;
                end;

                if not SyncSuccess then begin
                    GetPersistedDocumentAttachment(DocumentAttachment, FailureDocumentAttachment);
                    if SyncDirection = SyncDirection::"To External Storage" then begin
                        DescribeRetainedUpload(FailureDocumentAttachment, CreatedExternalFilePath, FailureReason);
                        LogFailure(FailureDocumentAttachment, StrSubstNo(CopyFailedErr, FailureReason), TelemetryErrorText, TelemetryErrorCallStack, 'Upload')
                    end else
                        LogFailure(FailureDocumentAttachment, StrSubstNo(CopyFailedErr, FailureReason), TelemetryErrorText, TelemetryErrorCallStack, 'Download');
                end;

                if (MaxRecordsToProcess > 0) and (ProcessedCount >= MaxRecordsToProcess) then
                    CurrReport.Break();
            end;

            trigger OnPostDataItem()
            begin
                LogSyncTelemetry();

                if IsInteractive then begin
                    if TotalCount <> 0 then
                        Dialog.Close();
                    if InternalCleanupBlockedCount > 0 then
                        Message(ProcessedWithBlockedInternalMsg, ProcessedCount - FailedCount - InternalCleanupBlockedCount, FailedCount, ExternalCopyCount, InternalCleanupBlockedCount)
                    else
                        if RetainedCount > 0 then
                            Message(ProcessedWithRetentionMsg, ProcessedCount - FailedCount, FailedCount, RetainedCount, RetiredCount, RetirementBlockedCount)
                        else
                            Message(ProcessedMsg, ProcessedCount - FailedCount, FailedCount);
                end;

                if TempErrorMessage.IsEmpty() then
                    exit;

                // Persist every failure so background runs can be reviewed without failing the job queue entry.
                RegisterFailures();
                if IsInteractive then
                    TempErrorMessage.ShowErrors();
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
                        ToolTip = 'Specifies whether to copy or move files. Move to External copies content but internal cleanup is blocked, retaining internal references and bytes with no database storage reclamation. Move to Internal restores content when needed and retires only verified local external references. Remote files are always retained.';
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
        TempErrorMessage: Record "Error Message" temporary;
        Dialog: Dialog;
        HideDialog: Boolean;
        IsInteractive: Boolean;
        FailedCount: Integer;
        RetainedCount: Integer;
        RetiredCount: Integer;
        RetirementBlockedCount: Integer;
        MaxRecordsToProcess: Integer;
        ProcessedCount: Integer;
        TotalCount: Integer;
        InternalCleanupBlockedCount: Integer;
        ExternalCopyCount: Integer;
        SyncDirection: Option "To External Storage","To Internal Storage";
        Operation: Option Copy,Move;
        SyncWorkerStep: Option Upload,Download,BlockInternalCleanup,RetireExternalReference;
        ProcessedMsg: Label 'Processed %1 attachments successfully. %2 failed.', Comment = '%1 = Successful operations, %2 = Failed operations';
        ProcessedWithBlockedInternalMsg: Label 'Completed %1 operations. %2 failed. External copies are available for %3 attachments. Internal cleanup was blocked for %4 attachments; internal references and bytes are retained and no database storage is reclaimed.', Comment = '%1 = Completed operations excluding blocked moves, %2 = Failed copies, %3 = External copies available, %4 = Blocked internal cleanup';
        ProcessedWithRetentionMsg: Label 'Processed %1 attachments successfully. %2 failed. Remote files for %3 attachment(s) were retained. %4 external reference(s) were retired locally; %5 retirement(s) were blocked.', Comment = '%1 = Number of processed attachments, %2 = Number of failed copies, %3 = Number of remote files retained, %4 = Number of local references retired, %5 = Number of blocked retirements';
        ProcessingMsg: Label 'Processing #1###### attachments...', Comment = '#1 = Total Number of Attachments';
        AttachmentFailedErr: Label 'Attachment %1: %2', Comment = '%1 = Original attachment filename, %2 = Failure reason';
        CopyFailedErr: Label 'The attachment could not be copied. %1', Comment = '%1 = Failure reason';
        SourceCleanupFailedErr: Label 'The external copy is available, but internal cleanup is blocked and the source content is retained. %1', Comment = '%1 = Blocked reason';
        ReferenceRetirementBlockedErr: Label 'The attachment was restored internally, but its local external reference could not be retired. %1', Comment = '%1 = Retirement refusal reason';
        OrphanedFileRetainedErr: Label 'The external file at %1 was retained because the attachment update failed. Verify the storage account and file before recovering or removing it.', Comment = '%1 = Created external file path';
        FailuresRegisteredTxt: Label 'External Storage Synchronization: %1 of %2 attachments failed.', Comment = '%1 = Number of failed attachments, %2 = Number of processed attachments';
        BlockedRetirementsRegisteredTxt: Label 'External Storage Synchronization: %1 attachment(s) failed and %2 retirement(s) were blocked out of %3 attachments.', Comment = '%1 = Number of failed copies, %2 = Number of blocked retirements, %3 = Number of processed attachments';
        BlockedInternalRegisteredTxt: Label 'External Storage Synchronization: %1 attachment(s) failed and %2 internal cleanup(s) were blocked out of %3 attachments.', Comment = '%1 = Failed copies, %2 = Blocked internal cleanup, %3 = Processed attachments';
        SyncStepFailedErr: Label 'The attachment synchronization step failed.';
        SyncStepFailedTelemetryErr: Label 'The attachment synchronization step failed.', Locked = true;

    trigger OnPreReport()
    begin
        IsInteractive := GuiAllowed() and not HideDialog;
    end;

    /// <summary>
    /// Suppresses progress dialogs, summary messages and error pages. The caller controls whether to show the request page.
    /// </summary>
    /// <param name="NewHideDialog">True to suppress progress dialogs, summary messages and error pages.</param>
    internal procedure SetHideDialog(NewHideDialog: Boolean)
    begin
        HideDialog := NewHideDialog;
    end;

    local procedure RunSyncWorker(var TargetDocumentAttachment: Record "Document Attachment"; Step: Option Upload,Download,BlockInternalCleanup,RetireExternalReference; var FailureReason: Text; var TelemetryErrorText: Text; var TelemetryErrorCallStack: Text; var CreatedExternalFilePath: Text[2048]): Boolean
    var
        DAExtStorageSyncWorker: Codeunit "DA Ext. Storage Sync Worker";
    begin
        Clear(FailureReason);
        Clear(TelemetryErrorText);
        Clear(TelemetryErrorCallStack);
        Clear(CreatedExternalFilePath);
        Clear(DAExtStorageSyncWorker);
        ClearLastError();

        DAExtStorageSyncWorker.SetStep(Step);
        // The Boolean Run commits successful writes and rolls back runtime failures before the next step.
        if DAExtStorageSyncWorker.Run(TargetDocumentAttachment) then begin
            FailureReason := DAExtStorageSyncWorker.GetFailureReason();
            TelemetryErrorText := DAExtStorageSyncWorker.GetTelemetryErrorText();
            TelemetryErrorCallStack := DAExtStorageSyncWorker.GetTelemetryErrorCallStack();
            CreatedExternalFilePath := DAExtStorageSyncWorker.GetLastCreatedExternalFilePath();
            exit(DAExtStorageSyncWorker.GetResult());
        end;

        FailureReason := GetLastErrorText();
        if FailureReason = '' then
            FailureReason := SyncStepFailedErr;
        TelemetryErrorText := GetLastErrorText(true);
        if TelemetryErrorText = '' then
            TelemetryErrorText := SyncStepFailedTelemetryErr;
        TelemetryErrorCallStack := GetLastErrorCallStack();
        CreatedExternalFilePath := DAExtStorageSyncWorker.GetLastCreatedExternalFilePath();
        exit(false);
    end;

    local procedure DescribeRetainedUpload(PersistedDocumentAttachment: Record "Document Attachment"; CreatedExternalFilePath: Text[2048]; var FailureReason: Text)
    begin
        if CreatedExternalFilePath = '' then
            exit;

        if PersistedDocumentAttachment."External File Path" = CreatedExternalFilePath then
            exit;

        if FailureReason = '' then
            FailureReason := StrSubstNo(OrphanedFileRetainedErr, CreatedExternalFilePath)
        else
            FailureReason += ' ' + StrSubstNo(OrphanedFileRetainedErr, CreatedExternalFilePath);
    end;

    local procedure LogFailure(FailedDocumentAttachment: Record "Document Attachment"; FailureMessage: Text; TelemetryErrorText: Text; TelemetryErrorCallStack: Text; FailureOperation: Text)
    var
        DAFeatureTelemetry: Codeunit "DA Feature Telemetry";
    begin
        if TelemetryErrorText = '' then
            TelemetryErrorText := SyncStepFailedTelemetryErr;
        DAFeatureTelemetry.LogSyncFailed(FailedDocumentAttachment, FailureOperation, TelemetryErrorText, TelemetryErrorCallStack, IsInteractive);

        if FailureOperation = 'RetireExternalReference' then
            RetirementBlockedCount += 1
        else
            if FailureOperation = 'BlockInternalCleanup' then
                InternalCleanupBlockedCount += 1
            else
                FailedCount += 1;
        TempErrorMessage.LogMessage(FailedDocumentAttachment, FailedDocumentAttachment.FieldNo("File Name"), TempErrorMessage."Message Type"::Error,
            StrSubstNo(AttachmentFailedErr, FailedDocumentAttachment."File Name" + '.' + FailedDocumentAttachment."File Extension", FailureMessage));
    end;

    local procedure GetPersistedDocumentAttachment(SourceDocumentAttachment: Record "Document Attachment"; var PersistedDocumentAttachment: Record "Document Attachment")
    begin
        PersistedDocumentAttachment.Reset();
        if PersistedDocumentAttachment.Get(
            SourceDocumentAttachment."Table ID",
            SourceDocumentAttachment."No.",
            SourceDocumentAttachment."Document Type",
            SourceDocumentAttachment."Line No.",
            SourceDocumentAttachment.ID)
        then
            exit;

        PersistedDocumentAttachment := SourceDocumentAttachment;
    end;

    local procedure RegisterFailures()
    var
        ErrorMessage: Record "Error Message";
        ErrorMessageRegister: Record "Error Message Register";
        RegisterID: Guid;
    begin
        if InternalCleanupBlockedCount > 0 then
            RegisterID := ErrorMessageRegister.New(CopyStr(StrSubstNo(BlockedInternalRegisteredTxt, FailedCount, InternalCleanupBlockedCount, ProcessedCount), 1, 250))
        else
            if RetirementBlockedCount > 0 then
                RegisterID := ErrorMessageRegister.New(CopyStr(StrSubstNo(BlockedRetirementsRegisteredTxt, FailedCount, RetirementBlockedCount, ProcessedCount), 1, 250))
            else
                RegisterID := ErrorMessageRegister.New(CopyStr(StrSubstNo(FailuresRegisteredTxt, FailedCount, ProcessedCount), 1, 250));
        TempErrorMessage.Reset();
        if TempErrorMessage.FindSet() then
            repeat
                ErrorMessage := TempErrorMessage;
                ErrorMessage.ID := 0;
                ErrorMessage."Register ID" := RegisterID;
                ErrorMessage.SetErrorCallStack(TempErrorMessage.GetErrorCallStack());
                ErrorMessage.Insert();
            until TempErrorMessage.Next() = 0;
    end;

    local procedure SetFilters()
    begin
        case SyncDirection of
            SyncDirection::"To External Storage":
                if Operation = Operation::Move then
                    DocumentAttachment.SetRange("Stored Internally", true)
                else
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
        // Log manual sync when run interactively, auto sync when run from job queue
        if IsInteractive then
            DAFeatureTelemetry.LogManualSync()
        else
            DAFeatureTelemetry.LogAutoSync();
    end;
}
