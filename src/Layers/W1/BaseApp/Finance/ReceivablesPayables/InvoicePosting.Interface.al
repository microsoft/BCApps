// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.ReceivablesPayables;

using Microsoft.Finance.GeneralLedger.Posting;

interface "Invoice Posting"
{
    /// <summary>
    /// Check if implementation codeunit designed for source document type posting
    /// </summary>
    procedure Check(TableID: Integer)

    /// <summary>
    /// Clear temporary posting buffers in invoice posting codeunit
    /// </summary>
    procedure ClearBuffers()

    /// <summary>
    /// Check credit limit for document customer
    /// </summary>
    procedure CheckCreditLine(DocumentHeaderVar: Variant; DocumentLineVar: Variant)

    /// <summary>
    /// Set HideProgressWindow variable inside the invoice posting codeunit
    /// </summary>
    procedure SetHideProgressWindow(NewHideProgressWindow: Boolean)

    /// <summary>
    /// Set posting related parameters using temporary table
    /// </summary>
    procedure SetParameters(InvoicePostingParameters: Record "Invoice Posting Parameters")

    /// <summary>
    /// Set PreviewMode variable inside the invoice posting codeunit
    /// </summary>
    procedure SetPreviewMode(NewPreviewMode: Boolean)

    /// <summary>
    /// Set SupressCommit variable inside the invoice posting codeunit
    /// </summary>
    procedure SetSuppressCommit(NewSuppressCommit: Boolean)

    /// <summary>
    /// Set SupressCommit variable inside the invoice posting codeunit
    /// </summary>
    procedure SetTotalLines(TotalDocumentLine: Variant; TotalDocumentLineLCY: Variant)

    /// <summary>
    /// Prepare invoice posting buffer line from source document line
    /// </summary>
    procedure PrepareLine(DocumentHeaderVar: Variant; DocumentLineVar: Variant; DocumentLineACYVar: Variant)

    /// <summary>
    /// Prepare invoice posting buffer line from source document job line
    /// </summary>
    procedure PrepareJobLine(DocumentHeaderVar: Variant; DocumentLineVar: Variant; DocumentLineACYVar: Variant)

    /// <summary>
    /// Process customer or vendor ledger entry.
    /// </summary>
    procedure PostLedgerEntry(DocumentHeaderVar: Variant; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")

    /// <summary>
    /// Process customer or vendor ledger entry.
    /// </summary>
    procedure PostBalancingEntry(DocumentHeaderVar: Variant; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")

    /// <summary>
    /// Process invoice posting buffer and post ledger entries for each record.
    /// </summary>
    procedure PostLines(DocumentHeaderVar: Variant; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; var Window: Dialog; var TotalAmount: Decimal)

    /// <summary>
    /// Calculate deferral amounts for invoice posting buffer
    /// </summary>
    procedure CalcDeferralAmounts(DocumentHeaderVar: Variant; DocumentLineVar: Variant; OriginalDeferralAmount: Decimal)

    /// <summary>
    /// Create deferral schedule for posted documents
    /// </summary>
    procedure CreatePostedDeferralSchedule(DocumentLineVar: Variant; NewDocumentType: Integer; NewDocumentNo: Code[20]; NewLineNo: Integer; PostingDate: Date)
}
