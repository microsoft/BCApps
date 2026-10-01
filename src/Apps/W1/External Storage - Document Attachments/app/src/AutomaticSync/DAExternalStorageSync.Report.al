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
            end;

            trigger OnAfterGetRecord()
            var
                FailureReason: Text;
                SyncSuccess: Boolean;
                DeleteSuccess: Boolean;
            begin
                ProcessedCount += 1;

                if IsInteractive then
                    Dialog.Update(1, ProcessedCount);

                SyncSuccess := false;
                ClearLastError();
                case SyncDirection of
                    SyncDirection::"To External Storage":
                        begin
                            SyncSuccess := ExternalStorageImpl.UploadToExternalStorage(DocumentAttachment, FailureReason);
                            if SyncSuccess and (Operation = Operation::Move) then begin
                                ClearLastError();
                                DeleteSuccess := ExternalStorageImpl.DeleteFromInternalStorage(DocumentAttachment, FailureReason);
                                if not DeleteSuccess then
                                    LogFailure(StrSubstNo(SourceCleanupFailedErr, FailureReason), FailureReason, 'DeleteInternal');
                            end;
                        end;
                    SyncDirection::"To Internal Storage":
                        begin
                            SyncSuccess := ExternalStorageImpl.DownloadFromExternalStorageToInternal(DocumentAttachment, FailureReason);
                            if SyncSuccess and (Operation = Operation::Move) then begin
                                DocumentAttachment.SetRange("Stored Internally");
                                DocumentAttachment.Find();
                                ClearLastError();
                                DeleteSuccess := ExternalStorageImpl.DeleteFromExternalStorage(DocumentAttachment, FailureReason);
                                if not DeleteSuccess then
                                    LogFailure(StrSubstNo(SourceCleanupFailedErr, FailureReason), FailureReason, 'DeleteExternal');
                                DocumentAttachment.SetRange("Stored Internally", false);
                            end;
                        end;
                end;

                if not SyncSuccess then
                    if SyncDirection = SyncDirection::"To External Storage" then
                        LogFailure(StrSubstNo(CopyFailedErr, FailureReason), FailureReason, 'Upload')
                    else
                        LogFailure(StrSubstNo(CopyFailedErr, FailureReason), FailureReason, 'Download');

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
        ExternalStorageImpl: Codeunit "DA External Storage Impl.";
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
        SyncDirection: Option "To External Storage","To Internal Storage";
        Operation: Option Copy,Move;

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

    local procedure LogFailure(FailureMessage: Text; FailureReason: Text; FailureOperation: Text)
    var
        DAFeatureTelemetry: Codeunit "DA Feature Telemetry";
        TelemetryErrorText: Text;
    begin
        TelemetryErrorText := GetLastErrorText(true);
        if TelemetryErrorText = '' then
            TelemetryErrorText := FailureReason;
        DAFeatureTelemetry.LogSyncFailed(DocumentAttachment, FailureOperation, TelemetryErrorText, GetLastErrorCallStack(), IsInteractive);

        FailedCount += 1;
        TempErrorMessage.LogMessage(DocumentAttachment, DocumentAttachment.FieldNo("File Name"), TempErrorMessage."Message Type"::Error,
            StrSubstNo(AttachmentFailedErr, DocumentAttachment."File Name" + '.' + DocumentAttachment."File Extension", FailureMessage));
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
