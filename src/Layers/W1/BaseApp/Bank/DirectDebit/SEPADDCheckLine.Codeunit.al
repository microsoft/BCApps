// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.DirectDebit;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Enums;
using Microsoft.Sales.Customer;

/// <summary>
/// Validates direct debit collection entries for SEPA compliance and data completeness.
/// Performs comprehensive validation of customer information, mandate details, bank account data,
/// and business rules before export to ensure SEPA standard compliance.
/// </summary>
codeunit 1233 "SEPA DD-Check Line"
{
    TableNo = "Direct Debit Collection Entry";

    trigger OnRun()
    begin
        Rec.DeletePaymentFileErrors();
        CheckCollectionEntry(Rec);
    end;

    var
        EuroCurrErr: Label 'Only transactions in euro (EUR) are allowed.';
        FieldBlankErr: Label '%1 must have a value in %2.', Comment = '%1=field name, %2=table name. Example: Name must have a value in Customer.';
        FieldKeyBlankErr: Label '%1 must have a value in %2 %3.', Comment = '%1=field name, %2= table name, %3=key field value. Example: Name must have a value in Customer 10000.';
#pragma warning disable AA0470
        MustBeCustomerErr: Label 'The customer %1 does not exist.';
#pragma warning restore AA0470
        MustBePositiveErr: Label 'The amount must be positive.';
#pragma warning disable AA0470
        NotActiveMandateErr: Label 'The mandate %1 is not active.';
#pragma warning restore AA0470
        PartnerTypeErr: Label 'The customer''s %1, %2, must be equal to the %1, %3, specified in the collection.', Comment = '%1 = Partner Type; %2 = Company/Person; %3 = Company/Person.';
        TransferDateErr: Label 'The earliest possible transfer date is today.';
        TransferDateAddnlInfoTxt: Label 'You can use the Reset Transfer Date action to eliminate the error.';
        SelectedRecordTxt: Label 'the currently selected record';
#pragma warning disable AA0470
        PartnerTypeBlankErr: Label '%1 must be filled.', Comment = 'Partner Type must be filled.';
#pragma warning restore AA0470
        ExportWithoutIBANAndSWIFTErr: Label 'Either the Bank Account No. and Bank Branch No. fields or the SWIFT Code and IBAN fields must be filled in for %1 %2.', Comment = '%1= table name, %2=key field value. Example: Either the Bank Account No. and Bank Branch No. fields or the SWIFT Code and IBAN fields must be filled in for Customer Bank Account ECA.';

    local procedure CheckCollectionEntry(DirectDebitCollectionEntry: Record "Direct Debit Collection Entry")
    var
        Customer: Record Customer;
        CustomerBankAccount: Record "Customer Bank Account";
        DirectDebitCollection: Record "Direct Debit Collection";
        GLSetup: Record "General Ledger Setup";
        SEPADirectDebitMandate: Record "SEPA Direct Debit Mandate";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckCollectionEntry(DirectDebitCollectionEntry, IsHandled);
        if IsHandled then
            exit;

        GLSetup.Get();
        if DirectDebitCollectionEntry."Transfer Amount" <= 0 then
            DirectDebitCollectionEntry.InsertPaymentFileError(MustBePositiveErr);

        if (DirectDebitCollectionEntry."Currency Code" <> GLSetup.GetCurrencyCode('EUR')) and not GLSetup."SEPA Non-Euro Export" then
            DirectDebitCollectionEntry.InsertPaymentFileError(EuroCurrErr);

        if DirectDebitCollectionEntry."Transfer Date" < Today then
            DirectDebitCollectionEntry.InsertPaymentFileErrorWithDetails(TransferDateErr, TransferDateAddnlInfoTxt);

        if not Customer.Get(DirectDebitCollectionEntry."Customer No.") then begin
            DirectDebitCollectionEntry.InsertPaymentFileError(StrSubstNo(MustBeCustomerErr, DirectDebitCollectionEntry."Customer No."));
            exit;
        end;

        if Customer.Name = '' then
            AddFieldEmptyError(DirectDebitCollectionEntry, Customer.TableCaption(), Customer.FieldCaption(Name), DirectDebitCollectionEntry."Customer No.");

        DirectDebitCollection.Get(DirectDebitCollectionEntry."Direct Debit Collection No.");

        IsHandled := false;
        OnBeforeCheckCustomerPartnerType(Customer, DirectDebitCollectionEntry, IsHandled);
        if not IsHandled then
            if Customer."Partner Type" <> DirectDebitCollection."Partner Type" then
                DirectDebitCollectionEntry.InsertPaymentFileError(StrSubstNo(PartnerTypeErr, Customer.FieldCaption("Partner Type"), Customer."Partner Type",
                    DirectDebitCollection."Partner Type"));

        if DirectDebitCollection."Partner Type" = DirectDebitCollection."Partner Type"::" " then
            DirectDebitCollectionEntry.InsertPaymentFileError(StrSubstNo(PartnerTypeBlankErr, DirectDebitCollection.FieldCaption("Partner Type")));

        if DirectDebitCollectionEntry."Mandate ID" = '' then
            AddFieldEmptyError(DirectDebitCollectionEntry, SelectedRecordTxt, DirectDebitCollectionEntry.FieldCaption(DirectDebitCollectionEntry."Mandate ID"), DirectDebitCollectionEntry."Mandate ID")
        else begin
            SEPADirectDebitMandate.Get(DirectDebitCollectionEntry."Mandate ID");
            if SEPADirectDebitMandate."Date of Signature" = 0D then
                AddFieldEmptyError(
                  DirectDebitCollectionEntry, SEPADirectDebitMandate.TableCaption(), SEPADirectDebitMandate.FieldCaption("Date of Signature"),
                  DirectDebitCollectionEntry."Mandate ID");
            if not SEPADirectDebitMandate.IsMandateActive(DirectDebitCollectionEntry."Transfer Date") then
                DirectDebitCollectionEntry.InsertPaymentFileError(StrSubstNo(NotActiveMandateErr, DirectDebitCollectionEntry."Mandate ID"));

            if SEPADirectDebitMandate."Customer Bank Account Code" = '' then
                AddFieldEmptyError(
                  DirectDebitCollectionEntry, SEPADirectDebitMandate.TableCaption(),
                  SEPADirectDebitMandate.FieldCaption("Customer Bank Account Code"), SEPADirectDebitMandate.ID)
            else begin
                CustomerBankAccount.Get(Customer."No.", SEPADirectDebitMandate."Customer Bank Account Code");
                if not GLSetup."SEPA Export w/o Bank Acc. Data" then begin
                    if CustomerBankAccount."SWIFT Code" = '' then
                        AddFieldEmptyError(
                          DirectDebitCollectionEntry, CustomerBankAccount.TableCaption(), CustomerBankAccount.FieldCaption("SWIFT Code"),
                          CustomerBankAccount.Code);
                    if CustomerBankAccount.IBAN = '' then
                        AddFieldEmptyError(
                          DirectDebitCollectionEntry, CustomerBankAccount.TableCaption(), CustomerBankAccount.FieldCaption(IBAN),
                          CustomerBankAccount.Code);
                end else
                    if (CustomerBankAccount."Bank Account No." = '') or (CustomerBankAccount."Bank Branch No." = '') then
                        if (CustomerBankAccount."SWIFT Code" = '') or (CustomerBankAccount.IBAN = '') then
                            DirectDebitCollectionEntry.InsertPaymentFileError(
                              StrSubstNo(ExportWithoutIBANAndSWIFTErr, CustomerBankAccount.TableCaption(), CustomerBankAccount.Code));
            end;
        end;
    end;

    local procedure AddFieldEmptyError(var DirectDebitCollectionEntry: Record "Direct Debit Collection Entry"; TableCaption2: Text; FieldCaption2: Text; KeyValue: Text)
    var
        ErrorText: Text;
    begin
        if KeyValue = '' then
            ErrorText := StrSubstNo(FieldBlankErr, FieldCaption2, TableCaption2)
        else
            ErrorText := StrSubstNo(FieldKeyBlankErr, FieldCaption2, TableCaption2, KeyValue);
        DirectDebitCollectionEntry.InsertPaymentFileError(ErrorText);
    end;

    /// <summary>
    /// Integration event that allows customization of collection entry validation logic.
    /// </summary>
    /// <param name="DirectDebitCollectionEntry">The collection entry being validated</param>
    /// <param name="IsHandled">Whether the event has been handled by subscribers</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckCollectionEntry(var DirectDebitCollectionEntry: Record "Direct Debit Collection Entry"; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event that allows customization of customer partner type validation.
    /// </summary>
    /// <param name="Customer">The customer being validated</param>
    /// <param name="DirectDebitCollectionEntry">The collection entry being processed</param>
    /// <param name="IsHandled">Whether the event has been handled by subscribers</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckCustomerPartnerType(Customer: Record Customer; DirectDebitCollectionEntry: Record "Direct Debit Collection Entry"; var IsHandled: Boolean)
    begin
    end;
}

