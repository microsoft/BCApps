// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.DirectDebit;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;

codeunit 12178 "SEPA CT CBI-Check Line"
{
    TableNo = "Gen. Journal Line";

    trigger OnRun()
    begin
        Rec.DeletePaymentFileErrors();
        CheckGenJnlLine(Rec);
        CheckCustVend(Rec);
    end;

    var
        MustBeBankAccErr: Label 'The balancing account must be a bank account.';
        MustBeVendorOrCustomerErr: Label 'The account must be a vendor or customer account.';
        MustBeVendPmtOrCustRefundErr: Label 'Only vendor payments and customer refunds are allowed.';
        MustBePositiveErr: Label 'The amount must be positive.';
        TransferDateErr: Label 'The earliest possible transfer date is today.';
        EuroCurrErr: Label 'Only transactions in euro (EUR) are allowed.';
        MissingBankAccErr: Label '%1 has no bank account.', Comment = '%1=customer or vendor.';
        FieldBlankErr: Label '%1 must have a value in %2.', Comment = '%1=table name, %2=field name. Example: Customer must have a value in Name.';
        FieldKeyBlankErr: Label '%1 %2 must have a value in %3.', Comment = '%1=table name, %2=key field value, %3=field name. Example: Customer 10000 must have a value in Name.';

    [Scope('OnPrem')]
    procedure CheckGenJnlLine(var GenJnlLine: Record "Gen. Journal Line")
    var
        GLSetup: Record "General Ledger Setup";
    begin
        GLSetup.Get();
        if GenJnlLine."Bal. Account Type" <> GenJnlLine."Bal. Account Type"::"Bank Account" then
            GenJnlLine.InsertPaymentFileError(MustBeBankAccErr);

        if GenJnlLine."Bal. Account No." = '' then
            AddFieldEmptyError(GenJnlLine, GenJnlLine.TableCaption(), GenJnlLine.FieldCaption("Bal. Account No."), '');

        if GenJnlLine."Recipient Bank Account" = '' then
            AddFieldEmptyError(GenJnlLine, GenJnlLine.TableCaption(), GenJnlLine.FieldCaption("Recipient Bank Account"), '');

        if not (GenJnlLine."Account Type" in [GenJnlLine."Account Type"::Vendor, GenJnlLine."Account Type"::Customer]) then
            GenJnlLine.InsertPaymentFileError(MustBeVendorOrCustomerErr);

        if ((GenJnlLine."Account Type" = GenJnlLine."Account Type"::Vendor) and (GenJnlLine."Document Type" <> GenJnlLine."Document Type"::Payment)) or
           ((GenJnlLine."Account Type" = GenJnlLine."Account Type"::Customer) and (GenJnlLine."Document Type" <> GenJnlLine."Document Type"::Refund))
        then
            GenJnlLine.InsertPaymentFileError(StrSubstNo(MustBeVendPmtOrCustRefundErr));

        if GenJnlLine.Amount <= 0 then
            GenJnlLine.InsertPaymentFileError(MustBePositiveErr);

        if GenJnlLine."Currency Code" <> GLSetup.GetCurrencyCode('EUR') then
            GenJnlLine.InsertPaymentFileError(EuroCurrErr);

        if GenJnlLine."Posting Date" < Today then
            GenJnlLine.InsertPaymentFileError(TransferDateErr);
    end;

    [Scope('OnPrem')]
    procedure CheckCustVend(var GenJnlLine: Record "Gen. Journal Line")
    var
        Customer: Record Customer;
        CustomerBankAccount: Record "Customer Bank Account";
        Vendor: Record Vendor;
    begin
        if GenJnlLine."Account No." = '' then begin
            GenJnlLine.InsertPaymentFileError(MustBeVendorOrCustomerErr);
            exit;
        end;
        case GenJnlLine."Account Type" of
            GenJnlLine."Account Type"::Customer:
                begin
                    Customer.Get(GenJnlLine."Account No.");
                    if Customer.Name = '' then
                        AddFieldEmptyError(GenJnlLine, Customer.TableCaption(), Customer.FieldCaption(Name), GenJnlLine."Account No.");
                    if GenJnlLine."Recipient Bank Account" = '' then
                        GenJnlLine.InsertPaymentFileError(StrSubstNo(MissingBankAccErr, Customer.TableCaption()))
                    else begin
                        CustomerBankAccount.Get(Customer."No.", GenJnlLine."Recipient Bank Account");
                        if CustomerBankAccount."SWIFT Code" = '' then
                            AddFieldEmptyError(
                              GenJnlLine, CustomerBankAccount.TableCaption(), CustomerBankAccount.FieldCaption("SWIFT Code"),
                              GenJnlLine."Recipient Bank Account");
                        if CustomerBankAccount.IBAN = '' then
                            AddFieldEmptyError(
                              GenJnlLine, CustomerBankAccount.TableCaption(), CustomerBankAccount.FieldCaption(IBAN), GenJnlLine."Recipient Bank Account");
                    end;
                end;
            GenJnlLine."Account Type"::Vendor:
                begin
                    Vendor.Get(GenJnlLine."Account No.");
                    if Vendor.Name = '' then
                        AddFieldEmptyError(GenJnlLine, Vendor.TableCaption(), Vendor.FieldCaption(Name), GenJnlLine."Account No.");
                    if GenJnlLine."Recipient Bank Account" = '' then
                        GenJnlLine.InsertPaymentFileError(StrSubstNo(MissingBankAccErr, Vendor.TableCaption()));
                end;
        end;
    end;

    [Scope('OnPrem')]
    procedure AddFieldEmptyError(var GenJnlLine: Record "Gen. Journal Line"; TableCaption: Text; FieldCaption: Text; KeyValue: Text)
    var
        ErrorText: Text;
    begin
        if KeyValue = '' then
            ErrorText := StrSubstNo(FieldBlankErr, TableCaption, FieldCaption)
        else
            ErrorText := StrSubstNo(FieldKeyBlankErr, TableCaption, KeyValue, FieldCaption);
        GenJnlLine.InsertPaymentFileError(ErrorText);
    end;
}

