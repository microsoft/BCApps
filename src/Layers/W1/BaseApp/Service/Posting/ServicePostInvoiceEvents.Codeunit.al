// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Posting;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Posting;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Sales.Receivables;
using Microsoft.Service.Document;

codeunit 827 "Service Post Invoice Events"
{
    // OnAfter events

    procedure RunOnAfterUpdateInvoicePostingBuffer(var InvoicePostingBuffer: Record "Invoice Posting Buffer")
    begin
        OnAfterUpdateInvoicePostingBuffer(InvoicePostingBuffer);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateInvoicePostingBuffer(var InvoicePostingBuffer: Record "Invoice Posting Buffer")
    begin
    end;

    procedure RunOnAfterGetSalesAccount(ServiceLine: Record "Service Line"; GenPostingSetup: Record "General Posting Setup"; var SalesAccountNo: Code[20])
    begin
        OnAfterGetSalesAccount(ServiceLine, GenPostingSetup, SalesAccountNo);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetSalesAccount(ServiceLine: Record "Service Line"; GenPostingSetup: Record "General Posting Setup"; var SalesAccountNo: Code[20])
    begin
    end;

    procedure RunOnAfterPrepareGenJnlLineFromInvoicePostBuffer(ServiceHeader: Record "Service Header"; var InvoicePostingBuffer: Record "Invoice Posting Buffer"; var GenJournalLine: Record "Gen. Journal Line")
    begin
        OnAfterPrepareGenJnlLineFromInvoicePostBuffer(ServiceHeader, InvoicePostingBuffer, GenJournalLine);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPrepareGenJnlLineFromInvoicePostBuffer(ServiceHeader: Record "Service Header"; var InvoicePostingBuffer: Record "Invoice Posting Buffer"; var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    // OnBefore events

    procedure RunOnBeforePrepareLine(ServiceHeader: Record "Service Header"; ServiceLine: Record "Service Line"; ServiceLineACY: Record "Service Line"; var IsHandled: Boolean)
    begin
        OnBeforePrepareLine(ServiceHeader, ServiceLine, ServiceLineACY, IsHandled);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePrepareLine(ServiceHeader: Record "Service Header"; ServiceLine: Record "Service Line"; ServiceLineACY: Record "Service Line"; var IsHandled: Boolean)
    begin
    end;

    procedure RunOnBeforePostLines(ServiceHeader: Record "Service Header"; var TempInvoicePostingBuffer: Record "Invoice Posting Buffer" temporary)
    begin
        OnBeforePostLines(ServiceHeader, TempInvoicePostingBuffer);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostLines(ServiceHeader: Record "Service Header"; var TempInvoicePostingBuffer: Record "Invoice Posting Buffer" temporary)
    begin
    end;

    procedure RunOnBeforeCalcInvoiceDiscountPosting(ServiceHeader: Record "Service Header"; ServiceLine: Record "Service Line"; ServiceLineACY: Record "Service Line"; var InvoicePostingBuffer: Record "Invoice Posting Buffer"; var IsHandled: Boolean)
    begin
        OnBeforeCalcInvoiceDiscountPosting(ServiceHeader, ServiceLine, ServiceLineACY, InvoicePostingBuffer, IsHandled);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcInvoiceDiscountPosting(ServiceHeader: Record "Service Header"; ServiceLine: Record "Service Line"; ServiceLineACY: Record "Service Line"; var InvoicePostingBuffer: Record "Invoice Posting Buffer"; var IsHandled: Boolean)
    begin
    end;

    procedure RunOnBeforeCalcLineDiscountPosting(ServiceHeader: Record "Service Header"; ServiceLine: Record "Service Line"; ServiceLineACY: Record "Service Line"; var InvoicePostingBuffer: Record "Invoice Posting Buffer"; var IsHandled: Boolean)
    begin
        OnBeforeCalcLineDiscountPosting(ServiceHeader, ServiceLine, ServiceLineACY, InvoicePostingBuffer, IsHandled);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcLineDiscountPosting(ServiceHeader: Record "Service Header"; ServiceLine: Record "Service Line"; ServiceLineACY: Record "Service Line"; var InvoicePostingBuffer: Record "Invoice Posting Buffer"; var IsHandled: Boolean)
    begin
    end;

    procedure RunOnBeforeGetSalesAccount(ServiceLine: Record "Service Line"; GenPostingSetup: Record "General Posting Setup"; var SalesAccountNo: Code[20]; var IsHandled: Boolean)
    begin
        OnBeforeGetSalesAccount(ServiceLine, GenPostingSetup, SalesAccountNo, IsHandled);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetSalesAccount(ServiceLine: Record "Service Line"; GenPostingSetup: Record "General Posting Setup"; var SalesAccountNo: Code[20]; var IsHandled: Boolean)
    begin
    end;

    procedure RunOnUpdateInvoicePostingBufferOnBeforeUpdate(var InvoicePostingBuffer: Record "Invoice Posting Buffer")
    begin
        OnUpdateInvoicePostingBufferOnBeforeUpdate(InvoicePostingBuffer);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateInvoicePostingBufferOnBeforeUpdate(var InvoicePostingBuffer: Record "Invoice Posting Buffer")
    begin
    end;

    // Prepare Line

    procedure RunOnPrepareLineOnAfterFillInvoicePostingBuffer(var InvoicePostingBuffer: Record "Invoice Posting Buffer"; ServiceLine: Record "Service Line"; ServiceLineACY: Record "Service Line"; SuppressCommit: Boolean; var TempInvoicePostingBuffer: Record "Invoice Posting Buffer" temporary)
    begin
        OnPrepareLineOnAfterFillInvoicePostingBuffer(InvoicePostingBuffer, ServiceLine, ServiceLineACY, SuppressCommit, TempInvoicePostingBuffer);
    end;

#if not CLEAN27
    [Obsolete('Replaced by same procedure with parameter TempInvoicePostingBuffer', '27.0')]
    procedure RunOnPrepareLineOnAfterFillInvoicePostingBuffer(var InvoicePostingBuffer: Record "Invoice Posting Buffer"; ServiceLine: Record "Service Line"; ServiceLineACY: Record "Service Line"; SuppressCommit: Boolean)
    var
        TempDummyInvoicePostingBuffer: Record "Invoice Posting Buffer" temporary;
    begin
        OnPrepareLineOnAfterFillInvoicePostingBuffer(InvoicePostingBuffer, ServiceLine, ServiceLineACY, SuppressCommit, TempDummyInvoicePostingBuffer);
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnPrepareLineOnAfterFillInvoicePostingBuffer(var InvoicePostingBuffer: Record "Invoice Posting Buffer"; ServiceLine: Record "Service Line"; ServiceLineACY: Record "Service Line"; SuppressCommit: Boolean; var TempInvoicePostingBuffer: Record "Invoice Posting Buffer" temporary)
    begin
    end;

    procedure RunOnPrepareLineOnAfterSetAmounts(var InvoicePostingBuffer: Record "Invoice Posting Buffer"; ServiceLine: Record "Service Line")
    begin
        OnPrepareLineOnAfterSetAmounts(InvoicePostingBuffer, ServiceLine);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPrepareLineOnAfterSetAmounts(var InvoicePostingBuffer: Record "Invoice Posting Buffer"; ServiceLine: Record "Service Line")
    begin
    end;

    procedure RunOnPrepareLineOnBeforeSetAmounts(ServiceLine: Record "Service Line"; ServiceLineACY: Record "Service Line"; var InvoicePostingBuffer: Record "Invoice Posting Buffer"; var TotalVAT: Decimal; var TotalVATACY: Decimal; var TotalAmount: Decimal; var TotalAmountACY: Decimal; var TotalVATBase: Decimal; var TotalVATBaseACY: Decimal; var IsHandled: Boolean)
    begin
        OnPrepareLineOnBeforeSetAmounts(ServiceLine, ServiceLineACY, InvoicePostingBuffer, TotalVAT, TotalVATACY, TotalAmount, TotalAmountACY, TotalVATBase, TotalVATBaseACY, IsHandled);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPrepareLineOnBeforeSetAmounts(ServiceLine: Record "Service Line"; ServiceLineACY: Record "Service Line"; var InvoicePostingBuffer: Record "Invoice Posting Buffer"; var TotalVAT: Decimal; var TotalVATACY: Decimal; var TotalAmount: Decimal; var TotalAmountACY: Decimal; var TotalVATBase: Decimal; var TotalVATBaseACY: Decimal; var IsHandled: Boolean)
    begin
    end;

    procedure RunOnPrepareLineOnBeforeSetAccount(ServiceHeader: Record "Service Header"; ServiceLine: Record "Service Line"; var SalesAccountNo: Code[20])
    begin
        OnPrepareLineOnBeforeSetAccount(ServiceHeader, ServiceLine, SalesAccountNo);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPrepareLineOnBeforeSetAccount(ServiceHeader: Record "Service Header"; ServiceLine: Record "Service Line"; var SalesAccountNo: Code[20])
    begin
    end;

    procedure RunOnPrepareLineOnBeforeUpdateInvoicePostingBufferLineDiscounts(var InvoicePostingBuffer: Record "Invoice Posting Buffer"; ServiceLine: Record "Service Line")
    begin
        OnPrepareLineOnBeforeUpdateInvoicePostingBufferLineDiscounts(InvoicePostingBuffer, ServiceLine)
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPrepareLineOnBeforeUpdateInvoicePostingBufferLineDiscounts(var InvoicePostingBuffer: Record "Invoice Posting Buffer"; ServiceLine: Record "Service Line")
    begin
    end;

    // Post Balancing Entry

    procedure RunOnPostBalancingEntryOnAfterGenJnlPostLine(var GenJournalLine: Record "Gen. Journal Line"; ServiceHeader: Record "Service Header"; var TotalServiceLine: Record "Service Line"; var TotalServiceLineLCY: Record "Service Line"; PreviewMode: Boolean; SuppressCommit: Boolean; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    begin
        OnPostBalancingEntryOnAfterGenJnlPostLine(GenJournalLine, ServiceHeader, TotalServiceLine, TotalServiceLineLCY, PreviewMode, SuppressCommit, GenJnlPostLine);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostBalancingEntryOnAfterGenJnlPostLine(var GenJournalLine: Record "Gen. Journal Line"; ServiceHeader: Record "Service Header"; var TotalServiceLine: Record "Service Line"; var TotalServiceLineLCY: Record "Service Line"; PreviewMode: Boolean; SuppressCommit: Boolean; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    begin
    end;

    procedure RunOnPostBalancingEntryOnBeforeGenJnlPostLine(var GenJournalLine: Record "Gen. Journal Line"; ServiceHeader: Record "Service Header"; var TotalServiceLine: Record "Service Line"; var TotalServiceLineLCY: Record "Service Line"; PreviewMode: Boolean; SuppressCommit: Boolean; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    begin
        OnPostBalancingEntryOnBeforeGenJnlPostLine(GenJournalLine, ServiceHeader, TotalServiceLine, TotalServiceLineLCY, PreviewMode, SuppressCommit, GenJnlPostLine);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostBalancingEntryOnBeforeGenJnlPostLine(var GenJournalLine: Record "Gen. Journal Line"; ServiceHeader: Record "Service Header"; var TotalServiceLine: Record "Service Line"; var TotalServiceLineLCY: Record "Service Line"; PreviewMode: Boolean; SuppressCommit: Boolean; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    begin
    end;

    internal procedure RunOnPostBalancingEntryOnBeforeFindCustLedgerEntry(var ServiceHeader: Record "Service Header"; var CustLedgerEntry: Record "Cust. Ledger Entry"; var IsHandled: Boolean)
    begin
        OnPostBalancingEntryOnBeforeFindCustLedgerEntry(ServiceHeader, CustLedgerEntry, IsHandled);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostBalancingEntryOnBeforeFindCustLedgerEntry(var ServiceHeader: Record "Service Header"; var CustLedgerEntry: Record "Cust. Ledger Entry"; var IsHandled: Boolean)
    begin
    end;

    // Post Ledger Entry

    procedure RunOnPostLedgerEntryOnAfterGenJnlPostLine(var GenJournalLine: Record "Gen. Journal Line"; ServiceHeader: Record "Service Header"; var TotalServiceLine: Record "Service Line"; var TotalServiceLineLCY: Record "Service Line"; PreviewMode: Boolean; SuppressCommit: Boolean; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    begin
        OnPostLedgerEntryOnAfterGenJnlPostLine(GenJournalLine, ServiceHeader, TotalServiceLine, TotalServiceLineLCY, PreviewMode, SuppressCommit, GenJnlPostLine);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostLedgerEntryOnAfterGenJnlPostLine(var GenJournalLine: Record "Gen. Journal Line"; ServiceHeader: Record "Service Header"; var TotalServiceLine: Record "Service Line"; var TotalServiceLineLCY: Record "Service Line"; PreviewMode: Boolean; SuppressCommit: Boolean; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    begin
    end;

#if not CLEAN26
    [Obsolete('Replaced by same procedure with parameter InvoicePostingParameters', '26.0')]
    procedure RunOnPostLedgerEntryOnBeforeGenJnlPostLine(var GenJournalLine: Record "Gen. Journal Line"; ServiceHeader: Record "Service Header"; var TotalServiceLine: Record "Service Line"; var TotalServiceLineLCY: Record "Service Line"; PreviewMode: Boolean; SuppressCommit: Boolean; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    var
        DummyInvoicePostingParameters: Record "Invoice Posting Parameters";
    begin
        OnPostLedgerEntryOnBeforeGenJnlPostLine(GenJournalLine, ServiceHeader, TotalServiceLine, TotalServiceLineLCY, PreviewMode, SuppressCommit, GenJnlPostLine, DummyInvoicePostingParameters);
    end;
#endif

    procedure RunOnPostLedgerEntryOnBeforeGenJnlPostLine(var GenJournalLine: Record "Gen. Journal Line"; ServiceHeader: Record "Service Header"; var TotalServiceLine: Record "Service Line"; var TotalServiceLineLCY: Record "Service Line"; PreviewMode: Boolean; SuppressCommit: Boolean; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; InvoicePostingParameters: Record "Invoice Posting Parameters")
    begin
        OnPostLedgerEntryOnBeforeGenJnlPostLine(GenJournalLine, ServiceHeader, TotalServiceLine, TotalServiceLineLCY, PreviewMode, SuppressCommit, GenJnlPostLine, InvoicePostingParameters);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostLedgerEntryOnBeforeGenJnlPostLine(var GenJournalLine: Record "Gen. Journal Line"; ServiceHeader: Record "Service Header"; var TotalServiceLine: Record "Service Line"; var TotalServiceLineLCY: Record "Service Line"; PreviewMode: Boolean; SuppressCommit: Boolean; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; InvoicePostingParameters: Record "Invoice Posting Parameters")
    begin
    end;

    // Post Lines

    procedure RunOnPostLinesOnAfterGenJnlLinePost(var GenJnlLine: Record "Gen. Journal Line"; ServiceHeader: Record "Service Header"; TempInvoicePostingBuffer: Record "Invoice Posting Buffer"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; PreviewMode: Boolean; SuppressCommit: Boolean; GLEntryNo: Integer)
    begin
        OnPostLinesOnAfterGenJnlLinePost(GenJnlLine, ServiceHeader, TempInvoicePostingBuffer, GenJnlPostLine, PreviewMode, SuppressCommit, GLEntryNo);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostLinesOnAfterGenJnlLinePost(var GenJnlLine: Record "Gen. Journal Line"; ServiceHeader: Record "Service Header"; TempInvoicePostingBuffer: Record "Invoice Posting Buffer"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; PreviewMode: Boolean; SuppressCommit: Boolean; GLEntryNo: Integer)
    begin
    end;

    procedure RunOnPostLinesOnBeforeGenJnlLinePost(var GenJnlLine: Record "Gen. Journal Line"; ServiceHeader: Record "Service Header"; TempInvoicePostingBuffer: Record "Invoice Posting Buffer"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; PreviewMode: Boolean; SuppressCommit: Boolean)
    begin
        OnPostLinesOnBeforeGenJnlLinePost(GenJnlLine, ServiceHeader, TempInvoicePostingBuffer, GenJnlPostLine, PreviewMode, SuppressCommit);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostLinesOnBeforeGenJnlLinePost(var GenJnlLine: Record "Gen. Journal Line"; ServiceHeader: Record "Service Header"; TempInvoicePostingBuffer: Record "Invoice Posting Buffer"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; PreviewMode: Boolean; SuppressCommit: Boolean)
    begin
    end;

    procedure RunOnPrepareLineAfterGetGenPostingSetup(var GeneralPostingSetup: Record "General Posting Setup"; ServiceHeader: Record "Service Header"; ServiceLine: Record "Service Line"; ServiceLineACY: Record "Service Line")
    begin
        OnPrepareLineAfterGetGenPostingSetup(GeneralPostingSetup, ServiceHeader, ServiceLine, ServiceLineACY);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPrepareLineAfterGetGenPostingSetup(var GeneralPostingSetup: Record "General Posting Setup"; ServiceHeader: Record "Service Header"; ServiceLine: Record "Service Line"; ServiceLineACY: Record "Service Line")
    begin
    end;

    procedure RunOnAfterPrepareInvoicePostingBuffer(var ServiceLine: Record "Service Line"; var InvoicePostingBuffer: Record "Invoice Posting Buffer")
    begin
        OnAfterPrepareInvoicePostingBuffer(ServiceLine, InvoicePostingBuffer);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPrepareInvoicePostingBuffer(var ServiceLine: Record "Service Line"; var InvoicePostingBuffer: Record "Invoice Posting Buffer")
    begin
    end;

    procedure RunOnBeforePrepareInvoicePostingBuffer(var ServiceLine: Record "Service Line"; var InvoicePostingBuffer: Record "Invoice Posting Buffer")
    begin
        OnBeforePrepareInvoicePostingBuffer(ServiceLine, InvoicePostingBuffer);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePrepareInvoicePostingBuffer(var ServiceLine: Record "Service Line"; var InvoicePostingBuffer: Record "Invoice Posting Buffer")
    begin
    end;
}
