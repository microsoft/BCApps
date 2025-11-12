// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Posting;

using Microsoft.Finance.Deferral;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Posting;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Sales.Document;
using Microsoft.Sales.Receivables;

codeunit 825 "Sales Post Invoice Events"
{
    // OnAfter events

    procedure RunOnAfterCalcInvoiceDiscountPosting(SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; SalesLineACY: Record "Sales Line"; var InvoicePostingBuffer: Record "Invoice Posting Buffer")
    begin
        OnAfterCalcInvoiceDiscountPosting(SalesHeader, SalesLine, SalesLineACY, InvoicePostingBuffer);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcInvoiceDiscountPosting(SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; SalesLineACY: Record "Sales Line"; var InvoicePostingBuffer: Record "Invoice Posting Buffer")
    begin
    end;

    procedure RunOnAfterCalcLineDiscountPosting(SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; SalesLineACY: Record "Sales Line"; var InvoicePostingBuffer: Record "Invoice Posting Buffer")
    begin
        OnAfterCalcLineDiscountPosting(SalesHeader, SalesLine, SalesLineACY, InvoicePostingBuffer);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcLineDiscountPosting(SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; SalesLineACY: Record "Sales Line"; var InvoicePostingBuffer: Record "Invoice Posting Buffer")
    begin
    end;

    procedure RunOnBeforeCreatePostedDeferralSchedule(var SalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
        OnBeforeCreatePostedDeferralSchedule(SalesLine, IsHandled);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreatePostedDeferralSchedule(var SalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    procedure RunOnAfterCreatePostedDeferralSchedule(var SalesLine: Record "Sales Line"; var PostedDeferralHeader: Record "Posted Deferral Header")
    begin
        OnAfterCreatePostedDeferralSchedule(SalesLine, PostedDeferralHeader);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreatePostedDeferralSchedule(var SalesLine: Record "Sales Line"; var PostedDeferralHeader: Record "Posted Deferral Header")
    begin
    end;

    procedure RunOnAfterGetSalesAccount(SalesLine: Record "Sales Line"; GenPostingSetup: Record "General Posting Setup"; var SalesAccountNo: Code[20])
    var
        SalesHeader: Record "Sales Header";
    begin
        if SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.") then;
        OnAfterGetSalesAccount(SalesLine, GenPostingSetup, SalesAccountNo, SalesHeader);
    end;

    procedure RunOnAfterGetSalesAccount(SalesLine: Record "Sales Line"; GenPostingSetup: Record "General Posting Setup"; var SalesAccountNo: Code[20]; SalesHeader: Record "Sales Header")
    begin
        OnAfterGetSalesAccount(SalesLine, GenPostingSetup, SalesAccountNo, SalesHeader);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetSalesAccount(SalesLine: Record "Sales Line"; GenPostingSetup: Record "General Posting Setup"; var SalesAccountNo: Code[20]; SalesHeader: Record "Sales Header")
    begin
    end;

    procedure RunOnBeforeGetSalesAccount(SalesLine: Record "Sales Line"; GenPostingSetup: Record "General Posting Setup"; var SalesAccountNo: Code[20]; var IsHandled: Boolean)
    begin
        OnBeforeGetSalesAccount(SalesLine, GenPostingSetup, SalesAccountNo, IsHandled);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetSalesAccount(SalesLine: Record "Sales Line"; GenPostingSetup: Record "General Posting Setup"; var SalesAccountNo: Code[20]; var IsHandled: Boolean)
    begin
    end;

    procedure RunOnBeforeGetAmountsForDeferral(SalesLine: Record "Sales Line"; var AmtToDefer: Decimal; var AmtToDeferACY: Decimal; var DeferralAccount: Code[20]; var IsHandled: Boolean)
    begin
        OnBeforeGetAmountsForDeferral(SalesLine, AmtToDefer, AmtToDeferACY, DeferralAccount, IsHandled);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetAmountsForDeferral(SalesLine: Record "Sales Line"; var AmtToDefer: Decimal; var AmtToDeferACY: Decimal; var DeferralAccount: Code[20]; var IsHandled: Boolean)
    begin
    end;

    procedure RunOnAfterInitTotalAmounts(SalesLine: Record "Sales Line"; SalesLineACY: Record "Sales Line"; var TotalVAT: Decimal; var TotalVATACY: Decimal; var TotalAmount: Decimal; var TotalAmountACY: Decimal; var TotalVATBase: Decimal; var TotalVATBaseACY: Decimal)
    begin
        OnAfterInitTotalAmounts(SalesLine, SalesLineACY, TotalVAT, TotalVATACY, TotalAmount, TotalAmountACY, TotalVATBase, TotalVATBaseACY);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitTotalAmounts(SalesLine: Record "Sales Line"; SalesLineACY: Record "Sales Line"; var TotalVAT: Decimal; var TotalVATACY: Decimal; var TotalAmount: Decimal; var TotalAmountACY: Decimal; var TotalVATBase: Decimal; var TotalVATBaseACY: Decimal)
    begin
    end;

    procedure RunOnAfterPrepareGenJnlLine(var GenJnlLine: Record "Gen. Journal Line"; SalesHeader: Record "Sales Header"; InvoicePostingBuffer: Record "Invoice Posting Buffer")
    begin
        OnAfterPrepareGenJnlLine(GenJnlLine, SalesHeader, InvoicePostingBuffer);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPrepareGenJnlLine(var GenJnlLine: Record "Gen. Journal Line"; SalesHeader: Record "Sales Header"; InvoicePostingBuffer: Record "Invoice Posting Buffer")
    begin
    end;

    procedure RunOnAfterSetApplyToDocNo(var GenJournalLine: Record "Gen. Journal Line"; SalesHeader: Record "Sales Header")
    begin
        OnAfterSetApplyToDocNo(GenJournalLine, SalesHeader);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetApplyToDocNo(var GenJournalLine: Record "Gen. Journal Line"; SalesHeader: Record "Sales Header")
    begin
    end;

    procedure RunOnAfterSetJobLineFilters(var JobSalesLine: Record "Sales Line"; InvoicePostingBuffer: Record "Invoice Posting Buffer")
    begin
        OnAfterSetJobLineFilters(JobSalesLine, InvoicePostingBuffer);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetJobLineFilters(var JobSalesLine: Record "Sales Line"; InvoicePostingBuffer: Record "Invoice Posting Buffer")
    begin
    end;

    // OnBefore events

    procedure RunOnBeforeCalcInvoiceDiscountPosting(SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; SalesLineACY: Record "Sales Line"; var InvoicePostingBuffer: Record "Invoice Posting Buffer"; var IsHandled: Boolean)
    begin
        OnBeforeCalcInvoiceDiscountPosting(SalesHeader, SalesLine, SalesLineACY, InvoicePostingBuffer, IsHandled);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcInvoiceDiscountPosting(SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; SalesLineACY: Record "Sales Line"; var InvoicePostingBuffer: Record "Invoice Posting Buffer"; var IsHandled: Boolean)
    begin
    end;

    procedure RunOnBeforeCalcLineDiscountPosting(SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; SalesLineACY: Record "Sales Line"; var InvoicePostingBuffer: Record "Invoice Posting Buffer"; var IsHandled: Boolean)
    begin
        OnBeforeCalcLineDiscountPosting(SalesHeader, SalesLine, SalesLineACY, InvoicePostingBuffer, IsHandled);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcLineDiscountPosting(SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; SalesLineACY: Record "Sales Line"; var InvoicePostingBuffer: Record "Invoice Posting Buffer"; var IsHandled: Boolean)
    begin
    end;

    procedure RunOnBeforeInitGenJnlLine(var GenJnlLine: Record "Gen. Journal Line"; SalesHeader: Record "Sales Header"; InvoicePostingBuffer: Record "Invoice Posting Buffer"; var IsHandled: Boolean)
    begin
        OnBeforeInitGenJnlLine(GenJnlLine, SalesHeader, InvoicePostingBuffer, IsHandled);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitGenJnlLine(var GenJnlLine: Record "Gen. Journal Line"; SalesHeader: Record "Sales Header"; InvoicePostingBuffer: Record "Invoice Posting Buffer"; var IsHandled: Boolean)
    begin
    end;

    procedure RunOnBeforeInitGenJnlLineAmountFieldsFromTotalLines(var GenJnlLine: Record "Gen. Journal Line"; var SalesHeader: Record "Sales Header"; var TotalSalesLine: Record "Sales Line"; var TotalSalesLineLCY: Record "Sales Line"; var IsHandled: Boolean)
    begin
#if not CLEAN28
        OnBeforeInitGenJnlLineAmountFieldsFromTotalLines(GenJnlLine, SalesHeader, TotalSalesLine, TotalSalesLineLCY, IsHandled);
#endif
        OnBeforeInitGenJnlLineAmountFieldsFromTotalLines2(GenJnlLine, SalesHeader, TotalSalesLine, TotalSalesLineLCY, IsHandled);
    end;

#if not CLEAN28
    [Obsolete('Replaced by OnBeforeInitGenJnlLineAmountFieldsFromTotalLines2', '28.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitGenJnlLineAmountFieldsFromTotalLines(var GenJnlLine: Record "Gen. Journal Line"; var PurchHeader: Record "Sales Header"; var TotalPurchLine: Record "Sales Line"; var TotalPurchLineLCY: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitGenJnlLineAmountFieldsFromTotalLines2(var GenJnlLine: Record "Gen. Journal Line"; var SalesHeader: Record "Sales Header"; var TotalSalesLine: Record "Sales Line"; var TotalSalesLineLCY: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    procedure RunOnBeforeRunGenJnlPostLine(var GenJnlLine: Record "Gen. Journal Line"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    begin
        OnBeforeRunGenJnlPostLine(GenJnlLine, GenJnlPostLine);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRunGenJnlPostLine(var GenJnlLine: Record "Gen. Journal Line"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    begin
    end;

    procedure RunOnBeforeSetAmountsForBalancingEntry(var CustLedgEntry: Record "Cust. Ledger Entry"; var GenJnlLine: Record "Gen. Journal Line"; var TotalSalesLine: Record "Sales Line"; var TotalSalesLineLCY: Record "Sales Line"; var IsHandled: Boolean)
    begin
        OnBeforeSetAmountsForBalancingEntry(CustLedgEntry, GenJnlLine, TotalSalesLine, TotalSalesLineLCY, IsHandled);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetAmountsForBalancingEntry(var CustLedgEntry: Record "Cust. Ledger Entry"; var GenJnlLine: Record "Gen. Journal Line"; var TotalSalesLine: Record "Sales Line"; var TotalSalesLineLCY: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    procedure RunOnBeforePostLines(SalesHeader: Record "Sales Header"; var TempInvoicePostingBuffer: Record "Invoice Posting Buffer" temporary)
    begin
        OnBeforePostLines(SalesHeader, TempInvoicePostingBuffer);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostLines(SalesHeader: Record "Sales Header"; var TempInvoicePostingBuffer: Record "Invoice Posting Buffer" temporary)
    begin
    end;

    procedure RunOnBeforePostLedgerEntry(var SalesHeader: Record "Sales Header"; var TotalSalesLine: Record "Sales Line"; var TotalSalesLineLCY: Record "Sales Line"; PreviewMode: Boolean; SuppressCommit: Boolean; InvoicePostingParameters: Record "Invoice Posting Parameters"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; var IsHandled: Boolean)
    begin
        OnBeforePostLedgerEntry(SalesHeader, TotalSalesLine, TotalSalesLineLCY, PreviewMode, SuppressCommit, InvoicePostingParameters, GenJnlPostLine, IsHandled);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostLedgerEntry(var SalesHeader: Record "Sales Header"; var TotalSalesLine: Record "Sales Line"; var TotalSalesLineLCY: Record "Sales Line"; SuppressCommit: Boolean; PreviewMode: Boolean; InvoicePostingParameters: Record "Invoice Posting Parameters"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; var IsHandled: Boolean)
    begin
    end;

    procedure RunOnBeforePrepareLine(SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; SalesLineACY: Record "Sales Line"; var IsHandled: Boolean)
    begin
        OnBeforePrepareLine(SalesHeader, SalesLine, SalesLineACY, IsHandled);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePrepareLine(SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; SalesLineACY: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    procedure RunOnBeforeTempDeferralLineInsert(var TempDeferralLine: Record "Deferral Line" temporary; DeferralLine: Record "Deferral Line"; SalesLine: Record "Sales Line"; var DeferralCount: Integer; var TotalDeferralCount: Integer)
    begin
        OnBeforeTempDeferralLineInsert(TempDeferralLine, DeferralLine, SalesLine, DeferralCount, TotalDeferralCount);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTempDeferralLineInsert(var TempDeferralLine: Record "Deferral Line" temporary; DeferralLine: Record "Deferral Line"; SalesLine: Record "Sales Line"; var DeferralCount: Integer; var TotalDeferralCount: Integer)
    begin
    end;

    // Post Balancing Entry

    procedure RunOnPostBalancingEntryOnBeforeFindCustLedgEntry(SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; InvoicePostingParameters: Record "Invoice Posting Parameters"; var CustLedgerEntry: Record "Cust. Ledger Entry"; var EntryFound: Boolean; var IsHandled: Boolean)
    begin
        OnPostBalancingEntryOnBeforeFindCustLedgEntry(SalesHeader, SalesLine, InvoicePostingParameters, CustLedgerEntry, EntryFound, IsHandled);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostBalancingEntryOnBeforeFindCustLedgEntry(SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; InvoicePostingParameters: Record "Invoice Posting Parameters"; var CustLedgerEntry: Record "Cust. Ledger Entry"; var EntryFound: Boolean; var IsHandled: Boolean)
    begin
    end;

    procedure RunOnPostBalancingEntryOnAfterGenJnlPostLine(var GenJnlLine: Record "Gen. Journal Line"; var SalesHeader: Record "Sales Header"; var TotalSalesLine: Record "Sales Line"; var TotalSalesLineLCY: Record "Sales Line"; PreviewMode: Boolean; SuppressCommit: Boolean; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    begin
        OnPostBalancingEntryOnAfterGenJnlPostLine(GenJnlLine, SalesHeader, TotalSalesLine, TotalSalesLineLCY, PreviewMode, SuppressCommit, GenJnlPostLine);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostBalancingEntryOnAfterGenJnlPostLine(var GenJnlLine: Record "Gen. Journal Line"; var SalesHeader: Record "Sales Header"; var TotalSalesLine: Record "Sales Line"; var TotalSalesLineLCY: Record "Sales Line"; PreviewMode: Boolean; SuppressCommit: Boolean; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    begin
    end;

    procedure RunOnPostBalancingEntryOnBeforeGenJnlPostLine(var GenJnlLine: Record "Gen. Journal Line"; var SalesHeader: Record "Sales Header"; var TotalSalesLine: Record "Sales Line"; var TotalSalesLineLCY: Record "Sales Line"; PreviewMode: Boolean; SuppressCommit: Boolean; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    begin
        OnPostBalancingEntryOnBeforeGenJnlPostLine(GenJnlLine, SalesHeader, TotalSalesLine, TotalSalesLineLCY, PreviewMode, SuppressCommit, GenJnlPostLine);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostBalancingEntryOnBeforeGenJnlPostLine(var GenJnlLine: Record "Gen. Journal Line"; var SalesHeader: Record "Sales Header"; var TotalSalesLine: Record "Sales Line"; var TotalSalesLineLCY: Record "Sales Line"; PreviewMode: Boolean; SuppressCommit: Boolean; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    begin
    end;

    procedure RunOnPostBalancingEntryOnAfterFindCustLedgEntry(var CustLedgEntry: Record "Cust. Ledger Entry")
    begin
        OnPostBalancingEntryOnAfterFindCustLedgEntry(CustLedgEntry);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostBalancingEntryOnAfterFindCustLedgEntry(var CustLedgEntry: Record "Cust. Ledger Entry")
    begin
    end;

    procedure RunOnPostBalancingEntryOnAfterInitNewLine(SalesHeader: Record "Sales Header"; var GenJournalLine: Record "Gen. Journal Line")
    begin
        OnPostBalancingEntryOnAfterInitNewLine(SalesHeader, GenJournalLine);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostBalancingEntryOnAfterInitNewLine(SalesHeader: Record "Sales Header"; var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;


    // Post Ledger Entry

    procedure RunOnPostLedgerEntryOnAfterGenJnlPostLine(var GenJnlLine: Record "Gen. Journal Line"; var SalesHeader: Record "Sales Header"; var TotalSalesLine: Record "Sales Line"; var TotalSalesLineLCY: Record "Sales Line"; PreviewMode: Boolean; SuppressCommit: Boolean; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    begin
        OnPostLedgerEntryOnAfterGenJnlPostLine(GenJnlLine, SalesHeader, TotalSalesLine, TotalSalesLineLCY, PreviewMode, SuppressCommit, GenJnlPostLine);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostLedgerEntryOnAfterGenJnlPostLine(var GenJnlLine: Record "Gen. Journal Line"; var SalesHeader: Record "Sales Header"; var TotalSalesLine: Record "Sales Line"; var TotalSalesLineLCY: Record "Sales Line"; PreviewMode: Boolean; SuppressCommit: Boolean; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    begin
    end;

    procedure RunOnPostLedgerEntryOnBeforeGenJnlPostLine(var GenJnlLine: Record "Gen. Journal Line"; var SalesHeader: Record "Sales Header"; var TotalSalesLine: Record "Sales Line"; var TotalSalesLineLCY: Record "Sales Line"; PreviewMode: Boolean; SuppressCommit: Boolean; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    begin
        OnPostLedgerEntryOnBeforeGenJnlPostLine(GenJnlLine, SalesHeader, TotalSalesLine, TotalSalesLineLCY, PreviewMode, SuppressCommit, GenJnlPostLine);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostLedgerEntryOnBeforeGenJnlPostLine(var GenJnlLine: Record "Gen. Journal Line"; var SalesHeader: Record "Sales Header"; var TotalSalesLine: Record "Sales Line"; var TotalSalesLineLCY: Record "Sales Line"; PreviewMode: Boolean; SuppressCommit: Boolean; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    begin
    end;

    // Prepare Line

    procedure RunOnPrepareLineOnAfterAssignAmounts(SalesLine: Record "Sales Line"; SalesLineACY: Record "Sales Line"; var TotalAmount: Decimal; var TotalAmountACY: Decimal)
    begin
        OnPrepareLineOnAfterAssignAmounts(SalesLine, SalesLineACY, TotalAmount, TotalAmountACY);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPrepareLineOnAfterAssignAmounts(SalesLine: Record "Sales Line"; SalesLineACY: Record "Sales Line"; var TotalAmount: Decimal; var TotalAmountACY: Decimal)
    begin
    end;

    procedure RunOnPrepareLineOnAfterSetAmounts(var InvoicePostingBuffer: Record "Invoice Posting Buffer"; SalesLine: Record "Sales Line")
    begin
        OnPrepareLineOnAfterSetAmounts(InvoicePostingBuffer, SalesLine);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPrepareLineOnAfterSetAmounts(var InvoicePostingBuffer: Record "Invoice Posting Buffer"; SalesLine: Record "Sales Line")
    begin
    end;

    procedure RunOnPrepareLineOnAfterFillInvoicePostingBuffer(var InvoicePostingBuffer: Record "Invoice Posting Buffer"; SalesLine: Record "Sales Line")
    begin
        OnPrepareLineOnAfterFillInvoicePostingBuffer(InvoicePostingBuffer, SalesLine);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPrepareLineOnAfterFillInvoicePostingBuffer(var InvoicePostingBuffer: Record "Invoice Posting Buffer"; SalesLine: Record "Sales Line")
    begin
    end;

    procedure RunOnPrepareLineOnBeforeAdjustTotalAmounts(SalesLine: Record "Sales Line"; var TotalAmount: Decimal; var TotalAmountACY: Decimal; UseDate: Date)
    begin
        OnPrepareLineOnBeforeAdjustTotalAmounts(SalesLine, TotalAmount, TotalAmountACY, UseDate);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPrepareLineOnBeforeAdjustTotalAmounts(SalesLine: Record "Sales Line"; var TotalAmount: Decimal; var TotalAmountACY: Decimal; UseDate: Date)
    begin
    end;

    procedure RunOnPrepareLineOnBeforeSetAccount(SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; var SalesAccount: Code[20])
    begin
        OnPrepareLineOnBeforeSetAccount(SalesHeader, SalesLine, SalesAccount);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPrepareLineOnBeforeSetAccount(SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; var SalesAccount: Code[20])
    begin
    end;

    procedure RunOnPrepareLineOnBeforeSetAmounts(SalesLine: Record "Sales Line"; SalesLineACY: Record "Sales Line"; var InvoicePostingBuffer: Record "Invoice Posting Buffer"; var TotalVAT: Decimal; var TotalVATACY: Decimal; var TotalAmount: Decimal; var TotalAmountACY: Decimal; var TotalVATBase: Decimal; var TotalVATBaseACY: Decimal; var IsHandled: Boolean)
    begin
        OnPrepareLineOnBeforeSetAmounts(SalesLine, SalesLineACY, InvoicePostingBuffer, TotalVAT, TotalVATACY, TotalAmount, TotalAmountACY, TotalVATBase, TotalVATBaseACY, IsHandled);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPrepareLineOnBeforeSetAmounts(SalesLine: Record "Sales Line"; SalesLineACY: Record "Sales Line"; var InvoicePostingBuffer: Record "Invoice Posting Buffer"; var TotalVAT: Decimal; var TotalVATACY: Decimal; var TotalAmount: Decimal; var TotalAmountACY: Decimal; var TotalVATBase: Decimal; var TotalVATBaseACY: Decimal; var IsHandled: Boolean)
    begin
    end;

    procedure RunOnPrepareLineOnAfterSetInvoiceDiscAccount(SalesLine: Record "Sales Line"; GenPostingSetup: Record "General Posting Setup"; var InvoicePostingBuffer: Record "Invoice Posting Buffer"; var TempInvoicePostingBuffer: Record "Invoice Posting Buffer" temporary)
    begin
        OnPrepareLineOnAfterSetInvoiceDiscAccount(SalesLine, GenPostingSetup, InvoicePostingBuffer, TempInvoicePostingBuffer);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPrepareLineOnAfterSetInvoiceDiscAccount(SalesLine: Record "Sales Line"; GenPostingSetup: Record "General Posting Setup"; var InvoicePostingBuffer: Record "Invoice Posting Buffer"; var TempInvoicePostingBuffer: Record "Invoice Posting Buffer" temporary)
    begin
    end;

    procedure RunOnPrepareLineOnAfterSetLineDiscAccount(SalesLine: Record "Sales Line"; GenPostingSetup: Record "General Posting Setup"; var InvoicePostingBuffer: Record "Invoice Posting Buffer"; var TempInvoicePostingBuffer: Record "Invoice Posting Buffer" temporary)
    begin
        OnPrepareLineOnAfterSetLineDiscAccount(SalesLine, GenPostingSetup, InvoicePostingBuffer, TempInvoicePostingBuffer);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPrepareLineOnAfterSetLineDiscAccount(SalesLine: Record "Sales Line"; GenPostingSetup: Record "General Posting Setup"; var InvoicePostingBuffer: Record "Invoice Posting Buffer"; var TempInvoicePostingBuffer: Record "Invoice Posting Buffer" temporary)
    begin
    end;

    procedure RunOnPrepareLineOnBeforeCalcInvoiceDiscountPosting(var TempInvoicePostingBuffer: Record "Invoice Posting Buffer"; var InvoicePostingBuffer: Record "Invoice Posting Buffer"; SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; TotalVAT: Decimal; TotalVATACY: Decimal; TotalAmount: Decimal; TotalAmountACY: Decimal; var IsHandled: Boolean)
    begin
        OnPrepareLineOnBeforeCalcInvoiceDiscountPosting(TempInvoicePostingBuffer, InvoicePostingBuffer, SalesHeader, SalesLine, TotalVAT, TotalVATACY, TotalAmount, TotalAmountACY, IsHandled);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPrepareLineOnBeforeCalcInvoiceDiscountPosting(var TempInvoicePostingBuffer: Record "Invoice Posting Buffer"; var InvoicePostingBuffer: Record "Invoice Posting Buffer"; SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; TotalVAT: Decimal; TotalVATACY: Decimal; TotalAmount: Decimal; TotalAmountACY: Decimal; var IsHandled: Boolean)
    begin
    end;

    procedure RunOnPrepareLineOnBeforeCalcLineDiscountPosting(var TempInvoicePostingBuffer: Record "Invoice Posting Buffer"; var InvoicePostingBuffer: Record "Invoice Posting Buffer"; SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; TotalVAT: Decimal; TotalVATACY: Decimal; TotalAmount: Decimal; TotalAmountACY: Decimal; var IsHandled: Boolean)
    begin
        OnPrepareLineOnBeforeCalcLineDiscountPosting(TempInvoicePostingBuffer, InvoicePostingBuffer, SalesHeader, SalesLine, TotalVAT, TotalVATACY, TotalAmount, TotalAmountACY, IsHandled);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPrepareLineOnBeforeCalcLineDiscountPosting(var TempInvoicePostingBuffer: Record "Invoice Posting Buffer"; var InvoicePostingBuffer: Record "Invoice Posting Buffer"; SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; TotalVAT: Decimal; TotalVATACY: Decimal; TotalAmount: Decimal; TotalAmountACY: Decimal; var IsHandled: Boolean)
    begin
    end;

    procedure RunOnPostLinesOnAfterGenJnlLinePost(var GenJnlLine: Record "Gen. Journal Line"; SalesHeader: Record "Sales Header"; TempInvoicePostingBuffer: Record "Invoice Posting Buffer"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; PreviewMode: Boolean; SuppressCommit: Boolean; GLEntryNo: Integer)
    begin
        OnPostLinesOnAfterGenJnlLinePost(GenJnlLine, SalesHeader, TempInvoicePostingBuffer, GenJnlPostLine, PreviewMode, SuppressCommit, GLEntryNo);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostLinesOnAfterGenJnlLinePost(var GenJnlLine: Record "Gen. Journal Line"; SalesHeader: Record "Sales Header"; TempInvoicePostingBuffer: Record "Invoice Posting Buffer"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; PreviewMode: Boolean; SuppressCommit: Boolean; GLEntryNo: Integer)
    begin
    end;

    procedure RunOnPostLinesOnBeforeGenJnlLinePost(var GenJnlLine: Record "Gen. Journal Line"; SalesHeader: Record "Sales Header"; TempInvoicePostingBuffer: Record "Invoice Posting Buffer"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; PreviewMode: Boolean; SuppressCommit: Boolean)
    begin
        OnPostLinesOnBeforeGenJnlLinePost(GenJnlLine, SalesHeader, TempInvoicePostingBuffer, GenJnlPostLine, PreviewMode, SuppressCommit);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostLinesOnBeforeGenJnlLinePost(var GenJnlLine: Record "Gen. Journal Line"; SalesHeader: Record "Sales Header"; TempInvoicePostingBuffer: Record "Invoice Posting Buffer"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; PreviewMode: Boolean; SuppressCommit: Boolean)
    begin
    end;

    procedure RunOnPostLinesOnBeforeTempInvoicePostingBufferDeleteAll(var SalesHeader: Record "Sales Header"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; var TotalSalesLine: Record "Sales Line"; var TotalSalesLineLCY: Record "Sales Line"; var InvoicePostingParameters: Record "Invoice Posting Parameters")
    begin
        OnPostLinesOnBeforeTempInvoicePostingBufferDeleteAll(SalesHeader, GenJnlPostLine, TotalSalesLine, TotalSalesLineLCY, InvoicePostingParameters);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostLinesOnBeforeTempInvoicePostingBufferDeleteAll(var SalesHeader: Record "Sales Header"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; var TotalSalesLine: Record "Sales Line"; var TotalSalesLineLCY: Record "Sales Line"; var InvoicePostingParameters: Record "Invoice Posting Parameters")
    begin
    end;

    procedure RunOnPrepareGenJnlLineOnAfterCopyToGenJnlLine(var GenJnlLine: Record "Gen. Journal Line"; SalesHeader: Record "Sales Header"; InvoicePostingBuffer: Record "Invoice Posting Buffer")
    begin
        OnPrepareGenJnlLineOnAfterCopyToGenJnlLine(GenJnlLine, SalesHeader, InvoicePostingBuffer);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPrepareGenJnlLineOnAfterCopyToGenJnlLine(var GenJnlLine: Record "Gen. Journal Line"; SalesHeader: Record "Sales Header"; InvoicePostingBuffer: Record "Invoice Posting Buffer")
    begin
    end;

    procedure RunOnPrepareLineOnAfterSetInvoiceDiscountPosting(SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; var InvoiceDiscountPosting: Boolean)
    begin
        OnPrepareLineOnAfterSetInvoiceDiscountPosting(SalesHeader, SalesLine, InvoiceDiscountPosting);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPrepareLineOnAfterSetInvoiceDiscountPosting(SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; var InvoiceDiscountPosting: Boolean)
    begin
    end;

    procedure RunOnPrepareLineOnAfterSetLineDiscountPosting(SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; var LineDiscountPosting: Boolean)
    begin
        OnPrepareLineOnAfterSetLineDiscountPosting(SalesHeader, SalesLine, LineDiscountPosting);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPrepareLineOnAfterSetLineDiscountPosting(SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; var LineDiscountPosting: Boolean)
    begin
    end;

    procedure RunOnPrepareLineOnAfterPrepareDeferralLine(SalesLine: Record "Sales Line"; InvoicePostingBuffer: Record "Invoice Posting Buffer"; UseDate: Date; InvDefLineNo: Integer; DeferralLineNo: Integer; SuppressCommit: Boolean)
    begin
        OnPrepareLineOnAfterPrepareDeferralLine(SalesLine, InvoicePostingBuffer, UseDate, InvDefLineNo, DeferralLineNo, SuppressCommit);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPrepareLineOnAfterPrepareDeferralLine(SalesLine: Record "Sales Line"; InvoicePostingBuffer: Record "Invoice Posting Buffer"; UseDate: Date; InvDefLineNo: Integer; DeferralLineNo: Integer; SuppressCommit: Boolean)
    begin
    end;

    procedure RunOnPrepareLineOnAfterUpdateInvoicePostingBuffer(SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; var InvoicePostingBuffer: Record "Invoice Posting Buffer"; var TempInvoicePostingBuffer: Record "Invoice Posting Buffer" temporary)
    begin
        OnPrepareLineOnAfterUpdateInvoicePostingBuffer(SalesHeader, SalesLine, InvoicePostingBuffer, TempInvoicePostingBuffer);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPrepareLineOnAfterUpdateInvoicePostingBuffer(SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; var InvoicePostingBuffer: Record "Invoice Posting Buffer"; var TempInvoicePostingBuffer: Record "Invoice Posting Buffer" temporary)
    begin
    end;

    procedure RunOnPrepareLineOnBeforePrepareDeferralLine(SalesLine: Record "Sales Line"; InvoicePostingBuffer: Record "Invoice Posting Buffer"; UseDate: Date; InvDefLineNo: Integer; DeferralLineNo: Integer; SuppressCommit: Boolean; var DeferralAccount: Code[20]; var SalesAccount: Code[20])
    begin
        OnPrepareLineOnBeforePrepareDeferralLine(SalesLine, InvoicePostingBuffer, UseDate, InvDefLineNo, DeferralLineNo, SuppressCommit, DeferralAccount, SalesAccount);
    end;

#if not CLEAN25
    [Obsolete('Use the method RunOnPrepareLineOnBeforePrepareDeferralLine(SalesLine: Record "Sales Line"; InvoicePostingBuffer: Record "Invoice Posting Buffer"; UseDate: Date; InvDefLineNo: Integer; DeferralLineNo: Integer; SuppressCommit: Boolean; var DeferralAccount: Code[20]; var SalesAccount: Code[20]) instead', '25.0')]
    procedure RunOnPrepareLineOnBeforePrepareDeferralLine(SalesLine: Record "Sales Line"; InvoicePostingBuffer: Record "Invoice Posting Buffer"; UseDate: Date; InvDefLineNo: Integer; DeferralLineNo: Integer; SuppressCommit: Boolean)
    var
        DeferralAccount, SalesAccount : Code[20];
    begin
        OnPrepareLineOnBeforePrepareDeferralLine(SalesLine, InvoicePostingBuffer, UseDate, InvDefLineNo, DeferralLineNo, SuppressCommit, DeferralAccount, SalesAccount);
    end;
#endif
    [IntegrationEvent(false, false)]
    local procedure OnPrepareLineOnBeforePrepareDeferralLine(SalesLine: Record "Sales Line"; InvoicePostingBuffer: Record "Invoice Posting Buffer"; UseDate: Date; InvDefLineNo: Integer; DeferralLineNo: Integer; SuppressCommit: Boolean; var DeferralAccount: Code[20]; var SalesAccount: Code[20])
    begin
    end;

    procedure RunOnPrepareLineOnBeforePrepareSales(SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; var GeneralPostingSetup: Record "General Posting Setup")
    begin
        OnPrepareLineOnBeforePrepareSales(SalesHeader, SalesLine, GeneralPostingSetup);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPrepareLineOnBeforePrepareSales(SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; var GeneralPostingSetup: Record "General Posting Setup")
    begin
    end;

    procedure RunOnPrepareLineOnBeforeSetInvoiceDiscAccount(SalesLine: Record "Sales Line"; GenPostingSetup: Record "General Posting Setup"; var InvDiscAccount: Code[20]; var IsHandled: Boolean)
    begin
        OnPrepareLineOnBeforeSetInvoiceDiscAccount(SalesLine, GenPostingSetup, InvDiscAccount, IsHandled);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPrepareLineOnBeforeSetInvoiceDiscAccount(SalesLine: Record "Sales Line"; GenPostingSetup: Record "General Posting Setup"; var InvDiscAccount: Code[20]; var IsHandled: Boolean)
    begin
    end;

    procedure RunOnPrepareLineOnBeforeSetLineDiscAccount(SalesLine: Record "Sales Line"; GenPostingSetup: Record "General Posting Setup"; var InvDiscAccount: Code[20]; var IsHandled: Boolean)
    begin
        OnPrepareLineOnBeforeSetLineDiscAccount(SalesLine, GenPostingSetup, InvDiscAccount, IsHandled);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPrepareLineOnBeforeSetLineDiscAccount(SalesLine: Record "Sales Line"; GenPostingSetup: Record "General Posting Setup"; var InvDiscAccount: Code[20]; var IsHandled: Boolean)
    begin
    end;

    procedure RunOnPrepareLineOnBeforeInvoicePostingBufferSetAccount(var InvoicePostingBuffer: Record "Invoice Posting Buffer"; var SalesLine: Record "Sales Line"; var GeneralPostingSetup: Record "General Posting Setup"; var InvDiscAccount: Code[20]; var TotalVAT: Decimal; var TotalVATACY: Decimal; var TotalAmount: Decimal; var TotalAmountACY: Decimal; var IsHandled: Boolean)
    begin
        OnPrepareLineOnBeforeInvoicePostingBufferSetAccount(InvoicePostingBuffer, SalesLine, GeneralPostingSetup, InvDiscAccount, TotalVAT, TotalVATACY, TotalAmount, TotalAmountACY, IsHandled);
    end;

    [IntegrationEvent(false, false)]
    procedure OnPrepareLineOnBeforeInvoicePostingBufferSetAccount(var InvoicePostingBuffer: Record "Invoice Posting Buffer"; var SalesLine: Record "Sales Line"; var GeneralPostingSetup: Record "General Posting Setup"; var InvDiscAccount: Code[20]; var TotalVAT: Decimal; var TotalVATACY: Decimal; var TotalAmount: Decimal; var TotalAmountACY: Decimal; var IsHandled: Boolean)
    begin
    end;

    // Prepare Deferral Line

    procedure RunOnPrepareDeferralLineOnBeforePrepareInitialAmounts(var DeferralPostBuffer: Record "Deferral Posting Buffer"; SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; AmountLCY: Decimal; AmountACY: Decimal; RemainAmtToDefer: Decimal; RemainAmtToDeferACY: Decimal; DeferralAccount: Code[20]; SalesAccount: Code[20])
    begin
        OnPrepareDeferralLineOnBeforePrepareInitialAmounts(DeferralPostBuffer, SalesHeader, SalesLine, AmountLCY, AmountACY, RemainAmtToDefer, RemainAmtToDeferACY, DeferralAccount, SalesAccount);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPrepareDeferralLineOnBeforePrepareInitialAmounts(var DeferralPostBuffer: Record "Deferral Posting Buffer"; SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; AmountLCY: Decimal; AmountACY: Decimal; RemainAmtToDefer: Decimal; RemainAmtToDeferACY: Decimal; DeferralAccount: Code[20]; SalesAccount: Code[20])
    begin
    end;

    // Calc Deferral Amount

    procedure RunOnCalcDeferralAmountsOnBeforeTempDeferralHeaderInsert(var TempDeferralHeader: Record "Deferral Header" temporary; DeferralHeader: Record "Deferral Header"; SalesLine: Record "Sales Line")
    begin
        OnCalcDeferralAmountsOnBeforeTempDeferralHeaderInsert(TempDeferralHeader, DeferralHeader, SalesLine);
    end;

    // Invoice Posting Buffer

    [IntegrationEvent(false, false)]
    local procedure OnCalcDeferralAmountsOnBeforeTempDeferralHeaderInsert(var TempDeferralHeader: Record "Deferral Header" temporary; DeferralHeader: Record "Deferral Header"; SalesLine: Record "Sales Line")
    begin
    end;

    procedure RunOnAfterPrepareInvoicePostingBuffer(var SalesLine: Record "Sales Line"; var InvoicePostingBuffer: Record "Invoice Posting Buffer")
    begin
        OnAfterPrepareInvoicePostingBuffer(SalesLine, InvoicePostingBuffer);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPrepareInvoicePostingBuffer(var SalesLine: Record "Sales Line"; var InvoicePostingBuffer: Record "Invoice Posting Buffer")
    begin
    end;

    procedure RunOnBeforePrepareInvoicePostingBuffer(var SalesLine: Record "Sales Line"; var InvoicePostingBuffer: Record "Invoice Posting Buffer")
    begin
        OnBeforePrepareInvoicePostingBuffer(SalesLine, InvoicePostingBuffer);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePrepareInvoicePostingBuffer(var SalesLine: Record "Sales Line"; var InvoicePostingBuffer: Record "Invoice Posting Buffer")
    begin
    end;

    procedure RunOnPrepareDeferralLineOnBeforeDeferralPostingBufferUpdate(var DeferralPostBuffer: Record "Deferral Posting Buffer"; var TempDeferralLine: Record "Deferral Line"; var AmountToDefer: Decimal)
    begin
        OnPrepareDeferralLineOnBeforeDeferralPostingBufferUpdate(DeferralPostBuffer, TempDeferralLine, AmountToDefer);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPrepareDeferralLineOnBeforeDeferralPostingBufferUpdate(var DeferralPostBuffer: Record "Deferral Posting Buffer"; var TempDeferralLine: Record "Deferral Line"; var AmountToDefer: Decimal)
    begin
    end;

    procedure RunOnAfterPrepareDeferralLine(var DeferralPostBuffer: Record "Deferral Posting Buffer"; var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; GenJnlLineDocNo: Code[20]; DeferralAccount: Code[20]; SalesAccount: Code[20]; InvDefLineNo: Integer; DeferralLineNo: Integer; var AmountToDefer: Decimal)
    begin
        OnAfterPrepareDeferralLine(DeferralPostBuffer, SalesHeader, SalesLine, GenJnlLineDocNo, DeferralAccount, SalesAccount, InvDefLineNo, DeferralLineNo, AmountToDefer);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPrepareDeferralLine(var DeferralPostBuffer: Record "Deferral Posting Buffer"; var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; GenJnlLineDocNo: Code[20]; DeferralAccount: Code[20]; SalesAccount: Code[20]; InvDefLineNo: Integer; DeferralLineNo: Integer; var AmountToDefer: Decimal)
    begin
    end;

    internal procedure RunOnBeforeUpdateInvoicePostingBuffer(var TempInvoicePostingBuffer: Record "Invoice Posting Buffer" temporary; InvoicePostingBuffer: Record "Invoice Posting Buffer"; ForceGLAccountType: Boolean; var InvDefLineNo: Integer; var DeferralLineNo: Integer; var FALineNo: Integer; SalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
        OnBeforeUpdateInvoicePostingBuffer(TempInvoicePostingBuffer, InvoicePostingBuffer, ForceGLAccountType, InvDefLineNo, DeferralLineNo, FALineNo, SalesLine, IsHandled);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateInvoicePostingBuffer(var TempInvoicePostingBuffer: Record "Invoice Posting Buffer" temporary; InvoicePostingBuffer: Record "Invoice Posting Buffer"; ForceGLAccountType: Boolean; var InvDefLineNo: Integer; var DeferralLineNo: Integer; var FALineNo: Integer; SalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    internal procedure RunOnPostLinesOnAfterPostJobSalesLines(var SalesHeader: Record "Sales Header"; var TempInvoicePostingBuffer: Record "Invoice Posting Buffer" temporary; var TotalSalesLine: Record "Sales Line"; var TotalSalesLineLCY: Record "Sales Line"; var GLEntryNo: Integer; var InvoicePostingParameters: Record "Invoice Posting Parameters")
    begin
        OnPostLinesOnAfterPostJobSalesLines(SalesHeader, TempInvoicePostingBuffer, TotalSalesLine, TotalSalesLineLCY, GLEntryNo, InvoicePostingParameters);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostLinesOnAfterPostJobSalesLines(var SalesHeader: Record "Sales Header"; var TempInvoicePostingBuffer: Record "Invoice Posting Buffer" temporary; var TotalSalesLine: Record "Sales Line"; var TotalSalesLineLCY: Record "Sales Line"; var GLEntryNo: Integer; var InvoicePostingParameters: Record "Invoice Posting Parameters")
    begin
    end;
}
