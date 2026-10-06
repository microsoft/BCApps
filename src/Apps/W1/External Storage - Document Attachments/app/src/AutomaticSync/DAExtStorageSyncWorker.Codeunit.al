// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.ExternalStorage.DocumentAttachments;

using Microsoft.Foundation.Attachment;

codeunit 8755 "DA Ext. Storage Sync Worker"
{
    Access = Internal;
    TableNo = "Document Attachment";

    var
        DAExternalStorageImpl: Codeunit "DA External Storage Impl.";
        Result: Boolean;
        StepInitialized: Boolean;
        FailureReason: Text;
        TelemetryErrorText: Text;
        TelemetryErrorCallStack: Text;
        ExternalFilePath: Text[2048];
        Step: Option Upload,Download,DeleteInternal,DeleteExternal,DeleteOrphanedFile;
        WorkerNotInitializedErr: Label 'The External Storage synchronization worker can only be run by the External Storage Sync report.';
        SyncStepFailedTelemetryErr: Label 'The attachment synchronization step failed.', Locked = true;

    trigger OnRun()
    begin
        Clear(Result);
        Clear(FailureReason);
        Clear(TelemetryErrorText);
        Clear(TelemetryErrorCallStack);

        if not StepInitialized then
            Error(WorkerNotInitializedErr);

        case Step of
            Step::Upload:
                Result := DAExternalStorageImpl.UploadToExternalStorage(Rec, FailureReason);
            Step::Download:
                Result := DAExternalStorageImpl.DownloadFromExternalStorageToInternal(Rec, FailureReason);
            Step::DeleteInternal:
                Result := DAExternalStorageImpl.DeleteFromInternalStorage(Rec, FailureReason);
            Step::DeleteExternal:
                Result := DAExternalStorageImpl.DeleteFromExternalStorage(Rec, FailureReason);
            Step::DeleteOrphanedFile:
                Result := DAExternalStorageImpl.DeleteExternalFileByPath(ExternalFilePath, FailureReason);
        end;

        if not Result then
            CaptureFailureTelemetry(DAExternalStorageImpl.CanLogLastFailureReasonToTelemetry());
    end;

    internal procedure SetStep(NewStep: Option Upload,Download,DeleteInternal,DeleteExternal,DeleteOrphanedFile)
    begin
        Step := NewStep;
        StepInitialized := true;
    end;

    internal procedure SetExternalFilePath(NewExternalFilePath: Text[2048])
    begin
        ExternalFilePath := NewExternalFilePath;
    end;

    internal procedure GetResult(): Boolean
    begin
        exit(Result);
    end;

    internal procedure GetFailureReason(): Text
    begin
        exit(FailureReason);
    end;

    internal procedure GetTelemetryErrorText(): Text
    begin
        exit(TelemetryErrorText);
    end;

    internal procedure GetTelemetryErrorCallStack(): Text
    begin
        exit(TelemetryErrorCallStack);
    end;

    internal procedure GetLastCreatedExternalFilePath(): Text[2048]
    begin
        exit(DAExternalStorageImpl.GetLastCreatedExternalFilePath());
    end;

    local procedure CaptureFailureTelemetry(CanLogFailureReasonToTelemetry: Boolean)
    begin
        TelemetryErrorText := GetLastErrorText(true);
        TelemetryErrorCallStack := GetLastErrorCallStack();
        if TelemetryErrorText = '' then
            if CanLogFailureReasonToTelemetry then
                TelemetryErrorText := FailureReason
            else
                TelemetryErrorText := SyncStepFailedTelemetryErr;
    end;
}
