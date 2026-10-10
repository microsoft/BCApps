// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Journal;

using Microsoft.Intercompany.BankAccount;
using Microsoft.Intercompany.GLAccount;
using Microsoft.Intercompany.Partner;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;

codeunit 8430 "IC Gen. Jnl.-Check Line"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Check Line", 'OnRunCheckOnAfterCheckAccountNoAndBalAccountNo', '', true, false)]
    local procedure OnRunCheckOnAfterCheckAccountNoAndBalAccountNo(var GenJournalLine: Record "Gen. Journal Line")
    var
        ICGLAccount: Record "IC G/L Account";
        ICBankAccount: Record "IC Bank Account";
    begin
        if GenJournalLine."IC Account No." = '' then
            exit;

        if GenJournalLine."IC Account Type" = GenJournalLine."IC Account Type"::"G/L Account" then
            if ICGLAccount.Get(GenJournalLine."IC Account No.") then
                ICGLAccount.TestField(Blocked, false, ErrorInfo.Create());

        if GenJournalLine."IC Account Type" = GenJournalLine."IC Account Type"::"Bank Account" then
            if ICBankAccount.Get(GenJournalLine."IC Account No.") then
                ICBankAccount.TestField(Blocked, false, ErrorInfo.Create());
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Check Line", 'OnCheckAccountNoOnAccountTypeICPartner', '', true, false)]
    local procedure OnCheckAccountNoOnAccountTypeICPartner(var GenJournalLine: Record "Gen. Journal Line")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        ICPartner: Record "IC Partner";
    begin
        ICPartner.Get(GenJournalLine."Account No.");
        ICPartner.CheckICPartner();

        if GenJournalLine."Journal Template Name" <> '' then begin
            GenJournalTemplate.Get(GenJournalLine."Journal Template Name");
            if GenJournalTemplate.Type <> GenJournalTemplate.Type::Intercompany then
                GenJournalLine.FieldError("Account Type", ErrorInfo.Create());
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Check Line", 'OnCheckBalAccountNoOnBalAccountTypeICPartner', '', true, false)]
    local procedure OnCheckBalAccountNoOnBalAccountTypeICPartner(var GenJournalLine: Record "Gen. Journal Line")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        ICPartner: Record "IC Partner";
    begin
        ICPartner.Get(GenJournalLine."Bal. Account No.");
        ICPartner.CheckICPartner();

        if GenJournalLine."Journal Template Name" <> '' then begin
            GenJournalTemplate.Get(GenJournalLine."Journal Template Name");
            if GenJournalTemplate.Type <> GenJournalTemplate.Type::Intercompany then
                GenJournalLine.FieldError("Bal. Account Type", ErrorInfo.Create());
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Check Line", 'OnCheckICPartnerOnAfterCheckCustomer', '', true, false)]
    local procedure OnCheckICPartnerOnAfterCheckCustomer(AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; DocumentType: Option; Customer: Record Customer; GenJnlLine: Record "Gen. Journal Line")
    var
        ICPartner: Record "IC Partner";
        GenJnlTemplate: Record "Gen. Journal Template";
    begin
        if (Customer."IC Partner Code" = '') or (GenJnlLine."Journal Template Name" = '') then
            exit;

        if not GenJnlTemplate.Get(GenJnlLine."Journal Template Name") then
            exit;

        if (GenJnlTemplate.Type = GenJnlTemplate.Type::Intercompany) and ICPartner.Get(Customer."IC Partner Code") then
            ICPartner.CheckICPartnerIndirect(Format(AccountType), AccountNo);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Check Line", 'OnCheckICPartnerOnAfterCheckVendor', '', true, false)]
    local procedure OnCheckICPartnerOnAfterCheckVendor(AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; DocumentType: Option; Vendor: Record Vendor; GenJnlLine: Record "Gen. Journal Line")
    var
        ICPartner: Record "IC Partner";
        GenJnlTemplate: Record "Gen. Journal Template";
    begin
        if (Vendor."IC Partner Code" = '') or (GenJnlLine."Journal Template Name" = '') then
            exit;

        if not GenJnlTemplate.Get(GenJnlLine."Journal Template Name") then
            exit;

        if (GenJnlTemplate.Type = GenJnlTemplate.Type::Intercompany) and ICPartner.Get(Vendor."IC Partner Code") then
            ICPartner.CheckICPartnerIndirect(Format(AccountType), AccountNo);
    end;
}