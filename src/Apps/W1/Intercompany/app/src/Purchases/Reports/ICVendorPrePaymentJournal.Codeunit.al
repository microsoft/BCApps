// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Reports;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Intercompany.BankAccount;
using Microsoft.Intercompany.GLAccount;
using Microsoft.Intercompany.Partner;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;

codeunit 8451 "IC Vendor Pre-Payment Journal"
{
    Access = Internal;

    [EventSubscriber(ObjectType::Report, Report::"Vendor Pre-Payment Journal", 'OnAfterCheckCustomerICPartner', '', false, false)]
    local procedure OnAfterCheckCustomerICPartnerSub(var GenJnlLine: Record "Gen. Journal Line"; var Cust: Record Customer; var GenJnlTemplate: Record "Gen. Journal Template"; var ErrorText: array[50] of Text[250]; var ErrorCounter: Integer)
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
                          PartnerLinkedToAccountErr,
                          Cust.TableCaption(), GenJnlLine."Account No.", ICPartner.TableCaption(), GenJnlLine."IC Partner Code"),
                        StrSubstNo(
                          FieldMustBeValueForRecordErr,
                          ICPartner.FieldCaption(Blocked), false, ICPartner.TableCaption(), Cust."IC Partner Code")),
                      ErrorText, ErrorCounter);
            end else
                AddError(
                  StrSubstNo(
                    '%1 %2',
                    StrSubstNo(
                      PartnerLinkedToAccountErr,
                      Cust.TableCaption(), GenJnlLine."Account No.", ICPartner.TableCaption(), Cust."IC Partner Code"),
                    StrSubstNo(
                      RecordDoesNotExistErr,
                      ICPartner.TableCaption(), Cust."IC Partner Code")),
                  ErrorText, ErrorCounter);
    end;

    [EventSubscriber(ObjectType::Report, Report::"Vendor Pre-Payment Journal", 'OnAfterCheckVendorICPartner', '', false, false)]
    local procedure OnAfterCheckVendorICPartnerSub(var GenJnlLine: Record "Gen. Journal Line"; var Vend: Record Vendor; var GenJnlTemplate: Record "Gen. Journal Template"; var ErrorText: array[50] of Text[250]; var ErrorCounter: Integer)
    var
        ICPartner: Record "IC Partner";
    begin
        if (Vend."IC Partner Code" <> '') and (GenJnlTemplate.Type = GenJnlTemplate.Type::Intercompany) then
            if ICPartner.Get(Vend."IC Partner Code") then begin
                if ICPartner.Blocked then
                    AddError(
                      StrSubstNo(
                        '%1 %2',
                        StrSubstNo(
                          PartnerLinkedToAccountErr,
                          Vend.TableCaption(), GenJnlLine."Account No.", ICPartner.TableCaption(), Vend."IC Partner Code"),
                        StrSubstNo(
                          FieldMustBeValueForRecordErr,
                          ICPartner.FieldCaption(Blocked), false, ICPartner.TableCaption(), Vend."IC Partner Code")),
                      ErrorText, ErrorCounter);
            end else
                AddError(
                  StrSubstNo(
                    '%1 %2',
                    StrSubstNo(
                      PartnerLinkedToAccountErr,
                      Vend.TableCaption(), GenJnlLine."Account No.", ICPartner.TableCaption(), GenJnlLine."IC Partner Code"),
                    StrSubstNo(
                      RecordDoesNotExistErr,
                      ICPartner.TableCaption(), Vend."IC Partner Code")),
                  ErrorText, ErrorCounter);
    end;

    [EventSubscriber(ObjectType::Report, Report::"Vendor Pre-Payment Journal", 'OnCheckICPartner', '', false, false)]
    local procedure OnCheckICPartnerSub(var GenJnlLine: Record "Gen. Journal Line"; var AccName: Text[100]; var ErrorText: array[50] of Text[250]; var ErrorCounter: Integer)
    var
        ICPartner: Record "IC Partner";
    begin
        if not ICPartner.Get(GenJnlLine."Account No.") then
            AddError(
              StrSubstNo(
                RecordDoesNotExistErr,
                ICPartner.TableCaption(), GenJnlLine."Account No."),
              ErrorText, ErrorCounter)
        else begin
            AccName := ICPartner.Name;
            if ICPartner.Blocked then
                AddError(
                  StrSubstNo(
                    FieldMustBeValueForRecordErr,
                    ICPartner.FieldCaption(Blocked), false, ICPartner.TableCaption(), GenJnlLine."Account No."),
                  ErrorText, ErrorCounter);
        end;
    end;

    [EventSubscriber(ObjectType::Report, Report::"Vendor Pre-Payment Journal", 'OnCheckICDocument', '', false, false)]
    local procedure OnCheckICDocumentSub(var GenJnlLine: Record "Gen. Journal Line"; var GenJnlTemplate: Record "Gen. Journal Template"; LastDate: Date; LastDocType: Enum "Gen. Journal Document Type"; LastDocNo: Code[20]; var CurrentICPartner: Code[20]; var ErrorText: array[50] of Text[250]; var ErrorCounter: Integer)
    var
        GenJnlLine4: Record "Gen. Journal Line";
    begin
        if GenJnlTemplate.Type = GenJnlTemplate.Type::Intercompany then begin
            if (GenJnlLine."Posting Date" <> LastDate) or (GenJnlLine."Document Type" <> LastDocType) or (GenJnlLine."Document No." <> LastDocNo) then begin
                GenJnlLine4.SetCurrentKey("Journal Template Name", "Journal Batch Name", "Posting Date", "Document No.");
                GenJnlLine4.SetRange("Journal Template Name", GenJnlLine."Journal Template Name");
                GenJnlLine4.SetRange("Journal Batch Name", GenJnlLine."Journal Batch Name");
                GenJnlLine4.SetRange("Posting Date", GenJnlLine."Posting Date");
                GenJnlLine4.SetRange("Document No.", GenJnlLine."Document No.");
                GenJnlLine4.SetFilter("IC Partner Code", '<>%1', '');
                if GenJnlLine4.FindFirst() then
                    CurrentICPartner := GenJnlLine4."IC Partner Code"
                else
                    CurrentICPartner := '';
            end;
            if (CurrentICPartner <> '') and (GenJnlLine."IC Direction" = GenJnlLine."IC Direction"::Outgoing) then
                if (GenJnlLine."Account Type" in [GenJnlLine."Account Type"::"G/L Account", GenJnlLine."Account Type"::"Bank Account"]) and
                   (GenJnlLine."Bal. Account Type" in [GenJnlLine."Bal. Account Type"::"G/L Account", GenJnlLine."Account Type"::"Bank Account"]) and
                   (GenJnlLine."Account No." <> '') and
                   (GenJnlLine."Bal. Account No." <> '')
                then
                    AddError(
                      StrSubstNo(
                        GLAndBankBothEnteredErr, GenJnlLine.FieldCaption("Account No."), GenJnlLine.FieldCaption("Bal. Account No.")),
                      ErrorText, ErrorCounter)
                else
                    if ((GenJnlLine."Account Type" in [GenJnlLine."Account Type"::"G/L Account", GenJnlLine."Account Type"::"Bank Account"]) and (GenJnlLine."Account No." <> '')) xor
                       ((GenJnlLine."Bal. Account Type" in [GenJnlLine."Bal. Account Type"::"G/L Account", GenJnlLine."Account Type"::"Bank Account"]) and
                        (GenJnlLine."Bal. Account No." <> ''))
                    then
                        CheckICAccountNo(GenJnlLine, CurrentICPartner, ErrorText, ErrorCounter);
        end;
    end;

    local procedure CheckICAccountNo(var GenJnlLine: Record "Gen. Journal Line"; CurrentICPartner: Code[20]; var ErrorText: array[50] of Text[250]; var ErrorCounter: Integer)
    var
        ICGLAccount: Record "IC G/L Account";
        ICBankAccount: Record "IC Bank Account";
    begin
        if GenJnlLine."IC Account No." = '' then
            AddError(StrSubstNo(ICAccNoMustBeSpecifiedErr, GenJnlLine.FieldCaption("IC Account No.")), ErrorText, ErrorCounter)
        else begin
            if GenJnlLine."IC Account Type" = GenJnlLine."IC Account Type"::"G/L Account" then
                if ICGLAccount.Get(GenJnlLine."IC Account No.") then
                    if ICGLAccount.Blocked then
                        AddError(StrSubstNo(FieldMustBeValueForRecordErr, ICGLAccount.FieldCaption(Blocked), false,
                            GenJnlLine.FieldCaption("IC Account No."), GenJnlLine."IC Account No."), ErrorText, ErrorCounter)
                    else
                        if GenJnlLine."IC Account No." <> '' then
                            AddError(StrSubstNo(ICAccNoCannotBeSpecifiedErr, GenJnlLine.FieldCaption("IC Account No.")), ErrorText, ErrorCounter)
                        else begin
                            if GenJnlLine."IC Direction" = GenJnlLine."IC Direction"::Incoming then
                                AddError(StrSubstNo(ICAccNoNotAllowedForDirectionErr, GenJnlLine.FieldCaption("IC Account No."),
                                    GenJnlLine.FieldCaption("IC Direction"), Format(GenJnlLine."IC Direction")), ErrorText, ErrorCounter);
                            if CurrentICPartner = '' then
                                AddError(StrSubstNo(ICAccNoNotICTransactionErr, GenJnlLine.FieldCaption("IC Account No.")), ErrorText, ErrorCounter);
                        end;
            if GenJnlLine."IC Account Type" = GenJnlLine."IC Account Type"::"Bank Account" then
                if ICBankAccount.Get(GenJnlLine."IC Account No.") then
                    if ICBankAccount.Blocked then
                        AddError(StrSubstNo(FieldMustBeValueForRecordErr, ICBankAccount.FieldCaption(Blocked), false,
                            GenJnlLine.FieldCaption("IC Account No."), GenJnlLine."IC Account No."), ErrorText, ErrorCounter)
                    else
                        if GenJnlLine."IC Account No." <> '' then
                            AddError(StrSubstNo(ICAccNoCannotBeSpecifiedErr, GenJnlLine.FieldCaption("IC Account No.")), ErrorText, ErrorCounter)
                        else begin
                            if GenJnlLine."IC Direction" = GenJnlLine."IC Direction"::Incoming then
                                AddError(StrSubstNo(ICAccNoNotAllowedForDirectionErr, GenJnlLine.FieldCaption("IC Account No."),
                                    GenJnlLine.FieldCaption("IC Direction"), Format(GenJnlLine."IC Direction")), ErrorText, ErrorCounter);
                            if CurrentICPartner = '' then
                                AddError(StrSubstNo(ICAccNoNotICTransactionErr, GenJnlLine.FieldCaption("IC Account No.")), ErrorText, ErrorCounter);
                        end;
        end;
    end;

    local procedure AddError(Text: Text[250]; var ErrorText: array[50] of Text[250]; var ErrorCounter: Integer)
    begin
        ErrorCounter := ErrorCounter + 1;
        ErrorText[ErrorCounter] := Text;
    end;

    var
        ICAccNoMustBeSpecifiedErr: Label '%1 must be specified.', Comment = '%1=Field caption';
        ICAccNoCannotBeSpecifiedErr: Label '%1 cannot be specified.', Comment = '%1=Field caption';
        RecordDoesNotExistErr: Label '%1 %2 does not exist.', Comment = '%1=Table caption;%2=Code value';
        FieldMustBeValueForRecordErr: Label '%1 must be %2 for %3 %4.', Comment = '%1=Field caption;%2=Expected value;%3=Table caption;%4=Code value';
        GLAndBankBothEnteredErr: Label 'You cannot enter G/L Account or Bank Account in both %1 and %2.', Comment = '%1=Account No. field caption;%2=Bal. Account No. field caption';
        PartnerLinkedToAccountErr: Label '%1 %2 is linked to %3 %4.', Comment = '%1=Customer table caption;%2=Account No.%3=IC Partner table caption;%4=IC Partner Code';
        ICAccNoNotAllowedForDirectionErr: Label '%1 must not be specified when %2 is %3.', Comment = '%1=IC Partner G/L Acc. No. field caption;%2=IC Direction field caption;%3=IC Direction format';
        ICAccNoNotICTransactionErr: Label '%1 must not be specified when the document is not an intercompany transaction.', Comment = '%1=IC Partner G/L Acc. No. field caption';
}
