#if not CLEANSCHEMA31
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Ledger;

using Microsoft.Bank.BankAccount;
using Microsoft.Bank.Reconciliation;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;

table 10550 "BACS Ledger Entry"
{
    Caption = 'BACS Ledger Entry';
    DataClassification = CustomerContent;
    ObsoleteReason = 'No longer required';
#if not CLEAN28
    ObsoleteState = Pending;
    ObsoleteTag = '28.0';
#else
    ObsoleteState = Removed;
    ObsoleteTag = '31.0';
#endif

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(2; "Bank Account No."; Code[20])
        {
            Caption = 'Bank Account No.';
            TableRelation = "Vendor Bank Account";
        }
        field(3; "Bank Account Ledger Entry No."; Integer)
        {
            Caption = 'Bank Account Ledger Entry No.';
            TableRelation = "Bank Account Ledger Entry";
        }
        field(4; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
        field(5; "Document Type"; Option)
        {
            Caption = 'Document Type';
            OptionCaption = ' ,Payment,Invoice,Credit Memo,Finance Charge Memo,Reminder';
            OptionMembers = " ",Payment,Invoice,"Credit Memo","Finance Charge Memo",Reminder;
        }
        field(6; "Document No."; Code[20])
        {
            Caption = 'Document No.';
        }
        field(7; Description; Text[50])
        {
            Caption = 'Description';
        }
        field(8; Amount; Decimal)
        {
            AutoFormatExpression = GetCurrencyCodeFromBank();
            AutoFormatType = 1;
            Caption = 'Amount';
        }
        field(9; "BACS Date"; Date)
        {
            Caption = 'BACS Date';
        }
        field(13; "Entry Status"; Option)
        {
            Caption = 'Entry Status';
            OptionCaption = ',Exported,Voided,Posted,Financially Voided';
            OptionMembers = ,Exported,Voided,Posted,"Financially Voided";
        }
        field(14; "Original Entry Status"; Option)
        {
            Caption = 'Original Entry Status';
            OptionCaption = ' ,Exported,Voided,Posted,Financially Voided';
            OptionMembers = " ",Exported,Voided,Posted,"Financially Voided";
        }
        field(15; "Bal. Account Type"; enum "Gen. Journal Account Type")
        {
            Caption = 'Bal. Account Type';
        }
        field(16; "Bal. Account No."; Code[20])
        {
            Caption = 'Bal. Account No.';
            TableRelation = if ("Bal. Account Type" = const("G/L Account")) "G/L Account"
            else
            if ("Bal. Account Type" = const(Customer)) Customer
            else
            if ("Bal. Account Type" = const(Vendor)) Vendor
            else
            if ("Bal. Account Type" = const("Bank Account")) "Bank Account"
            else
            if ("Bal. Account Type" = const("Fixed Asset")) "Fixed Asset";
        }
        field(17; Open; Boolean)
        {
            Caption = 'Open';
        }
        field(18; "Statement Status"; Option)
        {
            Caption = 'Statement Status';
            OptionCaption = 'Open,Bank Acc. Entry Applied,Check Entry Applied,Closed,BACS Entry Applied';
            OptionMembers = Open,"Bank Acc. Entry Applied","Check Entry Applied",Closed,"BACS Entry Applied";
        }
        field(19; "Statement No."; Code[20])
        {
            Caption = 'Statement No.';
            TableRelation = "Bank Acc. Reconciliation Line"."Statement No." where("Bank Account No." = field("Bank Account No."));
        }
        field(20; "Statement Line No."; Integer)
        {
            Caption = 'Statement Line No.';
            TableRelation = "Bank Acc. Reconciliation Line"."Statement Line No." where("Bank Account No." = field("Bank Account No."),
                                                                                        "Statement No." = field("Statement No."));
        }
        field(21; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(22; "External Document No."; Code[35])
        {
            Caption = 'External Document No.';
        }
        field(23; "Account Type"; enum "Gen. Journal Account Type")
        {
            Caption = 'Account Type';
        }
        field(24; "Account No."; Code[20])
        {
            Caption = 'Account No.';
            TableRelation = if ("Account Type" = const("G/L Account")) "G/L Account"
            else
            if ("Account Type" = const(Customer)) Customer
            else
            if ("Account Type" = const(Vendor)) Vendor
            else
            if ("Account Type" = const("Bank Account")) "Bank Account"
            else
            if ("Account Type" = const("Fixed Asset")) "Fixed Asset";
        }
        field(35; "Journal Batch Name"; Code[10])
        {
            Caption = 'Journal Batch Name';
        }
        field(36; "Register No."; Integer)
        {
            Caption = 'Register No.';
            TableRelation = "BACS Register";
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Bank Account No.", "Entry Status")
        {
        }
        key(Key3; "Bank Account Ledger Entry No.", "Entry Status")
        {
        }
        key(Key4; "Bank Account No.", "BACS Date")
        {
        }
        key(Key5; "Bank Account No.", Open)
        {
        }
        key(Key6; "Document No.", "Posting Date")
        {
        }
        key(Key7; "Entry Status")
        {
        }
        key(Key8; "Bal. Account No.", "Entry Status")
        {
        }
        key(Key9; "Bal. Account No.", Open)
        {
        }
        key(Key10; "Bal. Account No.", "BACS Date")
        {
        }
        key(Key11; "Register No.", "Bal. Account No.", "Statement Status", "Statement No.")
        {
            SumIndexFields = Amount;
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Entry No.", "BACS Date", "Bank Account No.", Description)
        {
        }
    }

    [Scope('OnPrem')]
    procedure GetCurrencyCodeFromBank(): Code[10]
    var
        BankAccount: Record "Bank Account";
    begin
        if "Bank Account No." = BankAccount."No." then
            exit(BankAccount."Currency Code");

        if BankAccount.Get("Bank Account No.") then
            exit(BankAccount."Currency Code");

        exit('');
    end;
}
#endif

