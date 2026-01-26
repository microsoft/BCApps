// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Statement;

using Microsoft.Bank.Payment;
using Microsoft.Finance.Currency;
using Microsoft.Purchases.Payables;
using Microsoft.Sales.Receivables;
using System.Utilities;

codeunit 11000002 "CBG Journal Telebank Interface"
{

    trigger OnRun()
    begin
    end;

    var
        AmountToApplyIsChangedQst: Label 'The amount has been adjusted in one or more applied entries. All CBG statement lines will be created using the adjusted amounts.\\Do you want to apply the corrected amounts to all lines in this CBG statement?';

    [Scope('OnPrem')]
    procedure InsertPaymentHistory(CBGStatement: Record "CBG Statement")
    var
        PaymHistOverview: Page "Payment History List";
        PaymHist: Record "Payment History";
        PaymentHistLine: Record "Payment History Line";
        CBGStatementLine: Record "CBG Statement Line";
        LineAmount: Decimal;
        IsConfirmHandled: Boolean;
        UseAdjustedAmount: Boolean;
    begin
        OnBeforeInsertPaymentHistory(CBGStatement);
        CBGStatement.TestField(Type, CBGStatement.Type::"Bank/Giro");
        CBGStatement.TestField("Account Type", CBGStatement."Account Type"::"Bank Account");

        PaymHist.SetCurrentKey("Our Bank", Status);
        PaymHist.Ascending(false);
        PaymHist.SetRange("Our Bank", CBGStatement."Account No.");
        PaymHist.SetRange(Status, PaymHist.Status::Transmitted);
        PaymHist.SetFilter("Remaining Amount", '<>%1', 0);

        PaymHistOverview.SetTableView(PaymHist);
        PaymHistOverview.LookupMode(true);
        PaymHistOverview.Editable(false);
        if PaymHistOverview.RunModal() = ACTION::LookupOK then begin
            PaymHistOverview.GetRecord(PaymHist);
            PaymentHistLine.SetCurrentKey("Our Bank", Status);
            PaymentHistLine.SetRange("Our Bank", PaymHist."Our Bank");
            PaymentHistLine.SetRange("Run No.", PaymHist."Run No.");
            PaymentHistLine.SetFilter(Status, '%1|%2',
              PaymentHistLine.Status::Transmitted,
              PaymentHistLine.Status::"Request for Cancellation");
            if PaymentHistLine.Find('-') then begin
                CBGStatementLine.SetRange("Journal Template Name", CBGStatement."Journal Template Name");
                CBGStatementLine.SetRange("No.", CBGStatement."No.");
                repeat
                    if CBGStatementLine.FindLast() then
                        CBGStatementLine."Line No." := CBGStatementLine."Line No." + 10000
                    else begin
                        CBGStatementLine."Line No." := 10000;
                        CBGStatementLine."Journal Template Name" := CBGStatement."Journal Template Name";
                        CBGStatementLine."No." := CBGStatement."No.";
                    end;
                    CheckConfirmPaymentHistoryAmount(PaymentHistLine, LineAmount, IsConfirmHandled, UseAdjustedAmount);
                    InsertCBGStatementLine(CBGStatementLine, CBGStatement, PaymentHistLine, UseAdjustedAmount, LineAmount);
                until PaymentHistLine.Next() = 0;
            end;
        end;
    end;

    local procedure InsertCBGStatementLine(var CBGStatementLine: Record "CBG Statement Line"; CBGStatement: Record "CBG Statement"; PaymentHistLine: Record "Payment History Line"; UseAdjustedAmount: Boolean; AdjustedAmount: Decimal)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInsertCBGStatementLine(CBGStatementLine, CBGStatement, PaymentHistLine, IsHandled);
        if IsHandled then
            exit;

        CBGStatementLine.Init();
        CBGStatementLine.InitRecord(CBGStatementLine);
        CBGStatementLine.Validate(Identification, PaymentHistLine.Identification);
        CBGStatementLine.Insert(true);
        if UseAdjustedAmount then begin
            CBGStatementLine."Amount Settled" := AdjustedAmount;
            CBGStatementLine.Validate(Amount, AdjustedAmount)
        end else begin
            CBGStatementLine."Amount Settled" := CBGStatementLine.Amount;
            CBGStatementLine.Validate(Amount);
        end;
        CBGStatementLine.Validate("Shortcut Dimension 1 Code", PaymentHistLine."Global Dimension 1 Code");
        CBGStatementLine.Validate("Shortcut Dimension 2 Code", PaymentHistLine."Global Dimension 2 Code");
        OnInsertCBGStatementLineOnBeforeCBGStatementLineModify(CBGStatementLine, CBGStatement, PaymentHistLine);
        CBGStatementLine.Modify(true);
    end;

    local procedure CheckConfirmPaymentHistoryAmount(PaymentHistoryLine: Record "Payment History Line"; var LineAmount: Decimal; var IsConfirmHandled: Boolean; var UseAdjustedAmount: Boolean)
    var
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        LineAmount := PaymentHistoryLine.Amount;
        if PaymentHistoryLine."Account Type" = PaymentHistoryLine."Account Type"::Employee then
            IsConfirmHandled := true;

        if IsConfirmHandled and not UseAdjustedAmount then
            exit;

        LineAmount := CalcPaymentHistoryLineAmount(PaymentHistoryLine);
        if IsConfirmHandled then
            exit;

        if not (LineAmount in [0, PaymentHistoryLine.Amount]) then begin
            UseAdjustedAmount :=
                ConfirmManagement.GetResponse(AmountToApplyIsChangedQst, false);
            IsConfirmHandled := true;
        end;
    end;

    procedure CalcPaymentHistoryLineAmount(PaymentHistoryLine: Record "Payment History Line") Amount: Decimal
    var
        DetailLine: Record "Detail Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        DetailLine.SetCurrentKey("Our Bank", Status, "Connect Batches");
        DetailLine.SetRange("Our Bank", PaymentHistoryLine."Our Bank");
        DetailLine.SetRange(Status, DetailLine.Status::"In process");
        DetailLine.SetRange("Connect Batches", PaymentHistoryLine."Run No.");
        DetailLine.SetRange("Connect Lines", PaymentHistoryLine."Line No.");
        DetailLine.SetFilter("Serial No. (Entry)", '<>%1', 0);
        if DetailLine.FindSet() then
            repeat
                case DetailLine."Account Type" of
                    DetailLine."Account Type"::Customer:
                        if CustLedgerEntry.Get(DetailLine."Serial No. (Entry)") then begin
                            DetailedCustLedgEntry.SetCurrentKey("Cust. Ledger Entry No.", "Posting Date");
                            DetailedCustLedgEntry.SetRange("Cust. Ledger Entry No.", CustLedgerEntry."Entry No.");
                            DetailedCustLedgEntry.SetFilter(
                              "Entry Type", '%1|%2',
                              DetailedCustLedgEntry."Entry Type"::"Unrealized Gain", DetailedCustLedgEntry."Entry Type"::"Unrealized Loss");
                            if DetailedCustLedgEntry.FindLast() then
                                Amount +=
                                  CurrencyExchangeRate.ExchangeAmtFCYToFCY(
                                    DetailedCustLedgEntry."Posting Date",
                                    DetailLine."Currency Code (Entry)", DetailLine."Currency Code", DetailLine."Amount (Entry)")
                            else
                                Amount += DetailLine.Amount;
                        end;
                    DetailLine."Account Type"::Vendor:
                        if VendorLedgerEntry.Get(DetailLine."Serial No. (Entry)") then begin
                            DetailedVendorLedgEntry.SetCurrentKey("Vendor Ledger Entry No.", "Posting Date");
                            DetailedVendorLedgEntry.SetRange("Vendor Ledger Entry No.", VendorLedgerEntry."Entry No.");
                            DetailedVendorLedgEntry.SetFilter(
                              "Entry Type", '%1|%2',
                              DetailedVendorLedgEntry."Entry Type"::"Unrealized Gain", DetailedVendorLedgEntry."Entry Type"::"Unrealized Loss");
                            if DetailedVendorLedgEntry.FindLast() then
                                Amount +=
                                  CurrencyExchangeRate.ExchangeAmtFCYToFCY(
                                    DetailedVendorLedgEntry."Posting Date",
                                    DetailLine."Currency Code (Entry)", DetailLine."Currency Code", DetailLine."Amount (Entry)")
                            else
                                Amount += DetailLine.Amount;
                        end;
                end;
            until DetailLine.Next() = 0;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertCBGStatementLine(var CBGStatementLine: Record "CBG Statement Line"; CBGStatement: Record "CBG Statement"; PaymentHistoryLine: Record "Payment History Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertPaymentHistory(CBGStatement: Record "CBG Statement")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertCBGStatementLineOnBeforeCBGStatementLineModify(var CBGStatementLine: Record "CBG Statement Line"; CBGStatement: Record "CBG Statement"; PaymentHistoryLine: Record "Payment History Line")
    begin
    end;
}

