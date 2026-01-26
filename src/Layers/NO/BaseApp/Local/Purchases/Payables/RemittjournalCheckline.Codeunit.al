// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Payables;

using Microsoft.Finance.GeneralLedger.Journal;
using System.Utilities;

codeunit 15000001 "Remitt. journal - Check line"
{
    TableNo = "Gen. Journal Line";

    trigger OnRun()
    begin
    end;

    var
        Text001: Label 'Field %1 is used for settlement return and should be left empty.';
        CreditMemoOffsetMsg: Label 'Credit memo offset can not be made in arrear and must not be made before %1.', Comment = '%1 - Day of Today';
        Text009: Label 'Error in journal line "%1".\%2.', Comment = 'Parameter 1 - Jln line description, 2 - text with error';
        TwelveMonthsMsg: Label '12 months';
        ThirteenMonthsMsg: Label '13 months';
        PostingDateAfterMaxDateMsg: Label 'Payment must be made within %1, and should not be due after %2.', Comment = '%1 - Count of months, %2 - Max Date';
        PostingDateBeforeMaxDateMsg: Label 'Payment must be made up to one year in arrears, and should not be due before %1.', Comment = '%1 - Max Date';
        VendorRemittedMsg: Label '%1 should be %2. Only the vendors are remitted.', Comment = '%1 - Caption of "Account Type", %2 - Account type';
        DocumentTypeMsg: Label '%1 should be left empty when "paying" credit memo/debit entry.', Comment = '%1 - Caption of "Document Type"';
        PaymentAndCashDiscMsg: Label 'Due date and cash discount date are both the same Saturday or Sunday. Payment is not due before Monday, which is later than the cash discount date.';
        FieldIsNotUseForRemmitanceMsg: Label 'The %1 field must be empty because it is not used for remittance.', Comment = '%1 - name of field';

    procedure Check(GenJnlline: Record "Gen. Journal Line"; RemAccount: Record "Remittance Account"; var ErrorText: array[50] of Text[250]; var ErrorFatal: array[50] of Boolean): Boolean
    var
        RemAgreement: Record "Remittance Agreement";
        PaymentDay: Record Date;
        CashDiscountDay: Record Date;
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        RemittanceTools: Codeunit "Remittance Tools";
        ErrorCounter: Integer;
        CheckDatesError: Text[250];
    begin
        ErrorCounter := 0;
        RemAgreement.Get(RemAccount."Remittance Agreement Code");

        if GenJnlline."Applies-to Doc. No." = '' then
            VendorLedgerEntry.Init()
        else
            RemittanceTools.SearchEntry(GenJnlline, VendorLedgerEntry);

        // "Bal. Account nr." is not in use and must be left empty:
        if GenJnlline."Bal. Account No." <> '' then
            AddError(StrSubstNo(FieldIsNotUseForRemmitanceMsg, GenJnlline.FieldCaption("Bal. Account No.")),
              true, ErrorCounter, ErrorText, ErrorFatal);

        // Document no. is used for settlement return. Must be left empty:
        if GenJnlline."Document No." <> '' then
            AddError(StrSubstNo(Text001, GenJnlline.FieldCaption("Document No.")), true, ErrorCounter, ErrorText, ErrorFatal);

        if GenJnlline."Account Type" <> GenJnlline."Account Type"::Vendor then
            AddError(StrSubstNo(VendorRemittedMsg, GenJnlline.FieldCaption("Account Type"), GenJnlline."Account Type"),
              true, ErrorCounter, ErrorText, ErrorFatal);

        if (GenJnlline.Amount < 0) and (GenJnlline."Document Type" <> "Gen. Journal Document Type"::" ") then
            AddError(StrSubstNo(DocumentTypeMsg, GenJnlline.FieldCaption("Document Type")), true, ErrorCounter, ErrorText, ErrorFatal);

        CheckDatesError := CheckDates(GenJnlline);
        if CheckDatesError <> '' then
            AddError(CheckDatesError, true, ErrorCounter, ErrorText, ErrorFatal);

        // Both payment and cash discount are due on the same saturday/sunday
        if PaymentDay.Get(PaymentDay."Period Type"::Date, GenJnlline."Posting Date") and
           CashDiscountDay.Get(CashDiscountDay."Period Type"::Date, VendorLedgerEntry."Pmt. Discount Date")
        then
            if (PaymentDay."Period No." in [6, 7]) and
               (CashDiscountDay."Period No." in [6, 7]) and
               ((VendorLedgerEntry."Pmt. Discount Date" - GenJnlline."Posting Date") in [0, 1])
            then
                AddError(PaymentAndCashDiscMsg, false, ErrorCounter, ErrorText, ErrorFatal);

        // Check for PostBanken: Credit memo-date must be prior to TODAY:
        RemAccount.Get(GenJnlline."Remittance Account Code");
        if RemAgreement."Payment System" = RemAgreement."Payment System"::Postbanken then
            if (GenJnlline."Posting Date" < Today) and (GenJnlline.Amount < 0) then
                AddError(StrSubstNo(CreditMemoOffsetMsg, Today), true, ErrorCounter, ErrorText, ErrorFatal);

        exit(ErrorText[1] <> '');
    end;

    procedure CheckUntilFirstError(GenJnlLine: Record "Gen. Journal Line"; RemittanceAccount: Record "Remittance Account")
    var
        ErrorText: array[50] of Text[250];
        ErrorFatal: array[50] of Boolean;
    begin
        if Check(GenJnlLine, RemittanceAccount, ErrorText, ErrorFatal) then
            Error(Text009, GenJnlLine.Description, ErrorText[1]);
    end;

    procedure CheckDates(GenJnlLine: Record "Gen. Journal Line"): Text[250]
    var
        RemittanceAccount: Record "Remittance Account";
        RemittanceAgreement: Record "Remittance Agreement";
        MaxDate: Date;
        MessageText: Text[100];
    begin
        RemittanceAccount.Get(GenJnlLine."Remittance Account Code");
        RemittanceAgreement.Get(RemittanceAccount."Remittance Agreement Code");

        // Payment made up to 12/13 mths. in advance
        if RemittanceAgreement."Payment System" = RemittanceAgreement."Payment System"::BBS then begin
            MaxDate := CalcDate('<+12M-1D>', Today);
            MessageText := TwelveMonthsMsg;
        end else begin
            MaxDate := CalcDate('<+13M-1D>', Today);
            MessageText := ThirteenMonthsMsg;
        end;
        if GenJnlLine."Posting Date" > MaxDate then
            exit(StrSubstNo(PostingDateAfterMaxDateMsg, MessageText, MaxDate));

        // Payment made up to 1 year in arrear:
        MaxDate := CalcDate('<-12M>', Today);
        if GenJnlLine."Posting Date" < MaxDate then
            exit(StrSubstNo(PostingDateBeforeMaxDateMsg, MaxDate));
    end;

    procedure AddError(ErrorMsg: Text[250]; Fatal: Boolean; var ErrorCounter: Integer; var ErrorText: array[50] of Text[250]; var ErrorFatal: array[50] of Boolean)
    begin
        ErrorCounter := ErrorCounter + 1;
        ErrorText[ErrorCounter] := ErrorMsg;
        ErrorFatal[ErrorCounter] := Fatal;
    end;
}

