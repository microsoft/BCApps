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
                TotalCount := Count();

                if TotalCount = 0 then
                    CurrReport.Break();

                if MaxRecordsToProcess > 0 then
                    if TotalCount > MaxRecordsToProcess then
                        TotalCount := MaxRecordsToProcess;

                ProcessedCount := 0;
                FailedCount := 0;

                if IsInteractive then
                    Dialog.Open(ProcessingMsg, TotalCount);

                Commit(); // Commit before the first isolated worker run.
            end;

            trigger OnAfterGetRecord()
            var
                FailureDocumentAttachment: Record "Document Attachment";
                StepDocumentAttachment: Record "Document Attachment";
                FailureReason: Text;
                TelemetryErrorText: Text;
                TelemetryErrorCallStack: Text;
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
                            SyncSuccess := RunSyncWorker(DocumentAttachment, SyncWorkerStep::Upload, FailureReason, TelemetryErrorText, TelemetryErrorCallStack);
                            if SyncSuccess and (Operation = Operation::Move) then begin
                                Commit(); // Persist the external copy before trying to remove the internal source.
                                GetPersistedDocumentAttachment(DocumentAttachment, StepDocumentAttachment);
                                DeleteSuccess := RunSyncWorker(StepDocumentAttachment, SyncWorkerStep::DeleteInternal, FailureReason, TelemetryErrorText, TelemetryErrorCallStack);
                                if not DeleteSuccess then begin
                                    GetPersistedDocumentAttachment(StepDocumentAttachment, FailureDocumentAttachment);
                                    LogFailure(FailureDocumentAttachment, StrSubstNo(SourceCleanupFailedErr, FailureReason), TelemetryErrorText, TelemetryErrorCallStack, 'DeleteInternal');
                                end;
                            end;
                        end;
                    SyncDirection::"To Internal Storage":
                        begin
                            SyncSuccess := RunSyncWorker(DocumentAttachment, SyncWorkerStep::Download, FailureReason, TelemetryErrorText, TelemetryErrorCallStack);
                            if SyncSuccess and (Operation = Operation::Move) then begin
                                Commit(); // Persist the internal copy before trying to remove the external source.
                                GetPersistedDocumentAttachment(DocumentAttachment, StepDocumentAttachment);
                                DeleteSuccess := RunSyncWorker(StepDocumentAttachment, SyncWorkerStep::DeleteExternal, FailureReason, TelemetryErrorText, TelemetryErrorCallStack);
                                if not DeleteSuccess then begin
                                    GetPersistedDocumentAttachment(StepDocumentAttachment, FailureDocumentAttachment);
                                    LogFailure(FailureDocumentAttachment, StrSubstNo(SourceCleanupFailedErr, FailureReason), TelemetryErrorText, TelemetryErrorCallStack, 'DeleteExternal');
                                end;
                            end;
                        end;
                end;

                if not SyncSuccess then begin
                    GetPersistedDocumentAttachment(DocumentAttachment, FailureDocumentAttachment);
                    if SyncDirection = SyncDirection::"To External Storage" then
                        LogFailure(FailureDocumentAttachment, StrSubstNo(CopyFailedErr, FailureReason), TelemetryErrorText, TelemetryErrorCallStack, 'Upload')
                    else
                        LogFailure(FailureDocumentAttachment, StrSubstNo(CopyFailedErr, FailureReason), TelemetryErrorText, TelemetryErrorCallStack, 'Download');
                end;

                Commit(); // Commit after each record to avoid lost in communication error with external storage service

                if (MaxRecordsToProcess > 0) and (ProcessedCount >= MaxRecordsToProcess) then
                    CurrReport.Break();
            end;

            trigger OnPostDataItem()
            begin
                LogSyncTelemetry();

                if IsInteractive then begin
                    if TotalCount <> 0 then
                        Dialog.Close();
                    Message(ProcessedMsg, ProcessedCount - FailedCount, FailedCount);
                end;

                if FailedCount = 0 then
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
                        ToolTip = 'Specifies whether to copy files (leaving them in the source) or move them (deleting from the source after successful copy).';
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
        MaxRecordsToProcess: Integer;
        ProcessedCount: Integer;
        TotalCount: Integer;
        ProcessedMsg: Label 'Processed %1 attachments successfully. %2 failed.', Comment = '%1 - Number of Processed Attachments, %2 - Number of Failed Attachments';
        ProcessingMsg: Label 'Processing #1###### attachments...', Comment = '%1 - Total Number of Attachments';
        AttachmentFailedErr: Label 'Attachment %1: %2', Comment = '%1 = Original attachment filename, %2 = Failure reason';
        CopyFailedErr: Label 'The attachment could not be copied. %1', Comment = '%1 = Failure reason';
        SourceCleanupFailedErr: Label 'The attachment was copied, but could not be removed from the source storage. %1', Comment = '%1 = Failure reason';
        FailuresRegisteredTxt: Label 'External Storage Synchronization: %1 of %2 attachments failed.', Comment = '%1 = Number of failed attachments, %2 = Number of processed attachments';
        SyncStepFailedErr: Label 'The attachment synchronization step failed.';
        SyncStepFailedTelemetryErr: Label 'The attachment synchronization step failed.', Locked = true;
        SyncDirection: Option "To External Storage","To Internal Storage";
        Operation: Option Copy,Move;
        SyncWorkerStep: Option Upload,Download,DeleteInternal,DeleteExternal;

    trigger OnPreReport()
    begin
        IsInteractive := GuiAllowed() and not HideDialog;
    end;

    /// <summary>
    /// Runs the report as it would run in a background session, without dialogs, messages or pages.
    /// </summary>
    /// <param name="NewHideDialog">True to suppress all user interface.</param>
    internal procedure SetHideDialog(NewHideDialog: Boolean)
    begin
        HideDialog := NewHideDialog;
    end;

    local procedure RunSyncWorker(var TargetDocumentAttachment: Record "Document Attachment"; Step: Option Upload,Download,DeleteInternal,DeleteExternal; var FailureReason: Text; var TelemetryErrorText: Text; var TelemetryErrorCallStack: Text): Boolean
    var
        DAExtStorageSyncWorker: Codeunit "DA Ext. Storage Sync Worker";
    begin
        Clear(FailureReason);
        Clear(TelemetryErrorText);
        Clear(TelemetryErrorCallStack);
        Clear(DAExtStorageSyncWorker);
        ClearLastError();

        DAExtStorageSyncWorker.SetStep(Step);
        if DAExtStorageSyncWorker.Run(TargetDocumentAttachment) then begin
            FailureReason := DAExtStorageSyncWorker.GetFailureReason();
            TelemetryErrorText := DAExtStorageSyncWorker.GetTelemetryErrorText();
            TelemetryErrorCallStack := DAExtStorageSyncWorker.GetTelemetryErrorCallStack();
            exit(DAExtStorageSyncWorker.GetResult());
        end;

        FailureReason := GetLastErrorText();
        if FailureReason = '' then
            FailureReason := SyncStepFailedErr;
        TelemetryErrorText := GetLastErrorText(true);
        if TelemetryErrorText = '' then
            TelemetryErrorText := SyncStepFailedTelemetryErr;
        TelemetryErrorCallStack := GetLastErrorCallStack();
        exit(false);
    end;

    local procedure LogFailure(FailedDocumentAttachment: Record "Document Attachment"; FailureMessage: Text; TelemetryErrorText: Text; TelemetryErrorCallStack: Text; FailureOperation: Text)
    var
        DAFeatureTelemetry: Codeunit "DA Feature Telemetry";
    begin
        if TelemetryErrorText = '' then
            TelemetryErrorText := SyncStepFailedTelemetryErr;
        DAFeatureTelemetry.LogSyncFailed(FailedDocumentAttachment, FailureOperation, TelemetryErrorText, TelemetryErrorCallStack, IsInteractive);

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
        // Log manual sync when run interactively, auto sync when run from job queue
        if IsInteractive then
            DAFeatureTelemetry.LogManualSync()
        else
            DAFeatureTelemetry.LogAutoSync();
    end;
}
