// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Currency;

using Microsoft.Bank.BankAccount;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;

table 186 "Exch. Rate Adjmt. Ledg. Entry"
{
    Caption = 'Exch. Rate Adjmt. Ledger Entry';
    DrillDownPageID = "Exch.Rate Adjmt. Ledg.Entries";
    LookupPageID = "Exch.Rate Adjmt. Ledg.Entries";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Register No."; Integer)
        {
            Caption = 'No.';
        }
        field(2; "Entry No."; Integer)
        {
            Caption = 'No.';
        }
        field(3; "Account No."; Code[20])
        {
            Caption = 'Account No.';
            TableRelation = if ("Account Type" = const(Customer)) Customer
            else
            if ("Account Type" = const(Vendor)) Vendor
            else
            if ("Account Type" = const("Bank Account")) "Bank Account";
        }
        field(4; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
        field(5; "Document Type"; Enum "Gen. Journal Document Type")
        {
            Caption = 'Document Type';
        }
        field(6; "Document No."; Code[20])
        {
            Caption = 'Document No.';
        }
        field(8; "Due Date"; Date)
        {
            Caption = 'Due Date';
        }
        field(9; "Account Type"; Enum "Exch. Rate Adjmt. Account Type")
        {
            Caption = 'Account Type';
        }
        field(10; "Account Name"; Text[100])
        {
            Caption = 'Account Name';
        }
        field(11; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            TableRelation = Currency;
        }
        field(12; "Currency Factor"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Currency Factor';
            Editable = false;
        }
        field(15; "Base Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Base Amount';
            Editable = false;
        }
        field(16; "Base Amount (LCY)"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            Caption = 'Base Amount (LCY)';
            Editable = false;
        }
        field(17; "Adjustment Amount"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            Caption = 'Adjustment Amount';
            Editable = false;
        }
        field(19; "Detailed Ledger Entry Type"; Enum "Detailed CV Ledger Entry Type")
        {
            Caption = 'Entry Type';
        }
        field(20; "Detailed Ledger Entry No."; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Detailed Ledger Entry No.';
            Editable = false;
        }
    }

    keys
    {
        key(Key1; "Register No.", "Entry No.")
        {
            Clustered = true;
        }
    }
}
