// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.DirectDebit;

using Microsoft.Bank.BankAccount;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.HumanResources.Employee;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;

/// <summary>
/// Validates general journal lines for SEPA credit transfer compliance and data completeness.
/// Performs comprehensive validation of account types, amounts, bank information, and vendor/customer/employee
/// details before export to ensure SEPA credit transfer standard compliance.
/// </summary>
codeunit 1223 "SEPA CT-Check Line"
{
    TableNo = "Gen. Journal Line";

    trigger OnRun()
    begin
        Rec.DeletePaymentFileErrors();
        CheckGenJnlLine(Rec);
        CheckBank(Rec);
        CheckCustVendEmpl(Rec);
    end;

    var
        MustBeBankAccErr: Label 'The balancing account must be a bank account.';
        MustBeVendorEmployeeOrCustomerErr: Label 'The account must be a vendor, customer or employee account.';
        MustBeVendEmplPmtOrCustRefundErr: Label 'Only vendor and employee payments and customer refunds are allowed.';
        MustBePositiveErr: Label 'The amount must be positive.';
        TransferDateErr: Label 'The earliest possible transfer date is today.';
        EuroCurrErr: Label 'Only transactions in euro (EUR) are allowed, because the %1 bank account is set up to use the %2 export format.', Comment = '%1= bank account No, %2 export format; Example: Only transactions in euro (EUR) are allowed, because the GIRO bank account is set up to use the SEPACT export format.';
        FieldBlankErr: Label 'The %1 field must be filled.', Comment = '%1= field name. Example: The Name field must be filled.';
        FieldKeyBlankErr: Label '%1 %2 must have a value in %3.', Comment = '%1=table name, %2=key field value, %3=field name. Example: Customer 10000 must have a value in Name.';

    local procedure CheckGenJnlLine(var GenJnlLine: Record "Gen. Journal Line")
    var
        GLSetup: Record "General Ledger Setup";
        BankAccount: Record "Bank Account";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckGenJnlLine(GenJnlLine, IsHandled);
        if IsHandled then
            exit;

        GLSetup.Get();

        GenJnlLine.OnCheckGenJournalLineExportRestrictions();

        if GenJnlLine."Bal. Account Type" <> GenJnlLine."Bal. Account Type"::"Bank Account" then
            GenJnlLine.InsertPaymentFileError(MustBeBankAccErr);

        if GenJnlLine."Bal. Account No." = '' then
            AddFieldEmptyError(GenJnlLine, GenJnlLine.TableCaption(), GenJnlLine.FieldCaption(GenJnlLine."Bal. Account No."), '');

        if GenJnlLine."Recipient Bank Account" = '' then
            AddFieldEmptyError(GenJnlLine, GenJnlLine.TableCaption(), GenJnlLine.FieldCaption(GenJnlLine."Recipient Bank Account"), '');

        if not (GenJnlLine."Account Type" in [GenJnlLine."Account Type"::Vendor, GenJnlLine."Account Type"::Customer, GenJnlLine."Account Type"::Employee]) then
            GenJnlLine.InsertPaymentFileError(MustBeVendorEmployeeOrCustomerErr);

        if ((GenJnlLine."Account Type" = GenJnlLine."Account Type"::Vendor) and (GenJnlLine."Document Type" <> GenJnlLine."Document Type"::Payment)) or
           ((GenJnlLine."Account Type" = GenJnlLine."Account Type"::Customer) and (GenJnlLine."Document Type" <> GenJnlLine."Document Type"::Refund)) or
           ((GenJnlLine."Account Type" = GenJnlLine."Account Type"::Employee) and (GenJnlLine."Document Type" <> GenJnlLine."Document Type"::Payment))
        then
            GenJnlLine.InsertPaymentFileError(StrSubstNo(MustBeVendEmplPmtOrCustRefundErr));

        if GenJnlLine.Amount <= 0 then
            GenJnlLine.InsertPaymentFileError(MustBePositiveErr);

        if (GenJnlLine."Currency Code" <> GLSetup.GetCurrencyCode('EUR')) and not GLSetup."SEPA Non-Euro Export" then begin
            BankAccount.Get(GenJnlLine."Bal. Account No.");
            GenJnlLine.InsertPaymentFileError(StrSubstNo(EuroCurrErr, GenJnlLine."Bal. Account No.", BankAccount."Payment Export Format"));
        end;

        if GenJnlLine."Posting Date" < Today then
            GenJnlLine.InsertPaymentFileError(TransferDateErr);

        OnAfterCheckGenJnlLine(GenJnlLine);
    end;

    local procedure CheckBank(var GenJnlLine: Record "Gen. Journal Line")
    var
        BankAccount: Record "Bank Account";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckBank(GenJnlLine, IsHandled);
        if IsHandled then
            exit;

        if BankAccount.Get(GenJnlLine."Bal. Account No.") then
            if BankAccount.IBAN = '' then
                AddFieldEmptyError(GenJnlLine, BankAccount.TableCaption(), BankAccount.FieldCaption(IBAN), GenJnlLine."Bal. Account No.");
    end;

    local procedure CheckCustVendEmpl(var GenJnlLine: Record "Gen. Journal Line")
    var
        Customer: Record Customer;
        CustomerBankAccount: Record "Customer Bank Account";
        Vendor: Record Vendor;
        VendorBankAccount: Record "Vendor Bank Account";
        Employee: Record Employee;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckCustVendEmpl(GenJnlLine, IsHandled);
        if IsHandled then
            exit;

        if GenJnlLine."Account No." = '' then begin
            GenJnlLine.InsertPaymentFileError(MustBeVendorEmployeeOrCustomerErr);
            exit;
        end;
        case GenJnlLine."Account Type" of
            GenJnlLine."Account Type"::Customer:
                begin
                    Customer.Get(GenJnlLine."Account No.");
                    if Customer.Name = '' then
                        AddFieldEmptyError(GenJnlLine, Customer.TableCaption(), Customer.FieldCaption(Name), GenJnlLine."Account No.");
                    if GenJnlLine."Recipient Bank Account" <> '' then begin
                        CustomerBankAccount.Get(Customer."No.", GenJnlLine."Recipient Bank Account");
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
                    if GenJnlLine."Recipient Bank Account" <> '' then begin
                        VendorBankAccount.Get(Vendor."No.", GenJnlLine."Recipient Bank Account");
                        if VendorBankAccount.IBAN = '' then
                            AddFieldEmptyError(
                              GenJnlLine, VendorBankAccount.TableCaption(), VendorBankAccount.FieldCaption(IBAN), GenJnlLine."Recipient Bank Account");
                    end;
                end;
            GenJnlLine."Account Type"::Employee:
                begin
                    Employee.Get(GenJnlLine."Account No.");
                    if Employee.FullName() = '' then
                        AddFieldEmptyError(GenJnlLine, Employee.TableCaption(), Employee.FieldCaption("First Name"), GenJnlLine."Account No.");
                    if GenJnlLine."Recipient Bank Account" <> '' then
                        if Employee.IBAN = '' then
                            AddFieldEmptyError(
                              GenJnlLine, Employee.TableCaption(), Employee.FieldCaption(IBAN), GenJnlLine."Recipient Bank Account");
                end;
            else
                OnCheckCustVendEmplOnCaseElse(GenJnlLine);
        end;
    end;

    local procedure AddFieldEmptyError(var GenJnlLine: Record "Gen. Journal Line"; TableCaption2: Text; FieldCaption: Text; KeyValue: Text)
    var
        ErrorText: Text;
    begin
        if KeyValue = '' then
            ErrorText := StrSubstNo(FieldBlankErr, FieldCaption)
        else
            ErrorText := StrSubstNo(FieldKeyBlankErr, TableCaption2, KeyValue, FieldCaption);
        GenJnlLine.InsertPaymentFileError(ErrorText);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckGenJnlLine(var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckBank(var GenJournalLine: Record "Gen. Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckCustVendEmpl(var GenJournalLine: Record "Gen. Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckGenJnlLine(var GenJournalLine: Record "Gen. Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckCustVendEmplOnCaseElse(var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;
}

