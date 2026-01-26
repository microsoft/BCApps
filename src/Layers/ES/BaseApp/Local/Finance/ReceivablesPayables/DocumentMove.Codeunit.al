// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.ReceivablesPayables;

using Microsoft.Bank.BankAccount;
using Microsoft.Foundation.Period;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.History;
using Microsoft.Sales.Receivables;

codeunit 7000004 "Document-Move"
{
    Permissions = TableData "Closed Cartera Doc." = imd,
                  TableData "Closed Bill Group" = imd,
                  TableData "Closed Payment Order" = imd;

    trigger OnRun()
    begin
    end;

    var
        Text1100000: Label 'You cannot delete a bank account with bill groups in preparation.';
        Text1100001: Label 'You cannot delete a bank account with bill groups.';
        Text1100002: Label 'You cannot delete a bank account with closed bill groups in a fiscal year that has not been closed yet.';
        Text1100003: Label 'You cannot delete a bank account with payment orders in preparation.';
        Text1100004: Label 'You cannot delete a bank account with payment orders.';
        Text1100005: Label 'You cannot delete a bank account with closed payment orders in a fiscal year that has not been closed yet.';
        AccountingPeriod: Record "Accounting Period";
        BillGr: Record "Bill Group";
        BillGr2: Record "Bill Group";
        PostedBillGr: Record "Posted Bill Group";
        PostedBillGr2: Record "Posted Bill Group";
        ClosedBillGr: Record "Closed Bill Group";
        ClosedBillGr2: Record "Closed Bill Group";
        ClosedDoc: Record "Closed Cartera Doc.";
        PmtOrd: Record "Payment Order";
        PmtOrd2: Record "Payment Order";
        PostedPmtOrd: Record "Posted Payment Order";
        PostedPmtOrd2: Record "Posted Payment Order";
        ClosedPmtOrd: Record "Closed Payment Order";
        ClosedPmtOrd2: Record "Closed Payment Order";

    [Scope('OnPrem')]
    procedure MoveBankAccDocs(BankAcc: Record "Bank Account")
    begin
        BillGr.LockTable();
        if BillGr2.FindLast() then;
        BillGr.Reset();
        BillGr.SetCurrentKey("Bank Account No.");
        BillGr.SetRange("Bank Account No.", BankAcc."No.");
        if BillGr.FindFirst() then
            Error(Text1100000);

        PostedBillGr.LockTable();
        if PostedBillGr2.FindLast() then;
        PostedBillGr.Reset();
        PostedBillGr.SetCurrentKey("Bank Account No.");
        PostedBillGr.SetRange("Bank Account No.", BankAcc."No.");
        if PostedBillGr.FindFirst() then
            Error(Text1100001);

        ClosedBillGr.LockTable();
        if ClosedBillGr2.FindLast() then;
        ClosedBillGr.Reset();
        ClosedBillGr.SetCurrentKey("Bank Account No.");
        ClosedBillGr.SetRange("Bank Account No.", BankAcc."No.");
        AccountingPeriod.SetRange(Closed, false);
        if AccountingPeriod.FindFirst() then
            ClosedBillGr.SetFilter("Closing Date", '>=%1', AccountingPeriod."Starting Date");
        if ClosedBillGr.FindFirst() then
            Error(Text1100002);
        ClosedBillGr.SetRange("Closing Date");
        ClosedBillGr.ModifyAll("Bank Account No.", '');

        PmtOrd.LockTable();
        if PmtOrd2.FindLast() then;
        PmtOrd.Reset();
        PmtOrd.SetCurrentKey("Bank Account No.");
        PmtOrd.SetRange("Bank Account No.", BankAcc."No.");
        if PmtOrd.FindFirst() then
            Error(Text1100003);

        PostedPmtOrd.LockTable();
        if PostedPmtOrd2.FindLast() then;
        PostedPmtOrd.Reset();
        PostedPmtOrd.SetCurrentKey("Bank Account No.");
        PostedPmtOrd.SetRange("Bank Account No.", BankAcc."No.");
        if PostedPmtOrd.FindFirst() then
            Error(Text1100004);

        ClosedPmtOrd.LockTable();
        if ClosedPmtOrd2.FindLast() then;
        ClosedPmtOrd.Reset();
        ClosedPmtOrd.SetCurrentKey("Bank Account No.");
        ClosedPmtOrd.SetRange("Bank Account No.", BankAcc."No.");
        AccountingPeriod.SetRange(Closed, false);
        if AccountingPeriod.FindFirst() then
            ClosedPmtOrd.SetFilter("Closing Date", '>=%1', AccountingPeriod."Starting Date");
        if ClosedPmtOrd.FindFirst() then
            Error(Text1100005);
        ClosedPmtOrd.SetRange("Closing Date");
        ClosedPmtOrd.ModifyAll("Bank Account No.", '');
    end;

    [Scope('OnPrem')]
    procedure MoveReceivableDocs(Cust: Record Customer)
    begin
        ClosedDoc.Reset();
        ClosedDoc.SetCurrentKey("Account No.", "Honored/Rejtd. at Date");
        ClosedDoc.SetRange("Account No.", Cust."No.");
        ClosedDoc.ModifyAll("Account No.", '');
    end;

    [Scope('OnPrem')]
    procedure MovePayableDocs(Vend: Record Vendor)
    begin
        ClosedDoc.Reset();
        ClosedDoc.SetCurrentKey("Account No.", "Honored/Rejtd. at Date");
        ClosedDoc.SetRange("Account No.", Vend."No.");
        ClosedDoc.ModifyAll("Account No.", '');
    end;
}

