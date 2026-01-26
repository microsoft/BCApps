// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Payables;

using Microsoft.Bank.BankAccount;
using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Foundation.NoSeries;

table 15000003 "Remittance Account"
{
    Caption = 'Remittance Account';
    LookupPageID = "Remittance Account Overview";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
        }
        field(2; "Remittance Agreement Code"; Code[10])
        {
            Caption = 'Remittance Agreement Code';
            TableRelation = "Remittance Agreement".Code;
        }
        field(5; Description; Text[30])
        {
            Caption = 'Description';
        }
        field(14; Type; Option)
        {
            Caption = 'Type';
            OptionCaption = 'Domestic,Foreign,Payment Instr.';
            OptionMembers = Domestic,Foreign,"Payment Instr.";

            trigger OnValidate()
            begin
                RemittanceAgreement.Get("Remittance Agreement Code");
                if (Type = Type::Foreign) and (RemittanceAgreement."Payment System" = RemittanceAgreement."Payment System"::BBS) then
                    Error(InvalidTypeErr);
            end;
        }
        field(21; "BBS Agreement ID"; Code[9])
        {
            Caption = 'BBS Agreement ID';
        }
        field(22; "Bank Account No."; Code[20])
        {
            Caption = 'Bank Account No.';

            trigger OnValidate()
            begin
                if "Bank Account No." <> '' then begin
                    ErrorMess := RemTools.CheckAccountNo("Bank Account No.", Type::Domestic);
                    if ErrorMess <> '' then
                        Error(ErrorMess);
                end;
            end;
        }
        field(25; "Account No."; Code[20])
        {
            Caption = 'Account No.';
            TableRelation = if ("Account Type" = const("Finance account")) "G/L Account"."No."
            else
            if ("Account Type" = const("Bank account")) "Bank Account"."No.";
        }
        field(26; "Document No. Series"; Code[20])
        {
            Caption = 'Document No. Series';
            TableRelation = "No. Series";
        }
        field(27; "Account Type"; Option)
        {
            Caption = 'Account Type';
            OptionCaption = 'Finance account,,,Bank account';
            OptionMembers = "Finance account",,,"Bank account";

            trigger OnValidate()
            begin
                if "Account Type" <> xRec."Account Type" then
                    Validate("Account No.", '');
            end;
        }
        field(28; "New Document Per."; Option)
        {
            Caption = 'New Document Per.';
            OptionCaption = 'Date,Vendor';
            OptionMembers = Date,Vendor;
        }
        field(29; "Return Journal Template Name"; Code[10])
        {
            Caption = 'Return Journal Template Name';
            TableRelation = "Gen. Journal Template".Name where(Type = const(Payments));
        }
        field(30; "Return Journal Name"; Code[10])
        {
            Caption = 'Return Journal Name';
            TableRelation = "Gen. Journal Batch".Name where("Journal Template Name" = field("Return Journal Template Name"));
        }
        field(40; "Recipient ref. 1 - Invoice"; Code[80])
        {
            Caption = 'Recipient ref. 1 - Invoice';

            trigger OnValidate()
            begin
                RemTools.CheckMessage("Remittance Agreement Code", "Recipient ref. 1 - Invoice");
            end;
        }
        field(41; "Recipient ref. 2 - Invoice"; Code[80])
        {
            Caption = 'Recipient ref. 2 - Invoice';

            trigger OnValidate()
            begin
                RemTools.CheckMessage("Remittance Agreement Code", "Recipient ref. 2 - Invoice");
            end;
        }
        field(42; "Recipient ref. 3 - Invoice"; Code[80])
        {
            Caption = 'Recipient ref. 3 - Invoice';

            trigger OnValidate()
            begin
                RemTools.CheckMessage("Remittance Agreement Code", "Recipient ref. 3 - Invoice");
            end;
        }
        field(43; "Recipient ref. 1 - Cr. Memo"; Code[80])
        {
            Caption = 'Recipient ref. 1 - Cr. Memo';

            trigger OnValidate()
            begin
                RemTools.CheckMessage("Remittance Agreement Code", "Recipient ref. 1 - Cr. Memo");
            end;
        }
        field(44; "Recipient ref. 2 - Cr. Memo"; Code[80])
        {
            Caption = 'Recipient ref. 2 - Cr. Memo';

            trigger OnValidate()
            begin
                RemTools.CheckMessage("Remittance Agreement Code", "Recipient ref. 2 - Cr. Memo");
            end;
        }
        field(45; "Recipient ref. 3 - Cr. Memo"; Code[80])
        {
            Caption = 'Recipient ref. 3 - Cr. Memo';

            trigger OnValidate()
            begin
                RemTools.CheckMessage("Remittance Agreement Code", "Recipient ref. 3 - Cr. Memo");
            end;
        }
        field(46; "Futures Contract No."; Code[6])
        {
            Caption = 'Futures Contract No.';
        }
        field(47; "Futures Contract Exch. Rate"; Decimal)
        {
            BlankZero = true;
            Caption = 'Futures Contract Exch. Rate';
            DecimalPlaces = 5 : 5;
        }
        field(51; "Recipient Ref. Abroad"; Code[35])
        {
            Caption = 'Recipient Ref. Abroad';

            trigger OnValidate()
            begin
                RemTools.CheckMessage("Remittance Agreement Code", "Recipient Ref. Abroad");
            end;
        }
        field(52; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            TableRelation = Currency.Code;
        }
        field(53; "Charge Account Type"; Option)
        {
            Caption = 'Charge Account Type';
            OptionCaption = 'Finance account,,,Bank account';
            OptionMembers = "Finance account",,,"Bank account";

            trigger OnValidate()
            begin
                if "Charge Account Type" <> xRec."Charge Account Type" then
                    Validate("Charge Account No.", '');
            end;
        }
        field(54; "Charge Account No."; Code[20])
        {
            Caption = 'Charge Account No.';
            TableRelation = if ("Charge Account Type" = const("Finance account")) "G/L Account"."No."
            else
            if ("Charge Account Type" = const("Bank account")) "Bank Account"."No.";
        }
        field(55; "Round off/Divergence Acc. No."; Code[20])
        {
            Caption = 'Round off/Divergence Acc. No.';
            TableRelation = "G/L Account"."No.";
        }
        field(56; "Max. Round off/Diverg. (LCY)"; Decimal)
        {
            Caption = 'Max. Round off/Diverg. (LCY)';
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    begin
        // Default if it's only an agreement.
        if RemittanceAgreement.Count = 1 then begin
            RemittanceAgreement.FindFirst();
            Validate("Remittance Agreement Code", RemittanceAgreement.Code);
        end;
    end;

    var
        RemittanceAgreement: Record "Remittance Agreement";
        RemTools: Codeunit "Remittance Tools";
        ErrorMess: Text[250];
        InvalidTypeErr: Label 'The type Foreign cannot be used with the BBS payment system.';
}

