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
        Step: Option Upload,Download,BlockInternalCleanup,RetireExternalReference;
        WorkerNotInitializedErr: Label 'The External Storage synchronization worker can only be run by the External Storage Sync report.';
        SyncStepFailedTelemetryErr: Label 'The attachment synchronization step failed.', Locked = true;

    trigger OnRun()
    var
        InitializationErrorInfo: ErrorInfo;
    begin
        Clear(Result);
        Clear(FailureReason);
        Clear(TelemetryErrorText);
        Clear(TelemetryErrorCallStack);

        if not StepInitialized then begin
            InitializationErrorInfo.Message := WorkerNotInitializedErr;
            InitializationErrorInfo.ErrorType := ErrorType::Internal;
            InitializationErrorInfo.DataClassification := DataClassification::SystemMetadata;
            Error(InitializationErrorInfo);
        end;

        case Step of
            Step::Upload:
                Result := DAExternalStorageImpl.UploadToExternalStorage(Rec, FailureReason);
            Step::Download:
                Result := DAExternalStorageImpl.DownloadFromExternalStorageToInternal(Rec, FailureReason);
            Step::BlockInternalCleanup:
                Result := DAExternalStorageImpl.RequestInternalCleanup(Rec, Enum::"DA Internal Cleanup Origin"::Move, FailureReason);
            Step::RetireExternalReference:
                Result := DAExternalStorageImpl.RetireExternalReference(Rec, FailureReason);
        end;

        if not Result then
            CaptureFailureTelemetry(DAExternalStorageImpl.CanLogLastFailureReasonToTelemetry());
    end;

    internal procedure SetStep(NewStep: Option Upload,Download,BlockInternalCleanup,RetireExternalReference)
    begin
        Step := NewStep;
        StepInitialized := true;
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
