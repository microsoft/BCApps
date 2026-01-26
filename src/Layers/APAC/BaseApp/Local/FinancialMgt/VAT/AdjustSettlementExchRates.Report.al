// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Posting;
using Microsoft.Finance.VAT.Ledger;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.AuditCodes;

report 28140 "Adjust Settlement Exch. Rates"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Adjust Settlement Exch. Rates';
    ProcessingOnly = true;
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Currency; Currency)
        {
            DataItemTableView = sorting(Code);
            RequestFilterFields = "Code";

            trigger OnAfterGetRecord()
            begin
                CurrExchRate.Reset();
                CurrExchRate.SetRange("Currency Code", Code);
                CurrExchRate.SetRange("Starting Date", 0D, StartDate);
                if CurrExchRate.FindLast() then
                    if CurrExchRate."Relational Currency Code" <> '' then
                        if UseDailyRate then begin
                            SettRate := CurrExchRate."Settlement Rate Amount";
                            RelSettRate := CurrExchRate."Relational Sett. Rate Amount";
                            RelCurrCode := CurrExchRate."Relational Currency Code";
                            CurrExchRate.SetFilter("Currency Code", RelCurrCode);
                            CurrExchRate.SetRange("Starting Date", 0D, StartDate);
                            if CurrExchRate.FindLast() then begin
                                CurrencyCode := CurrExchRate."Currency Code";
                                ExchRate := CurrExchRate."Exchange Rate Amount";
                                RelExchRate := CurrExchRate."Relational Exch. Rate Amount";
                                CurrencyFactor := (RelSettRate * RelExchRate) / (ExchRate * SettRate);
                            end;
                        end;
                VATCount := 0;
                CurrExchRate.Reset();
                CurrExchRate.SetRange("Currency Code", Code);
                if not UseDailyRate then begin
                    CurrExchRate.SetFilter("Starting Date", '..%1', CalcDate('-1D', StartDate));
                    CurrExchRate.FindLast();
                    CurrExchRate.TestField("Settlement Rate Amount");
                    CurrExchRate.TestField("Relational Sett. Rate Amount");
                end;
                VATEntry.LockTable();
                VATEntry.Reset();
                VATEntry.SetCurrentKey("Document Type", Type, "Currency Code", "Posting Date", Closed);
                VATEntry.SetRange("Document Type", VATEntry."Document Type"::Payment);
                VATEntry.SetFilter(Type, '<>%1', VATEntry.Type::Settlement);
                VATEntry.SetRange("Currency Code", Code);
                VATEntry.SetFilter("Posting Date", '%1..%2', StartDate, EndDateReq);
                VATEntry.SetRange(Closed, false);
                VATEntry.SetRange("Settlement Adjustment", false);
                VATCountTotal := VATEntry.Count();
                if VATEntry.FindSet() then
                    repeat
                        VATEntry2.Reset();
                        VATEntry2.Get(VATEntry."Unrealized VAT Entry No.");
                        if VATEntry2."Posting Date" < StartDate then begin
                            if UseDailyRate then begin
                                CurrExchRate.SetFilter("Starting Date", '..%1', VATEntry."Posting Date");
                                CurrExchRate.FindLast();
                            end;
                            VATCount := VATCount + 1;
                            Window.Update(1, Round(VATCount / VATCountTotal * 10000, 1));
                            PaymentTotal := VATEntry.Amount;
                            BaseTotal := VATEntry.Base;
                            if (PaymentTotal <> 0) and (BaseTotal <> 0) then begin
                                VATEntry4.Reset();
                                VATEntry4.SetRange("Sett. Payment Entry No.", VATEntry."Entry No.");
                                if (VATEntry."Sett. Unrealized Amount" <> 0) and (not VATEntry4.FindFirst()) then begin
                                    PaymentFactor := PaymentTotal / VATEntry."Sett. Unrealized Amount";
                                    ActualPaymentTotal := PaymentTotal + GetVatEntryPaymentTotal(VATEntry."Entry No.");
                                    if RelCurrCode = '' then begin
                                        FCYFactorAmount := VATEntry."Sett. Unrealised Amount (FCY)" * PaymentFactor;
                                        FCYFactorAmount := Round(FCYFactorAmount /
                                            (CurrExchRate."Settlement Rate Amount" / CurrExchRate."Relational Sett. Rate Amount"));
                                    end else
                                        FCYFactorAmount := VATEntry."Sett. Unrealised Amount (FCY)" * CurrencyFactor;
                                    PaymentTotal := FCYFactorAmount - ActualPaymentTotal;
                                    BaseFactor := BaseTotal / VATEntry."Sett. Unrealized Base";
                                    ActualBaseTotal := BaseTotal + GetVatEntryBaseTotal(VATEntry."Entry No.");
                                    if RelCurrCode = '' then begin
                                        FCYFactorBase := VATEntry."Sett. Unrealised Base (FCY)" * BaseFactor;
                                        FCYFactorBase := Round(FCYFactorBase /
                                            (CurrExchRate."Settlement Rate Amount" / CurrExchRate."Relational Sett. Rate Amount"));
                                    end else
                                        FCYFactorBase := VATEntry."Sett. Unrealised Base (FCY)" * CurrencyFactor;
                                    BaseTotal := FCYFactorBase - ActualBaseTotal;
                                    InsertVATEntry(VATEntry."Entry No.", PaymentTotal, BaseTotal);
                                end;
                            end;
                        end;
                    until VATEntry.Next() = 0;
            end;

            trigger OnPreDataItem()
            begin
                Window.Open(
                  Text002 +
                  Text003 +
                  Text010);
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(StartDate; StartDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Settlement Period';
                        ToolTip = 'Specifies the start date of the settlement period.';
                    }
                    field(EndDateReq; EndDateReq)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Ending Date';
                        ToolTip = 'Specifies the last date for the report.';
                    }
                    field(PostingDescription; PostingDescription)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Posting Description';
                        ToolTip = 'Specifies the posting description.';
                    }
                    field(PostingDocNo; PostingDocNo)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Document No.';
                        ToolTip = 'Specifies the original document that is associated with this entry.';
                    }
                    field(PostingDate; PostingDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Posting Date';
                        ToolTip = 'Specifies the posting date of the entry.';
                    }
                    field(UseDailyRate; UseDailyRate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Use Daily Settlement Exch. Rate';
                        ToolTip = 'Specifies that you want to use the daily settlement exchange rate.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            if PostingDescription = '' then
                PostingDescription := Text001;
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        if PostingDocNo = '' then
            Error(Text000, GenJnlLine.FieldCaption("Document No."));
    end;

    var
        Window: Dialog;
        VATEntry: Record "VAT Entry";
        VATEntry2: Record "VAT Entry";
        VATPostingSetup: Record "VAT Posting Setup";
        CurrExchRate: Record "Currency Exchange Rate";
        GenJnlLine: Record "Gen. Journal Line";
        SourceCodeSetup: Record "Source Code Setup";
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
        PostingDocNo: Code[20];
        CurrencyCode: Code[10];
        StartDate: Date;
        EndDateReq: Date;
        PostingDate: Date;
        PostingDescription: Text[50];
        VATCount: Integer;
        VATCountTotal: Integer;
        PaymentFactor: Decimal;
        PaymentTotal: Decimal;
        BaseFactor: Decimal;
        BaseTotal: Decimal;
        ActualPaymentTotal: Decimal;
        ActualBaseTotal: Decimal;
        FCYFactorAmount: Decimal;
        FCYFactorBase: Decimal;
        UseDailyRate: Boolean;
        Text000: Label 'You must specify %1.';
        Text001: Label 'Settlement Exch. Rate Adjmt. of %1 %2';
        Text002: Label 'Adjusting settlement exchange rates...\\';
        Text003: Label 'VAT Entry  @1@@@@@@@@@@@@@\\';
        Text010: Label 'Adjustment      #4#############';
        ExchRate: Decimal;
        RelExchRate: Decimal;
        RelSettRate: Decimal;
        SettRate: Decimal;
        RelCurrCode: Code[10];
        CurrencyFactor: Decimal;
        VATEntry4: Record "VAT Entry";

    [Scope('OnPrem')]
    procedure GetVatEntryPaymentTotal(VATEntryNo: Integer) TotalAmt: Decimal
    var
        VATEntryPay: Record "VAT Entry";
    begin
        VATEntryPay.Reset();
        VATEntryPay.SetCurrentKey("Sett. Payment Entry No.");
        VATEntryPay.SetRange("Sett. Payment Entry No.", VATEntryNo);
        VATEntryPay.CalcSums(Amount);
        exit(VATEntryPay.Amount);
    end;

    [Scope('OnPrem')]
    procedure GetVatEntryBaseTotal(VATEntryNo: Integer) TotalAmt: Decimal
    var
        VATEntryBase: Record "VAT Entry";
    begin
        VATEntryBase.Reset();
        VATEntryBase.SetCurrentKey("Sett. Payment Entry No.");
        VATEntryBase.SetRange("Sett. Payment Entry No.", VATEntryNo);
        VATEntryBase.CalcSums(Base);
        exit(VATEntryBase.Base);
    end;

    [Scope('OnPrem')]
    procedure InsertVATEntry(VATEntryNo: Integer; VATAmount: Decimal; VATBase: Decimal)
    var
        VATEntry2: Record "VAT Entry";
        VATEntry3: Record "VAT Entry";
        EntryNo: Integer;
    begin
        if (VATAmount = 0) and (VATBase = 0) then
            exit;
        VATEntry2.Reset();
        VATEntry2.FindLast();
        EntryNo := VATEntry2."Entry No." + 1;
        VATEntry3.Reset();
        VATEntry3.Init();
        VATEntry3.TransferFields(VATEntry);
        VATEntry3."Entry No." := EntryNo;
        VATEntry3.Amount := VATAmount;
        VATEntry3.Base := VATBase;
        VATEntry3."Sett. Unrealised Amount (FCY)" := VATEntry."Sett. Unrealised Amount (FCY)" * PaymentFactor;
        VATEntry3."Sett. Unrealised Base (FCY)" := VATEntry."Sett. Unrealised Base (FCY)" * BaseFactor;
        VATEntry3."Unrealized Amount" := 0;
        VATEntry3."Unrealized Base" := 0;
        VATEntry3."Remaining Unrealized Amount" := 0;
        VATEntry3."Remaining Unrealized Base" := 0;
        VATEntry3."Sett. Payment Entry No." := VATEntryNo;
        VATEntry3."Settlement Adjustment" := true;
        VATEntry3.Insert();

        SourceCodeSetup.Get();
        VATPostingSetup.Get(VATEntry."VAT Bus. Posting Group", VATEntry."VAT Prod. Posting Group");

        GenJnlLine.Init();
        GenJnlLine.Validate("Account Type", GenJnlLine."Account Type"::"G/L Account");
        case VATEntry.Type of
            VATEntry.Type::Sale:
                GenJnlLine.Validate("Account No.", VATPostingSetup."Sales VAT Account");
            VATEntry.Type::Purchase:
                GenJnlLine.Validate("Account No.", VATPostingSetup."Purchase VAT Account");
        end;
        GenJnlLine.Validate("Posting Date", PostingDate);
        GenJnlLine.Validate("Document Type", GenJnlLine."Document Type"::" ");
        GenJnlLine."Document No." := PostingDocNo;
        GenJnlLine.Description :=
          StrSubstNo(
            PostingDescription, Currency.Code, VATAmount);
        GenJnlLine.Amount := VATAmount;
        GenJnlLine."Amount (LCY)" := GenJnlLine.Amount;
        GenJnlLine."Source Code" := SourceCodeSetup."Exchange Rate Adjmt.";
        GenJnlLine."System-Created Entry" := true;
        GenJnlLine.Validate("Bal. Account Type", GenJnlLine."Bal. Account Type"::"G/L Account");
        if GenJnlLine."Debit Amount" <> 0 then
            GenJnlLine.Validate("Bal. Account No.", Currency."Realized Gains Acc.")
        else
            GenJnlLine.Validate("Bal. Account No.", Currency."Realized Losses Acc.");
        GenJnlPostLine.Run(GenJnlLine);
    end;
}

