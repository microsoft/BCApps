// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Document;

using Microsoft.Bank.BankAccount;
using Microsoft.Bank.Payment;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Service.History;
using Microsoft.Service.Posting;

codeunit 13535 "Service Payment References FI"
{

#if not CLEAN30
    var
        FIBankingPaymentFeature: Codeunit "Banking Payments Feature FI";
#endif

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Serv-Documents Mgt.", 'OnBeforeServInvHeaderInsert', '', false, false)]
    local procedure OnBeforeServInvHeaderInsert(var ServiceInvoiceHeader: Record "Service Invoice Header")
    var
        CreateReference: Codeunit "Bank Nos Check FI";
    begin
#if not CLEAN30
        if not FIBankingPaymentFeature.IsEnabled() then
            exit;
#endif

        ServiceInvoiceHeader."Payment Reference No." :=
          CreateReference.CreateSalesInvReference(ServiceInvoiceHeader."No.", ServiceInvoiceHeader."Bill-to Customer No.");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Serv-Documents Mgt.", 'OnAfterGetInvoicePostingParameters', '', false, false)]
    local procedure OnAfterGetInvoicePostingParameters(var InvoicePostingParameters: Record "Invoice Posting Parameters"; var ServiceInvoiceHeader: Record "Service Invoice Header")
    begin
#if not CLEAN30
        if not FIBankingPaymentFeature.IsEnabled() then
            exit;
#endif

        InvoicePostingParameters."Auto Document No." := ServiceInvoiceHeader."Payment Reference No.";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Service Post Invoice Events", 'OnPostLedgerEntryOnBeforeGenJnlPostLine', '', false, false)]
    local procedure OnPostLedgerEntryOnBeforeGenJnlPostLine(var GenJournalLine: Record "Gen. Journal Line"; InvoicePostingParameters: Record "Invoice Posting Parameters")
    begin
#if not CLEAN30
        if not FIBankingPaymentFeature.IsEnabled() then
            exit;
#endif

        GenJournalLine."Payment Reference No." := InvoicePostingParameters."Auto Document No.";
    end;
}
