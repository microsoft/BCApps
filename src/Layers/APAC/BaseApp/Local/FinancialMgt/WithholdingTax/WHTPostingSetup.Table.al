// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.WithholdingTax;

using Microsoft.Bank.BankAccount;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Foundation.NoSeries;

table 28043 "WHT Posting Setup"
{
    Caption = 'WHT Posting Setup';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "WHT Business Posting Group"; Code[20])
        {
            Caption = 'WHT Business Posting Group';
            TableRelation = "WHT Business Posting Group";
        }
        field(2; "WHT Product Posting Group"; Code[20])
        {
            Caption = 'WHT Product Posting Group';
            TableRelation = "WHT Product Posting Group";
        }
        field(3; "WHT %"; Decimal)
        {
            Caption = 'WHT %';
            DecimalPlaces = 0 : 5;
            MaxValue = 100;
            MinValue = 0;
        }
        field(4; "Prepaid WHT Account Code"; Code[20])
        {
            Caption = 'Prepaid WHT Account Code';
            TableRelation = "G/L Account";
        }
        field(5; "Payable WHT Account Code"; Code[20])
        {
            Caption = 'Payable WHT Account Code';
            TableRelation = "G/L Account";
        }
        field(7; "WHT Report"; Option)
        {
            Caption = 'WHT Report';
            OptionCaption = ' ,Por Ngor Dor 1,Por Ngor Dor 2,Por Ngor Dor 3,Por Ngor Dor 53,Por Ngor Dor 54';
            OptionMembers = " ","Por Ngor Dor 1","Por Ngor Dor 2","Por Ngor Dor 3","Por Ngor Dor 53","Por Ngor Dor 54";
        }
        field(8; "WHT Report Line No. Series"; Code[20])
        {
            Caption = 'WHT Report Line No. Series';
            TableRelation = "No. Series";
        }
        field(9; "Revenue Type"; Code[10])
        {
            Caption = 'Revenue Type';
            TableRelation = "WHT Revenue Types";
        }
        field(10; "Bal. Prepaid Account Type"; Option)
        {
            Caption = 'Bal. Prepaid Account Type';
            OptionCaption = 'Bank Account,G/L Account';
            OptionMembers = "Bank Account","G/L Account";
        }
        field(11; "Bal. Prepaid Account No."; Code[20])
        {
            Caption = 'Bal. Prepaid Account No.';
            TableRelation = if ("Bal. Prepaid Account Type" = const("Bank Account")) "Bank Account"
            else
            if ("Bal. Prepaid Account Type" = const("G/L Account")) "G/L Account";
        }
        field(12; "Bal. Payable Account Type"; Option)
        {
            Caption = 'Bal. Payable Account Type';
            OptionCaption = 'Bank Account,G/L Account';
            OptionMembers = "Bank Account","G/L Account";
        }
        field(13; "Bal. Payable Account No."; Code[20])
        {
            Caption = 'Bal. Payable Account No.';
            TableRelation = if ("Bal. Payable Account Type" = const("Bank Account")) "Bank Account"
            else
            if ("Bal. Payable Account Type" = const("G/L Account")) "G/L Account";
        }
        field(20; "Purch. WHT Adj. Account No."; Code[20])
        {
            Caption = 'Purch. WHT Adj. Account No.';
            TableRelation = "G/L Account";
        }
        field(21; "Sales WHT Adj. Account No."; Code[20])
        {
            Caption = 'Sales WHT Adj. Account No.';
            TableRelation = "G/L Account";
        }
        field(22; Sequence; Integer)
        {
            Caption = 'Sequence';
        }
        field(23; "Realized WHT Type"; Option)
        {
            Caption = 'Realized WHT Type';
            OptionCaption = ' ,Invoice,Payment,Earliest';
            OptionMembers = " ",Invoice,Payment,Earliest;
        }
        field(24; "WHT Minimum Invoice Amount"; Decimal)
        {
            Caption = 'WHT Minimum Invoice Amount';
        }
        field(25; "WHT Calculation Rule"; Option)
        {
            Caption = 'WHT Calculation Rule';
            OptionCaption = 'Less than,Less than or equal to,Equal to,Greater than,Greater than or equal to';
            OptionMembers = "Less than","Less than or equal to","Equal to","Greater than","Greater than or equal to";
        }
    }

    keys
    {
        key(Key1; "WHT Business Posting Group", "WHT Product Posting Group")
        {
            Clustered = true;
        }
        key(Key2; "WHT Business Posting Group", Sequence)
        {
        }
    }

    fieldgroups
    {
    }

    [Scope('OnPrem')]
    procedure GetPrepaidWHTAccount(): Code[20]
    begin
        TestField("Prepaid WHT Account Code");
        exit("Prepaid WHT Account Code");
    end;

    [Scope('OnPrem')]
    procedure GetPayableWHTAccount(): Code[20]
    begin
        TestField("Payable WHT Account Code");
        exit("Payable WHT Account Code");
    end;
}

