// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.DirectDebit;

using Microsoft.Bank.BankAccount;
using Microsoft.Bank.Payment;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Foundation.Enums;

codeunit 12177 "SEPA - DD Export Mgt."
{

    trigger OnRun()
    begin
    end;

    [Scope('OnPrem')]
    procedure ExportBillToFile(CustomerBillNo: Code[20]; BankAccountNo: Code[20]; PartnerType: Option; SourceTableID: Integer)
    var
        BankAccount: Record "Bank Account";
        DirectDebitCollection: Record "Direct Debit Collection";
        DirectDebitCollectionEntry: Record "Direct Debit Collection Entry";
    begin
        BankAccount.Get(BankAccountNo);
        DirectDebitCollection.CreateRecord(CustomerBillNo, BankAccountNo, Enum::"Partner Type".FromInteger(PartnerType));
        DirectDebitCollection."Source Table ID" := SourceTableID;
        DirectDebitCollection.Modify();
        DirectDebitCollectionEntry.SetRange("Direct Debit Collection No.", DirectDebitCollection."No.");
        DeleteExportErrors(CustomerBillNo, Format(SourceTableID));
        Commit();
        RunFileExportCodeunit(BankAccount.GetDDExportCodeunitID(), DirectDebitCollection."No.", DirectDebitCollectionEntry);
        DeleteDirectDebitCollection(DirectDebitCollection."No.");
    end;

    [Scope('OnPrem')]
    procedure RunFileExportCodeunit(CodeunitID: Integer; DirectDebitCollectionNo: Integer; var DirectDebitCollectionEntry: Record "Direct Debit Collection Entry")
    var
        LastError: Text;
    begin
        if CODEUNIT.Run(CodeunitID, DirectDebitCollectionEntry) then begin
            DeleteDirectDebitCollection(DirectDebitCollectionNo);
            exit;
        end;

        LastError := GetLastErrorText;
        DeleteDirectDebitCollection(DirectDebitCollectionNo);
        Commit();
        Error(LastError);
    end;

    [Scope('OnPrem')]
    procedure DeleteDirectDebitCollection(DirectDebitCollectionNo: Integer)
    var
        DirectDebitCollection: Record "Direct Debit Collection";
    begin
        if DirectDebitCollection.Get(DirectDebitCollectionNo) then
            DirectDebitCollection.Delete(true);
    end;

    [Scope('OnPrem')]
    procedure CheckBillHeader(PaymentMethodCode: Code[10])
    var
        Bill: Record Bill;
        PaymentMethod: Record "Payment Method";
    begin
        PaymentMethod.Get(PaymentMethodCode);
        Bill.Get(PaymentMethod."Bill Code");
        Bill.TestField("Bank Receipt", true);
    end;

    [Scope('OnPrem')]
    procedure DeleteExportErrors(CustomerBillNo: Code[20]; SourceTable: Text[10])
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        GenJnlLine."Journal Template Name" := '';
        GenJnlLine."Journal Batch Name" := SourceTable;
        GenJnlLine."Document No." := CustomerBillNo;
        GenJnlLine.DeletePaymentFileBatchErrors();
    end;
}

