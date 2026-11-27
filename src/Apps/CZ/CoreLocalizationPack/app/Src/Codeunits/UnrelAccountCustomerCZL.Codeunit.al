// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Registration;

using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;

codeunit 31033 "Unrel. Account - Customer CZL" implements "Unreliable Account CZL"
{
    var
        VATRegNoMismatchErr: Label 'The VAT registration number of %1 %2 does not match the VAT registration number %3 of the entry.', Comment = '%1 = Partner table caption, %2 = Partner number, %3 = Entry VAT registration number';
        BankAccountExistsErr: Label '%1 %2 already exists.', Comment = '%1 = Bank account table caption, %2 = Bank account code';
        BankAccountNoTooLongErr: Label 'The bank account number must not exceed %1 characters.', Comment = '%1 = Maximum bank account number length';

    procedure CreateBankAccount(UnreliablePayerEntryCZL: Record "Unreliable Payer Entry CZL"; AccountNo: Code[20]; BankAccountCode: Code[10]; BankAccountName: Text[100]; PreferredBankAccount: Boolean): RecordId
    var
        Customer: Record Customer;
        CustomerBankAccount: Record "Customer Bank Account";
        UnreliablePayerMgtCZL: Codeunit "Unreliable Payer Mgt. CZL";
    begin
        UnreliablePayerEntryCZL.CheckBankAccountCreationPossible();
        Customer.Get(AccountNo);
        if UnreliablePayerMgtCZL.GetLongVATRegNo(Customer."VAT Registration No.") <> UnreliablePayerMgtCZL.GetLongVATRegNo(UnreliablePayerEntryCZL."VAT Registration No.") then
            Error(VATRegNoMismatchErr, Customer.TableCaption(), AccountNo, UnreliablePayerEntryCZL."VAT Registration No.");
        CheckBankAccountNotExists(UnreliablePayerEntryCZL, AccountNo);
        CustomerBankAccount.Validate("Customer No.", AccountNo);
        CustomerBankAccount.Validate(Code, BankAccountCode);
        CustomerBankAccount.TestField(Code);
        CustomerBankAccount.Validate(Name, BankAccountName);
        case UnreliablePayerEntryCZL."Bank Account Type" of
            UnreliablePayerEntryCZL."Bank Account Type"::Standard:
                begin
                    if StrLen(UnreliablePayerEntryCZL."Full Bank Account No.") > MaxStrLen(CustomerBankAccount."Bank Account No.") then
                        Error(BankAccountNoTooLongErr, MaxStrLen(CustomerBankAccount."Bank Account No."));
                    CustomerBankAccount.Validate("Bank Account No.", CopyStr(UnreliablePayerEntryCZL."Full Bank Account No.", 1, MaxStrLen(CustomerBankAccount."Bank Account No.")));
                end;
            UnreliablePayerEntryCZL."Bank Account Type"::"Not Standard":
                CustomerBankAccount.Validate(IBAN, UnreliablePayerEntryCZL."Full Bank Account No.");
        end;
        CustomerBankAccount.Insert(true);
        if PreferredBankAccount then begin
            Customer.Validate("Preferred Bank Account Code", BankAccountCode);
            Customer.Modify(true);
        end;
        exit(CustomerBankAccount.RecordId());
    end;

    procedure CheckBankAccountNotExists(UnreliablePayerEntryCZL: Record "Unreliable Payer Entry CZL"; AccountNo: Code[20])
    var
        CustomerBankAccount: Record "Customer Bank Account";
    begin
        CustomerBankAccount.SetRange("Customer No.", AccountNo);
        case UnreliablePayerEntryCZL."Bank Account Type" of
            UnreliablePayerEntryCZL."Bank Account Type"::Standard:
                CustomerBankAccount.SetRange("Bank Account No.", UnreliablePayerEntryCZL."Full Bank Account No.");
            UnreliablePayerEntryCZL."Bank Account Type"::"Not Standard":
                CustomerBankAccount.SetRange(IBAN, UnreliablePayerEntryCZL."Full Bank Account No.");
        end;
        if CustomerBankAccount.FindFirst() then
            Error(BankAccountExistsErr, CustomerBankAccount.TableCaption(), CustomerBankAccount.Code);
    end;
}