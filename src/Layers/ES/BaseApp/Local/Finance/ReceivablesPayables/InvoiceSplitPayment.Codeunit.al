// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.ReceivablesPayables;

using Microsoft.Bank.BankAccount;
using Microsoft.Bank.DirectDebit;
using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Posting;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.PaymentTerms;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Setup;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.Receivables;
using Microsoft.Sales.Setup;

codeunit 7000005 "Invoice-Split Payment"
{

    trigger OnRun()
    begin
    end;

    var
        PaymentMethod: Record "Payment Method";
        PaymentTerms: Record "Payment Terms";
        GenJnlLine: Record "Gen. Journal Line";
        GenJnlLine2: Record "Gen. Journal Line";
        GLSetup: Record "General Ledger Setup";
        SalesSetup: Record "Sales & Receivables Setup";
        PurchSetup: Record "Purchases & Payables Setup";
        Currency: Record Currency;
        CurrencyExchRate: Record "Currency Exchange Rate";
        Installment: Record Installment;
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
        DueDateAdjust: Codeunit "Due Date-Adjust";
        CurrencyFactor: Decimal;
        VATAmountLCY: Decimal;
        TotalAmount: Decimal;
        TotalAmountLCY: Decimal;
        RemainingAmount: Decimal;
        RemainingAmountLCY: Decimal;
        NextDueDate: Date;
        CurrDocNo: Integer;
        TotalPerc: Decimal;
        ExistsVATNoReal: Boolean;
        ErrorMessage: Boolean;
        Text001: Label 'Sales %1 no. %2 cannot be posted, because the due date field for one or more installments is more than the legal limit of %3 days after the document date %4 for the original document.';
        Text002: Label 'Purchase %1 no. %2 cannot be posted, because the due date field for one or more installments is more than the legal limit of %3 days after the document date %4 for the original document.';
        Text1100000: Label 'You cannot select a bill-based %1 for a Credit memo.';
        Text1100001: Label '%1 must be 1 if %2 is True in %3';
        Text1100002: Label 'Transfer of Invoice %1 into bills';
        Text1100003: Label 'Unrealized VAT Type must be "Percentage" in VAT Posting Setup.';
        Text1100004: Label 'Bill %1/%2';
        Text1100005: Label 'The sum of %1 cannot be greater then 100 in the installments for %2 %3.';

    procedure SplitSalesInv(var SalesHeader: Record "Sales Header"; var CustLedgEntry: Record "Cust. Ledger Entry"; var Window: Dialog; SourceCode: Code[10]; GenJnlLineExtDocNo: Code[35]; GenJnlLineDocNo: Code[20]; VATAmount: Decimal; HideProgressWindow: Boolean)
    var
        VATPostingSetup: Record "VAT Posting Setup";
        SepaDirectDebitMandate: Record "SEPA Direct Debit Mandate";
        BillNo: Integer;
        IsHandled: Boolean;
    begin
        if not PaymentMethod.Get(SalesHeader."Payment Method Code") then
            exit;
        if (not PaymentMethod."Create Bills") and (not PaymentMethod."Invoices to Cartera") then
            exit;
        IsHandled := false;
        OnSplitSalesInvOnBeforeCheckPaymentMethod(SalesHeader, PaymentMethod, PaymentTerms, IsHandled);
        if not IsHandled then
            if PaymentMethod."Create Bills" and (SalesHeader."Document Type" = SalesHeader."Document Type"::"Credit Memo") then
                Error(Text1100000, SalesHeader.FieldCaption("Payment Method Code"));

        if SalesHeader."Currency Code" = '' then
            CurrencyFactor := 1
        else
            CurrencyFactor := SalesHeader."Currency Factor";

        GLSetup.Get();
        SalesSetup.GetRecordOnce();
        SalesHeader.TestField("Payment Terms Code");
        PaymentTerms.Get(SalesHeader."Payment Terms Code");
        PaymentTerms.CalcFields("No. of Installments");
        if PaymentTerms."No. of Installments" = 0 then
            PaymentTerms."No. of Installments" := 1;
        IsHandled := false;
        OnSplitSalesInvOnBeforeCheckPaymentMethod(SalesHeader, PaymentMethod, PaymentTerms, IsHandled);
        if not IsHandled then
            if PaymentMethod."Invoices to Cartera" and (PaymentTerms."No. of Installments" > 1) then
                Error(
                  Text1100001,
                  PaymentTerms.FieldCaption("No. of Installments"),
                  PaymentMethod.FieldCaption("Invoices to Cartera"),
                  PaymentMethod.TableCaption());
        CustLedgEntry.Find('+');
        CustLedgEntry.CalcFields("Remaining Amount", "Remaining Amt. (LCY)");
        if CustLedgEntry."Remaining Amount" = 0 then
            exit;

        TotalAmount := CustLedgEntry."Remaining Amount";
        TotalAmountLCY := CustLedgEntry."Remaining Amt. (LCY)";
        RemainingAmount := TotalAmount;
        RemainingAmountLCY := TotalAmountLCY;
        // close invoice entry
        if PaymentMethod."Create Bills" then begin
            GenJnlLine.Init();
            GenJnlLine."Posting Date" := SalesHeader."Posting Date";
            GenJnlLine."Document Date" := SalesHeader."Document Date";
            GenJnlLine.Validate("Account Type", GenJnlLine."Account Type"::Customer);
            GenJnlLine.Validate("Account No.", SalesHeader."Bill-to Customer No.");
            GenJnlLine."Document Type" := GenJnlLine."Document Type"::" ";
            GenJnlLine."Document No." := GenJnlLineDocNo;
            GenJnlLine.Description := CopyStr(StrSubstNo(Text1100002, GenJnlLineDocNo), 1, MaxStrLen(GenJnlLine.Description));
            GenJnlLine."Shortcut Dimension 1 Code" := SalesHeader."Shortcut Dimension 1 Code";
            GenJnlLine."Shortcut Dimension 2 Code" := SalesHeader."Shortcut Dimension 2 Code";
            GenJnlLine."Dimension Set ID" := SalesHeader."Dimension Set ID";
            GenJnlLine."Direct Debit Mandate ID" := SalesHeader."Direct Debit Mandate ID";
            GenJnlLine."Reason Code" := SalesHeader."Reason Code";
            GenJnlLine."External Document No." := GenJnlLineExtDocNo;
            GenJnlLine.Validate("Currency Code", SalesHeader."Currency Code");
            GenJnlLine.Amount := -TotalAmount;
            GenJnlLine."Amount (LCY)" := -TotalAmountLCY;
            GenJnlLine."System-Created Entry" := true;
            GenJnlLine."On Hold" := SalesHeader."On Hold";
            GenJnlLine."Applies-to Doc. Type" := GenJnlLine."Applies-to Doc. Type"::Invoice;
            GenJnlLine."Applies-to Doc. No." := GenJnlLineDocNo;
            GenJnlLine."Source Code" := SourceCode;
            GenJnlLine."Currency Factor" := CurrencyFactor;
            GenJnlLine."Payment Terms Code" := SalesHeader."Payment Terms Code";
            GenJnlLine."Payment Method Code" := SalesHeader."Payment Method Code";
            if SepaDirectDebitMandate.Get(SalesHeader."Direct Debit Mandate ID") then
                GenJnlLine."Recipient Bank Account" := SepaDirectDebitMandate."Customer Bank Account Code"
            else
                GenJnlLine."Recipient Bank Account" := SalesHeader."Cust. Bank Acc. Code";
            GenJnlLine."Salespers./Purch. Code" := SalesHeader."Salesperson Code";

            if GLSetup."Unrealized VAT" then begin
                FindCustVATSetup(VATPostingSetup, SalesHeader);
                if ErrorMessage then
                    Error(Text1100003);
            end;

            OnBeforeSplitSalesInvCloseEntry(GenJnlLine, SalesHeader);

            if GLSetup."Unrealized VAT" and ExistsVATNoReal then
                GenJnlLine2.Copy(GenJnlLine)
            else
                GenJnlPostLine.Run(GenJnlLine);
        end;
        // create bills
        if SalesHeader."Currency Code" = '' then begin
            Currency."Invoice Rounding Precision" := GLSetup."Inv. Rounding Precision (LCY)";
            Currency."Invoice Rounding Type" := GLSetup."Inv. Rounding Type (LCY)";
            Currency."Amount Rounding Precision" := GLSetup."Amount Rounding Precision";
            if SalesSetup."Invoice Rounding" then
                GLSetup.TestField("Inv. Rounding Precision (LCY)")
            else
                GLSetup.TestField("Amount Rounding Precision");
        end else begin
            Currency.Get(SalesHeader."Currency Code");
            if SalesSetup."Invoice Rounding" then
                Currency.TestField("Invoice Rounding Precision")
            else
                Currency.TestField("Amount Rounding Precision");
        end;
        TotalAmount := RoundReceivableAmt(TotalAmount);

        VATAmountLCY := RoundReceivableAmtLCY(VATAmount / CurrencyFactor);

        if PaymentTerms."No. of Installments" > 0 then begin
            Installment.SetRange("Payment Terms Code", PaymentTerms.Code);
            if Installment.Find('-') then;
        end;

        NextDueDate := SalesHeader."Due Date";

        GenJnlLine.Init();
        GenJnlLine."Posting Date" := SalesHeader."Posting Date";
        GenJnlLine."Document Date" := SalesHeader."Document Date";
        GenJnlLine.Validate("Account Type", GenJnlLine."Account Type"::Customer);
        GenJnlLine.Validate("Account No.", SalesHeader."Bill-to Customer No.");
        GenJnlLine."Document Type" := GenJnlLine."Document Type"::Bill;
        GenJnlLine."Document No." := GenJnlLineDocNo;
        GenJnlLine."Shortcut Dimension 1 Code" := SalesHeader."Shortcut Dimension 1 Code";
        GenJnlLine."Shortcut Dimension 2 Code" := SalesHeader."Shortcut Dimension 2 Code";
        GenJnlLine."Dimension Set ID" := SalesHeader."Dimension Set ID";
        GenJnlLine."Direct Debit Mandate ID" := SalesHeader."Direct Debit Mandate ID";
        GenJnlLine."Reason Code" := SalesHeader."Reason Code";
        GenJnlLine."External Document No." := GenJnlLineExtDocNo;
        GenJnlLine.Validate("Currency Code", SalesHeader."Currency Code");
        GenJnlLine."System-Created Entry" := true;
        GenJnlLine."On Hold" := SalesHeader."On Hold";
        GenJnlLine."Source Code" := SourceCode;
        GenJnlLine."Currency Factor" := CurrencyFactor;
        GenJnlLine."Payment Terms Code" := SalesHeader."Payment Terms Code";
        GenJnlLine."Payment Method Code" := SalesHeader."Payment Method Code";
        if SepaDirectDebitMandate.Get(SalesHeader."Direct Debit Mandate ID") then
            GenJnlLine."Recipient Bank Account" := SepaDirectDebitMandate."Customer Bank Account Code"
        else
            GenJnlLine."Recipient Bank Account" := SalesHeader."Cust. Bank Acc. Code";
        GenJnlLine."Salespers./Purch. Code" := SalesHeader."Salesperson Code";

        CurrDocNo := 1;
        repeat
            GenJnlLine."Due Date" := NextDueDate;
            CheckSalesDueDate(SalesHeader, GenJnlLine."Due Date", PaymentTerms."Max. No. of Days till Due Date");
            if not SalesHeader."Due Date Modified" then
                DueDateAdjust.SalesAdjustDueDate(
                  GenJnlLine."Due Date", SalesHeader."Document Date", PaymentTerms.CalculateMaxDueDate(SalesHeader."Document Date"), SalesHeader."Bill-to Customer No.");
            NextDueDate := GenJnlLine."Due Date";
            if CurrDocNo < PaymentTerms."No. of Installments" then begin
                Installment.TestField("% of Total");
                if CurrDocNo = 1 then begin
                    TotalPerc := Installment."% of Total";
                    case PaymentTerms."VAT distribution" of
                        PaymentTerms."VAT distribution"::"First Installment":
                            begin
                                GenJnlLine.Amount := RoundReceivableAmt((TotalAmount - VATAmount) * Installment."% of Total" / 100 + VATAmount);
                                GenJnlLine."Amount (LCY)" :=
                                  RoundReceivableAmtLCY(
                                    CurrencyExchRate.ExchangeAmtFCYToLCY(SalesHeader."Posting Date", Currency.Code, GenJnlLine.Amount, CurrencyFactor));
                            end;
                        PaymentTerms."VAT distribution"::"Last Installment":
                            begin
                                GenJnlLine.Amount := RoundReceivableAmt((TotalAmount - VATAmount) * Installment."% of Total" / 100);
                                GenJnlLine."Amount (LCY)" :=
                                  RoundReceivableAmtLCY(
                                    CurrencyExchRate.ExchangeAmtFCYToLCY(SalesHeader."Posting Date", Currency.Code, GenJnlLine.Amount, CurrencyFactor));
                            end;
                        PaymentTerms."VAT distribution"::Proportional:
                            begin
                                GenJnlLine.Amount := RoundReceivableAmt(TotalAmount * Installment."% of Total" / 100);
                                GenJnlLine."Amount (LCY)" :=
                                  RoundReceivableAmtLCY(
                                    CurrencyExchRate.ExchangeAmtFCYToLCY(SalesHeader."Posting Date", Currency.Code, GenJnlLine.Amount, CurrencyFactor));
                            end;
                    end;
                end else begin
                    TotalPerc := TotalPerc + Installment."% of Total";
                    if TotalPerc >= 100 then
                        Error(
                          Text1100005,
                          Installment.FieldCaption("% of Total"),
                          PaymentTerms.TableCaption(),
                          PaymentTerms.Code);
                    case PaymentTerms."VAT distribution" of
                        PaymentTerms."VAT distribution"::"First Installment",
                        PaymentTerms."VAT distribution"::"Last Installment":
                            begin
                                GenJnlLine.Amount := RoundReceivableAmt((TotalAmount - VATAmount) * Installment."% of Total" / 100);
                                GenJnlLine."Amount (LCY)" :=
                                  RoundReceivableAmtLCY(
                                    CurrencyExchRate.ExchangeAmtFCYToLCY(SalesHeader."Posting Date", Currency.Code, GenJnlLine.Amount, CurrencyFactor));
                            end;
                        PaymentTerms."VAT distribution"::Proportional:
                            begin
                                GenJnlLine.Amount := RoundReceivableAmt(TotalAmount * Installment."% of Total" / 100);
                                GenJnlLine."Amount (LCY)" :=
                                  RoundReceivableAmtLCY(
                                    CurrencyExchRate.ExchangeAmtFCYToLCY(SalesHeader."Posting Date", Currency.Code, GenJnlLine.Amount, CurrencyFactor));
                            end;
                    end;
                end;
                RemainingAmount := RemainingAmount - GenJnlLine.Amount;
                RemainingAmountLCY := RemainingAmountLCY - GenJnlLine."Amount (LCY)";
                OnAfterSplitSalesInvCalculateAmounts(GenJnlLine, SalesHeader, RemainingAmount, RemainingAmountLCY, Installment, CurrDocNo, PaymentTerms);
                Installment.TestField("Gap between Installments");
                NextDueDate := CalculateDate(Installment."Gap between Installments", NextDueDate);
                Installment.Next();
            end else begin
                GenJnlLine.Amount := RemainingAmount;
                GenJnlLine."Amount (LCY)" := RemainingAmountLCY;
            end;

            OnBeforeSplitSalesInvCreateBills(GenJnlLine, SalesHeader, Installment, CurrDocNo, PaymentTerms, RemainingAmount, RemainingAmountLCY);

            if PaymentMethod."Create Bills" and ((GenJnlLine.Amount <> 0) or (GenJnlLine."Amount (LCY)" <> 0)) then begin
                BillNo += 1;
                GenJnlLine."Bill No." := Format(BillNo);
                GenJnlLine.Description :=
                  CopyStr(
                    StrSubstNo(Text1100004, GenJnlLineDocNo, BillNo),
                    1,
                    MaxStrLen(GenJnlLine.Description));
                OnSplitSalesInvOnCreateBillsOnBeforePostGenJnlLine(GenJnlLine, SalesHeader);
                GenJnlPostLine.Run(GenJnlLine);
            end;
            CurrDocNo += 1;
        until (CurrDocNo > PaymentTerms."No. of Installments") or (RemainingAmount = 0);

        if GLSetup."Unrealized VAT" and ExistsVATNoReal then
            GenJnlPostLine.Run(GenJnlLine2);
    end;

    procedure SplitPurchInv(var PurchHeader: Record "Purchase Header"; var VendLedgEntry: Record "Vendor Ledger Entry"; var Window: Dialog; SourceCode: Code[10]; GenJnlLineExtDocNo: Code[35]; GenJnlLineDocNo: Code[20]; VATAmount: Decimal)
    var
        VATPostingSetup: Record "VAT Posting Setup";
        BillNo: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSplitPurchInv(PurchHeader, VendLedgEntry, IsHandled);
        if IsHandled then
            exit;

        if not PaymentMethod.Get(PurchHeader."Payment Method Code") then
            exit;
        if (not PaymentMethod."Create Bills") and (not PaymentMethod."Invoices to Cartera") then
            exit;
        IsHandled := false;
        OnSplitPurchInvOnBeforeCheckPaymentMethod(PurchHeader, PaymentMethod, PaymentTerms, IsHandled);
        if not IsHandled then
            if PaymentMethod."Create Bills" and (PurchHeader."Document Type" = PurchHeader."Document Type"::"Credit Memo") then
                Error(
                  Text1100000,
                  PurchHeader.FieldCaption("Payment Method Code"));

        if PurchHeader."Currency Code" = '' then
            CurrencyFactor := 1
        else
            CurrencyFactor := PurchHeader."Currency Factor";

        GLSetup.Get();
        PurchSetup.Get();
        PurchHeader.TestField("Payment Terms Code");
        PaymentTerms.Get(PurchHeader."Payment Terms Code");
        PaymentTerms.CalcFields("No. of Installments");
        if PaymentTerms."No. of Installments" = 0 then
            PaymentTerms."No. of Installments" := 1;
        IsHandled := false;
        OnSplitPurchInvOnBeforeCheckPaymentMethod(PurchHeader, PaymentMethod, PaymentTerms, IsHandled);
        if not IsHandled then
            if PaymentMethod."Invoices to Cartera" and (PaymentTerms."No. of Installments" > 1) then
                Error(
                  Text1100001,
                  PaymentTerms.FieldCaption("No. of Installments"),
                  PaymentMethod.FieldCaption("Invoices to Cartera"),
                  PaymentMethod.TableCaption());
        VendLedgEntry.Find('+');
        VendLedgEntry.CalcFields("Remaining Amount", "Remaining Amt. (LCY)");
        if VendLedgEntry."Remaining Amount" = 0 then
            exit;
        TotalAmount := VendLedgEntry."Remaining Amount";
        TotalAmountLCY := VendLedgEntry."Remaining Amt. (LCY)";
        RemainingAmount := VendLedgEntry."Remaining Amount";
        RemainingAmountLCY := VendLedgEntry."Remaining Amt. (LCY)";
        // close invoice entry
        if PaymentMethod."Create Bills" then begin
            GenJnlLine.Init();
            GenJnlLine."Posting Date" := PurchHeader."Posting Date";
            GenJnlLine."Document Date" := PurchHeader."Document Date";
            GenJnlLine.Validate("Account Type", GenJnlLine."Account Type"::Vendor);
            GenJnlLine.Validate("Account No.", PurchHeader."Pay-to Vendor No.");
            GenJnlLine."Document Type" := GenJnlLine."Document Type"::" ";
            GenJnlLine."Document No." := GenJnlLineDocNo;
            GenJnlLine.Description := CopyStr(StrSubstNo(Text1100002, GenJnlLineDocNo), 1, MaxStrLen(GenJnlLine.Description));
            GenJnlLine."Shortcut Dimension 1 Code" := PurchHeader."Shortcut Dimension 1 Code";
            GenJnlLine."Shortcut Dimension 2 Code" := PurchHeader."Shortcut Dimension 2 Code";
            GenJnlLine."Dimension Set ID" := PurchHeader."Dimension Set ID";
            GenJnlLine."Reason Code" := PurchHeader."Reason Code";
            GenJnlLine."External Document No." := GenJnlLineExtDocNo;
            GenJnlLine.Validate("Currency Code", PurchHeader."Currency Code");
            GenJnlLine."Posting Group" := PurchHeader."Vendor Posting Group";
            GenJnlLine.Amount := -TotalAmount;
            GenJnlLine."Amount (LCY)" := -TotalAmountLCY;
            GenJnlLine."System-Created Entry" := true;
            GenJnlLine."On Hold" := PurchHeader."On Hold";
            GenJnlLine."Applies-to Doc. Type" := GenJnlLine."Applies-to Doc. Type"::Invoice;
            GenJnlLine."Applies-to Doc. No." := GenJnlLineDocNo;
            GenJnlLine."Source Code" := SourceCode;
            GenJnlLine."Currency Factor" := CurrencyFactor;
            GenJnlLine."Payment Terms Code" := PurchHeader."Payment Terms Code";
            GenJnlLine."Payment Method Code" := PurchHeader."Payment Method Code";
            GenJnlLine."Recipient Bank Account" := PurchHeader."Vendor Bank Acc. Code";
            GenJnlLine."Salespers./Purch. Code" := PurchHeader."Purchaser Code";

            if GLSetup."Unrealized VAT" then begin
                FindVendVATSetup(VATPostingSetup, PurchHeader);
                if ErrorMessage then
                    Error(Text1100003);
            end;

            OnBeforeSplitPurchInvCloseEntry(GenJnlLine, PurchHeader);

            if GLSetup."Unrealized VAT" and ExistsVATNoReal then
                GenJnlLine2.Copy(GenJnlLine)
            else
                GenJnlPostLine.Run(GenJnlLine);
        end;
        // create bills
        if PurchHeader."Currency Code" = '' then begin
            Currency."Invoice Rounding Precision" := GLSetup."Inv. Rounding Precision (LCY)";
            Currency."Invoice Rounding Type" := GLSetup."Inv. Rounding Type (LCY)";
            Currency."Amount Rounding Precision" := GLSetup."Amount Rounding Precision";
            if PurchSetup."Invoice Rounding" then
                GLSetup.TestField("Inv. Rounding Precision (LCY)")
            else
                GLSetup.TestField("Amount Rounding Precision");
        end else begin
            Currency.Get(PurchHeader."Currency Code");
            if SalesSetup."Invoice Rounding" then
                Currency.TestField("Invoice Rounding Precision")
            else
                Currency.TestField("Amount Rounding Precision");
        end;
        TotalAmount := RoundPayableAmt(TotalAmount);

        VATAmountLCY := RoundPayableAmtLCY(VATAmount / CurrencyFactor);

        if PaymentTerms."No. of Installments" > 0 then begin
            Installment.SetRange("Payment Terms Code", PaymentTerms.Code);
            if Installment.Find('-') then;
        end;

        NextDueDate := PurchHeader."Due Date";

        GenJnlLine.Init();
        GenJnlLine."Posting Date" := PurchHeader."Posting Date";
        GenJnlLine."Document Date" := PurchHeader."Document Date";
        GenJnlLine.Validate("Account Type", GenJnlLine."Account Type"::Vendor);
        GenJnlLine.Validate("Account No.", PurchHeader."Pay-to Vendor No.");
        GenJnlLine."Document Type" := GenJnlLine."Document Type"::Bill;
        GenJnlLine."Document No." := GenJnlLineDocNo;
        GenJnlLine."Shortcut Dimension 1 Code" := PurchHeader."Shortcut Dimension 1 Code";
        GenJnlLine."Shortcut Dimension 2 Code" := PurchHeader."Shortcut Dimension 2 Code";
        GenJnlLine."Dimension Set ID" := PurchHeader."Dimension Set ID";
        GenJnlLine."Reason Code" := PurchHeader."Reason Code";
        GenJnlLine."External Document No." := GenJnlLineExtDocNo;
        GenJnlLine.Validate("Currency Code", PurchHeader."Currency Code");
        GenJnlLine."Posting Group" := PurchHeader."Vendor Posting Group";
        GenJnlLine."System-Created Entry" := true;
        GenJnlLine."On Hold" := PurchHeader."On Hold";
        GenJnlLine."Source Code" := SourceCode;
        GenJnlLine."Currency Factor" := CurrencyFactor;
        GenJnlLine."Payment Terms Code" := PurchHeader."Payment Terms Code";
        GenJnlLine."Payment Method Code" := PurchHeader."Payment Method Code";
        GenJnlLine."Recipient Bank Account" := PurchHeader."Vendor Bank Acc. Code";
        GenJnlLine."Salespers./Purch. Code" := PurchHeader."Purchaser Code";

        CurrDocNo := 1;
        repeat
            GenJnlLine."Due Date" := NextDueDate;
            CheckPurchDueDate(PurchHeader, GenJnlLine."Due Date", PaymentTerms."Max. No. of Days till Due Date");
            if not PurchHeader."Due Date Modified" then
                DueDateAdjust.PurchAdjustDueDate(
                  GenJnlLine."Due Date", PurchHeader."Document Date", PaymentTerms.CalculateMaxDueDate(PurchHeader."Document Date"), PurchHeader."Pay-to Vendor No.");
            NextDueDate := GenJnlLine."Due Date";
            if CurrDocNo < PaymentTerms."No. of Installments" then begin
                Installment.TestField("% of Total");
                OnBeforeSplitPurchInvCalculateAmounts(GenJnlLine, PurchHeader, TotalAmount, VATAmount, TotalAmountLCY, VATAmountLCY);
                if CurrDocNo = 1 then begin
                    TotalPerc := Installment."% of Total";
                    case PaymentTerms."VAT distribution" of
                        PaymentTerms."VAT distribution"::"First Installment":
                            begin
                                GenJnlLine.Amount := RoundPayableAmt((TotalAmount - VATAmount) * Installment."% of Total" / 100 + VATAmount);
                                GenJnlLine."Amount (LCY)" :=
                                  RoundPayableAmtLCY(
                                    CurrencyExchRate.ExchangeAmtFCYToLCY(PurchHeader."Posting Date", Currency.Code, GenJnlLine.Amount, CurrencyFactor));
                            end;
                        PaymentTerms."VAT distribution"::"Last Installment":
                            begin
                                GenJnlLine.Amount := RoundPayableAmt((TotalAmount - VATAmount) * Installment."% of Total" / 100);
                                GenJnlLine."Amount (LCY)" :=
                                  RoundPayableAmtLCY(
                                    CurrencyExchRate.ExchangeAmtFCYToLCY(PurchHeader."Posting Date", Currency.Code, GenJnlLine.Amount, CurrencyFactor));
                            end;
                        PaymentTerms."VAT distribution"::Proportional:
                            begin
                                GenJnlLine.Amount := RoundPayableAmt(TotalAmount * Installment."% of Total" / 100);
                                GenJnlLine."Amount (LCY)" :=
                                  RoundPayableAmtLCY(
                                    CurrencyExchRate.ExchangeAmtFCYToLCY(PurchHeader."Posting Date", Currency.Code, GenJnlLine.Amount, CurrencyFactor));
                            end;
                    end;
                end else begin
                    TotalPerc := TotalPerc + Installment."% of Total";
                    if TotalPerc >= 100 then
                        Error(
                          Text1100005,
                          Installment.FieldCaption("% of Total"),
                          PaymentTerms.TableCaption(),
                          PaymentTerms.Code);
                    case PaymentTerms."VAT distribution" of
                        PaymentTerms."VAT distribution"::"First Installment",
                        PaymentTerms."VAT distribution"::"Last Installment":
                            begin
                                GenJnlLine.Amount := RoundPayableAmt((TotalAmount - VATAmount) * Installment."% of Total" / 100);
                                GenJnlLine."Amount (LCY)" := RoundPayableAmtLCY(
                                    CurrencyExchRate.ExchangeAmtFCYToLCY(PurchHeader."Posting Date", Currency.Code, GenJnlLine.Amount, CurrencyFactor));
                            end;
                        PaymentTerms."VAT distribution"::Proportional:
                            begin
                                GenJnlLine.Amount := RoundPayableAmt(TotalAmount * Installment."% of Total" / 100);
                                GenJnlLine."Amount (LCY)" := RoundPayableAmtLCY(
                                    CurrencyExchRate.ExchangeAmtFCYToLCY(PurchHeader."Posting Date", Currency.Code, GenJnlLine.Amount, CurrencyFactor));
                            end;
                    end;
                end;
                RemainingAmount := RemainingAmount - GenJnlLine.Amount;
                RemainingAmountLCY := RemainingAmountLCY - GenJnlLine."Amount (LCY)";
                OnAfterSplitPurchInvCalculateAmounts(GenJnlLine, PurchHeader, RemainingAmount, RemainingAmountLCY);
                Installment.TestField("Gap between Installments");
                NextDueDate := CalculateDate(Installment."Gap between Installments", NextDueDate);
                Installment.Next();
            end else begin
                GenJnlLine.Amount := RemainingAmount;
                GenJnlLine."Amount (LCY)" := RemainingAmountLCY;
            end;

            OnBeforeSplitPurchInvCreateBills(GenJnlLine, PurchHeader, Installment, CurrDocNo, PaymentTerms, RemainingAmount, RemainingAmountLCY);

            if PaymentMethod."Create Bills" and ((GenJnlLine.Amount <> 0) or (GenJnlLine."Amount (LCY)" <> 0)) then begin
                BillNo += 1;
                GenJnlLine."Bill No." := Format(BillNo);
                GenJnlLine.Description :=
                  CopyStr(
                    StrSubstNo(Text1100004, GenJnlLineDocNo, BillNo),
                    1,
                    MaxStrLen(GenJnlLine.Description));
                OnSplitPurchInvOnCreateBillsOnBeforePostGenJnlLine(GenJnlLine, PurchHeader);
                GenJnlPostLine.Run(GenJnlLine);
            end;
            CurrDocNo += 1;
        until (CurrDocNo > PaymentTerms."No. of Installments") or (RemainingAmount = 0);

        if GLSetup."Unrealized VAT" and ExistsVATNoReal then
            GenJnlPostLine.Run(GenJnlLine2);
    end;

    procedure RoundReceivableAmt(Amount: Decimal): Decimal
    begin
        SalesSetup.GetRecordOnce();
        if SalesSetup."Invoice Rounding" then
            Amount := Round(Amount, Currency."Invoice Rounding Precision", SelectStr(Currency."Invoice Rounding Type" + 1, '=,>,<'))
        else
            Amount := Round(Amount, Currency."Amount Rounding Precision");

        exit(Amount);
    end;

    procedure RoundReceivableAmtLCY(Amount: Decimal): Decimal
    begin
        GLSetup.GetRecordOnce();
        SalesSetup.GetRecordOnce();
        if SalesSetup."Invoice Rounding" then
            Amount := Round(Amount, GLSetup."Inv. Rounding Precision (LCY)", SelectStr(GLSetup."Inv. Rounding Type (LCY)" + 1, '=,>,<'))
        else
            Amount := Round(Amount, GLSetup."Amount Rounding Precision");

        exit(Amount);
    end;

    procedure RoundPayableAmt(Amount: Decimal): Decimal
    begin
        SalesSetup.GetRecordOnce();
        if SalesSetup."Invoice Rounding" then
            Amount := Round(Amount, Currency."Invoice Rounding Precision", SelectStr(Currency."Invoice Rounding Type" + 1, '=,>,<'))
        else
            Amount := Round(Amount, Currency."Amount Rounding Precision");

        exit(Amount);
    end;

    procedure RoundPayableAmtLCY(Amount: Decimal): Decimal
    begin
        SalesSetup.GetRecordOnce();
        if SalesSetup."Invoice Rounding" then
            Amount := Round(Amount, GLSetup."Inv. Rounding Precision (LCY)", SelectStr(GLSetup."Inv. Rounding Type (LCY)" + 1, '=,>,<'))
        else
            Amount := Round(Amount, GLSetup."Amount Rounding Precision");

        exit(Amount);
    end;

    procedure FindCustVATSetup(var VATSetup: Record "VAT Posting Setup"; SalesHeader2: Record "Sales Header")
    var
        Customer: Record Customer;
        SalesLine2: Record "Sales Line";
        PostingGroup: Code[20];
    begin
        Customer.Get(SalesHeader2."Bill-to Customer No.");

        VATSetup.SetCurrentKey("VAT Bus. Posting Group", "VAT Prod. Posting Group");
        VATSetup.SetRange("VAT Bus. Posting Group", Customer."VAT Bus. Posting Group");

        SalesLine2.SetCurrentKey("Document Type", "Document No.", "Line No.");
        SalesLine2.SetRange("Document Type", SalesHeader2."Document Type");
        SalesLine2.SetRange("Document No.", SalesHeader2."No.");
        SalesLine2.Find('-');

        repeat
            case SalesLine2.Type of
                SalesLine2.Type::Item:
                    begin
                        PostingGroup := SalesLine2."VAT Prod. Posting Group";
                        VATSetup.SetRange("VAT Prod. Posting Group", PostingGroup);
                        if VATSetup.Find('-') and (VATSetup."Unrealized VAT Type" >= VATSetup."Unrealized VAT Type"::Percentage) then
                            if VATSetup."Unrealized VAT Type" > VATSetup."Unrealized VAT Type"::Percentage then
                                ErrorMessage := true
                            else
                                ExistsVATNoReal := true;
                    end;
                SalesLine2.Type::Resource:
                    begin
                        PostingGroup := SalesLine2."VAT Prod. Posting Group";
                        VATSetup.SetRange("VAT Prod. Posting Group", PostingGroup);
                        if VATSetup.Find('-') and (VATSetup."Unrealized VAT Type" >= VATSetup."Unrealized VAT Type"::Percentage) then
                            if VATSetup."Unrealized VAT Type" > VATSetup."Unrealized VAT Type"::Percentage then
                                ErrorMessage := true
                            else
                                ExistsVATNoReal := true;
                    end;
                SalesLine2.Type::"G/L Account":
                    begin
                        PostingGroup := SalesLine2."VAT Prod. Posting Group";
                        VATSetup.SetRange("VAT Prod. Posting Group", PostingGroup);
                        if VATSetup.Find('-') and (VATSetup."Unrealized VAT Type" >= VATSetup."Unrealized VAT Type"::Percentage) then
                            if VATSetup."Unrealized VAT Type" > VATSetup."Unrealized VAT Type"::Percentage then
                                ErrorMessage := true
                            else
                                ExistsVATNoReal := true;
                    end;
            end;
        until SalesLine2.Next() = 0;
    end;

    procedure FindVendVATSetup(var VATSetup: Record "VAT Posting Setup"; PurchHeader2: Record "Purchase Header")
    var
        PurchLine2: Record "Purchase Line";
        PostingGroup: Code[20];
    begin
        VATSetup.SetCurrentKey("VAT Bus. Posting Group", "VAT Prod. Posting Group");
        VATSetup.SetRange("VAT Bus. Posting Group", PurchHeader2."VAT Bus. Posting Group");

        PurchLine2.SetCurrentKey("Document Type", "Document No.", "Line No.");
        PurchLine2.SetRange("Document Type", PurchHeader2."Document Type");
        PurchLine2.SetRange("Document No.", PurchHeader2."No.");
        PurchLine2.Find('-');

        repeat
            case PurchLine2.Type of
                PurchLine2.Type::Item:
                    begin
                        PostingGroup := PurchLine2."VAT Prod. Posting Group";
                        VATSetup.SetRange("VAT Prod. Posting Group", PostingGroup);
                        if VATSetup.Find('-') and (VATSetup."Unrealized VAT Type" >= VATSetup."Unrealized VAT Type"::Percentage) then
                            if VATSetup."Unrealized VAT Type" > VATSetup."Unrealized VAT Type"::Percentage then
                                ErrorMessage := true
                            else
                                ExistsVATNoReal := true;
                    end;
                PurchLine2.Type::"G/L Account":
                    begin
                        PostingGroup := PurchLine2."VAT Prod. Posting Group";
                        VATSetup.SetRange("VAT Prod. Posting Group", PostingGroup);
                        if VATSetup.Find('-') and (VATSetup."Unrealized VAT Type" >= VATSetup."Unrealized VAT Type"::Percentage) then
                            if VATSetup."Unrealized VAT Type" > VATSetup."Unrealized VAT Type"::Percentage then
                                ErrorMessage := true
                            else
                                ExistsVATNoReal := true;
                    end;
            end;
        until PurchLine2.Next() = 0;
    end;

#if not CLEAN27
    [Obsolete('Moved to codeunit ServInvoiceSplitPayment', '27.0')]
    procedure SplitServiceInv(var ServiceHeader: Record Microsoft.Service.Document."Service Header"; var CustLedgEntry: Record "Cust. Ledger Entry"; var Window: Dialog; SourceCode: Code[10]; GenJnlLineExtDocNo: Code[35]; GenJnlLineDocNo: Code[20]; VATAmount: Decimal)
    var
        ServInvoiceSplitPayment: Codeunit "Serv. Invoice-Split Payment";
    begin
        ServInvoiceSplitPayment.SplitServiceInvoice(ServiceHeader, CustLedgEntry, Window, SourceCode, GenJnlLineExtDocNo, GenJnlLineDocNo, VATAmount);
    end;
#endif

#if not CLEAN27
    [Obsolete('Moved to codeunit ServInvoiceSplitPayment', '27.0')]
    procedure FindCustVATSetupServ(var VATSetup: Record "VAT Posting Setup"; ServiceHeader2: Record Microsoft.Service.Document."Service Header")
    var
        ServInvoiceSplitPayment: Codeunit "Serv. Invoice-Split Payment";
    begin
        ServInvoiceSplitPayment.FindCustVATSetupServ(VATSetup, ServiceHeader2, ErrorMessage, ExistsVATNoReal);
    end;
#endif

    procedure CalculateDate(DateFormulaText: Code[20]; DueDate: Date): Date
    var
        DateFormula: DateFormula;
    begin
        Evaluate(DateFormula, DateFormulaText);
        exit(CalcDate(DateFormula, DueDate));
    end;

    procedure CheckDueDate(NewDueDate: Date; InitialDocumentDate: Date; MaxNoOfDays: Integer): Boolean
    var
        MaxAllowedDueDate: Date;
    begin
        if MaxNoOfDays > 0 then begin
            MaxAllowedDueDate := InitialDocumentDate + MaxNoOfDays;
            exit(NewDueDate <= MaxAllowedDueDate);
        end;

        exit(true);
    end;

    local procedure CheckSalesDueDate(SalesHeader: Record "Sales Header"; NewDueDate: Date; MaxNoOfDays: Integer)
    begin
        if not CheckDueDate(NewDueDate, SalesHeader."Document Date", MaxNoOfDays) then
            Error(Text001, SalesHeader."Document Type", SalesHeader."No.", MaxNoOfDays, SalesHeader."Document Date");
    end;

    local procedure CheckPurchDueDate(PurchaseHeader: Record "Purchase Header"; NewDueDate: Date; MaxNoOfDays: Integer)
    begin
        if not CheckDueDate(NewDueDate, PurchaseHeader."Document Date", MaxNoOfDays) then
            Error(Text002, PurchaseHeader."Document Type", PurchaseHeader."No.", MaxNoOfDays, PurchaseHeader."Document Date");
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSplitSalesInvCalculateAmounts(var GenJournalLine: Record "Gen. Journal Line"; var SalesHeader: Record "Sales Header"; var RemainingAmount: Decimal; var RemainingAmountLCY: Decimal; Installment: Record Installment; CurrDocNo: Integer; PaymentTerms: Record "Payment Terms")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSplitPurchInvCalculateAmounts(var GenJournalLine: Record "Gen. Journal Line"; var PurchaseHeader: Record "Purchase Header"; var RemainingAmount: Decimal; var RemainingAmountLCY: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSplitSalesInvCloseEntry(var GenJournalLine: Record "Gen. Journal Line"; SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSplitSalesInvCreateBills(var GenJournalLine: Record "Gen. Journal Line"; SalesHeader: Record "Sales Header"; Installment: Record Installment; CurrDocNo: Integer; PaymentTerms: Record "Payment Terms"; RemainingAmount: Decimal; RemainingAmountLCY: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSplitPurchInvCalculateAmounts(var GenJournalLine: Record "Gen. Journal Line"; var PurchaseHeader: Record "Purchase Header"; var TotalAmount: Decimal; var VATAmount: Decimal; var TotalAmountLCY: Decimal; var VATAmountLCY: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSplitPurchInvCloseEntry(var GenJournalLine: Record "Gen. Journal Line"; PurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSplitPurchInvCreateBills(var GenJournalLine: Record "Gen. Journal Line"; PurchaseHeader: Record "Purchase Header"; Installment: Record Installment; CurrDocNo: Integer; PaymentTerms: Record "Payment Terms"; RemainingAmount: Decimal; RemainingAmountLCY: Decimal)
    begin
    end;

#if not CLEAN27
    internal procedure RunOnBeforeSplitServInvCloseEntry(var GenJournalLine: Record "Gen. Journal Line"; ServiceHeader: Record Microsoft.Service.Document."Service Header")
    begin
        OnBeforeSplitServInvCloseEntry(GenJournalLine, ServiceHeader);
    end;

    [Obsolete('Moved to codeunit ServInvoiceSplitPayment', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeSplitServInvCloseEntry(var GenJournalLine: Record "Gen. Journal Line"; ServiceHeader: Record Microsoft.Service.Document."Service Header")
    begin
    end;
#endif

#if not CLEAN27
    internal procedure RunOnBeforeSplitServInvCreateBills(var GenJournalLine: Record "Gen. Journal Line"; ServiceHeader: Record Microsoft.Service.Document."Service Header")
    begin
        OnBeforeSplitServInvCreateBills(GenJournalLine, ServiceHeader);
    end;

    [Obsolete('Moved to codeunit ServInvoiceSplitPayment', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeSplitServInvCreateBills(var GenJournalLine: Record "Gen. Journal Line"; ServiceHeader: Record Microsoft.Service.Document."Service Header")
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnSplitPurchInvOnBeforeCheckPaymentMethod(var PurchHeader: Record "Purchase Header"; var PaymentMethod: Record "Payment Method"; var PaymentTerms: Record "Payment Terms"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSplitSalesInvOnBeforeCheckPaymentMethod(var SalesHeader: Record "Sales Header"; var PaymentMethod: Record "Payment Method"; var PaymentTerms: Record "Payment Terms"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSplitSalesInvOnCreateBillsOnBeforePostGenJnlLine(var GenJournalLine: Record "Gen. Journal Line"; var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSplitPurchInvOnCreateBillsOnBeforePostGenJnlLine(var GenJournalLine: Record "Gen. Journal Line"; PurchaseHeader: Record "Purchase Header")
    begin
    end;

#if not CLEAN27
    internal procedure RunOnSplitServiceInvOnCreateBillsOnBeforePostGenJnlLine(var GenJournalLine: Record "Gen. Journal Line"; ServiceHeader: Record Microsoft.Service.Document."Service Header")
    begin
        OnSplitServiceInvOnCreateBillsOnBeforePostGenJnlLine(GenJournalLine, ServiceHeader);
    end;

    [Obsolete('Moved to codeunit ServInvoiceSplitPayment', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnSplitServiceInvOnCreateBillsOnBeforePostGenJnlLine(var GenJournalLine: Record "Gen. Journal Line"; ServiceHeader: Record Microsoft.Service.Document."Service Header")
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSplitPurchInv(var PurchHeader: Record "Purchase Header"; var VendLedgEntry: Record "Vendor Ledger Entry"; var IsHandled: Boolean)
    begin
    end;
}

