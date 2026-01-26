// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Company;

using Microsoft.Bank.BankAccount;
using Microsoft.Bank.Payment;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Foundation.Address;
using System.Environment;

codeunit 1306 "Company Information Mgt."
{
    InherentEntitlements = X;
    InherentPermissions = X;
    Permissions = tabledata "Company Information" = r;

    trigger OnRun()
    begin
    end;

    var
        CompanyBankAccountTxt: Label 'CHECKING';
        XPAYMENTTxt: Label 'PAYMENT', Comment = 'Payment';
        XPmtRegTxt: Label 'PMT REG', Comment = 'Payment Registration';
        CompanyBankAccountPostGroupTxt: Label 'CHECKING', Comment = 'Same as Bank Account Posting Group';
        CompanyNameWarningLbl: Label 'Do not add personal data to the company name as this is not treated as restricted data.';

    internal procedure GetCompanyNameClassificationWarning(): Text
    begin
        exit(CompanyNameWarningLbl);
    end;

    local procedure UpdateGeneralJournalBatch(BankAccount: Record "Bank Account"; JournalTemplateName: Code[10]; JournalBatchName: Code[10])
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        if GenJournalBatch.Get(JournalTemplateName, JournalBatchName) then
            if (GenJournalBatch."Bal. Account Type" = GenJournalBatch."Bal. Account Type"::"Bank Account") and (GenJournalBatch."Bal. Account No." = '') then begin
                GenJournalBatch.Validate("Bal. Account No.", BankAccount."No.");
                GenJournalBatch.Modify();
            end;
    end;

    procedure UpdateCompanyBankAccount(var CompanyInformation: Record "Company Information"; BankAccountPostingGroup: Code[20]; var BankAccount: Record "Bank Account")
    begin
        // create or update existing company bank account with the information entered by the user
        // update general journal payment batches to point to the company bank account (unless a bank account is already specified in them)
        if ((CompanyInformation."Bank Branch No." = '') and (CompanyInformation."Bank Account No." = '')) and ((CompanyInformation."SWIFT Code" = '') and (CompanyInformation.IBAN = '')) then
            exit;
        UpdateBankAccount(BankAccount, CompanyInformation, BankAccountPostingGroup);
        UpdateGeneralJournalBatch(BankAccount, XPAYMENTTxt, XPmtRegTxt);
        UpdatePaymentRegistrationSetup(BankAccount, XPAYMENTTxt, XPmtRegTxt);
    end;

    local procedure UpdatePaymentRegistrationSetup(BankAccount: Record "Bank Account"; JournalTemplateName: Code[10]; JournalBatchName: Code[10])
    var
        PaymentRegistrationSetup: Record "Payment Registration Setup";
    begin
        if not PaymentRegistrationSetup.Get(UserId) then begin
            PaymentRegistrationSetup."User ID" := CopyStr(UserId(), 1, MaxStrLen(PaymentRegistrationSetup."User ID"));
            PaymentRegistrationSetup.Insert();
        end;
        PaymentRegistrationSetup."Journal Template Name" := JournalTemplateName;
        PaymentRegistrationSetup."Journal Batch Name" := JournalBatchName;
        PaymentRegistrationSetup."Bal. Account Type" := PaymentRegistrationSetup."Bal. Account Type"::"Bank Account";
        PaymentRegistrationSetup."Bal. Account No." := BankAccount."No.";
        PaymentRegistrationSetup."Use this Account as Def." := true;
        PaymentRegistrationSetup."Auto Fill Date Received" := true;
        PaymentRegistrationSetup.Modify();
    end;

    local procedure UpdateBankAccount(var BankAccount: Record "Bank Account"; CompanyInformation: Record "Company Information"; BankAccountPostingGroup: Code[20])
    var
        BankAccPostingGroup: Record "Bank Account Posting Group";
        IsCompanyBankAcc: Boolean;
    begin
        if BankAccount."No." = '' then
            BankAccount."No." := CompanyBankAccountTxt;

        if not BankAccount.Get(BankAccount."No.") then begin
            BankAccount.Init();
            BankAccount."No." := CompanyBankAccountTxt;
            BankAccount.Insert();

            IsCompanyBankAcc := true;
        end;
        BankAccount.Validate(Name, CompanyInformation."Bank Name");
        BankAccount.Validate("Bank Branch No.", CompanyInformation."Bank Branch No.");
        BankAccount.Validate("Country/Region Code", CompanyInformation."Country/Region Code");
        BankAccount.Validate("Bank Account No.", CompanyInformation."Bank Account No.");
        BankAccount.Validate("SWIFT Code", CompanyInformation."SWIFT Code");
        BankAccount.Validate(IBAN, CompanyInformation.IBAN);
        if (BankAccountPostingGroup = '') and IsCompanyBankAcc then
            BankAccountPostingGroup := CompanyBankAccountPostGroupTxt;
        if BankAccPostingGroup.Get(BankAccountPostingGroup) then
            BankAccount.Validate("Bank Acc. Posting Group", BankAccPostingGroup.Code);
        BankAccount.Modify();
    end;

    procedure GetCompanyBankAccount(): Code[20]
    begin
        exit(CompanyBankAccountTxt);
    end;

    procedure GetCompanyBankAccountPostingGroup(): Code[20]
    var
        BankAccount: Record "Bank Account";
    begin
        if BankAccount.Get(CompanyBankAccountTxt) then
            exit(BankAccount."Bank Acc. Posting Group");
        exit('');
    end;

    [InherentPermissions(PermissionObjectType::TableData, Database::"Company Information", 'r')]
    procedure IsDemoCompany(): Boolean
    var
        CompanyInformation: Record "Company Information";
    begin
        Companyinformation.SetLoadFields("Demo Company");
        if CompanyInformation.Get() then;
        exit(CompanyInformation."Demo Company");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Company Information", 'OnAfterModifyEvent', '', false, false)]
    procedure SetCompanyDisplayNameOnCompanyInformationModify(var Rec: Record "Company Information"; var xRec: Record "Company Information"; RunTrigger: Boolean)
    var
        Company: Record Company;
    begin
        if Rec.IsTemporary then
            exit;

        Company.LockTable();
        if Company.Get(Rec.CurrentCompany) then
            if (Company."Display Name" <> Rec.Name) and (Rec.Name <> '') and (xRec.Name <> Rec.Name) then begin
                Company.Validate("Display Name", Rec.Name);
                Company.Modify(true);
            end;
    end;

    [Scope('OnPrem')]
    procedure IsEUCompany(CompanyInformation: Record "Company Information"): Boolean
    var
        CountryRegion: Record "Country/Region";
    begin
        if not CountryRegion.Get(CompanyInformation."Country/Region Code") then
            exit(false);

        exit(CountryRegion."EU Country/Region Code" <> '');
    end;

    procedure GetCompanyDisplayNameDefaulted(Company: Record Company): Text[250]
    begin
        if Company."Display Name" <> '' then
            exit(Company."Display Name");
        exit(Company.Name)
    end;
}
