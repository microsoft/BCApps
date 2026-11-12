// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using Microsoft.Bank.BankAccount;
using Microsoft.Bank.DirectDebit;
using Microsoft.Bank.Setup;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Foundation.Company;
using Microsoft.Sales.Customer;
using Microsoft.Purchases.Vendor;

codeunit 13578 "Banking Payments Events FI"
{
    Access = Internal;

    var
#if not CLEAN30
        Feature: Codeunit "Banking Payments Feature FI";
#endif
        AccountTooLongErr: Label '%1 cannot exceed 15 characters.', Comment = '%1 = Bank Account No. caption';

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Company-Initialize", 'OnAfterInitBankExportImportSetup', '', false, false)]
    internal procedure InitializeBankExportImportSetup()
    var
        BankExportImportSetup: Record "Bank Export/Import Setup";
        BankExportCodeTxt: Label 'SEPACT V02', Comment = 'No need to translate - but can be translated at will.', MaxLength = 20;
        BankExportNameTxt: Label 'SEPA Credit Transfer pain.001.001.02 ', MaxLength = 100;
    begin
#if not CLEAN30
        if not Feature.IsEnabled() then
            exit;
#endif
        if BankExportImportSetup.Get(BankExportCodeTxt) then
            exit;
        BankExportImportSetup.Init();
        BankExportImportSetup.Code := BankExportCodeTxt;
        BankExportImportSetup.Name := BankExportNameTxt;
        BankExportImportSetup.Direction := BankExportImportSetup.Direction::Export;
        BankExportImportSetup."Processing Codeunit ID" := Codeunit::"Export SEPA Payment File FI";
        BankExportImportSetup."Processing XMLport ID" := 0;
        BankExportImportSetup."Check Export Codeunit" := 0;
        BankExportImportSetup."Preserve Non-Latin Characters" := false;
        BankExportImportSetup.Insert();
    end;

    [EventSubscriber(ObjectType::Table, Database::"Bank Account", 'OnValidateBankAccount', '', false, false)]
    local procedure ValidateBank(var BankAccount: Record "Bank Account"; FieldToValidate: Text)
    begin
#if not CLEAN30
        if not Feature.IsEnabled() then
            exit;
#endif
        if FieldToValidate = 'Bank Account No.' then
            ValidateDomesticAccount(BankAccount."Bank Account No.", BankAccount."Country/Region Code", BankAccount."No.", BankAccount.FieldCaption("Bank Account No."));
    end;

    [EventSubscriber(ObjectType::Table, Database::"Customer Bank Account", 'OnValidateBankAccount', '', false, false)]
    local procedure ValidateCustomerBank(var CustomerBankAccount: Record "Customer Bank Account"; FieldToValidate: Text)
    begin
#if not CLEAN30
        if not Feature.IsEnabled() then
            exit;
#endif
        if FieldToValidate = 'Bank Account No.' then
            ValidateDomesticAccount(CustomerBankAccount."Bank Account No.", CustomerBankAccount."Country/Region Code", CustomerBankAccount.Code, CustomerBankAccount.FieldCaption("Bank Account No."));
    end;

    [EventSubscriber(ObjectType::Table, Database::"Vendor Bank Account", 'OnValidateBankAccount', '', false, false)]
    local procedure ValidateVendorBank(var VendorBankAccount: Record "Vendor Bank Account"; FieldToValidate: Text)
    begin
#if not CLEAN30
        if not Feature.IsEnabled() then
            exit;
#endif
        if FieldToValidate = 'Bank Account No.' then
            ValidateDomesticAccount(VendorBankAccount."Bank Account No.", VendorBankAccount."Country/Region Code", VendorBankAccount.Code, VendorBankAccount.FieldCaption("Bank Account No."));
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"SEPA CT-Prepare Source", 'OnAfterCreateTempJnlLines', '', false, false)]
    local procedure CreateSEPAJournalLines(var TempGenJnlLine: Record "Gen. Journal Line" temporary)
    var
        Exported: Record "Ref. Payment - Exported FI";
    begin
#if not CLEAN30
        if not Feature.IsEnabled() then
            exit;
#endif
        Exported.SetRange(Transferred, false);
        Exported.SetRange("Applied Payments", false);
        Exported.SetRange("SEPA Payment", true);
        if Exported.FindSet() then
            repeat
                TempGenJnlLine.Init();
                TempGenJnlLine."Journal Template Name" := '';
                TempGenJnlLine."Journal Batch Name" := '';
                case Exported."Document Type" of
                    Exported."Document Type"::Invoice:
                        TempGenJnlLine."Document Type" := TempGenJnlLine."Document Type"::Payment;
                    else
                        TempGenJnlLine."Document Type" := TempGenJnlLine."Document Type"::" ";
                end;
                TempGenJnlLine."Document No." := Exported."Document No.";
                TempGenJnlLine."Line No." := Exported."No.";
                TempGenJnlLine."Account No." := Exported."Vendor No.";
                TempGenJnlLine."Account Type" := TempGenJnlLine."Account Type"::Vendor;
                TempGenJnlLine."Bal. Account Type" := TempGenJnlLine."Bal. Account Type"::"Bank Account";
                TempGenJnlLine."Bal. Account No." := Exported."Payment Account";
                TempGenJnlLine."External Document No." := Exported."External Document No.";
                TempGenJnlLine.Amount := Exported.Amount;
                TempGenJnlLine."Applies-to Doc. Type" := Enum::"Gen. Journal Document Type".FromInteger(Exported."Document Type");
                TempGenJnlLine."Applies-to Doc. No." := Exported."Document No.";
                TempGenJnlLine."Currency Code" := Exported."Currency Code";
                TempGenJnlLine."Due Date" := Exported."Due Date";
                TempGenJnlLine."Posting Date" := Exported."Payment Date";
                TempGenJnlLine."Recipient Bank Account" := Exported."Vendor Account";
                TempGenJnlLine.Description := CopyStr(Exported."Description 2", 1, MaxStrLen(TempGenJnlLine.Description));
                TempGenJnlLine."Message to Recipient" := Exported."External Document No.";
                TempGenJnlLine."Bank Message Type" := Exported."Message Type";
                TempGenJnlLine."Payment Message" := Exported."Invoice Message";
                TempGenJnlLine."Payment Message 2" := Exported."Invoice Message 2";
                TempGenJnlLine."Planned Payment Date" := Exported."Payment Date";
                TempGenJnlLine.Insert();
            until Exported.Next() = 0;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"SEPA CT-Fill Export Buffer", 'OnAfterFillExportBuffer', '', false, false)]
    local procedure MarkSEPAExported(var PaymentExportData: Record "Payment Export Data")
    var
        Exported: Record "Ref. Payment - Exported FI";
    begin
#if not CLEAN30
        if not Feature.IsEnabled() then
            exit;
#endif
        Exported.SetRange(Transferred, false);
        Exported.SetRange("Applied Payments", false);
        Exported.SetRange("SEPA Payment", true);
        if Exported.FindSet(true) then
            repeat
                Exported.Transferred := true;
                Exported."Transfer Date" := Today();
                Exported."Transfer Time" := Time();
                Exported."Batch Code" := PaymentExportData."Message ID";
                Exported."Payment Execution Date" := Exported."Payment Date";
                Exported.Modify();
                Exported.MarkAffiliatedAsTransferred();
            until Exported.Next() = 0;
    end;

    local procedure ValidateDomesticAccount(AccountNo: Text[30]; CountryCode: Code[10]; AccountCode: Code[20]; FieldCaption: Text)
    var
        BankNosCheck: Codeunit "Bank Nos Check FI";
    begin
        if not (CountryCode in ['', 'FI']) then
            exit;
        if StrLen(AccountNo) > 15 then
            Error(AccountTooLongErr, FieldCaption);
        if AccountNo <> '' then
            BankNosCheck.CheckBankAccount(CopyStr(AccountNo, 1, 15), AccountCode);
    end;
}
