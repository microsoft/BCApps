// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.ReceivablesPayables;

using Microsoft.Bank.Statement;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;

codeunit 11426 "Payment Tolerance Mgt. NL"
{
    Access = Internal;

    [Scope('OnPrem')]
    procedure PmtTolCBGJnl(var CBGStatementLine: Record "CBG Statement Line"): Boolean
    var
        GLSetup: Record "General Ledger Setup";
        Customer: Record Customer;
        Vendor: Record Vendor;
        NewCustLedgEntry: Record "Cust. Ledger Entry";
        NewVendLedgEntry: Record "Vendor Ledger Entry";
        PaymentToleranceMgt: Codeunit "Payment Tolerance Management";
        AppliedAmount: Decimal;
        OriginalAppliedAmount: Decimal;
        ApplyingAmount: Decimal;
        AmounttoApply: Decimal;
        PmtDiscAmount: Decimal;
        MaxPmtTolAmount: Decimal;
        CBGStatementLineApplID: Code[20];
        ApplnRoundingPrecision: Decimal;
        CBGStatement: Record "CBG Statement";
        UseDocumentNo: Code[20];
    begin
        MaxPmtTolAmount := 0;
        PmtDiscAmount := 0;
        AppliedAmount := 0;
        ApplyingAmount := 0;
        AmounttoApply := 0;

        if CBGStatementLine."Account Type" = CBGStatementLine."Account Type"::Customer then begin
            Customer.Get(CBGStatementLine."Account No.");
            if Customer."Block Payment Tolerance" then
                exit(false);
        end else
            if CBGStatementLine."Account Type" = CBGStatementLine."Account Type"::Vendor then begin
                Vendor.Get(CBGStatementLine."Account No.");
                if Vendor."Block Payment Tolerance" then
                    exit(false);
            end;

        CBGStatement.Get(CBGStatementLine."Journal Template Name", CBGStatementLine."No.");
        GLSetup.Get();
        if CBGStatementLine."Applies-to Doc. No." = '' then
            if CBGStatementLine."Applies-to ID" <> '' then
                CBGStatementLineApplID := CBGStatementLine."Applies-to ID";

        if CBGStatementLine."Account Type" = CBGStatementLine."Account Type"::Customer then begin
            NewCustLedgEntry."Posting Date" := CBGStatementLine.Date;
            NewCustLedgEntry."Document No." := CBGStatementLine."Document No.";
            NewCustLedgEntry."Customer No." := CBGStatementLine."Account No.";
            NewCustLedgEntry."Currency Code" := CBGStatement.Currency;
            if CBGStatementLine."Applies-to Doc. No." <> '' then
                NewCustLedgEntry."Applies-to Doc. No." := CBGStatementLine."Applies-to Doc. No.";
            PaymentToleranceMgt.DelCustPmtTolAcc(NewCustLedgEntry, CBGStatementLineApplID);
            NewCustLedgEntry.Amount := CBGStatementLine.Amount;
            NewCustLedgEntry."Remaining Amount" := CBGStatementLine.Amount;
            case (CBGStatementLine.Amount >= 0) of
                true:
                    NewCustLedgEntry."Document Type" := NewCustLedgEntry."Document Type"::Refund;
                false:
                    NewCustLedgEntry."Document Type" := NewCustLedgEntry."Document Type"::Payment;
            end;
            PaymentToleranceMgt.CalcCustApplnAmount(
              NewCustLedgEntry, GLSetup, AppliedAmount, ApplyingAmount, AmounttoApply, PmtDiscAmount,
              MaxPmtTolAmount, CBGStatementLineApplID, ApplnRoundingPrecision);
        end else begin
            NewVendLedgEntry."Posting Date" := CBGStatementLine.Date;
            NewVendLedgEntry."Document No." := CBGStatementLine."Document No.";
            NewVendLedgEntry."Vendor No." := CBGStatementLine."Account No.";
            NewVendLedgEntry."Currency Code" := CBGStatement.Currency;
            if CBGStatementLine."Applies-to Doc. No." <> '' then
                NewVendLedgEntry."Applies-to Doc. No." := CBGStatementLine."Applies-to Doc. No.";
            PaymentToleranceMgt.DelVendPmtTolAcc(NewVendLedgEntry, CBGStatementLineApplID);
            NewVendLedgEntry.Amount := CBGStatementLine.Amount;
            NewVendLedgEntry."Remaining Amount" := CBGStatementLine.Amount;
            NewVendLedgEntry."Document Type" := NewVendLedgEntry."Document Type"::Payment;
            PaymentToleranceMgt.CalcVendApplnAmount(
              NewVendLedgEntry, GLSetup, AppliedAmount, ApplyingAmount, AmounttoApply, PmtDiscAmount,
              MaxPmtTolAmount, CBGStatementLineApplID, ApplnRoundingPrecision);
        end;

        OriginalAppliedAmount := AppliedAmount;

        if GLSetup."Pmt. Disc. Tolerance Warning" then
            case CBGStatementLine."Account Type" of
                CBGStatementLine."Account Type"::Customer:
                    if not PaymentToleranceMgt.ManagePaymentDiscToleranceWarningCustomer(
                         NewCustLedgEntry, CBGStatementLineApplID, AppliedAmount, AmounttoApply, CBGStatementLine."Applies-to Doc. No.")
                    then
                        exit(false);
                CBGStatementLine."Account Type"::Vendor:
                    if not PaymentToleranceMgt.ManagePaymentDiscToleranceWarningVendor(
                         NewVendLedgEntry, CBGStatementLineApplID, AppliedAmount, AmounttoApply, CBGStatementLine."Applies-to Doc. No.")
                    then
                        exit(false);
            end;

        if Abs(AmounttoApply) >= Abs(AppliedAmount - PmtDiscAmount - MaxPmtTolAmount) then begin
            AppliedAmount := AppliedAmount - PmtDiscAmount;
            if Abs(AppliedAmount) > Abs(AmounttoApply) then
                AppliedAmount := AmounttoApply;

            if ((Abs(AppliedAmount + ApplyingAmount) - ApplnRoundingPrecision) <= Abs(MaxPmtTolAmount)) and
              (MaxPmtTolAmount <> 0) and ((Abs(AppliedAmount + ApplyingAmount) - ApplnRoundingPrecision) <> 0) and
              ((Abs(AppliedAmount + ApplyingAmount) > ApplnRoundingPrecision))
            then begin
                if CBGStatement.Type = CBGStatement.Type::"Bank/Giro" then
                    UseDocumentNo := CBGStatement."Document No."
                else
                    UseDocumentNo := CBGStatementLine."Document No.";

                if CBGStatementLine."Account Type" = CBGStatementLine."Account Type"::Customer then begin
                    if GLSetup."Payment Tolerance Warning" then begin
                        if PaymentToleranceMgt.CallPmtTolWarning(
                             CBGStatementLine.Date, CBGStatementLine."Account No.", UseDocumentNo,
                             CBGStatement.Currency, ApplyingAmount, OriginalAppliedAmount, "Payment Tolerance Account Type"::Customer)
                        then begin
                            if ApplyingAmount <> 0 then
                                PaymentToleranceMgt.PutCustPmtTolAmount(NewCustLedgEntry, ApplyingAmount, AppliedAmount, CBGStatementLineApplID)
                            else
                                PaymentToleranceMgt.DelCustPmtTolAcc(NewCustLedgEntry, CBGStatementLineApplID);
                        end else
                            exit(false);
                    end else
                        PaymentToleranceMgt.PutCustPmtTolAmount(NewCustLedgEntry, AppliedAmount, ApplyingAmount, CBGStatementLineApplID);
                end else
                    if GLSetup."Payment Tolerance Warning" then begin
                        if PaymentToleranceMgt.CallPmtTolWarning(
                             CBGStatementLine.Date, CBGStatementLine."Account No.", UseDocumentNo,
                             CBGStatement.Currency, ApplyingAmount, OriginalAppliedAmount, "Payment Tolerance Account Type"::Vendor)
                        then begin
                            if (AppliedAmount <> 0) and (ApplyingAmount <> 0) then
                                PaymentToleranceMgt.PutVendPmtTolAmount(NewVendLedgEntry, ApplyingAmount, AppliedAmount, CBGStatementLineApplID)
                            else
                                PaymentToleranceMgt.DelVendPmtTolAcc(NewVendLedgEntry, CBGStatementLineApplID);
                        end else
                            exit(false);
                    end else
                        PaymentToleranceMgt.PutVendPmtTolAmount(NewVendLedgEntry, ApplyingAmount, AppliedAmount, CBGStatementLineApplID);
            end;

        end;
        exit(true);
    end;
}
