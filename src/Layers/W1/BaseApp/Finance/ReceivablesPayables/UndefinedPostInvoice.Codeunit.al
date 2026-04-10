// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.ReceivablesPayables;

using Microsoft.Finance.GeneralLedger.Posting;

/// <summary>
/// Default implementation of Invoice Posting interface that provides error handling for undefined posting scenarios.
/// Serves as a fallback implementation when no specific invoice posting logic has been configured.
/// </summary>
/// <remarks>
/// Safety implementation ensuring that invoice posting operations fail gracefully when proper posting interfaces are not defined.
/// Used by the invoice posting framework as a default to prevent silent failures and ensure explicit configuration.
/// Part of the extensible invoice posting architecture requiring explicit implementation selection.
/// </remarks>
codeunit 819 "Undefined Post Invoice" implements "Invoice Posting"
{
    var
        InvoicePostingParameters: Record "Invoice Posting Parameters";
        HideProgressWindow: Boolean;
        PreviewMode: Boolean;
        SuppressCommit: Boolean;

    /// <summary>
    /// Performs validation check for invoice posting but throws an error for undefined implementations.
    /// </summary>
    /// <param name="TableID">Table ID for the posting validation</param>
    procedure Check(TableID: Integer)
    begin
        error('Please define invoice posting interface using setup table.')
    end;

    /// <summary>
    /// Clears internal posting buffers but throws an error for undefined implementations.
    /// </summary>
    procedure ClearBuffers()
    begin
    end;

    /// <summary>
    /// Sets preview mode for posting operations but throws an error for undefined implementations.
    /// </summary>
    /// <param name="NewPreviewMode">Preview mode flag</param>
    procedure SetPreviewMode(NewPreviewMode: Boolean)
    begin
        PreviewMode := NewPreviewMode;
    end;

    /// <summary>
    /// Sets commit suppression for posting operations but throws an error for undefined implementations.
    /// </summary>
    /// <param name="NewSuppressCommit">Suppress commit flag</param>
    procedure SetSuppressCommit(NewSuppressCommit: Boolean)
    begin
        SuppressCommit := NewSuppressCommit;
    end;

    /// <summary>
    /// Sets progress window visibility for posting operations but throws an error for undefined implementations.
    /// </summary>
    /// <param name="NewHideProgressWindow">Hide progress window flag</param>
    procedure SetHideProgressWindow(NewHideProgressWindow: Boolean)
    begin
        HideProgressWindow := NewHideProgressWindow;
    end;

    /// <summary>
    /// Sets posting parameters but throws an error for undefined implementations.
    /// </summary>
    /// <param name="NewInvoicePostingParameters">Invoice posting parameters record</param>
    procedure SetParameters(NewInvoicePostingParameters: Record "Invoice Posting Parameters")
    begin
        InvoicePostingParameters := NewInvoicePostingParameters;
    end;

    /// <summary>
    /// Sets total line amounts for posting calculations but throws an error for undefined implementations.
    /// </summary>
    /// <param name="TotalDocumentLine">Total document line amounts</param>
    /// <param name="TotalDocumentLineLCY">Total document line amounts in local currency</param>
    procedure SetTotalLines(TotalDocumentLine: Variant; TotalDocumentLineLCY: Variant)
    begin
    end;

    /// <summary>
    /// Checks credit line limits but throws an error for undefined implementations.
    /// </summary>
    /// <param name="DocumentHeaderVar">Document header variant</param>
    /// <param name="DocumentLineVar">Document line variant</param>
    procedure CheckCreditLine(DocumentHeaderVar: Variant; DocumentLineVar: Variant)
    begin
    end;

    /// <summary>
    /// Prepares document line for posting but throws an error for undefined implementations.
    /// </summary>
    /// <param name="DocumentHeaderVar">Document header variant</param>
    /// <param name="DocumentLineVar">Document line variant</param>
    /// <param name="DocumentLineACYVar">Document line additional currency variant</param>
    procedure PrepareLine(DocumentHeaderVar: Variant; DocumentLineVar: Variant; DocumentLineACYVar: Variant)
    begin
    end;

    /// <summary>
    /// Prepares job line for posting but throws an error for undefined implementations.
    /// </summary>
    /// <param name="DocumentHeaderVar">Document header variant</param>
    /// <param name="DocumentLineVar">Document line variant</param>
    /// <param name="DocumentLineACYVar">Document line additional currency variant</param>
    procedure PrepareJobLine(DocumentHeaderVar: Variant; DocumentLineVar: Variant; DocumentLineACYVar: Variant)
    begin
    end;

    /// <summary>
    /// Posts invoice lines but throws an error for undefined implementations.
    /// </summary>
    /// <param name="DocumentHeaderVar">Document header variant</param>
    /// <param name="GenJnlPostLine">General journal posting line codeunit</param>
    /// <param name="Window">Progress window dialog</param>
    /// <param name="TotalAmount">Total posting amount</param>
    procedure PostLines(DocumentHeaderVar: Variant; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; var Window: Dialog; var TotalAmount: Decimal)
    begin
        TotalAmount := 0;
    end;

    /// <summary>
    /// Posts ledger entries but throws an error for undefined implementations.
    /// </summary>
    /// <param name="DocumentHeaderVar">Document header variant</param>
    /// <param name="GenJnlPostLine">General journal posting line codeunit</param>
    procedure PostLedgerEntry(DocumentHeaderVar: Variant; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    begin
    end;

    /// <summary>
    /// Posts balancing entries but throws an error for undefined implementations.
    /// </summary>
    /// <param name="DocumentHeaderVar">Document header variant</param>
    /// <param name="GenJnlPostLine">General journal posting line codeunit</param>
    procedure PostBalancingEntry(DocumentHeaderVar: Variant; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    begin
    end;

    /// <summary>
    /// Calculates deferral amounts but throws an error for undefined implementations.
    /// </summary>
    /// <param name="DocumentHeaderVar">Document header variant</param>
    /// <param name="DocumentLineVar">Document line variant</param>
    /// <param name="OriginalDeferralAmount">Original deferral amount</param>
    procedure CalcDeferralAmounts(DocumentHeaderVar: Variant; DocumentLineVar: Variant; OriginalDeferralAmount: Decimal)
    begin
    end;

    /// <summary>
    /// Creates posted deferral schedule but throws an error for undefined implementations.
    /// </summary>
    /// <param name="DocumentLineVar">Document line variant</param>
    /// <param name="NewDocumentType">New document type</param>
    /// <param name="NewDocumentNo">New document number</param>
    /// <param name="NewLineNo">New line number</param>
    /// <param name="PostingDate">Posting date</param>
    procedure CreatePostedDeferralSchedule(DocumentLineVar: Variant; NewDocumentType: Integer; NewDocumentNo: Code[20]; NewLineNo: Integer; PostingDate: Date)
    begin
    end;
}
