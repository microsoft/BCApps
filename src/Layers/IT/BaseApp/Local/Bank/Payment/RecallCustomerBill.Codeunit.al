// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using Microsoft.Bank.BankAccount;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Posting;
using Microsoft.Sales.Receivables;
using Microsoft.Sales.Setup;

codeunit 12170 "Recall Customer Bill"
{
    Permissions = TableData "Cust. Ledger Entry" = rimd;
    TableNo = "Customer Bill Header";

    trigger OnRun()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOnRun(Rec, IsHandled);
        if IsHandled then
            exit;

        if not Confirm(Text1130001) then
            exit;

        Rec.TestField("Payment Method Code");
        SalesSetup.Get();

        PaymentMethod.Get(Rec."Payment Method Code");
        Bill.Get(PaymentMethod."Bill Code");

        Bill.TestField("Allow Issue", true);

        CustomerBillLine.Reset();
        CustomerBillLine.SetRange("Customer Bill No.", Rec."No.");

        if UserId <> '' then
            CustomerBillLine.SetRange("Recalled by", UserId)
        else
            CustomerBillLine.SetRange("Recalled by", '***');

        if not CustomerBillLine.FindFirst() then
            Error(Text1130006);

        Window.Open(Text1130007 +
          Text1130008 +
          Text1130009 +
          Text1130010);

        repeat
            CustLedgEntry2.Get(CustomerBillLine."Customer Entry No.");
            if CustLedgEntry2."Bank Receipt Temp. No." <> CustomerBillLine."Temporary Cust. Bill No." then
                Error(Text1130013, CustomerBillLine."Temporary Cust. Bill No.");

            CustLedgEntry.Reset();
            CustLedgEntry.SetCurrentKey("Customer No.",
              "Document No.",
              "Document Type",
              "Document Type to Close",
              "Document No. to Close",
              "Document Occurrence to Close");
            CustLedgEntry.SetRange("Customer No.", CustLedgEntry2."Customer No.");
            CustLedgEntry.SetRange("Document No.", CustLedgEntry2."Bank Receipt Temp. No.");
            CustLedgEntry.SetRange("Document Type", CustLedgEntry2."Document Type"::Payment);
            CustLedgEntry.SetRange("Document Type to Close", CustLedgEntry2."Document Type");
            CustLedgEntry.SetRange("Document No. to Close", CustLedgEntry2."Document No.");
            CustLedgEntry.SetRange("Document Occurrence to Close", CustLedgEntry2."Document Occurrence");

            if not CustLedgEntry.FindFirst() then
                Error(Text1130015);

            if not CustLedgEntry.Open then
                Error(Text1130014, CustLedgEntry."Entry No.");

            Window.Update(1, CustLedgEntry."Customer No.");
            Window.Update(2, CustLedgEntry."Document No.");

            InitGenJnlLine(Bill."Bills for Coll. Temp. Acc. No.");
            // Invoice
            CustLedgEntry2."Allow Issue" := false;
            CustLedgEntry2."Bank Receipt Issued" := false;
            CustLedgEntry2."Bank Receipt Temp. No." := '';
            CustLedgEntry2.Modify();

            // Payment
            CustLedgEntry."Allow Issue" := false;
            CustLedgEntry."Bank Receipt Issued" := false;
            CustLedgEntry."Bank Receipt Temp. No." := GenJnlLine."Document No.";
            CustLedgEntry.Modify();

            GenJnlPostLine.RunWithCheck(GenJnlLine);

            BankReceiptToIssue := BankReceiptToIssue + 1;
            CustomerBillLine.Delete();
        until CustomerBillLine.Next() = 0;

        Window.Close();

        Message(Text1130023, BankReceiptToIssue);
    end;

    var
        PaymentMethod: Record "Payment Method";
        GenJnlLine: Record "Gen. Journal Line";
        CustomerBillLine: Record "Customer Bill Line";
        Text1130001: Label 'Do you want to recall the bills?';
        CustLedgEntry: Record "Cust. Ledger Entry";
        CustLedgEntry2: Record "Cust. Ledger Entry";
        Bill: Record Bill;
        SalesSetup: Record "Sales & Receivables Setup";
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
        Window: Dialog;
        Text1130006: Label 'There is nothing to recall.';
        Text1130007: Label 'Recalling Customer Bill...\\';
        Text1130008: Label 'Customer               #1###############\';
        Text1130009: Label 'Document No.           #2###############\';
        Text1130010: Label 'Bank Receipt Temp. No. #3###############';
        Text1130013: Label 'Customer Bill %1 has been already recalled.';
        Text1130014: Label 'Customer Entry No. %1 must be open.';
        Text1130015: Label 'Customer Payment Entry cannot be found.';
        BankReceiptToIssue: Integer;
        Text1130023: Label '%1 bills have been recalled.';
        Text1130024: Label 'Please specify account no. for %1 in %2 table for method %3 in the bank %4.';
        Text1130025: Label 'Customer Bill %1 already recalled or dishonored.';
        Text1130026: Label 'Entry No. %1 must be open.';
        BillsRecalledMsg: Label '%1 bills have been recalled.';

    [Scope('OnPrem')]
    procedure InitGenJnlLine(AccountNo: Code[20])
    begin
        GenJnlLine.Init();
        GenJnlLine.Validate("Posting Date", WorkDate());
        GenJnlLine."Document Date" := WorkDate();
        GenJnlLine."Document Type" := GenJnlLine."Document Type"::" ";
        GenJnlLine."Document No." := CustLedgEntry."Document No.";

        Window.Update(3, GenJnlLine."Document No.");

        GenJnlLine."External Document No." := CustLedgEntry."External Document No.";
        GenJnlLine."Account Type" := GenJnlLine."Account Type"::Customer;
        GenJnlLine.Validate("Account No.", CustLedgEntry."Customer No.");
        GenJnlLine."Bal. Account Type" := GenJnlLine."Bal. Account Type"::"G/L Account";
        GenJnlLine.Validate("Bal. Account No.", AccountNo);
        GenJnlLine.Description := SalesSetup."Recall Bill Description";
        GenJnlLine."Source Code" := CustLedgEntry."Source Code";
        GenJnlLine."Reason Code" := CustLedgEntry."Reason Code";
        GenJnlLine."Shortcut Dimension 1 Code" := CustLedgEntry."Global Dimension 1 Code";
        GenJnlLine."Shortcut Dimension 2 Code" := CustLedgEntry."Global Dimension 2 Code";
        GenJnlLine."Dimension Set ID" := CustLedgEntry."Dimension Set ID";

        CustLedgEntry.CalcFields("Remaining Amount");
        GenJnlLine.Amount := -CustLedgEntry."Remaining Amount";
        GenJnlLine.Validate("Currency Code", CustLedgEntry."Currency Code");
        GenJnlLine."Amount (LCY)" := -CustLedgEntry."Remaining Amt. (LCY)";
        GenJnlLine."Allow Application" := true;
        GenJnlLine."Bank Receipt" := CustLedgEntry."Bank Receipt";
        GenJnlLine."Applies-to Doc. Type" := CustLedgEntry."Document Type";
        GenJnlLine."Applies-to Doc. No." := CustLedgEntry."Document No.";
        GenJnlLine."Applies-to Occurrence No." := CustLedgEntry."Document Occurrence";
        GenJnlLine."Document Type to Close" := CustLedgEntry."Document Type to Close";
        GenJnlLine."Document No. to Close" := CustLedgEntry."Document No. to Close";
        GenJnlLine."Document Occurrence to Close" := CustLedgEntry."Document Occurrence to Close";
        OnAfterInitGenJnlLine(GenJnlLine, CustLedgEntry, AccountNo);
    end;

    [Scope('OnPrem')]
    procedure RecallIssuedBill(var IssuedCustomerBillLine: Record "Issued Customer Bill Line")
    var
        IssuedCustomerBillLine2: Record "Issued Customer Bill Line";
        IssuedCustomerBillHeader: Record "Issued Customer Bill Header";
        BillPostingGroup: Record "Bill Posting Group";
        BalanceAccountNo: Code[20];
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeRecallIssuedBill(IssuedCustomerBillLine, IsHandled);
        if IsHandled then
            exit;

        SalesSetup.Get();
        IssuedCustomerBillHeader.Get(IssuedCustomerBillLine."Customer Bill No.");
        GetBillCode(IssuedCustomerBillHeader."Payment Method Code");

        if not Confirm(Text1130001) then
            exit;

        BankReceiptToIssue := 0;
        IssuedCustomerBillLine2.Copy(IssuedCustomerBillLine);
        IssuedCustomerBillLine.SetRange("Recall Date", 0D);

        if UserId <> '' then
            IssuedCustomerBillLine.SetRange("Recalled by", UserId)
        else
            IssuedCustomerBillLine.SetRange("Recalled by", '***');

        if IssuedCustomerBillLine.FindFirst() then begin
            Window.Open(Text1130007 +
              Text1130008 +
              Text1130009 +
              Text1130010);

            BillPostingGroup.Get(IssuedCustomerBillHeader."Bank Account No.", IssuedCustomerBillHeader."Payment Method Code");

            case IssuedCustomerBillHeader.Type of
                IssuedCustomerBillHeader.Type::"Bills For Collection":
                    BalanceAccountNo := BillPostingGroup."Bills For Collection Acc. No.";
                IssuedCustomerBillHeader.Type::"Bills For Discount":
                    BalanceAccountNo := BillPostingGroup."Bills For Discount Acc. No.";
                IssuedCustomerBillHeader.Type::"Bills Subject To Collection":
                    BalanceAccountNo := BillPostingGroup."Bills Subj. to Coll. Acc. No.";
            end;

            if BalanceAccountNo = '' then
                Error(Text1130024, IssuedCustomerBillHeader.Type,
                  BillPostingGroup.TableCaption(), IssuedCustomerBillHeader."Payment Method Code", IssuedCustomerBillHeader."Bank Account No.");

            repeat
                CustLedgEntry2.Get(IssuedCustomerBillLine."Customer Entry No.");
                if CustLedgEntry2."Customer Bill No." <> IssuedCustomerBillLine."Final Cust. Bill No." then
                    Error(Text1130025, IssuedCustomerBillLine."Final Cust. Bill No.");

                CustLedgEntry.Reset();
                CustLedgEntry.SetFilter("Customer No.", CustLedgEntry2."Customer No.");
                if CustLedgEntry2."Allow Issue" then
                    CustLedgEntry.SetRange("Document No.", CustLedgEntry2."Bank Receipt Temp. No.");
                CustLedgEntry.SetRange("Document Type", CustLedgEntry2."Document Type"::Payment);
                CustLedgEntry.SetRange("Document Type to Close", CustLedgEntry2."Document Type");
                CustLedgEntry.SetFilter("Document No. to Close", CustLedgEntry2."Document No.");
                CustLedgEntry.SetRange("Document Occurrence to Close", CustLedgEntry2."Document Occurrence");
                CustLedgEntry.SetRange(Open, false);
                if CustLedgEntry.FindFirst() then
                    Error(Text1130026, CustLedgEntry."Entry No.");

                CustLedgEntry.SetRange(Open, true);
                CustLedgEntry.FindFirst();

                Window.Update(1, CustLedgEntry."Customer No.");
                Window.Update(2, CustLedgEntry."Document No.");

                CustLedgEntry."Allow Issue" := false;
                CustLedgEntry."Bank Receipt Issued" := true;
                CustLedgEntry."Bank Receipt Temp. No." := CustLedgEntry."Document No.";
                CustLedgEntry."Customer Bill No." := CustLedgEntry2."Customer Bill No.";
                CustLedgEntry."Bank Receipts List No." := CustLedgEntry2."Bank Receipts List No.";
                CustLedgEntry."Document Occurrence" := CustLedgEntry2."Document Occurrence";
                CustLedgEntry.Modify();

                InitGenJnlLine(BalanceAccountNo);
                OnRecallIssuedBillOnAfterInitGenJnlLine(GenJnlLine, BillPostingGroup, IssuedCustomerBillHeader, IssuedCustomerBillLine, CustLedgEntry2);

                CustLedgEntry2."Allow Issue" := false;
                CustLedgEntry2."Bank Receipt Issued" := false;
                CustLedgEntry2."Bank Receipt Temp. No." := '';
                CustLedgEntry2."Customer Bill No." := '';
                CustLedgEntry2."Bank Receipts List No." := '';
                CustLedgEntry2.Modify();

                Window.Update(3, GenJnlLine."Document No.");

                GenJnlPostLine.RunWithCheck(GenJnlLine);

                BankReceiptToIssue := BankReceiptToIssue + 1;
                IssuedCustomerBillLine."Recall Date" := WorkDate();
                IssuedCustomerBillLine.Modify();
            until IssuedCustomerBillLine.Next() = 0;

            Message(BillsRecalledMsg, BankReceiptToIssue);
            Window.Close();
        end else
            Message(Text1130006);

        IssuedCustomerBillLine.SetRange("Recalled by");
        IssuedCustomerBillLine.SetRange("Recall Date");
        IssuedCustomerBillLine.Copy(IssuedCustomerBillLine2);
    end;

    [Scope('OnPrem')]
    procedure GetBillCode(PaymentMethodCode: Code[20])
    var
        BillCode: Record Bill;
    begin
        PaymentMethod.Get(PaymentMethodCode);
        BillCode.Get(PaymentMethod."Bill Code");
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitGenJnlLine(var GenJournalLine: Record "Gen. Journal Line"; var CustLedgerEntry: Record "Cust. Ledger Entry"; var AccountNo: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnRun(var CustomerBillHeader: Record "Customer Bill Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRecallIssuedBill(var IssuedCustomerBillLine: Record "Issued Customer Bill Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRecallIssuedBillOnAfterInitGenJnlLine(var GenJournalLine: Record "Gen. Journal Line"; BillPostingGroup: Record "Bill Posting Group"; IssuedCustomerBillHeader: Record "Issued Customer Bill Header"; var IssuedCustomerBillLine: Record "Issued Customer Bill Line"; var CustLedgerEntry2: Record "Cust. Ledger Entry")
    begin
    end;
}

