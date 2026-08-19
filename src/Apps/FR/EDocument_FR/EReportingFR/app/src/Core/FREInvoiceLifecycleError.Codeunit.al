// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Formats;

codeunit 10985 "FR E-Invoice Lifecycle Error"
{
    Access = Internal;
    InherentEntitlements = X;
    Permissions = tabledata "FR E-Invoice Lifecycle" = m;
    TableNo = "FR E-Invoice Lifecycle";

    trigger OnRun()
    begin
        if Rec."Processing Status" = Rec."Processing Status"::"Message Sent" then
            exit;
        Session.LogMessage(
            '0000TDQ', LifecycleWorkerFailedTelemetryMsg, Verbosity::Error,
            DataClassification::SystemMetadata, TelemetryScope::All,
            'Category', LifecycleTelemetryCategoryTok);
        Session.LogMessage(
            '0000TDT', LifecycleWorkerDiagnosticTelemetryMsg, Verbosity::Error,
            DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher,
            'Category', LifecycleTelemetryCategoryTok, 'ErrorCallStack', GetLastErrorCallStack());
        Rec."Processing Status" := Rec."Processing Status"::Failed;
        Rec."Last Error" := CopyStr(GetLastErrorText(true), 1, MaxStrLen(Rec."Last Error"));
        Rec.Modify();
    end;

    var
        LifecycleWorkerFailedTelemetryMsg: Label 'French e-invoice lifecycle message processing failed.', Locked = true;
        LifecycleWorkerDiagnosticTelemetryMsg: Label 'French e-invoice lifecycle message processing failed with an internal error.', Locked = true;
        LifecycleTelemetryCategoryTok: Label 'French E-Invoice Lifecycle', Locked = true;
}
