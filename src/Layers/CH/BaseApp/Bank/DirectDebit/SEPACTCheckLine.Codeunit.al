// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.DirectDebit;

using Microsoft.Bank;
using Microsoft.Bank.BankAccount;
using Microsoft.Bank.Payment;
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
    var
        CHMgt: Codeunit CHMgt;
    begin
        SwissExport := CHMgt.IsSwissSEPACTExport(Rec);
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
        SwissExport: Boolean;
        UnknownSwissPaymentTypeErr: Label 'Unknown Swiss SEPA CT export payment type.';
        IBANTypeErr: Label 'The IBAN type on the recipient bank account must match the payment reference type.';
        QRIBANErr: Label 'The recipient bank account has an IBAN that is of type QR-IBAN. This type requires that the recipient bank account has a SEPA CT export payment type that is type 3.';
        QRRefErr: Label 'The payment reference is a QR reference. This type requires that the recipient bank account has a SEPA CT export payment type that is type 3.';
        IBANTypeHelpLinkTxt: Label 'https://go.microsoft.com/fwlink/?linkid=2210475', Locked = true;
        QRIBANHelpLinkTxt: Label 'https://go.microsoft.com/fwlink/?linkid=2210564', Locked = true;
        QRRefHelpLinkTxt: Label 'https://go.microsoft.com/fwlink/?linkid=2210811', Locked = true;

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

        if (not SwissExport) and (GenJnlLine."Currency Code" <> GLSetup.GetCurrencyCode('EUR')) and (not GLSetup."SEPA Non-Euro Export") then begin
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
        SwissIgnoreIBAN: Boolean;
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
                        CheckSwissExportCustomerBankPaymentType(GenJnlLine, CustomerBankAccount);
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
                        CheckSwissExportVendorBankPaymentType(GenJnlLine, VendorBankAccount, SwissIgnoreIBAN);
                        if not SwissIgnoreIBAN and (VendorBankAccount.IBAN = '') then
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

    local procedure CheckSwissExportVendorBankPaymentType(GenJnlLine: Record "Gen. Journal Line"; VendorBankAccount: Record "Vendor Bank Account"; var SwissIgnoreIBAN: Boolean)
    var
        DummyPaymentExportData: Record "Payment Export Data";
        BankAccount: Record "Bank Account";
        BankMgt: Codeunit BankMgt;
        SwissPaymentType: Option;
        IsQRReference: Boolean;
        IsQRIBAN: Boolean;
        IsReferenceAndIBANTypeMatched: Boolean;
    begin
        SwissIgnoreIBAN := false;

        if not SwissExport then
            exit;

        if VendorBankAccount.GetPaymentType(SwissPaymentType, GenJnlLine."Currency Code") then begin
            if (SwissPaymentType = DummyPaymentExportData."Swiss Payment Type"::"1") and (GenJnlLine."Reference No." = '') then
                AddFieldEmptyError(GenJnlLine, GenJnlLine.TableCaption(), GenJnlLine.FieldCaption("Reference No."), '');
            if SwissPaymentType in
               [DummyPaymentExportData."Swiss Payment Type"::"3",
                DummyPaymentExportData."Swiss Payment Type"::"5",
                DummyPaymentExportData."Swiss Payment Type"::"6"]
            then begin
                BankAccount.Get(GenJnlLine."Bal. Account No.");
                if BankAccount."SWIFT Code" = '' then
                    AddFieldEmptyError(
                      GenJnlLine, BankAccount.TableCaption(), BankAccount.FieldCaption("SWIFT Code"), GenJnlLine."Bal. Account No.");
            end;
            SwissIgnoreIBAN :=
              SwissPaymentType in
              [DummyPaymentExportData."Swiss Payment Type"::"1",
               DummyPaymentExportData."Swiss Payment Type"::"2.1",
               DummyPaymentExportData."Swiss Payment Type"::"6"];

            if not SwissIgnoreIBAN and (StrLen(DelChr(VendorBankAccount.IBAN)) = 21) then begin
                IsQRIBAN := BankMgt.IsQRIBAN(VendorBankAccount.IBAN);
                IsQRReference := BankMgt.IsQRReference(GenJnlLine."Payment Reference");
                IsReferenceAndIBANTypeMatched := not (IsQRReference xor IsQRIBAN);

                if SwissPaymentType = DummyPaymentExportData."Swiss Payment Type"::"3" then begin
                    if not IsReferenceAndIBANTypeMatched then
                        GenJnlLine.InsertPaymentFileErrorWithDetails(IBANTypeErr, '', IBANTypeHelpLinkTxt);
                end else begin
                    if IsQRReference then
                        GenJnlLine.InsertPaymentFileErrorWithDetails(QRRefErr, '', QRRefHelpLinkTxt);
                    if IsQRIBAN then
                        GenJnlLine.InsertPaymentFileErrorWithDetails(QRIBANErr, '', QRIBANHelpLinkTxt);
                end;
            end;

            exit;
        end;

        case VendorBankAccount."Payment Form" of
            VendorBankAccount."Payment Form"::ESR, VendorBankAccount."Payment Form"::"ESR+":
                if VendorBankAccount."ESR Account No." = '' then
                    AddFieldEmptyError(GenJnlLine, VendorBankAccount.TableCaption(), VendorBankAccount.FieldCaption(VendorBankAccount."ESR Account No."), VendorBankAccount.Code);
            VendorBankAccount."Payment Form"::"Post Payment Domestic":
                if VendorBankAccount.IBAN = '' then
                    AddFieldEmptyError(GenJnlLine, VendorBankAccount.TableCaption(), VendorBankAccount.FieldCaption(VendorBankAccount.IBAN), VendorBankAccount.Code);
            VendorBankAccount."Payment Form"::"Bank Payment Domestic":
                if (VendorBankAccount."Clearing No." = '') and (VendorBankAccount."SWIFT Code" = '') then
                    AddFieldEmptyError(GenJnlLine, VendorBankAccount.TableCaption(), VendorBankAccount.FieldCaption(VendorBankAccount."SWIFT Code"), VendorBankAccount.Code);
            VendorBankAccount."Payment Form"::"Bank Payment Abroad", VendorBankAccount."Payment Form"::"Post Payment Abroad":
                if VendorBankAccount."SWIFT Code" = '' then
                    AddFieldEmptyError(GenJnlLine, VendorBankAccount.TableCaption(), VendorBankAccount.FieldCaption(VendorBankAccount."SWIFT Code"), VendorBankAccount.Code);
            else
                GenJnlLine.InsertPaymentFileError(UnknownSwissPaymentTypeErr);
        end;
    end;

    local procedure CheckSwissExportCustomerBankPaymentType(GenJnlLine: Record "Gen. Journal Line"; CustomerBankAccount: Record "Customer Bank Account")
    var
        DummyPaymentExportData: Record "Payment Export Data";
        BankAccount: Record "Bank Account";
        SwissPaymentType: Option;
    begin
        if not SwissExport then
            exit;

        if CustomerBankAccount.GetPaymentType(SwissPaymentType, GenJnlLine."Currency Code") then
            if SwissPaymentType = DummyPaymentExportData."Swiss Payment Type"::"6" then begin
                BankAccount.Get(GenJnlLine."Bal. Account No.");
                if BankAccount."SWIFT Code" = '' then
                    AddFieldEmptyError(
                      GenJnlLine, BankAccount.TableCaption(), BankAccount.FieldCaption("SWIFT Code"), GenJnlLine."Bal. Account No.");
            end;
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

