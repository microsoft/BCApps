// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Ledger;

using Microsoft.Bank.BankAccount;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.HumanResources.Employee;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;

table 12144 "GL Book Entry"
{
    Caption = 'GL Book Entry';
    DrillDownPageID = "GL Book Entries";
    LookupPageID = "GL Book Entries";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            Editable = false;
        }
        field(3; "G/L Account No."; Code[20])
        {
            Caption = 'G/L Account No.';
            Editable = false;
            TableRelation = "G/L Account";
        }
        field(4; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
            ClosingDates = true;
            Editable = false;
        }
        field(5; "Document Type"; Enum "Gen. Journal Document Type")
        {
            Caption = 'Document Type';
            Editable = false;
        }
        field(6; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            Editable = false;
        }
        field(7; Description; Text[100])
        {
            CalcFormula = lookup("G/L Entry".Description where("Transaction No." = field("Transaction No."),
                                                                "G/L Account No." = field("G/L Account No."),
                                                                "Document No." = field("Document No."),
                                                                Positive = field(Positive),
                                                                "Source Type" = field("Source Type"),
                                                                "Source No." = field("Source No.")));
            Caption = 'Description';
            Editable = false;
            FieldClass = FlowField;
        }
        field(17; Amount; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = sum("G/L Entry".Amount where("Transaction No." = field("Transaction No."),
                                                        "G/L Account No." = field("G/L Account No."),
                                                        "Document No." = field("Document No."),
                                                        Positive = field(Positive),
                                                        "Source Type" = field("Source Type"),
                                                        "Source No." = field("Source No."),
                                                        "Posting Date" = field("Posting Date")));
            Caption = 'Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(52; "Transaction No."; Integer)
        {
            Caption = 'Transaction No.';
            Editable = false;
        }
        field(53; "Debit Amount"; Decimal)
        {
            AutoFormatType = 1;
            BlankZero = true;
            CalcFormula = sum("G/L Entry"."Debit Amount" where("Transaction No." = field("Transaction No."),
                                                                "G/L Account No." = field("G/L Account No."),
                                                                "Document No." = field("Document No."),
                                                                Positive = field(Positive),
                                                                "Source Type" = field("Source Type"),
                                                                "Source No." = field("Source No."),
                                                                "Posting Date" = field("Posting Date")));
            Caption = 'Debit Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(54; "Credit Amount"; Decimal)
        {
            AutoFormatType = 1;
            BlankZero = true;
            CalcFormula = sum("G/L Entry"."Credit Amount" where("Transaction No." = field("Transaction No."),
                                                                 "G/L Account No." = field("G/L Account No."),
                                                                 "Document No." = field("Document No."),
                                                                 Positive = field(Positive),
                                                                 "Source Type" = field("Source Type"),
                                                                 "Source No." = field("Source No."),
                                                                 "Posting Date" = field("Posting Date")));
            Caption = 'Credit Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(55; "Document Date"; Date)
        {
            Caption = 'Document Date';
            ClosingDates = true;
            Editable = false;
        }
        field(56; "External Document No."; Code[35])
        {
            Caption = 'External Document No.';
            Editable = false;
        }
        field(57; "Source Type"; Enum "Gen. Journal Source Type")
        {
            Caption = 'Source Type';
            Editable = false;
        }
        field(58; "Source No."; Code[20])
        {
            Caption = 'Source No.';
            Editable = false;
            TableRelation = if ("Source Type" = const(Customer)) Customer
            else
            if ("Source Type" = const(Vendor)) Vendor
            else
            if ("Source Type" = const("Bank Account")) "Bank Account"
            else
            if ("Source Type" = const("Fixed Asset")) "Fixed Asset"
            else
            if ("Source Type" = const(Employee)) Employee;
        }
        field(60; "Additional-Currency Amount"; Decimal)
        {
            CalcFormula = sum("G/L Entry"."Additional-Currency Amount" where("Transaction No." = field("Transaction No."),
                                                                              "G/L Account No." = field("G/L Account No."),
                                                                              "Document No." = field("Document No."),
                                                                              Positive = field(Positive),
                                                                              "Source Type" = field("Source Type"),
                                                                              "Source No." = field("Source No.")));
            Caption = 'Additional-Currency Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(70; "Official Date"; Date)
        {
            Caption = 'Official Date';
            Editable = false;
        }
        field(71; "Progressive No."; Integer)
        {
            Caption = 'Progressive No.';
            Editable = false;
        }
        field(72; Positive; Boolean)
        {
            Caption = 'Positive';
            Editable = false;
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Document No.", "Posting Date")
        {
        }
        key(Key3; "Transaction No.", "G/L Account No.", "Document No.", Positive, "Source Type", "Source No.")
        {
        }
        key(Key4; "Official Date")
        {
        }
        key(Key5; "Posting Date", "Transaction No.", "Entry No.")
        {
        }
        key(Key6; "Progressive No.")
        {
        }
        key(Key7; "G/L Account No.", "Posting Date")
        {
        }
        key(Key8; "Progressive No.", "Official Date")
        {
        }
    }

    fieldgroups
    {
    }
}

