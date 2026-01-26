// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.ReceivablesPayables;

using Microsoft.Bank.BankAccount;
using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Posting;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Ledger;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.PaymentTerms;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Receivables;
using Microsoft.Sales.Reports;
using Microsoft.Sales.Setup;
using Microsoft.Service.Document;
using Microsoft.Service.History;
using Microsoft.Service.Setup;

codeunit 7000035 "Serv. Invoice-Split Payment"
{
    var
        GLSetup: Record "General Ledger Setup";
        SalesSetup: Record "Sales & Receivables Setup";
#if not CLEAN27
        InvoiceSplitPayment: Codeunit "Invoice-Split Payment";
#endif
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text003: Label 'Service %1 no. %2 cannot be posted, because the due date field for one or more installments is more than the legal limit of %3 days after the document date %4 for the original document.';
        Text1100000: Label 'You cannot select a bill-based %1 for a Credit memo.';
        Text1100001: Label '%1 must be 1 if %2 is True in %3';
        Text1100002: Label 'Transfer of Invoice %1 into bills';
        Text1100003: Label 'Unrealized VAT Type must be "Percentage" in VAT Posting Setup.';
        Text1100004: Label 'Bill %1/%2';
        Text1100005: Label 'The sum of %1 cannot be greater then 100 in the installments for %2 %3.';
#pragma warning restore AA0074
#pragma warning restore AA0470

    procedure SplitServiceInvoice(var ServiceHeader: Record "Service Header"; var CustLedgEntry: Record "Cust. Ledger Entry"; var Window: Dialog; SourceCode: Code[10]; GenJnlLineExtDocNo: Code[35]; GenJnlLineDocNo: Code[20]; VATAmount: Decimal)
    var
        Currency: Record Currency;
        CurrencyExchRate: Record "Currency Exchange Rate";
        GenJnlLine: Record "Gen. Journal Line";
        GenJnlLine2: Record "Gen. Journal Line";
        Installment: Record Installment;
        PaymentMethod: Record "Payment Method";
        PaymentTerms: Record "Payment Terms";
        ServiceMgtSetup: Record "Service Mgt. Setup";
        VATPostingSetup: Record "VAT Posting Setup";
        DueDateAdjust: Codeunit "Due Date-Adjust";
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
        BillNo: Integer;
        CurrencyFactor: Decimal;
        TotalAmount: Decimal;
        TotalAmountLCY: Decimal;
        RemainingAmount: Decimal;
        RemainingAmountLCY: Decimal;
        NextDueDate: Date;
        CurrDocNo: Integer;
        TotalPerc: Decimal;
        ExistsVATNoReal: Boolean;
        ErrorMessage: Boolean;
    begin
        if not PaymentMethod.Get(ServiceHeader."Payment Method Code") then
            exit;
        if (not PaymentMethod."Create Bills") and (not PaymentMethod."Invoices to Cartera") then
            exit;
        if PaymentMethod."Create Bills" and (ServiceHeader."Document Type" = ServiceHeader."Document Type"::"Credit Memo") then
            Error(
              Text1100000,
              ServiceHeader.FieldCaption("Payment Method Code"));

        if ServiceHeader."Currency Code" = '' then
            CurrencyFactor := 1
        else
            CurrencyFactor := ServiceHeader."Currency Factor";

        GLSetup.GetRecordOnce();
        SalesSetup.GetRecordOnce();
        ServiceMgtSetup.Get();
        ServiceHeader.TestField("Payment Terms Code");
        PaymentTerms.Get(ServiceHeader."Payment Terms Code");
        PaymentTerms.CalcFields("No. of Installments");
        if PaymentTerms."No. of Installments" = 0 then
            PaymentTerms."No. of Installments" := 1;
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
            GenJnlLine."Posting Date" := ServiceHeader."Posting Date";
            GenJnlLine."Document Date" := ServiceHeader."Document Date";
            GenJnlLine.Validate("Account Type", GenJnlLine."Account Type"::Customer);
            GenJnlLine.Validate("Account No.", ServiceHeader."Bill-to Customer No.");
            GenJnlLine."Document Type" := GenJnlLine."Document Type"::" ";
            GenJnlLine."Document No." := GenJnlLineDocNo;
            GenJnlLine.Description :=
              CopyStr(StrSubstNo(Text1100002, GenJnlLineDocNo), 1, MaxStrLen(GenJnlLine.Description));
            GenJnlLine."Shortcut Dimension 1 Code" := ServiceHeader."Shortcut Dimension 1 Code";
            GenJnlLine."Shortcut Dimension 2 Code" := ServiceHeader."Shortcut Dimension 2 Code";
            GenJnlLine."Dimension Set ID" := ServiceHeader."Dimension Set ID";
            GenJnlLine."Reason Code" := ServiceHeader."Reason Code";
            GenJnlLine."External Document No." := GenJnlLineExtDocNo;
            GenJnlLine.Validate("Currency Code", ServiceHeader."Currency Code");
            GenJnlLine.Amount := -TotalAmount;
            GenJnlLine."Amount (LCY)" := -TotalAmountLCY;
            GenJnlLine."System-Created Entry" := true;
            GenJnlLine."Applies-to Doc. Type" := GenJnlLine."Applies-to Doc. Type"::Invoice;
            GenJnlLine."Applies-to Doc. No." := GenJnlLineDocNo;
            GenJnlLine."Source Code" := SourceCode;
            GenJnlLine."Currency Factor" := CurrencyFactor;
            GenJnlLine."Payment Method Code" := ServiceHeader."Payment Method Code";
            GenJnlLine."Recipient Bank Account" := ServiceHeader."Cust. Bank Acc. Code";
            GenJnlLine."Salespers./Purch. Code" := ServiceHeader."Salesperson Code";

            if GLSetup."Unrealized VAT" then begin
                FindCustVATSetupServ(VATPostingSetup, ServiceHeader, ErrorMessage, ExistsVATNoReal);
                if ErrorMessage then
                    Error(Text1100003);
            end;

            OnBeforeSplitServInvCloseEntry(GenJnlLine, ServiceHeader);
#if not CLEAN27
            InvoiceSplitPayment.RunOnBeforeSplitServInvCloseEntry(GenJnlLine, ServiceHeader);
#endif
            if GLSetup."Unrealized VAT" and ExistsVATNoReal then
                GenJnlLine2.Copy(GenJnlLine)
            else
                GenJnlPostLine.Run(GenJnlLine);
        end;
        // create bills
        if ServiceHeader."Currency Code" = '' then begin
            Currency."Invoice Rounding Precision" := GLSetup."Inv. Rounding Precision (LCY)";
            Currency."Invoice Rounding Type" := GLSetup."Inv. Rounding Type (LCY)";
            Currency."Amount Rounding Precision" := GLSetup."Amount Rounding Precision";
        end else
            Currency.Get(ServiceHeader."Currency Code");
        TotalAmount := RoundReceivableAmt(TotalAmount, Currency);

        RoundReceivableAmtLCY(VATAmount / CurrencyFactor);

        if PaymentTerms."No. of Installments" > 0 then begin
            Installment.SetRange("Payment Terms Code", PaymentTerms.Code);
            if Installment.Find('-') then;
        end;

        NextDueDate := ServiceHeader."Due Date";

        GenJnlLine.Init();
        GenJnlLine."Posting Date" := ServiceHeader."Posting Date";
        GenJnlLine."Document Date" := ServiceHeader."Document Date";
        GenJnlLine.Validate("Account Type", GenJnlLine."Account Type"::Customer);
        GenJnlLine.Validate("Account No.", ServiceHeader."Bill-to Customer No.");
        GenJnlLine."Document Type" := GenJnlLine."Document Type"::Bill;
        GenJnlLine."Document No." := GenJnlLineDocNo;
        GenJnlLine."Shortcut Dimension 1 Code" := ServiceHeader."Shortcut Dimension 1 Code";
        GenJnlLine."Shortcut Dimension 2 Code" := ServiceHeader."Shortcut Dimension 2 Code";
        GenJnlLine."Dimension Set ID" := ServiceHeader."Dimension Set ID";
        GenJnlLine."Reason Code" := ServiceHeader."Reason Code";
        GenJnlLine."External Document No." := GenJnlLineExtDocNo;
        GenJnlLine.Validate("Currency Code", ServiceHeader."Currency Code");
        GenJnlLine."System-Created Entry" := true;
        GenJnlLine."Source Code" := SourceCode;
        GenJnlLine."Currency Factor" := CurrencyFactor;
        GenJnlLine."Payment Method Code" := ServiceHeader."Payment Method Code";
        GenJnlLine."Recipient Bank Account" := ServiceHeader."Cust. Bank Acc. Code";
        GenJnlLine."Salespers./Purch. Code" := ServiceHeader."Salesperson Code";

        CurrDocNo := 1;
        repeat
            GenJnlLine."Due Date" := NextDueDate;
            CheckServiceDueDate(ServiceHeader, GenJnlLine."Due Date", PaymentTerms."Max. No. of Days till Due Date");
            DueDateAdjust.SalesAdjustDueDate(
              GenJnlLine."Due Date", ServiceHeader."Document Date", PaymentTerms.CalculateMaxDueDate(ServiceHeader."Document Date"), ServiceHeader."Bill-to Customer No.");
            NextDueDate := GenJnlLine."Due Date";
            if CurrDocNo < PaymentTerms."No. of Installments" then begin
                Installment.TestField("% of Total");
                if CurrDocNo = 1 then begin
                    TotalPerc := Installment."% of Total";
                    case PaymentTerms."VAT distribution" of
                        PaymentTerms."VAT distribution"::"First Installment":
                            begin
                                GenJnlLine.Amount := RoundReceivableAmt((TotalAmount - VATAmount) * Installment."% of Total" / 100 + VATAmount, Currency);
                                GenJnlLine."Amount (LCY)" :=
                                  RoundReceivableAmtLCY(
                                    CurrencyExchRate.ExchangeAmtFCYToLCY(ServiceHeader."Posting Date", Currency.Code, GenJnlLine.Amount, CurrencyFactor));
                            end;
                        PaymentTerms."VAT distribution"::"Last Installment":
                            begin
                                GenJnlLine.Amount := RoundReceivableAmt((TotalAmount - VATAmount) * Installment."% of Total" / 100, Currency);
                                GenJnlLine."Amount (LCY)" :=
                                  RoundReceivableAmtLCY(
                                    CurrencyExchRate.ExchangeAmtFCYToLCY(ServiceHeader."Posting Date", Currency.Code, GenJnlLine.Amount, CurrencyFactor));
                            end;
                        PaymentTerms."VAT distribution"::Proportional:
                            begin
                                GenJnlLine.Amount := RoundReceivableAmt(TotalAmount * Installment."% of Total" / 100, Currency);
                                GenJnlLine."Amount (LCY)" :=
                                  RoundReceivableAmtLCY(
                                    CurrencyExchRate.ExchangeAmtFCYToLCY(ServiceHeader."Posting Date", Currency.Code, GenJnlLine.Amount, CurrencyFactor));
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
                                GenJnlLine.Amount := RoundReceivableAmt((TotalAmount - VATAmount) * Installment."% of Total" / 100, Currency);
                                GenJnlLine."Amount (LCY)" :=
                                  RoundReceivableAmtLCY(
                                    CurrencyExchRate.ExchangeAmtFCYToLCY(ServiceHeader."Posting Date", Currency.Code, GenJnlLine.Amount, CurrencyFactor));
                            end;
                        PaymentTerms."VAT distribution"::Proportional:
                            begin
                                GenJnlLine.Amount := RoundReceivableAmt(TotalAmount * Installment."% of Total" / 100, Currency);
                                GenJnlLine."Amount (LCY)" :=
                                  RoundReceivableAmtLCY(
                                    CurrencyExchRate.ExchangeAmtFCYToLCY(ServiceHeader."Posting Date", Currency.Code, GenJnlLine.Amount, CurrencyFactor));
                            end;
                    end;
                end;
                RemainingAmount := RemainingAmount - GenJnlLine.Amount;
                RemainingAmountLCY := RemainingAmountLCY - GenJnlLine."Amount (LCY)";
                Installment.TestField("Gap between Installments");
                NextDueDate := CalculateDate(Installment."Gap between Installments", NextDueDate);
                Installment.Next();
            end else begin
                GenJnlLine.Amount := RemainingAmount;
                GenJnlLine."Amount (LCY)" := RemainingAmountLCY;
            end;

            OnBeforeSplitServInvCreateBills(GenJnlLine, ServiceHeader);
#if not CLEAN27
            InvoiceSplitPayment.RunOnBeforeSplitServInvCreateBills(GenJnlLine, ServiceHeader);
#endif

            if PaymentMethod."Create Bills" and ((GenJnlLine.Amount <> 0) or (GenJnlLine."Amount (LCY)" <> 0)) then begin
                BillNo += 1;
                GenJnlLine."Bill No." := Format(BillNo);
                GenJnlLine.Description :=
                  CopyStr(
                    StrSubstNo(Text1100004, GenJnlLineDocNo, BillNo),
                    1,
                    MaxStrLen(GenJnlLine.Description));
                OnSplitServiceInvOnCreateBillsOnBeforePostGenJnlLine(GenJnlLine, ServiceHeader);
                GenJnlPostLine.Run(GenJnlLine);
            end;
            CurrDocNo += 1;
        until (CurrDocNo > PaymentTerms."No. of Installments") or (RemainingAmount = 0);

        if GLSetup."Unrealized VAT" and ExistsVATNoReal then
            GenJnlPostLine.Run(GenJnlLine2);
    end;

    local procedure RoundReceivableAmt(Amount: Decimal; Currency: Record Currency): Decimal
    begin
        SalesSetup.GetRecordOnce();
        if SalesSetup."Invoice Rounding" then
            Amount := Round(Amount, Currency."Invoice Rounding Precision", SelectStr(Currency."Invoice Rounding Type" + 1, '=,>,<'))
        else
            Amount := Round(Amount, Currency."Amount Rounding Precision");

        exit(Amount);
    end;

    local procedure RoundReceivableAmtLCY(Amount: Decimal): Decimal
    begin
        GLSetup.GetRecordOnce();
        SalesSetup.GetRecordOnce();
        if SalesSetup."Invoice Rounding" then
            Amount := Round(Amount, GLSetup."Inv. Rounding Precision (LCY)", SelectStr(GLSetup."Inv. Rounding Type (LCY)" + 1, '=,>,<'))
        else
            Amount := Round(Amount, GLSetup."Amount Rounding Precision");

        exit(Amount);
    end;

    procedure FindCustVATSetupServ(var VATSetup: Record "VAT Posting Setup"; ServiceHeader2: Record "Service Header"; var ErrorMessage: Boolean; var ExistsVATNoReal: Boolean)
    var
        Customer: Record Customer;
        ServiceLine2: Record "Service Line";
        PostingGroup: Code[20];
    begin
        Customer.Get(ServiceHeader2."Bill-to Customer No.");

        VATSetup.SetCurrentKey("VAT Bus. Posting Group", "VAT Prod. Posting Group");
        VATSetup.SetRange("VAT Bus. Posting Group", Customer."VAT Bus. Posting Group");

        ServiceLine2.SetCurrentKey("Document Type", "Document No.", "Line No.");
        ServiceLine2.SetRange("Document Type", ServiceHeader2."Document Type");
        ServiceLine2.SetRange("Document No.", ServiceHeader2."No.");
        ServiceLine2.Find('-');

        repeat
            case ServiceLine2.Type of
                ServiceLine2.Type::Item:
                    begin
                        PostingGroup := ServiceLine2."VAT Prod. Posting Group";
                        VATSetup.SetRange("VAT Prod. Posting Group", PostingGroup);
                        if VATSetup.Find('-') and (VATSetup."Unrealized VAT Type" >= VATSetup."Unrealized VAT Type"::Percentage) then
                            if VATSetup."Unrealized VAT Type" > VATSetup."Unrealized VAT Type"::Percentage then
                                ErrorMessage := true
                            else
                                ExistsVATNoReal := true;
                    end;
                ServiceLine2.Type::Resource:
                    begin
                        PostingGroup := ServiceLine2."VAT Prod. Posting Group";
                        VATSetup.SetRange("VAT Prod. Posting Group", PostingGroup);
                        if VATSetup.Find('-') and (VATSetup."Unrealized VAT Type" >= VATSetup."Unrealized VAT Type"::Percentage) then
                            if VATSetup."Unrealized VAT Type" > VATSetup."Unrealized VAT Type"::Percentage then
                                ErrorMessage := true
                            else
                                ExistsVATNoReal := true;
                    end;
                ServiceLine2.Type::"G/L Account":
                    begin
                        PostingGroup := ServiceLine2."VAT Prod. Posting Group";
                        VATSetup.SetRange("VAT Prod. Posting Group", PostingGroup);
                        if VATSetup.Find('-') and (VATSetup."Unrealized VAT Type" >= VATSetup."Unrealized VAT Type"::Percentage) then
                            if VATSetup."Unrealized VAT Type" > VATSetup."Unrealized VAT Type"::Percentage then
                                ErrorMessage := true
                            else
                                ExistsVATNoReal := true;
                    end;
            end;
        until ServiceLine2.Next() = 0;
    end;

    local procedure CheckServiceDueDate(ServiceHeader: Record "Service Header"; NewDueDate: Date; MaxNoOfDays: Integer)
    begin
        if not CheckDueDate(NewDueDate, ServiceHeader."Document Date", MaxNoOfDays) then
            Error(Text003, ServiceHeader."Document Type", ServiceHeader."No.", MaxNoOfDays, ServiceHeader."Document Date");
    end;

    local procedure CheckDueDate(NewDueDate: Date; InitialDocumentDate: Date; MaxNoOfDays: Integer): Boolean
    var
        MaxAllowedDueDate: Date;
    begin
        if MaxNoOfDays > 0 then begin
            MaxAllowedDueDate := InitialDocumentDate + MaxNoOfDays;
            exit(NewDueDate <= MaxAllowedDueDate);
        end;

        exit(true);
    end;

    local procedure CalculateDate(DateFormulaText: Code[20]; DueDate: Date): Date
    var
        DateFormula: DateFormula;
    begin
        Evaluate(DateFormula, DateFormulaText);
        exit(CalcDate(DateFormula, DueDate));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSplitServInvCloseEntry(var GenJournalLine: Record "Gen. Journal Line"; ServiceHeader: Record Microsoft.Service.Document."Service Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSplitServInvCreateBills(var GenJournalLine: Record "Gen. Journal Line"; ServiceHeader: Record Microsoft.Service.Document."Service Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSplitServiceInvOnCreateBillsOnBeforePostGenJnlLine(var GenJournalLine: Record "Gen. Journal Line"; ServiceHeader: Record "Service Header")
    begin
    end;

    // Sales Invoice Book

    [EventSubscriber(ObjectType::Report, Report::"Sales Invoice Book", 'OnAfterUpdateCustomerData', '', true, true)]
    local procedure OnAfterUpdateCustomerData(VATEntry: Record "VAT Entry"; var Customer: Record Customer; var ShouldExit: Boolean)
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
    begin
        case VATEntry."Document Type" of
            VATEntry."Document Type"::"Credit Memo":
                if ServiceCrMemoHeader.Get(VATEntry."Document No.") then begin
                    Customer.Name := ServiceCrMemoHeader."Bill-to Name";
                    Customer."VAT Registration No." := ServiceCrMemoHeader."VAT Registration No.";
                    ShouldExit := true;
                end;
            VATEntry."Document Type"::Invoice:
                if ServiceInvoiceHeader.Get(VATEntry."Document No.") then begin
                    Customer.Name := ServiceInvoiceHeader."Bill-to Name";
                    Customer."VAT Registration No." := ServiceInvoiceHeader."VAT Registration No.";
                    ShouldExit := true;
                end;
        end;
    end;
}