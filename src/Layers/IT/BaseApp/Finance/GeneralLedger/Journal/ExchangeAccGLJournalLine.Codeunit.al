// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Journal;

using Microsoft.Finance.VAT.Calculation;

/// <summary>
/// Exchanges account and balancing account information in general journal lines for posting reversals and corrections.
/// Swaps all account-related fields including VAT settings, posting groups, and tax information between account and balancing account.
/// </summary>
/// <remarks>
/// Account field exchange functionality for journal line account/balancing account swapping.
/// Comprehensive field swapping including account numbers, VAT settings, posting groups, and tax configurations.
/// Key features: Complete account field exchange, VAT information preservation, posting group swapping, tax setting exchange.
/// Usage: Posting reversals, account corrections, balancing account adjustments with complete field consistency.
/// </remarks>
codeunit 366 "Exchange Acc. G/L Journal Line"
{
    TableNo = "Gen. Journal Line";

    trigger OnRun()
    begin
        OnBeforeOnRun(Rec);

        GenJnlLine2 := Rec;
        Rec."Account Type" := GenJnlLine2."Bal. Account Type";
        Rec."Account No." := GenJnlLine2."Bal. Account No.";
        Rec."VAT %" := GenJnlLine2."Bal. VAT %";
        Rec."VAT Amount" := GenJnlLine2."Bal. VAT Amount";
        Rec."VAT Amount (LCY)" := GenJnlLine2."Bal. VAT Amount (LCY)";
        Rec."VAT Difference" := GenJnlLine2."Bal. VAT Difference";
        Rec."Gen. Posting Type" := GenJnlLine2."Bal. Gen. Posting Type";
        Rec."Gen. Bus. Posting Group" := GenJnlLine2."Bal. Gen. Bus. Posting Group";
        Rec."Gen. Prod. Posting Group" := GenJnlLine2."Bal. Gen. Prod. Posting Group";
        Rec."VAT Bus. Posting Group" := GenJnlLine2."Bal. VAT Bus. Posting Group";
        Rec."VAT Prod. Posting Group" := GenJnlLine2."Bal. VAT Prod. Posting Group";
        Rec."VAT Calculation Type" := GenJnlLine2."Bal. VAT Calculation Type";
        Rec."VAT Base Amount" := GenJnlLine2."Bal. VAT Base Amount";
        Rec."VAT Base Amount (LCY)" := GenJnlLine2."Bal. VAT Base Amount (LCY)";
        Rec."Tax Area Code" := GenJnlLine2."Bal. Tax Area Code";
        Rec."Tax Liable" := GenJnlLine2."Bal. Tax Liable";
        Rec."Tax Group Code" := GenJnlLine2."Bal. Tax Group Code";
        Rec."Use Tax" := GenJnlLine2."Bal. Use Tax";

        Rec."Bal. Account Type" := GenJnlLine2."Account Type";
        Rec."Bal. Account No." := GenJnlLine2."Account No.";
        Rec."Bal. VAT %" := GenJnlLine2."VAT %";
        Rec."Bal. VAT Amount" := GenJnlLine2."VAT Amount";
        Rec."Bal. VAT Amount (LCY)" := GenJnlLine2."VAT Amount (LCY)";
        Rec."Bal. VAT Difference" := GenJnlLine2."VAT Difference";
        Rec."Bal. Gen. Posting Type" := GenJnlLine2."Gen. Posting Type";
        Rec."Bal. Gen. Bus. Posting Group" := GenJnlLine2."Gen. Bus. Posting Group";
        Rec."Bal. Gen. Prod. Posting Group" := GenJnlLine2."Gen. Prod. Posting Group";
        Rec."Bal. VAT Bus. Posting Group" := GenJnlLine2."VAT Bus. Posting Group";
        Rec."Bal. VAT Prod. Posting Group" := GenJnlLine2."VAT Prod. Posting Group";
        Rec."Bal. VAT Calculation Type" := GenJnlLine2."VAT Calculation Type";
        Rec."Bal. VAT Base Amount" := GenJnlLine2."VAT Base Amount";
        Rec."Bal. VAT Base Amount (LCY)" := GenJnlLine2."VAT Base Amount (LCY)";
        Rec."Bal. Tax Area Code" := GenJnlLine2."Tax Area Code";
        Rec."Bal. Tax Liable" := GenJnlLine2."Tax Liable";
        Rec."Bal. Tax Group Code" := GenJnlLine2."Tax Group Code";
        Rec."Bal. Use Tax" := GenJnlLine2."Use Tax";

        Rec.Amount := -GenJnlLine2.Amount;
        Rec."Debit Amount" := GenJnlLine2."Credit Amount";
        Rec."Credit Amount" := GenJnlLine2."Debit Amount";
        Rec."Amount (LCY)" := -GenJnlLine2."Amount (LCY)";
        Rec."Balance (LCY)" := -GenJnlLine2."Balance (LCY)";
        if (Rec."Currency Code" <> '') and not Rec."System-Created Entry" then begin
            Rec."Source Currency Amount" := Rec.Amount;
            Rec."Source Curr. VAT Base Amount" := Rec."VAT Base Amount";
            Rec."Source Curr. VAT Amount" := Rec."VAT Amount";
        end else begin
            Rec."Source Currency Amount" := -Rec."Source Currency Amount";
            Rec."Source Curr. VAT Base Amount" := -Rec."Source Curr. VAT Base Amount";
            Rec."Source Curr. VAT Amount" := -Rec."Source Curr. VAT Amount";
        end;
        NonDeductibleVAT.ExchangeAccGLJournalLine(Rec, GenJnlLine2);

        OnAfterOnRun(Rec, GenJnlLine2);
    end;

    var
        GenJnlLine2: Record "Gen. Journal Line";
        NonDeductibleVAT: Codeunit "Non-Deductible VAT";

    /// <summary>
    /// Integration event raised after completing account and balancing account field exchange operations.
    /// Enables custom processing after all account-related fields have been swapped between account and balancing account.
    /// </summary>
    /// <param name="GenJournalLine">Journal line record with exchanged account information.</param>
    /// <param name="GenJournalLine2">Original journal line record before exchange operation.</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterOnRun(var GenJournalLine: Record "Gen. Journal Line"; GenJournalLine2: Record "Gen. Journal Line")
    begin
    end;

    /// <summary>
    /// Integration event raised before starting account and balancing account field exchange operations.
    /// Enables custom validation or preprocessing before account field swapping begins.
    /// </summary>
    /// <param name="GenJournalLine">Journal line record that will have account information exchanged.</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnRun(var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;
}

