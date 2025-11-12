// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Reconciliation;

using Microsoft.Bank.BankAccount;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;

table 1251 "Text-to-Account Mapping"
{
    Caption = 'Text-to-Account Mapping';
    DataCaptionFields = "Mapping Text";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(2; "Mapping Text"; Text[250])
        {
            Caption = 'Mapping Text';
            NotBlank = true;

            trigger OnValidate()
            begin
                "Mapping Text" := CopyStr(RecordMatchMgt.Trim("Mapping Text"), 1, 250);
            end;
        }
        field(3; "Debit Acc. No."; Code[20])
        {
            Caption = 'Debit Acc. No.';
            TableRelation = "G/L Account" where("Account Type" = const(Posting),
                                                 Blocked = const(false),
                                                 "Direct Posting" = const(true));
        }
        field(4; "Credit Acc. No."; Code[20])
        {
            Caption = 'Credit Acc. No.';
            TableRelation = "G/L Account" where("Account Type" = const(Posting),
                                                 Blocked = const(false),
                                                 "Direct Posting" = const(true));
        }
        field(5; "Bal. Source Type"; Option)
        {
            Caption = 'Bal. Source Type';
            OptionCaption = 'G/L Account,Customer,Vendor,Bank Account';
            OptionMembers = "G/L Account",Customer,Vendor,"Bank Account";

            trigger OnValidate()
            begin
                Validate("Bal. Source No.", '');
            end;
        }
        field(6; "Bal. Source No."; Code[20])
        {
            Caption = 'Bal. Source No.';
            TableRelation = if ("Bal. Source Type" = const("G/L Account")) "G/L Account" where("Account Type" = const(Posting),
                                                                                              Blocked = const(false))
            else
            if ("Bal. Source Type" = const(Customer)) Customer
            else
            if ("Bal. Source Type" = const(Vendor)) Vendor
            else
            if ("Bal. Source Type" = const("Bank Account")) "Bank Account";
        }
        field(7; "Vendor No."; Code[20])
        {
            Caption = 'Vendor No.';
            TableRelation = Vendor;
        }
    }

    keys
    {
        key(Key1; "Line No.")
        {
            Clustered = true;
        }
        key(Key2; "Mapping Text", "Vendor No.")
        {
            Enabled = false;
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    begin
        CheckMappingText();
    end;

    trigger OnModify()
    begin
        CheckMappingText();
    end;

    var
        RecordMatchMgt: Codeunit "Record Match Mgt.";
        AlreadyExistErr: Label 'Entry with Mapping Text=''%1'' already exists.', Comment = '%1 is the value currently inserted.';
        BalAccountNoQst: Label 'The Bal. Account No. field must have a value if the Bal. Source Type field contains %1.\\Affected Mapping Text: %2. Do you want to quit without saving the data?', Comment = '%1 is option: Vendor or Customer and %2 is the record value in this field.';
        GLAccountNoQst: Label 'The Debit Acc. No. field or the Credit Acc. No. field must have a value if the Bal. Source Type field contains %1.\\Affected Mapping Text: %2. Do you want to quit without saving the data?', Comment = '%1 is option: G/L Account and %2 is the record value in this field.';
        FilterInvalidCharTxt: Label '(&)', Locked = true;

    procedure InsertRec(GenJnlLine: Record "Gen. Journal Line")
    var
        TextToAccMapping: Record "Text-to-Account Mapping";
        LastLineNo: Integer;
    begin
        if RecordMatchMgt.Trim(GenJnlLine.Description) <> '' then begin
            TextToAccMapping.SetFilter("Mapping Text", '%1', '@' + RecordMatchMgt.Trim(GenJnlLine.Description));
            if TextToAccMapping.FindFirst() then
                Copy(TextToAccMapping)
            else begin
                TextToAccMapping.Reset();
                if TextToAccMapping.FindLast() then
                    LastLineNo := TextToAccMapping."Line No.";

                Init();
                "Line No." := LastLineNo + 10000;
                Validate("Mapping Text", GenJnlLine.Description);
                SetBalSourceType(GenJnlLine);
                if "Bal. Source Type" <> "Bal. Source Type"::"G/L Account" then
                    "Bal. Source No." := GenJnlLine."Account No."
                else begin
                    "Debit Acc. No." := GenJnlLine."Account No.";
                    "Credit Acc. No." := GenJnlLine."Account No.";
                end;

                if "Mapping Text" <> '' then
                    Insert();
            end;

            Reset();
        end;

        PAGE.Run(PAGE::"Text-to-Account Mapping", Rec);
    end;

    procedure InsertRecFromBankAccReconciliationLine(BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line")
    var
        TextToAccMapping: Record "Text-to-Account Mapping";
        LastLineNo: Integer;
    begin
        if RecordMatchMgt.Trim(BankAccReconciliationLine."Transaction Text") <> '' then begin
            TextToAccMapping.SetFilter("Mapping Text", '%1', '@' + RecordMatchMgt.Trim(BankAccReconciliationLine."Transaction Text"));
            if TextToAccMapping.FindFirst() then
                Copy(TextToAccMapping)
            else begin
                TextToAccMapping.Reset();
                if TextToAccMapping.FindLast() then
                    LastLineNo := TextToAccMapping."Line No.";

                Init();
                "Line No." := LastLineNo + 10000;
                Validate("Mapping Text", BankAccReconciliationLine."Transaction Text");

                SetSourceTypeFromReconcLine(BankAccReconciliationLine);
                case "Bal. Source Type" of
                    "Bal. Source Type"::Customer,
                    "Bal. Source Type"::Vendor:
                        "Bal. Source No." := BankAccReconciliationLine."Account No.";
                    "Bal. Source Type"::"G/L Account":
                        begin
                            "Debit Acc. No." := BankAccReconciliationLine."Account No.";
                            "Credit Acc. No." := BankAccReconciliationLine."Account No.";
                        end;
                end;
                OnInsertRecFromBankAccReconciliationLineOnBeforeInsert(Rec, BankAccReconciliationLine);

                if "Mapping Text" <> '' then
                    Insert();
            end;

            Reset();

            Commit();
        end;

        PAGE.RunModal(PAGE::"Text-to-Account Mapping", Rec);
    end;

    procedure GetAccountNo(Amount: Decimal): Code[20]
    begin
        if Amount >= 0 then
            exit("Debit Acc. No.");

        exit("Credit Acc. No.");
    end;

    procedure GetPaymentDocType(var PaymentDocType: Option; ActualSourceType: Option; Amount: Decimal)
    var
        GenJournalLine: Record "Gen. Journal Line";
        ExpectedSourceType: Option;
    begin
        if Amount >= 0 then
            ExpectedSourceType := "Bal. Source Type"::Vendor
        else
            ExpectedSourceType := "Bal. Source Type"::Customer;

        if ExpectedSourceType = ActualSourceType then
            PaymentDocType := GenJournalLine."Document Type"::Payment.AsInteger()
        else
            PaymentDocType := GenJournalLine."Document Type"::Refund.AsInteger();
    end;

    procedure GetDocTypeForPmt(var DocType: Option; PaymentDocType: Option)
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        case PaymentDocType of
            GenJournalLine."Document Type"::Payment.AsInteger():
                DocType := GenJournalLine."Document Type"::Invoice.AsInteger();
            GenJournalLine."Document Type"::Refund.AsInteger():
                DocType := GenJournalLine."Document Type"::"Credit Memo".AsInteger();
        end;
    end;

    local procedure SetBalSourceType(GenJournalLine: Record "Gen. Journal Line")
    begin
        case GenJournalLine."Account Type" of
            GenJournalLine."Account Type"::Customer:
                "Bal. Source Type" := "Bal. Source Type"::Customer;
            GenJournalLine."Account Type"::Vendor:
                "Bal. Source Type" := "Bal. Source Type"::Vendor;
        end;
    end;

    local procedure SetSourceTypeFromReconcLine(BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line")
    begin
        case BankAccReconciliationLine."Account Type" of
            BankAccReconciliationLine."Account Type"::Customer:
                "Bal. Source Type" := "Bal. Source Type"::Customer;
            BankAccReconciliationLine."Account Type"::Vendor:
                "Bal. Source Type" := "Bal. Source Type"::Vendor;
            BankAccReconciliationLine."Account Type"::"Bank Account":
                "Bal. Source Type" := "Bal. Source Type"::"Bank Account";
        end;
    end;

    procedure IsBalSourceNoEnabled(): Boolean
    begin
        exit(not ("Bal. Source Type" in ["Bal. Source Type"::"G/L Account", "Bal. Source Type"::"Bank Account"]));
    end;

    local procedure CheckMappingText()
    var
        TextToAccMapping: Record "Text-to-Account Mapping";
    begin
        TextToAccMapping.SetFilter("Mapping Text", '%1', '@' + "Mapping Text");
        TextToAccMapping.SetRange("Vendor No.", "Vendor No.");
        TextToAccMapping.SetFilter("Line No.", '<>%1', "Line No.");
        if not TextToAccMapping.IsEmpty() then
            Error(AlreadyExistErr, "Mapping Text");
    end;

    procedure CheckEntriesAreConsistent(): Boolean
    var
        TextToAccMapping: Record "Text-to-Account Mapping";
    begin
        TextToAccMapping.SetFilter("Bal. Source Type", '%1|%2', TextToAccMapping."Bal. Source Type"::Vendor, TextToAccMapping."Bal. Source Type"::Customer);
        TextToAccMapping.SetRange("Bal. Source No.", '');
        if TextToAccMapping.FindFirst() then begin
            if DIALOG.Confirm(BalAccountNoQst, true, TextToAccMapping."Bal. Source Type", TextToAccMapping."Mapping Text")
            then begin
                TextToAccMapping.DeleteAll(true);
                exit(true);
            end;
            exit(false);
        end;

        TextToAccMapping.SetRange("Bal. Source Type", TextToAccMapping."Bal. Source Type"::"G/L Account");
        TextToAccMapping.SetRange("Debit Acc. No.", '');
        TextToAccMapping.SetRange("Credit Acc. No.", '');
        if TextToAccMapping.FindFirst() then begin
            if DIALOG.Confirm(GLAccountNoQst, true, TextToAccMapping."Bal. Source Type"::"G/L Account", TextToAccMapping."Mapping Text")
            then begin
                TextToAccMapping.DeleteAll(true);
                exit(true);
            end;
            exit(false);
        end;

        TextToAccMapping.SetRange("Bal. Source Type", TextToAccMapping."Bal. Source Type"::"Bank Account");
        TextToAccMapping.SetRange("Debit Acc. No.", '');
        TextToAccMapping.SetRange("Credit Acc. No.", '');
        if TextToAccMapping.FindFirst() then begin
            if DIALOG.Confirm(GLAccountNoQst, true, TextToAccMapping."Bal. Source Type"::"Bank Account", TextToAccMapping."Mapping Text")
            then begin
                TextToAccMapping.DeleteAll(true);
                exit(true);
            end;
            exit(false);
        end;
        // Exit normally
        exit(true)
    end;

    procedure SearchEnteriesInText(var TextToAccountMapping: Record "Text-to-Account Mapping"; LineDescription: Text; VendorNo: Code[20]): Integer
    var
        TempTextToAccountMapping: Record "Text-to-Account Mapping" temporary;
        TempDefaultTextToAccountMapping: Record "Text-to-Account Mapping" temporary;
        ResultCount: Integer;
    begin
        if SearchExactMapping(TextToAccountMapping, LineDescription, VendorNo) then
            exit(1);

        TextToAccountMapping.Reset();
        TextToAccountMapping.SetRange("Vendor No.", VendorNo);
        if not TextToAccountMapping.FindSet() then
            exit(0);

        repeat
            if TextToAccountMapping."Mapping Text" = '' then // Default mapping
                TempDefaultTextToAccountMapping.Copy(TextToAccountMapping)
            else
                if StrPos(UpperCase(LineDescription), UpperCase(TextToAccountMapping."Mapping Text")) > 0 then begin
                    TempTextToAccountMapping.Copy(TextToAccountMapping);
                    TempTextToAccountMapping.Insert();
                end;
        until TextToAccountMapping.Next() = 0;

        ResultCount := TempTextToAccountMapping.Count();
        if ResultCount = 0 then
            if TempDefaultTextToAccountMapping."Line No." <> 0 then begin
                TextToAccountMapping.Copy(TempDefaultTextToAccountMapping);
                exit(1);
            end;

        if ResultCount <> 1 then
            exit(ResultCount);

        TempTextToAccountMapping.FindFirst();
        TextToAccountMapping.Copy(TempTextToAccountMapping);
        exit(ResultCount);
    end;

    local procedure SearchExactMapping(var TextToAccountMapping: Record "Text-to-Account Mapping"; LineDescription: Text; VendorNo: Code[20]): Boolean
    begin
        TextToAccountMapping.Reset();
        TextToAccountMapping.SetRange("Vendor No.", VendorNo);
        TextToAccountMapping.SetFilter("Mapping Text", '%1', '@' + DelChr(LineDescription, '=', FilterInvalidCharTxt));
        exit(TextToAccountMapping.FindFirst());
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertRecFromBankAccReconciliationLineOnBeforeInsert(var TextToAccountMapping: Record "Text-to-Account Mapping"; BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line")
    begin
    end;
}

