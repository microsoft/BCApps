// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using Microsoft.Bank.BankAccount;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Posting;
using Microsoft.Foundation.NoSeries;
using Microsoft.Sales.Receivables;
using Microsoft.Utilities;

codeunit 12172 "Customer Bill - Post + Print"
{
    Permissions = TableData "Cust. Ledger Entry" = rimd,
                  TableData "Detailed Cust. Ledg. Entry" = rimd;
    TableNo = "Customer Bill Header";

    trigger OnRun()
    var
        HideDialog: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOnRun(Rec, IsHandled);
        if IsHandled then
            exit;

        HideDialog := false;

        OnBeforeConfirmPost(Rec, HideDialog);
        if not HideDialog then
            if not Confirm(PostAndPrintQst, false, Rec.TableCaption(), Rec."No.") then
                exit;

        Code(Rec);
    end;

    var
        PostAndPrintQst: Label 'Do you want to post and print %1 %2?', Comment = '%1 = table caption, %2 = document no.';
        BillCode: Record Bill;
        InvalidListDateErr: Label 'The List Date must be greater than the Document Date of Customer Bill Line %1.';
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
        DocumentErrorsMgt: Codeunit "Document Errors Mgt.";
        Window: Dialog;
        Text1130012: Label 'Posting Customer Bill...\\';
        Text1130013: Label 'G/L Account       #1##################\';
        Text1130014: Label 'Customer Bill No. #2##################\';
        Text1130015: Label 'Bank Receipt No.  #3##################\';
        BRNumber: Code[20];
        InvalidRemainingAmountErr: Label 'The Remaining Amount has been modified for customer entry Document No.: %1, Document Occurrence: %2. The new amount is %3.', Comment = '%1 - document number, %2 - document occurence, 3 - amount.';
        ListNumber: Code[20];
        HidePrintDialog: Boolean;
        HTMLPath: Text[1024];
        Text12100: Label 'is not within your range of allowed posting dates';

    [Scope('OnPrem')]
    procedure "Code"(var LocalCustomerBillHeader: Record "Customer Bill Header")
    var
        CustomerBillHeader: Record "Customer Bill Header";
        CustomerBillLine: Record "Customer Bill Line";
        IssuedCustBillHeader: Record "Issued Customer Bill Header";
        CustLedgEntry: Record "Cust. Ledger Entry";
        OldCustBillLine: Record "Customer Bill Line";
        BankAcc: Record "Bank Account";
        BillPostingGroup: Record "Bill Posting Group";
        NoSeries: Codeunit "No. Series";
        BalanceAmount: Decimal;
    begin
        CustomerBillHeader.Copy(LocalCustomerBillHeader);

        OnBeforePost(CustomerBillHeader);

        CheckCustBill(CustomerBillHeader);

        BankAcc.Get(CustomerBillHeader."Bank Account No.");
        BillPostingGroup.Get(CustomerBillHeader."Bank Account No.", CustomerBillHeader."Payment Method Code");

        case CustomerBillHeader.Type of
            CustomerBillHeader.Type::"Bills For Collection":
                BillPostingGroup.TestField("Bills For Collection Acc. No.");
            CustomerBillHeader.Type::"Bills For Discount":
                BillPostingGroup.TestField("Bills For Discount Acc. No.");
            CustomerBillHeader.Type::"Bills Subject To Collection":
                BillPostingGroup.TestField("Bills Subj. to Coll. Acc. No.");
        end;

        Window.Open(
          Text1130012 + Text1130013 + Text1130014 + Text1130015);

        CustomerBillHeader."Test Report" := false;
        ListNumber := NoSeries.GetNextNo(BillCode."List No.", CustomerBillHeader."List Date");
        CustomerBillHeader.Modify();

        CustomerBillLine.SetRange("Customer Bill No.", CustomerBillHeader."No.");
        CustomerBillLine.SetCurrentKey("Customer No.", "Due Date", "Customer Bank Acc. No.", "Cumulative Bank Receipts");
        if CustomerBillLine.FindSet() then begin
            InsertIssuedBillHeader(IssuedCustBillHeader, CustomerBillHeader, BillCode, ListNumber);

            OldCustBillLine := CustomerBillLine;
            CustLedgEntry.LockTable();
            BalanceAmount := 0;
            BRNumber := NoSeries.GetNextNo(BillCode."Final Bill No.", CustomerBillHeader."List Date");
            repeat
                CustomerBillLine.TestField(Amount);
                if CustomerBillLine."Document Date" > CustomerBillHeader."List Date" then
                    Error(InvalidListDateErr, CustomerBillLine."Line No.");
                CustomerBillLine.TestField("Due Date");

                if (OldCustBillLine."Customer No." <> CustomerBillLine."Customer No.") or
                   (OldCustBillLine."Due Date" <> CustomerBillLine."Due Date") or
                   (OldCustBillLine."Customer Bank Acc. No." <> CustomerBillLine."Customer Bank Acc. No.") or
                   (OldCustBillLine."Cumulative Bank Receipts" <> CustomerBillLine."Cumulative Bank Receipts")
                then
                    if OldCustBillLine."Cumulative Bank Receipts" then
                        BRNumber := NoSeries.GetNextNo(BillCode."Final Bill No.", CustomerBillHeader."List Date");

                UpdateCustLedgEntry(CustLedgEntry, CustomerBillLine);

                BalanceAmount := BalanceAmount + CustomerBillLine.Amount;

                PostCustBillLine(CustomerBillHeader, CustomerBillLine, CustLedgEntry);

                InsertIssuedBillLine(CustomerBillLine, ListNumber, BRNumber);

                if not CustomerBillLine."Cumulative Bank Receipts" then
                    BRNumber := NoSeries.GetNextNo(BillCode."Final Bill No.", CustomerBillHeader."List Date");

                OldCustBillLine := CustomerBillLine;
            until CustomerBillLine.Next() = 0;
            PostBalanceAccount(CustomerBillHeader, CustLedgEntry, BillPostingGroup, BalanceAmount);

            CustomerBillLine.DeleteAll(true);
            CustomerBillHeader.Delete(true);

            Window.Close();
            Commit();

            OnAfterPost(CustomerBillHeader, IssuedCustBillHeader);

            IssuedCustBillHeader.SetRecFilter();
            if HidePrintDialog then
                REPORT.SaveAsPdf(REPORT::"Issued Cust Bills Report", HTMLPath, IssuedCustBillHeader)
            else
                REPORT.RunModal(REPORT::"Issued Cust Bills Report", false, false, IssuedCustBillHeader);
        end else
            Error(DocumentErrorsMgt.GetNothingToPostErrorMsg());
    end;

    local procedure CheckCustBill(CustomerBillHeader: Record "Customer Bill Header")
    var
        PaymentMethod: Record "Payment Method";
    begin
        CustomerBillHeader.TestField(Type);
        CustomerBillHeader.TestField("Bank Account No.");
        CustomerBillHeader.TestField("List Date");
        CustomerBillHeader.TestField("Posting Date");
        CustomerBillHeader.TestField("Payment Method Code");

        PaymentMethod.Get(CustomerBillHeader."Payment Method Code");
        BillCode.Get(PaymentMethod."Bill Code");

        BillCode.TestField("List No.");
        BillCode.TestField("Final Bill No.");
        if BillCode."Allow Issue" then
            BillCode.TestField("Bills for Coll. Temp. Acc. No.");
    end;

    local procedure InsertIssuedBillHeader(var IssuedCustBillHeader: Record "Issued Customer Bill Header"; CustomerBillHeader: Record "Customer Bill Header"; BillCode: Record Bill; ListNo: Code[20])
    begin
        IssuedCustBillHeader.Init();
        IssuedCustBillHeader.TransferFields(CustomerBillHeader);
        IssuedCustBillHeader."No. Series" := BillCode."List No.";
        IssuedCustBillHeader."No." := ListNo;
        IssuedCustBillHeader."User ID" := UserId;
        IssuedCustBillHeader.Insert();
    end;

    local procedure InsertIssuedBillLine(CustomerBillLine: Record "Customer Bill Line"; ListNo: Code[20]; FinalBillNo: Code[20])
    var
        IssuedCustBillLine: Record "Issued Customer Bill Line";
    begin
        IssuedCustBillLine.Init();
        IssuedCustBillLine.TransferFields(CustomerBillLine);
        IssuedCustBillLine."Customer Bill No." := ListNo;
        IssuedCustBillLine."Final Cust. Bill No." := FinalBillNo;
        OnInsertIssuedBillLineOnBeforeInsert(IssuedCustBillLine);
        IssuedCustBillLine.Insert();
    end;

    [Scope('OnPrem')]
    procedure PostCustBillLine(CustomerBillHeader: Record "Customer Bill Header"; CustomerBillLine: Record "Customer Bill Line"; CustLedgEntry: Record "Cust. Ledger Entry")
    var
        GenJnlLine: Record "Gen. Journal Line";
        GenJnlCheckLine: Codeunit "Gen. Jnl.-Check Line";
    begin
        GenJnlLine.Init();

        GenJnlLine.Validate("Posting Date", CustomerBillHeader."Posting Date");
        GenJnlLine."Document Date" := CustomerBillHeader."List Date";

        if GenJnlCheckLine.DateNotAllowed(GenJnlLine."Posting Date") then
            GenJnlLine.FieldError("Posting Date", Text12100);

        if BillCode."Allow Issue" then begin
            GenJnlLine."Account Type" := GenJnlLine."Account Type"::"G/L Account";
            GenJnlLine.Validate("Account No.", BillCode."Bills for Coll. Temp. Acc. No.");
            GenJnlLine.Description := 'Cli ' + CustomerBillLine."Customer No." + ' Rif. ' + BRNumber;
        end else begin
            GenJnlLine."Account Type" := GenJnlLine."Account Type"::Customer;
            GenJnlLine.Validate("Account No.", CustomerBillLine."Customer No.");
            GenJnlLine."Due Date" := CustomerBillLine."Due Date";
            GenJnlLine."Document Type" := GenJnlLine."Document Type"::Payment;
            GenJnlLine.Description := 'Cli ' + CustomerBillLine."Customer No." + ' Ft. ' + CustLedgEntry."Document No.";
            GenJnlLine."External Document No." := CustLedgEntry."External Document No.";
            GenJnlLine."Bank Receipt" := true;
            GenJnlLine."Document Type to Close" := CustLedgEntry."Document Type";
            GenJnlLine."Document No. to Close" := CustLedgEntry."Document No.";
            GenJnlLine."Document Occurrence to Close" := CustLedgEntry."Document Occurrence";
            GenJnlLine."Allow Issue" := CustLedgEntry."Allow Issue";
        end;

        GenJnlLine."Document No." := ListNumber;

        Window.Update(1, GenJnlLine."Account No.");
        Window.Update(2, GenJnlLine."Document No.");
        Window.Update(3, BRNumber);

        GenJnlLine.Validate(Amount, -CustomerBillLine.Amount);
        GenJnlLine."Reason Code" := CustomerBillHeader."Reason Code";
        GenJnlLine."Source Code" := BillCode."Bill Source Code";
        GenJnlLine."Shortcut Dimension 1 Code" := CustLedgEntry."Global Dimension 1 Code";
        GenJnlLine."Shortcut Dimension 2 Code" := CustLedgEntry."Global Dimension 2 Code";
        GenJnlLine."Dimension Set ID" := CustLedgEntry."Dimension Set ID";

        OnBeforePostCustomerBillLine(GenJnlLine, CustomerBillHeader, CustomerBillLine, CustLedgEntry, GenJnlPostLine);
        GenJnlPostLine.RunWithoutCheck(GenJnlLine);
    end;

    [Scope('OnPrem')]
    procedure PostBalanceAccount(CustomerBillHeader: Record "Customer Bill Header"; CustLedgEntry: Record "Cust. Ledger Entry"; BillPostingGroup: Record "Bill Posting Group"; BalanceAmount: Decimal)
    var
        GenJnlLine: Record "Gen. Journal Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePostBalanceAccount(GenJnlLine, CustomerBillHeader, CustLedgEntry, BalanceAmount, IsHandled);
        if IsHandled then
            exit;

        GenJnlLine.Init();

        GenJnlLine.Validate("Posting Date", CustomerBillHeader."Posting Date");
        GenJnlLine."Document Type" := GenJnlLine."Document Type"::" ";
        GenJnlLine."Document No." := ListNumber;
        GenJnlLine."Document Date" := CustomerBillHeader."List Date";
        GenJnlLine."Account Type" := GenJnlLine."Account Type"::"G/L Account";

        case CustomerBillHeader.Type of
            CustomerBillHeader.Type::"Bills For Collection":
                GenJnlLine.Validate("Account No.", BillPostingGroup."Bills For Collection Acc. No.");
            CustomerBillHeader.Type::"Bills For Discount":
                GenJnlLine.Validate("Account No.", BillPostingGroup."Bills For Discount Acc. No.");
            CustomerBillHeader.Type::"Bills Subject To Collection":
                GenJnlLine.Validate("Account No.", BillPostingGroup."Bills Subj. to Coll. Acc. No.");
        end;
        OnPostBalanceAccountOnAfterValidateAccountNo(GenJnlLine, BillPostingGroup, CustomerBillHeader);

        GenJnlLine.Description := CustomerBillHeader."Report Header";
        GenJnlLine.Validate(Amount, BalanceAmount);
        GenJnlLine."Reason Code" := CustomerBillHeader."Reason Code";
        GenJnlLine."Source Code" := BillCode."Bill Source Code";
        GenJnlLine."Shortcut Dimension 1 Code" := CustLedgEntry."Global Dimension 1 Code";
        GenJnlLine."Shortcut Dimension 2 Code" := CustLedgEntry."Global Dimension 2 Code";
        GenJnlLine."Dimension Set ID" := CustLedgEntry."Dimension Set ID";

        GenJnlPostLine.RunWithoutCheck(GenJnlLine);
    end;

    local procedure UpdateCustLedgEntry(var CustLedgEntry: Record "Cust. Ledger Entry"; CustomerBillLine: Record "Customer Bill Line")
    var
        DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        RbCustLedgEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgEntry.Get(CustomerBillLine."Customer Entry No.");
        CustLedgEntry.CalcFields("Remaining Amount");

        if CustLedgEntry."Remaining Amount" <> CustomerBillLine.Amount then
            Error(InvalidRemainingAmountErr,
              CustLedgEntry."Document No.",
              CustLedgEntry."Document Occurrence",
              CustLedgEntry."Remaining Amount");

        if CustLedgEntry."Due Date" <> CustomerBillLine."Due Date" then begin
            DtldCustLedgEntry.SetCurrentKey("Cust. Ledger Entry No.");
            CustLedgEntry."Due Date" := CustomerBillLine."Due Date";
            DtldCustLedgEntry.SetRange("Cust. Ledger Entry No.", CustLedgEntry."Entry No.");
            DtldCustLedgEntry.ModifyAll("Initial Entry Due Date", CustLedgEntry."Due Date");
            RbCustLedgEntry.SetCurrentKey("Customer No.", "Document No.", "Document Type",
              "Document Type to Close", "Document No. to Close", "Document Occurrence to Close");
            RbCustLedgEntry.SetRange("Customer No.", CustLedgEntry."Customer No.");
            RbCustLedgEntry.SetRange("Document No.", CustLedgEntry."Bank Receipt Temp. No.");
            RbCustLedgEntry.SetRange("Document Type", RbCustLedgEntry."Document Type"::Payment);
            RbCustLedgEntry.SetRange("Document Type to Close", CustLedgEntry."Document Type");
            RbCustLedgEntry.SetRange("Document No. to Close", CustLedgEntry."Document No.");
            RbCustLedgEntry.SetRange("Document Occurrence to Close", CustLedgEntry."Document Occurrence");
            if RbCustLedgEntry.FindFirst() then begin
                RbCustLedgEntry."Due Date" := CustomerBillLine."Due Date";
                RbCustLedgEntry.Modify();
                DtldCustLedgEntry.SetRange("Cust. Ledger Entry No.", RbCustLedgEntry."Entry No.");
                DtldCustLedgEntry.ModifyAll("Initial Entry Due Date", RbCustLedgEntry."Due Date");
            end;
        end;
        CustLedgEntry."Cumulative Bank Receipts" := CustomerBillLine."Cumulative Bank Receipts";
        CustLedgEntry."Recipient Bank Account" := CustomerBillLine."Customer Bank Acc. No.";
        CustLedgEntry."Customer Bill No." := BRNumber;
        CustLedgEntry."Bank Receipts List No." := ListNumber;
        CustLedgEntry."Bank Receipt Issued" := true;
        CustLedgEntry.Modify();
    end;

    [Scope('OnPrem')]
    procedure SetHidePrintDialog(NewHidePrintDialog: Boolean)
    begin
        OnBeforeSetHidePrintDialog(HidePrintDialog, NewHidePrintDialog);
        HidePrintDialog := NewHidePrintDialog;
    end;

    [Scope('OnPrem')]
    procedure SetHTMLPath(NewHTMLPath: Text[1024])
    begin
        HTMLPath := NewHTMLPath;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPost(var CustomerBillHeader: Record "Customer Bill Header"; var IssuedCustomerBillHeader: Record "Issued Customer Bill Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnRun(var CustomerBillHeader: Record "Customer Bill Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePost(var CustomerBillHeader: Record "Customer Bill Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeConfirmPost(var CustomerBillHeader: Record "Customer Bill Header"; var HideDialog: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostCustomerBillLine(var GenJournalLine: Record "Gen. Journal Line"; CustomerBillHeader: Record "Customer Bill Header"; CustomerBillLine: Record "Customer Bill Line"; CustLedgerEntry: Record "Cust. Ledger Entry"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetHidePrintDialog(HidePrintDialog: Boolean; var NewHidePrintDialog: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertIssuedBillLineOnBeforeInsert(var IssuedCustomerBillLine: Record "Issued Customer Bill Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostBalanceAccountOnAfterValidateAccountNo(var GenJournalLine: Record "Gen. Journal Line"; BillPostingGroup: Record "Bill Posting Group"; CustomerBillHeader: Record "Customer Bill Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostBalanceAccount(var GenJournalLine: Record "Gen. Journal Line"; CustomerBillHeader: Record "Customer Bill Header"; CustLedgerEntry: Record "Cust. Ledger Entry"; var BalanceAmount: Decimal; var IsHandled: Boolean)
    begin
    end;
}

