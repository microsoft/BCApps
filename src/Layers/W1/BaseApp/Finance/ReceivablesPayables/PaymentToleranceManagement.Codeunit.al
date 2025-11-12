// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.ReceivablesPayables;

using Microsoft.Bank.Reconciliation;
using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Preview;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Receivables;
using System.Utilities;

codeunit 426 "Payment Tolerance Management"
{
    Permissions = TableData Currency = r,
                  TableData "Cust. Ledger Entry" = rim,
                  TableData "Vendor Ledger Entry" = rim,
                  TableData "Gen. Journal Line" = rim,
                  TableData "General Ledger Setup" = r;

    trigger OnRun()
    begin
    end;

    var
        CurrExchRate: Record "Currency Exchange Rate";
        GenJnlLineGlobal: Record "Gen. Journal Line";
        AccTypeOrBalAccTypeIsIncorrectErr: Label 'The value in either the Account Type field or the Bal. Account Type field is wrong.\\ The value must be %1.', Comment = '%1 = Customer or Vendor';
        SuppressCommit: Boolean;
        SuppressWarning: Boolean;

    procedure PmtTolCust(var CustLedgEntry: Record "Cust. Ledger Entry"): Boolean
    var
        GLSetup: Record "General Ledger Setup";
        Customer: Record Customer;
        AppliedAmount: Decimal;
        OriginalAppliedAmount: Decimal;
        ApplyingAmount: Decimal;
        AmounttoApply: Decimal;
        PmtDiscAmount: Decimal;
        MaxPmtTolAmount: Decimal;
        CustEntryApplId: Code[50];
        ApplnRoundingPrecision: Decimal;
    begin
        MaxPmtTolAmount := 0;
        PmtDiscAmount := 0;
        ApplyingAmount := 0;
        AmounttoApply := 0;
        AppliedAmount := 0;

        if Customer.Get(CustLedgEntry."Customer No.") then begin
            if Customer."Block Payment Tolerance" then
                exit(true);
        end else
            exit(false);

        GLSetup.Get();

        CustEntryApplId := UserId();
        if CustEntryApplId = '' then
            CustEntryApplId := '***';
        OnPmtTolCustOnAfterSetCustEntryApplId(CustLedgEntry, CustEntryApplId);

        DelCustPmtTolAcc(CustLedgEntry, CustEntryApplId);
        CustLedgEntry.CalcFields("Remaining Amount");
        OnPmtTolCustBeforeCalcCustApplnAmount(CustLedgEntry);
        CalcCustApplnAmount(
          CustLedgEntry, GLSetup, AppliedAmount, ApplyingAmount, AmounttoApply, PmtDiscAmount,
          MaxPmtTolAmount, CustEntryApplId, ApplnRoundingPrecision);

        OriginalAppliedAmount := AppliedAmount;

        if GLSetup."Pmt. Disc. Tolerance Warning" then
            if not ManagePaymentDiscToleranceWarningCustomer(CustLedgEntry, CustEntryApplId, AppliedAmount, AmounttoApply, '') then
                exit(false);

        if Abs(AmounttoApply) >= Abs(AppliedAmount - PmtDiscAmount - MaxPmtTolAmount) then begin
            AppliedAmount := AppliedAmount - PmtDiscAmount;
            if (Abs(AppliedAmount) > Abs(AmounttoApply)) and (AppliedAmount * PmtDiscAmount >= 0) then
                AppliedAmount := AmounttoApply;

            if ((Abs(AppliedAmount + ApplyingAmount) - ApplnRoundingPrecision) <= Abs(MaxPmtTolAmount)) and
               (MaxPmtTolAmount <> 0) and ((Abs(AppliedAmount + ApplyingAmount) - ApplnRoundingPrecision) <> 0)
               and (Abs(AppliedAmount + ApplyingAmount) > ApplnRoundingPrecision)
            then
                if GLSetup."Payment Tolerance Warning" then begin
                    if CallPmtTolWarning(
                         CustLedgEntry."Posting Date", CustLedgEntry."Customer No.", CustLedgEntry."Document No.",
                         CustLedgEntry."Currency Code", ApplyingAmount, OriginalAppliedAmount, "Payment Tolerance Account Type"::Customer)
                    then begin
                        if ApplyingAmount <> 0 then
                            PutCustPmtTolAmount(CustLedgEntry, ApplyingAmount, AppliedAmount, CustEntryApplId)
                        else
                            DelCustPmtTolAcc2(CustLedgEntry, CustEntryApplId);
                    end else
                        exit(false);
                end else
                    PutCustPmtTolAmount(CustLedgEntry, ApplyingAmount, AppliedAmount, CustEntryApplId);
        end;
        exit(true);
    end;

    procedure PmtTolVend(var VendLedgEntry: Record "Vendor Ledger Entry"): Boolean
    var
        GLSetup: Record "General Ledger Setup";
        Vendor: Record Vendor;
        AppliedAmount: Decimal;
        OriginalAppliedAmount: Decimal;
        ApplyingAmount: Decimal;
        AmounttoApply: Decimal;
        PmtDiscAmount: Decimal;
        MaxPmtTolAmount: Decimal;
        VendEntryApplID: Code[50];
        ApplnRoundingPrecision: Decimal;
    begin
        MaxPmtTolAmount := 0;
        PmtDiscAmount := 0;
        ApplyingAmount := 0;
        AmounttoApply := 0;
        AppliedAmount := 0;
        if Vendor.Get(VendLedgEntry."Vendor No.") then begin
            if Vendor."Block Payment Tolerance" then
                exit(true);
        end else
            exit(false);

        GLSetup.Get();
        VendEntryApplID := UserId();
        if VendEntryApplID = '' then
            VendEntryApplID := '***';
        OnPmtTolVendOnAfterSetVendEntryApplId(VendLedgEntry, VendEntryApplID);

        DelVendPmtTolAcc(VendLedgEntry, VendEntryApplID);
        VendLedgEntry.CalcFields("Remaining Amount");
        OnPmtTolVendBeforeCalcVendApplnAmount(VendLedgEntry);
        CalcVendApplnAmount(
          VendLedgEntry, GLSetup, AppliedAmount, ApplyingAmount, AmounttoApply, PmtDiscAmount,
          MaxPmtTolAmount, VendEntryApplID, ApplnRoundingPrecision);

        OriginalAppliedAmount := AppliedAmount;

        if GLSetup."Pmt. Disc. Tolerance Warning" then
            if not ManagePaymentDiscToleranceWarningVendor(VendLedgEntry, VendEntryApplID, AppliedAmount, AmounttoApply, '') then
                exit(false);

        if Abs(AmounttoApply) >= Abs(AppliedAmount - PmtDiscAmount - MaxPmtTolAmount) then begin
            AppliedAmount := AppliedAmount - PmtDiscAmount;
            if (Abs(AppliedAmount) > Abs(AmounttoApply)) and (AppliedAmount * PmtDiscAmount >= 0) then
                AppliedAmount := AmounttoApply;

            if ((Abs(AppliedAmount + ApplyingAmount) - ApplnRoundingPrecision) <= Abs(MaxPmtTolAmount)) and
               (MaxPmtTolAmount <> 0) and ((Abs(AppliedAmount + ApplyingAmount) - ApplnRoundingPrecision) <> 0) and
               (Abs(AppliedAmount + ApplyingAmount) > ApplnRoundingPrecision)
            then
                if GLSetup."Payment Tolerance Warning" then begin
                    if CallPmtTolWarning(
                         VendLedgEntry."Posting Date", VendLedgEntry."Vendor No.", VendLedgEntry."Document No.",
                         VendLedgEntry."Currency Code", ApplyingAmount, OriginalAppliedAmount, "Payment Tolerance Account Type"::Vendor)
                    then begin
                        if ApplyingAmount <> 0 then
                            PutVendPmtTolAmount(VendLedgEntry, ApplyingAmount, AppliedAmount, VendEntryApplID)
                        else
                            DelVendPmtTolAcc2(VendLedgEntry, VendEntryApplID);
                    end else
                        exit(false);
                end else
                    PutVendPmtTolAmount(VendLedgEntry, ApplyingAmount, AppliedAmount, VendEntryApplID);
        end;
        exit(true);
    end;

    procedure PmtTolGenJnl(var NewGenJnlLine: Record "Gen. Journal Line") Result: Boolean
    var
        TempGenJnlLine: Record "Gen. Journal Line" temporary;
    begin
        TempGenJnlLine := NewGenJnlLine;

        if TempGenJnlLine."Check Printed" then
            exit(true);

        if TempGenJnlLine."Financial Void" then
            exit(true);

        if (TempGenJnlLine."Applies-to Doc. No." = '') and (TempGenJnlLine."Applies-to ID" = '') then
            exit(true);

        OnPmtTolGenJnlOnAfterCheckConditions(TempGenJnlLine, SuppressCommit, Result);

        case true of
            (TempGenJnlLine."Account Type" = TempGenJnlLine."Account Type"::Customer) or
          (TempGenJnlLine."Bal. Account Type" = TempGenJnlLine."Bal. Account Type"::Customer):
                exit(SalesPmtTolGenJnl(TempGenJnlLine));
            (TempGenJnlLine."Account Type" = TempGenJnlLine."Account Type"::Vendor) or
          (TempGenJnlLine."Bal. Account Type" = TempGenJnlLine."Bal. Account Type"::Vendor):
                exit(PurchPmtTolGenJnl(TempGenJnlLine));
        end;

        OnAfterPmtTolGenJnl(TempGenJnlLine, SuppressCommit, Result);
    end;

    local procedure SalesPmtTolGenJnl(var GenJnlLine: Record "Gen. Journal Line"): Boolean
    var
        NewCustLedgEntry: Record "Cust. Ledger Entry";
        GenJnlPostPreview: Codeunit "Gen. Jnl.-Post Preview";
        GenJnlLineApplID: Code[50];
    begin
        if IsCustBlockPmtToleranceInGenJnlLine(GenJnlLine) then
            exit(false);

        GenJnlLineApplID := GetAppliesToID(GenJnlLine);

        NewCustLedgEntry."Posting Date" := GenJnlLine."Posting Date";
        NewCustLedgEntry."Document No." := GenJnlLine."Document No.";
        NewCustLedgEntry."Customer No." := GenJnlLine."Account No.";
        NewCustLedgEntry."Currency Code" := GenJnlLine."Currency Code";
        if GenJnlLine."Applies-to Doc. No." <> '' then
            NewCustLedgEntry."Applies-to Doc. No." := GenJnlLine."Applies-to Doc. No.";
        if not GenJnlPostPreview.IsActive() then
            DelCustPmtTolAcc(NewCustLedgEntry, GenJnlLineApplID);
        NewCustLedgEntry.Amount := GenJnlLine.Amount;
        NewCustLedgEntry."Remaining Amount" := GenJnlLine.Amount;
        NewCustLedgEntry."Document Type" := GenJnlLine."Document Type";
        GenJnlLineGlobal := GenJnlLine;
        exit(
          PmtTolCustLedgEntry(NewCustLedgEntry, GenJnlLine."Account No.", GenJnlLine."Posting Date",
            GenJnlLine."Document No.", GenJnlLineApplID, GenJnlLine."Applies-to Doc. No.",
            GenJnlLine."Currency Code"));
    end;

    local procedure PurchPmtTolGenJnl(var GenJnlLine: Record "Gen. Journal Line"): Boolean
    var
        NewVendLedgEntry: Record "Vendor Ledger Entry";
        GenJnlLineApplID: Code[50];
    begin
        if IsVendBlockPmtToleranceInGenJnlLine(GenJnlLine) then
            exit(false);

        GenJnlLineApplID := GetAppliesToID(GenJnlLine);

        NewVendLedgEntry."Posting Date" := GenJnlLine."Posting Date";
        NewVendLedgEntry."Document No." := GenJnlLine."Document No.";
        NewVendLedgEntry."Vendor No." := GenJnlLine."Account No.";
        NewVendLedgEntry."Currency Code" := GenJnlLine."Currency Code";
        if GenJnlLine."Applies-to Doc. No." <> '' then
            NewVendLedgEntry."Applies-to Doc. No." := GenJnlLine."Applies-to Doc. No.";
        DelVendPmtTolAcc(NewVendLedgEntry, GenJnlLineApplID);
        NewVendLedgEntry.Amount := GenJnlLine.Amount;
        NewVendLedgEntry."Remaining Amount" := GenJnlLine.Amount;
        NewVendLedgEntry."Document Type" := GenJnlLine."Document Type";
        exit(
          PmtTolVendLedgEntry(
            NewVendLedgEntry, GenJnlLine."Account No.", GenJnlLine."Posting Date",
            GenJnlLine."Document No.", GenJnlLineApplID, GenJnlLine."Applies-to Doc. No.",
            GenJnlLine."Currency Code"));
    end;

    procedure PmtTolPmtReconJnl(var NewBankAccReconciliationLine: Record "Bank Acc. Reconciliation Line") Result: Boolean
    var
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
    begin
        BankAccReconciliationLine := NewBankAccReconciliationLine;

        case BankAccReconciliationLine."Account Type" of
            BankAccReconciliationLine."Account Type"::Customer:
                exit(SalesPmtTolPmtReconJnl(BankAccReconciliationLine));
            BankAccReconciliationLine."Account Type"::Vendor:
                exit(PurchPmtTolPmtReconJnl(BankAccReconciliationLine));
        end;

        OnAfterPmtTolPmtReconJnl(BankAccReconciliationLine, SuppressCommit, Result);
    end;

    local procedure SalesPmtTolPmtReconJnl(var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"): Boolean
    var
        NewCustLedgEntry: Record "Cust. Ledger Entry";
    begin
        BankAccReconciliationLine.TestField("Account Type", BankAccReconciliationLine."Account Type"::Customer);

        if IsCustBlockPmtTolerance(BankAccReconciliationLine."Account No.") then
            exit(false);

        NewCustLedgEntry."Posting Date" := BankAccReconciliationLine."Transaction Date";
        NewCustLedgEntry."Document No." := BankAccReconciliationLine."Document No.";
        NewCustLedgEntry."Customer No." := BankAccReconciliationLine."Account No.";
        DelCustPmtTolAcc(NewCustLedgEntry, BankAccReconciliationLine.GetAppliesToID());
        NewCustLedgEntry.Amount := -BankAccReconciliationLine."Statement Amount";
        NewCustLedgEntry."Remaining Amount" := -BankAccReconciliationLine."Statement Amount";
        NewCustLedgEntry."Document Type" := NewCustLedgEntry."Document Type"::Payment;
        NewCustLedgEntry."Currency Code" := BankAccReconciliationLine.GetCurrencyCode();
        exit(
          PmtTolCustLedgEntry(
            NewCustLedgEntry, BankAccReconciliationLine."Account No.", BankAccReconciliationLine."Transaction Date",
            BankAccReconciliationLine."Statement No.", BankAccReconciliationLine.GetAppliesToID(), '',
            ''));
    end;

    local procedure PurchPmtTolPmtReconJnl(var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"): Boolean
    var
        NewVendLedgEntry: Record "Vendor Ledger Entry";
    begin
        BankAccReconciliationLine.TestField("Account Type", BankAccReconciliationLine."Account Type"::Vendor);

        if IsVendBlockPmtTolerance(BankAccReconciliationLine."Account No.") then
            exit(false);

        NewVendLedgEntry."Posting Date" := BankAccReconciliationLine."Transaction Date";
        NewVendLedgEntry."Document No." := BankAccReconciliationLine."Document No.";
        NewVendLedgEntry."Vendor No." := BankAccReconciliationLine."Account No.";
        DelVendPmtTolAcc(NewVendLedgEntry, BankAccReconciliationLine.GetAppliesToID());
        NewVendLedgEntry.Amount := -BankAccReconciliationLine."Statement Amount";
        NewVendLedgEntry."Remaining Amount" := -BankAccReconciliationLine."Statement Amount";
        NewVendLedgEntry."Document Type" := NewVendLedgEntry."Document Type"::Payment;
        NewVendLedgEntry."Currency Code" := BankAccReconciliationLine.GetCurrencyCode();

        exit(
          PmtTolVendLedgEntry(
            NewVendLedgEntry, BankAccReconciliationLine."Account No.", BankAccReconciliationLine."Transaction Date",
            BankAccReconciliationLine."Statement No.", BankAccReconciliationLine.GetAppliesToID(), '',
            ''));
    end;

    local procedure PmtTolCustLedgEntry(var NewCustLedgEntry: Record "Cust. Ledger Entry"; AccountNo: Code[20]; PostingDate: Date; DocNo: Code[20]; AppliesToID: Code[50]; AppliesToDocNo: Code[20]; CurrencyCode: Code[10]): Boolean
    var
        GLSetup: Record "General Ledger Setup";
        AppliedAmount: Decimal;
        OriginalAppliedAmount: Decimal;
        ApplyingAmount: Decimal;
        AmounttoApply: Decimal;
        PmtDiscAmount: Decimal;
        MaxPmtTolAmount: Decimal;
        ApplnRoundingPrecision: Decimal;
        IsHandled: Boolean;
        Result: Boolean;
    begin
        GLSetup.Get();
        CalcCustApplnAmount(
          NewCustLedgEntry, GLSetup, AppliedAmount, ApplyingAmount, AmounttoApply, PmtDiscAmount,
          MaxPmtTolAmount, AppliesToID, ApplnRoundingPrecision);

        IsHandled := false;
        OnPmtTolCustLedgEntryOnBeforeWarning(
         NewCustLedgEntry, GLSetup, AppliedAmount, ApplyingAmount, AmounttoApply, PmtDiscAmount,
         MaxPmtTolAmount, AppliesToID, ApplnRoundingPrecision, IsHandled, Result);
        if IsHandled then
            exit(Result);

        OriginalAppliedAmount := AppliedAmount;

        if GLSetup."Pmt. Disc. Tolerance Warning" then
            if not ManagePaymentDiscToleranceWarningCustomer(NewCustLedgEntry, AppliesToID, AppliedAmount, AmounttoApply, AppliesToDocNo) then
                exit(false);

        if Abs(AmounttoApply) >= Abs(AppliedAmount - PmtDiscAmount - MaxPmtTolAmount) then begin
            AppliedAmount := AppliedAmount - PmtDiscAmount;
            if (Abs(AppliedAmount) > Abs(AmounttoApply)) and (AppliedAmount * PmtDiscAmount > 0) then
                AppliedAmount := AmounttoApply;

            if ((Abs(AppliedAmount + ApplyingAmount) - ApplnRoundingPrecision) <= Abs(MaxPmtTolAmount)) and
               (MaxPmtTolAmount <> 0) and ((Abs(AppliedAmount + ApplyingAmount) - ApplnRoundingPrecision) <> 0) and
               (Abs(AppliedAmount + ApplyingAmount) > ApplnRoundingPrecision)
            then
                if GLSetup."Payment Tolerance Warning" then
                    if CallPmtTolWarning(
                         PostingDate, AccountNo, DocNo,
                         CurrencyCode, ApplyingAmount, OriginalAppliedAmount, "Payment Tolerance Account Type"::Customer)
                    then begin
                        if ApplyingAmount <> 0 then
                            PutCustPmtTolAmount(NewCustLedgEntry, ApplyingAmount, AppliedAmount, AppliesToID)
                        else
                            DelCustPmtTolAcc(NewCustLedgEntry, AppliesToID);
                    end else begin
                        DelCustPmtTolAcc(NewCustLedgEntry, AppliesToID);
                        exit(false);
                    end
                else
                    PutCustPmtTolAmount(NewCustLedgEntry, ApplyingAmount, AppliedAmount, AppliesToID);
        end;
        exit(true);
    end;

    local procedure PmtTolVendLedgEntry(var NewVendLedgEntry: Record "Vendor Ledger Entry"; AccountNo: Code[20]; PostingDate: Date; DocNo: Code[20]; AppliesToID: Code[50]; AppliesToDocNo: Code[20]; CurrencyCode: Code[10]): Boolean
    var
        GLSetup: Record "General Ledger Setup";
        AppliedAmount: Decimal;
        OriginalAppliedAmount: Decimal;
        ApplyingAmount: Decimal;
        AmounttoApply: Decimal;
        PmtDiscAmount: Decimal;
        MaxPmtTolAmount: Decimal;
        ApplnRoundingPrecision: Decimal;
        IsHandled: Boolean;
        Result: Boolean;
    begin
        GLSetup.Get();
        CalcVendApplnAmount(
          NewVendLedgEntry, GLSetup, AppliedAmount, ApplyingAmount, AmounttoApply, PmtDiscAmount,
          MaxPmtTolAmount, AppliesToID, ApplnRoundingPrecision);

        IsHandled := false;
        OnPmtTolVendLedgEntryOnBeforeWarning(
          NewVendLedgEntry, GLSetup, AppliedAmount, ApplyingAmount, AmounttoApply, PmtDiscAmount,
          MaxPmtTolAmount, AppliesToID, ApplnRoundingPrecision, IsHandled, Result);
        if IsHandled then
            exit(Result);

        OriginalAppliedAmount := AppliedAmount;

        if GLSetup."Pmt. Disc. Tolerance Warning" then
            if not ManagePaymentDiscToleranceWarningVendor(NewVendLedgEntry, AppliesToID, AppliedAmount, AmounttoApply, AppliesToDocNo) then
                exit(false);

        if Abs(AmounttoApply) >= Abs(AppliedAmount - PmtDiscAmount - MaxPmtTolAmount) then begin
            AppliedAmount := AppliedAmount - PmtDiscAmount;
            if (Abs(AppliedAmount) > Abs(AmounttoApply)) and (AppliedAmount * PmtDiscAmount > 0) then
                AppliedAmount := AmounttoApply;

            if ((Abs(AppliedAmount + ApplyingAmount) - ApplnRoundingPrecision) <= Abs(MaxPmtTolAmount)) and
               (MaxPmtTolAmount <> 0) and ((Abs(AppliedAmount + ApplyingAmount) - ApplnRoundingPrecision) <> 0) and
               (Abs(AppliedAmount + ApplyingAmount) > ApplnRoundingPrecision)
            then
                if GLSetup."Payment Tolerance Warning" then
                    if CallPmtTolWarning(
                         PostingDate, AccountNo, DocNo, CurrencyCode, ApplyingAmount, OriginalAppliedAmount, "Payment Tolerance Account Type"::Vendor)
                    then begin
                        if ApplyingAmount <> 0 then
                            PutVendPmtTolAmount(NewVendLedgEntry, ApplyingAmount, AppliedAmount, AppliesToID)
                        else
                            DelVendPmtTolAcc(NewVendLedgEntry, AppliesToID);
                    end else begin
                        DelVendPmtTolAcc(NewVendLedgEntry, AppliesToID);
                        exit(false);
                    end
                else
                    PutVendPmtTolAmount(NewVendLedgEntry, ApplyingAmount, AppliedAmount, AppliesToID);
        end;
        exit(true);
    end;

    local procedure CalcCustApplnAmount(CustledgEntry: Record "Cust. Ledger Entry"; GLSetup: Record "General Ledger Setup"; var AppliedAmount: Decimal; var ApplyingAmount: Decimal; var AmounttoApply: Decimal; var PmtDiscAmount: Decimal; var MaxPmtTolAmount: Decimal; CustEntryApplID: Code[50]; var ApplnRoundingPrecision: Decimal)
    var
        AppliedCustLedgEntry: Record "Cust. Ledger Entry";
        TempAppliedCustLedgerEntry: Record "Cust. Ledger Entry" temporary;
        CustLedgEntry2: Record "Cust. Ledger Entry";
        ApplnCurrencyCode: Code[10];
        ApplnDate: Date;
        AmountRoundingPrecision: Decimal;
        TempAmount: Decimal;
        i: Integer;
        PositiveFilter: Boolean;
        SetPositiveFilter: Boolean;
        ApplnInMultiCurrency: Boolean;
        UseDisc: Boolean;
        RemainingPmtDiscPossible: Decimal;
        AvailableAmount: Decimal;
    begin
        ApplnCurrencyCode := CustledgEntry."Currency Code";
        ApplnDate := CustledgEntry."Posting Date";
        ApplnRoundingPrecision := GLSetup."Appln. Rounding Precision";
        AmountRoundingPrecision := GLSetup."Amount Rounding Precision";

        if CustEntryApplID <> '' then begin
            AppliedCustLedgEntry.SetCurrentKey("Customer No.", "Applies-to ID", Open, Positive);
            AppliedCustLedgEntry.SetRange("Customer No.", CustledgEntry."Customer No.");
            AppliedCustLedgEntry.SetRange("Applies-to ID", CustEntryApplID);
            AppliedCustLedgEntry.SetRange(Open, true);
            CustLedgEntry2 := CustledgEntry;
            PositiveFilter := CustledgEntry."Remaining Amount" < 0;
            AppliedCustLedgEntry.SetRange(Positive, PositiveFilter);
            if CustledgEntry."Entry No." <> 0 then
                AppliedCustLedgEntry.SetFilter("Entry No.", '<>%1', CustledgEntry."Entry No.");

            // Find Application Rounding Precision
            GetCustApplicationRoundingPrecisionForAppliesToID(
              AppliedCustLedgEntry, ApplnRoundingPrecision, AmountRoundingPrecision, ApplnInMultiCurrency, ApplnCurrencyCode);

            if AppliedCustLedgEntry.Find('-') then begin
                ApplyingAmount := CustledgEntry."Remaining Amount";
                TempAmount := CustledgEntry."Remaining Amount";
                AppliedCustLedgEntry.SetRange(Positive);
                AppliedCustLedgEntry.Find('-');
                repeat
                    OnCalcCustApplnAmountOnBeforeUpdateCustAmountsForApplication(AppliedCustLedgEntry, CustledgEntry, TempAppliedCustLedgerEntry);
                    UpdateCustAmountsForApplication(AppliedCustLedgEntry, CustledgEntry, TempAppliedCustLedgerEntry);
                    CheckCustPaymentAmountsForAppliesToID(
                      CustledgEntry, AppliedCustLedgEntry, TempAppliedCustLedgerEntry, MaxPmtTolAmount, AvailableAmount, TempAmount,
                      ApplnRoundingPrecision);
                until AppliedCustLedgEntry.Next() = 0;

                TempAmount := TempAmount + MaxPmtTolAmount;

                PositiveFilter := GetCustPositiveFilter(CustledgEntry."Document Type", TempAmount);
                SetPositiveFilter := true;
                AppliedCustLedgEntry.SetRange(Positive, PositiveFilter);
            end else
                AppliedCustLedgEntry.SetRange(Positive);

            if CustledgEntry."Entry No." <> 0 then
                AppliedCustLedgEntry.SetRange("Entry No.");

            for i := 1 to 2 do begin
                if SetPositiveFilter then begin
                    if i = 2 then
                        AppliedCustLedgEntry.SetRange(Positive, not PositiveFilter);
                end else
                    i := 2;

                if AppliedCustLedgEntry.FindSet() then
                    repeat
                        AppliedCustLedgEntry.CalcFields("Remaining Amount");
                        OnCalcCustApplnAmountAfterCalcRemainingAmount(AppliedCustLedgEntry);
                        TempAppliedCustLedgerEntry := AppliedCustLedgEntry;
                        if AppliedCustLedgEntry."Currency Code" <> ApplnCurrencyCode then
                            AppliedCustLedgEntry.UpdateAmountsForApplication(ApplnDate, ApplnCurrencyCode, false, true);
                        // Check Payment Discount
                        UseDisc := false;
                        if CheckCalcPmtDiscCust(
                             CustLedgEntry2, AppliedCustLedgEntry, ApplnRoundingPrecision, false, false) and
                           (((CustledgEntry.Amount > 0) and (i = 1)) or
                            ((AppliedCustLedgEntry."Remaining Amount" < 0) and (i = 1)) or
                            (Abs(Abs(CustLedgEntry2."Remaining Amount") + ApplnRoundingPrecision -
                               Abs(AppliedCustLedgEntry."Remaining Amount")) >= Abs(AppliedCustLedgEntry.GetRemainingPmtDiscPossible(CustLedgEntry2."Posting Date") + AppliedCustLedgEntry."Max. Payment Tolerance")) or
                            (Abs(Abs(CustLedgEntry2."Remaining Amount") + ApplnRoundingPrecision -
                               Abs(AppliedCustLedgEntry."Remaining Amount")) <= Abs(AppliedCustLedgEntry.GetRemainingPmtDiscPossible(CustLedgEntry2."Posting Date") + MaxPmtTolAmount)))
                        then begin
                            PmtDiscAmount := PmtDiscAmount + AppliedCustLedgEntry.GetRemainingPmtDiscPossible(CustLedgEntry2."Posting Date");
                            UseDisc := true;
                        end;
                        // Check Payment Discount Tolerance
                        if AppliedCustLedgEntry."Amount to Apply" = AppliedCustLedgEntry."Remaining Amount" then
                            AvailableAmount := CustLedgEntry2."Remaining Amount"
                        else
                            AvailableAmount := -AppliedCustLedgEntry."Amount to Apply";
                        if CheckPmtDiscTolCust(CustLedgEntry2."Posting Date",
                             CustledgEntry."Document Type", AvailableAmount,
                             AppliedCustLedgEntry, ApplnRoundingPrecision, MaxPmtTolAmount) and
                           (((CustledgEntry.Amount > 0) and (i = 1)) or
                            ((AppliedCustLedgEntry."Remaining Amount" < 0) and (i = 1)) or
                            (Abs(Abs(CustLedgEntry2."Remaining Amount") + ApplnRoundingPrecision -
                               Abs(AppliedCustLedgEntry."Remaining Amount")) >= Abs(AppliedCustLedgEntry."Remaining Pmt. Disc. Possible" + AppliedCustLedgEntry."Max. Payment Tolerance")) or
                            (Abs(Abs(CustLedgEntry2."Remaining Amount") + ApplnRoundingPrecision -
                               Abs(AppliedCustLedgEntry."Remaining Amount")) <= Abs(AppliedCustLedgEntry."Remaining Pmt. Disc. Possible" + MaxPmtTolAmount)))
                        then begin
                            PmtDiscAmount := PmtDiscAmount + AppliedCustLedgEntry."Remaining Pmt. Disc. Possible";
                            UseDisc := true;
                            AppliedCustLedgEntry."Accepted Pmt. Disc. Tolerance" := true;
                            if CustledgEntry."Currency Code" <> AppliedCustLedgEntry."Currency Code" then begin
                                RemainingPmtDiscPossible := AppliedCustLedgEntry."Remaining Pmt. Disc. Possible";
                                AppliedCustLedgEntry."Remaining Pmt. Disc. Possible" := TempAppliedCustLedgerEntry."Remaining Pmt. Disc. Possible";
                                AppliedCustLedgEntry."Max. Payment Tolerance" := TempAppliedCustLedgerEntry."Max. Payment Tolerance";
                            end;
                            AppliedCustLedgEntry.Modify();
                            if CustledgEntry."Currency Code" <> AppliedCustLedgEntry."Currency Code" then
                                AppliedCustLedgEntry."Remaining Pmt. Disc. Possible" := RemainingPmtDiscPossible;
                        end;

                        if CustledgEntry."Entry No." <> AppliedCustLedgEntry."Entry No." then begin
                            MaxPmtTolAmount := Round(MaxPmtTolAmount, AmountRoundingPrecision);
                            PmtDiscAmount := Round(PmtDiscAmount, AmountRoundingPrecision);
                            AppliedAmount := AppliedAmount + Round(AppliedCustLedgEntry."Remaining Amount", AmountRoundingPrecision);
                            if UseDisc then begin
                                AmounttoApply :=
                                  AmounttoApply +
                                  Round(
                                    ABSMinTol(
                                      AppliedCustLedgEntry."Remaining Amount" -
                                      AppliedCustLedgEntry."Remaining Pmt. Disc. Possible",
                                      AppliedCustLedgEntry."Amount to Apply",
                                      MaxPmtTolAmount),
                                    AmountRoundingPrecision);
                                CustLedgEntry2."Remaining Amount" :=
                                  CustLedgEntry2."Remaining Amount" +
                                  Round(AppliedCustLedgEntry."Remaining Amount" - AppliedCustLedgEntry."Remaining Pmt. Disc. Possible", AmountRoundingPrecision)
                            end else begin
                                AmounttoApply := AmounttoApply + Round(AppliedCustLedgEntry."Amount to Apply", AmountRoundingPrecision);
                                CustLedgEntry2."Remaining Amount" :=
                                  CustLedgEntry2."Remaining Amount" + Round(AppliedCustLedgEntry."Remaining Amount", AmountRoundingPrecision);
                            end;
                            if CustledgEntry."Remaining Amount" > 0 then begin
                                CustledgEntry."Remaining Amount" := CustledgEntry."Remaining Amount" + AppliedCustLedgEntry."Remaining Amount";
                                if CustledgEntry."Remaining Amount" < 0 then
                                    CustledgEntry."Remaining Amount" := 0;
                            end;
                            if CustledgEntry."Remaining Amount" < 0 then begin
                                CustledgEntry."Remaining Amount" := CustledgEntry."Remaining Amount" + AppliedCustLedgEntry."Remaining Amount";
                                if CustledgEntry."Remaining Amount" > 0 then
                                    CustledgEntry."Remaining Amount" := 0;
                            end;
                        end else
                            ApplyingAmount := AppliedCustLedgEntry."Remaining Amount";
                    until AppliedCustLedgEntry.Next() = 0;

                if not SuppressCommit then
                    Commit();
                OnCalcCustApplnAmountOnAfterAppliedCustLedgEntryLoop(AppliedCustLedgEntry);
            end;
        end else
            if CustledgEntry."Applies-to Doc. No." <> '' then begin
                AppliedCustLedgEntry.SetCurrentKey("Customer No.", Open);
                AppliedCustLedgEntry.SetRange("Customer No.", CustledgEntry."Customer No.");
                AppliedCustLedgEntry.SetRange(Open, true);
                AppliedCustLedgEntry.SetRange("Document No.", CustledgEntry."Applies-to Doc. No.");
                if AppliedCustLedgEntry.Find('-') then begin
                    GetApplicationRoundingPrecisionForAppliesToDoc(
                      AppliedCustLedgEntry."Currency Code", ApplnRoundingPrecision, AmountRoundingPrecision, ApplnCurrencyCode);
                    UpdateCustAmountsForApplication(AppliedCustLedgEntry, CustledgEntry, TempAppliedCustLedgerEntry);
                    CheckCustPaymentAmountsForAppliesToDoc(
                      CustledgEntry, AppliedCustLedgEntry, TempAppliedCustLedgerEntry, MaxPmtTolAmount, ApplnRoundingPrecision, PmtDiscAmount,
                      ApplnCurrencyCode);
                    MaxPmtTolAmount := Round(MaxPmtTolAmount, AmountRoundingPrecision);
                    PmtDiscAmount := Round(PmtDiscAmount, AmountRoundingPrecision);
                    AppliedAmount := Round(AppliedCustLedgEntry."Remaining Amount", AmountRoundingPrecision);
                    AmounttoApply := Round(AppliedCustLedgEntry."Amount to Apply", AmountRoundingPrecision);
                end;
                ApplyingAmount := CustledgEntry.Amount;
            end;
    end;

    local procedure CalcVendApplnAmount(VendledgEntry: Record "Vendor Ledger Entry"; GLSetup: Record "General Ledger Setup"; var AppliedAmount: Decimal; var ApplyingAmount: Decimal; var AmounttoApply: Decimal; var PmtDiscAmount: Decimal; var MaxPmtTolAmount: Decimal; VendEntryApplID: Code[50]; var ApplnRoundingPrecision: Decimal)
    var
        AppliedVendLedgEntry: Record "Vendor Ledger Entry";
        TempAppliedVendorLedgerEntry: Record "Vendor Ledger Entry" temporary;
        VendLedgEntry2: Record "Vendor Ledger Entry";
        ApplnCurrencyCode: Code[10];
        ApplnDate: Date;
        AmountRoundingPrecision: Decimal;
        TempAmount: Decimal;
        i: Integer;
        PositiveFilter: Boolean;
        SetPositiveFilter: Boolean;
        ApplnInMultiCurrency: Boolean;
        RemainingPmtDiscPossible: Decimal;
        UseDisc: Boolean;
        AvailableAmount: Decimal;
    begin
        ApplnCurrencyCode := VendledgEntry."Currency Code";
        ApplnDate := VendledgEntry."Posting Date";
        ApplnRoundingPrecision := GLSetup."Appln. Rounding Precision";
        AmountRoundingPrecision := GLSetup."Amount Rounding Precision";

        if VendEntryApplID <> '' then begin
            AppliedVendLedgEntry.SetCurrentKey("Vendor No.", "Applies-to ID", Open, Positive);
            AppliedVendLedgEntry.SetRange("Vendor No.", VendledgEntry."Vendor No.");
            AppliedVendLedgEntry.SetRange("Applies-to ID", VendEntryApplID);
            AppliedVendLedgEntry.SetRange(Open, true);
            VendLedgEntry2 := VendledgEntry;
            PositiveFilter := VendledgEntry."Remaining Amount" > 0;
            AppliedVendLedgEntry.SetRange(Positive, not PositiveFilter);

            if VendledgEntry."Entry No." <> 0 then
                AppliedVendLedgEntry.SetFilter("Entry No.", '<>%1', VendledgEntry."Entry No.");
            GetVendApplicationRoundingPrecisionForAppliesToID(AppliedVendLedgEntry,
              ApplnRoundingPrecision, AmountRoundingPrecision, ApplnInMultiCurrency, ApplnCurrencyCode);
            if AppliedVendLedgEntry.Find('-') then begin
                ApplyingAmount := VendledgEntry."Remaining Amount";
                TempAmount := VendledgEntry."Remaining Amount";
                AppliedVendLedgEntry.SetRange(Positive);
                AppliedVendLedgEntry.Find('-');
                repeat
                    OnCalcVendApplnAmountOnBeforeUpdateVendAmountsForApplication(AppliedVendLedgEntry, VendledgEntry, TempAppliedVendorLedgerEntry);
                    UpdateVendAmountsForApplication(AppliedVendLedgEntry, VendledgEntry, TempAppliedVendorLedgerEntry);
                    CheckVendPaymentAmountsForAppliesToID(
                      VendledgEntry, AppliedVendLedgEntry, TempAppliedVendorLedgerEntry, MaxPmtTolAmount, AvailableAmount, TempAmount,
                      ApplnRoundingPrecision);
                until AppliedVendLedgEntry.Next() = 0;

                TempAmount := TempAmount + MaxPmtTolAmount;
                PositiveFilter := GetVendPositiveFilter(VendledgEntry."Document Type", TempAmount);
                SetPositiveFilter := true;
                AppliedVendLedgEntry.SetRange(Positive, not PositiveFilter);
            end else
                AppliedVendLedgEntry.SetRange(Positive);

            if VendledgEntry."Entry No." <> 0 then
                AppliedVendLedgEntry.SetRange("Entry No.");

            for i := 1 to 2 do begin
                if SetPositiveFilter then begin
                    if i = 2 then
                        AppliedVendLedgEntry.SetRange(Positive, PositiveFilter);
                end else
                    i := 2;

                if AppliedVendLedgEntry.FindSet() then
                    repeat
                        AppliedVendLedgEntry.CalcFields("Remaining Amount");
                        OnCalcVendApplnAmountAfterCalcRemainingAmount(AppliedVendLedgEntry);
                        TempAppliedVendorLedgerEntry := AppliedVendLedgEntry;
                        if AppliedVendLedgEntry."Currency Code" <> ApplnCurrencyCode then
                            AppliedVendLedgEntry.UpdateAmountsForApplication(ApplnDate, ApplnCurrencyCode, false, true);
                        // Check Payment Discount
                        UseDisc := false;
                        if CheckCalcPmtDiscVend(
                             VendLedgEntry2, AppliedVendLedgEntry, ApplnRoundingPrecision, false, false) and
                           (((VendledgEntry.Amount < 0) and (i = 1)) or
                            ((AppliedVendLedgEntry."Remaining Amount" > 0) and (i = 1)) or
                            (Abs(Abs(VendLedgEntry2."Remaining Amount") + ApplnRoundingPrecision -
                               Abs(AppliedVendLedgEntry."Remaining Amount")) >= Abs(AppliedVendLedgEntry.GetRemainingPmtDiscPossible(VendLedgEntry2."Posting Date") + AppliedVendLedgEntry."Max. Payment Tolerance")) or
                            (Abs(Abs(VendLedgEntry2."Remaining Amount") + ApplnRoundingPrecision -
                               Abs(AppliedVendLedgEntry."Remaining Amount")) <= Abs(AppliedVendLedgEntry.GetRemainingPmtDiscPossible(VendLedgEntry2."Posting Date") + MaxPmtTolAmount)))
                        then begin
                            PmtDiscAmount := PmtDiscAmount + AppliedVendLedgEntry.GetRemainingPmtDiscPossible(VendLedgEntry2."Posting Date");
                            UseDisc := true;
                        end;
                        // Check Payment Discount Tolerance
                        if AppliedVendLedgEntry."Amount to Apply" = AppliedVendLedgEntry."Remaining Amount" then
                            AvailableAmount := VendLedgEntry2."Remaining Amount"
                        else
                            AvailableAmount := -AppliedVendLedgEntry."Amount to Apply";

                        if CheckPmtDiscTolVend(
                             VendLedgEntry2."Posting Date", VendledgEntry."Document Type", AvailableAmount,
                             AppliedVendLedgEntry, ApplnRoundingPrecision, MaxPmtTolAmount) and
                           (((VendledgEntry.Amount < 0) and (i = 1)) or
                            ((AppliedVendLedgEntry."Remaining Amount" > 0) and (i = 1)) or
                            (Abs(Abs(VendLedgEntry2."Remaining Amount") + ApplnRoundingPrecision -
                               Abs(AppliedVendLedgEntry."Remaining Amount")) >= Abs(AppliedVendLedgEntry."Remaining Pmt. Disc. Possible" + AppliedVendLedgEntry."Max. Payment Tolerance")) or
                            (Abs(Abs(VendLedgEntry2."Remaining Amount") + ApplnRoundingPrecision -
                               Abs(AppliedVendLedgEntry."Remaining Amount")) <= Abs(AppliedVendLedgEntry."Remaining Pmt. Disc. Possible" + MaxPmtTolAmount)))
                        then begin
                            PmtDiscAmount := PmtDiscAmount + AppliedVendLedgEntry."Remaining Pmt. Disc. Possible";
                            UseDisc := true;
                            AppliedVendLedgEntry."Accepted Pmt. Disc. Tolerance" := true;
                            if VendledgEntry."Currency Code" <> AppliedVendLedgEntry."Currency Code" then begin
                                RemainingPmtDiscPossible := AppliedVendLedgEntry."Remaining Pmt. Disc. Possible";
                                AppliedVendLedgEntry."Remaining Pmt. Disc. Possible" := TempAppliedVendorLedgerEntry."Remaining Pmt. Disc. Possible";
                                AppliedVendLedgEntry."Max. Payment Tolerance" := TempAppliedVendorLedgerEntry."Max. Payment Tolerance";
                            end;
                            AppliedVendLedgEntry.Modify();
                            if VendledgEntry."Currency Code" <> AppliedVendLedgEntry."Currency Code" then
                                AppliedVendLedgEntry."Remaining Pmt. Disc. Possible" := RemainingPmtDiscPossible;
                        end;

                        if VendledgEntry."Entry No." <> AppliedVendLedgEntry."Entry No." then begin
                            PmtDiscAmount := Round(PmtDiscAmount, AmountRoundingPrecision);
                            MaxPmtTolAmount := Round(MaxPmtTolAmount, AmountRoundingPrecision);
                            AppliedAmount := AppliedAmount + Round(AppliedVendLedgEntry."Remaining Amount", AmountRoundingPrecision);
                            if UseDisc then begin
                                AmounttoApply :=
                                  AmounttoApply +
                                  Round(
                                    ABSMinTol(
                                      AppliedVendLedgEntry."Remaining Amount" -
                                      AppliedVendLedgEntry."Remaining Pmt. Disc. Possible",
                                      AppliedVendLedgEntry."Amount to Apply",
                                      MaxPmtTolAmount),
                                    AmountRoundingPrecision);
                                VendLedgEntry2."Remaining Amount" :=
                                  VendLedgEntry2."Remaining Amount" +
                                  Round(AppliedVendLedgEntry."Remaining Amount" - AppliedVendLedgEntry."Remaining Pmt. Disc. Possible", AmountRoundingPrecision)
                            end else begin
                                AmounttoApply := AmounttoApply + Round(AppliedVendLedgEntry."Amount to Apply", AmountRoundingPrecision);
                                VendLedgEntry2."Remaining Amount" :=
                                  VendLedgEntry2."Remaining Amount" + Round(AppliedVendLedgEntry."Remaining Amount", AmountRoundingPrecision);
                            end;
                            if VendledgEntry."Remaining Amount" > 0 then begin
                                VendledgEntry."Remaining Amount" := VendledgEntry."Remaining Amount" + AppliedVendLedgEntry."Remaining Amount";
                                if VendledgEntry."Remaining Amount" < 0 then
                                    VendledgEntry."Remaining Amount" := 0;
                            end;
                            if VendledgEntry."Remaining Amount" < 0 then begin
                                VendledgEntry."Remaining Amount" := VendledgEntry."Remaining Amount" + AppliedVendLedgEntry."Remaining Amount";
                                if VendledgEntry."Remaining Amount" > 0 then
                                    VendledgEntry."Remaining Amount" := 0;
                            end;
                        end else
                            ApplyingAmount := AppliedVendLedgEntry."Remaining Amount";
                    until AppliedVendLedgEntry.Next() = 0;

                if not SuppressCommit then
                    Commit();
                OnCalcVendApplnAmountOnAfterAppliedVendLedgEntryLoop(AppliedVendLedgEntry);
            end;
        end else
            if VendledgEntry."Applies-to Doc. No." <> '' then begin
                AppliedVendLedgEntry.SetCurrentKey("Vendor No.", Open);
                AppliedVendLedgEntry.SetRange("Vendor No.", VendledgEntry."Vendor No.");
                AppliedVendLedgEntry.SetRange(Open, true);
                AppliedVendLedgEntry.SetRange("Document No.", VendledgEntry."Applies-to Doc. No.");
                if AppliedVendLedgEntry.Find('-') then begin
                    GetApplicationRoundingPrecisionForAppliesToDoc(
                      AppliedVendLedgEntry."Currency Code", ApplnRoundingPrecision, AmountRoundingPrecision, ApplnCurrencyCode);
                    UpdateVendAmountsForApplication(AppliedVendLedgEntry, VendledgEntry, TempAppliedVendorLedgerEntry);
                    CheckVendPaymentAmountsForAppliesToDoc(VendledgEntry, AppliedVendLedgEntry, TempAppliedVendorLedgerEntry, MaxPmtTolAmount,
                      ApplnRoundingPrecision, PmtDiscAmount);
                    PmtDiscAmount := Round(PmtDiscAmount, AmountRoundingPrecision);
                    MaxPmtTolAmount := Round(MaxPmtTolAmount, AmountRoundingPrecision);
                    AppliedAmount := Round(AppliedVendLedgEntry."Remaining Amount", AmountRoundingPrecision);
                    AmounttoApply := Round(AppliedVendLedgEntry."Amount to Apply", AmountRoundingPrecision);
                end;
                ApplyingAmount := VendledgEntry.Amount;
            end;
    end;

    local procedure CheckPmtDiscTolCust(NewPostingdate: Date; NewDocType: Enum "Gen. Journal Document Type"; NewAmount: Decimal; OldCustLedgEntry: Record "Cust. Ledger Entry"; ApplnRoundingPrecision: Decimal; MaxPmtTolAmount: Decimal) Result: Boolean
    var
        ToleranceAmount: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckPmtDiscTolCust(NewPostingdate, NewDocType, NewAmount, OldCustLedgEntry, ApplnRoundingPrecision, MaxPmtTolAmount, IsHandled, Result);
        if IsHandled then
            exit(Result);

        if ((NewDocType = NewDocType::Payment) and
            ((OldCustLedgEntry."Document Type" in [OldCustLedgEntry."Document Type"::Invoice,
                                                   OldCustLedgEntry."Document Type"::"Credit Memo"]) and
             (NewPostingdate > OldCustLedgEntry."Pmt. Discount Date") and
             (NewPostingdate <= OldCustLedgEntry."Pmt. Disc. Tolerance Date") and
             (OldCustLedgEntry."Remaining Pmt. Disc. Possible" <> 0))) or
           ((NewDocType = NewDocType::Refund) and
            ((OldCustLedgEntry."Document Type" = OldCustLedgEntry."Document Type"::"Credit Memo") and
             (NewPostingdate > OldCustLedgEntry."Pmt. Discount Date") and
             (NewPostingdate <= OldCustLedgEntry."Pmt. Disc. Tolerance Date") and
             (OldCustLedgEntry."Remaining Pmt. Disc. Possible" <> 0)))
        then begin
            ToleranceAmount := (Abs(NewAmount) + ApplnRoundingPrecision) -
              Abs(OldCustLedgEntry."Remaining Amount" - OldCustLedgEntry."Remaining Pmt. Disc. Possible");
            exit((ToleranceAmount >= 0) or (Abs(MaxPmtTolAmount) >= Abs(ToleranceAmount)));
        end;
        exit(false);
    end;

    local procedure CheckPmtTolCust(NewDocType: Enum "Gen. Journal Document Type"; OldCustLedgEntry: Record "Cust. Ledger Entry") Result: Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckPmtTolCust(NewDocType, OldCustLedgEntry, IsHandled, Result);
        if IsHandled then
            exit(Result);

        if ((NewDocType = NewDocType::Payment) and
            (OldCustLedgEntry."Document Type" = OldCustLedgEntry."Document Type"::Invoice)) or
           ((NewDocType = NewDocType::Refund) and
            (OldCustLedgEntry."Document Type" = OldCustLedgEntry."Document Type"::"Credit Memo"))
        then
            exit(true);

        exit(false);
    end;

    local procedure CheckPmtDiscTolVend(NewPostingdate: Date; NewDocType: Enum "Gen. Journal Document Type"; NewAmount: Decimal; OldVendLedgEntry: Record "Vendor Ledger Entry"; ApplnRoundingPrecision: Decimal; MaxPmtTolAmount: Decimal): Boolean
    var
        ToleranceAmount: Decimal;
        IsHandled, Result : Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckPmtDiscTolVend(NewPostingdate, NewDocType, NewAmount, OldVendLedgEntry, ApplnRoundingPrecision, MaxPmtTolAmount, IsHandled, Result);
        if IsHandled then
            exit(Result);

        if ((NewDocType = NewDocType::Payment) and
            ((OldVendLedgEntry."Document Type" in [OldVendLedgEntry."Document Type"::Invoice,
                                                   OldVendLedgEntry."Document Type"::"Credit Memo"]) and
             (NewPostingdate > OldVendLedgEntry."Pmt. Discount Date") and
             (NewPostingdate <= OldVendLedgEntry."Pmt. Disc. Tolerance Date") and
             (OldVendLedgEntry."Remaining Pmt. Disc. Possible" <> 0))) or
           ((NewDocType = NewDocType::Refund) and
            ((OldVendLedgEntry."Document Type" = OldVendLedgEntry."Document Type"::"Credit Memo") and
             (NewPostingdate > OldVendLedgEntry."Pmt. Discount Date") and
             (NewPostingdate <= OldVendLedgEntry."Pmt. Disc. Tolerance Date") and
             (OldVendLedgEntry."Remaining Pmt. Disc. Possible" <> 0)))
        then begin
            ToleranceAmount := (Abs(NewAmount) + ApplnRoundingPrecision) -
              Abs(OldVendLedgEntry."Remaining Amount" - OldVendLedgEntry."Remaining Pmt. Disc. Possible");
            exit((ToleranceAmount >= 0) or (Abs(MaxPmtTolAmount) >= Abs(ToleranceAmount)));
        end;
        exit(false);
    end;

    local procedure CheckPmtTolVend(NewDocType: Enum "Gen. Journal Document Type"; OldVendLedgEntry: Record "Vendor Ledger Entry"): Boolean
    begin
        if ((NewDocType = NewDocType::Payment) and
            (OldVendLedgEntry."Document Type" = OldVendLedgEntry."Document Type"::Invoice)) or
           ((NewDocType = NewDocType::Refund) and
            (OldVendLedgEntry."Document Type" = OldVendLedgEntry."Document Type"::"Credit Memo"))
        then
            exit(true);

        exit(false);
    end;

    procedure CallPmtDiscTolWarning(PostingDate: Date; No: Code[20]; DocNo: Code[20]; CurrencyCode: Code[10]; Amount: Decimal; AppliedAmount: Decimal; PmtDiscAmount: Decimal; var RemainingAmountTest: Boolean; AccountType: Enum "Payment Tolerance Account Type") Result: Boolean
    var
        GenJnlPostPreview: Codeunit "Gen. Jnl.-Post Preview";
        PmtDiscTolWarning: Page "Payment Disc Tolerance Warning";
        ActionType: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCallPmtDiscTolWarning(
            PostingDate, No, DocNo, CurrencyCode, Amount, AppliedAmount, PmtDiscAmount, RemainingAmountTest, AccountType.AsInteger(), ActionType, Result, IsHandled, SuppressCommit);
        if IsHandled then
            exit(Result);

        if PmtDiscAmount = 0 then begin
            RemainingAmountTest := false;
            exit(true);
        end;

        if GenJnlPostPreview.IsActive() then
            exit(true);

        if SuppressCommit then
            exit(true);

        if SuppressWarning then
            exit(true);

        PmtDiscTolWarning.SetValues(PostingDate, No, DocNo, CurrencyCode, Amount, AppliedAmount, PmtDiscAmount);
        PmtDiscTolWarning.SetAccountName(GetAccountName(AccountType, No));
        PmtDiscTolWarning.LookupMode(true);
        if ACTION::Yes = PmtDiscTolWarning.RunModal() then begin
            PmtDiscTolWarning.GetValues(ActionType);
            if ActionType = 2 then
                RemainingAmountTest := true
            else
                RemainingAmountTest := false;
        end else
            exit(false);
        exit(true);
    end;

    procedure CallPmtTolWarning(PostingDate: Date; No: Code[20]; DocNo: Code[20]; CurrencyCode: Code[10]; var Amount: Decimal; AppliedAmount: Decimal; AccountType: Enum "Payment Tolerance Account Type"): Boolean
    var
        GenJnlPostPreview: Codeunit "Gen. Jnl.-Post Preview";
        PmtTolWarning: Page "Payment Tolerance Warning";
        ActionType: Integer;
        IsHandled: Boolean;
    begin
        if GenJnlPostPreview.IsActive() then
            exit(true);

        if SuppressCommit then
            exit(true);

        if SuppressWarning then
            exit(true);

        IsHandled := false;
        OnBeforeRunModalPmtTolWarningCallPmtTolWarning(
            PostingDate, No, DocNo, CurrencyCode, Amount, AppliedAmount, AccountType.AsInteger(), ActionType, IsHandled);
        if IsHandled then
            exit(ActionType = 2);

        PmtTolWarning.SetValues(PostingDate, No, DocNo, CurrencyCode, Amount, AppliedAmount, 0);
        PmtTolWarning.SetAccountName(GetAccountName(AccountType, No));
        PmtTolWarning.LookupMode(true);
        if ACTION::Yes = PmtTolWarning.RunModal() then begin
            PmtTolWarning.GetValues(ActionType);
            if ActionType = 2 then
                Amount := 0;
        end else
            exit(false);
        exit(true);
    end;

    local procedure PutCustPmtTolAmount(CustledgEntry: Record "Cust. Ledger Entry"; Amount: Decimal; AppliedAmount: Decimal; CustEntryApplID: Code[50])
    var
        AppliedCustLedgEntry: Record "Cust. Ledger Entry";
        AppliedCustLedgerEntry2: Record "Cust. Ledger Entry";
        Currency: Record Currency;
        Number: Integer;
        AcceptedTolAmount: Decimal;
        AcceptedEntryTolAmount: Decimal;
        TotalAmount: Decimal;
        OneToManyApplication: Boolean;
        RemainingPmtToleranceToAccept: Decimal;
    begin
        AppliedCustLedgEntry.SetCurrentKey("Customer No.", Open, Positive);
        AppliedCustLedgEntry.SetRange("Customer No.", CustledgEntry."Customer No.");
        AppliedCustLedgEntry.SetRange(Open, true);
        AppliedCustLedgEntry.SetFilter("Max. Payment Tolerance", '<>%1', 0);

        if CustledgEntry."Applies-to Doc. No." <> '' then
            AppliedCustLedgEntry.SetRange("Document No.", CustledgEntry."Applies-to Doc. No.")
        else
            AppliedCustLedgEntry.SetRange("Applies-to ID", CustEntryApplID);

        if CustledgEntry."Document Type" = CustledgEntry."Document Type"::Payment then
            AppliedCustLedgEntry.SetRange(Positive, true)
        else
            AppliedCustLedgEntry.SetRange(Positive, false);
        OnPutCustPmtTolAmountOnAfterAppliedCustLedgEntrySetFilters(AppliedCustLedgEntry, CustledgEntry);

        AppliedCustLedgEntry.SetLoadFields("Currency Code");
        if AppliedCustLedgEntry.FindSet(false) then
            repeat
                AppliedCustLedgEntry.CalcFields(Amount);
                OnPutCustPmtTolAmountAfterCalcAmount(AppliedCustLedgEntry);
                if CustledgEntry."Currency Code" <> AppliedCustLedgEntry."Currency Code" then
                    AppliedCustLedgEntry.Amount :=
                      CurrExchRate.ExchangeAmount(
                        AppliedCustLedgEntry.Amount,
                        AppliedCustLedgEntry."Currency Code",
                        CustledgEntry."Currency Code", CustledgEntry."Posting Date");
                TotalAmount := TotalAmount + AppliedCustLedgEntry.Amount;
            until AppliedCustLedgEntry.Next() = 0;

        AppliedCustLedgEntry.ReadIsolation(IsolationLevel::UpdLock);
        AppliedCustLedgEntry.SetLoadFields();

        AcceptedTolAmount := Amount + AppliedAmount;
        Number := AppliedCustLedgEntry.Count();
        if Number <> 1 then begin
            OneToManyApplication := true;
            AppliedCustLedgEntry.SetAutoCalcFields(Amount);
            AppliedCustLedgEntry.SetCurrentKey(Amount);
            AppliedCustLedgEntry.SetAscending(Amount, false);
        end;

        if AppliedCustLedgEntry.FindSet(true) then
            repeat
                AppliedCustLedgEntry.CalcFields("Remaining Amount");
                AppliedCustLedgerEntry2 := AppliedCustLedgEntry;
                if AppliedCustLedgEntry."Currency Code" = '' then begin
                    Currency.Init();
                    Currency.Code := '';
                    Currency.InitRoundingPrecision();
                end else
                    if AppliedCustLedgEntry."Currency Code" <> Currency.Code then
                        Currency.Get(AppliedCustLedgEntry."Currency Code");
                if Number <> 1 then begin
                    if CustledgEntry."Currency Code" <> AppliedCustLedgEntry."Currency Code" then
                        AppliedCustLedgEntry.Amount :=
                          CurrExchRate.ExchangeAmount(
                            AppliedCustLedgEntry.Amount,
                            AppliedCustLedgEntry."Currency Code",
                            CustledgEntry."Currency Code", CustledgEntry."Posting Date");
                    AcceptedEntryTolAmount := Round((AppliedCustLedgEntry.Amount / TotalAmount) * AcceptedTolAmount);
                    AcceptedEntryTolAmount := GetMinTolAmountByAbsValue(AcceptedEntryTolAmount, AppliedCustLedgEntry."Max. Payment Tolerance");
                    TotalAmount := TotalAmount - AppliedCustLedgEntry.Amount;
                    AcceptedTolAmount := AcceptedTolAmount - AcceptedEntryTolAmount;
                    AppliedCustLedgEntry."Accepted Payment Tolerance" := AcceptedEntryTolAmount;
                end else begin
                    AcceptedEntryTolAmount := AcceptedTolAmount;
                    if OneToManyApplication then begin
                        AcceptedEntryTolAmount := GetMinTolAmountByAbsValue(AcceptedEntryTolAmount, AppliedCustLedgEntry."Max. Payment Tolerance");
                        RemainingPmtToleranceToAccept := AcceptedTolAmount - AcceptedEntryTolAmount;
                    end;
                    AppliedCustLedgEntry."Accepted Payment Tolerance" := AcceptedEntryTolAmount;
                end;
                AppliedCustLedgEntry."Max. Payment Tolerance" := AppliedCustLedgerEntry2."Max. Payment Tolerance";
                AppliedCustLedgEntry."Amount to Apply" := AppliedCustLedgerEntry2."Remaining Amount";
                AppliedCustLedgEntry.Modify();
                Number := Number - 1;
            until AppliedCustLedgEntry.Next() = 0;

        if RemainingPmtToleranceToAccept <> 0 then
            if AppliedCustLedgEntry.FindSet(true) then
                repeat
                    if RemainingPmtToleranceToAccept < (AppliedCustLedgEntry."Max. Payment Tolerance" - AppliedCustLedgEntry."Accepted Payment Tolerance") then begin
                        AppliedCustLedgEntry."Accepted Payment Tolerance" += RemainingPmtToleranceToAccept;
                        AppliedCustLedgEntry.Modify();
                        RemainingPmtToleranceToAccept := 0
                    end else begin
                        RemainingPmtToleranceToAccept -= (AppliedCustLedgEntry."Max. Payment Tolerance" - AppliedCustLedgEntry."Accepted Payment Tolerance");
                        AppliedCustLedgEntry."Accepted Payment Tolerance" := AppliedCustLedgEntry."Max. Payment Tolerance";
                        AppliedCustLedgEntry.Modify()
                    end;
                until (AppliedCustLedgEntry.Next() = 0) or (RemainingPmtToleranceToAccept = 0);

        if not SuppressCommit then
            Commit();
    end;

    local procedure PutVendPmtTolAmount(VendLedgEntry: Record "Vendor Ledger Entry"; Amount: Decimal; AppliedAmount: Decimal; VendEntryApplID: Code[50])
    var
        AppliedVendLedgEntry: Record "Vendor Ledger Entry";
        AppliedVendorLedgerEntry2: Record "Vendor Ledger Entry";
        Currency: Record Currency;
        Number: Integer;
        AcceptedTolAmount: Decimal;
        AcceptedEntryTolAmount: Decimal;
        TotalAmount: Decimal;
        OneToManyApplication: Boolean;
        RemainingPmtToleranceToAccept: Decimal;
    begin
        AppliedVendLedgEntry.SetCurrentKey("Vendor No.", Open, Positive);
        AppliedVendLedgEntry.SetRange("Vendor No.", VendLedgEntry."Vendor No.");
        AppliedVendLedgEntry.SetRange(Open, true);
        AppliedVendLedgEntry.SetFilter("Max. Payment Tolerance", '<>%1', 0);

        if VendLedgEntry."Applies-to Doc. No." <> '' then
            AppliedVendLedgEntry.SetRange("Document No.", VendLedgEntry."Applies-to Doc. No.")
        else
            AppliedVendLedgEntry.SetRange("Applies-to ID", VendEntryApplID);

        if VendLedgEntry."Document Type" = VendLedgEntry."Document Type"::Payment then
            AppliedVendLedgEntry.SetRange(Positive, false)
        else
            AppliedVendLedgEntry.SetRange(Positive, true);
        OnPutVendPmtTolAmountOnAfterVendLedgEntrySetFilters(AppliedVendLedgEntry, VendLedgEntry);

        AppliedVendLedgEntry.SetLoadFields("Currency Code");
        if AppliedVendLedgEntry.FindSet(false) then
            repeat
                AppliedVendLedgEntry.CalcFields(Amount);
                OnPutVendPmtTolAmountAfterCalcAmount(AppliedVendLedgEntry);
                if VendLedgEntry."Currency Code" <> AppliedVendLedgEntry."Currency Code" then
                    AppliedVendLedgEntry.Amount :=
                      CurrExchRate.ExchangeAmount(
                        AppliedVendLedgEntry.Amount,
                        AppliedVendLedgEntry."Currency Code",
                        VendLedgEntry."Currency Code", VendLedgEntry."Posting Date");
                TotalAmount := TotalAmount + AppliedVendLedgEntry.Amount;
            until AppliedVendLedgEntry.Next() = 0;

        AppliedVendLedgEntry.ReadIsolation(IsolationLevel::UpdLock);
        AppliedVendLedgEntry.SetLoadFields();

        AcceptedTolAmount := Amount + AppliedAmount;
        Number := AppliedVendLedgEntry.Count();
        if Number <> 1 then begin
            OneToManyApplication := true;
            AppliedVendLedgEntry.SetAutoCalcFields(Amount);
            AppliedVendLedgEntry.SetCurrentKey(Amount);
            AppliedVendLedgEntry.SetAscending(Amount, false);
        end;

        if AppliedVendLedgEntry.FindSet(true) then
            repeat
                AppliedVendLedgEntry.CalcFields("Remaining Amount");
                AppliedVendorLedgerEntry2 := AppliedVendLedgEntry;
                if AppliedVendLedgEntry."Currency Code" = '' then begin
                    Currency.Init();
                    Currency.Code := '';
                    Currency.InitRoundingPrecision();
                end else
                    if AppliedVendLedgEntry."Currency Code" <> Currency.Code then
                        Currency.Get(AppliedVendLedgEntry."Currency Code");
                if VendLedgEntry."Currency Code" <> AppliedVendLedgEntry."Currency Code" then
                    AppliedVendLedgEntry."Max. Payment Tolerance" :=
                      CurrExchRate.ExchangeAmount(
                        AppliedVendLedgEntry."Max. Payment Tolerance",
                        AppliedVendLedgEntry."Currency Code",
                        VendLedgEntry."Currency Code", VendLedgEntry."Posting Date");
                if Number <> 1 then begin
                    if VendLedgEntry."Currency Code" <> AppliedVendLedgEntry."Currency Code" then
                        AppliedVendLedgEntry.Amount :=
                          CurrExchRate.ExchangeAmount(
                            AppliedVendLedgEntry.Amount,
                            AppliedVendLedgEntry."Currency Code",
                            VendLedgEntry."Currency Code", VendLedgEntry."Posting Date");
                    AcceptedEntryTolAmount := Round((AppliedVendLedgEntry.Amount / TotalAmount) * AcceptedTolAmount);
                    AcceptedEntryTolAmount := GetMinTolAmountByAbsValue(AcceptedEntryTolAmount, AppliedVendLedgEntry."Max. Payment Tolerance");
                    TotalAmount := TotalAmount - AppliedVendLedgEntry.Amount;
                    AcceptedTolAmount := AcceptedTolAmount - AcceptedEntryTolAmount;
                    AppliedVendLedgEntry."Accepted Payment Tolerance" := AcceptedEntryTolAmount;
                end else begin
                    AcceptedEntryTolAmount := AcceptedTolAmount;
                    if OneToManyApplication then begin
                        AcceptedEntryTolAmount := GetMinTolAmountByAbsValue(AcceptedEntryTolAmount, AppliedVendLedgEntry."Max. Payment Tolerance");
                        RemainingPmtToleranceToAccept := AcceptedTolAmount - AcceptedEntryTolAmount;
                    end;
                    AppliedVendLedgEntry."Accepted Payment Tolerance" := AcceptedEntryTolAmount;
                end;
                AppliedVendLedgEntry."Max. Payment Tolerance" := AppliedVendorLedgerEntry2."Max. Payment Tolerance";
                AppliedVendLedgEntry."Amount to Apply" := AppliedVendorLedgerEntry2."Remaining Amount";
                AppliedVendLedgEntry.Modify();
                Number := Number - 1;
            until AppliedVendLedgEntry.Next() = 0;

        if RemainingPmtToleranceToAccept <> 0 then
            if AppliedVendLedgEntry.FindSet(true) then
                repeat
                    if RemainingPmtToleranceToAccept < (AppliedVendLedgEntry."Max. Payment Tolerance" - AppliedVendLedgEntry."Accepted Payment Tolerance") then begin
                        AppliedVendLedgEntry."Accepted Payment Tolerance" += RemainingPmtToleranceToAccept;
                        AppliedVendLedgEntry.Modify();
                        RemainingPmtToleranceToAccept := 0
                    end else begin
                        RemainingPmtToleranceToAccept -= (AppliedVendLedgEntry."Max. Payment Tolerance" - AppliedVendLedgEntry."Accepted Payment Tolerance");
                        AppliedVendLedgEntry."Accepted Payment Tolerance" := AppliedVendLedgEntry."Max. Payment Tolerance";
                        AppliedVendLedgEntry.Modify()
                    end;
                until (AppliedVendLedgEntry.Next() = 0) or (RemainingPmtToleranceToAccept = 0);

        if not SuppressCommit then
            Commit();
    end;

    local procedure DelCustPmtTolAcc(CustledgEntry: Record "Cust. Ledger Entry"; CustEntryApplID: Code[50])
    var
        AppliedCustLedgEntry: Record "Cust. Ledger Entry";
        PmtTolHasBeenModified: Boolean;
    begin
        AppliedCustLedgEntry.SetCurrentKey("Customer No.", Open, Positive);
        AppliedCustLedgEntry.SetRange("Customer No.", CustledgEntry."Customer No.");
        AppliedCustLedgEntry.SetRange(Open, true);
        AppliedCustLedgEntry.ReadIsolation(IsolationLevel::UpdLock);
        AppliedCustLedgEntry.SetLoadFields("Document No.", "Applies-to ID", "Accepted Payment Tolerance", "Accepted Pmt. Disc. Tolerance");
        if AppliedCustLedgEntry.Find('-') then
            repeat
                if (AppliedCustLedgEntry."Applies-to ID" = CustEntryApplID) or (AppliedCustLedgEntry."Document No." = CustledgEntry."Applies-to Doc. No.") then begin
                    AppliedCustLedgEntry."Accepted Payment Tolerance" := 0;
                    AppliedCustLedgEntry."Accepted Pmt. Disc. Tolerance" := false;
                    AppliedCustLedgEntry.Modify();
                    PmtTolHasBeenModified := true;
                end;
            until AppliedCustLedgEntry.Next() = 0;
        if PmtTolHasBeenModified and (not SuppressCommit) then
            Commit();
    end;

    local procedure DelVendPmtTolAcc(VendLedgEntry: Record "Vendor Ledger Entry"; VendEntryApplID: Code[50])
    var
        AppliedVendLedgEntry: Record "Vendor Ledger Entry";
        PmtTolHasBeenModified: Boolean;
    begin
        AppliedVendLedgEntry.SetCurrentKey("Vendor No.", "Applies-to ID", Open, Positive, "Due Date");
        AppliedVendLedgEntry.SetRange("Vendor No.", VendLedgEntry."Vendor No.");
        AppliedVendLedgEntry.SetRange(Open, true);
        AppliedVendLedgEntry.ReadIsolation(IsolationLevel::UpdLock);
        AppliedVendLedgEntry.SetLoadFields("Document No.", "Applies-to ID", "Accepted Payment Tolerance", "Accepted Pmt. Disc. Tolerance");
        if AppliedVendLedgEntry.FindSet() then
            repeat
                if (AppliedVendLedgEntry."Applies-to ID" = VendEntryApplID) or (AppliedVendLedgEntry."Document No." = VendLedgEntry."Applies-to Doc. No.") then begin
                    AppliedVendLedgEntry."Accepted Payment Tolerance" := 0;
                    AppliedVendLedgEntry."Accepted Pmt. Disc. Tolerance" := false;
                    AppliedVendLedgEntry.Modify();
                    PmtTolHasBeenModified := true;
                end;
            until AppliedVendLedgEntry.Next() = 0;
        if PmtTolHasBeenModified and (not SuppressCommit) then
            Commit();
    end;

    procedure CalcGracePeriodCVLedgEntry(PmtTolGracePeriode: DateFormula)
    var
        Customer: Record Customer;
        CustLedgEntry: Record "Cust. Ledger Entry";
        Vendor: Record Vendor;
        VendLedgEntry: Record "Vendor Ledger Entry";
    begin
        CustLedgEntry.ReadIsolation(IsolationLevel::UpdLock);
        Customer.SetLoadFields("No.", "Block Payment Tolerance");
        Customer.ReadIsolation(IsolationLevel::UpdLock);
        CustLedgEntry.SetCurrentKey("Customer No.", Open);
        CustLedgEntry.SetRange(Open, true);
        CustLedgEntry.SetLoadFields("Customer No.", "Document Type", "Pmt. Discount Date", "Document Date", "Pmt. Disc. Tolerance Date");
        OnCalcGracePeriodCVLedgEntryOnAfterCustLedgEntrySetFilters(CustLedgEntry);
        if CustLedgEntry.Find('-') then
            repeat
                if not (CustLedgEntry."Document Type" in [CustLedgEntry."Document Type"::Invoice, CustLedgEntry."Document Type"::"Credit Memo"]) then
                    continue;
                if Customer."No." <> CustLedgEntry."Customer No." then
                    Customer.Get(CustLedgEntry."Customer No.");
                if Customer."Block Payment Tolerance" then
                    continue;
                if CustLedgEntry."Pmt. Discount Date" <> 0D then begin
                    if CustLedgEntry."Pmt. Discount Date" <> CustLedgEntry."Document Date" then
                        CustLedgEntry."Pmt. Disc. Tolerance Date" :=
                            CalcDate(PmtTolGracePeriode, CustLedgEntry."Pmt. Discount Date")
                    else
                        CustLedgEntry."Pmt. Disc. Tolerance Date" :=
                            CustLedgEntry."Pmt. Discount Date";
                end else
                    CustLedgEntry."Pmt. Disc. Tolerance Date" := 0D;
                OnCalcGracePeriodCVLedgEntryOnBeforeCustLedgEntryModify(CustLedgEntry, PmtTolGracePeriode);
                CustLedgEntry.Modify();
            until CustLedgEntry.Next() = 0;

        VendLedgEntry.ReadIsolation(IsolationLevel::UpdLock);
        Vendor.SetLoadFields("No.", "Block Payment Tolerance");
        Vendor.ReadIsolation(IsolationLevel::UpdLock);
        VendLedgEntry.SetCurrentKey("Vendor No.", Open);
        VendLedgEntry.SetRange(Open, true);
        VendLedgEntry.SetLoadFields("Vendor No.", "Document Type", "Pmt. Discount Date", "Pmt. Disc. Tolerance Date", "Document Date");
        if VendLedgEntry.Find('-') then
            repeat
                if not (VendLedgEntry."Document Type" in [VendLedgEntry."Document Type"::Invoice, VendLedgEntry."Document Type"::"Credit Memo"]) then
                    continue;
                if Vendor."No." <> VendLedgEntry."VEndor No." then
                    Vendor.Get(VendLedgEntry."Vendor No.");
                if Vendor."Block Payment Tolerance" then
                    continue;
                if VendLedgEntry."Pmt. Discount Date" <> 0D then begin
                    if VendLedgEntry."Pmt. Disc. Tolerance Date" <>
                        VendLedgEntry."Document Date"
                    then
                        VendLedgEntry."Pmt. Disc. Tolerance Date" :=
                            CalcDate(PmtTolGracePeriode, VendLedgEntry."Pmt. Discount Date")
                    else
                        VendLedgEntry."Pmt. Disc. Tolerance Date" :=
                            VendLedgEntry."Pmt. Discount Date";
                end else
                    VendLedgEntry."Pmt. Disc. Tolerance Date" := 0D;
                OnCalcGracePeriodCVLedgEntryOnBeforeVendLedgEntryModify(VendLedgEntry, PmtTolGracePeriode);
                VendLedgEntry.Modify();
            until VendLedgEntry.Next() = 0;
    end;

    procedure CalcTolCustLedgEntry(Customer: Record Customer)
    var
        GLSetup: Record "General Ledger Setup";
        Currency: Record Currency;
        CustLedgEntry: Record "Cust. Ledger Entry";
        IsHandled: Boolean;
    begin
        GLSetup.Get();
        CustLedgEntry.SetCurrentKey("Customer No.", Open);
        CustLedgEntry.SetRange("Customer No.", Customer."No.");
        CustLedgEntry.SetRange(Open, true);
        CustLedgEntry.ReadIsolation(IsolationLevel::UpdLock);
        CustLedgEntry.SetLoadFields("Document Type", "Posting Date", "Pmt. Discount Date", "Currency Code", "Max. Payment Tolerance", Amount, "Amount (LCY)");
        if not CustLedgEntry.Find('-') then
            exit;
        repeat
            IsHandled := false;
            OnCalcTolCustLedgEntryOnCustLedgEntryLoopIterationStart(CustLedgEntry, GLSetup, IsHandled);
            if not IsHandled then begin
                if (CustLedgEntry."Document Type" = CustLedgEntry."Document Type"::Invoice) or
                    (CustLedgEntry."Document Type" = CustLedgEntry."Document Type"::"Credit Memo")
                 then begin
                    CustLedgEntry.CalcFields(Amount, "Amount (LCY)");
                    if CustLedgEntry."Pmt. Discount Date" >= CustLedgEntry."Posting Date" then
                        CustLedgEntry."Pmt. Disc. Tolerance Date" :=
                          CalcDate(GLSetup."Payment Discount Grace Period", CustLedgEntry."Pmt. Discount Date");
                    if CustLedgEntry."Currency Code" = '' then begin
                        if (GLSetup."Max. Payment Tolerance Amount" <
                            Abs(GLSetup."Payment Tolerance %" / 100 * CustLedgEntry."Amount (LCY)")) or (GLSetup."Payment Tolerance %" = 0)
                        then begin
                            if (GLSetup."Max. Payment Tolerance Amount" = 0) and (GLSetup."Payment Tolerance %" > 0) then
                                CustLedgEntry."Max. Payment Tolerance" :=
                                  GLSetup."Payment Tolerance %" * CustLedgEntry."Amount (LCY)" / 100
                            else
                                if CustLedgEntry."Document Type" = CustLedgEntry."Document Type"::"Credit Memo" then
                                    CustLedgEntry."Max. Payment Tolerance" := -GLSetup."Max. Payment Tolerance Amount"
                                else
                                    CustLedgEntry."Max. Payment Tolerance" := GLSetup."Max. Payment Tolerance Amount"
                        end else
                            CustLedgEntry."Max. Payment Tolerance" :=
                              GLSetup."Payment Tolerance %" * CustLedgEntry."Amount (LCY)" / 100
                    end else begin
                        Currency.Get(CustLedgEntry."Currency Code");
                        if (Currency."Max. Payment Tolerance Amount" <
                            Abs(Currency."Payment Tolerance %" / 100 * CustLedgEntry.Amount)) or (Currency."Payment Tolerance %" = 0)
                        then begin
                            if (Currency."Max. Payment Tolerance Amount" = 0) and (Currency."Payment Tolerance %" > 0) then
                                CustLedgEntry."Max. Payment Tolerance" :=
                                  Round(Currency."Payment Tolerance %" * CustLedgEntry.Amount / 100, Currency."Amount Rounding Precision")
                            else
                                if CustLedgEntry."Document Type" = CustLedgEntry."Document Type"::"Credit Memo" then
                                    CustLedgEntry."Max. Payment Tolerance" := -Currency."Max. Payment Tolerance Amount"
                                else
                                    CustLedgEntry."Max. Payment Tolerance" := Currency."Max. Payment Tolerance Amount"
                        end else
                            CustLedgEntry."Max. Payment Tolerance" :=
                              Round(Currency."Payment Tolerance %" * CustLedgEntry.Amount / 100, Currency."Amount Rounding Precision");
                    end;
                end;
                if Abs(CustLedgEntry.Amount) < Abs(CustLedgEntry."Max. Payment Tolerance") then
                    CustLedgEntry."Max. Payment Tolerance" := CustLedgEntry.Amount;
                OnCalcTolCustLedgEntryOnBeforeModify(CustLedgEntry);
                CustLedgEntry.Modify();
            end;
        until CustLedgEntry.Next() = 0;
    end;

    procedure DelTolCustLedgEntry(Customer: Record Customer)
    var
        GLSetup: Record "General Ledger Setup";
        CustLedgEntry: Record "Cust. Ledger Entry";
    begin
        GLSetup.Get();
        CustLedgEntry.SetCurrentKey("Customer No.", Open);
        CustLedgEntry.SetRange("Customer No.", Customer."No.");
        CustLedgEntry.SetRange(Open, true);
        CustLedgEntry.ReadIsolation(IsolationLevel::UpdLock);
        CustLedgEntry.SetLoadFields("Pmt. Disc. Tolerance Date", "Max. Payment Tolerance");
        if not CustLedgEntry.Find('-') then
            exit;
        repeat
            CustLedgEntry."Pmt. Disc. Tolerance Date" := 0D;
            CustLedgEntry."Max. Payment Tolerance" := 0;
            OnDelTolCustLedgEntryOnBeforeModify(CustLedgEntry);
            CustLedgEntry.Modify();
        until CustLedgEntry.Next() = 0;
    end;

    procedure CalcTolVendLedgEntry(Vendor: Record Vendor)
    var
        GLSetup: Record "General Ledger Setup";
        Currency: Record Currency;
        VendLedgEntry: Record "Vendor Ledger Entry";
    begin
        GLSetup.Get();
        VendLedgEntry.SetCurrentKey("Vendor No.", Open);
        VendLedgEntry.SetRange("Vendor No.", Vendor."No.");
        VendLedgEntry.SetRange(Open, true);
        VendLedgEntry.ReadIsolation(IsolationLevel::UpdLock);
        VendLedgEntry.SetLoadFields("Document Type", "Posting Date", "Pmt. Discount Date", "Currency Code", "Max. Payment Tolerance", Amount, "Amount (LCY)");
        if not VendLedgEntry.Find('-') then
            exit;
        repeat
            if (VendLedgEntry."Document Type" = VendLedgEntry."Document Type"::Invoice) or
               (VendLedgEntry."Document Type" = VendLedgEntry."Document Type"::"Credit Memo")
            then begin
                VendLedgEntry.CalcFields(Amount, "Amount (LCY)");
                if VendLedgEntry."Pmt. Discount Date" >= VendLedgEntry."Posting Date" then
                    VendLedgEntry."Pmt. Disc. Tolerance Date" :=
                      CalcDate(GLSetup."Payment Discount Grace Period", VendLedgEntry."Pmt. Discount Date");
                if VendLedgEntry."Currency Code" = '' then begin
                    if (GLSetup."Max. Payment Tolerance Amount" <
                        Abs(GLSetup."Payment Tolerance %" / 100 * VendLedgEntry."Amount (LCY)")) or (GLSetup."Payment Tolerance %" = 0)
                    then begin
                        if (GLSetup."Max. Payment Tolerance Amount" = 0) and (GLSetup."Payment Tolerance %" > 0) then
                            VendLedgEntry."Max. Payment Tolerance" :=
                              GLSetup."Payment Tolerance %" * VendLedgEntry."Amount (LCY)" / 100
                        else
                            if VendLedgEntry."Document Type" = VendLedgEntry."Document Type"::"Credit Memo" then
                                VendLedgEntry."Max. Payment Tolerance" := GLSetup."Max. Payment Tolerance Amount"
                            else
                                VendLedgEntry."Max. Payment Tolerance" := -GLSetup."Max. Payment Tolerance Amount"
                    end else
                        VendLedgEntry."Max. Payment Tolerance" :=
                          GLSetup."Payment Tolerance %" * VendLedgEntry."Amount (LCY)" / 100
                end else begin
                    Currency.Get(VendLedgEntry."Currency Code");
                    if (Currency."Max. Payment Tolerance Amount" <
                        Abs(Currency."Payment Tolerance %" / 100 * VendLedgEntry.Amount)) or (Currency."Payment Tolerance %" = 0)
                    then begin
                        if (Currency."Max. Payment Tolerance Amount" = 0) and (Currency."Payment Tolerance %" > 0) then
                            VendLedgEntry."Max. Payment Tolerance" :=
                              Round(Currency."Payment Tolerance %" * VendLedgEntry.Amount / 100, Currency."Amount Rounding Precision")
                        else
                            if VendLedgEntry."Document Type" = VendLedgEntry."Document Type"::"Credit Memo" then
                                VendLedgEntry."Max. Payment Tolerance" := Currency."Max. Payment Tolerance Amount"
                            else
                                VendLedgEntry."Max. Payment Tolerance" := -Currency."Max. Payment Tolerance Amount"
                    end else
                        VendLedgEntry."Max. Payment Tolerance" :=
                          Round(Currency."Payment Tolerance %" * VendLedgEntry.Amount / 100, Currency."Amount Rounding Precision");
                end;
            end;
            if Abs(VendLedgEntry.Amount) < Abs(VendLedgEntry."Max. Payment Tolerance") then
                VendLedgEntry."Max. Payment Tolerance" := VendLedgEntry.Amount;
            OnCalcTolVendLedgEntryOnBeforeModify(VendLedgEntry);
            VendLedgEntry.Modify();
        until VendLedgEntry.Next() = 0;
    end;

    procedure DelTolVendLedgEntry(Vendor: Record Vendor)
    var
        GLSetup: Record "General Ledger Setup";
        VendLedgEntry: Record "Vendor Ledger Entry";
    begin
        GLSetup.Get();
        VendLedgEntry.SetCurrentKey("Vendor No.", Open);
        VendLedgEntry.SetRange("Vendor No.", Vendor."No.");
        VendLedgEntry.SetRange(Open, true);
        VendLedgEntry.ReadIsolation(IsolationLevel::UpdLock);
        VendLedgEntry.SetLoadFields("Pmt. Disc. Tolerance Date", "Max. Payment Tolerance");
        if not VendLedgEntry.Find('-') then
            exit;
        repeat
            VendLedgEntry."Pmt. Disc. Tolerance Date" := 0D;
            VendLedgEntry."Max. Payment Tolerance" := 0;
            OnDelTolVendLedgEntryOnBeforeModify(VendLedgEntry);
            VendLedgEntry.Modify();
        until VendLedgEntry.Next() = 0;
    end;

    procedure DelPmtTolApllnDocNo(GenJnlLine: Record "Gen. Journal Line"; DocumentNo: Code[20])
    var
        AppliedCustLedgEntry: Record "Cust. Ledger Entry";
        AppliedVendLedgEntry: Record "Vendor Ledger Entry";
    begin
        OnBeforeDelPmtTolApllnDocNo(GenJnlLine);

        if (GenJnlLine."Bal. Account Type" = GenJnlLine."Bal. Account Type"::Customer) or
           (GenJnlLine."Bal. Account Type" = GenJnlLine."Bal. Account Type"::Vendor)
        then
            CODEUNIT.Run(CODEUNIT::"Exchange Acc. G/L Journal Line", GenJnlLine);

        if GenJnlLine."Account Type" = GenJnlLine."Account Type"::Customer then begin
            AppliedCustLedgEntry.SetCurrentKey("Customer No.", Open, Positive);
            AppliedCustLedgEntry.SetRange("Customer No.", GenJnlLine."Account No.");
            AppliedCustLedgEntry.SetRange(Open, true);
            AppliedCustLedgEntry.ReadIsolation(IsolationLevel::UpdLock);
            AppliedCustLedgEntry.SetLoadFields("Document No.", "Accepted Payment Tolerance", "Accepted Pmt. Disc. Tolerance");
            if AppliedCustLedgEntry.FindSet() then begin
                repeat
                    if AppliedCustLedgEntry."Document No." = DocumentNo then begin
                        AppliedCustLedgEntry."Accepted Payment Tolerance" := 0;
                        AppliedCustLedgEntry."Accepted Pmt. Disc. Tolerance" := false;
                        AppliedCustLedgEntry.Modify();
                    end;
                until AppliedCustLedgEntry.Next() = 0;
                if not SuppressCommit then
                    Commit();
            end;
        end else
            if GenJnlLine."Account Type" = GenJnlLine."Account Type"::Vendor then begin
                AppliedVendLedgEntry.SetCurrentKey("Vendor No.", Open, Positive);
                AppliedVendLedgEntry.SetRange("Vendor No.", GenJnlLine."Account No.");
                AppliedVendLedgEntry.SetRange(Open, true);
                AppliedVendLedgEntry.ReadIsolation(IsolationLevel::UpdLock);
                AppliedVendLedgEntry.SetLoadFields("Document No.", "Accepted Payment Tolerance", "Accepted Pmt. Disc. Tolerance");
                if AppliedVendLedgEntry.FindSet() then begin
                    repeat
                        if AppliedVendLedgEntry."Document No." = DocumentNo then begin
                            AppliedVendLedgEntry."Accepted Payment Tolerance" := 0;
                            AppliedVendLedgEntry."Accepted Pmt. Disc. Tolerance" := false;
                            AppliedVendLedgEntry.Modify();
                        end;
                    until AppliedVendLedgEntry.Next() = 0;
                    if not SuppressCommit then
                        Commit();
                end;
            end;

        OnAfterDelPmtTolApllnDocNo(GenJnlLine, DocumentNo, SuppressCommit);
    end;

    procedure ABSMinTol(Decimal1: Decimal; Decimal2: Decimal; Decimal1Tolerance: Decimal): Decimal
    begin
        if Abs(Decimal1) - Abs(Decimal1Tolerance) < Abs(Decimal2) then
            exit(Decimal1);
        exit(Decimal2);
    end;

    local procedure DelCustPmtTolAcc2(CustledgEntry: Record "Cust. Ledger Entry"; CustEntryApplID: Code[50])
    var
        AppliedCustLedgEntry: Record "Cust. Ledger Entry";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeDelCustPmtTolAcc2(CustledgEntry, CustEntryApplID, IsHandled);
        if IsHandled then
            exit;

        if CustEntryApplID <> '' then begin
            AppliedCustLedgEntry.SetCurrentKey("Customer No.", Open, Positive);
            AppliedCustLedgEntry.SetRange("Customer No.", CustledgEntry."Customer No.");
            AppliedCustLedgEntry.SetRange(Open, true);
            AppliedCustLedgEntry.ReadIsolation(IsolationLevel::UpdLock);
            AppliedCustLedgEntry.SetLoadFields("Applies-to ID", "Document Type", "Accepted Payment Tolerance", "Accepted Pmt. Disc. Tolerance");
            if AppliedCustLedgEntry.FindSet() then
                repeat
                    if (CustledgEntry."Document Type" = CustledgEntry."Document Type"::Payment) and (AppliedCustLedgEntry."Document Type" <> AppliedCustLedgEntry."Document Type"::Invoice) then
                        continue;
                    if (CustledgEntry."Document Type" = CustledgEntry."Document Type"::Refund) and (AppliedCustLedgEntry."Document Type" <> AppliedCustLedgEntry."Document Type"::"Credit Memo") then
                        continue;
                    if AppliedCustLedgEntry."Applies-to ID" = CustEntryApplID then begin
                        AppliedCustLedgEntry."Accepted Payment Tolerance" := 0;
                        AppliedCustLedgEntry."Accepted Pmt. Disc. Tolerance" := false;
                        AppliedCustLedgEntry.Modify();
                        if not SuppressCommit then
                            Commit();
                    end;
                until AppliedCustLedgEntry.Next() = 0;
        end;
    end;

    local procedure DelVendPmtTolAcc2(VendLedgEntry: Record "Vendor Ledger Entry"; VendEntryApplID: Code[50])
    var
        AppliedVendLedgEntry: Record "Vendor Ledger Entry";
    begin
        if VendEntryApplID <> '' then begin
            AppliedVendLedgEntry.SetCurrentKey("Vendor No.", Open, Positive);
            AppliedVendLedgEntry.SetRange("Vendor No.", VendLedgEntry."Vendor No.");
            AppliedVendLedgEntry.SetRange(Open, true);
            AppliedVendLedgEntry.ReadIsolation(IsolationLevel::UpdLock);
            AppliedVendLedgEntry.SetLoadFields("Applies-to ID", "Document Type", "Accepted Payment Tolerance", "Accepted Pmt. Disc. Tolerance");
            if AppliedVendLedgEntry.FindLast() then
                repeat
                    if (VendLedgEntry."Document Type" = VendLedgEntry."Document Type"::Payment) and (AppliedVendLedgEntry."Document Type" <> AppliedVendLedgEntry."Document Type"::Invoice) then
                        continue;
                    if (VendLedgEntry."Document Type" = VendLedgEntry."Document Type"::Refund) and (AppliedVendLedgEntry."Document Type" <> AppliedVendLedgEntry."Document Type"::"Credit Memo") then
                        continue;
                    if AppliedVendLedgEntry."Applies-to ID" = VendEntryApplID then begin
                        AppliedVendLedgEntry."Accepted Payment Tolerance" := 0;
                        AppliedVendLedgEntry."Accepted Pmt. Disc. Tolerance" := false;
                        AppliedVendLedgEntry.Modify();
                        if not SuppressCommit then
                            Commit();
                    end;
                until AppliedVendLedgEntry.Next() = 0;
        end;
    end;

    local procedure GetCustApplicationRoundingPrecisionForAppliesToID(var AppliedCustLedgEntry: Record "Cust. Ledger Entry"; var ApplnRoundingPrecision: Decimal; var AmountRoundingPrecision: Decimal; var ApplnInMultiCurrency: Boolean; ApplnCurrencyCode: Code[20])
    begin
        AppliedCustLedgEntry.SetFilter("Currency Code", '<>%1', ApplnCurrencyCode);
        ApplnInMultiCurrency := not AppliedCustLedgEntry.IsEmpty();
        AppliedCustLedgEntry.SetRange("Currency Code");

        GetAmountRoundingPrecision(ApplnRoundingPrecision, AmountRoundingPrecision, ApplnInMultiCurrency, ApplnCurrencyCode);
    end;

    local procedure GetVendApplicationRoundingPrecisionForAppliesToID(var AppliedVendLedgEntry: Record "Vendor Ledger Entry"; var ApplnRoundingPrecision: Decimal; var AmountRoundingPrecision: Decimal; var ApplnInMultiCurrency: Boolean; ApplnCurrencyCode: Code[20])
    begin
        AppliedVendLedgEntry.SetFilter("Currency Code", '<>%1', ApplnCurrencyCode);
        ApplnInMultiCurrency := not AppliedVendLedgEntry.IsEmpty();
        AppliedVendLedgEntry.SetRange("Currency Code");

        GetAmountRoundingPrecision(ApplnRoundingPrecision, AmountRoundingPrecision, ApplnInMultiCurrency, ApplnCurrencyCode);
    end;

    procedure GetApplicationRoundingPrecisionForAppliesToDoc(AppliedEntryCurrencyCode: Code[10]; var ApplnRoundingPrecision: Decimal; var AmountRoundingPrecision: Decimal; ApplnCurrencyCode: Code[20])
    var
        Currency: Record Currency;
    begin
        if ApplnCurrencyCode = '' then begin
            Currency.Init();
            Currency.Code := '';
            Currency.InitRoundingPrecision();
            if AppliedEntryCurrencyCode = '' then
                ApplnRoundingPrecision := 0;
        end else
            if ApplnCurrencyCode <> AppliedEntryCurrencyCode then begin
                Currency.Get(ApplnCurrencyCode);
                ApplnRoundingPrecision := Currency."Appln. Rounding Precision";
            end else
                ApplnRoundingPrecision := 0;

        AmountRoundingPrecision := Currency."Amount Rounding Precision";
    end;

    local procedure UpdateCustAmountsForApplication(var AppliedCustLedgEntry: Record "Cust. Ledger Entry"; var CustLedgEntry: Record "Cust. Ledger Entry"; var TempAppliedCustLedgEntry: Record "Cust. Ledger Entry" temporary)
    begin
        AppliedCustLedgEntry.CalcFields("Remaining Amount");
        OnUpdateCustAmountsForApplicationAfterCalcRemainingAmount(AppliedCustLedgEntry);
        TempAppliedCustLedgEntry := AppliedCustLedgEntry;
        if CustLedgEntry."Currency Code" <> AppliedCustLedgEntry."Currency Code" then
            AppliedCustLedgEntry.UpdateAmountsForApplication(CustLedgEntry."Posting Date", CustLedgEntry."Currency Code", true, true);
    end;

    local procedure UpdateVendAmountsForApplication(var AppliedVendLedgEntry: Record "Vendor Ledger Entry"; var VendLedgEntry: Record "Vendor Ledger Entry"; var TempAppliedVendLedgEntry: Record "Vendor Ledger Entry" temporary)
    begin
        AppliedVendLedgEntry.CalcFields("Remaining Amount");
        OnUpdateVendAmountsForApplicationAfterCalcRemainingAmount(AppliedVendLedgEntry);
        TempAppliedVendLedgEntry := AppliedVendLedgEntry;
        if VendLedgEntry."Currency Code" <> AppliedVendLedgEntry."Currency Code" then
            AppliedVendLedgEntry.UpdateAmountsForApplication(VendLedgEntry."Posting Date", VendLedgEntry."Currency Code", true, true);
    end;

    local procedure GetCustPositiveFilter(DocumentType: Enum "Gen. Journal Document Type"; TempAmount: Decimal) PositiveFilter: Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetCustPositiveFilter(DocumentType, TempAmount, IsHandled, PositiveFilter);
        if IsHandled then
            exit(PositiveFilter);

        PositiveFilter := TempAmount <= 0;
        if ((TempAmount > 0) and (DocumentType = DocumentType::Refund) or (DocumentType = DocumentType::Invoice) or
            (DocumentType = DocumentType::"Credit Memo"))
        then
            PositiveFilter := true;

        exit(PositiveFilter);
    end;

    local procedure GetVendPositiveFilter(DocumentType: Enum "Gen. Journal Document Type"; TempAmount: Decimal) PositiveFilter: Boolean
    begin
        PositiveFilter := TempAmount >= 0;
        if ((TempAmount < 0) and (DocumentType = DocumentType::Refund) or (DocumentType = DocumentType::Invoice) or
            (DocumentType = DocumentType::"Credit Memo"))
        then
            PositiveFilter := true;

        exit(PositiveFilter);
    end;

    local procedure CheckCustPaymentAmountsForAppliesToID(CustLedgEntry: Record "Cust. Ledger Entry"; var AppliedCustLedgEntry: Record "Cust. Ledger Entry"; var TempAppliedCustLedgEntry: Record "Cust. Ledger Entry" temporary; var MaxPmtTolAmount: Decimal; var AvailableAmount: Decimal; var TempAmount: Decimal; ApplnRoundingPrecision: Decimal)
    begin
        // Check Payment Tolerance
        if CheckPmtTolCust(CustLedgEntry."Document Type", AppliedCustLedgEntry) then
            MaxPmtTolAmount := MaxPmtTolAmount + AppliedCustLedgEntry."Max. Payment Tolerance";

        // Check Payment Discount
        if CheckCalcPmtDiscCust(CustLedgEntry, AppliedCustLedgEntry, 0, false, false) then
            AppliedCustLedgEntry."Remaining Amount" :=
              AppliedCustLedgEntry."Remaining Amount" - AppliedCustLedgEntry.GetRemainingPmtDiscPossible(CustLedgEntry."Posting Date");

        // Check Payment Discount Tolerance
        if AppliedCustLedgEntry."Amount to Apply" = AppliedCustLedgEntry."Remaining Amount" then
            AvailableAmount := TempAmount
        else
            AvailableAmount := -AppliedCustLedgEntry."Amount to Apply";
        if CheckPmtDiscTolCust(
             CustLedgEntry."Posting Date", CustLedgEntry."Document Type", AvailableAmount, AppliedCustLedgEntry, ApplnRoundingPrecision,
             MaxPmtTolAmount)
        then begin
            AppliedCustLedgEntry."Remaining Amount" :=
              AppliedCustLedgEntry."Remaining Amount" - AppliedCustLedgEntry."Remaining Pmt. Disc. Possible";
            AppliedCustLedgEntry."Accepted Pmt. Disc. Tolerance" := true;
            if CustLedgEntry."Currency Code" <> AppliedCustLedgEntry."Currency Code" then begin
                AppliedCustLedgEntry."Remaining Pmt. Disc. Possible" :=
                  TempAppliedCustLedgEntry."Remaining Pmt. Disc. Possible";
                AppliedCustLedgEntry."Max. Payment Tolerance" :=
                  TempAppliedCustLedgEntry."Max. Payment Tolerance";
            end;
            AppliedCustLedgEntry.Modify();
        end;
        TempAmount :=
          TempAmount +
          ABSMinTol(
            AppliedCustLedgEntry."Remaining Amount",
            AppliedCustLedgEntry."Amount to Apply",
            MaxPmtTolAmount);
    end;

    local procedure CheckVendPaymentAmountsForAppliesToID(VendLedgEntry: Record "Vendor Ledger Entry"; var AppliedVendLedgEntry: Record "Vendor Ledger Entry"; var TempAppliedVendLedgEntry: Record "Vendor Ledger Entry" temporary; var MaxPmtTolAmount: Decimal; var AvailableAmount: Decimal; var TempAmount: Decimal; ApplnRoundingPrecision: Decimal)
    begin
        // Check Payment Tolerance
        if CheckPmtTolVend(VendLedgEntry."Document Type", AppliedVendLedgEntry) then
            MaxPmtTolAmount := MaxPmtTolAmount + AppliedVendLedgEntry."Max. Payment Tolerance";

        // Check Payment Discount
        if CheckCalcPmtDiscVend(VendLedgEntry, AppliedVendLedgEntry, 0, false, false) then
            AppliedVendLedgEntry."Remaining Amount" :=
              AppliedVendLedgEntry."Remaining Amount" - AppliedVendLedgEntry.GetRemainingPmtDiscPossible(VendLedgEntry."Posting Date");

        // Check Payment Discount Tolerance
        if AppliedVendLedgEntry."Amount to Apply" = AppliedVendLedgEntry."Remaining Amount" then
            AvailableAmount := TempAmount
        else
            AvailableAmount := -AppliedVendLedgEntry."Amount to Apply";
        if CheckPmtDiscTolVend(VendLedgEntry."Posting Date", VendLedgEntry."Document Type", AvailableAmount,
             AppliedVendLedgEntry, ApplnRoundingPrecision, MaxPmtTolAmount)
        then begin
            AppliedVendLedgEntry."Remaining Amount" :=
              AppliedVendLedgEntry."Remaining Amount" - AppliedVendLedgEntry."Remaining Pmt. Disc. Possible";
            AppliedVendLedgEntry."Accepted Pmt. Disc. Tolerance" := true;
            if VendLedgEntry."Currency Code" <> AppliedVendLedgEntry."Currency Code" then begin
                AppliedVendLedgEntry."Remaining Pmt. Disc. Possible" :=
                  TempAppliedVendLedgEntry."Remaining Pmt. Disc. Possible";
                AppliedVendLedgEntry."Max. Payment Tolerance" :=
                  TempAppliedVendLedgEntry."Max. Payment Tolerance";
            end;
            AppliedVendLedgEntry.Modify();
        end;
        TempAmount :=
          TempAmount +
          ABSMinTol(
            AppliedVendLedgEntry."Remaining Amount",
            AppliedVendLedgEntry."Amount to Apply",
            MaxPmtTolAmount);
    end;

    local procedure CheckCustPaymentAmountsForAppliesToDoc(CustLedgEntry: Record "Cust. Ledger Entry"; var AppliedCustLedgEntry: Record "Cust. Ledger Entry"; var TempAppliedCustLedgEntry: Record "Cust. Ledger Entry" temporary; var MaxPmtTolAmount: Decimal; ApplnRoundingPrecision: Decimal; var PmtDiscAmount: Decimal; ApplnCurrencyCode: Code[20])
    begin
        // Check Payment Tolerance
        if CheckPmtTolCust(CustLedgEntry."Document Type", AppliedCustLedgEntry) and
           CheckCustLedgAmt(CustLedgEntry, AppliedCustLedgEntry, AppliedCustLedgEntry."Max. Payment Tolerance", ApplnRoundingPrecision)
        then
            MaxPmtTolAmount := MaxPmtTolAmount + AppliedCustLedgEntry."Max. Payment Tolerance";

        // Check Payment Discount
        if CheckCalcPmtDiscCust(CustLedgEntry, AppliedCustLedgEntry, 0, false, false) and
           CheckCustLedgAmt(CustLedgEntry, AppliedCustLedgEntry, MaxPmtTolAmount, ApplnRoundingPrecision)
        then
            PmtDiscAmount := PmtDiscAmount + AppliedCustLedgEntry.GetRemainingPmtDiscPossible(CustLedgEntry."Posting Date");

        // Check Payment Discount Tolerance
        if CheckPmtDiscTolCust(
             CustLedgEntry."Posting Date", CustLedgEntry."Document Type", CustLedgEntry.Amount, AppliedCustLedgEntry,
             ApplnRoundingPrecision, MaxPmtTolAmount) and CheckCustLedgAmt(
             CustLedgEntry, AppliedCustLedgEntry, MaxPmtTolAmount, ApplnRoundingPrecision)
        then begin
            PmtDiscAmount := PmtDiscAmount + AppliedCustLedgEntry."Remaining Pmt. Disc. Possible";
            AppliedCustLedgEntry."Accepted Pmt. Disc. Tolerance" := true;
            if AppliedCustLedgEntry."Currency Code" <> ApplnCurrencyCode then begin
                AppliedCustLedgEntry."Max. Payment Tolerance" :=
                  TempAppliedCustLedgEntry."Max. Payment Tolerance";
                AppliedCustLedgEntry."Remaining Pmt. Disc. Possible" :=
                  TempAppliedCustLedgEntry."Remaining Pmt. Disc. Possible";
            end;
            AppliedCustLedgEntry.Modify();
            if not SuppressCommit then
                Commit();
        end;
    end;

    local procedure CheckVendPaymentAmountsForAppliesToDoc(VendLedgEntry: Record "Vendor Ledger Entry"; var AppliedVendLedgEntry: Record "Vendor Ledger Entry"; var TempAppliedVendLedgEntry: Record "Vendor Ledger Entry" temporary; var MaxPmtTolAmount: Decimal; ApplnRoundingPrecision: Decimal; var PmtDiscAmount: Decimal)
    begin
        // Check Payment Tolerance
        if CheckPmtTolVend(VendLedgEntry."Document Type", AppliedVendLedgEntry) and
           CheckVendLedgAmt(VendLedgEntry, AppliedVendLedgEntry, AppliedVendLedgEntry."Max. Payment Tolerance", ApplnRoundingPrecision)
        then
            MaxPmtTolAmount := MaxPmtTolAmount + AppliedVendLedgEntry."Max. Payment Tolerance";

        // Check Payment Discount
        if CheckCalcPmtDiscVend(
             VendLedgEntry, AppliedVendLedgEntry, 0, false, false) and
           CheckVendLedgAmt(VendLedgEntry, AppliedVendLedgEntry, MaxPmtTolAmount, ApplnRoundingPrecision)
        then
            PmtDiscAmount := PmtDiscAmount + AppliedVendLedgEntry.GetRemainingPmtDiscPossible(VendLedgEntry."Posting Date");

        // Check Payment Discount Tolerance
        if CheckPmtDiscTolVend(
             VendLedgEntry."Posting Date", VendLedgEntry."Document Type", VendLedgEntry.Amount,
             AppliedVendLedgEntry, ApplnRoundingPrecision, MaxPmtTolAmount) and
           CheckVendLedgAmt(VendLedgEntry, AppliedVendLedgEntry, MaxPmtTolAmount, ApplnRoundingPrecision)
        then begin
            PmtDiscAmount := PmtDiscAmount + AppliedVendLedgEntry."Remaining Pmt. Disc. Possible";
            AppliedVendLedgEntry."Accepted Pmt. Disc. Tolerance" := true;
            if VendLedgEntry."Currency Code" <> AppliedVendLedgEntry."Currency Code" then begin
                AppliedVendLedgEntry."Remaining Pmt. Disc. Possible" := TempAppliedVendLedgEntry."Remaining Pmt. Disc. Possible";
                AppliedVendLedgEntry."Max. Payment Tolerance" := TempAppliedVendLedgEntry."Max. Payment Tolerance";
            end;
            AppliedVendLedgEntry.Modify();
            if not SuppressCommit then
                Commit();
        end;
    end;

    local procedure CheckCustLedgAmt(CustLedgEntry: Record "Cust. Ledger Entry"; AppliedCustLedgEntry: Record "Cust. Ledger Entry"; MaxPmtTolAmount: Decimal; ApplnRoundingPrecision: Decimal): Boolean
    begin
        exit((Abs(CustLedgEntry.Amount) + ApplnRoundingPrecision >= Abs(AppliedCustLedgEntry."Remaining Amount" -
                AppliedCustLedgEntry."Remaining Pmt. Disc. Possible" - MaxPmtTolAmount)));
    end;

    local procedure CheckVendLedgAmt(VendLedgEntry: Record "Vendor Ledger Entry"; AppliedVendLedgEntry: Record "Vendor Ledger Entry"; MaxPmtTolAmount: Decimal; ApplnRoundingPrecision: Decimal): Boolean
    begin
        exit((Abs(VendLedgEntry.Amount) + ApplnRoundingPrecision >= Abs(AppliedVendLedgEntry."Remaining Amount" -
                AppliedVendLedgEntry."Remaining Pmt. Disc. Possible" - MaxPmtTolAmount)));
    end;

    procedure GetAmountRoundingPrecision(var ApplnRoundingPrecision: Decimal; var AmountRoundingPrecision: Decimal; ApplnInMultiCurrency: Boolean; ApplnCurrencyCode: Code[20])
    var
        Currency: Record Currency;
    begin
        if ApplnCurrencyCode = '' then begin
            Currency.Init();
            Currency.Code := '';
            Currency.InitRoundingPrecision();
        end else
            if ApplnInMultiCurrency then
                Currency.Get(ApplnCurrencyCode)
            else
                Currency.Init();

        ApplnRoundingPrecision := Currency."Appln. Rounding Precision";
        AmountRoundingPrecision := Currency."Amount Rounding Precision";
    end;

    procedure CalcRemainingPmtDisc(var NewCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var OldCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var OldCVLedgEntryBuf2: Record "CV Ledger Entry Buffer"; GLSetup: Record "General Ledger Setup")
    var
        Handled: Boolean;
    begin
        OnBeforeCalcRemainingPmtDisc(NewCVLedgEntryBuf, OldCVLedgEntryBuf, OldCVLedgEntryBuf2, GLSetup, Handled);
        if Handled then
            exit;

        if Abs(NewCVLedgEntryBuf."Max. Payment Tolerance") > Abs(NewCVLedgEntryBuf."Remaining Amount") then
            NewCVLedgEntryBuf."Max. Payment Tolerance" := NewCVLedgEntryBuf."Remaining Amount";
        if (((NewCVLedgEntryBuf."Document Type" in [NewCVLedgEntryBuf."Document Type"::"Credit Memo",
                                                    NewCVLedgEntryBuf."Document Type"::Invoice]) and
             (OldCVLedgEntryBuf."Document Type" in [OldCVLedgEntryBuf."Document Type"::Invoice,
                                                    OldCVLedgEntryBuf."Document Type"::"Credit Memo"])) and
            ((OldCVLedgEntryBuf."Remaining Pmt. Disc. Possible" <> 0) and
             (NewCVLedgEntryBuf."Remaining Pmt. Disc. Possible" <> 0)) or
            ((OldCVLedgEntryBuf."Document Type" = OldCVLedgEntryBuf."Document Type"::"Credit Memo") and
             (OldCVLedgEntryBuf."Remaining Pmt. Disc. Possible" <> 0) and
             (NewCVLedgEntryBuf."Document Type" <> NewCVLedgEntryBuf."Document Type"::Refund)))
        then begin
            if OldCVLedgEntryBuf."Remaining Amount" <> 0 then
                OldCVLedgEntryBuf2."Remaining Pmt. Disc. Possible" :=
                  Round(OldCVLedgEntryBuf."Remaining Pmt. Disc. Possible" -
                    (OldCVLedgEntryBuf."Remaining Pmt. Disc. Possible" *
                     (OldCVLedgEntryBuf2."Remaining Amount" - OldCVLedgEntryBuf."Remaining Amount") /
                     OldCVLedgEntryBuf2."Remaining Amount"), GLSetup."Amount Rounding Precision");
            if NewCVLedgEntryBuf."Remaining Amount" - OldCVLedgEntryBuf2."Remaining Amount" + OldCVLedgEntryBuf."Remaining Amount" <> 0 then
                NewCVLedgEntryBuf."Remaining Pmt. Disc. Possible" :=
                  Round(NewCVLedgEntryBuf."Remaining Pmt. Disc. Possible" +
                    (NewCVLedgEntryBuf."Remaining Pmt. Disc. Possible" *
                     (OldCVLedgEntryBuf2."Remaining Amount" - OldCVLedgEntryBuf."Remaining Amount") /
                     (NewCVLedgEntryBuf."Remaining Amount" -
                      OldCVLedgEntryBuf2."Remaining Amount" + OldCVLedgEntryBuf."Remaining Amount")),
                    GLSetup."Amount Rounding Precision");

            if NewCVLedgEntryBuf."Currency Code" = OldCVLedgEntryBuf2."Currency Code" then
                OldCVLedgEntryBuf."Remaining Pmt. Disc. Possible" := OldCVLedgEntryBuf2."Remaining Pmt. Disc. Possible"
            else
                OldCVLedgEntryBuf."Remaining Pmt. Disc. Possible" := OldCVLedgEntryBuf2."Remaining Pmt. Disc. Possible";
        end;

        if OldCVLedgEntryBuf."Document Type" in [OldCVLedgEntryBuf."Document Type"::Invoice,
                                                 OldCVLedgEntryBuf."Document Type"::"Credit Memo"]
        then
            if Abs(OldCVLedgEntryBuf."Remaining Amount") < Abs(OldCVLedgEntryBuf."Max. Payment Tolerance") then
                OldCVLedgEntryBuf."Max. Payment Tolerance" := OldCVLedgEntryBuf."Remaining Amount";

        if not NewCVLedgEntryBuf.Open then begin
            NewCVLedgEntryBuf."Remaining Pmt. Disc. Possible" := 0;
            NewCVLedgEntryBuf."Max. Payment Tolerance" := 0;
        end;

        if not OldCVLedgEntryBuf.Open then begin
            OldCVLedgEntryBuf."Remaining Pmt. Disc. Possible" := 0;
            OldCVLedgEntryBuf."Max. Payment Tolerance" := 0;
        end;
    end;

    procedure CalcMaxPmtTolerance(DocumentType: Enum "Gen. Journal Document Type"; CurrencyCode: Code[10]; Amount: Decimal; AmountLCY: Decimal; Sign: Decimal; var MaxPaymentTolerance: Decimal)
    var
        Currency: Record Currency;
        GLSetup: Record "General Ledger Setup";
        MaxPaymentToleranceAmount: Decimal;
        PaymentTolerancePct: Decimal;
        PaymentAmount: Decimal;
        AmountRoundingPrecision: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcMaxPmtTolerance(DocumentType.AsInteger(), CurrencyCode, Amount, AmountLCY, Sign, MaxPaymentTolerance, IsHandled);
        if IsHandled then
            exit;

        if CurrencyCode = '' then begin
            GLSetup.Get();
            MaxPaymentToleranceAmount := GLSetup."Max. Payment Tolerance Amount";
            PaymentTolerancePct := GLSetup."Payment Tolerance %";
            AmountRoundingPrecision := GLSetup."Amount Rounding Precision";
            PaymentAmount := AmountLCY;
        end else begin
            Currency.Get(CurrencyCode);
            MaxPaymentToleranceAmount := Currency."Max. Payment Tolerance Amount";
            PaymentTolerancePct := Currency."Payment Tolerance %";
            AmountRoundingPrecision := Currency."Amount Rounding Precision";
            PaymentAmount := Amount;
        end;

        if (MaxPaymentToleranceAmount <
            Abs(PaymentTolerancePct / 100 * PaymentAmount)) or (PaymentTolerancePct = 0)
        then begin
            if (MaxPaymentToleranceAmount = 0) and (PaymentTolerancePct > 0) then
                MaxPaymentTolerance :=
                  Round(PaymentTolerancePct * PaymentAmount / 100, AmountRoundingPrecision)
            else
                if DocumentType = DocumentType::"Credit Memo" then
                    MaxPaymentTolerance := -MaxPaymentToleranceAmount * Sign
                else
                    MaxPaymentTolerance := MaxPaymentToleranceAmount * Sign
        end else
            MaxPaymentTolerance :=
              Round(PaymentTolerancePct * PaymentAmount / 100, AmountRoundingPrecision);

        if Abs(MaxPaymentTolerance) > Abs(Amount) then
            MaxPaymentTolerance := Amount;

        OnAfterCalcMaxPmtTolerance(DocumentType.AsInteger(), CurrencyCode, Amount, AmountLCY, Sign, MaxPaymentTolerance);
    end;

    procedure CheckCalcPmtDisc(var NewCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var OldCVLedgEntryBuf2: Record "CV Ledger Entry Buffer"; ApplnRoundingPrecision: Decimal; CheckFilter: Boolean; CheckAmount: Boolean): Boolean
    var
        Handled: Boolean;
        Result: Boolean;
    begin
        OnBeforeCheckCalcPmtDisc(NewCVLedgEntryBuf, OldCVLedgEntryBuf2, ApplnRoundingPrecision, CheckFilter, CheckAmount, Handled, Result);
        if Handled then
            exit(Result);

        if ((NewCVLedgEntryBuf."Document Type" in [NewCVLedgEntryBuf."Document Type"::Refund,
                                                   NewCVLedgEntryBuf."Document Type"::Payment]) and
            (((OldCVLedgEntryBuf2."Document Type" = OldCVLedgEntryBuf2."Document Type"::"Credit Memo") and
              (OldCVLedgEntryBuf2.GetRemainingPmtDiscPossible(NewCVLedgEntryBuf."Posting Date") <> 0) and
              (NewCVLedgEntryBuf."Posting Date" <= OldCVLedgEntryBuf2."Pmt. Discount Date")) or
             ((OldCVLedgEntryBuf2."Document Type" = OldCVLedgEntryBuf2."Document Type"::Invoice) and
              (OldCVLedgEntryBuf2.GetRemainingPmtDiscPossible(NewCVLedgEntryBuf."Posting Date") <> 0) and
              (NewCVLedgEntryBuf."Posting Date" <= OldCVLedgEntryBuf2."Pmt. Discount Date"))))
        then begin
            if CheckFilter then begin
                if CheckAmount then begin
                    if (OldCVLedgEntryBuf2.GetFilter(Positive) <> '') or
                       (Abs(NewCVLedgEntryBuf."Remaining Amount") + ApplnRoundingPrecision >=
                        Abs(OldCVLedgEntryBuf2."Remaining Amount" - OldCVLedgEntryBuf2.GetRemainingPmtDiscPossible(NewCVLedgEntryBuf."Posting Date")))
                    then
                        exit(true);

                    exit(false);
                end;

                exit(OldCVLedgEntryBuf2.GetFilter(Positive) <> '');
            end;
            if CheckAmount then
                exit((Abs(NewCVLedgEntryBuf."Remaining Amount") + ApplnRoundingPrecision >=
                      Abs(OldCVLedgEntryBuf2."Remaining Amount" - OldCVLedgEntryBuf2."Remaining Pmt. Disc. Possible")));

            exit(true);
        end;
        exit(false);
    end;

    procedure CheckCalcPmtDiscCVCust(var NewCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var OldCustLedgEntry2: Record "Cust. Ledger Entry"; ApplnRoundingPrecision: Decimal; CheckFilter: Boolean; CheckAmount: Boolean): Boolean
    var
        OldCVLedgEntryBuf2: Record "CV Ledger Entry Buffer";
    begin
        OldCustLedgEntry2.CopyFilter(Positive, OldCVLedgEntryBuf2.Positive);
        OldCVLedgEntryBuf2.CopyFromCustLedgEntry(OldCustLedgEntry2);
        exit(
          CheckCalcPmtDisc(
            NewCVLedgEntryBuf, OldCVLedgEntryBuf2, ApplnRoundingPrecision, CheckFilter, CheckAmount));
    end;

    procedure CheckCalcPmtDiscCust(var NewCustLedgEntry: Record "Cust. Ledger Entry"; var OldCustLedgEntry2: Record "Cust. Ledger Entry"; ApplnRoundingPrecision: Decimal; CheckFilter: Boolean; CheckAmount: Boolean): Boolean
    var
        NewCVLedgEntryBuf: Record "CV Ledger Entry Buffer";
        OldCVLedgEntryBuf2: Record "CV Ledger Entry Buffer";
    begin
        NewCVLedgEntryBuf.CopyFromCustLedgEntry(NewCustLedgEntry);
        OldCustLedgEntry2.CopyFilter(Positive, OldCVLedgEntryBuf2.Positive);
        OldCVLedgEntryBuf2.CopyFromCustLedgEntry(OldCustLedgEntry2);
        exit(
          CheckCalcPmtDisc(
            NewCVLedgEntryBuf, OldCVLedgEntryBuf2, ApplnRoundingPrecision, CheckFilter, CheckAmount));
    end;

    procedure CheckCalcPmtDiscGenJnlCust(GenJnlLine: Record "Gen. Journal Line"; OldCustLedgEntry2: Record "Cust. Ledger Entry"; ApplnRoundingPrecision: Decimal; CheckAmount: Boolean): Boolean
    var
        NewCVLedgEntryBuf: Record "CV Ledger Entry Buffer";
        OldCVLedgEntryBuf2: Record "CV Ledger Entry Buffer";
    begin
        NewCVLedgEntryBuf."Document Type" := GenJnlLine."Document Type";
        NewCVLedgEntryBuf."Posting Date" := GenJnlLine."Posting Date";
        NewCVLedgEntryBuf."Remaining Amount" := GenJnlLine.Amount;
        OldCVLedgEntryBuf2.CopyFromCustLedgEntry(OldCustLedgEntry2);
        exit(
          CheckCalcPmtDisc(
            NewCVLedgEntryBuf, OldCVLedgEntryBuf2, ApplnRoundingPrecision, false, CheckAmount));
    end;

    procedure CheckCalcPmtDiscCVVend(var NewCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var OldVendLedgEntry2: Record "Vendor Ledger Entry"; ApplnRoundingPrecision: Decimal; CheckFilter: Boolean; CheckAmount: Boolean): Boolean
    var
        OldCVLedgEntryBuf2: Record "CV Ledger Entry Buffer";
    begin
        OldVendLedgEntry2.CopyFilter(Positive, OldCVLedgEntryBuf2.Positive);
        OldCVLedgEntryBuf2.CopyFromVendLedgEntry(OldVendLedgEntry2);
        exit(
          CheckCalcPmtDisc(
            NewCVLedgEntryBuf, OldCVLedgEntryBuf2, ApplnRoundingPrecision, CheckFilter, CheckAmount));
    end;

    procedure CheckCalcPmtDiscVend(var NewVendLedgEntry: Record "Vendor Ledger Entry"; var OldVendLedgEntry2: Record "Vendor Ledger Entry"; ApplnRoundingPrecision: Decimal; CheckFilter: Boolean; CheckAmount: Boolean): Boolean
    var
        NewCVLedgEntryBuf: Record "CV Ledger Entry Buffer";
        OldCVLedgEntryBuf2: Record "CV Ledger Entry Buffer";
    begin
        NewCVLedgEntryBuf.CopyFromVendLedgEntry(NewVendLedgEntry);
        OldVendLedgEntry2.CopyFilter(Positive, OldCVLedgEntryBuf2.Positive);
        OldCVLedgEntryBuf2.CopyFromVendLedgEntry(OldVendLedgEntry2);
        exit(
          CheckCalcPmtDisc(
            NewCVLedgEntryBuf, OldCVLedgEntryBuf2, ApplnRoundingPrecision, CheckFilter, CheckAmount));
    end;

    procedure CheckCalcPmtDiscGenJnlVend(GenJnlLine: Record "Gen. Journal Line"; OldVendLedgEntry2: Record "Vendor Ledger Entry"; ApplnRoundingPrecision: Decimal; CheckAmount: Boolean): Boolean
    var
        NewCVLedgEntryBuf: Record "CV Ledger Entry Buffer";
        OldCVLedgEntryBuf2: Record "CV Ledger Entry Buffer";
    begin
        NewCVLedgEntryBuf."Document Type" := GenJnlLine."Document Type";
        NewCVLedgEntryBuf."Posting Date" := GenJnlLine."Posting Date";
        NewCVLedgEntryBuf."Remaining Amount" := GenJnlLine.Amount;
        OldCVLedgEntryBuf2.CopyFromVendLedgEntry(OldVendLedgEntry2);
        exit(
          CheckCalcPmtDisc(
            NewCVLedgEntryBuf, OldCVLedgEntryBuf2, ApplnRoundingPrecision, false, CheckAmount));
    end;

    local procedure ManagePaymentDiscToleranceWarningCustomer(var NewCustLedgEntry: Record "Cust. Ledger Entry"; GenJnlLineApplID: Code[50]; var AppliedAmount: Decimal; var AmountToApply: Decimal; AppliesToDocNo: Code[20]): Boolean
    var
        AppliedCustLedgEntry: Record "Cust. Ledger Entry";
        RemainingAmountTest: Boolean;
    begin
        AppliedCustLedgEntry.SetCurrentKey("Customer No.", "Applies-to ID", Open, Positive);
        AppliedCustLedgEntry.SetRange("Customer No.", NewCustLedgEntry."Customer No.");
        if AppliesToDocNo <> '' then
            AppliedCustLedgEntry.SetRange("Document No.", AppliesToDocNo)
        else
            AppliedCustLedgEntry.SetRange("Applies-to ID", GenJnlLineApplID);
        AppliedCustLedgEntry.SetRange(Open, true);
        AppliedCustLedgEntry.SetRange("Accepted Pmt. Disc. Tolerance", true);
        if AppliedCustLedgEntry.FindSet() then
            repeat
                AppliedCustLedgEntry.CalcFields("Remaining Amount");
                OnManagePaymentDiscToleranceWarningCustomerAfterCalcRemainingAmount(AppliedCustLedgEntry);
                if CallPmtDiscTolWarning(
                     AppliedCustLedgEntry."Posting Date", AppliedCustLedgEntry."Customer No.",
                     AppliedCustLedgEntry."Document No.", AppliedCustLedgEntry."Currency Code",
                     AppliedCustLedgEntry."Remaining Amount", 0,
                     AppliedCustLedgEntry."Remaining Pmt. Disc. Possible", RemainingAmountTest, "Payment Tolerance Account Type"::Customer)
                then begin
                    if RemainingAmountTest then begin
                        AppliedCustLedgEntry."Accepted Pmt. Disc. Tolerance" := false;
                        AppliedCustLedgEntry.Modify();
                        if not SuppressCommit then
                            Commit();
                        if NewCustLedgEntry."Currency Code" <> AppliedCustLedgEntry."Currency Code" then
                            AppliedCustLedgEntry."Remaining Pmt. Disc. Possible" :=
                              CurrExchRate.ExchangeAmount(
                                AppliedCustLedgEntry."Remaining Pmt. Disc. Possible",
                                AppliedCustLedgEntry."Currency Code",
                                NewCustLedgEntry."Currency Code",
                                NewCustLedgEntry."Posting Date");
                        AppliedAmount := AppliedAmount + AppliedCustLedgEntry."Remaining Pmt. Disc. Possible";
                        AmountToApply := AmountToApply + AppliedCustLedgEntry."Remaining Pmt. Disc. Possible";
                    end else
                        if (AppliedCustLedgEntry."Remaining Pmt. Disc. Possible" - AppliedCustLedgEntry."Remaining Amount") <> NewCustLedgEntry.Amount then begin
                            NewCustLedgEntry.Amount += AppliedCustLedgEntry."Remaining Pmt. Disc. Possible";
                            UpdateGenJournalLineAmount(NewCustLedgEntry.Amount);
                            AdjustRemainingAmount(NewCustLedgEntry, AppliedCustLedgEntry."Remaining Amount");
                            if not SuppressCommit then
                                Commit();
                        end;
                end else begin
                    DelCustPmtTolAcc(NewCustLedgEntry, GenJnlLineApplID);
                    exit(false);
                end;
            until AppliedCustLedgEntry.Next() = 0;

        exit(true);
    end;

    local procedure ManagePaymentDiscToleranceWarningVendor(var NewVendLedgEntry: Record "Vendor Ledger Entry"; GenJnlLineApplID: Code[50]; var AppliedAmount: Decimal; var AmountToApply: Decimal; AppliesToDocNo: Code[20]): Boolean
    var
        AppliedVendLedgEntry: Record "Vendor Ledger Entry";
        RemainingAmountTest: Boolean;
    begin
        AppliedVendLedgEntry.SetCurrentKey("Vendor No.", "Applies-to ID", Open, Positive);
        AppliedVendLedgEntry.SetRange("Vendor No.", NewVendLedgEntry."Vendor No.");
        if AppliesToDocNo <> '' then
            AppliedVendLedgEntry.SetRange("Document No.", AppliesToDocNo)
        else
            AppliedVendLedgEntry.SetRange("Applies-to ID", GenJnlLineApplID);
        AppliedVendLedgEntry.SetRange(Open, true);
        AppliedVendLedgEntry.SetRange("Accepted Pmt. Disc. Tolerance", true);
        if AppliedVendLedgEntry.FindSet() then
            repeat
                AppliedVendLedgEntry.CalcFields("Remaining Amount");
                OnManagePaymentDiscToleranceWarningVendorAfterCalcRemainingAmount(AppliedVendLedgEntry);
                if CallPmtDiscTolWarning(
                     AppliedVendLedgEntry."Posting Date", AppliedVendLedgEntry."Vendor No.",
                     AppliedVendLedgEntry."Document No.", AppliedVendLedgEntry."Currency Code",
                     AppliedVendLedgEntry."Remaining Amount", 0,
                     AppliedVendLedgEntry."Remaining Pmt. Disc. Possible", RemainingAmountTest, "Payment Tolerance Account Type"::Vendor)
                then begin
                    if RemainingAmountTest then begin
                        AppliedVendLedgEntry."Accepted Pmt. Disc. Tolerance" := false;
                        AppliedVendLedgEntry.Modify();
                        if not SuppressCommit then
                            Commit();
                        if NewVendLedgEntry."Currency Code" <> AppliedVendLedgEntry."Currency Code" then
                            AppliedVendLedgEntry."Remaining Pmt. Disc. Possible" :=
                              CurrExchRate.ExchangeAmount(
                                AppliedVendLedgEntry."Remaining Pmt. Disc. Possible",
                                AppliedVendLedgEntry."Currency Code",
                                NewVendLedgEntry."Currency Code", NewVendLedgEntry."Posting Date");
                        AppliedAmount := AppliedAmount + AppliedVendLedgEntry."Remaining Pmt. Disc. Possible";
                        AmountToApply := AmountToApply + AppliedVendLedgEntry."Remaining Pmt. Disc. Possible";
                    end
                end else begin
                    DelVendPmtTolAcc(NewVendLedgEntry, GenJnlLineApplID);
                    exit(false);
                end;
            until AppliedVendLedgEntry.Next() = 0;

        exit(true);
    end;

    procedure SetSuppressCommit(NewSuppressCommit: Boolean)
    begin
        SuppressCommit := NewSuppressCommit;
    end;

    procedure SetSuppressWarning(NewSuppressWarning: Boolean)
    begin
        SuppressWarning := NewSuppressWarning;
    end;

    local procedure IsCustBlockPmtToleranceInGenJnlLine(var GenJnlLine: Record "Gen. Journal Line"): Boolean
    begin
        CheckAccountType(GenJnlLine, GenJnlLine."Account Type"::Customer);

        if GenJnlLine."Bal. Account Type" = GenJnlLine."Bal. Account Type"::Customer then
            CODEUNIT.Run(CODEUNIT::"Exchange Acc. G/L Journal Line", GenJnlLine);

        exit(IsCustBlockPmtTolerance(GenJnlLine."Account No."));
    end;

    local procedure IsVendBlockPmtToleranceInGenJnlLine(var GenJnlLine: Record "Gen. Journal Line"): Boolean
    begin
        CheckAccountType(GenJnlLine, GenJnlLine."Account Type"::Vendor);

        if GenJnlLine."Bal. Account Type" = GenJnlLine."Bal. Account Type"::Vendor then
            CODEUNIT.Run(CODEUNIT::"Exchange Acc. G/L Journal Line", GenJnlLine);

        exit(IsVendBlockPmtTolerance(GenJnlLine."Account No."));
    end;

    local procedure IsCustBlockPmtTolerance(AccountNo: Code[20]): Boolean
    var
        Customer: Record Customer;
    begin
        if not Customer.Get(AccountNo) then
            exit(false);
        if Customer."Block Payment Tolerance" then
            exit(true);
        exit(false);
    end;

    local procedure IsVendBlockPmtTolerance(AccountNo: Code[20]): Boolean
    var
        Vendor: Record Vendor;
    begin
        if not Vendor.Get(AccountNo) then
            exit(false);
        if Vendor."Block Payment Tolerance" then
            exit(true);
        exit(false);
    end;

    procedure CheckAccountType(GenJnlLine: Record "Gen. Journal Line"; AccountType: Enum "Gen. Journal Account Type")
    var
        DummyGenJnlLine: Record "Gen. Journal Line";
    begin
        DummyGenJnlLine."Account Type" := AccountType;
        if not (AccountType in [GenJnlLine."Account Type", GenJnlLine."Bal. Account Type"]) then
            Error(AccTypeOrBalAccTypeIsIncorrectErr, DummyGenJnlLine."Account Type");
    end;

    procedure GetAppliesToID(GenJnlLine: Record "Gen. Journal Line"): Code[50]
    begin
        if GenJnlLine."Applies-to Doc. No." = '' then
            if GenJnlLine."Applies-to ID" <> '' then
                exit(GenJnlLine."Applies-to ID");
    end;

    local procedure GetAccountName(AccountType: Enum "Payment Tolerance Account Type"; AccountNo: Code[20]): Text
    var
        Customer: Record Customer;
        Vendor: Record Vendor;
        Result: Text;
    begin
        case AccountType of
            AccountType::Customer:
                if Customer.Get(AccountNo) then
                    exit(Customer.Name);
            AccountType::Vendor:
                if Vendor.Get(AccountNo) then
                    exit(Vendor.Name);
            else begin
                OnGetAccountNameOnCaseElse(AccountType, AccountNo, Result);
                exit(Result);
            end;
        end;
    end;

    local procedure GetMinTolAmountByAbsValue(ExpectedEntryTolAmount: Decimal; MaxPmtTolAmount: Decimal) AcceptedEntryTolAmount: Decimal
    var
        Math: Codeunit Math;
        Sign: Integer;
    begin
        if ExpectedEntryTolAmount = 0 then
            Sign := 1
        else
            Sign := ExpectedEntryTolAmount / Abs(ExpectedEntryTolAmount);

        AcceptedEntryTolAmount := Sign * Math.Min(Abs(ExpectedEntryTolAmount), Abs(MaxPmtTolAmount));
    end;

    local procedure UpdateGenJournalLineAmount(NewAmount: Decimal)
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        if (GenJnlLineGlobal."Journal Template Name" = '') or (GenJnlLineGlobal."Journal Batch Name" = '') then
            exit;

        if not GenJnlLine.Get(
            GenJnlLineGlobal."Journal Template Name",
            GenJnlLineGlobal."Journal Batch Name",
            GenJnlLineGlobal."Line No.") then
            exit;

        if (GenJnlLine."Applies-to ID" = '') then
            exit;

        GenJnlLine.Amount := NewAmount;

        if GenJnlLine."Currency Code" = '' then
            GenJnlLine."Amount (LCY)" := GenJnlLine.Amount
        else
            GenJnlLine."Amount (LCY)" := Round(
                CurrExchRate.ExchangeAmtFCYToLCY(
                    GenJnlLine."Posting Date",
                    GenJnlLine."Currency Code",
                    GenJnlLine.Amount,
                    GenJnlLine."Currency Factor"));

        GenJnlLine.Validate("Amount");
        GenJnlLine.Modify(true);
    end;

    local procedure AdjustRemainingAmount(var CustLedgEntry: Record "Cust. Ledger Entry"; AppliedRemainingAmount: Decimal)
    begin
        if CustLedgEntry."Remaining Amount" <> 0 then begin
            CustLedgEntry."Remaining Amount" += AppliedRemainingAmount;

            if (CustLedgEntry."Remaining Amount" > 0) and (AppliedRemainingAmount < 0) then
                CustLedgEntry."Remaining Amount" := 0;

            if (CustLedgEntry."Remaining Amount" < 0) and (AppliedRemainingAmount > 0) then
                CustLedgEntry."Remaining Amount" := 0;
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcMaxPmtTolerance(DocumentType: Option " ",Payment,Invoice,"Credit Memo","Finance Charge Memo",Reminder,Refund; CurrencyCode: Code[10]; Amount: Decimal; AmountLCY: Decimal; Sign: Decimal; var MaxPaymentTolerance: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterDelPmtTolApllnDocNo(var GenJournalLine: Record "Gen. Journal Line"; DocumentNo: Code[20]; SuppressCommit: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPmtTolGenJnl(GenJournalLine: Record "Gen. Journal Line"; SuppressCommit: Boolean; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPmtTolPmtReconJnl(var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; SuppressCommit: Boolean; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcMaxPmtTolerance(DocumentType: Option " ",Payment,Invoice,"Credit Memo","Finance Charge Memo",Reminder,Refund; CurrencyCode: Code[10]; Amount: Decimal; AmountLCY: Decimal; Sign: Decimal; var MaxPaymentTolerance: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcRemainingPmtDisc(var NewCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var OldCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var OldCVLedgEntryBuf2: Record "CV Ledger Entry Buffer"; GLSetup: Record "General Ledger Setup"; var Handled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCallPmtDiscTolWarning(PostingDate: Date; No: Code[20]; DocNo: Code[20]; CurrencyCode: Code[10]; Amount: Decimal; AppliedAmount: Decimal; PmtDiscAmount: Decimal; var RemainingAmountTest: Boolean; AccountType: Option Customer,Vendor; var ActionType: Integer; var Result: Boolean; var IsHandled: Boolean; SuppressCommit: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckCalcPmtDisc(var NewCVLedgEntryBuf: Record "CV Ledger Entry Buffer"; var OldCVLedgEntryBuf2: Record "CV Ledger Entry Buffer"; ApplnRoundingPrecision: Decimal; CheckFilter: Boolean; CheckAmount: Boolean; var Handled: Boolean; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckPmtDiscTolCust(NewPostingdate: Date; NewDocType: Enum "Gen. Journal Document Type"; NewAmount: Decimal; OldCustLedgEntry: Record "Cust. Ledger Entry"; ApplnRoundingPrecision: Decimal; MaxPmtTolAmount: Decimal; var IsHandled: Boolean; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckPmtDiscTolVend(NewPostingdate: Date; NewDocType: Enum "Gen. Journal Document Type"; NewAmount: Decimal; OldVendLedgEntry: Record "Vendor Ledger Entry"; ApplnRoundingPrecision: Decimal; MaxPmtTolAmount: Decimal; var IsHandled: Boolean; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDelPmtTolApllnDocNo(var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRunModalPmtTolWarningCallPmtTolWarning(PostingDate: Date; No: Code[20]; DocNo: Code[20]; CurrencyCode: Code[10]; var Amount: Decimal; AppliedAmount: Decimal; AccountType: Option Customer,Vendor; var ActionType: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcCustApplnAmountOnBeforeUpdateCustAmountsForApplication(var AppliedCustLedgerEntry: Record "Cust. Ledger Entry"; var CustLedgerEntry: Record "Cust. Ledger Entry"; var AppliedCustLedgerEntryTemp: Record "Cust. Ledger Entry" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcCustApplnAmountOnAfterAppliedCustLedgEntryLoop(var AppliedCustLedgerEntry: Record "Cust. Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcVendApplnAmountOnBeforeUpdateVendAmountsForApplication(var AppliedVendorLedgerEntry: Record "Vendor Ledger Entry"; var VendoerLedgerEntry: Record "Vendor Ledger Entry"; var AppliedVendorLedgerEntryTemp: Record "Vendor Ledger Entry" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcVendApplnAmountOnAfterAppliedVendLedgEntryLoop(var AppliedVendorLedgerEntry: Record "Vendor Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcTolCustLedgEntryOnBeforeModify(var CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcTolVendLedgEntryOnBeforeModify(var VendorLedgerEntry: Record "Vendor Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcTolCustLedgEntryOnCustLedgEntryLoopIterationStart(CustLedgerEntry: Record "Cust. Ledger Entry"; GeneralLedgerSetup: Record "General Ledger Setup"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetAccountNameOnCaseElse(AccountType: Enum "Payment Tolerance Account Type"; AccountNo: Code[20]; var Result: text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPmtTolCustOnAfterSetCustEntryApplId(var CustLedgerEntry: Record "Cust. Ledger Entry"; var CustEntryApplId: code[50])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPmtTolVendOnAfterSetVendEntryApplId(var VendorLedgerEntry: Record "Vendor Ledger Entry"; var VendEntryApplId: code[50])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPutCustPmtTolAmountOnAfterAppliedCustLedgEntrySetFilters(var AppliedCustLedgerEntry: Record "Cust. Ledger Entry"; CustLedgerEntry: Record "Cust. Ledger Entry");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPutVendPmtTolAmountOnAfterVendLedgEntrySetFilters(var AppliedVendorLedgerEntry: Record "Vendor Ledger Entry"; VendorLedgerEntry: Record "Vendor Ledger Entry");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcGracePeriodCVLedgEntryOnBeforeCustLedgEntryModify(var CustLedgerEntry: Record "Cust. Ledger Entry"; PmtTolGracePeriode: DateFormula);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcGracePeriodCVLedgEntryOnBeforeVendLedgEntryModify(var VendorLedgerEntry: Record "Vendor Ledger Entry"; PmtTolGracePeriode: DateFormula);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDelTolCustLedgEntryOnBeforeModify(var CustLedgerEntry: Record "Cust. Ledger Entry");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDelTolVendLedgEntryOnBeforeModify(var VendorLedgerEntry: Record "Vendor Ledger Entry");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPmtTolGenJnlOnAfterCheckConditions(GenJournalLine: Record "Gen. Journal Line"; var SuppressCommit: Boolean; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcCustApplnAmountAfterCalcRemainingAmount(var CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcVendApplnAmountAfterCalcRemainingAmount(var VendorLedgerEntry: Record "Vendor Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnManagePaymentDiscToleranceWarningCustomerAfterCalcRemainingAmount(var CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnManagePaymentDiscToleranceWarningVendorAfterCalcRemainingAmount(var VendorLedgerEntry: Record "Vendor Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPmtTolCustBeforeCalcCustApplnAmount(var CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPmtTolVendBeforeCalcVendApplnAmount(var VendorLedgerEntry: Record "Vendor Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPutCustPmtTolAmountAfterCalcAmount(var CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPutVendPmtTolAmountAfterCalcAmount(var VendorLedgerEntry: Record "Vendor Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateCustAmountsForApplicationAfterCalcRemainingAmount(var CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateVendAmountsForApplicationAfterCalcRemainingAmount(var VendorLedgerEntry: Record "Vendor Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPmtTolCustLedgEntryOnBeforeWarning(var CustledgEntry: Record "Cust. Ledger Entry"; GLSetup: Record "General Ledger Setup"; var AppliedAmount: Decimal; var ApplyingAmount: Decimal; var AmounttoApply: Decimal; var PmtDiscAmount: Decimal; var MaxPmtTolAmount: Decimal; CustEntryApplID: Code[50]; var ApplnRoundingPrecision: Decimal; var IsHandled: Boolean; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPmtTolVendLedgEntryOnBeforeWarning(var VendledgEntry: Record "Vendor Ledger Entry"; GLSetup: Record "General Ledger Setup"; var AppliedAmount: Decimal; var ApplyingAmount: Decimal; var AmounttoApply: Decimal; var PmtDiscAmount: Decimal; var MaxPmtTolAmount: Decimal; VendEntryApplID: Code[50]; var ApplnRoundingPrecision: Decimal; var IsHandled: Boolean; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckPmtTolCust(var NewDocType: Enum "Gen. Journal Document Type"; var OldCustLedgEntry: Record "Cust. Ledger Entry"; var IsHandled: Boolean; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDelCustPmtTolAcc2(CustledgEntry: Record "Cust. Ledger Entry"; CustEntryApplID: Code[50]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetCustPositiveFilter(DocumentType: Enum "Gen. Journal Document Type"; TempAmount: Decimal; var IsHandled: Boolean; var PositiveFilter: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcGracePeriodCVLedgEntryOnAfterCustLedgEntrySetFilters(var CustLedgEntry: Record "Cust. Ledger Entry");
    begin
    end;
}

