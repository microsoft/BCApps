// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Currency;

using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Posting;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Ledger;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Purchases.Payables;
using Microsoft.Sales.Receivables;

/// <summary>
/// Reserved codeunit for implementing country-specific exchange rate adjustment logic.
/// Provides a placeholder for localization-specific event subscribers and customizations
/// related to exchange rate adjustment processing.
/// </summary>
/// <remarks>
/// Intended for use by localization partners to implement region-specific requirements
/// for exchange rate adjustments without modifying core adjustment procedures.
/// Event subscribers can be added to handle local compliance and calculation rules.
/// </remarks>
codeunit 597 "Exch. Rate Adjmt. Subscribers"
{
    Permissions = TableData "VAT Entry" = rim,
                  TableData "G/L Register" = rim;

    var
        GLSetup: Record "General Ledger Setup";
        SourceCodeSetup: Record "Source Code Setup";
        NewVATEntry: Record "VAT Entry";
        NewVATEntry4No: Record "VAT Entry";
        VATEntryLink: Record "G/L Entry - VAT Entry Link";
        TempDimSetEntry: Record "Dimension Set Entry" temporary;
        DimMgt: Codeunit DimensionManagement;
        VATEntryNoTotal: Integer;
        VATEntriesCounter: Integer;
        Text92000Txt: Label 'VAT exch. adjustment Doc. ';
        VATExchRateProgressBarTxt: Label 'Adjust VAT rate...\\';
        VATEntriesProgressBarTxt: Label 'Adjusted entries  @1@@@@@@@@@@@@@';
        CorrRevChargeEntryNo: Integer;
        FirstVATEntryNo: Integer;
        GLSetupRead: Boolean;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Exch. Rate Adjmt. Process", 'OnAfterAdjustCustomerLedgerEntryOnAfterCalcAdjmtAmount', '', false, false)]
    local procedure OnAfterAdjustCustomerLedgerEntryOnAfterCalcAdjmtAmount(CustLedgerEntry: Record "Cust. Ledger Entry"; ExchRateAdjmtParameters: Record "Exch. Rate Adjmt. Parameters"; AdjmtAmount: Decimal; Application: Boolean; var ShouldExit: Boolean)
    begin
        case ExchRateAdjmtParameters."Valuation Method" of
            1: // ValuationMethod::"Lowest Value":
                if (AdjmtAmount >= 0) and (not Application) then
                    ShouldExit := true;
            2: // ValuationMethod::"BilMoG (Germany)":
                if not Application then
                    if not CalculateBilMoG(
                        AdjmtAmount, CustLedgerEntry."Remaining Amt. (LCY)",
                        CustCalcRemOrigAmtLCY(CustLedgerEntry, ExchRateAdjmtParameters."Posting Date"),
                        CustLedgerEntry."Due Date", ExchRateAdjmtParameters."Due Date To")
                    then
                        ShouldExit := true;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Exch. Rate Adjmt. Process", 'OnAfterAdjustVendorLedgerEntryOnAfterCalcAdjmtAmount', '', false, false)]
    local procedure OnAfterAdjustVendorLedgerEntryOnAfterCalcAdjmtAmount(VendLedgerEntry: Record "Vendor Ledger Entry"; ExchRateAdjmtParameters: Record "Exch. Rate Adjmt. Parameters"; AdjmtAmount: Decimal; Application: Boolean; var ShouldExit: Boolean)
    begin
        case ExchRateAdjmtParameters."Valuation Method" of
            1: // ValuationMethod::"Lowest Value":
                if (AdjmtAmount >= 0) and (not Application) then
                    ShouldExit := true;
            2: // ValuationMethod::"BilMoG (Germany)":
                if not Application then
                    if not CalculateBilMoG(
                        AdjmtAmount, VendLedgerEntry."Remaining Amt. (LCY)",
                        VendCalcRemOrigAmtLCY(VendLedgerEntry, ExchRateAdjmtParameters."Posting Date"),
                        VendLedgerEntry."Due Date", ExchRateAdjmtParameters."Due Date To")
                    then
                        ShouldExit := true;
        end;
    end;

    local procedure CalculateBilMoG(var AdjAmt2: Decimal; RemAmtLCY: Decimal; OrigRemAmtLCY: Decimal; DueDate: Date; DueDateTo: Date): Boolean
    begin
        if (DueDateTo < DueDate) or (DueDate = 0D) then begin
            if (RemAmtLCY = OrigRemAmtLCY) and (AdjAmt2 >= 0) then
                exit(false);
            if (AdjAmt2 + RemAmtLCY) > OrigRemAmtLCY then
                AdjAmt2 := OrigRemAmtLCY - RemAmtLCY;
        end;
        exit(true);
    end;

    local procedure CustCalcRemOrigAmtLCY(CustLedgEntry2: Record "Cust. Ledger Entry"; PostingDate: Date): Decimal
    var
        DtldCustEntry2: Record "Detailed Cust. Ledg. Entry";
    begin
        DtldCustEntry2.SetCurrentKey("Cust. Ledger Entry No.", "Entry Type", "Posting Date");
        DtldCustEntry2.SetRange("Cust. Ledger Entry No.", CustLedgEntry2."Entry No.");
        DtldCustEntry2.SetRange(
          "Entry Type", DtldCustEntry2."Entry Type"::"Initial Entry", DtldCustEntry2."Entry Type"::Application);
        DtldCustEntry2.SetRange("Posting Date", CustLedgEntry2."Posting Date", PostingDate);
        DtldCustEntry2.CalcSums("Amount (LCY)");
        exit(DtldCustEntry2."Amount (LCY)");
    end;

    local procedure VendCalcRemOrigAmtLCY(VendLedgEntry2: Record "Vendor Ledger Entry"; PostingDate: Date): Decimal
    var
        DtldVendEntry2: Record "Detailed Vendor Ledg. Entry";
    begin
        DtldVendEntry2.SetCurrentKey("Vendor Ledger Entry No.", "Entry Type", "Posting Date");
        DtldVendEntry2.SetRange("Vendor Ledger Entry No.", VendLedgEntry2."Entry No.");
        DtldVendEntry2.SetRange(
          "Entry Type", DtldVendEntry2."Entry Type"::"Initial Entry", DtldVendEntry2."Entry Type"::Application);
        DtldVendEntry2.SetRange("Posting Date", VendLedgEntry2."Posting Date", PostingDate);
        DtldVendEntry2.CalcSums("Amount (LCY)");
        exit(DtldVendEntry2."Amount (LCY)");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Exch. Rate Adjmt. Process", 'OnBeforeAdjustGLAccountsAndVATEntries', '', false, false)]
    local procedure OnBeforeAdjustGLAccountsAndVATEntries(ExchRateAdjmtParameters: Record "Exch. Rate Adjmt. Parameters"; var Currency: Record Currency; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    begin
        if ExchRateAdjmtParameters."Adjust VAT Entries" then
            AdjustVATEntries(ExchRateAdjmtParameters, Currency, GenJnlPostLine);
    end;

    local procedure AdjustVATEntries(var ExchRateAdjmtParameters: Record "Exch. Rate Adjmt. Parameters" temporary; var Currency: Record Currency; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    var
        VATEntry: Record "VAT Entry";
        Window: Dialog;
    begin
        Window.Open(VATExchRateProgressBarTxt + VATEntriesProgressBarTxt);

        VATEntry.SetRange("Posting Date", ExchRateAdjmtParameters."Start Date", ExchRateAdjmtParameters."End Date");
        Currency.SetView(ExchRateAdjmtParameters."Currency Filter");

        NewVATEntry.LockTable();
        if NewVATEntry.FindLast() then
            FirstVATEntryNo := NewVATEntry."Entry No." + 1;

        VATEntryNoTotal := VATEntry.Count();
        VATEntry.SetRange("Posting Date", ExchRateAdjmtParameters."Start Date", ExchRateAdjmtParameters."End Date");
        if VATEntry.FindSet() then
            repeat
                VATEntriesCounter := VATEntriesCounter + 1;
                Window.Update(1, Round(VATEntriesCounter / VATEntryNoTotal * 10000, 1));

                ProcessVATEntryAdjustment(VATEntry, ExchRateAdjmtParameters, GenJnlPostLine);
            until VATEntry.Next() = 0;

        UpdateGLRegToVATEntryNo(GenJnlPostLine);
    end;

    local procedure ProcessVATEntryAdjustment(var VATEntry: Record "VAT Entry"; ExchRateAdjmtParameters: Record "Exch. Rate Adjmt. Parameters"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    begin
        if (not VATEntry."Unadjusted Exchange Rate") or VATEntry.Closed then
            exit;

        if (VATEntry.Type = VATEntry.Type::Sale) and
            (VATEntry."VAT Calculation Type" = VATEntry."VAT Calculation Type"::"Reverse Charge VAT")
        then
            exit;

        if VATEntry.Type in [VATEntry.Type::Sale, VATEntry.Type::Purchase] then begin
            NewVATEntry := VATEntry;
            AdjustVATRate(VATEntry, ExchRateAdjmtParameters, GenJnlPostLine);
        end;
    end;

    local procedure GetGLSetup()
    begin
        if not GLSetupRead then
            GLSetup.Get();

        GLSetupRead := true;
    end;

    local procedure GetAdditionalReportingCurrency(): Code[10]
    begin
        GetGLSetup();
        exit(GLSetup."Additional Reporting Currency");
    end;

    // CH Begin
    local procedure AdjustVATRate(VATEntry: Record "VAT Entry"; ExchRateAdjmtParameters: Record "Exch. Rate Adjmt. Parameters"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    var
        Currency1: Record Currency;
        CurrExchRate: Record "Currency Exchange Rate";
        GenJnlLine: Record "Gen. Journal Line";
        GLEntry: Record "G/L Entry";
        GLEntryVATEntryLink: Record "G/L Entry - VAT Entry Link";
        VATGLEntry: Record "G/L Entry";
        VATPostingSetup2: Record "VAT Posting Setup";
        FixAmount: Decimal;
        FixAmountAddCurr: Decimal;
        CorrBaseAmount: Decimal;
        CorrBaseAmtAddCurr: Decimal;
        VATEntryNoToModify: Integer;
        PostingDate: Date;
    begin
        GLSetup.Get();
        SourceCodeSetup.Get();

        CurrExchRate.SetRange("Currency Code", VATEntry."Currency Code");
        CurrExchRate.SetRange("Starting Date", 0D, VATEntry."Posting Date");
        if not CurrExchRate.FindLast() then
            exit;

        CurrExchRate.TestField("VAT Exch. Rate Amount");
        CurrExchRate.TestField("Relational VAT Exch. Rate Amt");
        Currency1.Get(VATEntry."Currency Code");
        Currency1.TestField("Realized Gains Acc.");
        Currency1.TestField("Realized Losses Acc.");

        FixAmount :=
            Round(
                VATEntry."Amount (FCY)" / CurrExchRate."VAT Exch. Rate Amount" * CurrExchRate."Relational VAT Exch. Rate Amt",
                GLSetup."Amount Rounding Precision") -
            VATEntry.Amount;

        CorrBaseAmount :=
            Round(
                VATEntry."Base (FCY)" / CurrExchRate."VAT Exch. Rate Amount" * CurrExchRate."Relational VAT Exch. Rate Amt",
                GLSetup."Amount Rounding Precision") -
            VATEntry.Base;

        if FixAmount <> 0 then begin
            VATPostingSetup2.Get(VATEntry."VAT Bus. Posting Group", VATEntry."VAT Prod. Posting Group");

            GLEntryVATEntryLink.SetRange("VAT Entry No.", VATEntry."Entry No.");
            if GLEntryVATEntryLink.FindFirst() then begin
                VATGLEntry.Get(GLEntryVATEntryLink."G/L Entry No.");
                DimMgt.GetDimensionSet(TempDimSetEntry, VATGLEntry."Dimension Set ID");
            end;

            // Additional exchange rate adjustment only if "VAT Calculation Type" is "Reverse Charge VAT" (Erwerbssteuer)
            if VATEntry."VAT Calculation Type" = VATEntry."VAT Calculation Type"::"Reverse Charge VAT" then begin
                GenJnlLine.Init();
                GenJnlLine."Posting Date" := VATEntry."Posting Date";
                GenJnlLine."Document No." := VATEntry."Document No.";
                GenJnlLine."Account Type" := GenJnlLine."Account Type"::"G/L Account";
                GenJnlLine."Reason Code" := VATEntry."Reason Code";
                GenJnlLine."Source Code" := SourceCodeSetup."Exchange Rate Adjmt.";

                if FixAmount > 0 then
                    GenJnlLine.Validate("Account No.", Currency1.GetRealizedLossesAccount());
                if FixAmount < 0 then
                    GenJnlLine.Validate("Account No.", Currency1.GetRealizedGainsAccount());

                if VATEntry.Type = VATEntry.Type::Sale then begin
                    VATPostingSetup2.TestField("Sales VAT Account");
                    GenJnlLine.Validate("Bal. Account No.", VATPostingSetup2."Sales VAT Account");
                end else begin
                    GenJnlLine.Validate("Bal. Account No.", VATPostingSetup2."Reverse Chrg. VAT Acc.");
                    VATPostingSetup2.TestField("Reverse Chrg. VAT Acc.");
                end;

                GenJnlLine."System-Created Entry" := true;
                GenJnlLine.Description := Text92000Txt + Format(VATEntry."Document No.");
                GenJnlLine."Bill-to/Pay-to No." := VATEntry."Bill-to/Pay-to No.";

                GenJnlLine.Validate(Amount, FixAmount);

                PostGenJnlLine(GenJnlLine, TempDimSetEntry, GenJnlPostLine, ExchRateAdjmtParameters);
                GLEntry.FindLast();
                CorrRevChargeEntryNo := GLEntry."Entry No.";
            end;

            GenJnlLine.Init();
            GenJnlLine."Posting Date" := VATEntry."Posting Date";
            GenJnlLine."Document No." := VATEntry."Document No.";
            GenJnlLine."Account Type" := GenJnlLine."Account Type"::"G/L Account";
            GenJnlLine."Reason Code" := VATEntry."Reason Code";
            GenJnlLine."Source Code" := SourceCodeSetup."Exchange Rate Adjmt.";
            if VATEntry.Type = VATEntry.Type::Sale then begin
                VATPostingSetup2.TestField("Sales VAT Account");
                GenJnlLine.Validate("Account No.", VATPostingSetup2."Sales VAT Account");
            end else begin
                VATPostingSetup2.TestField("Purchase VAT Account");
                GenJnlLine.Validate("Account No.", VATPostingSetup2."Purchase VAT Account");
            end;
            if FixAmount > 0 then
                GenJnlLine.Validate("Bal. Account No.", Currency1."Realized Gains Acc.");
            if FixAmount < 0 then
                GenJnlLine.Validate("Bal. Account No.", Currency1."Realized Losses Acc.");
            GenJnlLine."System-Created Entry" := true;
            GenJnlLine.Description := Text92000Txt + Format(VATEntry."Document No.");
            GenJnlLine."Bill-to/Pay-to No." := VATEntry."Bill-to/Pay-to No.";
            GenJnlLine.Validate(Amount, FixAmount);

            Clear(GenJnlPostLine);
            PostGenJnlLine(GenJnlLine, TempDimSetEntry, GenJnlPostLine, ExchRateAdjmtParameters);
            GLEntry.FindLast();
            NewVATEntry.SetRange("Transaction No.", GLEntry."Transaction No.");
            if NewVATEntry.FindLast() then
                VATEntryNoToModify := NewVATEntry."Entry No.";
        end;

        if (FixAmount <> 0) or (Abs(CorrBaseAmount) > 0.01) then begin  // Don't correct differences of 1 Cent or less
                                                                        // adjust VAT entries
            NewVATEntry := VATEntry;
            NewVATEntry."Currency Factor" := CurrExchRate."VAT Exch. Rate Amount" / CurrExchRate."Relational VAT Exch. Rate Amt";
            NewVATEntry.Amount := FixAmount;
            NewVATEntry.Base := CorrBaseAmount;

            // adjust additional currency
            if (NewVATEntry."Additional-Currency Amount" <> 0) or (NewVATEntry."Additional-Currency Base" <> 0) then begin
                Currency1.Get(GetAdditionalReportingCurrency());
                CurrExchRate.SetRange("Currency Code", GetAdditionalReportingCurrency());
                if CurrExchRate.FindLast() then begin
                    CurrExchRate.TestField("Exchange Rate Amount");
                    CurrExchRate.TestField("Relational Exch. Rate Amount");

                    FixAmountAddCurr :=
                      Round(
                        CurrExchRate.ExchangeAmtLCYToFCY(
                            PostingDate, GetAdditionalReportingCurrency(), VATEntry.Amount + FixAmount,
                            CurrExchRate.ExchangeRate(PostingDate, GetAdditionalReportingCurrency())),
                        Currency1."Amount Rounding Precision") -
                      VATEntry."Additional-Currency Amount";
                    CorrBaseAmtAddCurr :=
                      Round(
                        CurrExchRate.ExchangeAmtLCYToFCY(
                            PostingDate, GetAdditionalReportingCurrency(), VATEntry.Base + CorrBaseAmount,
                            CurrExchRate.ExchangeRate(PostingDate, GetAdditionalReportingCurrency())),
                        Currency1."Amount Rounding Precision") -
                      VATEntry."Additional-Currency Base";

                    NewVATEntry."Additional-Currency Amount" := FixAmountAddCurr;
                    NewVATEntry."Additional-Currency Base" := CorrBaseAmtAddCurr;
                end;
            end;

            NewVATEntry."Unadjusted Exchange Rate" := false;
            NewVATEntry."Amount (FCY)" := 0;
            NewVATEntry."Base (FCY)" := 0;
            NewVATEntry."VAT Difference" := 0;
            NewVATEntry."Add.-Curr. VAT Difference" := 0;
            NewVATEntry."Exchange Rate Adjustment" := true;

            if VATEntryNoToModify <> 0 then begin
                NewVATEntry."Entry No." := VATEntryNoToModify;
                NewVATEntry.Modify()
            end else begin
                NewVATEntry4No.FindLast();
                NewVATEntry."Entry No." := NewVATEntry4No."Entry No." + 1;
                NewVATEntry.Insert();
            end;
            if GLEntry."Entry No." = 0 then begin
                VATEntryLink.SetRange("VAT Entry No.", VATEntry."Entry No.");
                if VATEntryLink.FindFirst() then
                    GLEntry."Entry No." := VATEntryLink."G/L Entry No.";
            end;
            if GLEntry."Entry No." <> 0 then
                if not VATEntryLink.Get(GLEntry."Entry No.", NewVATEntry."Entry No.") then
                    VATEntryLink.InsertLinkSelf(GLEntry."Entry No.", NewVATEntry."Entry No.");
            if CorrRevChargeEntryNo <> 0 then begin
                GLEntry.Get(CorrRevChargeEntryNo);
                if not VATEntryLink.Get(GLEntry."Entry No.", NewVATEntry."Entry No.") then
                    VATEntryLink.InsertLinkSelf(GLEntry."Entry No.", NewVATEntry."Entry No.");
            end;
        end;

        VATEntry."Unadjusted Exchange Rate" := false;
        VATEntry.Modify();

        UpdateGLRegToVATEntryNo(GenJnlPostLine);
    end;

    local procedure UpdateGLRegToVATEntryNo(var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    var
        GLRegister: Record "G/L Register";
    begin
        GenJnlPostLine.GetGLReg(GLRegister);
        if GLRegister."No." <> 0 then begin
            GLRegister."To VAT Entry No." := NewVATEntry."Entry No.";
            GLRegister.Modify();
        end else
            if NewVATEntry."Entry No." >= FirstVATEntryNo then begin
                GLRegister.LockTable();
                GLRegister.FindLast();
                GLRegister.Init();
                GLRegister."No." := GLRegister."No." + 1;

                SourceCodeSetup.Get();
                GLRegister."Source Code" := SourceCodeSetup."Exchange Rate Adjmt.";
                GLRegister."User ID" := CopyStr(UserId(), 1, MaxStrLen(GLRegister."User ID"));
                GLRegister."From VAT Entry No." := FirstVATEntryNo;
                GLRegister."To VAT Entry No." := NewVATEntry."Entry No.";
                GLRegister.Insert();
            end;
    end;

    local procedure PostGenJnlLine(var GenJnlLine: Record "Gen. Journal Line"; var DimSetEntry: Record "Dimension Set Entry"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; ExchRateAdjmtParameters: Record "Exch. Rate Adjmt. Parameters"): Integer
    begin
        GenJnlLine."Journal Template Name" := ExchRateAdjmtParameters."Journal Template Name";
        GenJnlLine."Journal Batch Name" := ExchRateAdjmtParameters."Journal Batch Name";
        GenJnlLine."Shortcut Dimension 1 Code" := GetGlobalDimVal(GLSetup."Global Dimension 1 Code", DimSetEntry);
        GenJnlLine."Shortcut Dimension 2 Code" := GetGlobalDimVal(GLSetup."Global Dimension 2 Code", DimSetEntry);
        GenJnlLine."Dimension Set ID" := DimMgt.GetDimensionSetID(TempDimSetEntry);
        GenJnlPostLine.Run(GenJnlLine);
        exit(GenJnlPostLine.GetNextTransactionNo());
    end;

    local procedure GetGlobalDimVal(GlobalDimCode: Code[20]; var DimSetEntry: Record "Dimension Set Entry"): Code[20]
    var
        DimVal: Code[20];
    begin
        if GlobalDimCode = '' then
            DimVal := ''
        else begin
            DimSetEntry.SetRange("Dimension Code", GlobalDimCode);
            if DimSetEntry.Find('-') then
                DimVal := DimSetEntry."Dimension Value Code"
            else
                DimVal := '';
            DimSetEntry.SetRange("Dimension Code");
        end;
        exit(DimVal);
    end;
    // CH.end
}