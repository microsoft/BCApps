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

/// <summary>
/// Provides integration events for customizing the sales invoice posting process.
/// </summary>
codeunit 825 "Sales Post Invoice Events"
{
    // OnAfter events

    /// <summary>
    /// Raises the OnAfterCalcInvoiceDiscountPosting event after calculating invoice discount posting.
    /// </summary>
    /// <param name="SalesHeader">The sales header being posted.</param>
    /// <param name="SalesLine">The sales line being posted.</param>
    /// <param name="SalesLineACY">The sales line in additional currency.</param>
    /// <param name="InvoicePostingBuffer">The invoice posting buffer being populated.</param>
    procedure RunOnAfterCalcInvoiceDiscountPosting(SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; SalesLineACY: Record "Sales Line"; var InvoicePostingBuffer: Record "Invoice Posting Buffer")
    begin
        OnAfterCalcInvoiceDiscountPosting(SalesHeader, SalesLine, SalesLineACY, InvoicePostingBuffer);
    end;

    /// <summary>
    /// Raised after calculating the invoice discount posting amounts.
    /// </summary>
    /// <param name="SalesHeader">The sales header being posted.</param>
    /// <param name="SalesLine">The sales line being posted.</param>
    /// <param name="SalesLineACY">The sales line in additional currency.</param>
    /// <param name="InvoicePostingBuffer">The invoice posting buffer being populated.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcInvoiceDiscountPosting(SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; SalesLineACY: Record "Sales Line"; var InvoicePostingBuffer: Record "Invoice Posting Buffer")
    begin
    end;

    /// <summary>
    /// Raises the OnAfterCalcLineDiscountPosting event after calculating line discount posting.
    /// </summary>
    /// <param name="SalesHeader">The sales header being posted.</param>
    /// <param name="SalesLine">The sales line being posted.</param>
    /// <param name="SalesLineACY">The sales line in additional currency.</param>
    /// <param name="InvoicePostingBuffer">The invoice posting buffer being populated.</param>
    procedure RunOnAfterCalcLineDiscountPosting(SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; SalesLineACY: Record "Sales Line"; var InvoicePostingBuffer: Record "Invoice Posting Buffer")
    begin
        OnAfterCalcLineDiscountPosting(SalesHeader, SalesLine, SalesLineACY, InvoicePostingBuffer);
    end;

    /// <summary>
    /// Raised after calculating the line discount posting amounts.
    /// </summary>
    /// <param name="SalesHeader">The sales header being posted.</param>
    /// <param name="SalesLine">The sales line being posted.</param>
    /// <param name="SalesLineACY">The sales line in additional currency.</param>
    /// <param name="InvoicePostingBuffer">The invoice posting buffer being populated.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcLineDiscountPosting(SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; SalesLineACY: Record "Sales Line"; var InvoicePostingBuffer: Record "Invoice Posting Buffer")
    begin
    end;

    /// <summary>
    /// Raises the OnBeforeCreatePostedDeferralSchedule event before creating the posted deferral schedule.
    /// </summary>
    /// <param name="SalesLine">The sales line for which to create the deferral schedule.</param>
    /// <param name="IsHandled">Set to true to skip the default deferral schedule creation logic.</param>
    procedure RunOnBeforeCreatePostedDeferralSchedule(var SalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
        OnBeforeCreatePostedDeferralSchedule(SalesLine, IsHandled);
    end;

    /// <summary>
    /// Raised before creating the posted deferral schedule.
    /// </summary>
    /// <param name="SalesLine">The sales line for which to create the deferral schedule.</param>
    /// <param name="IsHandled">Set to true to skip the default deferral schedule creation logic.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreatePostedDeferralSchedule(var SalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Raises the OnAfterCreatePostedDeferralSchedule event after creating the posted deferral schedule.
    /// </summary>
    /// <param name="SalesLine">The sales line for which the deferral schedule was created.</param>
    /// <param name="PostedDeferralHeader">The posted deferral header that was created.</param>
    procedure RunOnAfterCreatePostedDeferralSchedule(var SalesLine: Record "Sales Line"; var PostedDeferralHeader: Record "Posted Deferral Header")
    begin
        OnAfterCreatePostedDeferralSchedule(SalesLine, PostedDeferralHeader);
    end;

    /// <summary>
    /// Raised after creating the posted deferral schedule.
    /// </summary>
    /// <param name="SalesLine">The sales line for which the deferral schedule was created.</param>
    /// <param name="PostedDeferralHeader">The posted deferral header that was created.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterCreatePostedDeferralSchedule(var SalesLine: Record "Sales Line"; var PostedDeferralHeader: Record "Posted Deferral Header")
    begin
    end;

    /// <summary>
    /// Runs the OnAfterGetSalesAccount integration event by first retrieving the sales header.
    /// </summary>
    /// <param name="SalesLine">The sales line for which the account is retrieved.</param>
    /// <param name="GenPostingSetup">The general posting setup used to retrieve the account.</param>
    /// <param name="SalesAccountNo">The sales account number that was retrieved.</param>
    procedure RunOnAfterGetSalesAccount(SalesLine: Record "Sales Line"; GenPostingSetup: Record "General Posting Setup"; var SalesAccountNo: Code[20])
    var
        SalesHeader: Record "Sales Header";
    begin
        if SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.") then;
        OnAfterGetSalesAccount(SalesLine, GenPostingSetup, SalesAccountNo, SalesHeader);
    end;

    /// <summary>
    /// Runs the OnAfterGetSalesAccount integration event with the provided sales header.
    /// </summary>
    /// <param name="SalesLine">The sales line for which the account is retrieved.</param>
    /// <param name="GenPostingSetup">The general posting setup used to retrieve the account.</param>
    /// <param name="SalesAccountNo">The sales account number that was retrieved.</param>
    /// <param name="SalesHeader">The sales header associated with the sales line.</param>
    procedure RunOnAfterGetSalesAccount(SalesLine: Record "Sales Line"; GenPostingSetup: Record "General Posting Setup"; var SalesAccountNo: Code[20]; SalesHeader: Record "Sales Header")
    begin
        OnAfterGetSalesAccount(SalesLine, GenPostingSetup, SalesAccountNo, SalesHeader);
    end;

    /// <summary>
    /// Raised after retrieving the sales account from the general posting setup.
    /// </summary>
    /// <param name="SalesLine">The sales line for which the account is retrieved.</param>
    /// <param name="GenPostingSetup">The general posting setup used to retrieve the account.</param>
    /// <param name="SalesAccountNo">The sales account number that was retrieved.</param>
    /// <param name="SalesHeader">The sales header associated with the sales line.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterGetSalesAccount(SalesLine: Record "Sales Line"; GenPostingSetup: Record "General Posting Setup"; var SalesAccountNo: Code[20]; SalesHeader: Record "Sales Header")
    begin
    end;

    /// <summary>
    /// Runs the OnBeforeGetSalesAccount integration event.
    /// </summary>
    /// <param name="SalesLine">The sales line for which the account is being retrieved.</param>
    /// <param name="GenPostingSetup">The general posting setup used to retrieve the account.</param>
    /// <param name="SalesAccountNo">The sales account number to be retrieved.</param>
    /// <param name="IsHandled">Set to true to skip the default account retrieval logic.</param>
    procedure RunOnBeforeGetSalesAccount(SalesLine: Record "Sales Line"; GenPostingSetup: Record "General Posting Setup"; var SalesAccountNo: Code[20]; var IsHandled: Boolean)
    begin
        OnBeforeGetSalesAccount(SalesLine, GenPostingSetup, SalesAccountNo, IsHandled);
    end;

    /// <summary>
    /// Raised before retrieving the sales account from the general posting setup.
    /// </summary>
    /// <param name="SalesLine">The sales line for which the account is being retrieved.</param>
    /// <param name="GenPostingSetup">The general posting setup used to retrieve the account.</param>
    /// <param name="SalesAccountNo">The sales account number to be retrieved.</param>
    /// <param name="IsHandled">Set to true to skip the default account retrieval logic.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetSalesAccount(SalesLine: Record "Sales Line"; GenPostingSetup: Record "General Posting Setup"; var SalesAccountNo: Code[20]; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Runs the OnBeforeGetAmountsForDeferral integration event.
    /// </summary>
    /// <param name="SalesLine">The sales line for which deferral amounts are calculated.</param>
    /// <param name="AmtToDefer">The amount to defer in local currency.</param>
    /// <param name="AmtToDeferACY">The amount to defer in additional currency.</param>
    /// <param name="DeferralAccount">The deferral account to use.</param>
    /// <param name="IsHandled">Set to true to skip the default deferral amount calculation.</param>
    procedure RunOnBeforeGetAmountsForDeferral(SalesLine: Record "Sales Line"; var AmtToDefer: Decimal; var AmtToDeferACY: Decimal; var DeferralAccount: Code[20]; var IsHandled: Boolean)
    begin
        OnBeforeGetAmountsForDeferral(SalesLine, AmtToDefer, AmtToDeferACY, DeferralAccount, IsHandled);
    end;

    /// <summary>
    /// Raised before calculating the amounts for deferral posting.
    /// </summary>
    /// <param name="SalesLine">The sales line for which deferral amounts are calculated.</param>
    /// <param name="AmtToDefer">The amount to defer in local currency.</param>
    /// <param name="AmtToDeferACY">The amount to defer in additional currency.</param>
    /// <param name="DeferralAccount">The deferral account to use.</param>
    /// <param name="IsHandled">Set to true to skip the default deferral amount calculation.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetAmountsForDeferral(SalesLine: Record "Sales Line"; var AmtToDefer: Decimal; var AmtToDeferACY: Decimal; var DeferralAccount: Code[20]; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Runs the OnAfterInitTotalAmounts integration event.
    /// </summary>
    /// <param name="SalesLine">The sales line being processed.</param>
    /// <param name="SalesLineACY">The sales line in additional currency.</param>
    /// <param name="TotalVAT">The total VAT amount in local currency.</param>
    /// <param name="TotalVATACY">The total VAT amount in additional currency.</param>
    /// <param name="TotalAmount">The total amount in local currency.</param>
    /// <param name="TotalAmountACY">The total amount in additional currency.</param>
    /// <param name="TotalVATBase">The total VAT base amount in local currency.</param>
    /// <param name="TotalVATBaseACY">The total VAT base amount in additional currency.</param>
    procedure RunOnAfterInitTotalAmounts(SalesLine: Record "Sales Line"; SalesLineACY: Record "Sales Line"; var TotalVAT: Decimal; var TotalVATACY: Decimal; var TotalAmount: Decimal; var TotalAmountACY: Decimal; var TotalVATBase: Decimal; var TotalVATBaseACY: Decimal)
    begin
        OnAfterInitTotalAmounts(SalesLine, SalesLineACY, TotalVAT, TotalVATACY, TotalAmount, TotalAmountACY, TotalVATBase, TotalVATBaseACY);
    end;

    /// <summary>
    /// Raised after initializing the total amounts for invoice posting.
    /// </summary>
    /// <param name="SalesLine">The sales line being processed.</param>
    /// <param name="SalesLineACY">The sales line in additional currency.</param>
    /// <param name="TotalVAT">The total VAT amount in local currency.</param>
    /// <param name="TotalVATACY">The total VAT amount in additional currency.</param>
    /// <param name="TotalAmount">The total amount in local currency.</param>
    /// <param name="TotalAmountACY">The total amount in additional currency.</param>
    /// <param name="TotalVATBase">The total VAT base amount in local currency.</param>
    /// <param name="TotalVATBaseACY">The total VAT base amount in additional currency.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterInitTotalAmounts(SalesLine: Record "Sales Line"; SalesLineACY: Record "Sales Line"; var TotalVAT: Decimal; var TotalVATACY: Decimal; var TotalAmount: Decimal; var TotalAmountACY: Decimal; var TotalVATBase: Decimal; var TotalVATBaseACY: Decimal)
    begin
    end;

    /// <summary>
    /// Runs the OnAfterPrepareGenJnlLine integration event.
    /// </summary>
    /// <param name="GenJnlLine">The general journal line that was prepared.</param>
    /// <param name="SalesHeader">The sales header being posted.</param>
    /// <param name="InvoicePostingBuffer">The invoice posting buffer containing the posting data.</param>
    procedure RunOnAfterPrepareGenJnlLine(var GenJnlLine: Record "Gen. Journal Line"; SalesHeader: Record "Sales Header"; InvoicePostingBuffer: Record "Invoice Posting Buffer")
    begin
        OnAfterPrepareGenJnlLine(GenJnlLine, SalesHeader, InvoicePostingBuffer);
    end;

    /// <summary>
    /// Raised after preparing the general journal line for posting.
    /// </summary>
    /// <param name="GenJnlLine">The general journal line that was prepared.</param>
    /// <param name="SalesHeader">The sales header being posted.</param>
    /// <param name="InvoicePostingBuffer">The invoice posting buffer containing the posting data.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterPrepareGenJnlLine(var GenJnlLine: Record "Gen. Journal Line"; SalesHeader: Record "Sales Header"; InvoicePostingBuffer: Record "Invoice Posting Buffer")
    begin
    end;

    /// <summary>
    /// Runs the OnAfterSetApplyToDocNo integration event.
    /// </summary>
    /// <param name="GenJournalLine">The general journal line being updated.</param>
    /// <param name="SalesHeader">The sales header being posted.</param>
    procedure RunOnAfterSetApplyToDocNo(var GenJournalLine: Record "Gen. Journal Line"; SalesHeader: Record "Sales Header")
    begin
        OnAfterSetApplyToDocNo(GenJournalLine, SalesHeader);
    end;

    /// <summary>
    /// Raised after setting the apply-to document number on the general journal line.
    /// </summary>
    /// <param name="GenJournalLine">The general journal line being updated.</param>
    /// <param name="SalesHeader">The sales header being posted.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterSetApplyToDocNo(var GenJournalLine: Record "Gen. Journal Line"; SalesHeader: Record "Sales Header")
    begin
    end;

    /// <summary>
    /// Runs the OnAfterSetJobLineFilters integration event.
    /// </summary>
    /// <param name="JobSalesLine">The sales line with job-related filters applied.</param>
    /// <param name="InvoicePostingBuffer">The invoice posting buffer used for filtering.</param>
    procedure RunOnAfterSetJobLineFilters(var JobSalesLine: Record "Sales Line"; InvoicePostingBuffer: Record "Invoice Posting Buffer")
    begin
        OnAfterSetJobLineFilters(JobSalesLine, InvoicePostingBuffer);
    end;

    /// <summary>
    /// Raised after setting filters on job sales lines for invoice posting.
    /// </summary>
    /// <param name="JobSalesLine">The sales line with job-related filters applied.</param>
    /// <param name="InvoicePostingBuffer">The invoice posting buffer used for filtering.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterSetJobLineFilters(var JobSalesLine: Record "Sales Line"; InvoicePostingBuffer: Record "Invoice Posting Buffer")
    begin
    end;

    // OnBefore events

    /// <summary>
    /// Runs the OnBeforeCalcInvoiceDiscountPosting integration event.
    /// </summary>
    /// <param name="SalesHeader">The sales header being posted.</param>
    /// <param name="SalesLine">The sales line being posted.</param>
    /// <param name="SalesLineACY">The sales line in additional currency.</param>
    /// <param name="InvoicePostingBuffer">The invoice posting buffer to be populated.</param>
    /// <param name="IsHandled">Set to true to skip the default invoice discount calculation.</param>
    procedure RunOnBeforeCalcInvoiceDiscountPosting(SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; SalesLineACY: Record "Sales Line"; var InvoicePostingBuffer: Record "Invoice Posting Buffer"; var IsHandled: Boolean)
    begin
        OnBeforeCalcInvoiceDiscountPosting(SalesHeader, SalesLine, SalesLineACY, InvoicePostingBuffer, IsHandled);
    end;

    /// <summary>
    /// Raised before calculating invoice discount posting amounts.
    /// </summary>
    /// <param name="SalesHeader">The sales header being posted.</param>
    /// <param name="SalesLine">The sales line being posted.</param>
    /// <param name="SalesLineACY">The sales line in additional currency.</param>
    /// <param name="InvoicePostingBuffer">The invoice posting buffer to be populated.</param>
    /// <param name="IsHandled">Set to true to skip the default invoice discount calculation.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcInvoiceDiscountPosting(SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; SalesLineACY: Record "Sales Line"; var InvoicePostingBuffer: Record "Invoice Posting Buffer"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Runs the OnBeforeCalcLineDiscountPosting integration event.
    /// </summary>
    /// <param name="SalesHeader">The sales header being posted.</param>
    /// <param name="SalesLine">The sales line being posted.</param>
    /// <param name="SalesLineACY">The sales line in additional currency.</param>
    /// <param name="InvoicePostingBuffer">The invoice posting buffer to be populated.</param>
    /// <param name="IsHandled">Set to true to skip the default line discount calculation.</param>
    procedure RunOnBeforeCalcLineDiscountPosting(SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; SalesLineACY: Record "Sales Line"; var InvoicePostingBuffer: Record "Invoice Posting Buffer"; var IsHandled: Boolean)
    begin
        OnBeforeCalcLineDiscountPosting(SalesHeader, SalesLine, SalesLineACY, InvoicePostingBuffer, IsHandled);
    end;

    /// <summary>
    /// Raised before calculating line discount posting amounts.
    /// </summary>
    /// <param name="SalesHeader">The sales header being posted.</param>
    /// <param name="SalesLine">The sales line being posted.</param>
    /// <param name="SalesLineACY">The sales line in additional currency.</param>
    /// <param name="InvoicePostingBuffer">The invoice posting buffer to be populated.</param>
    /// <param name="IsHandled">Set to true to skip the default line discount calculation.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcLineDiscountPosting(SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; SalesLineACY: Record "Sales Line"; var InvoicePostingBuffer: Record "Invoice Posting Buffer"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Runs the OnBeforeInitGenJnlLine integration event.
    /// </summary>
    /// <param name="GenJnlLine">The general journal line to be initialized.</param>
    /// <param name="SalesHeader">The sales header being posted.</param>
    /// <param name="InvoicePostingBuffer">The invoice posting buffer containing the posting data.</param>
    /// <param name="IsHandled">Set to true to skip the default initialization logic.</param>
    procedure RunOnBeforeInitGenJnlLine(var GenJnlLine: Record "Gen. Journal Line"; SalesHeader: Record "Sales Header"; InvoicePostingBuffer: Record "Invoice Posting Buffer"; var IsHandled: Boolean)
    begin
        OnBeforeInitGenJnlLine(GenJnlLine, SalesHeader, InvoicePostingBuffer, IsHandled);
    end;

    /// <summary>
    /// Raised before initializing the general journal line for invoice posting.
    /// </summary>
    /// <param name="GenJnlLine">The general journal line to be initialized.</param>
    /// <param name="SalesHeader">The sales header being posted.</param>
    /// <param name="InvoicePostingBuffer">The invoice posting buffer containing the posting data.</param>
    /// <param name="IsHandled">Set to true to skip the default initialization logic.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitGenJnlLine(var GenJnlLine: Record "Gen. Journal Line"; SalesHeader: Record "Sales Header"; InvoicePostingBuffer: Record "Invoice Posting Buffer"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Runs the OnBeforeInitGenJnlLineAmountFieldsFromTotalLines integration event.
    /// </summary>
    /// <param name="GenJnlLine">The general journal line to be initialized.</param>
    /// <param name="SalesHeader">The sales header being posted.</param>
    /// <param name="TotalSalesLine">The total sales line amounts.</param>
    /// <param name="TotalSalesLineLCY">The total sales line amounts in local currency.</param>
    /// <param name="IsHandled">Set to true to skip the default amount initialization logic.</param>
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

    /// <summary>
    /// Raised before initializing the general journal line amount fields from total lines.
    /// </summary>
    /// <param name="GenJnlLine">The general journal line to be initialized.</param>
    /// <param name="SalesHeader">The sales header being posted.</param>
    /// <param name="TotalSalesLine">The total sales line amounts.</param>
    /// <param name="TotalSalesLineLCY">The total sales line amounts in local currency.</param>
    /// <param name="IsHandled">Set to true to skip the default amount initialization.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitGenJnlLineAmountFieldsFromTotalLines2(var GenJnlLine: Record "Gen. Journal Line"; var SalesHeader: Record "Sales Header"; var TotalSalesLine: Record "Sales Line"; var TotalSalesLineLCY: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Runs the OnBeforeRunGenJnlPostLine integration event.
    /// </summary>
    /// <param name="GenJnlLine">The general journal line to be posted.</param>
    /// <param name="GenJnlPostLine">The general journal post line codeunit instance.</param>
    procedure RunOnBeforeRunGenJnlPostLine(var GenJnlLine: Record "Gen. Journal Line"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    begin
        OnBeforeRunGenJnlPostLine(GenJnlLine, GenJnlPostLine);
    end;

    /// <summary>
    /// Raised before running the general journal post line codeunit.
    /// </summary>
    /// <param name="GenJnlLine">The general journal line to be posted.</param>
    /// <param name="GenJnlPostLine">The general journal post line codeunit instance.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeRunGenJnlPostLine(var GenJnlLine: Record "Gen. Journal Line"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    begin
    end;

    /// <summary>
    /// Runs the OnBeforeSetAmountsForBalancingEntry integration event.
    /// </summary>
    /// <param name="CustLedgEntry">The customer ledger entry for the balancing entry.</param>
    /// <param name="GenJnlLine">The general journal line being prepared.</param>
    /// <param name="TotalSalesLine">The total sales line amounts.</param>
    /// <param name="TotalSalesLineLCY">The total sales line amounts in local currency.</param>
    /// <param name="IsHandled">Set to true to skip the default amount setting logic.</param>
    procedure RunOnBeforeSetAmountsForBalancingEntry(var CustLedgEntry: Record "Cust. Ledger Entry"; var GenJnlLine: Record "Gen. Journal Line"; var TotalSalesLine: Record "Sales Line"; var TotalSalesLineLCY: Record "Sales Line"; var IsHandled: Boolean)
    begin
        OnBeforeSetAmountsForBalancingEntry(CustLedgEntry, GenJnlLine, TotalSalesLine, TotalSalesLineLCY, IsHandled);
    end;

    /// <summary>
    /// Raised before setting amounts for the balancing entry.
    /// </summary>
    /// <param name="CustLedgEntry">The customer ledger entry for the balancing entry.</param>
    /// <param name="GenJnlLine">The general journal line being prepared.</param>
    /// <param name="TotalSalesLine">The total sales line amounts.</param>
    /// <param name="TotalSalesLineLCY">The total sales line amounts in local currency.</param>
    /// <param name="IsHandled">Set to true to skip the default amount setting logic.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetAmountsForBalancingEntry(var CustLedgEntry: Record "Cust. Ledger Entry"; var GenJnlLine: Record "Gen. Journal Line"; var TotalSalesLine: Record "Sales Line"; var TotalSalesLineLCY: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Runs the OnBeforePostLines integration event.
    /// </summary>
    /// <param name="SalesHeader">The sales header being posted.</param>
    /// <param name="TempInvoicePostingBuffer">The temporary invoice posting buffer containing lines to post.</param>
    procedure RunOnBeforePostLines(SalesHeader: Record "Sales Header"; var TempInvoicePostingBuffer: Record "Invoice Posting Buffer" temporary)
    begin
        OnBeforePostLines(SalesHeader, TempInvoicePostingBuffer);
    end;

    /// <summary>
    /// Raised before posting the invoice lines to the general ledger.
    /// </summary>
    /// <param name="SalesHeader">The sales header being posted.</param>
    /// <param name="TempInvoicePostingBuffer">The temporary invoice posting buffer containing lines to post.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforePostLines(SalesHeader: Record "Sales Header"; var TempInvoicePostingBuffer: Record "Invoice Posting Buffer" temporary)
    begin
    end;

    /// <summary>
    /// Runs the OnBeforePostLedgerEntry integration event.
    /// </summary>
    /// <param name="SalesHeader">The sales header being posted.</param>
    /// <param name="TotalSalesLine">The total sales line amounts.</param>
    /// <param name="TotalSalesLineLCY">The total sales line amounts in local currency.</param>
    /// <param name="PreviewMode">Indicates whether the posting is in preview mode.</param>
    /// <param name="SuppressCommit">Indicates whether to suppress database commits.</param>
    /// <param name="InvoicePostingParameters">The invoice posting parameters.</param>
    /// <param name="GenJnlPostLine">The general journal post line codeunit instance.</param>
    /// <param name="IsHandled">Set to true to skip the default ledger entry posting.</param>
    procedure RunOnBeforePostLedgerEntry(var SalesHeader: Record "Sales Header"; var TotalSalesLine: Record "Sales Line"; var TotalSalesLineLCY: Record "Sales Line"; PreviewMode: Boolean; SuppressCommit: Boolean; InvoicePostingParameters: Record "Invoice Posting Parameters"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; var IsHandled: Boolean)
    begin
        OnBeforePostLedgerEntry(SalesHeader, TotalSalesLine, TotalSalesLineLCY, PreviewMode, SuppressCommit, InvoicePostingParameters, GenJnlPostLine, IsHandled);
    end;

    /// <summary>
    /// Raised before posting the customer ledger entry.
    /// </summary>
    /// <param name="SalesHeader">The sales header being posted.</param>
    /// <param name="TotalSalesLine">The total sales line amounts.</param>
    /// <param name="TotalSalesLineLCY">The total sales line amounts in local currency.</param>
    /// <param name="SuppressCommit">Indicates whether to suppress database commits.</param>
    /// <param name="PreviewMode">Indicates whether the posting is in preview mode.</param>
    /// <param name="InvoicePostingParameters">The invoice posting parameters.</param>
    /// <param name="GenJnlPostLine">The general journal post line codeunit instance.</param>
    /// <param name="IsHandled">Set to true to skip the default ledger entry posting.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforePostLedgerEntry(var SalesHeader: Record "Sales Header"; var TotalSalesLine: Record "Sales Line"; var TotalSalesLineLCY: Record "Sales Line"; SuppressCommit: Boolean; PreviewMode: Boolean; InvoicePostingParameters: Record "Invoice Posting Parameters"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Runs the OnBeforePrepareLine integration event.
    /// </summary>
    /// <param name="SalesHeader">The sales header being posted.</param>
    /// <param name="SalesLine">The sales line to be prepared.</param>
    /// <param name="SalesLineACY">The sales line in additional currency.</param>
    /// <param name="IsHandled">Set to true to skip the default line preparation.</param>
    procedure RunOnBeforePrepareLine(SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; SalesLineACY: Record "Sales Line"; var IsHandled: Boolean)
    begin
        OnBeforePrepareLine(SalesHeader, SalesLine, SalesLineACY, IsHandled);
    end;

    /// <summary>
    /// Raised before preparing a sales line for invoice posting.
    /// </summary>
    /// <param name="SalesHeader">The sales header being posted.</param>
    /// <param name="SalesLine">The sales line to be prepared.</param>
    /// <param name="SalesLineACY">The sales line in additional currency.</param>
    /// <param name="IsHandled">Set to true to skip the default line preparation.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforePrepareLine(SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; SalesLineACY: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Runs the OnBeforeTempDeferralLineInsert integration event.
    /// </summary>
    /// <param name="TempDeferralLine">The temporary deferral line to be inserted.</param>
    /// <param name="DeferralLine">The source deferral line.</param>
    /// <param name="SalesLine">The sales line associated with the deferral.</param>
    /// <param name="DeferralCount">The current deferral line count.</param>
    /// <param name="TotalDeferralCount">The total number of deferral lines.</param>
    procedure RunOnBeforeTempDeferralLineInsert(var TempDeferralLine: Record "Deferral Line" temporary; DeferralLine: Record "Deferral Line"; SalesLine: Record "Sales Line"; var DeferralCount: Integer; var TotalDeferralCount: Integer)
    begin
        OnBeforeTempDeferralLineInsert(TempDeferralLine, DeferralLine, SalesLine, DeferralCount, TotalDeferralCount);
    end;

    /// <summary>
    /// Raised before inserting a temporary deferral line.
    /// </summary>
    /// <param name="TempDeferralLine">The temporary deferral line to be inserted.</param>
    /// <param name="DeferralLine">The source deferral line.</param>
    /// <param name="SalesLine">The sales line associated with the deferral.</param>
    /// <param name="DeferralCount">The current deferral line count.</param>
    /// <param name="TotalDeferralCount">The total number of deferral lines.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeTempDeferralLineInsert(var TempDeferralLine: Record "Deferral Line" temporary; DeferralLine: Record "Deferral Line"; SalesLine: Record "Sales Line"; var DeferralCount: Integer; var TotalDeferralCount: Integer)
    begin
    end;

    // Post Balancing Entry

    /// <summary>
    /// Runs the OnPostBalancingEntryOnBeforeFindCustLedgEntry integration event.
    /// </summary>
    /// <param name="SalesHeader">The sales header being posted.</param>
    /// <param name="SalesLine">The sales line being posted.</param>
    /// <param name="InvoicePostingParameters">The invoice posting parameters.</param>
    /// <param name="CustLedgerEntry">The customer ledger entry to find.</param>
    /// <param name="EntryFound">Indicates whether the entry was found.</param>
    /// <param name="IsHandled">Set to true to skip the default find logic.</param>
    procedure RunOnPostBalancingEntryOnBeforeFindCustLedgEntry(SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; InvoicePostingParameters: Record "Invoice Posting Parameters"; var CustLedgerEntry: Record "Cust. Ledger Entry"; var EntryFound: Boolean; var IsHandled: Boolean)
    begin
        OnPostBalancingEntryOnBeforeFindCustLedgEntry(SalesHeader, SalesLine, InvoicePostingParameters, CustLedgerEntry, EntryFound, IsHandled);
    end;

    /// <summary>
    /// Raised before finding the customer ledger entry during balancing entry posting.
    /// </summary>
    /// <param name="SalesHeader">The sales header being posted.</param>
    /// <param name="SalesLine">The sales line being posted.</param>
    /// <param name="InvoicePostingParameters">The invoice posting parameters.</param>
    /// <param name="CustLedgerEntry">The customer ledger entry to find.</param>
    /// <param name="EntryFound">Indicates whether the entry was found.</param>
    /// <param name="IsHandled">Set to true to skip the default find logic.</param>
    [IntegrationEvent(false, false)]
    local procedure OnPostBalancingEntryOnBeforeFindCustLedgEntry(SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; InvoicePostingParameters: Record "Invoice Posting Parameters"; var CustLedgerEntry: Record "Cust. Ledger Entry"; var EntryFound: Boolean; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Runs the OnPostBalancingEntryOnAfterGenJnlPostLine integration event.
    /// </summary>
    /// <param name="GenJnlLine">The general journal line that was posted.</param>
    /// <param name="SalesHeader">The sales header being posted.</param>
    /// <param name="TotalSalesLine">The total sales line amounts.</param>
    /// <param name="TotalSalesLineLCY">The total sales line amounts in local currency.</param>
    /// <param name="PreviewMode">Indicates whether the posting is in preview mode.</param>
    /// <param name="SuppressCommit">Indicates whether to suppress database commits.</param>
    /// <param name="GenJnlPostLine">The general journal post line codeunit instance.</param>
    procedure RunOnPostBalancingEntryOnAfterGenJnlPostLine(var GenJnlLine: Record "Gen. Journal Line"; var SalesHeader: Record "Sales Header"; var TotalSalesLine: Record "Sales Line"; var TotalSalesLineLCY: Record "Sales Line"; PreviewMode: Boolean; SuppressCommit: Boolean; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    begin
        OnPostBalancingEntryOnAfterGenJnlPostLine(GenJnlLine, SalesHeader, TotalSalesLine, TotalSalesLineLCY, PreviewMode, SuppressCommit, GenJnlPostLine);
    end;

    /// <summary>
    /// Raised after posting the balancing entry to the general journal.
    /// </summary>
    /// <param name="GenJnlLine">The general journal line that was posted.</param>
    /// <param name="SalesHeader">The sales header being posted.</param>
    /// <param name="TotalSalesLine">The total sales line amounts.</param>
    /// <param name="TotalSalesLineLCY">The total sales line amounts in local currency.</param>
    /// <param name="PreviewMode">Indicates whether the posting is in preview mode.</param>
    /// <param name="SuppressCommit">Indicates whether to suppress database commits.</param>
    /// <param name="GenJnlPostLine">The general journal post line codeunit instance.</param>
    [IntegrationEvent(false, false)]
    local procedure OnPostBalancingEntryOnAfterGenJnlPostLine(var GenJnlLine: Record "Gen. Journal Line"; var SalesHeader: Record "Sales Header"; var TotalSalesLine: Record "Sales Line"; var TotalSalesLineLCY: Record "Sales Line"; PreviewMode: Boolean; SuppressCommit: Boolean; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    begin
    end;

    /// <summary>
    /// Runs the OnPostBalancingEntryOnBeforeGenJnlPostLine integration event.
    /// </summary>
    /// <param name="GenJnlLine">The general journal line to be posted.</param>
    /// <param name="SalesHeader">The sales header being posted.</param>
    /// <param name="TotalSalesLine">The total sales line amounts.</param>
    /// <param name="TotalSalesLineLCY">The total sales line amounts in local currency.</param>
    /// <param name="PreviewMode">Indicates whether the posting is in preview mode.</param>
    /// <param name="SuppressCommit">Indicates whether to suppress database commits.</param>
    /// <param name="GenJnlPostLine">The general journal post line codeunit instance.</param>
    procedure RunOnPostBalancingEntryOnBeforeGenJnlPostLine(var GenJnlLine: Record "Gen. Journal Line"; var SalesHeader: Record "Sales Header"; var TotalSalesLine: Record "Sales Line"; var TotalSalesLineLCY: Record "Sales Line"; PreviewMode: Boolean; SuppressCommit: Boolean; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    begin
        OnPostBalancingEntryOnBeforeGenJnlPostLine(GenJnlLine, SalesHeader, TotalSalesLine, TotalSalesLineLCY, PreviewMode, SuppressCommit, GenJnlPostLine);
    end;

    /// <summary>
    /// Raised before posting the balancing entry to the general journal.
    /// </summary>
    /// <param name="GenJnlLine">The general journal line to be posted.</param>
    /// <param name="SalesHeader">The sales header being posted.</param>
    /// <param name="TotalSalesLine">The total sales line amounts.</param>
    /// <param name="TotalSalesLineLCY">The total sales line amounts in local currency.</param>
    /// <param name="PreviewMode">Indicates whether the posting is in preview mode.</param>
    /// <param name="SuppressCommit">Indicates whether to suppress database commits.</param>
    /// <param name="GenJnlPostLine">The general journal post line codeunit instance.</param>
    [IntegrationEvent(false, false)]
    local procedure OnPostBalancingEntryOnBeforeGenJnlPostLine(var GenJnlLine: Record "Gen. Journal Line"; var SalesHeader: Record "Sales Header"; var TotalSalesLine: Record "Sales Line"; var TotalSalesLineLCY: Record "Sales Line"; PreviewMode: Boolean; SuppressCommit: Boolean; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    begin
    end;

    /// <summary>
    /// Runs the OnPostBalancingEntryOnAfterFindCustLedgEntry integration event.
    /// </summary>
    /// <param name="CustLedgEntry">The customer ledger entry that was found.</param>
    procedure RunOnPostBalancingEntryOnAfterFindCustLedgEntry(var CustLedgEntry: Record "Cust. Ledger Entry")
    begin
        OnPostBalancingEntryOnAfterFindCustLedgEntry(CustLedgEntry);
    end;

    /// <summary>
    /// Raised after finding the customer ledger entry during balancing entry posting.
    /// </summary>
    /// <param name="CustLedgEntry">The customer ledger entry that was found.</param>
    [IntegrationEvent(false, false)]
    local procedure OnPostBalancingEntryOnAfterFindCustLedgEntry(var CustLedgEntry: Record "Cust. Ledger Entry")
    begin
    end;

    /// <summary>
    /// Runs the OnPostBalancingEntryOnAfterInitNewLine integration event.
    /// </summary>
    /// <param name="SalesHeader">The sales header being posted.</param>
    /// <param name="GenJournalLine">The general journal line that was initialized.</param>
    procedure RunOnPostBalancingEntryOnAfterInitNewLine(SalesHeader: Record "Sales Header"; var GenJournalLine: Record "Gen. Journal Line")
    begin
        OnPostBalancingEntryOnAfterInitNewLine(SalesHeader, GenJournalLine);
    end;

    /// <summary>
    /// Raised after initializing a new general journal line during balancing entry posting.
    /// </summary>
    /// <param name="SalesHeader">The sales header being posted.</param>
    /// <param name="GenJournalLine">The general journal line that was initialized.</param>
    [IntegrationEvent(false, false)]
    local procedure OnPostBalancingEntryOnAfterInitNewLine(SalesHeader: Record "Sales Header"; var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;


    // Post Ledger Entry

    /// <summary>
    /// Runs the OnPostLedgerEntryOnAfterGenJnlPostLine integration event.
    /// </summary>
    /// <param name="GenJnlLine">The general journal line that was posted.</param>
    /// <param name="SalesHeader">The sales header being posted.</param>
    /// <param name="TotalSalesLine">The total sales line amounts.</param>
    /// <param name="TotalSalesLineLCY">The total sales line amounts in local currency.</param>
    /// <param name="PreviewMode">Indicates whether the posting is in preview mode.</param>
    /// <param name="SuppressCommit">Indicates whether to suppress database commits.</param>
    /// <param name="GenJnlPostLine">The general journal post line codeunit instance.</param>
    procedure RunOnPostLedgerEntryOnAfterGenJnlPostLine(var GenJnlLine: Record "Gen. Journal Line"; var SalesHeader: Record "Sales Header"; var TotalSalesLine: Record "Sales Line"; var TotalSalesLineLCY: Record "Sales Line"; PreviewMode: Boolean; SuppressCommit: Boolean; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    begin
        OnPostLedgerEntryOnAfterGenJnlPostLine(GenJnlLine, SalesHeader, TotalSalesLine, TotalSalesLineLCY, PreviewMode, SuppressCommit, GenJnlPostLine);
    end;

    /// <summary>
    /// Raised after posting the ledger entry to the general journal.
    /// </summary>
    /// <param name="GenJnlLine">The general journal line that was posted.</param>
    /// <param name="SalesHeader">The sales header being posted.</param>
    /// <param name="TotalSalesLine">The total sales line amounts.</param>
    /// <param name="TotalSalesLineLCY">The total sales line amounts in local currency.</param>
    /// <param name="PreviewMode">Indicates whether the posting is in preview mode.</param>
    /// <param name="SuppressCommit">Indicates whether to suppress database commits.</param>
    /// <param name="GenJnlPostLine">The general journal post line codeunit instance.</param>
    [IntegrationEvent(false, false)]
    local procedure OnPostLedgerEntryOnAfterGenJnlPostLine(var GenJnlLine: Record "Gen. Journal Line"; var SalesHeader: Record "Sales Header"; var TotalSalesLine: Record "Sales Line"; var TotalSalesLineLCY: Record "Sales Line"; PreviewMode: Boolean; SuppressCommit: Boolean; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    begin
    end;

    /// <summary>
    /// Runs the OnPostLedgerEntryOnBeforeGenJnlPostLine integration event.
    /// </summary>
    /// <param name="GenJnlLine">The general journal line to be posted.</param>
    /// <param name="SalesHeader">The sales header being posted.</param>
    /// <param name="TotalSalesLine">The total sales line amounts.</param>
    /// <param name="TotalSalesLineLCY">The total sales line amounts in local currency.</param>
    /// <param name="PreviewMode">Indicates whether the posting is in preview mode.</param>
    /// <param name="SuppressCommit">Indicates whether to suppress database commits.</param>
    /// <param name="GenJnlPostLine">The general journal post line codeunit instance.</param>
    procedure RunOnPostLedgerEntryOnBeforeGenJnlPostLine(var GenJnlLine: Record "Gen. Journal Line"; var SalesHeader: Record "Sales Header"; var TotalSalesLine: Record "Sales Line"; var TotalSalesLineLCY: Record "Sales Line"; PreviewMode: Boolean; SuppressCommit: Boolean; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    begin
        OnPostLedgerEntryOnBeforeGenJnlPostLine(GenJnlLine, SalesHeader, TotalSalesLine, TotalSalesLineLCY, PreviewMode, SuppressCommit, GenJnlPostLine);
    end;

    /// <summary>
    /// Raised before posting the ledger entry to the general journal.
    /// </summary>
    /// <param name="GenJnlLine">The general journal line to be posted.</param>
    /// <param name="SalesHeader">The sales header being posted.</param>
    /// <param name="TotalSalesLine">The total sales line amounts.</param>
    /// <param name="TotalSalesLineLCY">The total sales line amounts in local currency.</param>
    /// <param name="PreviewMode">Indicates whether the posting is in preview mode.</param>
    /// <param name="SuppressCommit">Indicates whether to suppress database commits.</param>
    /// <param name="GenJnlPostLine">The general journal post line codeunit instance.</param>
    [IntegrationEvent(false, false)]
    local procedure OnPostLedgerEntryOnBeforeGenJnlPostLine(var GenJnlLine: Record "Gen. Journal Line"; var SalesHeader: Record "Sales Header"; var TotalSalesLine: Record "Sales Line"; var TotalSalesLineLCY: Record "Sales Line"; PreviewMode: Boolean; SuppressCommit: Boolean; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    begin
    end;

    // Prepare Line

    /// <summary>
    /// Runs the OnPrepareLineOnAfterAssignAmounts integration event.
    /// </summary>
    /// <param name="SalesLine">The sales line being processed.</param>
    /// <param name="SalesLineACY">The sales line in additional currency.</param>
    /// <param name="TotalAmount">The total amount in local currency.</param>
    /// <param name="TotalAmountACY">The total amount in additional currency.</param>
    procedure RunOnPrepareLineOnAfterAssignAmounts(SalesLine: Record "Sales Line"; SalesLineACY: Record "Sales Line"; var TotalAmount: Decimal; var TotalAmountACY: Decimal)
    begin
        OnPrepareLineOnAfterAssignAmounts(SalesLine, SalesLineACY, TotalAmount, TotalAmountACY);
    end;

    /// <summary>
    /// Raised after assigning amounts during line preparation.
    /// </summary>
    /// <param name="SalesLine">The sales line being processed.</param>
    /// <param name="SalesLineACY">The sales line in additional currency.</param>
    /// <param name="TotalAmount">The total amount in local currency.</param>
    /// <param name="TotalAmountACY">The total amount in additional currency.</param>
    [IntegrationEvent(false, false)]
    local procedure OnPrepareLineOnAfterAssignAmounts(SalesLine: Record "Sales Line"; SalesLineACY: Record "Sales Line"; var TotalAmount: Decimal; var TotalAmountACY: Decimal)
    begin
    end;

    /// <summary>
    /// Runs the OnPrepareLineOnAfterSetAmounts integration event.
    /// </summary>
    /// <param name="InvoicePostingBuffer">The invoice posting buffer being populated.</param>
    /// <param name="SalesLine">The sales line being processed.</param>
    procedure RunOnPrepareLineOnAfterSetAmounts(var InvoicePostingBuffer: Record "Invoice Posting Buffer"; SalesLine: Record "Sales Line")
    begin
        OnPrepareLineOnAfterSetAmounts(InvoicePostingBuffer, SalesLine);
    end;

    /// <summary>
    /// Raised after setting amounts on the invoice posting buffer during line preparation.
    /// </summary>
    /// <param name="InvoicePostingBuffer">The invoice posting buffer being populated.</param>
    /// <param name="SalesLine">The sales line being processed.</param>
    [IntegrationEvent(false, false)]
    local procedure OnPrepareLineOnAfterSetAmounts(var InvoicePostingBuffer: Record "Invoice Posting Buffer"; SalesLine: Record "Sales Line")
    begin
    end;

    /// <summary>
    /// Runs the OnPrepareLineOnAfterFillInvoicePostingBuffer integration event.
    /// </summary>
    /// <param name="InvoicePostingBuffer">The invoice posting buffer that was filled.</param>
    /// <param name="SalesLine">The sales line being processed.</param>
    procedure RunOnPrepareLineOnAfterFillInvoicePostingBuffer(var InvoicePostingBuffer: Record "Invoice Posting Buffer"; SalesLine: Record "Sales Line")
    begin
        OnPrepareLineOnAfterFillInvoicePostingBuffer(InvoicePostingBuffer, SalesLine);
    end;

    /// <summary>
    /// Raised after filling the invoice posting buffer during line preparation.
    /// </summary>
    /// <param name="InvoicePostingBuffer">The invoice posting buffer that was filled.</param>
    /// <param name="SalesLine">The sales line being processed.</param>
    [IntegrationEvent(false, false)]
    local procedure OnPrepareLineOnAfterFillInvoicePostingBuffer(var InvoicePostingBuffer: Record "Invoice Posting Buffer"; SalesLine: Record "Sales Line")
    begin
    end;

    /// <summary>
    /// Runs the OnPrepareLineOnBeforeAdjustTotalAmounts integration event.
    /// </summary>
    /// <param name="SalesLine">The sales line being processed.</param>
    /// <param name="TotalAmount">The total amount in local currency to adjust.</param>
    /// <param name="TotalAmountACY">The total amount in additional currency to adjust.</param>
    /// <param name="UseDate">The date to use for currency conversion.</param>
    procedure RunOnPrepareLineOnBeforeAdjustTotalAmounts(SalesLine: Record "Sales Line"; var TotalAmount: Decimal; var TotalAmountACY: Decimal; UseDate: Date)
    begin
        OnPrepareLineOnBeforeAdjustTotalAmounts(SalesLine, TotalAmount, TotalAmountACY, UseDate);
    end;

    /// <summary>
    /// Raised before adjusting total amounts during line preparation.
    /// </summary>
    /// <param name="SalesLine">The sales line being processed.</param>
    /// <param name="TotalAmount">The total amount in local currency to adjust.</param>
    /// <param name="TotalAmountACY">The total amount in additional currency to adjust.</param>
    /// <param name="UseDate">The date to use for currency conversion.</param>
    [IntegrationEvent(false, false)]
    local procedure OnPrepareLineOnBeforeAdjustTotalAmounts(SalesLine: Record "Sales Line"; var TotalAmount: Decimal; var TotalAmountACY: Decimal; UseDate: Date)
    begin
    end;

    /// <summary>
    /// Runs the OnPrepareLineOnBeforeSetAccount integration event.
    /// </summary>
    /// <param name="SalesHeader">The sales header being posted.</param>
    /// <param name="SalesLine">The sales line being processed.</param>
    /// <param name="SalesAccount">The sales account to be set.</param>
    procedure RunOnPrepareLineOnBeforeSetAccount(SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; var SalesAccount: Code[20])
    begin
        OnPrepareLineOnBeforeSetAccount(SalesHeader, SalesLine, SalesAccount);
    end;

    /// <summary>
    /// Raised before setting the sales account during line preparation.
    /// </summary>
    /// <param name="SalesHeader">The sales header being posted.</param>
    /// <param name="SalesLine">The sales line being processed.</param>
    /// <param name="SalesAccount">The sales account to be set.</param>
    [IntegrationEvent(false, false)]
    local procedure OnPrepareLineOnBeforeSetAccount(SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; var SalesAccount: Code[20])
    begin
    end;

    /// <summary>
    /// Runs the OnPrepareLineOnBeforeSetAmounts integration event.
    /// </summary>
    /// <param name="SalesLine">The sales line being processed.</param>
    /// <param name="SalesLineACY">The sales line in additional currency.</param>
    /// <param name="InvoicePostingBuffer">The invoice posting buffer being populated.</param>
    /// <param name="TotalVAT">The total VAT amount in local currency.</param>
    /// <param name="TotalVATACY">The total VAT amount in additional currency.</param>
    /// <param name="TotalAmount">The total amount in local currency.</param>
    /// <param name="TotalAmountACY">The total amount in additional currency.</param>
    /// <param name="TotalVATBase">The total VAT base amount in local currency.</param>
    /// <param name="TotalVATBaseACY">The total VAT base amount in additional currency.</param>
    /// <param name="IsHandled">Set to true to skip the default amount setting logic.</param>
    procedure RunOnPrepareLineOnBeforeSetAmounts(SalesLine: Record "Sales Line"; SalesLineACY: Record "Sales Line"; var InvoicePostingBuffer: Record "Invoice Posting Buffer"; var TotalVAT: Decimal; var TotalVATACY: Decimal; var TotalAmount: Decimal; var TotalAmountACY: Decimal; var TotalVATBase: Decimal; var TotalVATBaseACY: Decimal; var IsHandled: Boolean)
    begin
        OnPrepareLineOnBeforeSetAmounts(SalesLine, SalesLineACY, InvoicePostingBuffer, TotalVAT, TotalVATACY, TotalAmount, TotalAmountACY, TotalVATBase, TotalVATBaseACY, IsHandled);
    end;

    /// <summary>
    /// Raised before setting amounts on the invoice posting buffer during line preparation.
    /// </summary>
    /// <param name="SalesLine">The sales line being processed.</param>
    /// <param name="SalesLineACY">The sales line in additional currency.</param>
    /// <param name="InvoicePostingBuffer">The invoice posting buffer being populated.</param>
    /// <param name="TotalVAT">The total VAT amount in local currency.</param>
    /// <param name="TotalVATACY">The total VAT amount in additional currency.</param>
    /// <param name="TotalAmount">The total amount in local currency.</param>
    /// <param name="TotalAmountACY">The total amount in additional currency.</param>
    /// <param name="TotalVATBase">The total VAT base amount in local currency.</param>
    /// <param name="TotalVATBaseACY">The total VAT base amount in additional currency.</param>
    /// <param name="IsHandled">Set to true to skip the default amount setting logic.</param>
    [IntegrationEvent(false, false)]
    local procedure OnPrepareLineOnBeforeSetAmounts(SalesLine: Record "Sales Line"; SalesLineACY: Record "Sales Line"; var InvoicePostingBuffer: Record "Invoice Posting Buffer"; var TotalVAT: Decimal; var TotalVATACY: Decimal; var TotalAmount: Decimal; var TotalAmountACY: Decimal; var TotalVATBase: Decimal; var TotalVATBaseACY: Decimal; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Runs the OnPrepareLineOnAfterSetInvoiceDiscAccount integration event.
    /// </summary>
    /// <param name="SalesLine">The sales line being processed.</param>
    /// <param name="GenPostingSetup">The general posting setup used.</param>
    /// <param name="InvoicePostingBuffer">The invoice posting buffer being populated.</param>
    /// <param name="TempInvoicePostingBuffer">The temporary invoice posting buffer.</param>
    procedure RunOnPrepareLineOnAfterSetInvoiceDiscAccount(SalesLine: Record "Sales Line"; GenPostingSetup: Record "General Posting Setup"; var InvoicePostingBuffer: Record "Invoice Posting Buffer"; var TempInvoicePostingBuffer: Record "Invoice Posting Buffer" temporary)
    begin
        OnPrepareLineOnAfterSetInvoiceDiscAccount(SalesLine, GenPostingSetup, InvoicePostingBuffer, TempInvoicePostingBuffer);
    end;

    /// <summary>
    /// Raised after setting the invoice discount account during line preparation.
    /// </summary>
    /// <param name="SalesLine">The sales line being processed.</param>
    /// <param name="GenPostingSetup">The general posting setup used.</param>
    /// <param name="InvoicePostingBuffer">The invoice posting buffer being populated.</param>
    /// <param name="TempInvoicePostingBuffer">The temporary invoice posting buffer.</param>
    [IntegrationEvent(false, false)]
    local procedure OnPrepareLineOnAfterSetInvoiceDiscAccount(SalesLine: Record "Sales Line"; GenPostingSetup: Record "General Posting Setup"; var InvoicePostingBuffer: Record "Invoice Posting Buffer"; var TempInvoicePostingBuffer: Record "Invoice Posting Buffer" temporary)
    begin
    end;

    /// <summary>
    /// Runs the OnPrepareLineOnAfterSetLineDiscAccount integration event.
    /// </summary>
    /// <param name="SalesLine">The sales line being processed.</param>
    /// <param name="GenPostingSetup">The general posting setup used.</param>
    /// <param name="InvoicePostingBuffer">The invoice posting buffer being populated.</param>
    /// <param name="TempInvoicePostingBuffer">The temporary invoice posting buffer.</param>
    procedure RunOnPrepareLineOnAfterSetLineDiscAccount(SalesLine: Record "Sales Line"; GenPostingSetup: Record "General Posting Setup"; var InvoicePostingBuffer: Record "Invoice Posting Buffer"; var TempInvoicePostingBuffer: Record "Invoice Posting Buffer" temporary)
    begin
        OnPrepareLineOnAfterSetLineDiscAccount(SalesLine, GenPostingSetup, InvoicePostingBuffer, TempInvoicePostingBuffer);
    end;

    /// <summary>
    /// Raised after setting the line discount account during line preparation.
    /// </summary>
    /// <param name="SalesLine">The sales line being processed.</param>
    /// <param name="GenPostingSetup">The general posting setup used.</param>
    /// <param name="InvoicePostingBuffer">The invoice posting buffer being populated.</param>
    /// <param name="TempInvoicePostingBuffer">The temporary invoice posting buffer.</param>
    [IntegrationEvent(false, false)]
    local procedure OnPrepareLineOnAfterSetLineDiscAccount(SalesLine: Record "Sales Line"; GenPostingSetup: Record "General Posting Setup"; var InvoicePostingBuffer: Record "Invoice Posting Buffer"; var TempInvoicePostingBuffer: Record "Invoice Posting Buffer" temporary)
    begin
    end;

    /// <summary>
    /// Runs the OnPrepareLineOnBeforeCalcInvoiceDiscountPosting integration event.
    /// </summary>
    /// <param name="TempInvoicePostingBuffer">The temporary invoice posting buffer.</param>
    /// <param name="InvoicePostingBuffer">The invoice posting buffer being populated.</param>
    /// <param name="SalesHeader">The sales header being posted.</param>
    /// <param name="SalesLine">The sales line being processed.</param>
    /// <param name="TotalVAT">The total VAT amount in local currency.</param>
    /// <param name="TotalVATACY">The total VAT amount in additional currency.</param>
    /// <param name="TotalAmount">The total amount in local currency.</param>
    /// <param name="TotalAmountACY">The total amount in additional currency.</param>
    /// <param name="IsHandled">Set to true to skip the default invoice discount calculation.</param>
    procedure RunOnPrepareLineOnBeforeCalcInvoiceDiscountPosting(var TempInvoicePostingBuffer: Record "Invoice Posting Buffer"; var InvoicePostingBuffer: Record "Invoice Posting Buffer"; SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; TotalVAT: Decimal; TotalVATACY: Decimal; TotalAmount: Decimal; TotalAmountACY: Decimal; var IsHandled: Boolean)
    begin
        OnPrepareLineOnBeforeCalcInvoiceDiscountPosting(TempInvoicePostingBuffer, InvoicePostingBuffer, SalesHeader, SalesLine, TotalVAT, TotalVATACY, TotalAmount, TotalAmountACY, IsHandled);
    end;

    /// <summary>
    /// Raised before calculating invoice discount posting during line preparation.
    /// </summary>
    /// <param name="TempInvoicePostingBuffer">The temporary invoice posting buffer.</param>
    /// <param name="InvoicePostingBuffer">The invoice posting buffer being populated.</param>
    /// <param name="SalesHeader">The sales header being posted.</param>
    /// <param name="SalesLine">The sales line being processed.</param>
    /// <param name="TotalVAT">The total VAT amount in local currency.</param>
    /// <param name="TotalVATACY">The total VAT amount in additional currency.</param>
    /// <param name="TotalAmount">The total amount in local currency.</param>
    /// <param name="TotalAmountACY">The total amount in additional currency.</param>
    /// <param name="IsHandled">Set to true to skip the default invoice discount calculation.</param>
    [IntegrationEvent(false, false)]
    local procedure OnPrepareLineOnBeforeCalcInvoiceDiscountPosting(var TempInvoicePostingBuffer: Record "Invoice Posting Buffer"; var InvoicePostingBuffer: Record "Invoice Posting Buffer"; SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; TotalVAT: Decimal; TotalVATACY: Decimal; TotalAmount: Decimal; TotalAmountACY: Decimal; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Runs the OnPrepareLineOnBeforeCalcLineDiscountPosting integration event.
    /// </summary>
    /// <param name="TempInvoicePostingBuffer">The temporary invoice posting buffer.</param>
    /// <param name="InvoicePostingBuffer">The invoice posting buffer being populated.</param>
    /// <param name="SalesHeader">The sales header being posted.</param>
    /// <param name="SalesLine">The sales line being processed.</param>
    /// <param name="TotalVAT">The total VAT amount in local currency.</param>
    /// <param name="TotalVATACY">The total VAT amount in additional currency.</param>
    /// <param name="TotalAmount">The total amount in local currency.</param>
    /// <param name="TotalAmountACY">The total amount in additional currency.</param>
    /// <param name="IsHandled">Set to true to skip the default line discount calculation.</param>
    procedure RunOnPrepareLineOnBeforeCalcLineDiscountPosting(var TempInvoicePostingBuffer: Record "Invoice Posting Buffer"; var InvoicePostingBuffer: Record "Invoice Posting Buffer"; SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; TotalVAT: Decimal; TotalVATACY: Decimal; TotalAmount: Decimal; TotalAmountACY: Decimal; var IsHandled: Boolean)
    begin
        OnPrepareLineOnBeforeCalcLineDiscountPosting(TempInvoicePostingBuffer, InvoicePostingBuffer, SalesHeader, SalesLine, TotalVAT, TotalVATACY, TotalAmount, TotalAmountACY, IsHandled);
    end;

    /// <summary>
    /// Raised before calculating line discount posting during line preparation.
    /// </summary>
    /// <param name="TempInvoicePostingBuffer">The temporary invoice posting buffer.</param>
    /// <param name="InvoicePostingBuffer">The invoice posting buffer being populated.</param>
    /// <param name="SalesHeader">The sales header being posted.</param>
    /// <param name="SalesLine">The sales line being processed.</param>
    /// <param name="TotalVAT">The total VAT amount in local currency.</param>
    /// <param name="TotalVATACY">The total VAT amount in additional currency.</param>
    /// <param name="TotalAmount">The total amount in local currency.</param>
    /// <param name="TotalAmountACY">The total amount in additional currency.</param>
    /// <param name="IsHandled">Set to true to skip the default line discount calculation.</param>
    [IntegrationEvent(false, false)]
    local procedure OnPrepareLineOnBeforeCalcLineDiscountPosting(var TempInvoicePostingBuffer: Record "Invoice Posting Buffer"; var InvoicePostingBuffer: Record "Invoice Posting Buffer"; SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; TotalVAT: Decimal; TotalVATACY: Decimal; TotalAmount: Decimal; TotalAmountACY: Decimal; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Runs the OnPostLinesOnAfterGenJnlLinePost integration event.
    /// </summary>
    /// <param name="GenJnlLine">The general journal line that was posted.</param>
    /// <param name="SalesHeader">The sales header being posted.</param>
    /// <param name="TempInvoicePostingBuffer">The temporary invoice posting buffer for the line.</param>
    /// <param name="GenJnlPostLine">The general journal post line codeunit instance.</param>
    /// <param name="PreviewMode">Indicates whether the posting is in preview mode.</param>
    /// <param name="SuppressCommit">Indicates whether to suppress database commits.</param>
    /// <param name="GLEntryNo">The general ledger entry number that was created.</param>
    procedure RunOnPostLinesOnAfterGenJnlLinePost(var GenJnlLine: Record "Gen. Journal Line"; SalesHeader: Record "Sales Header"; TempInvoicePostingBuffer: Record "Invoice Posting Buffer"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; PreviewMode: Boolean; SuppressCommit: Boolean; GLEntryNo: Integer)
    begin
        OnPostLinesOnAfterGenJnlLinePost(GenJnlLine, SalesHeader, TempInvoicePostingBuffer, GenJnlPostLine, PreviewMode, SuppressCommit, GLEntryNo);
    end;

    /// <summary>
    /// Raised after posting each invoice line to the general journal.
    /// </summary>
    /// <param name="GenJnlLine">The general journal line that was posted.</param>
    /// <param name="SalesHeader">The sales header being posted.</param>
    /// <param name="TempInvoicePostingBuffer">The temporary invoice posting buffer for the line.</param>
    /// <param name="GenJnlPostLine">The general journal post line codeunit instance.</param>
    /// <param name="PreviewMode">Indicates whether the posting is in preview mode.</param>
    /// <param name="SuppressCommit">Indicates whether to suppress database commits.</param>
    /// <param name="GLEntryNo">The general ledger entry number that was created.</param>
    [IntegrationEvent(false, false)]
    local procedure OnPostLinesOnAfterGenJnlLinePost(var GenJnlLine: Record "Gen. Journal Line"; SalesHeader: Record "Sales Header"; TempInvoicePostingBuffer: Record "Invoice Posting Buffer"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; PreviewMode: Boolean; SuppressCommit: Boolean; GLEntryNo: Integer)
    begin
    end;

    /// <summary>
    /// Runs the OnPostLinesOnBeforeGenJnlLinePost integration event.
    /// </summary>
    /// <param name="GenJnlLine">The general journal line to be posted.</param>
    /// <param name="SalesHeader">The sales header being posted.</param>
    /// <param name="TempInvoicePostingBuffer">The temporary invoice posting buffer for the line.</param>
    /// <param name="GenJnlPostLine">The general journal post line codeunit instance.</param>
    /// <param name="PreviewMode">Indicates whether the posting is in preview mode.</param>
    /// <param name="SuppressCommit">Indicates whether to suppress database commits.</param>
    procedure RunOnPostLinesOnBeforeGenJnlLinePost(var GenJnlLine: Record "Gen. Journal Line"; SalesHeader: Record "Sales Header"; TempInvoicePostingBuffer: Record "Invoice Posting Buffer"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; PreviewMode: Boolean; SuppressCommit: Boolean)
    begin
        OnPostLinesOnBeforeGenJnlLinePost(GenJnlLine, SalesHeader, TempInvoicePostingBuffer, GenJnlPostLine, PreviewMode, SuppressCommit);
    end;

    /// <summary>
    /// Raised before posting each invoice line to the general journal.
    /// </summary>
    /// <param name="GenJnlLine">The general journal line to be posted.</param>
    /// <param name="SalesHeader">The sales header being posted.</param>
    /// <param name="TempInvoicePostingBuffer">The temporary invoice posting buffer for the line.</param>
    /// <param name="GenJnlPostLine">The general journal post line codeunit instance.</param>
    /// <param name="PreviewMode">Indicates whether the posting is in preview mode.</param>
    /// <param name="SuppressCommit">Indicates whether to suppress database commits.</param>
    [IntegrationEvent(false, false)]
    local procedure OnPostLinesOnBeforeGenJnlLinePost(var GenJnlLine: Record "Gen. Journal Line"; SalesHeader: Record "Sales Header"; TempInvoicePostingBuffer: Record "Invoice Posting Buffer"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; PreviewMode: Boolean; SuppressCommit: Boolean)
    begin
    end;

    /// <summary>
    /// Runs the OnPostLinesOnBeforeTempInvoicePostingBufferDeleteAll integration event.
    /// </summary>
    /// <param name="SalesHeader">The sales header being posted.</param>
    /// <param name="GenJnlPostLine">The general journal post line codeunit instance.</param>
    /// <param name="TotalSalesLine">The total sales line amounts.</param>
    /// <param name="TotalSalesLineLCY">The total sales line amounts in local currency.</param>
    /// <param name="InvoicePostingParameters">The invoice posting parameters.</param>
    procedure RunOnPostLinesOnBeforeTempInvoicePostingBufferDeleteAll(var SalesHeader: Record "Sales Header"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; var TotalSalesLine: Record "Sales Line"; var TotalSalesLineLCY: Record "Sales Line"; var InvoicePostingParameters: Record "Invoice Posting Parameters")
    begin
        OnPostLinesOnBeforeTempInvoicePostingBufferDeleteAll(SalesHeader, GenJnlPostLine, TotalSalesLine, TotalSalesLineLCY, InvoicePostingParameters);
    end;

    /// <summary>
    /// Raised before deleting all records from the temporary invoice posting buffer.
    /// </summary>
    /// <param name="SalesHeader">The sales header being posted.</param>
    /// <param name="GenJnlPostLine">The general journal post line codeunit instance.</param>
    /// <param name="TotalSalesLine">The total sales line amounts.</param>
    /// <param name="TotalSalesLineLCY">The total sales line amounts in local currency.</param>
    /// <param name="InvoicePostingParameters">The invoice posting parameters.</param>
    [IntegrationEvent(false, false)]
    local procedure OnPostLinesOnBeforeTempInvoicePostingBufferDeleteAll(var SalesHeader: Record "Sales Header"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; var TotalSalesLine: Record "Sales Line"; var TotalSalesLineLCY: Record "Sales Line"; var InvoicePostingParameters: Record "Invoice Posting Parameters")
    begin
    end;

    /// <summary>
    /// Runs the OnPrepareGenJnlLineOnAfterCopyToGenJnlLine integration event.
    /// </summary>
    /// <param name="GenJnlLine">The general journal line being prepared.</param>
    /// <param name="SalesHeader">The sales header being posted.</param>
    /// <param name="InvoicePostingBuffer">The invoice posting buffer containing the source data.</param>
    procedure RunOnPrepareGenJnlLineOnAfterCopyToGenJnlLine(var GenJnlLine: Record "Gen. Journal Line"; SalesHeader: Record "Sales Header"; InvoicePostingBuffer: Record "Invoice Posting Buffer")
    begin
        OnPrepareGenJnlLineOnAfterCopyToGenJnlLine(GenJnlLine, SalesHeader, InvoicePostingBuffer);
    end;

    /// <summary>
    /// Raised after copying data to the general journal line during preparation.
    /// </summary>
    /// <param name="GenJnlLine">The general journal line being prepared.</param>
    /// <param name="SalesHeader">The sales header being posted.</param>
    /// <param name="InvoicePostingBuffer">The invoice posting buffer containing the source data.</param>
    [IntegrationEvent(false, false)]
    local procedure OnPrepareGenJnlLineOnAfterCopyToGenJnlLine(var GenJnlLine: Record "Gen. Journal Line"; SalesHeader: Record "Sales Header"; InvoicePostingBuffer: Record "Invoice Posting Buffer")
    begin
    end;

    /// <summary>
    /// Runs the OnPrepareLineOnAfterSetInvoiceDiscountPosting integration event.
    /// </summary>
    /// <param name="SalesHeader">The sales header being posted.</param>
    /// <param name="SalesLine">The sales line being processed.</param>
    /// <param name="InvoiceDiscountPosting">Indicates whether invoice discount will be posted.</param>
    procedure RunOnPrepareLineOnAfterSetInvoiceDiscountPosting(SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; var InvoiceDiscountPosting: Boolean)
    begin
        OnPrepareLineOnAfterSetInvoiceDiscountPosting(SalesHeader, SalesLine, InvoiceDiscountPosting);
    end;

    /// <summary>
    /// Raised after determining whether to post invoice discount during line preparation.
    /// </summary>
    /// <param name="SalesHeader">The sales header being posted.</param>
    /// <param name="SalesLine">The sales line being processed.</param>
    /// <param name="InvoiceDiscountPosting">Indicates whether invoice discount will be posted.</param>
    [IntegrationEvent(false, false)]
    local procedure OnPrepareLineOnAfterSetInvoiceDiscountPosting(SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; var InvoiceDiscountPosting: Boolean)
    begin
    end;

    /// <summary>
    /// Runs the OnPrepareLineOnAfterSetLineDiscountPosting integration event.
    /// </summary>
    /// <param name="SalesHeader">The sales header being posted.</param>
    /// <param name="SalesLine">The sales line being processed.</param>
    /// <param name="LineDiscountPosting">Indicates whether line discount will be posted.</param>
    procedure RunOnPrepareLineOnAfterSetLineDiscountPosting(SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; var LineDiscountPosting: Boolean)
    begin
        OnPrepareLineOnAfterSetLineDiscountPosting(SalesHeader, SalesLine, LineDiscountPosting);
    end;

    /// <summary>
    /// Raised after determining whether to post line discount during line preparation.
    /// </summary>
    /// <param name="SalesHeader">The sales header being posted.</param>
    /// <param name="SalesLine">The sales line being processed.</param>
    /// <param name="LineDiscountPosting">Indicates whether line discount will be posted.</param>
    [IntegrationEvent(false, false)]
    local procedure OnPrepareLineOnAfterSetLineDiscountPosting(SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; var LineDiscountPosting: Boolean)
    begin
    end;

    /// <summary>
    /// Runs the OnPrepareLineOnAfterPrepareDeferralLine integration event.
    /// </summary>
    /// <param name="SalesLine">The sales line being processed.</param>
    /// <param name="InvoicePostingBuffer">The invoice posting buffer being populated.</param>
    /// <param name="UseDate">The date to use for the deferral.</param>
    /// <param name="InvDefLineNo">The invoice deferral line number.</param>
    /// <param name="DeferralLineNo">The deferral line number.</param>
    /// <param name="SuppressCommit">Indicates whether to suppress database commits.</param>
    procedure RunOnPrepareLineOnAfterPrepareDeferralLine(SalesLine: Record "Sales Line"; InvoicePostingBuffer: Record "Invoice Posting Buffer"; UseDate: Date; InvDefLineNo: Integer; DeferralLineNo: Integer; SuppressCommit: Boolean)
    begin
        OnPrepareLineOnAfterPrepareDeferralLine(SalesLine, InvoicePostingBuffer, UseDate, InvDefLineNo, DeferralLineNo, SuppressCommit);
    end;

    /// <summary>
    /// Raised after preparing the deferral line during line preparation.
    /// </summary>
    /// <param name="SalesLine">The sales line being processed.</param>
    /// <param name="InvoicePostingBuffer">The invoice posting buffer being populated.</param>
    /// <param name="UseDate">The date to use for the deferral.</param>
    /// <param name="InvDefLineNo">The invoice deferral line number.</param>
    /// <param name="DeferralLineNo">The deferral line number.</param>
    /// <param name="SuppressCommit">Indicates whether to suppress database commits.</param>
    [IntegrationEvent(false, false)]
    local procedure OnPrepareLineOnAfterPrepareDeferralLine(SalesLine: Record "Sales Line"; InvoicePostingBuffer: Record "Invoice Posting Buffer"; UseDate: Date; InvDefLineNo: Integer; DeferralLineNo: Integer; SuppressCommit: Boolean)
    begin
    end;

    /// <summary>
    /// Runs the OnPrepareLineOnAfterUpdateInvoicePostingBuffer integration event.
    /// </summary>
    /// <param name="SalesHeader">The sales header being posted.</param>
    /// <param name="SalesLine">The sales line being processed.</param>
    /// <param name="InvoicePostingBuffer">The invoice posting buffer that was updated.</param>
    /// <param name="TempInvoicePostingBuffer">The temporary invoice posting buffer.</param>
    procedure RunOnPrepareLineOnAfterUpdateInvoicePostingBuffer(SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; var InvoicePostingBuffer: Record "Invoice Posting Buffer"; var TempInvoicePostingBuffer: Record "Invoice Posting Buffer" temporary)
    begin
        OnPrepareLineOnAfterUpdateInvoicePostingBuffer(SalesHeader, SalesLine, InvoicePostingBuffer, TempInvoicePostingBuffer);
    end;

    /// <summary>
    /// Raised after updating the invoice posting buffer during line preparation.
    /// </summary>
    /// <param name="SalesHeader">The sales header being posted.</param>
    /// <param name="SalesLine">The sales line being processed.</param>
    /// <param name="InvoicePostingBuffer">The invoice posting buffer that was updated.</param>
    /// <param name="TempInvoicePostingBuffer">The temporary invoice posting buffer.</param>
    [IntegrationEvent(false, false)]
    local procedure OnPrepareLineOnAfterUpdateInvoicePostingBuffer(SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; var InvoicePostingBuffer: Record "Invoice Posting Buffer"; var TempInvoicePostingBuffer: Record "Invoice Posting Buffer" temporary)
    begin
    end;

    /// <summary>
    /// Runs the OnPrepareLineOnBeforePrepareDeferralLine integration event.
    /// </summary>
    /// <param name="SalesLine">The sales line being processed.</param>
    /// <param name="InvoicePostingBuffer">The invoice posting buffer being populated.</param>
    /// <param name="UseDate">The date to use for the deferral.</param>
    /// <param name="InvDefLineNo">The invoice deferral line number.</param>
    /// <param name="DeferralLineNo">The deferral line number.</param>
    /// <param name="SuppressCommit">Indicates whether to suppress database commits.</param>
    /// <param name="DeferralAccount">The deferral account to use.</param>
    /// <param name="SalesAccount">The sales account to use.</param>
    procedure RunOnPrepareLineOnBeforePrepareDeferralLine(SalesLine: Record "Sales Line"; InvoicePostingBuffer: Record "Invoice Posting Buffer"; UseDate: Date; InvDefLineNo: Integer; DeferralLineNo: Integer; SuppressCommit: Boolean; var DeferralAccount: Code[20]; var SalesAccount: Code[20])
    begin
        OnPrepareLineOnBeforePrepareDeferralLine(SalesLine, InvoicePostingBuffer, UseDate, InvDefLineNo, DeferralLineNo, SuppressCommit, DeferralAccount, SalesAccount);
    end;

    /// <summary>
    /// Raised before preparing the deferral line during line preparation.
    /// </summary>
    /// <param name="SalesLine">The sales line being processed.</param>
    /// <param name="InvoicePostingBuffer">The invoice posting buffer being populated.</param>
    /// <param name="UseDate">The date to use for the deferral.</param>
    /// <param name="InvDefLineNo">The invoice deferral line number.</param>
    /// <param name="DeferralLineNo">The deferral line number.</param>
    /// <param name="SuppressCommit">Indicates whether to suppress database commits.</param>
    /// <param name="DeferralAccount">The deferral account to use.</param>
    /// <param name="SalesAccount">The sales account to use.</param>
    [IntegrationEvent(false, false)]
    local procedure OnPrepareLineOnBeforePrepareDeferralLine(SalesLine: Record "Sales Line"; InvoicePostingBuffer: Record "Invoice Posting Buffer"; UseDate: Date; InvDefLineNo: Integer; DeferralLineNo: Integer; SuppressCommit: Boolean; var DeferralAccount: Code[20]; var SalesAccount: Code[20])
    begin
    end;

    /// <summary>
    /// Runs the OnPrepareLineOnBeforePrepareSales integration event.
    /// </summary>
    /// <param name="SalesHeader">The sales header being posted.</param>
    /// <param name="SalesLine">The sales line being processed.</param>
    /// <param name="GeneralPostingSetup">The general posting setup to be used.</param>
    procedure RunOnPrepareLineOnBeforePrepareSales(SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; var GeneralPostingSetup: Record "General Posting Setup")
    begin
        OnPrepareLineOnBeforePrepareSales(SalesHeader, SalesLine, GeneralPostingSetup);
    end;

    /// <summary>
    /// Raised before preparing sales posting setup during line preparation.
    /// </summary>
    /// <param name="SalesHeader">The sales header being posted.</param>
    /// <param name="SalesLine">The sales line being processed.</param>
    /// <param name="GeneralPostingSetup">The general posting setup to be used.</param>
    [IntegrationEvent(false, false)]
    local procedure OnPrepareLineOnBeforePrepareSales(SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; var GeneralPostingSetup: Record "General Posting Setup")
    begin
    end;

    /// <summary>
    /// Runs the OnPrepareLineOnBeforeSetInvoiceDiscAccount integration event.
    /// </summary>
    /// <param name="SalesLine">The sales line being processed.</param>
    /// <param name="GenPostingSetup">The general posting setup used.</param>
    /// <param name="InvDiscAccount">The invoice discount account to be set.</param>
    /// <param name="IsHandled">Set to true to skip the default account setting logic.</param>
    procedure RunOnPrepareLineOnBeforeSetInvoiceDiscAccount(SalesLine: Record "Sales Line"; GenPostingSetup: Record "General Posting Setup"; var InvDiscAccount: Code[20]; var IsHandled: Boolean)
    begin
        OnPrepareLineOnBeforeSetInvoiceDiscAccount(SalesLine, GenPostingSetup, InvDiscAccount, IsHandled);
    end;

    /// <summary>
    /// Raised before setting the invoice discount account during line preparation.
    /// </summary>
    /// <param name="SalesLine">The sales line being processed.</param>
    /// <param name="GenPostingSetup">The general posting setup used.</param>
    /// <param name="InvDiscAccount">The invoice discount account to be set.</param>
    /// <param name="IsHandled">Set to true to skip the default account setting logic.</param>
    [IntegrationEvent(false, false)]
    local procedure OnPrepareLineOnBeforeSetInvoiceDiscAccount(SalesLine: Record "Sales Line"; GenPostingSetup: Record "General Posting Setup"; var InvDiscAccount: Code[20]; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Runs the OnPrepareLineOnBeforeSetLineDiscAccount integration event.
    /// </summary>
    /// <param name="SalesLine">The sales line being processed.</param>
    /// <param name="GenPostingSetup">The general posting setup used.</param>
    /// <param name="InvDiscAccount">The line discount account to be set.</param>
    /// <param name="IsHandled">Set to true to skip the default account setting logic.</param>
    procedure RunOnPrepareLineOnBeforeSetLineDiscAccount(SalesLine: Record "Sales Line"; GenPostingSetup: Record "General Posting Setup"; var InvDiscAccount: Code[20]; var IsHandled: Boolean)
    begin
        OnPrepareLineOnBeforeSetLineDiscAccount(SalesLine, GenPostingSetup, InvDiscAccount, IsHandled);
    end;

    /// <summary>
    /// Raised before setting the line discount account during line preparation.
    /// </summary>
    /// <param name="SalesLine">The sales line being processed.</param>
    /// <param name="GenPostingSetup">The general posting setup used.</param>
    /// <param name="InvDiscAccount">The line discount account to be set.</param>
    /// <param name="IsHandled">Set to true to skip the default account setting logic.</param>
    [IntegrationEvent(false, false)]
    local procedure OnPrepareLineOnBeforeSetLineDiscAccount(SalesLine: Record "Sales Line"; GenPostingSetup: Record "General Posting Setup"; var InvDiscAccount: Code[20]; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Runs the OnPrepareLineOnBeforeInvoicePostingBufferSetAccount integration event.
    /// </summary>
    /// <param name="InvoicePostingBuffer">The invoice posting buffer being populated.</param>
    /// <param name="SalesLine">The sales line being processed.</param>
    /// <param name="GeneralPostingSetup">The general posting setup used.</param>
    /// <param name="InvDiscAccount">The invoice discount account.</param>
    /// <param name="TotalVAT">The total VAT amount in local currency.</param>
    /// <param name="TotalVATACY">The total VAT amount in additional currency.</param>
    /// <param name="TotalAmount">The total amount in local currency.</param>
    /// <param name="TotalAmountACY">The total amount in additional currency.</param>
    /// <param name="IsHandled">Set to true to skip the default account setting logic.</param>
    procedure RunOnPrepareLineOnBeforeInvoicePostingBufferSetAccount(var InvoicePostingBuffer: Record "Invoice Posting Buffer"; var SalesLine: Record "Sales Line"; var GeneralPostingSetup: Record "General Posting Setup"; var InvDiscAccount: Code[20]; var TotalVAT: Decimal; var TotalVATACY: Decimal; var TotalAmount: Decimal; var TotalAmountACY: Decimal; var IsHandled: Boolean)
    begin
        OnPrepareLineOnBeforeInvoicePostingBufferSetAccount(InvoicePostingBuffer, SalesLine, GeneralPostingSetup, InvDiscAccount, TotalVAT, TotalVATACY, TotalAmount, TotalAmountACY, IsHandled);
    end;

    /// <summary>
    /// Raised before setting the account on the invoice posting buffer during line preparation.
    /// </summary>
    /// <param name="InvoicePostingBuffer">The invoice posting buffer being populated.</param>
    /// <param name="SalesLine">The sales line being processed.</param>
    /// <param name="GeneralPostingSetup">The general posting setup used.</param>
    /// <param name="InvDiscAccount">The invoice discount account.</param>
    /// <param name="TotalVAT">The total VAT amount in local currency.</param>
    /// <param name="TotalVATACY">The total VAT amount in additional currency.</param>
    /// <param name="TotalAmount">The total amount in local currency.</param>
    /// <param name="TotalAmountACY">The total amount in additional currency.</param>
    /// <param name="IsHandled">Set to true to skip the default account setting logic.</param>
    [IntegrationEvent(false, false)]
    procedure OnPrepareLineOnBeforeInvoicePostingBufferSetAccount(var InvoicePostingBuffer: Record "Invoice Posting Buffer"; var SalesLine: Record "Sales Line"; var GeneralPostingSetup: Record "General Posting Setup"; var InvDiscAccount: Code[20]; var TotalVAT: Decimal; var TotalVATACY: Decimal; var TotalAmount: Decimal; var TotalAmountACY: Decimal; var IsHandled: Boolean)
    begin
    end;

    // Prepare Deferral Line

    /// <summary>
    /// Runs the OnPrepareDeferralLineOnBeforePrepareInitialAmounts integration event.
    /// </summary>
    /// <param name="DeferralPostBuffer">The deferral posting buffer being populated.</param>
    /// <param name="SalesHeader">The sales header being posted.</param>
    /// <param name="SalesLine">The sales line being processed.</param>
    /// <param name="AmountLCY">The amount in local currency.</param>
    /// <param name="AmountACY">The amount in additional currency.</param>
    /// <param name="RemainAmtToDefer">The remaining amount to defer in local currency.</param>
    /// <param name="RemainAmtToDeferACY">The remaining amount to defer in additional currency.</param>
    /// <param name="DeferralAccount">The deferral account to use.</param>
    /// <param name="SalesAccount">The sales account to use.</param>
    procedure RunOnPrepareDeferralLineOnBeforePrepareInitialAmounts(var DeferralPostBuffer: Record "Deferral Posting Buffer"; SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; AmountLCY: Decimal; AmountACY: Decimal; RemainAmtToDefer: Decimal; RemainAmtToDeferACY: Decimal; DeferralAccount: Code[20]; SalesAccount: Code[20])
    begin
        OnPrepareDeferralLineOnBeforePrepareInitialAmounts(DeferralPostBuffer, SalesHeader, SalesLine, AmountLCY, AmountACY, RemainAmtToDefer, RemainAmtToDeferACY, DeferralAccount, SalesAccount);
    end;

    /// <summary>
    /// Raised before preparing initial amounts for deferral line posting.
    /// </summary>
    /// <param name="DeferralPostBuffer">The deferral posting buffer being populated.</param>
    /// <param name="SalesHeader">The sales header being posted.</param>
    /// <param name="SalesLine">The sales line being processed.</param>
    /// <param name="AmountLCY">The amount in local currency.</param>
    /// <param name="AmountACY">The amount in additional currency.</param>
    /// <param name="RemainAmtToDefer">The remaining amount to defer in local currency.</param>
    /// <param name="RemainAmtToDeferACY">The remaining amount to defer in additional currency.</param>
    /// <param name="DeferralAccount">The deferral account to use.</param>
    /// <param name="SalesAccount">The sales account to use.</param>
    [IntegrationEvent(false, false)]
    local procedure OnPrepareDeferralLineOnBeforePrepareInitialAmounts(var DeferralPostBuffer: Record "Deferral Posting Buffer"; SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; AmountLCY: Decimal; AmountACY: Decimal; RemainAmtToDefer: Decimal; RemainAmtToDeferACY: Decimal; DeferralAccount: Code[20]; SalesAccount: Code[20])
    begin
    end;

    // Calc Deferral Amount

    /// <summary>
    /// Runs the OnCalcDeferralAmountsOnBeforeTempDeferralHeaderInsert integration event.
    /// </summary>
    /// <param name="TempDeferralHeader">The temporary deferral header to be inserted.</param>
    /// <param name="DeferralHeader">The source deferral header.</param>
    /// <param name="SalesLine">The sales line associated with the deferral.</param>
    procedure RunOnCalcDeferralAmountsOnBeforeTempDeferralHeaderInsert(var TempDeferralHeader: Record "Deferral Header" temporary; DeferralHeader: Record "Deferral Header"; SalesLine: Record "Sales Line")
    begin
        OnCalcDeferralAmountsOnBeforeTempDeferralHeaderInsert(TempDeferralHeader, DeferralHeader, SalesLine);
    end;

    // Invoice Posting Buffer

    /// <summary>
    /// Raised before inserting a temporary deferral header during deferral amount calculation.
    /// </summary>
    /// <param name="TempDeferralHeader">The temporary deferral header to be inserted.</param>
    /// <param name="DeferralHeader">The source deferral header.</param>
    /// <param name="SalesLine">The sales line associated with the deferral.</param>
    [IntegrationEvent(false, false)]
    local procedure OnCalcDeferralAmountsOnBeforeTempDeferralHeaderInsert(var TempDeferralHeader: Record "Deferral Header" temporary; DeferralHeader: Record "Deferral Header"; SalesLine: Record "Sales Line")
    begin
    end;

    /// <summary>
    /// Runs the OnAfterPrepareInvoicePostingBuffer integration event.
    /// </summary>
    /// <param name="SalesLine">The sales line being processed.</param>
    /// <param name="InvoicePostingBuffer">The invoice posting buffer that was prepared.</param>
    procedure RunOnAfterPrepareInvoicePostingBuffer(var SalesLine: Record "Sales Line"; var InvoicePostingBuffer: Record "Invoice Posting Buffer")
    begin
        OnAfterPrepareInvoicePostingBuffer(SalesLine, InvoicePostingBuffer);
    end;

    /// <summary>
    /// Raised after preparing the invoice posting buffer for a sales line.
    /// </summary>
    /// <param name="SalesLine">The sales line being processed.</param>
    /// <param name="InvoicePostingBuffer">The invoice posting buffer that was prepared.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterPrepareInvoicePostingBuffer(var SalesLine: Record "Sales Line"; var InvoicePostingBuffer: Record "Invoice Posting Buffer")
    begin
    end;

    /// <summary>
    /// Runs the OnBeforePrepareInvoicePostingBuffer integration event.
    /// </summary>
    /// <param name="SalesLine">The sales line to be processed.</param>
    /// <param name="InvoicePostingBuffer">The invoice posting buffer to be prepared.</param>
    procedure RunOnBeforePrepareInvoicePostingBuffer(var SalesLine: Record "Sales Line"; var InvoicePostingBuffer: Record "Invoice Posting Buffer")
    begin
        OnBeforePrepareInvoicePostingBuffer(SalesLine, InvoicePostingBuffer);
    end;

    /// <summary>
    /// Raised before preparing the invoice posting buffer for a sales line.
    /// </summary>
    /// <param name="SalesLine">The sales line to be processed.</param>
    /// <param name="InvoicePostingBuffer">The invoice posting buffer to be prepared.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforePrepareInvoicePostingBuffer(var SalesLine: Record "Sales Line"; var InvoicePostingBuffer: Record "Invoice Posting Buffer")
    begin
    end;

    /// <summary>
    /// Runs the OnPrepareDeferralLineOnBeforeDeferralPostingBufferUpdate integration event.
    /// </summary>
    /// <param name="DeferralPostBuffer">The deferral posting buffer to be updated.</param>
    /// <param name="TempDeferralLine">The temporary deferral line being processed.</param>
    /// <param name="AmountToDefer">The amount to defer.</param>
    procedure RunOnPrepareDeferralLineOnBeforeDeferralPostingBufferUpdate(var DeferralPostBuffer: Record "Deferral Posting Buffer"; var TempDeferralLine: Record "Deferral Line"; var AmountToDefer: Decimal)
    begin
        OnPrepareDeferralLineOnBeforeDeferralPostingBufferUpdate(DeferralPostBuffer, TempDeferralLine, AmountToDefer);
    end;

    /// <summary>
    /// Raised before updating the deferral posting buffer during deferral line preparation.
    /// </summary>
    /// <param name="DeferralPostBuffer">The deferral posting buffer to be updated.</param>
    /// <param name="TempDeferralLine">The temporary deferral line being processed.</param>
    /// <param name="AmountToDefer">The amount to defer.</param>
    [IntegrationEvent(false, false)]
    local procedure OnPrepareDeferralLineOnBeforeDeferralPostingBufferUpdate(var DeferralPostBuffer: Record "Deferral Posting Buffer"; var TempDeferralLine: Record "Deferral Line"; var AmountToDefer: Decimal)
    begin
    end;

    /// <summary>
    /// Runs the OnAfterPrepareDeferralLine integration event.
    /// </summary>
    /// <param name="DeferralPostBuffer">The deferral posting buffer that was prepared.</param>
    /// <param name="SalesHeader">The sales header being posted.</param>
    /// <param name="SalesLine">The sales line being processed.</param>
    /// <param name="GenJnlLineDocNo">The general journal line document number.</param>
    /// <param name="DeferralAccount">The deferral account used.</param>
    /// <param name="SalesAccount">The sales account used.</param>
    /// <param name="InvDefLineNo">The invoice deferral line number.</param>
    /// <param name="DeferralLineNo">The deferral line number.</param>
    /// <param name="AmountToDefer">The amount being deferred.</param>
    procedure RunOnAfterPrepareDeferralLine(var DeferralPostBuffer: Record "Deferral Posting Buffer"; var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; GenJnlLineDocNo: Code[20]; DeferralAccount: Code[20]; SalesAccount: Code[20]; InvDefLineNo: Integer; DeferralLineNo: Integer; var AmountToDefer: Decimal)
    begin
        OnAfterPrepareDeferralLine(DeferralPostBuffer, SalesHeader, SalesLine, GenJnlLineDocNo, DeferralAccount, SalesAccount, InvDefLineNo, DeferralLineNo, AmountToDefer);
    end;

    /// <summary>
    /// Raised after preparing a deferral line for posting.
    /// </summary>
    /// <param name="DeferralPostBuffer">The deferral posting buffer that was prepared.</param>
    /// <param name="SalesHeader">The sales header being posted.</param>
    /// <param name="SalesLine">The sales line being processed.</param>
    /// <param name="GenJnlLineDocNo">The general journal line document number.</param>
    /// <param name="DeferralAccount">The deferral account used.</param>
    /// <param name="SalesAccount">The sales account used.</param>
    /// <param name="InvDefLineNo">The invoice deferral line number.</param>
    /// <param name="DeferralLineNo">The deferral line number.</param>
    /// <param name="AmountToDefer">The amount being deferred.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterPrepareDeferralLine(var DeferralPostBuffer: Record "Deferral Posting Buffer"; var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; GenJnlLineDocNo: Code[20]; DeferralAccount: Code[20]; SalesAccount: Code[20]; InvDefLineNo: Integer; DeferralLineNo: Integer; var AmountToDefer: Decimal)
    begin
    end;

    internal procedure RunOnBeforeUpdateInvoicePostingBuffer(var TempInvoicePostingBuffer: Record "Invoice Posting Buffer" temporary; InvoicePostingBuffer: Record "Invoice Posting Buffer"; ForceGLAccountType: Boolean; var InvDefLineNo: Integer; var DeferralLineNo: Integer; var FALineNo: Integer; SalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
        OnBeforeUpdateInvoicePostingBuffer(TempInvoicePostingBuffer, InvoicePostingBuffer, ForceGLAccountType, InvDefLineNo, DeferralLineNo, FALineNo, SalesLine, IsHandled);
    end;

    /// <summary>
    /// Raised before updating the invoice posting buffer with new data.
    /// </summary>
    /// <param name="TempInvoicePostingBuffer">The temporary invoice posting buffer to update.</param>
    /// <param name="InvoicePostingBuffer">The source invoice posting buffer.</param>
    /// <param name="ForceGLAccountType">Indicates whether to force G/L account type.</param>
    /// <param name="InvDefLineNo">The invoice deferral line number.</param>
    /// <param name="DeferralLineNo">The deferral line number.</param>
    /// <param name="FALineNo">The fixed asset line number.</param>
    /// <param name="SalesLine">The sales line being processed.</param>
    /// <param name="IsHandled">Set to true to skip the default update logic.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateInvoicePostingBuffer(var TempInvoicePostingBuffer: Record "Invoice Posting Buffer" temporary; InvoicePostingBuffer: Record "Invoice Posting Buffer"; ForceGLAccountType: Boolean; var InvDefLineNo: Integer; var DeferralLineNo: Integer; var FALineNo: Integer; SalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    internal procedure RunOnPostLinesOnAfterPostJobSalesLines(var SalesHeader: Record "Sales Header"; var TempInvoicePostingBuffer: Record "Invoice Posting Buffer" temporary; var TotalSalesLine: Record "Sales Line"; var TotalSalesLineLCY: Record "Sales Line"; var GLEntryNo: Integer; var InvoicePostingParameters: Record "Invoice Posting Parameters")
    begin
        OnPostLinesOnAfterPostJobSalesLines(SalesHeader, TempInvoicePostingBuffer, TotalSalesLine, TotalSalesLineLCY, GLEntryNo, InvoicePostingParameters);
    end;

    /// <summary>
    /// Raised after posting job-related sales lines during invoice line posting.
    /// </summary>
    /// <param name="SalesHeader">The sales header being posted.</param>
    /// <param name="TempInvoicePostingBuffer">The temporary invoice posting buffer.</param>
    /// <param name="TotalSalesLine">The total sales line amounts.</param>
    /// <param name="TotalSalesLineLCY">The total sales line amounts in local currency.</param>
    /// <param name="GLEntryNo">The general ledger entry number.</param>
    /// <param name="InvoicePostingParameters">The invoice posting parameters.</param>
    [IntegrationEvent(false, false)]
    local procedure OnPostLinesOnAfterPostJobSalesLines(var SalesHeader: Record "Sales Header"; var TempInvoicePostingBuffer: Record "Invoice Posting Buffer" temporary; var TotalSalesLine: Record "Sales Line"; var TotalSalesLineLCY: Record "Sales Line"; var GLEntryNo: Integer; var InvoicePostingParameters: Record "Invoice Posting Parameters")
    begin
    end;
}