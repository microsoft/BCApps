// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Registration;

using Microsoft.Purchases.Vendor;

codeunit 31032 "Unrel. Account - Vendor CZL" implements "Unreliable Account CZL"
{
    var
        VATRegNoMismatchErr: Label 'The VAT registration number of %1 %2 does not match the VAT registration number %3 of the entry.', Comment = '%1 = Partner table caption, %2 = Partner number, %3 = Entry VAT registration number';
        BankAccountExistsErr: Label '%1 %2 already exists.', Comment = '%1 = Bank account table caption, %2 = Bank account code';
        BankAccountNoTooLongErr: Label 'The bank account number must not exceed %1 characters.', Comment = '%1 = Maximum bank account number length';

    procedure CreateBankAccount(UnreliablePayerEntryCZL: Record "Unreliable Payer Entry CZL"; AccountNo: Code[20]; BankAccountCode: Code[10]; BankAccountName: Text[100]; PreferredBankAccount: Boolean): RecordId
    var
        Vendor: Record Vendor;
        VendorBankAccount: Record "Vendor Bank Account";
        UnreliablePayerMgtCZL: Codeunit "Unreliable Payer Mgt. CZL";
    begin
        UnreliablePayerEntryCZL.CheckBankAccountCreationPossible();
        Vendor.Get(AccountNo);
        if UnreliablePayerMgtCZL.GetLongVATRegNo(Vendor."VAT Registration No.") <> UnreliablePayerMgtCZL.GetLongVATRegNo(UnreliablePayerEntryCZL."VAT Registration No.") then
            Error(VATRegNoMismatchErr, Vendor.TableCaption(), AccountNo, UnreliablePayerEntryCZL."VAT Registration No.");
        CheckBankAccountNotExists(UnreliablePayerEntryCZL, AccountNo);
        VendorBankAccount.Validate("Vendor No.", AccountNo);
        VendorBankAccount.Validate(Code, BankAccountCode);
        VendorBankAccount.TestField(Code);
        VendorBankAccount.Validate(Name, BankAccountName);
        case UnreliablePayerEntryCZL."Bank Account Type" of
            UnreliablePayerEntryCZL."Bank Account Type"::Standard:
                begin
                    if StrLen(UnreliablePayerEntryCZL."Full Bank Account No.") > MaxStrLen(VendorBankAccount."Bank Account No.") then
                        Error(BankAccountNoTooLongErr, MaxStrLen(VendorBankAccount."Bank Account No."));
                    VendorBankAccount.Validate("Bank Account No.", CopyStr(UnreliablePayerEntryCZL."Full Bank Account No.", 1, MaxStrLen(VendorBankAccount."Bank Account No.")));
                end;
            UnreliablePayerEntryCZL."Bank Account Type"::"Not Standard":
                VendorBankAccount.Validate(IBAN, UnreliablePayerEntryCZL."Full Bank Account No.");
        end;
        VendorBankAccount.Insert(true);
        if PreferredBankAccount then begin
            Vendor.Validate("Preferred Bank Account Code", BankAccountCode);
            Vendor.Modify(true);
        end;
        exit(VendorBankAccount.RecordId());
    end;

    procedure CheckBankAccountNotExists(UnreliablePayerEntryCZL: Record "Unreliable Payer Entry CZL"; AccountNo: Code[20])
    var
        VendorBankAccount: Record "Vendor Bank Account";
    begin
        VendorBankAccount.SetRange("Vendor No.", AccountNo);
        case UnreliablePayerEntryCZL."Bank Account Type" of
            UnreliablePayerEntryCZL."Bank Account Type"::Standard:
                VendorBankAccount.SetRange("Bank Account No.", UnreliablePayerEntryCZL."Full Bank Account No.");
            UnreliablePayerEntryCZL."Bank Account Type"::"Not Standard":
                VendorBankAccount.SetRange(IBAN, UnreliablePayerEntryCZL."Full Bank Account No.");
        end;
        if VendorBankAccount.FindFirst() then
            Error(BankAccountExistsErr, VendorBankAccount.TableCaption(), VendorBankAccount.Code);
    end;
}