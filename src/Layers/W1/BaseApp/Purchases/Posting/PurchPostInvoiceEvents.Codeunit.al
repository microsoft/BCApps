// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Posting;

using Microsoft.Finance.Currency;
using Microsoft.Finance.Deferral;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Posting;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Payables;

codeunit 826 "Purch. Post Invoice Events"
{
    // OnAfter events

    procedure RunOnAfterCalcInvoiceDiscountPosting(PurchHeader: Record "Purchase Header"; PurchLine: Record "Purchase Line"; PurchLineACY: Record "Purchase Line"; var InvoicePostingBuffer: Record "Invoice Posting Buffer")
    begin
        OnAfterCalcInvoiceDiscountPosting(PurchHeader, PurchLine, PurchLineACY, InvoicePostingBuffer);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcInvoiceDiscountPosting(PurchHeader: Record "Purchase Header"; PurchLine: Record "Purchase Line"; PurchLineACY: Record "Purchase Line"; var InvoicePostingBuffer: Record "Invoice Posting Buffer")
    begin
    end;

    procedure RunOnAfterCalcLineDiscountPosting(PurchHeader: Record "Purchase Header"; PurchLine: Record "Purchase Line"; PurchLineACY: Record "Purchase Line"; var InvoicePostingBuffer: Record "Invoice Posting Buffer")
    begin
        OnAfterCalcLineDiscountPosting(PurchHeader, PurchLine, PurchLineACY, InvoicePostingBuffer);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcLineDiscountPosting(PurchHeader: Record "Purchase Header"; PurchLine: Record "Purchase Line"; PurchLineACY: Record "Purchase Line"; var InvoicePostingBuffer: Record "Invoice Posting Buffer")
    begin
    end;

    procedure RunOnBeforeCreatePostedDeferralSchedule(PurchLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
        OnBeforeCreatePostedDeferralSchedule(PurchLine, IsHandled);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreatePostedDeferralSchedule(var PurchLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    procedure RunOnAfterCreatePostedDeferralSchedule(PurchLine: Record "Purchase Line"; var PostedDeferralHeader: Record "Posted Deferral Header")
    begin
        OnAfterCreatePostedDeferralSchedule(PurchLine, PostedDeferralHeader);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreatePostedDeferralSchedule(var PurchLine: Record "Purchase Line"; var PostedDeferralHeader: Record "Posted Deferral Header")
    begin
    end;

    procedure RunOnAfterGetPurchAccount(PurchLine: Record "Purchase Line"; GenPostingSetup: Record "General Posting Setup"; var PurchAccountNo: Code[20])
    begin
        OnAfterGetPurchAccount(PurchLine, GenPostingSetup, PurchAccountNo);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetPurchAccount(PurchLine: Record "Purchase Line"; GenPostingSetup: Record "General Posting Setup"; var SalesAccountNo: Code[20])
    begin
    end;

    procedure RunOnAfterInitTotalAmounts(PurchLine: Record "Purchase Line"; PurchLineACY: Record "Purchase Line"; var TotalVAT: Decimal; var TotalVATACY: Decimal; var TotalAmount: Decimal; var TotalAmountACY: Decimal; var TotalVATBase: Decimal; var TotalVATBaseACY: Decimal)
    begin
        OnAfterInitTotalAmounts(PurchLine, PurchLineACY, TotalVAT, TotalVATACY, TotalAmount, TotalAmountACY, TotalVATBase, TotalVATBaseACY);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitTotalAmounts(PurchLine: Record "Purchase Line"; PurchLineACY: Record "Purchase Line"; var TotalVAT: Decimal; var TotalVATACY: Decimal; var TotalAmount: Decimal; var TotalAmountACY: Decimal; var TotalVATBase: Decimal; var TotalVATBaseACY: Decimal)
    begin
    end;

    procedure RunOnAfterPrepareGenJnlLine(var GenJnlLine: Record "Gen. Journal Line"; PurchHeader: Record "Purchase Header"; InvoicePostingBuffer: Record "Invoice Posting Buffer")
    begin
        OnAfterPrepareGenJnlLine(GenJnlLine, PurchHeader, InvoicePostingBuffer);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPrepareGenJnlLine(var GenJnlLine: Record "Gen. Journal Line"; PurchHeader: Record "Purchase Header"; InvoicePostingBuffer: Record "Invoice Posting Buffer")
    begin
    end;

    procedure RunOnAfterSetApplyToDocNo(var GenJournalLine: Record "Gen. Journal Line"; PurchaseHeader: Record "Purchase Header")
    begin
        OnAfterSetApplyToDocNo(GenJournalLine, PurchaseHeader);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetApplyToDocNo(var GenJournalLine: Record "Gen. Journal Line"; PurchaseHeader: Record "Purchase Header")
    begin
    end;

    procedure RunOnAfterSetJobLineFilters(var JobPurchLine: Record "Purchase Line"; InvoicePostingBuffer: Record "Invoice Posting Buffer")
    begin
        OnAfterSetJobLineFilters(JobPurchLine, InvoicePostingBuffer);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetJobLineFilters(var JobPurchLine: Record "Purchase Line"; InvoicePostingBuffer: Record "Invoice Posting Buffer")
    begin
    end;

    // OnBefore events

    procedure RunOnBeforeCalcInvoiceDiscountPosting(PurchHeader: Record "Purchase Header"; PurchLine: Record "Purchase Line"; PurchLineACY: Record "Purchase Line"; var InvoicePostingBuffer: Record "Invoice Posting Buffer"; var IsHandled: Boolean)
    begin
        OnBeforeCalcInvoiceDiscountPosting(PurchHeader, PurchLine, PurchLineACY, InvoicePostingBuffer, IsHandled);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcInvoiceDiscountPosting(PurchHeader: Record "Purchase Header"; PurchLine: Record "Purchase Line"; PurchLineACY: Record "Purchase Line"; var InvoicePostingBuffer: Record "Invoice Posting Buffer"; var IsHandled: Boolean)
    begin
    end;

    procedure RunOnBeforeCalcLineDiscountPosting(PurchHeader: Record "Purchase Header"; PurchLine: Record "Purchase Line"; PurchLineACY: Record "Purchase Line"; var InvoicePostingBuffer: Record "Invoice Posting Buffer"; var IsHandled: Boolean)
    begin
        OnBeforeCalcLineDiscountPosting(PurchHeader, PurchLine, PurchLineACY, InvoicePostingBuffer, IsHandled);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcLineDiscountPosting(PurchHeader: Record "Purchase Header"; PurchLine: Record "Purchase Line"; PurchLineACY: Record "Purchase Line"; var InvoicePostingBuffer: Record "Invoice Posting Buffer"; var IsHandled: Boolean)
    begin
    end;

    procedure RunOnBeforeInitGenJnlLine(var GenJnlLine: Record "Gen. Journal Line"; PurchHeader: Record "Purchase Header"; InvoicePostingBuffer: Record "Invoice Posting Buffer"; var IsHandled: Boolean)
    begin
        OnBeforeInitGenJnlLine(GenJnlLine, PurchHeader, InvoicePostingBuffer, IsHandled);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitGenJnlLine(var GenJnlLine: Record "Gen. Journal Line"; PurchHeader: Record "Purchase Header"; InvoicePostingBuffer: Record "Invoice Posting Buffer"; var IsHandled: Boolean)
    begin
    end;

    procedure RunOnBeforeInitGenJnlLineAmountFieldsFromTotalLines(var GenJnlLine: Record "Gen. Journal Line"; var PurchHeader: Record "Purchase Header"; var TotalPurchLine: Record "Purchase Line"; var TotalPurchLineLCY: Record "Purchase Line"; var IsHandled: Boolean)
    begin
        OnBeforeInitGenJnlLineAmountFieldsFromTotalLines(GenJnlLine, PurchHeader, TotalPurchLine, TotalPurchLineLCY, IsHandled);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitGenJnlLineAmountFieldsFromTotalLines(var GenJnlLine: Record "Gen. Journal Line"; var PurchHeader: Record "Purchase Header"; var TotalPurchLine: Record "Purchase Line"; var TotalPurchLineLCY: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    procedure RunOnBeforeSetAmountsForBalancingEntry(var VendLedgEntry: Record "Vendor Ledger Entry"; var GenJnlLine: Record "Gen. Journal Line"; var TotalPurchLine: Record "Purchase Line"; var TotalPurchLineLCY: Record "Purchase Line"; var IsHandled: Boolean)
    begin
        OnBeforeSetAmountsForBalancingEntry(VendLedgEntry, GenJnlLine, TotalPurchLine, TotalPurchLineLCY, IsHandled);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetAmountsForBalancingEntry(var VendLedgEntry: Record "Vendor Ledger Entry"; var GenJnlLine: Record "Gen. Journal Line"; var TotalPurchLine: Record "Purchase Line"; var TotalPurchLineLCY: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    procedure RunOnBeforePostLines(PurchHeader: Record "Purchase Header"; var TempInvoicePostingBuffer: Record "Invoice Posting Buffer" temporary)
    begin
        OnBeforePostLines(PurchHeader, TempInvoicePostingBuffer);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostLines(PurchHeader: Record "Purchase Header"; var TempInvoicePostingBuffer: Record "Invoice Posting Buffer" temporary)
    begin
    end;

    procedure RunOnBeforePostLedgerEntry(var PurchHeader: Record "Purchase Header"; var TotalPurchLine: Record "Purchase Line"; var TotalPurchLineLCY: Record "Purchase Line"; PreviewMode: Boolean; SuppressCommit: Boolean; InvoicePostingParameters: Record "Invoice Posting Parameters"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; var IsHandled: Boolean)
    begin
        OnBeforePostLedgerEntry(PurchHeader, TotalPurchLine, TotalPurchLineLCY, SuppressCommit, PreviewMode, InvoicePostingParameters, GenJnlPostLine, IsHandled);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostLedgerEntry(var PurchHeader: Record "Purchase Header"; var TotalPurchLine: Record "Purchase Line"; var TotalPurchLineLCY: Record "Purchase Line"; PreviewMode: Boolean; SuppressCommit: Boolean; InvoicePostingParameters: Record "Invoice Posting Parameters"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; var IsHandled: Boolean)
    begin
    end;

    procedure RunOnBeforePrepareLine(PurchHeader: Record "Purchase Header"; PurchLine: Record "Purchase Line"; PurchLineACY: Record "Purchase Line"; var IsHandled: Boolean)
    begin
        OnBeforePrepareLine(PurchHeader, PurchLine, PurchLineACY, IsHandled);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePrepareLine(PurchHeader: Record "Purchase Header"; PurchLine: Record "Purchase Line"; PurchLineACY: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    procedure RunOnBeforeTempDeferralLineInsert(var TempDeferralLine: Record "Deferral Line" temporary; DeferralLine: Record "Deferral Line"; PurchLine: Record "Purchase Line"; var DeferralCount: Integer; var TotalDeferralCount: Integer)
    begin
        OnBeforeTempDeferralLineInsert(TempDeferralLine, DeferralLine, PurchLine, DeferralCount, TotalDeferralCount);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTempDeferralLineInsert(var TempDeferralLine: Record "Deferral Line" temporary; DeferralLine: Record "Deferral Line"; PurchLine: Record "Purchase Line"; var DeferralCount: Integer; var TotalDeferralCount: Integer)
    begin
    end;

#if not CLEAN27
    [Obsolete('Use the procedure with AccountNo parameter instead.', '27.0')]
    procedure RunOnBeforePrepareLineFADiscount(var InvoicePostingBuffer: Record "Invoice Posting Buffer"; GenPostingSetup: Record "General Posting Setup"; var IsHandled: Boolean)
    begin
        RunOnBeforePrepareLineFADiscount(InvoicePostingBuffer, GenPostingSetup, '', IsHandled);
    end;
#endif

    procedure RunOnBeforePrepareLineFADiscount(var InvoicePostingBuffer: Record "Invoice Posting Buffer"; GenPostingSetup: Record "General Posting Setup"; AccountNo: Code[20]; var IsHandled: Boolean)
    begin
        OnBeforePrepareLineFADiscount(InvoicePostingBuffer, GenPostingSetup, AccountNo, IsHandled);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePrepareLineFADiscount(var InvoicePostingBuffer: Record "Invoice Posting Buffer"; GenPostingSetup: Record "General Posting Setup"; AccountNo: Code[20]; var IsHandled: Boolean)
    begin
    end;

    procedure RunOnBeforeCalculateVATAmounts(PurchHeader: Record "Purchase Header"; var InvoicePostingBuffer: Record "Invoice Posting Buffer"; var IsHandled: Boolean)
    begin
        OnBeforeCalculateVATAmounts(PurchHeader, InvoicePostingBuffer, IsHandled);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalculateVATAmounts(PurchHeader: Record "Purchase Header"; var InvoicePostingBuffer: Record "Invoice Posting Buffer"; var IsHandled: Boolean)
    begin
    end;

    procedure RunOnCalculateVATAmountsOnReverseChargeVATOnBeforeModify(PurchHeader: Record "Purchase Header"; Currency: Record Currency; VATPostingSetup: Record "VAT Posting Setup"; var InvoicePostingBuffer: Record "Invoice Posting Buffer")
    begin
        OnCalculateVATAmountsOnReverseChargeVATOnBeforeModify(PurchHeader, Currency, VATPostingSetup, InvoicePostingBuffer);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalculateVATAmountsOnReverseChargeVATOnBeforeModify(PurchHeader: Record "Purchase Header"; Currency: Record Currency; VATPostingSetup: Record "VAT Posting Setup"; var InvoicePostingBuffer: Record "Invoice Posting Buffer")
    begin
    end;

    procedure RunOnCalculateVATAmountInBufferOnBeforeTempInvoicePostingBufferAssign(var VATAmount: Decimal; var VATAmountACY: Decimal; var TempInvoicePostingBuffer: Record "Invoice Posting Buffer" temporary)
    begin
        OnCalculateVATAmountInBufferOnBeforeTempInvoicePostingBufferAssign(VATAmount, VATAmountACY, TempInvoicePostingBuffer);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalculateVATAmountInBufferOnBeforeTempInvoicePostingBufferAssign(var VATAmount: Decimal; var VATAmountACY: Decimal; var TempInvoicePostingBuffer: Record "Invoice Posting Buffer" temporary)
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

#if not CLEAN26
    [Obsolete('Replaced by procedure that also receives PurchHeader and TempInvoicePostingBuffer', '26.0')]
    procedure RunOnCalculateVATAmountsOnAfterGetReverseChargeVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup")
    var
        PurchHeader: Record "Purchase Header";
        TempInvoicePostingBuffer: Record "Invoice Posting Buffer" temporary;
    begin
        OnCalculateVATAmountsOnAfterGetReverseChargeVATPostingSetup(VATPostingSetup, PurchHeader, TempInvoicePostingBuffer);
    end;

    [Obsolete('Replaced by procedure that also receives TempInvoicePostingBuffer', '26.0')]
    procedure RunOnCalculateVATAmountsOnAfterGetReverseChargeVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup"; PurchHeader: Record "Purchase Header")
    var
        TempInvoicePostingBuffer: Record "Invoice Posting Buffer" temporary;
    begin
        OnCalculateVATAmountsOnAfterGetReverseChargeVATPostingSetup(VATPostingSetup, PurchHeader, TempInvoicePostingBuffer);
    end;
#endif

    procedure RunOnCalculateVATAmountsOnAfterGetReverseChargeVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup"; PurchHeader: Record "Purchase Header"; var TempInvoicePostingBuffer: Record "Invoice Posting Buffer" temporary)
    begin
        OnCalculateVATAmountsOnAfterGetReverseChargeVATPostingSetup(VATPostingSetup, PurchHeader, TempInvoicePostingBuffer);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalculateVATAmountsOnAfterGetReverseChargeVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup"; PurchHeader: Record "Purchase Header"; var TempInvoicePostingBuffer: Record "Invoice Posting Buffer" temporary)
    begin
    end;

    // Post Balancing Entry

    procedure RunOnPostBalancingEntryOnBeforeFindVendLedgEntry(PurchHeader: Record "Purchase Header"; PurchLine: Record "Purchase Line"; InvoicePostingParameters: Record "Invoice Posting Parameters"; var VendLedgerEntry: Record "Vendor Ledger Entry"; var EntryFound: Boolean; var IsHandled: Boolean)
    begin
        OnPostBalancingEntryOnBeforeFindVendLedgEntry(PurchHeader, PurchLine, InvoicePostingParameters, VendLedgerEntry, EntryFound, IsHandled);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostBalancingEntryOnBeforeFindVendLedgEntry(PurchHeader: Record "Purchase Header"; PurchLine: Record "Purchase Line"; InvoicePostingParameters: Record "Invoice Posting Parameters"; var VendLedgerEntry: Record "Vendor Ledger Entry"; var EntryFound: Boolean; var IsHandled: Boolean)
    begin
    end;

    procedure RunOnPostBalancingEntryOnAfterInitNewLine(var GenJnlLine: Record "Gen. Journal Line"; var PurchHeader: Record "Purchase Header")
    begin
        OnPostBalancingEntryOnAfterInitNewLine(GenJnlLine, PurchHeader);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostBalancingEntryOnAfterInitNewLine(var GenJnlLine: Record "Gen. Journal Line"; var PurchHeader: Record "Purchase Header")
    begin
    end;

    procedure RunOnPostBalancingEntryOnAfterGenJnlPostLine(var GenJnlLine: Record "Gen. Journal Line"; var PurchHeader: Record "Purchase Header"; var TotalPurchLine: Record "Purchase Line"; var TotalPurchLineLCY: Record "Purchase Line"; PreviewMode: Boolean; SuppressCommit: Boolean; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    begin
        OnPostBalancingEntryOnAfterGenJnlPostLine(GenJnlLine, PurchHeader, TotalPurchLine, TotalPurchLineLCY, PreviewMode, SuppressCommit, GenJnlPostLine);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostBalancingEntryOnAfterGenJnlPostLine(var GenJnlLine: Record "Gen. Journal Line"; var PurchHeader: Record "Purchase Header"; var TotalPurchLine: Record "Purchase Line"; var TotalPurchLineLCY: Record "Purchase Line"; PreviewMode: Boolean; SuppressCommit: Boolean; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    begin
    end;

    procedure RunOnPostBalancingEntryOnBeforeGenJnlPostLine(var GenJnlLine: Record "Gen. Journal Line"; var PurchHeader: Record "Purchase Header"; var TotalPurchLine: Record "Purchase Line"; var TotalPurchLineLCY: Record "Purchase Line"; PreviewMode: Boolean; SuppressCommit: Boolean; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    begin
        OnPostBalancingEntryOnBeforeGenJnlPostLine(GenJnlLine, PurchHeader, TotalPurchLine, TotalPurchLineLCY, PreviewMode, SuppressCommit, GenJnlPostLine);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostBalancingEntryOnBeforeGenJnlPostLine(var GenJnlLine: Record "Gen. Journal Line"; var PurchHeader: Record "Purchase Header"; var TotalPurchLine: Record "Purchase Line"; var TotalPurchLineLCY: Record "Purchase Line"; PreviewMode: Boolean; SuppressCommit: Boolean; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    begin
    end;

    procedure RunOnPostBalancingEntryOnAfterFindVendLedgEntry(var VendLedgEntry: Record "Vendor Ledger Entry")
    begin
        OnPostBalancingEntryOnAfterFindVendLedgEntry(VendLedgEntry);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostBalancingEntryOnAfterFindVendLedgEntry(var VendLedgEntry: Record "Vendor Ledger Entry")
    begin
    end;

    // Post Ledger Entry

    procedure RunOnPostLedgerEntryOnAfterGenJnlPostLine(var GenJnlLine: Record "Gen. Journal Line"; var PurchHeader: Record "Purchase Header"; var TotalPurchLine: Record "Purchase Line"; var TotalPurchLineLCY: Record "Purchase Line"; PreviewMode: Boolean; SuppressCommit: Boolean; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    begin
        OnPostLedgerEntryOnAfterGenJnlPostLine(GenJnlLine, PurchHeader, TotalPurchLine, TotalPurchLineLCY, PreviewMode, SuppressCommit, GenJnlPostLine);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostLedgerEntryOnAfterGenJnlPostLine(var GenJnlLine: Record "Gen. Journal Line"; var PurchHeader: Record "Purchase Header"; var TotalPurchLine: Record "Purchase Line"; var TotalPurchLineLCY: Record "Purchase Line"; PreviewMode: Boolean; SuppressCommit: Boolean; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    begin
    end;

    procedure RunOnPostLedgerEntryOnBeforeGenJnlPostLine(var GenJnlLine: Record "Gen. Journal Line"; var PurchHeader: Record "Purchase Header"; var TotalPurchLine: Record "Purchase Line"; var TotalPurchLineLCY: Record "Purchase Line"; PreviewMode: Boolean; SuppressCommit: Boolean; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    begin
        OnPostLedgerEntryOnBeforeGenJnlPostLine(GenJnlLine, PurchHeader, TotalPurchLine, TotalPurchLineLCY, PreviewMode, SuppressCommit, GenJnlPostLine);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostLedgerEntryOnBeforeGenJnlPostLine(var GenJnlLine: Record "Gen. Journal Line"; var PurchHeader: Record "Purchase Header"; var TotalPurchLine: Record "Purchase Line"; var TotalPurchLineLCY: Record "Purchase Line"; PreviewMode: Boolean; SuppressCommit: Boolean; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    begin
    end;

    // Prepare Line

    procedure RunOnPrepareLineOnAfterAssignAmounts(PurchLine: Record "Purchase Line"; PurchLineACY: Record "Purchase Line"; var TotalAmount: Decimal; var TotalAmountACY: Decimal)
    begin
        OnPrepareLineOnAfterAssignAmounts(PurchLine, PurchLineACY, TotalAmount, TotalAmountACY);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPrepareLineOnAfterAssignAmounts(PurchLine: Record "Purchase Line"; PurchLineACY: Record "Purchase Line"; var TotalAmount: Decimal; var TotalAmountACY: Decimal)
    begin
    end;

    procedure RunOnPrepareLineOnAfterSetAmounts(var InvoicePostingBuffer: Record "Invoice Posting Buffer"; PurchLine: Record "Purchase Line")
    begin
        OnPrepareLineOnAfterSetAmounts(InvoicePostingBuffer, PurchLine);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPrepareLineOnAfterSetAmounts(var InvoicePostingBuffer: Record "Invoice Posting Buffer"; PurchLine: Record "Purchase Line")
    begin
    end;

    procedure RunOnPrepareLineOnAfterFillInvoicePostingBuffer(var InvoicePostingBuffer: Record "Invoice Posting Buffer"; PurchLine: Record "Purchase Line"; var TempInvoicePostingBuffer: Record "Invoice Posting Buffer" temporary; var FALineNo: Integer; var InvDefLineNo: Integer; var DeferralLineNo: Integer; var IsHandled: Boolean)
    begin
        OnPrepareLineOnAfterFillInvoicePostingBuffer(InvoicePostingBuffer, PurchLine, TempInvoicePostingBuffer, FALineNo, InvDefLineNo, DeferralLineNo, IsHandled);
    end;

#if not CLEAN26
    [Obsolete('Replaced by procedure RunOnPrepareLineOnAfterFillInvoicePostingBuffer(var InvoicePostingBuffer: Record "Invoice Posting Buffer"; PurchLine: Record "Purchase Line"; var TempInvoicePostingBuffer: Record "Invoice Posting Buffer" temporary; var FALineNo: Integer; var InvDefLineNo: Integer; var DeferralLineNo: Integer; var IsHandled: Boolean)', '26.0')]
    procedure RunOnPrepareLineOnAfterFillInvoicePostingBuffer(var InvoicePostingBuffer: Record "Invoice Posting Buffer"; PurchLine: Record "Purchase Line")
    var
        TempInvoicePostingBuffer: Record "Invoice Posting Buffer" temporary;
        FALineNo: Integer;
        InvDefLineNo: Integer;
        DeferralLineNo: Integer;
        IsHandled: Boolean;
    begin
        OnPrepareLineOnAfterFillInvoicePostingBuffer(InvoicePostingBuffer, PurchLine, TempInvoicePostingBuffer, FALineNo, InvDefLineNo, DeferralLineNo, IsHandled);
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnPrepareLineOnAfterFillInvoicePostingBuffer(var InvoicePostingBuffer: Record "Invoice Posting Buffer"; PurchLine: Record "Purchase Line"; var TempInvoicePostingBuffer: Record "Invoice Posting Buffer" temporary; var FALineNo: Integer; var InvDefLineNo: Integer; var DeferralLineNo: Integer; var IsHandled: Boolean)
    begin
    end;

    procedure RunOnPrepareLineOnBeforeAdjustTotalAmounts(PurchLine: Record "Purchase Line"; var TotalAmount: Decimal; var TotalAmountACY: Decimal; UseDate: Date)
    begin
        OnPrepareLineOnBeforeAdjustTotalAmounts(PurchLine, TotalAmount, TotalAmountACY, UseDate);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPrepareLineOnBeforeAdjustTotalAmounts(PurchLine: Record "Purchase Line"; var TotalAmount: Decimal; var TotalAmountACY: Decimal; UseDate: Date)
    begin
    end;

    procedure RunOnPrepareLineOnBeforeSetAccount(PurchHeader: Record "Purchase Header"; PurchLine: Record "Purchase Line"; var PurchAccount: Code[20])
    begin
        OnPrepareLineOnBeforeSetAccount(PurchHeader, PurchLine, PurchAccount);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPrepareLineOnBeforeSetAccount(PurchHeader: Record "Purchase Header"; PurchLine: Record "Purchase Line"; var SalesAccount: Code[20])
    begin
    end;

    procedure RunOnPrepareLineOnBeforeSetAmounts(PurchLine: Record "Purchase Line"; PurchLineACY: Record "Purchase Line"; var InvoicePostingBuffer: Record "Invoice Posting Buffer"; var TotalVAT: Decimal; var TotalVATACY: Decimal; var TotalAmount: Decimal; var TotalAmountACY: Decimal; var TotalVATBase: Decimal; var TotalVATBaseACY: Decimal; var IsHandled: Boolean)
    begin
        OnPrepareLineOnBeforeSetAmounts(PurchLine, PurchLineACY, InvoicePostingBuffer, TotalVAT, TotalVATACY, TotalAmount, TotalAmountACY, TotalVATBase, TotalVATBaseACY, IsHandled);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPrepareLineOnBeforeSetAmounts(PurchLine: Record "Purchase Line"; PurchLineACY: Record "Purchase Line"; var InvoicePostingBuffer: Record "Invoice Posting Buffer"; var TotalVAT: Decimal; var TotalVATACY: Decimal; var TotalAmount: Decimal; var TotalAmountACY: Decimal; var TotalVATBase: Decimal; var TotalVATBaseACY: Decimal; var IsHandled: Boolean)
    begin
    end;

    procedure RunOnPrepareLineOnAfterSetInvoiceDiscAccount(PurchLine: Record "Purchase Line"; GenPostingSetup: Record "General Posting Setup"; var InvoicePostingBuffer: Record "Invoice Posting Buffer"; var TempInvoicePostingBuffer: Record "Invoice Posting Buffer" temporary)
    begin
        OnPrepareLineOnAfterSetInvoiceDiscAccount(PurchLine, GenPostingSetup, InvoicePostingBuffer, TempInvoicePostingBuffer);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPrepareLineOnAfterSetInvoiceDiscAccount(PurchLine: Record "Purchase Line"; GenPostingSetup: Record "General Posting Setup"; var InvoicePostingBuffer: Record "Invoice Posting Buffer"; var TempInvoicePostingBuffer: Record "Invoice Posting Buffer" temporary)
    begin
    end;

    procedure RunOnPrepareLineOnAfterSetLineDiscAccount(PurchLine: Record "Purchase Line"; GenPostingSetup: Record "General Posting Setup"; var InvoicePostingBuffer: Record "Invoice Posting Buffer"; var TempInvoicePostingBuffer: Record "Invoice Posting Buffer" temporary)
    begin
        OnPrepareLineOnAfterSetLineDiscAccount(PurchLine, GenPostingSetup, InvoicePostingBuffer, TempInvoicePostingBuffer);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPrepareLineOnAfterSetLineDiscAccount(PurchLine: Record "Purchase Line"; GenPostingSetup: Record "General Posting Setup"; var InvoicePostingBuffer: Record "Invoice Posting Buffer"; var TempInvoicePostingBuffer: Record "Invoice Posting Buffer" temporary)
    begin
    end;

    procedure RunOnPrepareLineOnBeforeCalcInvoiceDiscountPosting(var TempInvoicePostingBuffer: Record "Invoice Posting Buffer"; var InvoicePostingBuffer: Record "Invoice Posting Buffer"; PurchHeader: Record "Purchase Header"; PurchLine: Record "Purchase Line"; TotalVAT: Decimal; TotalVATACY: Decimal; TotalAmount: Decimal; TotalAmountACY: Decimal; var IsHandled: Boolean)
    begin
        OnPrepareLineOnBeforeCalcInvoiceDiscountPosting(TempInvoicePostingBuffer, InvoicePostingBuffer, PurchHeader, PurchLine, TotalVAT, TotalVATACY, TotalAmount, TotalAmountACY, IsHandled);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPrepareLineOnBeforeCalcInvoiceDiscountPosting(var TempInvoicePostingBuffer: Record "Invoice Posting Buffer"; var InvoicePostingBuffer: Record "Invoice Posting Buffer"; PurchHeader: Record "Purchase Header"; PurchLine: Record "Purchase Line"; TotalVAT: Decimal; TotalVATACY: Decimal; TotalAmount: Decimal; TotalAmountACY: Decimal; var IsHandled: Boolean)
    begin
    end;

    procedure RunOnPrepareLineOnBeforeCalcLineDiscountPosting(var TempInvoicePostingBuffer: Record "Invoice Posting Buffer"; var InvoicePostingBuffer: Record "Invoice Posting Buffer"; PurchHeader: Record "Purchase Header"; PurchLine: Record "Purchase Line"; TotalVAT: Decimal; TotalVATACY: Decimal; TotalAmount: Decimal; TotalAmountACY: Decimal; var IsHandled: Boolean)
    begin
        OnPrepareLineOnBeforeCalcLineDiscountPosting(TempInvoicePostingBuffer, InvoicePostingBuffer, PurchHeader, PurchLine, TotalVAT, TotalVATACY, TotalAmount, TotalAmountACY, IsHandled);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPrepareLineOnBeforeCalcLineDiscountPosting(var TempInvoicePostingBuffer: Record "Invoice Posting Buffer"; var InvoicePostingBuffer: Record "Invoice Posting Buffer"; PurchHeader: Record "Purchase Header"; PurchLine: Record "Purchase Line"; TotalVAT: Decimal; TotalVATACY: Decimal; TotalAmount: Decimal; TotalAmountACY: Decimal; var IsHandled: Boolean)
    begin
    end;

    procedure RunOnPostLinesOnAfterGenJnlLinePost(var GenJnlLine: Record "Gen. Journal Line"; PurchHeader: Record "Purchase Header"; TempInvoicePostingBuffer: Record "Invoice Posting Buffer"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; PreviewMode: Boolean; SuppressCommit: Boolean; GLEntryNo: Integer)
    begin
        OnPostLinesOnAfterGenJnlLinePost(GenJnlLine, PurchHeader, TempInvoicePostingBuffer, GenJnlPostLine, PreviewMode, SuppressCommit, GLEntryNo);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostLinesOnAfterGenJnlLinePost(var GenJnlLine: Record "Gen. Journal Line"; PurchHeader: Record "Purchase Header"; TempInvoicePostingBuffer: Record "Invoice Posting Buffer"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; PreviewMode: Boolean; SuppressCommit: Boolean; GLEntryNo: Integer)
    begin
    end;

    procedure RunOnPostLinesOnBeforeGenJnlLinePost(var GenJnlLine: Record "Gen. Journal Line"; PurchHeader: Record "Purchase Header"; TempInvoicePostingBuffer: Record "Invoice Posting Buffer"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; PreviewMode: Boolean; SuppressCommit: Boolean)
    begin
        OnPostLinesOnBeforeGenJnlLinePost(GenJnlLine, PurchHeader, TempInvoicePostingBuffer, GenJnlPostLine, PreviewMode, SuppressCommit);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostLinesOnBeforeGenJnlLinePost(var GenJnlLine: Record "Gen. Journal Line"; PurchHeader: Record "Purchase Header"; TempInvoicePostingBuffer: Record "Invoice Posting Buffer"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; PreviewMode: Boolean; SuppressCommit: Boolean)
    begin
    end;

    procedure RunOnPrepareGenJnlLineOnAfterCopyToGenJnlLine(var GenJnlLine: Record "Gen. Journal Line"; PurchHeader: Record "Purchase Header"; InvoicePostingBuffer: Record "Invoice Posting Buffer")
    begin
        OnPrepareGenJnlLineOnAfterCopyToGenJnlLine(GenJnlLine, PurchHeader, InvoicePostingBuffer);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPrepareGenJnlLineOnAfterCopyToGenJnlLine(var GenJnlLine: Record "Gen. Journal Line"; PurchHeader: Record "Purchase Header"; InvoicePostingBuffer: Record "Invoice Posting Buffer")
    begin
    end;

    procedure RunOnPrepareLineOnAfterSetInvoiceDiscountPosting(PurchHeader: Record "Purchase Header"; PurchLine: Record "Purchase Line"; var InvoiceDiscountPosting: Boolean)
    begin
        OnPrepareLineOnAfterSetInvoiceDiscountPosting(PurchHeader, PurchLine, InvoiceDiscountPosting);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPrepareLineOnAfterSetInvoiceDiscountPosting(PurchHeader: Record "Purchase Header"; PurchLine: Record "Purchase Line"; var InvoiceDiscountPosting: Boolean)
    begin
    end;

    procedure RunOnPrepareLineOnAfterSetLineDiscountPosting(PurchHeader: Record "Purchase Header"; PurchLine: Record "Purchase Line"; var LineDiscountPosting: Boolean)
    begin
        OnPrepareLineOnAfterSetLineDiscountPosting(PurchHeader, PurchLine, LineDiscountPosting);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPrepareLineOnAfterSetLineDiscountPosting(PurchHeader: Record "Purchase Header"; PurchLine: Record "Purchase Line"; var LineDiscountPosting: Boolean)
    begin
    end;

    procedure RunOnPrepareLineOnAfterPrepareDeferralLine(PurchLine: Record "Purchase Line"; InvoicePostingBuffer: Record "Invoice Posting Buffer"; UseDate: Date; InvDefLineNo: Integer; DeferralLineNo: Integer; SuppressCommit: Boolean)
    begin
        OnPrepareLineOnAfterPrepareDeferralLine(PurchLine, InvoicePostingBuffer, UseDate, InvDefLineNo, DeferralLineNo, SuppressCommit);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPrepareLineOnAfterPrepareDeferralLine(PurchLine: Record "Purchase Line"; InvoicePostingBuffer: Record "Invoice Posting Buffer"; UseDate: Date; InvDefLineNo: Integer; DeferralLineNo: Integer; SuppressCommit: Boolean)
    begin
    end;

    procedure RunOnPrepareLineOnAfterUpdateInvoicePostingBuffer(PurchHeader: Record "Purchase Header"; PurchLine: Record "Purchase Line"; InvoicePostingBuffer: Record "Invoice Posting Buffer"; var TempInvoicePostingBuffer: Record "Invoice Posting Buffer" temporary)
    begin
        OnPrepareLineOnAfterUpdateInvoicePostingBuffer(PurchHeader, PurchLine, InvoicePostingBuffer, TempInvoicePostingBuffer);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPrepareLineOnAfterUpdateInvoicePostingBuffer(PurchHeader: Record "Purchase Header"; PurchLine: Record "Purchase Line"; var InvoicePostingBuffer: Record "Invoice Posting Buffer"; var TempInvoicePostingBuffer: Record "Invoice Posting Buffer" temporary)
    begin
    end;

    procedure RunOnPrepareLineOnBeforePrepareDeferralLine(PurchLine: Record "Purchase Line"; InvoicePostingBuffer: Record "Invoice Posting Buffer"; UseDate: Date; InvDefLineNo: Integer; DeferralLineNo: Integer; SuppressCommit: Boolean)
    begin
        OnPrepareLineOnBeforePrepareDeferralLine(PurchLine, InvoicePostingBuffer, UseDate, InvDefLineNo, DeferralLineNo, SuppressCommit);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPrepareLineOnBeforePrepareDeferralLine(PurchLine: Record "Purchase Line"; InvoicePostingBuffer: Record "Invoice Posting Buffer"; UseDate: Date; InvDefLineNo: Integer; DeferralLineNo: Integer; SuppressCommit: Boolean)
    begin
    end;

    procedure RunOnPrepareLineOnBeforePreparePurchase(PurchHeader: Record "Purchase Header"; PurchLine: Record "Purchase Line"; var GeneralPostingSetup: Record "General Posting Setup")
    begin
        OnPrepareLineOnBeforePreparePurchase(PurchHeader, PurchLine, GeneralPostingSetup);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPrepareLineOnBeforePreparePurchase(PurchHeader: Record "Purchase Header"; PurchLine: Record "Purchase Line"; var GeneralPostingSetup: Record "General Posting Setup")
    begin
    end;

    procedure RunOnPrepareLineOnBeforeSetInvoiceDiscAccount(PurchLine: Record "Purchase Line"; GenPostingSetup: Record "General Posting Setup"; var InvDiscAccount: Code[20]; var IsHandled: Boolean)
    begin
        OnPrepareLineOnBeforeSetInvoiceDiscAccount(PurchLine, GenPostingSetup, InvDiscAccount, IsHandled);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPrepareLineOnBeforeSetInvoiceDiscAccount(PurchLine: Record "Purchase Line"; GenPostingSetup: Record "General Posting Setup"; var InvDiscAccount: Code[20]; var IsHandled: Boolean)
    begin
    end;

    procedure RunOnPrepareLineOnBeforeSetLineDiscAccount(PurchLine: Record "Purchase Line"; GenPostingSetup: Record "General Posting Setup"; var InvDiscAccount: Code[20]; var IsHandled: Boolean)
    begin
        OnPrepareLineOnBeforeSetLineDiscAccount(PurchLine, GenPostingSetup, InvDiscAccount, IsHandled);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPrepareLineOnBeforeSetLineDiscAccount(PurchLine: Record "Purchase Line"; GenPostingSetup: Record "General Posting Setup"; var InvDiscAccount: Code[20]; var IsHandled: Boolean)
    begin
    end;

    // Prepare Deferral Line

    procedure RunOnPrepareDeferralLineOnBeforePrepareInitialAmounts(var DeferralPostBuffer: Record "Deferral Posting Buffer"; PurchHeader: Record "Purchase Header"; PurchLine: Record "Purchase Line"; AmountLCY: Decimal; AmountACY: Decimal; RemainAmtToDefer: Decimal; RemainAmtToDeferACY: Decimal; DeferralAccount: Code[20]; PurchAccount: Code[20])
    begin
        OnPrepareDeferralLineOnBeforePrepareInitialAmounts(DeferralPostBuffer, PurchHeader, PurchLine, AmountLCY, AmountACY, RemainAmtToDefer, RemainAmtToDeferACY, DeferralAccount, PurchAccount);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPrepareDeferralLineOnBeforePrepareInitialAmounts(var DeferralPostBuffer: Record "Deferral Posting Buffer"; PurchHeader: Record "Purchase Header"; PurchLine: Record "Purchase Line"; AmountLCY: Decimal; AmountACY: Decimal; RemainAmtToDefer: Decimal; RemainAmtToDeferACY: Decimal; DeferralAccount: Code[20]; PurchAccount: Code[20])
    begin
    end;

    procedure RunOnPrepareDeferralLineOnAfterInitFromDeferralLine(var DeferralPostingBuffer: Record "Deferral Posting Buffer"; DeferralLine: Record "Deferral Line"; PurchaseLine: Record "Purchase Line"; DeferralTemplate: Record "Deferral Template")
    begin
        OnPrepareDeferralLineOnAfterInitFromDeferralLine(DeferralPostingBuffer, DeferralLine, PurchaseLine, DeferralTemplate);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPrepareDeferralLineOnAfterInitFromDeferralLine(var DeferralPostingBuffer: Record "Deferral Posting Buffer"; DeferralLine: Record "Deferral Line"; PurchaseLine: Record "Purchase Line"; DeferralTemplate: Record "Deferral Template")
    begin
    end;

    // Calc Deferral Amount

    procedure RunOnCalcDeferralAmountsOnBeforeTempDeferralHeaderInsert(var TempDeferralHeader: Record "Deferral Header" temporary; DeferralHeader: Record "Deferral Header"; PurchaseLine: Record "Purchase Line")
    begin
        OnCalcDeferralAmountsOnBeforeTempDeferralHeaderInsert(TempDeferralHeader, DeferralHeader, PurchaseLine);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcDeferralAmountsOnBeforeTempDeferralHeaderInsert(var TempDeferralHeader: Record "Deferral Header" temporary; DeferralHeader: Record "Deferral Header"; PurchaseLine: Record "Purchase Line")
    begin
    end;

    // CheckItemQuantityPurchCredit

    procedure RunOnBeforeCheckItemQuantityPurchCredit(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
        OnBeforeCheckItemQuantityPurchCredit(PurchaseHeader, PurchaseLine, IsHandled);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckItemQuantityPurchCredit(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    // Invoice Posting Buffer

    procedure RunOnAfterPrepareInvoicePostingBuffer(var PurchaseLine: Record "Purchase Line"; var InvoicePostingBuffer: Record "Invoice Posting Buffer")
    begin
        OnAfterPrepareInvoicePostingBuffer(PurchaseLine, InvoicePostingBuffer);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPrepareInvoicePostingBuffer(var PurchaseLine: Record "Purchase Line"; var InvoicePostingBuffer: Record "Invoice Posting Buffer")
    begin
    end;

    procedure RunOnBeforePrepareInvoicePostingBuffer(var PurchaseLine: Record "Purchase Line"; var InvoicePostingBuffer: Record "Invoice Posting Buffer")
    begin
        OnBeforePrepareInvoicePostingBuffer(PurchaseLine, InvoicePostingBuffer);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePrepareInvoicePostingBuffer(var PurchaseLine: Record "Purchase Line"; var InvoicePostingBuffer: Record "Invoice Posting Buffer")
    begin
    end;

    procedure RunOnCalculateVATAmountsOnAfterVatCalculationType(var TempInvoicePostingBuffer: Record "Invoice Posting Buffer" temporary; var PurchHeader: Record "Purchase Header"; VatPostingSetup: Record "VAT Posting Setup")
    begin
        OnCalculateVATAmountsOnAfterVatCalculationType(TempInvoicePostingBuffer, PurchHeader, VatPostingSetup);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalculateVATAmountsOnAfterVatCalculationType(var TempInvoicePostingBuffer: Record "Invoice Posting Buffer" temporary; var PurchHeader: Record "Purchase Header"; VatPostingSetup: Record "VAT Posting Setup")
    begin
    end;

    procedure RunOnBeforePrepareDeferralLine(var TempDeferralHeader: Record "Deferral Header" temporary; var TempDeferralLine: Record "Deferral Line" temporary; var PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"; AmountLCY: Decimal; AmountACY: Decimal; RemainAmtToDefer: Decimal; RemainAmtToDeferACY: Decimal; DeferralAccount: Code[20]; PurchAccount: Code[20]; DocNo: Code[20]; InvDefLineNo: Integer; var IsHandled: Boolean)
    begin
        OnBeforePrepareDeferralLine(TempDeferralHeader, TempDeferralLine, PurchHeader, PurchLine, AmountLCY, AmountACY, RemainAmtToDefer, RemainAmtToDeferACY, DeferralAccount, PurchAccount, DocNo, InvDefLineNo, IsHandled);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePrepareDeferralLine(var TempDeferralHeader: Record "Deferral Header" temporary; var TempDeferralLine: Record "Deferral Line" temporary; var PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"; AmountLCY: Decimal; AmountACY: Decimal; RemainAmtToDefer: Decimal; RemainAmtToDeferACY: Decimal; DeferralAccount: Code[20]; PurchAccount: Code[20]; DocNo: Code[20]; InvDefLineNo: Integer; var IsHandled: Boolean)
    begin
    end;

    procedure RunOnBeforeGetAmountsForDeferral(PurchLine: Record "Purchase Line"; var AmtToDefer: Decimal; var AmtToDeferACY: Decimal; var DeferralAccount: Code[20]; var IsHandled: Boolean)
    begin
        OnBeforeGetAmountsForDeferral(PurchLine, AmtToDefer, AmtToDefer, DeferralAccount, IsHandled);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetAmountsForDeferral(PurchLine: Record "Purchase Line"; var AmtToDefer: Decimal; var AmtToDeferACY: Decimal; var DeferralAccount: Code[20]; var IsHandled: Boolean)
    begin
    end;

    procedure RunOnCalcSplitFA(GenJnlLine: Record "Gen. Journal Line"; SplitNo: Integer; var SplitEnabled: Boolean)
    begin
        OnCalcSplitFA(GenJnlLine, SplitNo, SplitEnabled);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcSplitFA(GenJnlLine: Record "Gen. Journal Line"; SplitNo: Integer; var SplitEnabled: Boolean)
    begin
    end;
}
