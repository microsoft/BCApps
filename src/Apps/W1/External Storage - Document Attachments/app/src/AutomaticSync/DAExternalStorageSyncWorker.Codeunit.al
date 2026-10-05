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
        FailureReason: Text;
        TelemetryErrorText: Text;
        TelemetryErrorCallStack: Text;
        Step: Option Upload,Download,DeleteInternal,DeleteExternal;
        SyncStepFailedTelemetryErr: Label 'The attachment synchronization step failed.', Locked = true;

    trigger OnRun()
    begin
        Clear(Result);
        Clear(FailureReason);
        Clear(TelemetryErrorText);
        Clear(TelemetryErrorCallStack);

        case Step of
            Step::Upload:
                Result := DAExternalStorageImpl.UploadToExternalStorage(Rec, FailureReason);
            Step::Download:
                Result := DAExternalStorageImpl.DownloadFromExternalStorageToInternal(Rec, FailureReason);
            Step::DeleteInternal:
                Result := DAExternalStorageImpl.DeleteFromInternalStorage(Rec, FailureReason);
            Step::DeleteExternal:
                Result := DAExternalStorageImpl.DeleteFromExternalStorage(Rec, FailureReason);
        end;

        if not Result then
            CaptureFailureTelemetry(DAExternalStorageImpl.CanLogLastFailureReasonToTelemetry());
    end;

    internal procedure SetStep(NewStep: Option Upload,Download,DeleteInternal,DeleteExternal)
    begin
        Step := NewStep;
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
