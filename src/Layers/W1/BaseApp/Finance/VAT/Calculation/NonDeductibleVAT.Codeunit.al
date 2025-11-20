// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Calculation;

using Microsoft.Finance.Currency;
using Microsoft.Finance.Deferral;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Finance.VAT.Ledger;
using Microsoft.Finance.VAT.Setup;
using Microsoft.FixedAssets.Ledger;
using Microsoft.Foundation.Enums;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Projects.Project.Journal;

/// <summary>
/// Provides an interface of the Non-Deductible VAT functionality.
/// </summary>
codeunit 6200 "Non-Deductible VAT"
{
    Access = Public;

    var
        NonDedVATImpl: Codeunit "Non-Ded. VAT Impl.";

    /// <summary>
    /// Returns true if the Non-Deductible VAT functionality is enabled
    /// </summary>
    /// <returns>if the feature is fully enabled</returns>
    procedure IsNonDeductibleVATEnabled(): Boolean
    begin
        exit(NonDedVATImpl.IsNonDeductibleVATEnabled());
    end;

    /// <summary>
    /// Returns true if Non-Deductible VAT fields must be shown in document lines
    /// </summary>
    /// <returns>If Non-Deductible VAT fields are visible in documents</returns>
    procedure ShowNonDeductibleVATInLines(): Boolean
    begin
        exit(NonDedVATImpl.ShowNonDeductibleVATInLines());
    end;

    /// <summary>
    /// Returns the non-deductible VAT amount of the current purchase line
    /// </summary>
    /// <param name="PurchLine">The current purchase line</param>
    /// <returns>The non-deductible VAT amount</returns>
    procedure GetNonDeductibleVATAmount(PurchaseLine: Record "Purchase Line"): Decimal
    begin
        exit(NonDedVATImpl.GetNonDeductibleVATAmount(PurchaseLine));
    end;

    /// <summary>
    /// Returns the non-deductible VAT percent for the combination of a VAT Business group, VAT Product group and a certain posting type
    /// </summary>
    /// <param name="VATBusPostGroupCode">The VAT business posting group code</param>
    /// <param name="VATProdPostGroupCode">The VAT product posting group code</param>
    /// <param name="GeneralPostingType">The sales or purchase</param>
    procedure GetNonDeductibleVATPct(VATBusPostGroupCode: Code[20]; VATProdPostGroupCode: Code[20]; GeneralPostingType: Enum "General Posting Type")
    begin
        NonDedVATImpl.GetNonDeductibleVATPct(VATBusPostGroupCode, VATProdPostGroupCode, GeneralPostingType);
    end;

    /// <summary>
    /// Returns the non-deductible VAT percent of the current VAT posting setup
    /// </summary>
    /// <param name="VATPostingSetup">The current VAT posting setup</param>
    /// <returns>The non-deductible VAT percent</returns>
    procedure GetNonDeductibleVATPct(VATPostingSetup: Record "VAT Posting Setup"): Decimal
    begin
        exit(NonDedVATImpl.GetNonDeductibleVATPct(VATPostingSetup, Enum::"General Posting Type"::Purchase));
    end;

    /// <summary>
    /// Returns the non-deductible VAT amount of the current general journal line
    /// </summary>
    /// <param name="GenJournalLine">The current general journal line</param>
    /// <returns>The non-deductible VAT amount</returns>
    procedure GetNonDeductibleVATAmount(GenJournalLine: Record "Gen. Journal Line"): Decimal
    begin
        exit(NonDedVATImpl.GetNonDeductibleVATAmount(GenJournalLine));
    end;

    /// <summary>
    /// Returns the non-deductible VAT percent for deferrals
    /// </summary>
    /// <param name="VATBusPostGroupCode">VAT business posting group code</param>
    /// <param name="VATProdPostGroupCode">VAT product posting group code</param>
    /// <param name="DeferralDocType">Deferral document type</param>
    /// <returns>The non-deductible VAT percent</returns>
    procedure GetNonDeductibleVATPct(VATBusPostGroupCode: Code[20]; VATProdPostGroupCode: Code[20]; DeferralDocType: Enum "Deferral Document Type"): Decimal
    begin
        exit(NonDedVATImpl.GetNonDeductibleVATPct(VATBusPostGroupCode, VATProdPostGroupCode, DeferralDocType));
    end;

    /// <summary>
    /// Returns the Non-Deductible VAT account for deferrals
    /// </summary>
    /// <param name="DeferralDocType">Deferral document type</param>
    /// <param name="PostingGLAccountNo">Default posting G/L account number</param>
    /// <param name="VATPostingSetup">VAT Posting Setup</param>
    /// <returns>The G/L account number</returns>
    procedure GetNonDeductibleVATAccForDeferrals(DeferralDocType: Enum "Deferral Document Type"; PostingGLAccountNo: Code[20]; VATPostingSetup: Record "VAT Posting Setup"): Code[20]
    begin
        exit(NonDedVATImpl.GetNonDeductibleVATAccForDeferrals(DeferralDocType, PostingGLAccountNo, VATPostingSetup));
    end;

    /// <summary>
    /// Get the Non-Deductible VAT amount to add to the item cost
    /// </summary>
    /// <param name="PurchaseLine">The current purchase line</param>
    /// <returns>The Non-Deductible VAT Amount</returns>
    procedure GetNonDeductibleVATAmountForItemCost(PurchaseLine: Record "Purchase Line"): Decimal
    begin
        exit(NonDedVATImpl.GetNonDeductibleVATAmountForItemCost(PurchaseLine));
    end;

    /// <summary>
    /// Get Non-Deductible VAT amount
    /// </summary>
    /// <param name="Amount">The base amount</param>
    /// <param name="NonDeductiblePercent">The Non-Deductible VAT percent</param>
    /// <param name="AmountRoundingPrecision">Amount rounding precision to apply after multiplication</param>
    /// <param name="Rounding">The remainining rounding difference after multiplication</param>
    /// <returns>The Non-Deductible VAT Amount</returns>
    procedure GetNonDeductibleAmount(Amount: Decimal; NonDeductiblePercent: Decimal; AmountRoundingPrecision: Decimal; var Rounding: Decimal) Result: Decimal
    begin
        exit(NonDedVATImpl.GetNonDeductibleAmount(Amount, NonDeductiblePercent, AmountRoundingPrecision, Rounding));
    end;

    /// <summary>
    /// Returns the non-deductible VAT base from the VAT entry in both LCY and ACY
    /// </summary>
    /// <param name="NonDedVATBase">The Non-Deductible VAT base</param>
    /// <param name="NonDedVATBaseACY">The Non-Deductible VAT base in additional currency</param>
    /// <param name="VATEntry">The current purchase line</param>
    procedure GetNonDeductibleVATBaseBothCurrencies(var NonDedVATBase: Decimal; var NonDedVATBaseACY: Decimal; VATEntry: Record "VAT Entry")
    begin
        NonDedVATImpl.GetNonDeductibleVATBaseBothCurrencies(NonDedVATBase, NonDedVATBaseACY, VATEntry);
    end;

    /// <summary>
    /// Sets the non-deductible VAT percent in the purchase line
    /// </summary>
    /// <param name="PurchaseLine">The current purchase line</param>
    procedure SetNonDeductiblePct(var PurchaseLine: Record "Purchase Line")
    begin
        NonDedVATImpl.SetNonDeductiblePct(PurchaseLine);
    end;

    /// <summary>
    /// Set the Non-Deductible VAT amount in the purchase line
    /// </summary>
    /// <param name="PurchaseLine">The current purchase line</param>
    /// <param name="NonDeductibleVATAmount">The Non-Deductible VAT amount to set</param>
    procedure SetNonDedVATAmountInPurchLine(var PurchaseLine: Record "Purchase Line"; NonDeductibleVATAmount: Decimal)
    begin
        NonDedVATImpl.SetNonDedVATAmountInPurchLine(PurchaseLine, NonDeductibleVATAmount);
    end;

    /// <summary>
    /// Set the Non-Deductible VAT difference of the VAT amount line to the purchase line with factor multiplication
    /// </summary>
    /// <param name="PurchaseLine">The current purchase line</param>
    /// <param name="VATAmountLineRemainder">Remainder from rounding to add to the next line</param>
    /// <param name="VATDifference">The Non-Deductible VAT difference to set</param>
    /// <param name="VATAmountLine">The current VAT amount line</param>
    /// <param name="Currency">The currency code of the document</param>
    /// <param name="Part">The numerator for the factor calculation</param>
    /// <param name="Total">The denominator for factor calculation</param>
    procedure SetNonDedVATAmountDiffInPurchLine(var PurchaseLine: Record "Purchase Line"; var VATAmountLineRemainder: Record "VAT Amount Line"; var VATDifference: Decimal; VATAmountLine: Record "VAT Amount Line"; Currency: Record Currency; Part: Decimal; Total: Decimal)
    begin
        NonDedVATImpl.SetNonDedVATAmountDiffInPurchLine(PurchaseLine, VATAmountLineRemainder, VATDifference, VATAmountLine, Currency, Part, Total);
    end;

    /// <summary>
    /// Set Non-Deductible VAT base in the VAT Entry
    /// </summary>
    /// <param name="VATEntry">The current VAT Entry to be updated</param>
    /// <param name="NonDedVATAmount">Non-Deductible VAT amount</param>
    /// <param name="NonDedVATAmountACY">Non-Deductible VAT amount in additional currency</param>
    procedure SetNonDeductibleVATAmount(var VATEntry: Record "VAT Entry"; NonDedVATAmount: Decimal; NonDedVATAmountACY: Decimal)
    begin
        NonDedVATImpl.SetNonDeductibleVATAmount(VATEntry, NonDedVATAmount, NonDedVATAmountACY);
    end;

    /// <summary>
    /// Set Non-Deductible VAT amount in the VAT Entry
    /// </summary>
    /// <param name="VATEntry">The current VAT Entry to be updated</param>
    /// <param name="NonDedVATBase">Non-Deductible VAT base</param>
    /// <param name="NonDedVATBaseACY">Non-Deductible VAT base in additional currency</param>
    procedure SetNonDeductibleVATBase(var VATEntry: Record "VAT Entry"; NonDedVATBase: Decimal; NonDedVATBaseACY: Decimal)
    begin
        NonDedVATImpl.SetNonDeductibleVATBase(VATEntry, NonDedVATBase, NonDedVATBaseACY);
    end;

    /// <summary>
    /// Set Non-Deductible VAT amounts in the invoice posting buffer
    /// </summary>
    /// <param name="InvoicePostingBuffer">The current invoice posting buffer to be updated</param>
    /// <param name="TotalNonDedVATBase">Total Non-Deductible VAT base</param>
    /// <param name="TotalNonDedVATAmount">Total Non-Deductible VAT amount</param>
    /// <param name="TotalNonDedVATBaseACY">Total Non-Deductible VAT base in additional currency</param>
    /// <param name="TotalNonDedVATAmountACY">Total Non-Deductible VAT amount in additional currency</param>
    /// <param name="TotalNonDedVATDiff">Total Non-Deductible VAT difference</param>
    procedure SetNonDeductibleVAT(var InvoicePostingBuffer: Record "Invoice Posting Buffer"; TotalNonDedVATBase: Decimal; TotalNonDedVATAmount: Decimal; TotalNonDedVATBaseACY: Decimal; TotalNonDedVATAmountACY: Decimal; TotalNonDedVATDiff: Decimal)
    begin
        NonDedVATImpl.SetNonDeductibleVAT(InvoicePostingBuffer, TotalNonDedVATBase, TotalNonDedVATAmount, TotalNonDedVATBaseACY, TotalNonDedVATAmountACY, TotalNonDedVATDiff);
    end;

    /// <summary>
    /// Set Non-Deductible VAT amounts in the VAT entry
    /// </summary>
    /// <param name="VATEntry">The current VAT Entry to be updated</param>
    /// <param name="NonDedBase">The Non-Deductible VAT base</param>
    /// <param name="NonDedVATAmount">The Non-Deductible VAT amount</param>
    /// <param name="SrcCurrNonDedBaseAmount">The Non-Deductible VAT base in additional currency</param>
    /// <param name="SrcCurrNonDedVATAmount">The Non-Deductible VAT amount in additional currency</param>
    /// <param name="NonDedVATDiff">The Non-Deductible VAT difference</param>
    /// <param name="NonDedVATDiffACY">The Non-Deductible VAT difference in additional currency</param>  
    procedure SetNonDedVATInVATEntry(var VATEntry: Record "VAT Entry"; NonDedBase: Decimal; NonDedVATAmount: Decimal; SrcCurrNonDedBaseAmount: Decimal; SrcCurrNonDedVATAmount: Decimal; NonDedVATDiff: Decimal; NonDedVATDiffACY: Decimal)
    begin
        NonDedVATImpl.SetNonDedVATInVATEntry(VATEntry, NonDedBase, NonDedVATAmount, SrcCurrNonDedBaseAmount, SrcCurrNonDedVATAmount, NonDedVATDiff, NonDedVATDiffACY);
    end;

    /// <summary>
    /// Initialize the Non-Deductible VAT amount from purchase line
    /// </summary>
    /// <param name="NonDedVATBase">Non-Deductible VAT Base</param>
    /// <param name="NonDedVATAmount">Non-Deductible VAT Amount</param>
    /// <param name="NonDedVATBaseACY">Non-Deductible VAT Base in additional currency</param>
    /// <param name="NonDedVATAmountACY">Non-Deductible VAT Amount in additional currency</param>
    /// <param name="NonDedVATDiff">Non-Deductible VAT Difference</param>
    /// <param name="PurchaseLine">The current purchase line</param>
    /// <param name="PurchaseLineACY">The current purchase line in additional currency</param>
    procedure Init(var NonDedVATBase: Decimal; var NonDedVATAmount: Decimal; var NonDedVATBaseACY: Decimal; var NonDedVATAmountACY: Decimal; var NonDedVATDiff: Decimal; PurchaseLine: Record "Purchase Line"; PurchaseLineACY: Record "Purchase Line")
    begin
        NonDedVATImpl.Init(NonDedVATBase, NonDedVATAmount, NonDedVATBaseACY, NonDedVATAmountACY, NonDedVATDiff, PurchaseLine, PurchaseLineACY);
    end;

    /// <summary>
    /// Clears Non-Deductible VAT difference in the purchase line
    /// </summary>
    /// <param name="PurchaseLine">The current purchase line</param>
    procedure InitNonDeductibleVATDiff(var PurchaseLine: Record "Purchase Line")
    begin
        NonDedVATImpl.InitNonDeductibleVATDiff(PurchaseLine);
    end;

    /// <summary>
    /// Updates the non-deductible VAT base and amount in the purchase line with rounding
    /// </summary>
    /// <param name="PurchaseLine">The current purchase line</param>
    /// <param name="TempVATAmountLineRemainder">Remainder from rounding to add to the next line</param>
    /// <param name="Currency">The currency code of the purchase document</param>
    procedure Update(var PurchaseLine: Record "Purchase Line"; var TempVATAmountLineRemainder: Record "VAT Amount Line" temporary; Currency: Record Currency)
    begin
        NonDedVATImpl.Update(PurchaseLine, TempVATAmountLineRemainder, Currency);
    end;

    /// <summary>
    /// Updates the non-deductible VAT base and amount in the purchase line
    /// </summary>
    /// <param name="PurchaseLine">The current purchase line</param>
    /// <param name="Currency">The currency code of the purchase document</param>
    procedure Update(var PurchaseLine: Record "Purchase Line"; Currency: Record Currency)
    begin
        NonDedVATImpl.Update(PurchaseLine, Currency);
    end;

    /// <summary>
    /// Update the non-deductible VAT base and amount in the purchase line with factor multiplication
    /// </summary>
    /// <param name="PurchaseLine">The current purchase line</param>
    /// <param name="Part">The numerator for the factor calculation</param>
    /// <param name="Total">The denominator for factor calculation</param>
    /// <param name="AmountRoundingPrecision">Amount rounding precision to apply after multiplication</param>
    procedure Update(var PurchaseLine: Record "Purchase Line"; Part: Decimal; Total: Decimal; AmountRoundingPrecision: Decimal)
    begin
        NonDedVATImpl.Update(PurchaseLine, Part, Total, AmountRoundingPrecision);
    end;

    /// <summary>
    /// Updates total Non-Deductible VAT amounts in the invoice posting buffer
    /// </summary>
    /// <param name="TotalNonDedVATBase">Total Non-Deductible VAT base</param>
    /// <param name="TotalNonDedVATAmount">Total Non-Deductible VAT amount</param>
    /// <param name="TotalNonDedVATBaseACY">Total Non-Deductible VAT base in additional currency</param>
    /// <param name="TotalNonDedVATAmountACY">Total Non-Deductible VAT amount in additional currency</param>
    /// <param name="TotalNonDedVATDiff">Total Non-Deductible VAT difference</param>
    /// <param name="InvoicePostingBuffer">The current invoice posting buffer to update totals</param>
    procedure Update(var TotalNonDedVATBase: Decimal; var TotalNonDedVATAmount: Decimal; var TotalNonDedVATBaseACY: Decimal; var TotalNonDedVATAmountACY: Decimal; var TotalNonDedVATDiff: Decimal; InvoicePostingBuffer: Record "Invoice Posting Buffer")
    begin
        NonDedVATImpl.Update(TotalNonDedVATBase, TotalNonDedVATAmount, TotalNonDedVATBaseACY, TotalNonDedVATAmountACY, TotalNonDedVATDiff, InvoicePostingBuffer);
    end;

    /// <summary>
    /// Update Non-Deductible VAT amounts in the VAT amount line
    /// </summary>
    /// <param name="VATAmountLine">The current VAT amount line</param>
    /// <param name="Currency">The currency code of the document</param>
    procedure Update(var VATAmountLine: Record "VAT Amount Line"; Currency: Record Currency)
    begin
        NonDedVATImpl.Update(VATAmountLine, Currency);
    end;

    /// <summary>
    /// Update Non-Deductible VAT amounts in the invoice posting buffer with rounding
    /// </summary>
    /// <param name="InvoicePostingBuffer">The current invoice posting buffer</param>
    /// <param name="RemainderInvoicePostingBuffer">Remainder from rounding to add to the next line</param>
    /// <param name="AmountRoundingPrecision">Amount rounding precision to apply for rounding</param>
    procedure Update(var InvoicePostingBuffer: Record "Invoice Posting Buffer"; var RemainderInvoicePostingBuffer: Record "Invoice Posting Buffer"; AmountRoundingPrecision: Decimal)
    begin
        NonDedVATImpl.Update(InvoicePostingBuffer, RemainderInvoicePostingBuffer, AmountRoundingPrecision);
    end;

    /// <summary>
    /// Divide Non-Deductible VAT amounts of VAT amount line for the purchase line
    /// </summary>
    /// <param name="PurchaseLine">The current purchase line</param>
    /// <param name="VATAmountLineRemainder">Remainder from rounding to add to the next line</param>
    /// <param name="VATAmountLine">The current VAT amount line to divide</param>
    /// <param name="Currency">The currency code of the purchase document</param>
    /// <param name="Part">The numerator for the factor calculation</param>
    /// <param name="Total">The denominator for factor calculation</param>
    procedure DivideNonDeductibleVATInPurchaseLine(var PurchaseLine: Record "Purchase Line"; var VATAmountLineRemainder: Record "VAT Amount Line"; VATAmountLine: Record "VAT Amount Line"; Currency: Record Currency; Part: Decimal; Total: Decimal)
    begin
        NonDedVATImpl.DivideNonDeductibleVATInPurchaseLine(PurchaseLine, VATAmountLineRemainder, VATAmountLine, Currency, Part, Total);
    end;

    /// <summary>
    /// Update Non-Deductible VAT amounts on VAT amount validation in the VAT amount line
    /// </summary>
    /// <param name="VATAmountLine">The current VAT amount line</param>
    procedure ValidateVATAmountInVATAmountLine(var VATAmountLine: Record "VAT Amount Line")
    begin
        NonDedVATImpl.ValidateVATAmountInVATAmountLine(VATAmountLine);
    end;

    /// <summary>
    /// Update Non-Deductible VAT amounts on Non-Deductible VAT amount validation in the VAT amount line
    /// </summary>
    /// <param name="VATAmountLine">The current VAT amount line</param>
    procedure ValidateNonDeductibleVATInVATAmountLine(var VATAmountLine: Record "VAT Amount Line")
    begin
        NonDedVATImpl.ValidateNonDeductibleVATInVATAmountLine(VATAmountLine);
    end;

    /// <summary>
    /// Update Non-Deductible VAT amounts in the VAT amount line with VAT difference
    /// </summary>
    /// <param name="VATAmountLine">The current VAT amount line</param>
    /// <param name="Currency">The currency code of the document</param>
    procedure UpdateNonDeductibleAmountsWithDiffInVATAmountLine(var VATAmountLine: Record "VAT Amount Line"; Currency: Record Currency)
    begin
        NonDedVATImpl.UpdateNonDeductibleAmountsWithDiffInVATAmountLine(VATAmountLine, Currency);
    end;

    /// <summary>
    /// Get Non-Deductible VAT Amount from VAT amount line with factor multiplication
    /// </summary>
    /// <param name="VATAmountLineRemainder">Remainder from rounding to add to the next line</param>
    /// <param name="VATAmountLine">The current VAT amount line</param>
    /// <param name="Currency">The currency code of the document</param>
    /// <param name="Part">The numerator for the factor calculation</param>
    /// <param name="Total">The denominator for factor calculation</param>
    /// <returns>The Non-Deductible VAT Amount</returns>
    procedure GetNonDedVATAmountFromVATAmountLine(var VATAmountLineRemainder: Record "VAT Amount Line"; VATAmountLine: Record "VAT Amount Line"; Currency: Record Currency; Part: Decimal; Total: Decimal): Decimal
    begin
        exit(NonDedVATImpl.GetNonDedVATAmountFromVATAmountLine(VATAmountLineRemainder, VATAmountLine, Currency, Part, Total));
    end;

    /// <summary>
    /// Adds the Non-Deductible VAT amounts to the VAT amount line from the purchase line with factor multiplication
    /// </summary>
    /// <param name="VATAmountLine">The current VAT amount line</param>
    /// <param name="VATAmountLineRemainder">Remainder from rounding to add to the next line</param>
    /// <param name="PurchaseLine">The current purchase line</param>
    /// <param name="Currency">The currency code of the document</param>
    /// <param name="Part">The numerator for the factor calculation</param>
    /// <param name="Total">The denominator for factor calculation</param>
    procedure AddNonDedAmountsOfPurchLineToVATAmountLine(var VATAmountLine: Record "VAT Amount Line"; var VATAmountLineRemainder: Record "VAT Amount Line"; PurchaseLine: Record "Purchase Line"; Currency: Record Currency; Part: Decimal; Total: Decimal)
    begin
        NonDedVATImpl.AddNonDedAmountsOfPurchLineToVATAmountLine(VATAmountLine, VATAmountLineRemainder, PurchaseLine, Currency, Part, Total);
    end;

    /// <summary>
    /// Copy Non-Deductible VAT amounts from the purchase invoice line to VAT amount line
    /// </summary>
    /// <param name="VATAmountLine">The current VAT amount line</param>
    /// <param name="PurchInvLine">The current purchase invoice line</param>
    procedure CopyNonDedVATFromPurchInvLineToVATAmountLine(var VATAmountLine: Record "VAT Amount Line"; PurchInvLine: Record "Purch. Inv. Line")
    begin
        NonDedVATImpl.CopyNonDedVATFromPurchInvLineToVATAmountLine(VATAmountLine, PurchInvLine);
    end;

    /// <summary>
    /// Copy Non-Deductible VAT amounts from the purchase credit memo line to VAT amount line
    /// </summary>
    /// <param name="VATAmountLine">The current VAT amount line</param>
    /// <param name="PurchCrMemoLine">The current purchase credit memo line</param>
    procedure CopyNonDedVATFromPurchCrMemoLineToVATAmountLine(var VATAmountLine: Record "VAT Amount Line"; PurchCrMemoLine: Record "Purch. Cr. Memo Line")
    begin
        NonDedVATImpl.CopyNonDedVATFromPurchCrMemoLineToVATAmountLine(VATAmountLine, PurchCrMemoLine);
    end;

    /// <summary>
    /// Copy Non-Deductible VAT amount from general journal line to G/L entry
    /// </summary>
    /// <param name="GLEntry">The current G/L entry</param>
    /// <param name="GenJournalLine">The current general journal line</param>
    procedure CopyNonDedVATAmountFromGenJnlLineToGLEntry(var GLEntry: Record "G/L Entry"; GenJournalLine: Record "Gen. Journal Line")
    begin
        NonDedVATImpl.CopyNonDedVATAmountFromGenJnlLineToGLEntry(GLEntry, GenJournalLine);
    end;

    /// <summary>
    /// Copy Non-Deductible VAT from general journal line to FA ledger Entry
    /// </summary>
    /// <param name="FALedgEntry">The current FA ledger entry</param>
    /// <param name="GenJnlLine">The current general journal line</param>
    procedure CopyNonDedVATFromGenJnlLineToFALedgEntry(var FALedgEntry: Record "FA Ledger Entry"; GenJnlLine: Record "Gen. Journal Line")
    begin
        NonDedVATImpl.CopyNonDedVATFromGenJnlLineToFALedgEntry(FALedgEntry, GenJnlLine);
    end;

    procedure CopyNonDedVATFromGenJnlLineToJobJnlLine(var JobJnlLine: Record "Job Journal Line"; GenJnlLine: Record "Gen. Journal Line")
    begin
        NonDedVATImpl.CopyNonDedVATFromGenJnlLineToJobJnlLine(JobJnlLine, GenJnlLine);
    end;

    /// <summary>
    /// Throws an error if purchase line contains prepayment and Non-Deductible VAT
    /// </summary>
    /// <param name="PurchaseLine">The current purchase line</param>
    procedure CheckPrepmtWithNonDeductubleVATInPurchaseLine(PurchaseLine: Record "Purchase Line")
    begin
        NonDedVATImpl.CheckPrepmtWithNonDeductubleVATInPurchaseLine(PurchaseLine);
    end;

    /// <summary>
    /// Throws the error about prepayment not compatible with Non-Deductible VAT if VAT Posting Setup contains Non-Deductible VAT
    /// </summary>
    /// <param name="PurchaseLine">The current purchase line</param>
    procedure CheckPrepmtVATPostingSetup(VATPostingSetup: Record "VAT Posting Setup")
    begin
        NonDedVATImpl.CheckPrepmtVATPostingSetup(VATPostingSetup);
    end;

    /// <summary>
    /// Throws an error if current VAT posting setup contains unrealized VAT and Non-Deductible VAT
    /// </summary>
    /// <param name="VATPostingSetup">The current VAT posting setup</param>
    procedure CheckUnrealizedVATWithNonDeductibleVATInVATPostingSetup(VATPostingSetup: Record "VAT Posting Setup")
    begin
        NonDedVATImpl.CheckUnrealizedVATWithNonDeductibleVATInVATPostingSetup(VATPostingSetup);
    end;

    /// <summary>
    /// Check that a certain change of the VAT Posting Setup is allowed
    /// </summary>
    procedure CheckVATPostingSetupChangeIsAllowed(VATPostingSetup: Record "VAT Posting Setup")
    begin
        NonDedVATImpl.CheckVATPostingSetupChangeIsAllowed(VATPostingSetup);
    end;

    /// <summary>
    /// Check that a Non-Deductible VAT % is allowed in the purchase line
    /// </summary>
    procedure CheckNonDeductibleVATPctIsAllowed(PurchaseLine: Record "Purchase Line")
    begin
        NonDedVATImpl.CheckNonDeductibleVATPctIsAllowed(PurchaseLine);
    end;

    /// <summary>
    /// Throws an error if the total Non-Deductible VAT difference is not allowed
    /// </summary>
    /// <param name="TempVATAmountLine"></param>
    /// <param name="xTempVATAmountLine"></param>
    /// <param name="AllowVATDifference"></param>
    /// <param name="Currency"></param>
    procedure CheckNonDeductibleVATAmountDiff(var TempVATAmountLine: Record "VAT Amount Line" temporary; xTempVATAmountLine: Record "VAT Amount Line" temporary; AllowVATDifference: Boolean; Currency: Record Currency)
    begin
        NonDedVATImpl.CheckNonDeductibleVATAmountDiff(TempVATAmountLine, xTempVATAmountLine, AllowVATDifference, Currency);
    end;

    /// <summary>
    /// Deduct the Non-Deductible VAT amounts from the VAT amount line
    /// </summary>
    /// <param name="TotalVATAmountLine">The VAT amount line to be deducted</param>
    /// <param name="VATAmountLine">The current VAT amount line</param>
    procedure DeductNonDedValuesFromVATAmountLine(var TotalVATAmountLine: Record "VAT Amount Line"; VATAmountLineDeduct: Record "VAT Amount Line")
    begin
        NonDedVATImpl.DeductNonDedValuesFromVATAmountLine(TotalVATAmountLine, VATAmountLineDeduct);
    end;

    /// <summary>
    /// Reverse the Non-Deductible VAT base and amount in the purchase line
    /// </summary>
    /// <param name="PurchaseLine">The current purchase line</param>
    procedure Reverse(var PurchaseLine: Record "Purchase Line")
    begin
        NonDedVATImpl.Reverse(PurchaseLine);
    end;

    /// <summary>
    /// Reverse the Non-Deductible VAT base and amount in the invoice posting buffer
    /// </summary>
    /// <param name="InvoicePostingBuffer">The current invoice posting buffer</param>
    procedure Reverse(var InvoicePostingBuffer: Record "Invoice Posting Buffer")
    begin
        NonDedVATImpl.Reverse(InvoicePostingBuffer);
    end;

    /// <summary>
    /// Reverse Non-Deductible amount in G/L Entry
    /// </summary>
    /// <param name="GLEntry">The G/L Entry to set the reversed amount</param>
    /// <param name="GLEntryToReverse">The G/L Entry to take the value from</param>
    procedure Reverse(var GLEntry: Record "G/L Entry"; GLEntryToReverse: Record "G/L Entry")
    begin
        NonDedVATImpl.Reverse(GLEntry, GLEntryToReverse);
    end;

    /// <summary>
    /// Reverse Non-Deductible amount in the VAT Entry
    /// </summary>
    /// <param name="VATEntry">The VAT Entry to set the reversed amount</param>
    procedure Reverse(var VATEntry: Record "VAT Entry")
    begin
        NonDedVATImpl.Reverse(VATEntry);
    end;

    /// <summary>
    /// Increment the Non-Deductible VAT amounts in the VAT amount line
    /// </summary>
    /// <param name="TotalVATAmountLine">The VAT amount line to be incremented</param>
    /// <param name="VATAmountLine">The current VAT amount line</param>
    procedure Increment(var TotalVATAmountLine: Record "VAT Amount Line"; VATAmountLine: Record "VAT Amount Line")
    begin
        NonDedVATImpl.Increment(TotalVATAmountLine, VATAmountLine);
    end;

    /// <summary>
    /// Increment Non-Deductible VAT amounts in the purchase line
    /// </summary>
    /// <param name="TotalPurchaseLine">The purchase line to be incremented</param>
    /// <param name="PurchaseLine">The current purchase line</param>
    procedure Increment(var TotalPurchaseLine: Record "Purchase Line"; PurchaseLine: Record "Purchase Line")
    begin
        NonDedVATImpl.Increment(TotalPurchaseLine, PurchaseLine);
    end;

    /// <summary>
    /// Increment Non-Deductible VAT amounts in the invoice posting buffer
    /// </summary>
    /// <param name="TotalInvoicePostingBuffer">The invoice posting buffer to be incremented</param>
    /// <param name="InvoicePostingBuffer">The current invoice posting buffer</param>
    procedure Increment(var TotalInvoicePostingBuffer: Record "Invoice Posting Buffer"; InvoicePostingBuffer: Record "Invoice Posting Buffer")
    begin
        NonDedVATImpl.Increment(TotalInvoicePostingBuffer, InvoicePostingBuffer);
    end;

    /// <summary>
    /// Identifies if the current FA ledger entry is a Non-Deductible VAT entry in the first acquisition
    /// </summary>
    /// <param name="FALedgEntry"></param>
    /// <returns>Returns true if the current FA ledger entry is a Non-Deductible VAT entry in the first acquisition</returns>
    procedure IsNonDedFALedgEntryInFirstAcquisition(FALedgEntry: Record "FA Ledger Entry"): Boolean
    begin
        exit(NonDedVATImpl.IsNonDedFALedgEntryInFirstAcquisition(FALedgEntry));
    end;

    /// <summary>
    /// Round Non-Deductible VAT amounts after exchanging to the local currency
    /// </summary>
    /// <param name="PurchaseHeader">The current purchase header</param>
    /// <param name="PurchaseLine">The current purchase line</param>
    /// <param name="TotalPurchaseLine">The total purchase line with remainders</param>
    /// <param name="TotalPurchaseLineLCY">The total purchase line in additional curency with remainders</param>
    procedure RoundNonDeductibleVAT(PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; TotalPurchaseLine: Record "Purchase Line"; TotalPurchaseLineLCY: Record "Purchase Line")
    begin
        NonDedVATImpl.RoundNonDeductibleVAT(PurchaseHeader, PurchaseLine, TotalPurchaseLine, TotalPurchaseLineLCY);
    end;

    /// <summary>
    /// Clear Non-Deductible VAT in the purchase line
    /// </summary>
    /// <param name="PurchaseLine">The current purchase line</param>
    procedure ClearNonDeductibleVAT(var PurchaseLine: Record "Purchase Line")
    begin
        NonDedVATImpl.ClearNonDeductibleVAT(PurchaseLine);
    end;

    /// <summary>
    /// Clear Non-Deductible VAT in the invoice posting buffer
    /// </summary>
    /// <param name="InvoicePostingBuffer">The current invoice posting buffer</param>
    procedure ClearNonDeductibleVAT(var InvoicePostingBuffer: Record "Invoice Posting Buffer")
    begin
        NonDedVATImpl.ClearNonDeductibleVAT(InvoicePostingBuffer);
    end;

    /// <summary>
    /// Clear Non-Deductible VAT amounts in additional currency in VAT entry
    /// </summary>
    /// <param name="VATEntry">The current VAT entry</param>
    procedure ClearNonDedVATACYInVATEntry(var VATEntry: Record "VAT Entry")
    begin
        NonDedVATImpl.ClearNonDedVATACYInVATEntry(VATEntry);
    end;

    /// <summary>
    /// Validate the Non-Deductible VAT percent in the general journal line
    /// </summary>
    /// <param name="GenJournalLine">The current general journal line</param>
    procedure ValidateNonDedVATPctInGenJnlLine(var GenJournalLine: Record "Gen. Journal Line")
    begin
        NonDedVATImpl.ValidateNonDedVATPctInGenJnlLine(GenJournalLine);
    end;

    /// <summary>
    /// Validate the Non-Deductible VAT percent in the general journal line for the balance account
    /// </summary>
    /// <param name="GenJournalLine">The current general journal line</param>
    procedure ValidateBalNonDedVATPctInGenJnlLine(var GenJournalLine: Record "Gen. Journal Line")
    begin
        NonDedVATImpl.ValidateBalNonDedVATPctInGenJnlLine(GenJournalLine);
    end;

    /// <summary>
    /// Calculate Non-Deductible VAT amounts in the general journal line
    /// </summary>
    /// <param name="GenJournalLine">The current journal line</param>
    /// <param name="Currency">The currency code of the document</param>
    procedure Calculate(var GenJournalLine: Record "Gen. Journal Line"; Currency: Record Currency)
    begin
        NonDedVATImpl.Calculate(GenJournalLine, Currency);
    end;

    /// <summary>
    /// Calculate Non-Deductible VAT amounts in the general journal line for the balance account
    /// </summary>
    /// <param name="GenJournalLine">The current journal line</param>
    /// <param name="Currency">The currency code of the document</param>
    procedure CalculateBalAcc(var GenJournalLine: Record "Gen. Journal Line"; Currency: Record Currency)
    begin
        NonDedVATImpl.CalculateBalAcc(GenJournalLine, Currency);
    end;

    /// <summary>
    /// Calculate Non-Deductible VAT amounts in the invoice posting buffer
    /// </summary>
    /// <param name="InvoicePostingBuffer">The current invoice posting buffer</param>
    procedure Calculate(var InvoicePostingBuffer: Record "Invoice Posting Buffer")
    begin
        NonDedVATImpl.Calculate(InvoicePostingBuffer);
    end;

    /// <summary>
    /// Calculate Non-Deductible VAT per unit
    /// </summary>
    /// <param name="NonDeductibleBaseAmount">The calculated total Non-Deductible base</param>
    /// <param name="NonDeductibleVATAmount">The calculated total Non-Deductible amount</param>
    /// <param name="NonDeductibleVATAmtPerUnit">The calculated Non-Deductible VAT amount per unit</param>
    /// <param name="NonDeductibleVATAmtPerUnitLCY">The calculated Non-Deductible VAT amount per unit in local currency</param>
    /// <param name="NDVATAmountRounding">The remaining rounding difference of Non-Deductible VAT amount</param>
    /// <param name="NDVATBaseRounding">The remaining rounding difference of Non-Deductible VAT base</param>
    /// <param name="PurchHeader">The current purchase header</param>
    /// <param name="PurchaseLine">The current purchase line with LCY amounts</param>
    procedure Calculate(var NonDeductibleBaseAmount: Decimal; var NonDeductibleVATAmount: Decimal; var NonDeductibleVATAmtPerUnit: Decimal; var NonDeductibleVATAmtPerUnitLCY: Decimal; var NDVATAmountRounding: Decimal; var NDVATBaseRounding: Decimal; PurchHeader: Record "Purchase Header"; PurchaseLine: Record "Purchase Line")
    begin
        NonDedVATImpl.Calculate(NonDeductibleBaseAmount, NonDeductibleVATAmount, NonDeductibleVATAmtPerUnit, NonDeductibleVATAmtPerUnitLCY, NDVATAmountRounding, NDVATBaseRounding, PurchHeader, PurchaseLine);
    end;

    /// <summary>
    /// Copy Non-Deductible VAT from the purchase line to the invoice posting buffer
    /// </summary>
    /// <param name="InvoicePostingBuffer">The current invoice posting buffer</param>
    /// <param name="PurchaseLine">The current purchase line</param>
    procedure Copy(var InvoicePostingBuffer: Record "Invoice Posting Buffer"; PurchaseLine: Record "Purchase Line")
    begin
        NonDedVATImpl.Copy(InvoicePostingBuffer, PurchaseLine);
    end;

    /// <summary>
    /// Copy Non-Deductible VAT from the general journal line to the VAT Entry
    /// </summary>
    /// <param name="VATEntry">The current VAT Entry</param>
    /// <param name="GenJournalLine">The current general journal line</param>
    procedure Copy(var VATEntry: Record "VAT Entry"; GenJournalLine: Record "Gen. Journal Line")
    begin
        NonDedVATImpl.Copy(VATEntry, GenJournalLine);
    end;

    /// <summary>
    /// Copy Non-Deductible VAT from the invoice posting buffer to the general journal line
    /// </summary>
    /// <param name="GenJournalLine">The current general journal line</param>
    /// <param name="InvoicePostingBuffer">The current invoice posting buffer</param>
    procedure Copy(var GenJournalLine: Record "Gen. Journal Line"; InvoicePostingBuffer: Record "Invoice Posting Buffer")
    begin
        NonDedVATImpl.Copy(GenJournalLine, InvoicePostingBuffer);
    end;

    /// <summary>
    /// Exchange Non-Deductible VAT fields with the balance side in general journaal line
    /// </summary>
    /// <param name="GenJournalLine">The current general journal line</param>
    /// <param name="GenJournalLine">The copied general journal line</param>
    procedure ExchangeAccGLJournalLine(var GenJournalLine: Record "Gen. Journal Line"; CopiedGenJournalLine: Record "Gen. Journal Line")
    begin
        NonDedVATImpl.ExchangeAccGLJournalLine(GenJournalLine, CopiedGenJournalLine);
    end;

    /// <summary>
    /// Adjust VAT amounts with Non-Deductible VAT from general journal line
    /// </summary>
    /// <param name="VATAmount">The VAT amount to be adjusted</param>
    /// <param name="BaseAmount">The VAT base to be adjusted</param>
    /// <param name="VATAmountACY">The VAT amount in additional currency to be adjusted</param>
    /// <param name="BaseAmountACY">The VAT base in additional currency to be adjusted</param>
    /// <param name="GenJournalLine">The current general journal line</param>
    procedure AdjustVATAmountsFromGenJnlLine(var VATAmount: Decimal; var BaseAmount: Decimal; var VATAmountACY: Decimal; var BaseAmountACY: Decimal; var GenJournalLine: Record "Gen. Journal Line")
    begin
        NonDedVATImpl.AdjustVATAmountsFromGenJnlLine(VATAmount, BaseAmount, VATAmountACY, BaseAmountACY, GenJournalLine);
    end;

    /// <summary>
    /// Adjust rounding for invoice posting buffer
    /// </summary>
    /// <param name="RoundingInvoicePostingBuffer">The invoice posting buffer for rounding</param>
    /// <param name="CurrInvoicePostingBuffer">The current invoice posting buffer</param>
    procedure AdjustRoundingForInvoicePostingBufferUpdate(var RoundingInvoicePostingBuffer: Record "Invoice Posting Buffer"; var CurrInvoicePostingBuffer: Record "Invoice Posting Buffer")
    begin
        NonDedVATImpl.AdjustRoundingForInvoicePostingBufferUpdate(RoundingInvoicePostingBuffer, CurrInvoicePostingBuffer);
    end;

    /// <summary>
    /// Returns true if the Non-Deductible VAT amount must be added to the fixed asset cost
    /// </summary>
    /// <returns>If the Non-Deductible amount must be added to the fixed asset cost</returns>
    procedure UseNonDeductibleVATAmountForFixedAssetCost(): Boolean
    begin
        exit(NonDedVATImpl.UseNonDeductibleVATAmountForFixedAssetCost());
    end;

    /// <summary>
    /// Returns true if the Non-Deductible VAT amount must be added to the job cost
    /// </summary>
    /// <returns>If the Non-Deductible amount must be added to the job cost</returns>
    procedure UseNonDeductibleVATAmountForJobCost(): Boolean
    begin
        exit(NonDedVATImpl.UseNonDeductibleVATAmountForJobCost());
    end;

    /// <summary>
    /// Apply rounding for the final posting from the invoice posting buffer
    /// </summary>
    /// <param name="RoundingInvoicePostingBuffer">The invoice posting buffer for rounding</param>
    /// <param name="CurrInvoicePostingBuffer">The current invoice posting buffer</param>
    procedure ApplyRoundingForFinalPostingFromInvoicePostingBuffer(var RoundingInvoicePostingBuffer: Record "Invoice Posting Buffer"; var CurrInvoicePostingBuffer: Record "Invoice Posting Buffer")
    begin
        NonDedVATImpl.ApplyRoundingForFinalPostingFromInvoicePostingBuffer(RoundingInvoicePostingBuffer, CurrInvoicePostingBuffer);
    end;

    [IntegrationEvent(false, false)]
    internal procedure OnBeforeGetNonDeductibleVATPctForPurchLine(var NonDeductibleVATPct: Decimal; PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    internal procedure OnBeforeGetNonDedVATPctForGenJnlLine(var NonDeductibleVATPct: Decimal; GenJournalLine: Record "Gen. Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    internal procedure OnBeforeGetBalNonDedVATPctForGenJnlLine(var NonDeductibleVATPct: Decimal; GenJournalLine: Record "Gen. Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    internal procedure OnBeforeGetNonDeductibleVATPctForDeferrals(var NonDeductibleVATPct: Decimal; VATBusPostGroupCode: Code[20]; VATProdPostGroupCode: Code[20]; DeferralDocType: Enum "Deferral Document Type"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    internal procedure OnBeforeCalcNonDedAmountsInGenJnlLine(var GenJournalLine: Record "Gen. Journal Line"; Currency: Record Currency; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    internal procedure OnBeforeCalcBalNonDedAmountsInGenJnlLine(var GenJournalLine: Record "Gen. Journal Line"; Currency: Record Currency; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    internal procedure OnBeforeGetNonDeductibleVATPct(var NonDeductibleVATPct: Decimal; VATPostingSetup: Record "VAT Posting Setup"; GeneralPostingType: Enum "General Posting Type"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    internal procedure OnBeforeUpdateNonDeductibleAmountsWithRoundingInPurchLine(var PurchaseLine: Record "Purchase Line"; var TempVATAmountLineRemainder: Record "VAT Amount Line" temporary; Currency: Record Currency; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    internal procedure OnBeforeUpdateNonDeductibleAmountsInPurchLine(var PurchaseLine: Record "Purchase Line"; Currency: Record Currency; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    internal procedure OnBeforeUpdateNonDeductibleAmountsWithFactorInPurchLine(var PurchaseLine: Record "Purchase Line"; Part: Decimal; Total: Decimal; AmountRoundingPrecision: Decimal; var IsHandled: Boolean)
    begin

    end;

    [IntegrationEvent(false, false)]
    internal procedure OnBeforeDivideNonDeductibleVATInPurchaseLine(var PurchaseLine: Record "Purchase Line"; var VATAmountLineRemainder: Record "VAT Amount Line"; VATAmountLine: Record "VAT Amount Line"; Currency: Record Currency; Part: Decimal; Total: Decimal; var IsHandled: Boolean)
    begin

    end;

    [IntegrationEvent(false, false)]
    internal procedure OnBeforeValidateVATAmountInVATAmountLine(var VATAmountLine: Record "VAT Amount Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    internal procedure OnBeforeValidateNonDeductibleVATInVATAmountLine(var VATAmountLine: Record "VAT Amount Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    internal procedure OnBeforeUpdateNonDeductibleAmountsInVATAmountLine(var VATAmountLine: Record "VAT Amount Line"; Currency: Record Currency; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    internal procedure OnBeforeUpdateNonDeductibleAmountsWithDiffInVATAmountLine(var VATAmountLine: Record "VAT Amount Line"; Currency: Record Currency; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    internal procedure OnBeforeAdjustVATAmountsFromGenJnlLine(var VATAmount: Decimal; var BaseAmount: Decimal; var VATAmountACY: Decimal; var BaseAmountACY: Decimal; var GenJournalLine: Record "Gen. Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    internal procedure OnBeforeSetNonDedVATAmountInPurchLine(var PurchaseLine: Record "Purchase Line"; NonDeductibleVATAmount: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    internal procedure OnBeforeSetNonDedVATAmountDiffInPurchLine(var PurchaseLine: Record "Purchase Line"; var VATAmountLineRemainder: Record "VAT Amount Line"; var VATDifference: Decimal; VATAmountLine: Record "VAT Amount Line"; Currency: Record Currency; Part: Decimal; Total: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    internal procedure OnBeforeGetNonDedVATAmountFromVATAmountLine(var NonDeductibleVATAmount: Decimal; var VATAmountLineRemainder: Record "VAT Amount Line"; VATAmountLine: Record "VAT Amount Line"; Currency: Record Currency; Part: Decimal; Total: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    internal procedure OnBeforeAddNonDedAmountsOfPurchLineToVATAmountLine(var VATAmountLine: Record "VAT Amount Line"; var VATAmountLineRemainder: Record "VAT Amount Line"; PurchaseLine: Record "Purchase Line"; Currency: Record Currency; Part: Decimal; Total: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    internal procedure OnBeforeCopyNonDedVATFromPurchInvLineToVATAmountLine(var VATAmountLine: Record "VAT Amount Line"; PurchInvLine: Record "Purch. Inv. Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    internal procedure OnBeforeCopyNonDedVATFromPurchCrMemoLineToVATAmountLine(var VATAmountLine: Record "VAT Amount Line"; PurchCrMemoLine: Record "Purch. Cr. Memo Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    internal procedure OnBeforeCheckVATPostingSetupChangeIsAllowed(VATPostingSetup: Record "VAT Posting Setup"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    internal procedure OnBeforeCheckNonDeductibleVATPctIsAllowed(PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;
}