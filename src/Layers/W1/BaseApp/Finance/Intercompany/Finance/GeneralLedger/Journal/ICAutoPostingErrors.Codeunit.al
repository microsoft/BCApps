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
using System.Integration;

codeunit 8428 "IC Auto Posting Errors"
{
    var
        Text002Txt: Label '%1 must be specified.', Comment = '%1=Gen. Posting Type';
        Text009Txt: Label '%1 cannot be specified.', Comment = '%1=Project No.';
        Text031Txt: Label '%1 %2 does not exist.', Comment = '%1=GLAcc.TableCaption(), %2=Account No.';
        Text032Txt: Label '%1 must be %2 for %3 %4.', Comment = '%1=GLAcc. Account Type field caption, %2=GLAcc.Account Type, %3=GLAcc. table caption, %4=Account No.';
        Text066Txt: Label 'You cannot enter G/L Account or Bank Account in both %1 and %2.', Comment = '%1=Account No. field caption, %2=Bal. Account No. field caption';
        Text067Txt: Label '%1 %2 is linked to %3 %4.', Comment = '%1=Customer table caption, %2=Account No., %3=ICPartner table caption, %4=IC Partner Code';
        Text069Txt: Label '%1 must not be specified when %2 is %3.', Comment = '%1=IC Partner G/L Acc. No. field caption, %2=IC Direction field caption, %3=IC Direction';
        Text070Txt: Label '%1 must not be specified when the document is not an intercompany transaction.', Comment = '%1=IC Partner G/L Acc. No. field caption';

    [EventSubscriber(ObjectType::Report, Report::"Auto Posting Errors", 'OnAfterCheckCustBase', '', true, false)]
    local procedure OnAfterCheckCustBase(var GenJnlLine: Record "Gen. Journal Line"; Customer: Record Customer; GenJnlTemplate: Record "Gen. Journal Template"; var ErrorText: array[50] of Text[250]; var ErrorCounter: Integer; var DataMigrationError: Record "Data Migration Error"; GPMigrationType: Text; PostingErrorText: Text)
    var
        ICPartner: Record "IC Partner";
    begin
        if (Customer."IC Partner Code" = '') or (GenJnlTemplate.Type <> GenJnlTemplate.Type::Intercompany) then
            exit;

        if ICPartner.Get(Customer."IC Partner Code") then begin
            if ICPartner.Blocked then
                AddError(GenJnlLine, StrSubstNo('%1 %2', StrSubstNo(Text067Txt, Customer.TableCaption(), GenJnlLine."Account No.", ICPartner.TableCaption(), GenJnlLine."IC Partner Code"), StrSubstNo(Text032Txt, ICPartner.FieldCaption(Blocked), false, ICPartner.TableCaption(), Customer."IC Partner Code")), ErrorText, ErrorCounter, DataMigrationError, GPMigrationType, PostingErrorText);
        end else
            AddError(GenJnlLine, StrSubstNo('%1 %2', StrSubstNo(Text067Txt, Customer.TableCaption(), GenJnlLine."Account No.", ICPartner.TableCaption(), Customer."IC Partner Code"), StrSubstNo(Text031Txt, ICPartner.TableCaption(), Customer."IC Partner Code")), ErrorText, ErrorCounter, DataMigrationError, GPMigrationType, PostingErrorText);
    end;

    [EventSubscriber(ObjectType::Report, Report::"Auto Posting Errors", 'OnAfterCheckVendBase', '', true, false)]
    local procedure OnAfterCheckVendBase(var GenJnlLine: Record "Gen. Journal Line"; Vendor: Record Vendor; GenJnlTemplate: Record "Gen. Journal Template"; var ErrorText: array[50] of Text[250]; var ErrorCounter: Integer; var DataMigrationError: Record "Data Migration Error"; GPMigrationType: Text; PostingErrorText: Text)
    var
        ICPartner: Record "IC Partner";
    begin
        if (Vendor."IC Partner Code" = '') or (GenJnlTemplate.Type <> GenJnlTemplate.Type::Intercompany) then
            exit;

        if ICPartner.Get(Vendor."IC Partner Code") then begin
            if ICPartner.Blocked then
                AddError(GenJnlLine, StrSubstNo('%1 %2', StrSubstNo(Text067Txt, Vendor.TableCaption(), GenJnlLine."Account No.", ICPartner.TableCaption(), Vendor."IC Partner Code"), StrSubstNo(Text032Txt, ICPartner.FieldCaption(Blocked), false, ICPartner.TableCaption(), Vendor."IC Partner Code")), ErrorText, ErrorCounter, DataMigrationError, GPMigrationType, PostingErrorText);
        end else
            AddError(GenJnlLine, StrSubstNo('%1 %2', StrSubstNo(Text067Txt, Vendor.TableCaption(), GenJnlLine."Account No.", ICPartner.TableCaption(), GenJnlLine."IC Partner Code"), StrSubstNo(Text031Txt, ICPartner.TableCaption(), Vendor."IC Partner Code")), ErrorText, ErrorCounter, DataMigrationError, GPMigrationType, PostingErrorText);
    end;

    [EventSubscriber(ObjectType::Report, Report::"Auto Posting Errors", 'OnCheckICPartner', '', true, false)]
    local procedure OnCheckICPartner(var GenJnlLine: Record "Gen. Journal Line"; var AccName: Text[100]; var ErrorText: array[50] of Text[250]; var ErrorCounter: Integer; var DataMigrationError: Record "Data Migration Error"; GPMigrationType: Text; PostingErrorText: Text; var IsHandled: Boolean)
    var
        ICPartner: Record "IC Partner";
    begin
        if not ICPartner.Get(GenJnlLine."Account No.") then
            AddError(GenJnlLine, StrSubstNo(Text031Txt, ICPartner.TableCaption(), GenJnlLine."Account No."), ErrorText, ErrorCounter, DataMigrationError, GPMigrationType, PostingErrorText)
        else begin
            AccName := ICPartner.Name;
            if ICPartner.Blocked then
                AddError(GenJnlLine, StrSubstNo(Text032Txt, ICPartner.FieldCaption(Blocked), false, ICPartner.TableCaption(), GenJnlLine."Account No."), ErrorText, ErrorCounter, DataMigrationError, GPMigrationType, PostingErrorText);
        end;

        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Report, Report::"Auto Posting Errors", 'OnBeforeCheckICDocument', '', true, false)]
    local procedure OnBeforeCheckICDocument(var GenJnlLine: Record "Gen. Journal Line"; GenJnlTemplate: Record "Gen. Journal Template"; LastDate: Date; LastDocType: Enum "Gen. Journal Document Type"; LastDocNo: Code[20]; var ErrorText: array[50] of Text[250]; var ErrorCounter: Integer; var DataMigrationError: Record "Data Migration Error"; GPMigrationType: Text; PostingErrorText: Text; var IsHandled: Boolean)
    var
        GenJnlLine4: Record "Gen. Journal Line";
        CurrentICPartner: Code[20];
    begin
        if GenJnlTemplate.Type <> GenJnlTemplate.Type::Intercompany then
            exit;

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

        CheckICAccountNo(GenJnlLine, CurrentICPartner, ErrorText, ErrorCounter, DataMigrationError, GPMigrationType, PostingErrorText);
        IsHandled := true;
    end;

    local procedure CheckICAccountNo(var GenJnlLine: Record "Gen. Journal Line"; CurrentICPartner: Code[20]; var ErrorText: array[50] of Text[250]; var ErrorCounter: Integer; var DataMigrationError: Record "Data Migration Error"; GPMigrationType: Text; PostingErrorText: Text)
    var
        ICGLAccount: Record "IC G/L Account";
        ICBankAccount: Record "IC Bank Account";
    begin
        if (CurrentICPartner <> '') and (GenJnlLine."IC Direction" = GenJnlLine."IC Direction"::Outgoing) then
            if (GenJnlLine."Account Type" in [GenJnlLine."Account Type"::"G/L Account", GenJnlLine."Account Type"::"Bank Account"]) and
               (GenJnlLine."Bal. Account Type" in [GenJnlLine."Bal. Account Type"::"G/L Account", GenJnlLine."Account Type"::"Bank Account"]) and
               (GenJnlLine."Account No." <> '') and
               (GenJnlLine."Bal. Account No." <> '')
            then
                AddError(GenJnlLine, StrSubstNo(Text066Txt, GenJnlLine.FieldCaption("Account No."), GenJnlLine.FieldCaption("Bal. Account No.")), ErrorText, ErrorCounter, DataMigrationError, GPMigrationType, PostingErrorText)
            else begin
                if (((GenJnlLine."Account Type" in [GenJnlLine."Account Type"::"G/L Account", GenJnlLine."Account Type"::"Bank Account"]) and (GenJnlLine."Account No." <> '')) xor
                   ((GenJnlLine."Bal. Account Type" in [GenJnlLine."Bal. Account Type"::"G/L Account", GenJnlLine."Account Type"::"Bank Account"]) and (GenJnlLine."Bal. Account No." <> '')))
                then
                    if GenJnlLine."IC Account No." = '' then
                        AddError(GenJnlLine, StrSubstNo(Text002Txt, GenJnlLine.FieldCaption("IC Account No.")), ErrorText, ErrorCounter, DataMigrationError, GPMigrationType, PostingErrorText)
                    else begin
                        if GenJnlLine."IC Account Type" = GenJnlLine."IC Account Type"::"G/L Account" then
                            if ICGLAccount.Get(GenJnlLine."IC Account No.") then
                                if ICGLAccount.Blocked then
                                    AddError(GenJnlLine, StrSubstNo(Text032Txt, ICGLAccount.FieldCaption(Blocked), false, GenJnlLine.FieldCaption("IC Account No."), GenJnlLine."IC Account No."), ErrorText, ErrorCounter, DataMigrationError, GPMigrationType, PostingErrorText);

                        if GenJnlLine."IC Account Type" = GenJnlLine."IC Account Type"::"Bank Account" then
                            if ICBankAccount.Get(GenJnlLine."IC Account No.", CurrentICPartner) then
                                if ICBankAccount.Blocked then
                                    AddError(GenJnlLine, StrSubstNo(Text032Txt, ICBankAccount.FieldCaption(Blocked), false, GenJnlLine.FieldCaption("IC Account No."), GenJnlLine."IC Account No."), ErrorText, ErrorCounter, DataMigrationError, GPMigrationType, PostingErrorText);
                    end;

                if not (((GenJnlLine."Account Type" in [GenJnlLine."Account Type"::"G/L Account", GenJnlLine."Account Type"::"Bank Account"]) and (GenJnlLine."Account No." <> '')) xor
                        ((GenJnlLine."Bal. Account Type" in [GenJnlLine."Bal. Account Type"::"G/L Account", GenJnlLine."Account Type"::"Bank Account"]) and (GenJnlLine."Bal. Account No." <> '')))
                then
                    if GenJnlLine."IC Account No." <> '' then
                        AddError(GenJnlLine, StrSubstNo(Text009Txt, GenJnlLine.FieldCaption("IC Account No.")), ErrorText, ErrorCounter, DataMigrationError, GPMigrationType, PostingErrorText);
            end
        else
            if GenJnlLine."IC Account No." <> '' then begin
                if GenJnlLine."IC Direction" = GenJnlLine."IC Direction"::Incoming then
                    AddError(GenJnlLine, StrSubstNo(Text069Txt, GenJnlLine.FieldCaption("IC Account No."), GenJnlLine.FieldCaption("IC Direction"), Format(GenJnlLine."IC Direction")), ErrorText, ErrorCounter, DataMigrationError, GPMigrationType, PostingErrorText);
                if CurrentICPartner = '' then
                    AddError(GenJnlLine, StrSubstNo(Text070Txt, GenJnlLine.FieldCaption("IC Account No.")), ErrorText, ErrorCounter, DataMigrationError, GPMigrationType, PostingErrorText);
            end;
    end;

    local procedure AddError(var GenJnlLine: Record "Gen. Journal Line"; Text: Text[250]; var ErrorText: array[50] of Text[250]; var ErrorCounter: Integer; var DataMigrationError: Record "Data Migration Error"; GPMigrationType: Text; PostingErrorText: Text)
    begin
        ErrorCounter := ErrorCounter + 1;
        ErrorText[ErrorCounter] := Text;

        if DataMigrationError.FindLast() then
            DataMigrationError.Id := DataMigrationError.Id + 1
        else
            DataMigrationError.Id := 1;
        DataMigrationError.Init();
        DataMigrationError."Migration Type" := CopyStr(GPMigrationType, 1, MaxStrLen(DataMigrationError."Migration Type"));
        DataMigrationError."Error Message" := CopyStr(StrSubstNo(PostingErrorText, GenJnlLine."Journal Batch Name", GenJnlLine."Document No.", Text), 1, MaxStrLen(DataMigrationError."Error Message"));
        DataMigrationError.Insert();
    end;
}