// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Reports;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Intercompany.BankAccount;
using Microsoft.Intercompany.GLAccount;
using Microsoft.Intercompany.Partner;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;

/// <summary>
/// Handles Intercompany-specific validations for report 2 General Journal - Test.
/// </summary>
codeunit 8434 "IC General Journal - Test"
{
    var
        MustBeSpecifiedErr: Label '%1 must be specified.', Comment = ' %1 = field name';
        CannotBeSpecifiedErr: Label '%1 cannot be specified.', Comment = ' %1 = field name';
        DoesNotExistErr: Label '%1 %2 does not exist.', Comment = ' %1 = table name, %2 = code';
        MustBeForErr: Label '%1 must be %2 for %3 %4.', Comment = ' %1 = field caption, %2 = value, %3 = table caption, %4 = code';
        CannotEnterErr: Label 'You cannot enter G/L Account or Bank Account in both %1 and %2.', Comment = ' %1 = field name, %2 = field name';
        IsLinkedToErr: Label '%1 %2 is linked to %3 %4.', Comment = ' %1 = field caption, %2 = value, %3 = table caption, %4 = code';
        MustNotBeSpecifiedErr: Label '%1 must not be specified when %2 is %3.', Comment = ' %1 = field caption, %2 = field caption, %3 = value';
        MustNotBeSpecifiedWhenNotIntercompanyErr: Label '%1 must not be specified when the document is not an intercompany transaction.', Comment = ' %1 = field caption';

    [EventSubscriber(ObjectType::Report, Report::"General Journal - Test", 'OnAfterCheckCustOnBeforeCustPosting', '', false, false)]
    local procedure OnAfterCheckCustOnBeforeCustPosting(var GenJournalLine: Record "Gen. Journal Line"; Customer: Record Customer; GenJournalTemplate: Record "Gen. Journal Template"; var ErrorCounter: Integer; var ErrorText: array[50] of Text[250])
    var
        ICPartner: Record "IC Partner";
    begin
        if (Customer."IC Partner Code" <> '') and (GenJournalTemplate.Type = GenJournalTemplate.Type::Intercompany) then
            if ICPartner.Get(Customer."IC Partner Code") then begin
                if ICPartner.Blocked then
                    AddError(
                      StrSubstNo(
                        '%1 %2',
                        StrSubstNo(
                          IsLinkedToErr,
                          Customer.TableCaption(), GenJournalLine."Account No.", ICPartner.TableCaption(), GenJournalLine."IC Partner Code"),
                        StrSubstNo(
                          MustBeForErr,
                          ICPartner.FieldCaption(Blocked), false, ICPartner.TableCaption(), Customer."IC Partner Code")),
                      ErrorCounter,
                      ErrorText);
            end else
                AddError(
                  StrSubstNo(
                    '%1 %2',
                    StrSubstNo(
                      IsLinkedToErr,
                      Customer.TableCaption(), GenJournalLine."Account No.", ICPartner.TableCaption(), Customer."IC Partner Code"),
                    StrSubstNo(
                      DoesNotExistErr,
                      ICPartner.TableCaption(), Customer."IC Partner Code")),
                  ErrorCounter,
                  ErrorText);
    end;

    [EventSubscriber(ObjectType::Report, Report::"General Journal - Test", 'OnAfterCheckVendOnBeforeVendPosting', '', false, false)]
    local procedure OnAfterCheckVendOnBeforeVendPosting(var GenJournalLine: Record "Gen. Journal Line"; Vendor: Record Vendor; GenJournalTemplate: Record "Gen. Journal Template"; var ErrorCounter: Integer; var ErrorText: array[50] of Text[250])
    var
        ICPartner: Record "IC Partner";
    begin
        if (Vendor."IC Partner Code" <> '') and (GenJournalTemplate.Type = GenJournalTemplate.Type::Intercompany) then
            if ICPartner.Get(Vendor."IC Partner Code") then begin
                if ICPartner.Blocked then
                    AddError(
                      StrSubstNo(
                        '%1 %2',
                        StrSubstNo(
                          IsLinkedToErr,
                          Vendor.TableCaption(), GenJournalLine."Account No.", ICPartner.TableCaption(), Vendor."IC Partner Code"),
                        StrSubstNo(
                          MustBeForErr,
                          ICPartner.FieldCaption(Blocked), false, ICPartner.TableCaption(), Vendor."IC Partner Code")),
                      ErrorCounter,
                      ErrorText);
            end else
                AddError(
                  StrSubstNo(
                    '%1 %2',
                    StrSubstNo(
                      IsLinkedToErr,
                      Vendor.TableCaption(), GenJournalLine."Account No.", ICPartner.TableCaption(), GenJournalLine."IC Partner Code"),
                    StrSubstNo(
                      DoesNotExistErr,
                      ICPartner.TableCaption(), Vendor."IC Partner Code")),
                  ErrorCounter,
                  ErrorText);
    end;

    [EventSubscriber(ObjectType::Report, Report::"General Journal - Test", 'OnCheckAccountTypesOnAccountTypeICPartner', '', false, false)]
    local procedure OnCheckAccountTypesOnAccountTypeICPartner(var GenJournalLine: Record "Gen. Journal Line"; var Name: Text[100]; var ErrorCounter: Integer; var ErrorText: array[50] of Text[250])
    var
        ICPartner: Record "IC Partner";
    begin
        if not ICPartner.Get(GenJournalLine."Account No.") then
            AddError(
              StrSubstNo(
                DoesNotExistErr,
                ICPartner.TableCaption(), GenJournalLine."Account No."),
              ErrorCounter,
              ErrorText)
        else begin
            Name := ICPartner.Name;
            if ICPartner.Blocked then
                AddError(
                  StrSubstNo(
                    MustBeForErr,
                    ICPartner.FieldCaption(Blocked), false, ICPartner.TableCaption(), GenJournalLine."Account No."),
                  ErrorCounter,
                  ErrorText);
        end;
    end;

    [EventSubscriber(ObjectType::Report, Report::"General Journal - Test", 'OnCheckICDocument', '', false, false)]
    local procedure OnCheckICDocument(var GenJournalLine: Record "Gen. Journal Line"; GenJournalTemplate: Record "Gen. Journal Template"; LastDate: Date; LastDocType: Enum "Gen. Journal Document Type"; LastDocNo: Code[20]; var CurrentICPartner: Code[20]; var ErrorCounter: Integer; var ErrorText: array[50] of Text[250])
    var
        GenJnlLine4: Record "Gen. Journal Line";
        ICGLAccount: Record "IC G/L Account";
        ICBankAccount: Record "IC Bank Account";
    begin
        if GenJournalTemplate.Type = GenJournalTemplate.Type::Intercompany then begin
            if (GenJournalLine."Posting Date" <> LastDate) or (GenJournalLine."Document Type" <> LastDocType) or (GenJournalLine."Document No." <> LastDocNo) then begin
                GenJnlLine4.SetCurrentKey("Journal Template Name", "Journal Batch Name", "Posting Date", "Document No.");
                GenJnlLine4.SetRange("Journal Template Name", GenJournalLine."Journal Template Name");
                GenJnlLine4.SetRange("Journal Batch Name", GenJournalLine."Journal Batch Name");
                GenJnlLine4.SetRange("Posting Date", GenJournalLine."Posting Date");
                GenJnlLine4.SetRange("Document No.", GenJournalLine."Document No.");
                GenJnlLine4.SetFilter("IC Partner Code", '<>%1', '');
                if GenJnlLine4.FindFirst() then
                    CurrentICPartner := GenJnlLine4."IC Partner Code"
                else
                    CurrentICPartner := '';
            end;

            if (CurrentICPartner <> '') and (GenJournalLine."IC Direction" = GenJournalLine."IC Direction"::Outgoing) then begin
                if (GenJournalLine."Account Type" in [GenJournalLine."Account Type"::"G/L Account", GenJournalLine."Account Type"::"Bank Account"]) and
                   (GenJournalLine."Bal. Account Type" in [GenJournalLine."Bal. Account Type"::"G/L Account", GenJournalLine."Account Type"::"Bank Account"]) and
                   (GenJournalLine."Account No." <> '') and
                   (GenJournalLine."Bal. Account No." <> '')
                then
                    AddError(StrSubstNo(CannotEnterErr, GenJournalLine.FieldCaption("Account No."), GenJournalLine.FieldCaption("Bal. Account No.")), ErrorCounter, ErrorText)
                else
                    if ((GenJournalLine."Account Type" in [GenJournalLine."Account Type"::"G/L Account", GenJournalLine."Account Type"::"Bank Account"]) and (GenJournalLine."Account No." <> '')) xor
                       ((GenJournalLine."Bal. Account Type" in [GenJournalLine."Bal. Account Type"::"G/L Account", GenJournalLine."Account Type"::"Bank Account"]) and
                        (GenJournalLine."Bal. Account No." <> ''))
                    then
                        if GenJournalLine."IC Account No." = '' then
                            AddError(StrSubstNo(MustBeSpecifiedErr, GenJournalLine.FieldCaption("IC Account No.")), ErrorCounter, ErrorText)
                        else begin
                            if GenJournalLine."IC Account Type" = GenJournalLine."IC Account Type"::"G/L Account" then
                                if ICGLAccount.Get(GenJournalLine."IC Account No.") then
                                    if ICGLAccount.Blocked then
                                        AddError(StrSubstNo(MustBeForErr, ICGLAccount.FieldCaption(Blocked), false,
                                            GenJournalLine.FieldCaption("IC Account No."), GenJournalLine."IC Account No."), ErrorCounter, ErrorText);

                            if GenJournalLine."IC Account Type" = GenJournalLine."IC Account Type"::"Bank Account" then
                                if ICBankAccount.Get(GenJournalLine."IC Account No.", CurrentICPartner) then
                                    if ICBankAccount.Blocked then
                                        AddError(StrSubstNo(MustBeForErr, ICBankAccount.FieldCaption(Blocked), false,
                                            GenJournalLine.FieldCaption("IC Account No."), GenJournalLine."IC Account No."), ErrorCounter, ErrorText);
                        end
                    else
                        if GenJournalLine."IC Account No." <> '' then
                            AddError(StrSubstNo(CannotBeSpecifiedErr, GenJournalLine.FieldCaption("IC Account No.")), ErrorCounter, ErrorText);
            end else
                if GenJournalLine."IC Account No." <> '' then begin
                    if GenJournalLine."IC Direction" = GenJournalLine."IC Direction"::Incoming then
                        AddError(StrSubstNo(MustNotBeSpecifiedErr, GenJournalLine.FieldCaption("IC Account No."), GenJournalLine.FieldCaption("IC Direction"), Format(GenJournalLine."IC Direction")), ErrorCounter, ErrorText);
                    if CurrentICPartner = '' then
                        AddError(StrSubstNo(MustNotBeSpecifiedWhenNotIntercompanyErr, GenJournalLine.FieldCaption("IC Account No.")), ErrorCounter, ErrorText);
                end;
        end;
    end;

    local procedure AddError(Text: Text[250]; var ErrorCounter: Integer; var ErrorText: array[50] of Text[250])
    begin
        ErrorCounter := ErrorCounter + 1;
        ErrorText[ErrorCounter] := Text;
    end;
}
