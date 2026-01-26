// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using Microsoft.Bank.BankAccount;
using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Receivables;

codeunit 2000000 PmtJrnlManagement
{
    Permissions = TableData "Cust. Ledger Entry" = rm,
                  TableData "Vendor Ledger Entry" = rm,
                  TableData "Payment Journal Template" = rimd,
                  TableData "Paym. Journal Batch" = rimd;

    trigger OnRun()
    begin
    end;

    var
        Text000: Label 'DEFAULT', Comment = 'DEFAULT - default batch name';
        Text001: Label 'Default Payment Journal';
        Text002: Label 'Default Journal';
        Text003: Label 'It is not possible to display %1 in a field with a length of %2.';
        LastPaymentJnlLine: Record "Payment Journal Line";

    procedure TemplateSelection(var PaymJnlLine: Record "Payment Journal Line"; var JnlSelected: Boolean)
    var
        PaymentJnlTemplate: Record "Payment Journal Template";
        PaymentJnlTemplate2: Record "Payment Journal Template";
    begin
        JnlSelected := true;

        PaymentJnlTemplate.Reset();
        if not PaymentJnlTemplate.FindSet() then begin
            PaymentJnlTemplate.Init();
            PaymentJnlTemplate.Name := Text000;
            PaymentJnlTemplate.Description := Text001;
            PaymentJnlTemplate."Page ID" := PAGE::"EB Payment Journal";
            PaymentJnlTemplate.Insert(true);
            Commit();
        end else begin
            PaymentJnlTemplate2 := PaymentJnlTemplate;
            if PaymentJnlTemplate.Next() <> 0 then
                JnlSelected := PAGE.RunModal(0, PaymentJnlTemplate) = ACTION::LookupOK
            else
                PaymentJnlTemplate := PaymentJnlTemplate2;
        end;
        if JnlSelected then begin
            PaymJnlLine.FilterGroup(2);
            PaymJnlLine.SetRange("Journal Template Name", PaymentJnlTemplate.Name);
            PaymJnlLine.FilterGroup(0);
        end;
    end;

    procedure OpenJournal(var CurrentJnlBatchName: Code[10]; var PaymentJnlLine: Record "Payment Journal Line")
    begin
        CheckTemplateName(PaymentJnlLine.GetRangeMax("Journal Template Name"), CurrentJnlBatchName);
        PaymentJnlLine.FilterGroup(2);
        PaymentJnlLine.SetRange("Journal Batch Name", CurrentJnlBatchName);
        PaymentJnlLine.FilterGroup(0);
    end;

    local procedure CheckTemplateName(CurrenJnlTemplateName: Code[10]; var CurrentJnlBatchName: Code[10])
    var
        PaymentJnlTemplate: Record "Payment Journal Template";
        PaymJnlBatch: Record "Paym. Journal Batch";
    begin
        PaymentJnlTemplate.Get(CurrenJnlTemplateName);
        PaymJnlBatch.SetRange("Journal Template Name", CurrenJnlTemplateName);
        if not PaymJnlBatch.Get(CurrenJnlTemplateName, CurrentJnlBatchName) then begin
            if not PaymJnlBatch.FindLast() then begin
                PaymJnlBatch.Init();
                PaymJnlBatch."Journal Template Name" := CurrenJnlTemplateName;
                PaymJnlBatch.Name := Text000;
                PaymJnlBatch.Description := Text002;
                PaymJnlBatch."Reason Code" := PaymentJnlTemplate."Reason Code";
                PaymJnlBatch.Insert();
                Commit();
            end;
            CurrentJnlBatchName := PaymJnlBatch.Name
        end;
    end;

    procedure OpenJnlBatch(var PaymJnlBatch: Record "Paym. Journal Batch")
    var
        PaymentJnlTemplate: Record "Payment Journal Template";
        PaymJnlLine: Record "Payment Journal Line";
        PaymentJnlTemplate2: Record "Payment Journal Template";
        JnlSelected: Boolean;
    begin
        if PaymJnlBatch.GetFilter("Journal Template Name") <> '' then
            exit;
        PaymJnlBatch.FilterGroup(2);
        if PaymJnlBatch.GetFilter("Journal Template Name") <> '' then begin
            PaymJnlBatch.FilterGroup(0);
            exit;
        end;
        PaymJnlBatch.FilterGroup(0);

        if not PaymJnlBatch.FindFirst() then begin
            if not PaymentJnlTemplate.FindFirst() then
                TemplateSelection(PaymJnlLine, JnlSelected);
            if PaymentJnlTemplate.FindFirst() then
                CheckTemplateName(PaymentJnlTemplate.Name, PaymJnlBatch.Name);
        end;
        PaymJnlBatch.FindFirst();
        JnlSelected := true;
        if PaymJnlBatch.GetFilter("Journal Template Name") <> '' then
            PaymentJnlTemplate.SetRange(Name, PaymJnlBatch.GetFilter("Journal Template Name"));
        if PaymentJnlTemplate.FindSet() then begin
            PaymentJnlTemplate2 := PaymentJnlTemplate;
            if PaymentJnlTemplate.Next() <> 0 then
                JnlSelected := PAGE.RunModal(0, PaymentJnlTemplate) = ACTION::LookupOK
            else
                PaymentJnlTemplate := PaymentJnlTemplate2;
        end;
        if not JnlSelected then
            Error('');

        PaymJnlBatch.FilterGroup(2);
        PaymJnlBatch.SetRange("Journal Template Name", PaymentJnlTemplate.Name);
        PaymJnlBatch.FilterGroup(0);
    end;

    procedure TemplateSelectionFromBatch(var PaymJnlBatch: Record "Paym. Journal Batch")
    var
        PaymJnlLine: Record "Payment Journal Line";
        PaymentJnlTemplate: Record "Payment Journal Template";
    begin
        PaymentJnlTemplate.Get(PaymJnlBatch."Journal Template Name");
        PaymentJnlTemplate.TestField("Page ID");
        PaymJnlBatch.TestField(Name);

        PaymJnlLine.FilterGroup := 2;
        PaymJnlLine.SetRange("Journal Template Name", PaymentJnlTemplate.Name);
        PaymJnlLine.FilterGroup := 0;

        PaymJnlLine."Journal Template Name" := '';
        PaymJnlLine."Journal Batch Name" := PaymJnlBatch.Name;
        PAGE.Run(PaymentJnlTemplate."Page ID", PaymJnlLine);
    end;

    procedure CheckName(CurrentJnlBatchName: Code[10]; var PaymentJnlLine: Record "Payment Journal Line")
    var
        PaymentJnlBatch: Record "Paym. Journal Batch";
    begin
        PaymentJnlBatch.Get(PaymentJnlLine.GetRangeMax("Journal Template Name"), CurrentJnlBatchName);
    end;

    procedure SetName(CurrentJnlBatchName: Code[10]; var PaymentJnlLine: Record "Payment Journal Line")
    begin
        PaymentJnlLine.FilterGroup(2);
        PaymentJnlLine.SetRange("Journal Batch Name", CurrentJnlBatchName);
        PaymentJnlLine.FilterGroup(0);
        if PaymentJnlLine.FindFirst() then;
    end;

    procedure LookupName(CurrenJnlTemplateName: Code[10]; CurrentJnlBatchName: Code[10]; var NewJnlBatchName: Text[10]): Boolean
    var
        PaymJnlBatch: Record "Paym. Journal Batch";
    begin
        PaymJnlBatch."Journal Template Name" := CurrenJnlTemplateName;
        PaymJnlBatch.Name := CurrentJnlBatchName;
        PaymJnlBatch.FilterGroup(2);

        PaymJnlBatch.SetRange("Journal Template Name", CurrenJnlTemplateName);
        PaymJnlBatch.FilterGroup(0);
        if PAGE.RunModal(0, PaymJnlBatch) <> ACTION::LookupOK then
            exit(false);

        NewJnlBatchName := PaymJnlBatch.Name;
        exit(true);
    end;

    procedure GetAccount(var PaymentJnlLine: Record "Payment Journal Line"; var AccName: Text[100]; var BankAccName: Text[100])
    var
        Cust: Record Customer;
        Vend: Record Vendor;
        Bank: Record "Bank Account";
    begin
        if (PaymentJnlLine."Account Type" <> LastPaymentJnlLine."Account Type") or
           (PaymentJnlLine."Account No." <> LastPaymentJnlLine."Account No.")
        then begin
            AccName := '';
            if PaymentJnlLine."Account No." <> '' then
                case PaymentJnlLine."Account Type" of
                    PaymentJnlLine."Account Type"::Customer:
                        if Cust.Get(PaymentJnlLine."Account No.") then
                            AccName := Cust.Name;
                    PaymentJnlLine."Account Type"::Vendor:
                        if Vend.Get(PaymentJnlLine."Account No.") then
                            AccName := Vend.Name;
                end;
        end;
        if PaymentJnlLine."Bank Account" <> LastPaymentJnlLine."Bank Account" then begin
            BankAccName := '';
            if Bank.Get(PaymentJnlLine."Bank Account") then
                BankAccName := Bank.Name;
        end;

        LastPaymentJnlLine := PaymentJnlLine;
    end;

    procedure CalculateTotals(var PaymentJnlLine: Record "Payment Journal Line"; LastPaymentJnlLine: Record "Payment Journal Line"; var Balance: Decimal; var TotalAmount: Decimal; var ShowAmount: Boolean; var ShowTotalAmount: Boolean)
    var
        TempPaymJnlLine: Record "Payment Journal Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalculateTotals(PaymentJnlLine, LastPaymentJnlLine, Balance, TotalAmount, ShowAmount, ShowTotalAmount, IsHandled);
        if IsHandled then
            exit;

        TempPaymJnlLine.CopyFilters(PaymentJnlLine);
        TempPaymJnlLine.SetCurrentKey(
          "Journal Template Name", "Journal Batch Name", "Account Type", "Account No.", "Export Protocol Code", "Bank Account");
        if TempPaymJnlLine.CalcSums("Amount (LCY)") then begin
            if PaymentJnlLine."Line No." <> 0 then // 0 = new record
                TotalAmount := TempPaymJnlLine."Amount (LCY)"
            else
                TotalAmount := TempPaymJnlLine."Amount (LCY)" + LastPaymentJnlLine."Amount (LCY)";
            ShowTotalAmount := true;
        end else
            ShowTotalAmount := false;

        if PaymentJnlLine."Line No." = 0 then
            ShowAmount := false
        else // 0 = New record
            if PaymentJnlLine."Account No." <> '' then begin
                TempPaymJnlLine.SetCurrentKey("Account Type", "Account No.");
                TempPaymJnlLine.SetRange("Account Type", PaymentJnlLine."Account Type");
                TempPaymJnlLine.SetRange("Account No.", PaymentJnlLine."Account No.");
                TempPaymJnlLine.SetCurrentKey("Account Type", "Account No.");
                if TempPaymJnlLine.CalcSums("Amount (LCY)") then begin
                    Balance := TempPaymJnlLine."Amount (LCY)";
                    ShowAmount := true;
                end else
                    ShowAmount := false;
            end;
    end;

    procedure SetUpNewLine(var PaymentJnlLine: Record "Payment Journal Line"; LastPaymentJnlLine: Record "Payment Journal Line")
    var
        PaymentJnlTemplate: Record "Payment Journal Template";
    begin
        PaymentJnlLine.Validate("Posting Date", LastPaymentJnlLine."Posting Date");
        PaymentJnlTemplate.Get(PaymentJnlLine."Journal Template Name");
        PaymentJnlLine.Validate("Bank Account", PaymentJnlTemplate."Bank Account");
    end;

    procedure ShowCard(PaymentJnlLine: Record "Payment Journal Line")
    var
        GLAcc: Record "G/L Account";
        Cust: Record Customer;
        Vend: Record Vendor;
    begin
        case PaymentJnlLine."Account Type" of
            0:
                begin
                    GLAcc."No." := PaymentJnlLine."Account No.";
                    PAGE.Run(PAGE::"G/L Account Card", GLAcc);
                end;
            PaymentJnlLine."Account Type"::Customer:
                begin
                    Cust."No." := PaymentJnlLine."Account No.";
                    PAGE.Run(PAGE::"Customer Card", Cust);
                end;
            PaymentJnlLine."Account Type"::Vendor:
                begin
                    Vend."No." := PaymentJnlLine."Account No.";
                    PAGE.Run(PAGE::"Vendor Card", Vend);
                end;
        end;
    end;

    procedure ShowEntries(PaymentJnlLine: Record "Payment Journal Line")
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        VendLedgEntry: Record "Vendor Ledger Entry";
    begin
        case PaymentJnlLine."Account Type" of
            PaymentJnlLine."Account Type"::Customer:
                begin
                    CustLedgEntry.SetCurrentKey("Customer No.", "Posting Date");
                    CustLedgEntry.SetRange("Customer No.", PaymentJnlLine."Account No.");
                    if CustLedgEntry.FindLast() then;
                    PAGE.Run(PAGE::"Customer Ledger Entries", CustLedgEntry);
                end;
            PaymentJnlLine."Account Type"::Vendor:
                begin
                    VendLedgEntry.SetCurrentKey("Vendor No.", "Posting Date");
                    VendLedgEntry.SetRange("Vendor No.", PaymentJnlLine."Account No.");
                    if VendLedgEntry.FindLast() then;
                    PAGE.Run(PAGE::"Vendor Ledger Entries", VendLedgEntry);
                end;
        end;
    end;

    procedure ConvertToDigit(AlphaNumValue: Text[250]; Length: Integer): Text[250]
    begin
        exit(DelChr(Format(DelChr(AlphaNumValue, '=', DelChr(AlphaNumValue, '=', '0123456789')), Length)));
    end;

    procedure DecimalNumeralZeroFormat(DecimalNumeral: Decimal; Length: Integer): Text[250]
    begin
        exit(TextZeroFormat(DelChr(Format(Round(Abs(DecimalNumeral), 1, '<'), 0, 1)), Length));
    end;

    procedure TextZeroFormat(Text: Text[250]; Length: Integer): Text[250]
    begin
        if StrLen(Text) > Length then
            Error(
              Text003,
              Text, Length);
        exit(PadStr('', Length - StrLen(Text), '0') + Text);
    end;

    procedure PrintTestReport(PmtJnlBatch: Record "Paym. Journal Batch")
    var
        PmtJnlTemplate: Record "Payment Journal Template";
    begin
        PmtJnlBatch.SetRecFilter();
        PmtJnlTemplate.Get(PmtJnlBatch."Journal Template Name");
        PmtJnlTemplate.TestField("Test Report ID");
        REPORT.Run(PmtJnlTemplate."Test Report ID", true, false, PmtJnlBatch);
    end;

    procedure Mod97Test(BankAccountNo: Text[250]): Boolean
    var
        Decimal: Decimal;
        Check: Decimal;
        BankAccNo: Text[30];
    begin
        BankAccNo := CopyStr(ConvertToDigit(BankAccountNo, MaxStrLen(BankAccNo)), 1, MaxStrLen(BankAccNo));
        if StrLen(BankAccNo) <> 12 then
            exit(false);

        Evaluate(Decimal, CopyStr(BankAccNo, 1, 10));
        Evaluate(Check, CopyStr(BankAccNo, 11, 2));

        Decimal := Decimal mod 97;
        if Decimal = 0 then
            Decimal := 97;

        exit(Decimal = Check);
    end;

    procedure ModifyPmtDiscDueDate(PaymentJnlLine: Record "Payment Journal Line")
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
        CustLedgEntry: Record "Cust. Ledger Entry";
        CurrExchRate: Record "Currency Exchange Rate";
        Currency: Record Currency;
    begin
        case PaymentJnlLine."Account Type" of
            PaymentJnlLine."Account Type"::Customer:
                begin
                    CustLedgEntry.SetCurrentKey("Document No.");
                    CustLedgEntry.SetRange("Document Type", PaymentJnlLine."Applies-to Doc. Type");
                    CustLedgEntry.SetRange("Document No.", PaymentJnlLine."Applies-to Doc. No.");
                    CustLedgEntry.SetRange("Customer No.", PaymentJnlLine."Account No.");
                    CustLedgEntry.SetRange(Open, true);
                    if CustLedgEntry.FindLast() then begin
                        if CustLedgEntry."Currency Code" = PaymentJnlLine."Currency Code" then
                            CustLedgEntry.Validate("Remaining Pmt. Disc. Possible", -PaymentJnlLine."Pmt. Disc. Possible")
                        else begin
                            if not Currency.Get(CustLedgEntry."Currency Code") then
                                Currency.InvoiceRoundingDirection();
                            CustLedgEntry.Validate("Remaining Pmt. Disc. Possible",
                              Round(
                                CurrExchRate.ExchangeAmtFCYToFCY(
                                  CustLedgEntry."Posting Date", PaymentJnlLine."Currency Code", CustLedgEntry."Currency Code", -PaymentJnlLine."Pmt. Disc. Possible"),
                                Currency."Amount Rounding Precision"));
                        end;
                        CustLedgEntry.Validate("Pmt. Discount Date", PaymentJnlLine."Posting Date");
                        CustLedgEntry.Modify(true);
                    end;
                end;
            PaymentJnlLine."Account Type"::Vendor:
                begin
                    VendLedgEntry.SetCurrentKey("Document No.");
                    VendLedgEntry.SetRange("Document Type", PaymentJnlLine."Applies-to Doc. Type");
                    VendLedgEntry.SetRange("Document No.", PaymentJnlLine."Applies-to Doc. No.");
                    VendLedgEntry.SetRange("Vendor No.", PaymentJnlLine."Account No.");
                    VendLedgEntry.SetRange(Open, true);
                    if VendLedgEntry.FindLast() then begin
                        if VendLedgEntry."Currency Code" = PaymentJnlLine."Currency Code" then
                            VendLedgEntry.Validate("Remaining Pmt. Disc. Possible", -PaymentJnlLine."Pmt. Disc. Possible")
                        else begin
                            if not Currency.Get(VendLedgEntry."Currency Code") then
                                Currency.InvoiceRoundingDirection();
                            VendLedgEntry.Validate("Remaining Pmt. Disc. Possible",
                              Round(
                                CurrExchRate.ExchangeAmtFCYToFCY(
                                  VendLedgEntry."Posting Date", PaymentJnlLine."Currency Code", VendLedgEntry."Currency Code", -PaymentJnlLine."Pmt. Disc. Possible"),
                                Currency."Amount Rounding Precision"));
                        end;
                        VendLedgEntry.Validate("Pmt. Discount Date", PaymentJnlLine."Posting Date");
                        VendLedgEntry.Modify(true);
                    end;
                end;
        end;
    end;

    procedure SetApplID(PaymentJnlLine: Record "Payment Journal Line")
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
        CustLedgEntry: Record "Cust. Ledger Entry";
    begin
        case PaymentJnlLine."Account Type" of
            PaymentJnlLine."Account Type"::Customer:
                begin
                    CustLedgEntry.SetCurrentKey("Document No.");
                    CustLedgEntry.SetRange("Document Type", PaymentJnlLine."Applies-to Doc. Type");
                    CustLedgEntry.SetRange("Document No.", PaymentJnlLine."Applies-to Doc. No.");
                    CustLedgEntry.SetRange("Customer No.", PaymentJnlLine."Account No.");
                    CustLedgEntry.SetRange("Entry No.", PaymentJnlLine."Ledger Entry No.");
                    CustLedgEntry.SetRange(Open, true);
                    if CustLedgEntry.FindLast() then begin
                        CustLedgEntry.Validate("Amount to Apply", -PaymentJnlLine."Original Remaining Amount");
                        CustLedgEntry.Validate("Applies-to ID", PaymentJnlLine."Applies-to ID");
                        CustLedgEntry.Modify(true);
                    end;
                end;
            PaymentJnlLine."Account Type"::Vendor:
                begin
                    VendLedgEntry.SetCurrentKey("Document No.");
                    VendLedgEntry.SetRange("Document Type", PaymentJnlLine."Applies-to Doc. Type");
                    VendLedgEntry.SetRange("Document No.", PaymentJnlLine."Applies-to Doc. No.");
                    VendLedgEntry.SetRange("Vendor No.", PaymentJnlLine."Account No.");
                    VendLedgEntry.SetRange("Entry No.", PaymentJnlLine."Ledger Entry No.");
                    VendLedgEntry.SetRange(Open, true);
                    if VendLedgEntry.FindLast() then begin
                        VendLedgEntry.Validate("Amount to Apply", -PaymentJnlLine."Original Remaining Amount");
                        VendLedgEntry.Validate("Applies-to ID", PaymentJnlLine."Applies-to ID");
                        VendLedgEntry.Modify(true);
                    end;
                end;
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalculateTotals(var PaymentJnlLine: Record "Payment Journal Line"; LastPaymentJnlLine: Record "Payment Journal Line"; var Balance: Decimal; var TotalAmount: Decimal; var ShowAmount: Boolean; var ShowTotalAmount: Boolean; var IsHandled: Boolean)
    begin
    end;
}

