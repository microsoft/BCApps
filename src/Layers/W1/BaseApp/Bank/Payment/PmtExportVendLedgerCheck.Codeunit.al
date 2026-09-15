// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using Microsoft.Bank.BankAccount;
using Microsoft.Purchases.Payables;

/// <summary>
/// Validates vendor ledger entries before they are exported for payment processing.
/// This codeunit performs comprehensive checks to ensure vendor payment data integrity and compliance.
/// </summary>
codeunit 1212 "Pmt. Export Vend. Ledger Check"
{
    TableNo = "Vendor Ledger Entry";

    trigger OnRun()
    begin
        CheckDocumentType(Rec);
        CheckPaymentMethod(Rec);
        CheckSimultaneousPmtInfoCreditorNo(Rec);
        CheckEmptyPmtInfo(Rec);
        CheckBalAccountType(Rec);
        CheckBankAccount(Rec);
        CheckBalAccountNo(Rec);

        OnPmtExportVendorLedgerCheck(Rec);
    end;

    var
        EmptyPaymentDetailsErr: Label '%1 or %2 must be used for payments.', Comment = '%1=Field;%2=Field';
        SimultaneousPaymentDetailsErr: Label '%1 and %2 cannot be used simultaneously for payments.', Comment = '%1=Field;%2=Field';
        WrongFieldValueErr: Label '%1 for one or more %2 is different from %3.', Comment = '%1=Field;%2=Table;%3=Value';
#pragma warning disable AA0470
        MissingPmtMethodErr: Label '%1 must be used for payments.';
#pragma warning restore AA0470

    local procedure CheckDocumentType(var VendLedgEntry: Record "Vendor Ledger Entry")
    var
        VendLedgEntry2: Record "Vendor Ledger Entry";
    begin
        VendLedgEntry2.Copy(VendLedgEntry);
        VendLedgEntry2.SetFilter("Document Type", '<>%1', VendLedgEntry2."Document Type"::Payment);

        if not VendLedgEntry2.IsEmpty() then
            Error(WrongFieldValueErr,
              VendLedgEntry2.FieldCaption("Document Type"), VendLedgEntry2.TableCaption(), VendLedgEntry2."Document Type"::Payment);
    end;

    local procedure CheckPaymentMethod(var VendLedgEntry: Record "Vendor Ledger Entry")
    var
        VendLedgEntry2: Record "Vendor Ledger Entry";
    begin
        VendLedgEntry2.Copy(VendLedgEntry);
        VendLedgEntry2.SetRange("Payment Method Code", '');

        if not VendLedgEntry2.IsEmpty() then
            Error(MissingPmtMethodErr, VendLedgEntry2.FieldCaption("Payment Method Code"));
    end;

    local procedure CheckSimultaneousPmtInfoCreditorNo(var VendLedgEntry: Record "Vendor Ledger Entry")
    var
        VendLedgEntry2: Record "Vendor Ledger Entry";
    begin
        VendLedgEntry2.Copy(VendLedgEntry);
        VendLedgEntry2.SetFilter("Recipient Bank Account", '<>%1', '');
        VendLedgEntry2.SetFilter("Creditor No.", '<>%1', '');

        if not VendLedgEntry2.IsEmpty() then
            Error(SimultaneousPaymentDetailsErr,
              VendLedgEntry2.FieldCaption("Recipient Bank Account"), VendLedgEntry2.FieldCaption("Creditor No."));
    end;

    local procedure CheckEmptyPmtInfo(var VendLedgEntry: Record "Vendor Ledger Entry")
    var
        VendLedgEntry2: Record "Vendor Ledger Entry";
        Handled: Boolean;
    begin
        VendLedgEntry2.Copy(VendLedgEntry);
        VendLedgEntry2.SetRange("Recipient Bank Account", '');
        VendLedgEntry2.SetRange("Creditor No.", '');

        OnCheckEmptyPmtInfoVendorLedgerEntry(VendLedgEntry2, Handled);

        if not Handled then
            if not VendLedgEntry2.IsEmpty() then
                Error(EmptyPaymentDetailsErr,
                  VendLedgEntry2.FieldCaption("Recipient Bank Account"), VendLedgEntry2.FieldCaption("Creditor No."));
    end;

    local procedure CheckBalAccountType(var VendLedgEntry: Record "Vendor Ledger Entry")
    var
        VendLedgEntry2: Record "Vendor Ledger Entry";
    begin
        VendLedgEntry2.Copy(VendLedgEntry);
        VendLedgEntry2.SetFilter("Bal. Account Type", '<>%1', VendLedgEntry2."Bal. Account Type"::"Bank Account");

        if not VendLedgEntry2.IsEmpty() then
            Error(WrongFieldValueErr, VendLedgEntry2.FieldCaption("Bal. Account Type"),
              VendLedgEntry2.TableCaption(), VendLedgEntry2."Bal. Account Type"::"Bank Account");
    end;

    local procedure CheckBalAccountNo(var VendLedgEntry: Record "Vendor Ledger Entry")
    var
        VendLedgEntry2: Record "Vendor Ledger Entry";
    begin
        VendLedgEntry2.Copy(VendLedgEntry);
        VendLedgEntry2.SetRange("Bal. Account Type", VendLedgEntry2."Bal. Account Type"::"Bank Account");
        VendLedgEntry2.SetFilter("Bal. Account No.", '<>%1', VendLedgEntry."Bal. Account No.");

        if not VendLedgEntry2.IsEmpty() then
            Error(WrongFieldValueErr, VendLedgEntry2.FieldCaption("Bal. Account No."),
              VendLedgEntry2.TableCaption(), VendLedgEntry."Bal. Account No.");
    end;

    local procedure CheckBankAccount(var VendLedgEntry: Record "Vendor Ledger Entry")
    var
        BankAccount: Record "Bank Account";
    begin
        BankAccount.Get(VendLedgEntry."Bal. Account No.");
        BankAccount.TestField("Payment Export Format");
    end;

    /// <summary>
    /// Integration event that allows customization of vendor ledger entry validation logic for payment export.
    /// This event is raised during vendor ledger entry validation to allow external extensions to add custom validation rules.
    /// </summary>
    /// <param name="VendorLedgerEntry">The vendor ledger entry being validated for payment export.</param>
    [IntegrationEvent(false, false)]
    local procedure OnPmtExportVendorLedgerCheck(var VendorLedgerEntry: Record "Vendor Ledger Entry")
    begin
    end;

    /// <summary>
    /// Integration event that allows customization of payment information validation for vendor ledger entries.
    /// This event is raised during empty payment information checks to enable custom validation logic.
    /// </summary>
    /// <param name="VendorLedgerEntry">The vendor ledger entry being checked for payment information.</param>
    /// <param name="Handled">Set to true if the validation has been handled by an external extension.</param>
    [IntegrationEvent(false, false)]
    local procedure OnCheckEmptyPmtInfoVendorLedgerEntry(var VendorLedgerEntry: Record "Vendor Ledger Entry"; var Handled: Boolean)
    begin
    end;
}

