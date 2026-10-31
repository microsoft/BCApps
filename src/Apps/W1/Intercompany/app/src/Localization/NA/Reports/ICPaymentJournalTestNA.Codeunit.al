#if INTERCOMPANY_NA
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Intercompany;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Reports;
using Microsoft.Intercompany.BankAccount;
using Microsoft.Intercompany.GLAccount;
using Microsoft.Intercompany.Journal;
using Microsoft.Intercompany.Partner;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;

codeunit 8559 "IC Payment Journal Test NA"
{
    Access = Internal;

    var
        MustBeSpecifiedErr: Label '%1 must be specified.', Comment = ' %1 = field, value, or account information';
        CannotBeSpecifiedErr: Label '%1 cannot be specified.', Comment = ' %1 = field, value, or account information';
        DoesNotExistErr: Label '%1 %2 does not exist.', Comment = ' %1 = field, value, or account information, %2 = field, value, or account information';
        MustBeForErr: Label '%1 must be %2 for %3 %4.', Comment = ' %1 = field, value, or account information, %2 = field, value, or account information, %3 = field, value, or account information, %4 = field, value, or account information';
        CannotEnterErr: Label 'You cannot enter G/L Account or Bank Account in both %1 and %2.', Comment = ' %1 = field, value, or account information, %2 = field, value, or account information';
        IsLinkedToErr: Label '%1 %2 is linked to %3 %4.', Comment = ' %1 = field, value, or account information, %2 = field, value, or account information, %3 = field, value, or account information, %4 = field, value, or account information';
        MustNotBeSpecifiedErr: Label '%1 must not be specified when %2 is %3.', Comment = ' %1 = field, value, or account information, %2 = field, value, or account information, %3 = field, value, or account information';
        MustNotBeSpecifiedWhenNotICErr: Label '%1 must not be specified when the document is not an intercompany transaction.', Comment = ' %1 = field, value, or account information';

    [EventSubscriber(ObjectType::Report, Report::"Payment Journal - Test", 'OnCheckCustomerIC', '', false, false)]
    local procedure OnCheckCustomerIC(GenJnlLine: Record "Gen. Journal Line"; Cust: Record Customer; GenJnlTemplate: Record "Gen. Journal Template"; var ErrorCounter: Integer; var ErrorText: array[50] of Text[250])
    var
        ICPartner: Record "IC Partner";
    begin
        if (Cust."IC Partner Code" <> '') and (GenJnlTemplate.Type = GenJnlTemplate.Type::Intercompany) then
            if ICPartner.Get(Cust."IC Partner Code") then begin
                if ICPartner.Blocked then
                    AddError(
                      StrSubstNo(
                        '%1 %2',
                        StrSubstNo(
                          IsLinkedToErr,
                          Cust.TableCaption(), GenJnlLine."Account No.", ICPartner.TableCaption(), GenJnlLine."IC Partner Code"),
                        StrSubstNo(
                          MustBeForErr,
                          ICPartner.FieldCaption(Blocked), false, ICPartner.TableCaption(), Cust."IC Partner Code")), ErrorCounter, ErrorText);
            end else
                AddError(
                  StrSubstNo(
                    '%1 %2',
                    StrSubstNo(
                      IsLinkedToErr,
                      Cust.TableCaption(), GenJnlLine."Account No.", ICPartner.TableCaption(), Cust."IC Partner Code"),
                    StrSubstNo(
                      DoesNotExistErr,
                      ICPartner.TableCaption(), Cust."IC Partner Code")), ErrorCounter, ErrorText);
    end;

    [EventSubscriber(ObjectType::Report, Report::"Payment Journal - Test", 'OnCheckVendorIC', '', false, false)]
    local procedure OnCheckVendorIC(GenJnlLine: Record "Gen. Journal Line"; Cust: Record Customer; Vend: Record Vendor; GenJnlTemplate: Record "Gen. Journal Template"; var ErrorCounter: Integer; var ErrorText: array[50] of Text[250])
    var
        ICPartner: Record "IC Partner";
    begin
        if (Vend."IC Partner Code" <> '') and (GenJnlTemplate.Type = GenJnlTemplate.Type::Intercompany) then
            if ICPartner.Get(Cust."IC Partner Code") then begin
                if ICPartner.Blocked then
                    AddError(
                      StrSubstNo(
                        '%1 %2',
                        StrSubstNo(
                          IsLinkedToErr,
                          Vend.TableCaption(), GenJnlLine."Account No.", ICPartner.TableCaption(), Vend."IC Partner Code"),
                        StrSubstNo(
                          MustBeForErr,
                          ICPartner.FieldCaption(Blocked), false, ICPartner.TableCaption(), Vend."IC Partner Code")), ErrorCounter, ErrorText);
            end else
                AddError(
                  StrSubstNo(
                    '%1 %2',
                    StrSubstNo(
                      IsLinkedToErr,
                      Vend.TableCaption(), GenJnlLine."Account No.", ICPartner.TableCaption(), GenJnlLine."IC Partner Code"),
                    StrSubstNo(
                      DoesNotExistErr,
                      ICPartner.TableCaption(), Vend."IC Partner Code")), ErrorCounter, ErrorText);
    end;

    [EventSubscriber(ObjectType::Report, Report::"Payment Journal - Test", 'OnCheckICPartnerAccount', '', false, false)]
    local procedure OnCheckICPartnerAccount(GenJnlLine: Record "Gen. Journal Line"; var AccName2: Text[100]; var ErrorCounter: Integer; var ErrorText: array[50] of Text[250])
    var
        ICPartner: Record "IC Partner";
    begin
        if not ICPartner.Get(GenJnlLine."Account No.") then
            AddError(
              StrSubstNo(
                DoesNotExistErr,
                ICPartner.TableCaption(), GenJnlLine."Account No."), ErrorCounter, ErrorText)
        else begin
            AccName2 := ICPartner.Name;
            if ICPartner.Blocked then
                AddError(
                  StrSubstNo(
                    MustBeForErr,
                    ICPartner.FieldCaption(Blocked), false, ICPartner.TableCaption(), GenJnlLine."Account No."), ErrorCounter, ErrorText);
        end;
    end;

    [EventSubscriber(ObjectType::Report, Report::"Payment Journal - Test", 'OnCheckICDocument', '', false, false)]
    local procedure OnCheckICDocument(GenJournalLine: Record "Gen. Journal Line"; GenJnlTemplate: Record "Gen. Journal Template"; LastDate: Date; LastDocType: Enum "Gen. Journal Document Type"; LastDocNo: Code[20]; var CurrentICPartner: Code[20]; var ErrorCounter: Integer; var ErrorText: array[50] of Text[250])
    var
        GenJnlLine4: Record "Gen. Journal Line";
    begin
        if GenJnlTemplate.Type = GenJnlTemplate.Type::Intercompany then begin
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
            CheckICAccountNo(GenJournalLine, CurrentICPartner, ErrorCounter, ErrorText);
        end;
    end;

    local procedure CheckICAccountNo(GenJournalLine: Record "Gen. Journal Line"; CurrentICPartner: Code[20]; var ErrorCounter: Integer; var ErrorText: array[50] of Text[250])
    var
        ICGLAccount: Record "IC G/L Account";
        ICBankAccount: Record "IC Bank Account";
    begin
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
                        if GenJournalLine."IC Account Type" = "IC Journal Account Type"::"G/L Account" then
                            if ICGLAccount.Get(GenJournalLine."IC Account No.") then
                                if ICGLAccount.Blocked then
                                    AddError(StrSubstNo(MustBeForErr, ICGLAccount.FieldCaption(Blocked), false,
                                        GenJournalLine.FieldCaption("IC Account No."), GenJournalLine."IC Account No."), ErrorCounter, ErrorText);

                        if GenJournalLine."IC Account Type" = "IC Journal Account Type"::"Bank Account" then
                            if ICBankAccount.Get(GenJournalLine."IC Account No.", CurrentICPartner) then
                                if ICBankAccount.Blocked then
                                    AddError(StrSubstNo(MustBeForErr, ICGLAccount.FieldCaption(Blocked), false,
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
                    AddError(StrSubstNo(MustNotBeSpecifiedWhenNotICErr, GenJournalLine.FieldCaption("IC Account No.")), ErrorCounter, ErrorText);
            end;
    end;

    local procedure AddError(Text: Text[250]; var ErrorCounter: Integer; var ErrorText: array[50] of Text[250])
    begin
        ErrorCounter := ErrorCounter + 1;
        ErrorText[ErrorCounter] := Text;
    end;
}
#endif
