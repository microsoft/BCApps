// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Journal;

using Microsoft.Finance.Currency;

codeunit 407 "Adjust Gen. Journal Balance"
{
    TableNo = "Gen. Journal Line";

    trigger OnRun()
    var
        GenJnlLine: Record "Gen. Journal Line";
        PrevGenJnlLine: Record "Gen. Journal Line";
        CorrectionEntry: Boolean;
        TotalAmountLCY: Decimal;
    begin
        TempCurrTotalBuffer.DeleteAll();
        GenJnlLine.SetRange("Journal Template Name", Rec."Journal Template Name");
        GenJnlLine.SetRange("Journal Batch Name", Rec."Journal Batch Name");

        OnRunOnBeforeGenJnlLineFind(GenJnlLine);
        if not GenJnlLine.Find('-') then
            exit;
        PrevGenJnlLine := GenJnlLine;
        CorrectionEntry := true;
        TotalAmountLCY := 0;
        repeat
            if (GenJnlLine."Posting Date" <> PrevGenJnlLine."Posting Date") or
               (GenJnlLine."Document No." <> PrevGenJnlLine."Document No.")
            then begin
                if CheckCurrBalance() and (TotalAmountLCY <> 0) then begin
                    PrevGenJnlLine.Correction := CorrectionEntry;
                    InsertCorrectionLines(GenJnlLine, PrevGenJnlLine);
                end;
                TotalAmountLCY := 0;
                TempCurrTotalBuffer.DeleteAll();
                CorrectionEntry := true;
                PrevGenJnlLine := GenJnlLine;
            end;
            TotalAmountLCY := TotalAmountLCY + GenJnlLine."Amount (LCY)";
            if GenJnlLine."Bal. Account No." = '' then begin
                if TempCurrTotalBuffer.Get(GenJnlLine."Currency Code") then begin
                    TempCurrTotalBuffer."Total Amount" :=
                      TempCurrTotalBuffer."Total Amount" + GenJnlLine.Amount;
                    TempCurrTotalBuffer."Total Amount (LCY)" :=
                      TempCurrTotalBuffer."Total Amount (LCY)" + GenJnlLine."Amount (LCY)";
                    TempCurrTotalBuffer.Modify();
                end else begin
                    TempCurrTotalBuffer."Currency Code" := GenJnlLine."Currency Code";
                    TempCurrTotalBuffer."Total Amount" := GenJnlLine.Amount;
                    TempCurrTotalBuffer."Total Amount (LCY)" := GenJnlLine."Amount (LCY)";
                    TempCurrTotalBuffer.Insert();
                end;
                CorrectionEntry := CorrectionEntry and GenJnlLine.Correction;
            end;

            if GenJnlLine."Document Type" <> PrevGenJnlLine."Document Type" then
                GenJnlLine."Document Type" := GenJnlLine."Document Type"::" ";
            if GenJnlLine."Business Unit Code" <> PrevGenJnlLine."Business Unit Code" then
                GenJnlLine."Business Unit Code" := '';
            if GenJnlLine."Reason Code" <> PrevGenJnlLine."Reason Code" then
                GenJnlLine."Reason Code" := '';
            if GenJnlLine."Recurring Method" <> PrevGenJnlLine."Recurring Method" then
                GenJnlLine."Recurring Method" := GenJnlLine."Recurring Method"::" ";
            if GenJnlLine."Recurring Frequency" <> PrevGenJnlLine."Recurring Frequency" then
                Evaluate(GenJnlLine."Recurring Frequency", '<>');

            PrevGenJnlLine := GenJnlLine;
        until GenJnlLine.Next() = 0;

        Clear(PrevGenJnlLine);

        if CheckCurrBalance() and (TotalAmountLCY <> 0) then begin
            GenJnlLine.Correction := CorrectionEntry;
            InsertCorrectionLines(PrevGenJnlLine, GenJnlLine);
        end;
    end;

    var
        TempCurrTotalBuffer: Record "Currency Total Buffer" temporary;

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'The program cannot find a key between line number %1 and line number %2.';
        Text002: Label 'Rounding correction for %1';
#pragma warning restore AA0470
#pragma warning restore AA0074

    local procedure CheckCurrBalance(): Boolean
    var
        InBalance: Boolean;
    begin
        InBalance := true;
        if TempCurrTotalBuffer.Find('-') then
            repeat
                InBalance := InBalance and (TempCurrTotalBuffer."Total Amount" = 0)
            until (not InBalance) or (TempCurrTotalBuffer.Next() = 0);
        exit(InBalance);
    end;

    local procedure InsertCorrectionLines(var GenJnlLine2: Record "Gen. Journal Line"; var PrevGenJnlLine2: Record "Gen. Journal Line")
    var
        Currency: Record Currency;
        NewGenJnlLine: Record "Gen. Journal Line";
    begin
        NewGenJnlLine := PrevGenJnlLine2;

        TempCurrTotalBuffer.SetFilter("Currency Code", '<>%1', '');
        TempCurrTotalBuffer.SetRange("Total Amount", 0);

        if TempCurrTotalBuffer.Find('-') then
            repeat
                Currency.Get(TempCurrTotalBuffer."Currency Code");
                NewGenJnlLine.Init();
                if GenJnlLine2."Line No." = 0 then
                    NewGenJnlLine."Line No." := NewGenJnlLine."Line No." + 10000
                else
                    if GenJnlLine2."Line No." >= NewGenJnlLine."Line No." + 2 then
                        NewGenJnlLine."Line No." := (NewGenJnlLine."Line No." + GenJnlLine2."Line No.") div 2
                    else
                        Error(
                          Text000,
                          PrevGenJnlLine2."Line No.",
                          GenJnlLine2."Line No.");
                NewGenJnlLine."Document Type" := PrevGenJnlLine2."Document Type";
                NewGenJnlLine."Account Type" := NewGenJnlLine."Account Type"::"G/L Account";
                NewGenJnlLine.Correction := PrevGenJnlLine2.Correction;
                if NewGenJnlLine.Correction xor (TempCurrTotalBuffer."Total Amount (LCY)" <= 0) then
                    NewGenJnlLine.Validate("Account No.", Currency.GetConvLCYRoundingDebitAccount())
                else
                    NewGenJnlLine.Validate("Account No.", Currency.GetConvLCYRoundingCreditAccount());
                NewGenJnlLine."Posting Date" := PrevGenJnlLine2."Posting Date";
                NewGenJnlLine."Document No." := PrevGenJnlLine2."Document No.";
                NewGenJnlLine.Description := StrSubstNo(Text002, TempCurrTotalBuffer."Currency Code");
                NewGenJnlLine.Validate(Amount, -TempCurrTotalBuffer."Total Amount (LCY)");
                NewGenJnlLine."Source Code" := PrevGenJnlLine2."Source Code";
                NewGenJnlLine."Business Unit Code" := PrevGenJnlLine2."Business Unit Code";
                NewGenJnlLine."Reason Code" := PrevGenJnlLine2."Reason Code";
                NewGenJnlLine."Recurring Method" := PrevGenJnlLine2."Recurring Method";
                NewGenJnlLine."Recurring Frequency" := PrevGenJnlLine2."Recurring Frequency";
                NewGenJnlLine."Posting No. Series" := PrevGenJnlLine2."Posting No. Series";
                OnBeforeGenJnlLineInsert(NewGenJnlLine, GenJnlLine2, PrevGenJnlLine2);
                if TempCurrTotalBuffer."Total Amount (LCY)" <> 0 then begin
                    OnInsertCorrectionLinesOnBeforeNewGenJnlLineInsert(GenJnlLine2, PrevGenJnlLine2, NewGenJnlLine);
                    NewGenJnlLine.Insert();
                end;
            until TempCurrTotalBuffer.Next() = 0;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGenJnlLineInsert(var NewGenJnlLine: Record "Gen. Journal Line"; GenJnlLine2: Record "Gen. Journal Line"; PrevGenJnlLine2: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertCorrectionLinesOnBeforeNewGenJnlLineInsert(var GenJnlLine2: Record "Gen. Journal Line"; var PrevGenJnlLine2: Record "Gen. Journal Line"; var NewGenJnlLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnBeforeGenJnlLineFind(var GenJnlLine: Record "Gen. Journal Line")
    begin
    end;
}

