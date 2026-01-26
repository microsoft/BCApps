// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Document;

using Microsoft.Bank.BankAccount;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Service.History;
using Microsoft.Service.Posting;

codeunit 13410 "Serv. Document Mgt. FI"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Serv-Documents Mgt.", 'OnBeforeServInvHeaderInsert', '', false, false)]
    local procedure OnBeforeServInvHeaderInsert(var ServiceInvoiceHeader: Record "Service Invoice Header")
    var
        CreateReference: Codeunit "Bank Nos Check";
    begin
        ServiceInvoiceHeader."Reference No." :=
          CreateReference.CreateSalesInvReference(ServiceInvoiceHeader."No.", ServiceInvoiceHeader."Bill-to Customer No.");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Serv-Documents Mgt.", 'OnAfterGetInvoicePostingParameters', '', false, false)]
    local procedure OnAfterGetInvoicePostingParameters(var InvoicePostingParameters: Record "Invoice Posting Parameters" temporary; var ServiceInvoiceHeader: Record "Service Invoice Header")
    begin
        InvoicePostingParameters."Auto Document No." := ServiceInvoiceHeader."Reference No.";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Service Post Invoice Events", 'OnPostLedgerEntryOnBeforeGenJnlPostLine', '', false, false)]
    local procedure OnPostLedgerEntryOnBeforeGenJnlPostLine(var GenJournalLine: Record "Gen. Journal Line"; InvoicePostingParameters: Record "Invoice Posting Parameters" temporary)
    begin
        GenJournalLine."Reference No." := InvoicePostingParameters."Auto Document No.";
    end;
}