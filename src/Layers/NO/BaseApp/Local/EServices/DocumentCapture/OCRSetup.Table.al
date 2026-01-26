// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

using Microsoft.Bank.BankAccount;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Journal;

table 15000100 "OCR Setup"
{
    Caption = 'OCR Setup';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
        }
        field(2; Format; Option)
        {
            Caption = 'Format';
            OptionCaption = 'BBS,Data Dialog';
            OptionMembers = BBS,"Data Dialog";
        }
        field(10; FileName; Text[250])
        {
            Caption = 'FileName';
        }
        field(11; "Delete Return File"; Boolean)
        {
            Caption = 'Delete Return File';
        }
        field(20; "Bal. Account Type"; Option)
        {
            Caption = 'Bal. Account Type';
            OptionCaption = 'Gen. Ledg. Account,,,Bank Account';
            OptionMembers = "Gen. Ledg. Account",,,"Bank Account";

            trigger OnValidate()
            begin
                "Bal. Account No." := '';
            end;
        }
        field(21; "Bal. Account No."; Code[20])
        {
            Caption = 'Bal. Account No.';
            TableRelation = if ("Bal. Account Type" = const("Gen. Ledg. Account")) "G/L Account"."No."
            else
            if ("Bal. Account Type" = const("Bank Account")) "Bank Account"."No.";
        }
        field(22; "Journal Template Name"; Code[10])
        {
            Caption = 'Journal Template Name';
            TableRelation = "Gen. Journal Template".Name;

            trigger OnValidate()
            begin
                "Journal Name" := '';
            end;
        }
        field(23; "Journal Name"; Code[10])
        {
            Caption = 'Journal Name';
            TableRelation = "Gen. Journal Batch".Name where("Journal Template Name" = field("Journal Template Name"));
        }
        field(24; "Max. Divergence"; Decimal)
        {
            Caption = 'Max. Divergence';
        }
        field(25; "Divergence Account No."; Code[20])
        {
            Caption = 'Divergence Account No.';
            TableRelation = "G/L Account"."No.";
        }
    }

    keys
    {
        key(Key1; "Primary Key")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

