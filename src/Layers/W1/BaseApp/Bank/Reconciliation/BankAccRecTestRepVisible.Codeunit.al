// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Reconciliation;

using Microsoft.Bank.Reports;
using Microsoft.Foundation.Reporting;

codeunit 385 "Bank Acc.Rec.Test Rep. Visible"
{
    EventSubscriberInstance = Manual;

    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";

    [EventSubscriber(ObjectType::Report, Report::"Bank Acc. Recon. - Test", 'OnBeforeInitReport', '', false, false)]
    local procedure OnBeforePrintDocument(var ShouldShowOutstandingBankTransactions: Boolean)
    begin
        ShouldShowOutstandingBankTransactions := true;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Report Selections", 'OnBeforePrintDocument', '', false, false)]
    local procedure OnBeforePrintDocumentReportSelections(TempReportSelections: Record "Report Selections" temporary; IsGUI: Boolean; var RecVarToPrint: Variant; var IsHandled: Boolean)
    begin
        Session.LogMessage('0000JLN', Format(TempReportSelections.Usage) + ' ' + Format(TempReportSelections."Report ID"), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', BankAccReconciliation.GetBankReconciliationTelemetryFeatureName());
    end;

}
