// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using Microsoft.Bank.BankAccount;
using Microsoft.Finance.GeneralLedger.Journal;

/// <summary>
/// Validates general journal lines before they are exported for payment processing.
/// This codeunit performs comprehensive checks to ensure payment data integrity and compliance.
/// </summary>
codeunit 1211 "Payment Export Gen. Jnl Check"
{
    TableNo = "Gen. Journal Line";

    trigger OnRun()
    begin
        CheckPaymentExportGenJnl(Rec);
    end;

    var
        EmptyPaymentDetailsErr: Label '%1 or %2 must be used for payments.', Comment = '%1=Field;%2=Field';
        SimultaneousPaymentDetailsErr: Label '%1 and %2 cannot be used simultaneously for payments.', Comment = '%1=Field;%2=Field';
#pragma warning disable AA0470
        WrongBalAccountErr: Label '%1 for the %2 is different from %3 on %4: %5.', Comment = '%1=Field;%1=Table;%3=Value;%4=Table;%5=Value';
#pragma warning restore AA0470
        MustBeVendorEmployeeOrCustomerErr: Label 'The account must be a vendor, customer or employee account.';
        MustBeVendEmplPmtOrCustRefundErr: Label 'Only vendor and employee payments and customer refunds are allowed.';
        MustBePositiveErr: Label 'The amount must be positive.';
        FieldBlankErr: Label '%1 must have a value in %2.', Comment = '%1=table name, %2=field name. Example: Customer must have a value in Name.';
        FieldKeyBlankErr: Label '%1 %2 must have a value in %3.', Comment = '%1=table name, %2=key field value, %3=field name. Example: Customer 10000 must have a value in Name.';
        TempGenJournalBatch: Record "Gen. Journal Batch" temporary;
        WrongBankPaymentTypeErr: Label '%1 must be either %2 or %3.', Comment = '%1=Bank Payment Type field caption, %2=Electronic Payment bank payment type, %3=Electronic Payment-IAT bank payment type';

    local procedure CheckPaymentExportGenJnl(var GenJournalLine: Record "Gen. Journal Line")
    var
        GenJnlBatch: Record "Gen. Journal Batch";
        Handled: Boolean;
    begin
        GenJournalLine.DeletePaymentFileErrors();
        GenJnlBatch.Get(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name");

        if not TempGenJournalBatch.Get(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name") then
            CheckGenJournalBatch(GenJournalLine, GenJnlBatch);

        if GenJournalLine."Payment Method Code" = '' then
            AddFieldEmptyError(GenJournalLine, GenJournalLine.TableCaption(), GenJournalLine.FieldCaption("Payment Method Code"), '');

        if (GenJournalLine."Recipient Bank Account" <> '') and (GenJournalLine."Creditor No." <> '') then
            GenJournalLine.InsertPaymentFileError(StrSubstNo(SimultaneousPaymentDetailsErr,
                GenJournalLine.FieldCaption("Recipient Bank Account"), GenJournalLine.FieldCaption("Creditor No.")));

        if GenJournalLine."Bal. Account Type" <> GenJournalLine."Bal. Account Type"::"Bank Account" then
            GenJournalLine.InsertPaymentFileError(StrSubstNo(WrongBalAccountErr, GenJournalLine.FieldCaption("Bal. Account Type"),
                GenJournalLine.TableCaption, GenJournalLine."Bal. Account Type"::"Bank Account", GenJnlBatch.TableCaption(), GenJnlBatch.Name));

        if GenJournalLine."Bal. Account No." <> GenJnlBatch."Bal. Account No." then
            GenJournalLine.InsertPaymentFileError(StrSubstNo(WrongBalAccountErr, GenJournalLine.FieldCaption("Bal. Account No."),
                GenJournalLine.TableCaption, GenJnlBatch."Bal. Account No.", GenJnlBatch.TableCaption(), GenJnlBatch.Name));

        if GenJournalLine.Amount <= 0 then
            GenJournalLine.InsertPaymentFileError(MustBePositiveErr);

        if ((GenJournalLine."Account Type" = GenJournalLine."Account Type"::"Bank Account") or
            (GenJournalLine."Bal. Account Type" = GenJournalLine."Bal. Account Type"::"Bank Account")) and
           ((GenJournalLine."Bank Payment Type" <> GenJournalLine."Bank Payment Type"::"Electronic Payment") and
            (GenJournalLine."Bank Payment Type" <> GenJournalLine."Bank Payment Type"::"Electronic Payment-IAT"))
        then
            GenJournalLine.InsertPaymentFileError(StrSubstNo(WrongBankPaymentTypeErr, GenJournalLine.FieldCaption("Bank Payment Type"),
                GenJournalLine."Bank Payment Type"::"Electronic Payment", GenJournalLine."Bank Payment Type"::"Electronic Payment-IAT"));

        OnPaymentExportGenJnlCheck(GenJournalLine, Handled);
        if not Handled then begin
            if not (GenJournalLine."Account Type" in [GenJournalLine."Account Type"::Customer, GenJournalLine."Account Type"::Vendor, GenJournalLine."Account Type"::Employee])
            then
                GenJournalLine.InsertPaymentFileError(MustBeVendorEmployeeOrCustomerErr);

            if ((GenJournalLine."Account Type" = GenJournalLine."Account Type"::Vendor) and
                (GenJournalLine."Document Type" <> GenJournalLine."Document Type"::Payment)) or
               ((GenJournalLine."Account Type" = GenJournalLine."Account Type"::Customer) and
                (GenJournalLine."Document Type" <> GenJournalLine."Document Type"::Refund)) or
               ((GenJournalLine."Account Type" = GenJournalLine."Account Type"::Employee) and
                (GenJournalLine."Document Type" <> GenJournalLine."Document Type"::Payment))
            then
                GenJournalLine.InsertPaymentFileError(MustBeVendEmplPmtOrCustRefundErr);

            if not (GenJournalLine."Account Type" = GenJournalLine."Account Type"::Employee) and
               (GenJournalLine."Recipient Bank Account" = '') and (GenJournalLine."Creditor No." = '')
            then
                GenJournalLine.InsertPaymentFileError(StrSubstNo(EmptyPaymentDetailsErr,
                    GenJournalLine.FieldCaption("Recipient Bank Account"), GenJournalLine.FieldCaption("Creditor No.")));
        end;
    end;

    /// <summary>
    /// Adds a field empty error to the payment file error log for a general journal line.
    /// </summary>
    /// <param name="GenJnlLine">The general journal line record to add the error to.</param>
    /// <param name="TableCaption2">The caption of the table where the field is missing.</param>
    /// <param name="FieldCaption">The caption of the field that is empty.</param>
    /// <param name="KeyValue">The key value to identify the specific record, if applicable.</param>
    procedure AddFieldEmptyError(var GenJnlLine: Record "Gen. Journal Line"; TableCaption2: Text; FieldCaption: Text; KeyValue: Text)
    var
        ErrorText: Text;
    begin
        if KeyValue = '' then
            ErrorText := StrSubstNo(FieldBlankErr, TableCaption2, FieldCaption)
        else
            ErrorText := StrSubstNo(FieldKeyBlankErr, TableCaption2, KeyValue, FieldCaption);
        GenJnlLine.InsertPaymentFileError(ErrorText);
    end;

    /// <summary>
    /// Adds a batch-related empty field error to the payment file error log for a general journal line.
    /// </summary>
    /// <param name="GenJnlLine">The general journal line record to add the error to.</param>
    /// <param name="FieldCaption">The caption of the field that is empty in the journal batch.</param>
    /// <param name="KeyValue">The key value to identify the specific batch record.</param>
    procedure AddBatchEmptyError(var GenJnlLine: Record "Gen. Journal Line"; FieldCaption: Text; KeyValue: Variant)
    var
        GenJnlBatch: Record "Gen. Journal Batch";
    begin
        AddFieldEmptyError(GenJnlLine, GenJnlBatch.TableCaption(), FieldCaption, Format(KeyValue));
    end;

    local procedure CheckGenJournalBatch(GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch")
    var
        BankAccount: Record "Bank Account";
    begin
        TempGenJournalBatch := GenJournalBatch;
        TempGenJournalBatch.Insert();

        GenJournalBatch.OnCheckGenJournalLineExportRestrictions();

        if not GenJournalBatch."Allow Payment Export" then
            AddBatchEmptyError(GenJournalLine, GenJournalBatch.FieldCaption("Allow Payment Export"), '');

        if GenJournalBatch."Bal. Account Type" <> GenJournalBatch."Bal. Account Type"::"Bank Account" then
            AddBatchEmptyError(GenJournalLine, GenJournalBatch.FieldCaption("Bal. Account Type"), GenJournalBatch."Bal. Account Type");

        if GenJournalBatch."Bal. Account No." = '' then
            AddBatchEmptyError(GenJournalLine, GenJournalBatch.FieldCaption("Bal. Account No."), GenJournalBatch."Bal. Account No.");

        if BankAccount.Get(GenJournalBatch."Bal. Account No.") then
            if (BankAccount."Export Format" = 0) or (BankAccount."Export Format" = BankAccount."Export Format"::Other) then
                if BankAccount."Payment Export Format" = '' then
                    GenJournalLine.InsertPaymentFileError(
                      StrSubstNo(FieldBlankErr, BankAccount.FieldCaption("Payment Export Format"), BankAccount.TableCaption()));
    end;

    /// <summary>
    /// Integration event that allows customization of payment export validation logic.
    /// This event is raised during general journal line validation to allow external extensions to add custom validation rules.
    /// </summary>
    /// <param name="GenJournalLine">The general journal line being validated for payment export.</param>
    /// <param name="Handled">Set to true if the validation has been handled by an external extension.</param>
    [IntegrationEvent(false, false)]
    local procedure OnPaymentExportGenJnlCheck(var GenJournalLine: Record "Gen. Journal Line"; var Handled: Boolean)
    begin
    end;
}

