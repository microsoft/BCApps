// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Agent.PayablesAgent;

using System.Telemetry;

codeunit 3348 "PA Draft Based Telemetry"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        PATelemetry: Codeunit "PA Telemetry";

    #region Configuration - demo email
    internal procedure LogDemoEmailSendingFailed(ErrorMessage: Text)
    var
        Telemetry: Codeunit Telemetry;
        EmailNotSentErr: Label 'The email has not been sent. Error: %1.', Comment = '%1 - error message from the email management codeunit';
    begin
        Telemetry.LogMessage('0000PJW', StrSubstNo(EmailNotSentErr, ErrorMessage), Verbosity::Warning, DataClassification::SystemMetadata);
    end;
    #endregion

    #region Billing
    internal procedure LogBillingTemporaryHeader(EDocumentEntryNo: Integer)
    var
        CustomDimensions: Dictionary of [Text, Text];
    begin
        CustomDimensions := GetBillingDocumentDimensions(EDocumentEntryNo);
        Session.LogMessage('0000R32', 'Skipping billing log for temporary E-Document Purchase Header.', Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, CustomDimensions);
    end;

    internal procedure LogBillingUnmatchedDocument(EDocumentEntryNo: Integer)
    var
        CustomDimensions: Dictionary of [Text, Text];
    begin
        CustomDimensions := GetBillingDocumentDimensions(EDocumentEntryNo);
        Session.LogMessage('0000R33', 'The E-Document does not match the current session E-Document. Skipping billing log.', Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, CustomDimensions);
    end;

    internal procedure LogBillingTooManyDocumentsWithoutLines(EDocumentEntryNo: Integer; NumberOfDocumentsWithoutLines: Integer)
    var
        CustomDimensions: Dictionary of [Text, Text];
        PayablesAgentNoLinesDocumentCountTok: Label 'documentsWithoutLines', Locked = true;
    begin
        CustomDimensions := GetBillingDocumentDimensions(EDocumentEntryNo);
        CustomDimensions.Add(PayablesAgentNoLinesDocumentCountTok, Format(NumberOfDocumentsWithoutLines, 0, 9));
        Session.LogMessage('0000QIN', 'Detected too many documents without lines.', Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, CustomDimensions);
    end;

    internal procedure LogBillingLinesExtracted(UpperLineRange: Integer)
    var
        CustomDimensions: Dictionary of [Text, Text];
        LinesExtractedForEDocumentLbl: Label 'Lines extracted for the E-Document.', Locked = true;
    begin
        CustomDimensions := PATelemetry.GetCustomDimensions();
        CustomDimensions.Add('UpperLineRange', Format(UpperLineRange, 0, 9));
        Session.LogMessage('0000QIO', LinesExtractedForEDocumentLbl, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, CustomDimensions);
    end;

    internal procedure LogBillingMissingInvoiceNumber()
    begin
        Session.LogMessage('0000QFC', 'The invoice number is empty.', Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, PATelemetry.GetCustomDimensions());
    end;

    internal procedure LogBillingMissingVendorName()
    begin
        Session.LogMessage('0000QFD', 'The vendor company name is empty.', Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, PATelemetry.GetCustomDimensions());
    end;

    internal procedure LogBillingNoLinesExtracted()
    begin
        Session.LogMessage('0000QFE', 'No lines were extracted for the E-Document.', Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, PATelemetry.GetCustomDimensions());
    end;

    internal procedure LogBillingAgentTaskNotFound()
    var
        CustomDimensions: Dictionary of [Text, Text];
    begin
        // Historically emitted without the category dimension.
        Session.LogMessage('0000TCT', 'Agent Task not found for logging billing record.', Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, CustomDimensions);
    end;

    internal procedure LogBillingDuplicateOperation()
    begin
        Session.LogMessage('0000R34', 'Billing log already exists for this operation. Skipping duplicate log.', Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, PATelemetry.GetCustomDimensions());
    end;

    internal procedure LogBillingDailyLimitReached(NewUsageConsumed: Decimal)
    var
        CustomDimensions: Dictionary of [Text, Text];
        PayablesAgentAAChargedTok: Label 'autonomousActionsCharged', Locked = true;
    begin
        CustomDimensions := PATelemetry.GetCustomDimensions();
        CustomDimensions.Add(PayablesAgentAAChargedTok, Format(NewUsageConsumed, 0, 9));
        Session.LogMessage('0000QIP', 'Daily credit limit reached. Billing log will not be created.', Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, CustomDimensions);
    end;

    internal procedure LogBillingOperationCreated(Operation: Text; ExcludeFromBilling: Boolean)
    var
        CustomDimensions: Dictionary of [Text, Text];
        CreatedPABillingOperationMsg: Label 'Created a Payables Agent billing operation.', Locked = true;
    begin
        CustomDimensions := PATelemetry.GetCustomDimensions();
        CustomDimensions.Add('Operation', Operation);
        CustomDimensions.Add('ExcludeFromBilling', Format(ExcludeFromBilling, 0, 9));
        Session.LogMessage('0000PO3', CreatedPABillingOperationMsg, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, CustomDimensions);
    end;

    local procedure GetBillingDocumentDimensions(EDocumentEntryNo: Integer) CustomDimensions: Dictionary of [Text, Text]
    begin
        CustomDimensions := PATelemetry.GetCustomDimensions();
        CustomDimensions.Add('EDocumentEntryNo', Format(EDocumentEntryNo));
    end;
    #endregion
}
