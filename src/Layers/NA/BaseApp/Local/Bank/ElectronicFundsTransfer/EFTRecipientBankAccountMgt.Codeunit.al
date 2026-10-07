// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.ElectronicFundsTransfer;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;

codeunit 10200 "EFT Recipient Bank Account Mgt"
{
    var
        NotVendorAccountErr: Label 'The account type or balance account type should be vendor on the following General Journal Line: Journal Template Name = %1, Line No. = %2.', Comment = '%1=Journal Template Name, %2=Line Number';
        NotCustomerAccountErr: Label 'The account type or balance account type should be customer on the following General Journal Line: Journal Template Name = %1, Line No. = %2.', Comment = '%1=Journal Template Name, %2=Line Number';
        EmptyRecipientBankAccountErr: Label 'The recepient bank account cannot be empty on the following General Journal Line: Journal Batch Name: %1, Journal Template Name: %2, Line No.: %3.', Comment = '%1=Journal Batch Name, %2=Journal Template Name, %3=Line Number';
        InvalidRecepientBankAccountErr: Label 'Invalid recepient bank account on the following General Journal Line: Journal Template Name = %1, Line No. = %2.', Comment = '%1=Journal Template Name, %2=Line Number';
        InvalidVendorBankAccountErr: Label 'This vendor bank account cannot be used for electronic payments: Vendor No. = %1, Code = %2.', Comment = '%1=Vendor Number, %2=Code property';
        InvalidCustomerBankAccountErr: Label 'This customer bank account cannot be used for electronic payments: Customer No. = %1, Code = %2.', Comment = '%1=Customer Number, %2=Code property';
        GenJnlLineDoesNotExistErr: Label 'The General Journal Line with Journal Template Name %1, Journal Batch Name %2 and Line No. %3 does not exist.', Comment = '%1=Journal Template Name, %2=Journal Batch Name, %3=Line Number';

    procedure GetRecipientVendorBankAccount(var VendBankAccount: Record "Vendor Bank Account"; var TempEFTExportWorkset: Record "EFT Export Workset" temporary; VendorNo: Code[20])
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        GetGenJournalLine(GenJournalLine, TempEFTExportWorkset);

        GetRecipientVendorBankAccount(VendBankAccount, GenJournalLine, VendorNo);
    end;

    procedure GetRecipientVendorBankAccount(var VendBankAccount: Record "Vendor Bank Account"; GenJnlLine: Record "Gen. Journal Line"; VendorNo: Code[20])
    begin
        ValidateAccountType(GenJnlLine, GenJnlLine."Account Type"::Vendor, NotVendorAccountErr);

        ValidateRecipientBankAccount(GenJnlLine);

        if not VendBankAccount.Get(VendorNo, GenJnlLine."Recipient Bank Account") then
            Error(InvalidRecepientBankAccountErr, GenJnlLine."Journal Template Name", GenJnlLine."Line No.");

        if not VendBankAccount."Use for Electronic Payments" then
            Error(InvalidVendorBankAccountErr, VendBankAccount."Vendor No.", VendBankAccount.Code);
    end;

    procedure GetRecipientCustomerBankAccount(var CustBankAccount: Record "Customer Bank Account"; var TempEFTExportWorkset: Record "EFT Export Workset" temporary; CustomerNo: Code[20])
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        GetGenJournalLine(GenJournalLine, TempEFTExportWorkset);

        GetRecipientCustomerBankAccount(CustBankAccount, GenJournalLine, CustomerNo);
    end;

    procedure GetRecipientCustomerBankAccount(var CustBankAccount: Record "Customer Bank Account"; GenJnlLine: Record "Gen. Journal Line"; CustomerNo: Code[20])
    begin
        ValidateAccountType(GenJnlLine, GenJnlLine."Account Type"::Customer, NotCustomerAccountErr);

        ValidateRecipientBankAccount(GenJnlLine);

        if not CustBankAccount.Get(CustomerNo, GenJnlLine."Recipient Bank Account") then
            Error(InvalidRecepientBankAccountErr, GenJnlLine."Journal Template Name", GenJnlLine."Line No.");

        if not CustBankAccount."Use for Electronic Payments" then
            Error(InvalidCustomerBankAccountErr, CustBankAccount."Customer No.", CustBankAccount.Code);
    end;

    local procedure ValidateAccountType(GenJnlLine: Record "Gen. Journal Line"; AccountType: Enum "Gen. Journal Account Type"; ErrorMsg: Text)
    begin
        if (GenJnlLine."Account Type" <> AccountType) and (GenJnlLine."Bal. Account Type" <> AccountType) then
            Error(ErrorMsg, GenJnlLine."Journal Template Name", GenJnlLine."Line No.");
    end;

    local procedure ValidateRecipientBankAccount(GenJnlLine: Record "Gen. Journal Line")
    begin
        if GenJnlLine."Recipient Bank Account" = '' then
            Error(EmptyRecipientBankAccountErr, GenJnlLine."Journal Batch Name",
                GenJnlLine."Journal Template Name", GenJnlLine."Line No.");
    end;

    local procedure GetGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; var TempEFTExportWorkset: Record "EFT Export Workset" temporary)
    begin
        GenJournalLine.SetRange("Journal Template Name", TempEFTExportWorkset."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", TempEFTExportWorkset."Journal Batch Name");
        GenJournalLine.SetRange("Line No.", TempEFTExportWorkset."Line No.");

        if not GenJournalLine.FindFirst() then
            Error(GenJnlLineDoesNotExistErr, TempEFTExportWorkset."Journal Template Name",
                TempEFTExportWorkset."Journal Batch Name", TempEFTExportWorkset."Line No.");
    end;

}
