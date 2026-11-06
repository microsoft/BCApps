// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument.Interfactura;

codeunit 3376 "MX E-Document Telemetry"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        FeatureNameTok: Label 'E-Document Mexico CFDI', Locked = true;
        CategoryTok: Label 'Category', Locked = true;
        CFDIServiceNameTok: Label 'CFDI', Locked = true;
        CFDIServiceSetUpMsg: Label 'E-Document service set up with the CFDI format.', Locked = true;
        CFDIDataEditedMsg: Label 'CFDI data edited on E-Document %1.', Locked = true;
        ComplementCancelRequestedMsg: Label 'Cancellation request submitted for payment complement %1.', Locked = true;
        ComplementCancelStatusRequestedMsg: Label 'Checking cancellation status for payment complement %1.', Locked = true;
        ComplementCancelResultMsg: Label 'Cancellation of payment complement %1 finished with status %2.', Locked = true;
        ComplementCancelFailedMsg: Label 'Cancellation request for payment complement %1 failed: %2', Locked = true;
        CanceledWithoutPACMsg: Label '%1 %2 was marked as canceled without contacting the PAC (%3).', Locked = true, Comment = '%1 = document kind, %2 = entry no, %3 = reason';
        CancellationResetMsg: Label 'Cancellation request of payment complement %1 was reset.', Locked = true;
        SecurityAuditComplementRejectedTxt: Label 'PAC rejected CFDI payment complement stamp request: %1', Locked = true, Comment = '%1 - PAC error';
        SecurityAuditComplementCancelRequestedTxt: Label 'CFDI cancellation request submitted for payment complement %1.', Locked = true, Comment = '%1 - payment complement entry no';
        SecurityAuditCanceledWithoutPACTxt: Label '%1 %2 was marked as canceled in Business Central without contacting the PAC (%3).', Locked = true, Comment = '%1 = document kind, %2 = entry no, %3 = reason';

    procedure LogServiceSetUp()
    begin
        Session.LogMessage('0000WKJ', CFDIServiceSetUpMsg, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, CategoryTok, FeatureNameTok);
    end;

    procedure LogCFDIDataEdited(EDocumentEntryNo: Integer)
    begin
        Session.LogMessage('0000WKK', StrSubstNo(CFDIDataEditedMsg, EDocumentEntryNo), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, CategoryTok, FeatureNameTok);
    end;

    procedure LogComplementStampRejected(ErrorText: Text)
    begin
        Session.LogSecurityAudit(CFDIServiceNameTok, SecurityOperationResult::Failure, StrSubstNo(SecurityAuditComplementRejectedTxt, ErrorText), AuditCategory::CustomerFacing);
    end;

    procedure LogComplementCancelRequested(ComplementEntryNo: Integer; IsStatusRequest: Boolean)
    begin
        if IsStatusRequest then begin
            Session.LogMessage('0000WKL', StrSubstNo(ComplementCancelStatusRequestedMsg, ComplementEntryNo), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, CategoryTok, FeatureNameTok);
            exit;
        end;
        Session.LogMessage('0000WKM', StrSubstNo(ComplementCancelRequestedMsg, ComplementEntryNo), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, CategoryTok, FeatureNameTok);
        Session.LogSecurityAudit(CFDIServiceNameTok, SecurityOperationResult::Success, StrSubstNo(SecurityAuditComplementCancelRequestedTxt, ComplementEntryNo), AuditCategory::CustomerFacing);
    end;

    procedure LogComplementCancelResult(ComplementEntryNo: Integer; CancellationStatus: Enum "MX Compl. Cancel Status")
    begin
        Session.LogMessage('0000WKN', StrSubstNo(ComplementCancelResultMsg, ComplementEntryNo, Format(CancellationStatus)), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, CategoryTok, FeatureNameTok);
    end;

    procedure LogComplementCancelFailed(ComplementEntryNo: Integer; ErrorText: Text)
    begin
        Session.LogMessage('0000WKO', StrSubstNo(ComplementCancelFailedMsg, ComplementEntryNo, ErrorText), Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, CategoryTok, FeatureNameTok);
    end;

    procedure LogCanceledWithoutPAC(DocumentKind: Text; EntryNo: Integer; Reason: Text)
    begin
        Session.LogMessage('0000WKP', StrSubstNo(CanceledWithoutPACMsg, DocumentKind, EntryNo, Reason), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, CategoryTok, FeatureNameTok);
        Session.LogSecurityAudit(CFDIServiceNameTok, SecurityOperationResult::Success, StrSubstNo(SecurityAuditCanceledWithoutPACTxt, DocumentKind, EntryNo, Reason), AuditCategory::CustomerFacing);
    end;

    procedure LogCancellationReset(ComplementEntryNo: Integer)
    begin
        Session.LogMessage('0000WKQ', StrSubstNo(CancellationResetMsg, ComplementEntryNo), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, CategoryTok, FeatureNameTok);
    end;
}
