// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Deposit;

using Microsoft.Bank.BankAccount;
using Microsoft.Bank.Ledger;
using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Intercompany.Partner;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Receivables;

table 10144 "Posted Deposit Line"
{
    Caption = 'Posted Deposit Line';
    LookupPageID = "Posted Deposit Lines";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Deposit No."; Code[20])
        {
            Caption = 'Deposit No.';
            TableRelation = "Posted Deposit Header";
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(3; "Account Type"; Enum "Gen. Journal Account Type")
        {
            Caption = 'Account Type';
            InitValue = Customer;
        }
        field(4; "Account No."; Code[20])
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
            if ("Account Type" = const("IC Partner")) "IC Partner";
        }
        field(5; "Document Date"; Date)
        {
            Caption = 'Document Date';
        }
        field(6; "Document Type"; Enum "Gen. Journal Document Type")
        {
            Caption = 'Document Type';
        }
        field(7; "Document No."; Code[20])
        {
            Caption = 'Document No.';
        }
        field(8; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(9; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            Editable = false;
            TableRelation = Currency;
        }
        field(10; Amount; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Amount';
            MinValue = 0;
        }
        field(11; "Posting Group"; Code[20])
        {
            Caption = 'Posting Group';
            Editable = false;
            TableRelation = if ("Account Type" = const(Customer)) "Customer Posting Group"
            else
            if ("Account Type" = const(Vendor)) "Vendor Posting Group";
        }
        field(12; "Shortcut Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,2,1';
            Caption = 'Shortcut Dimension 1 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1));
        }
        field(13; "Shortcut Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,2,2';
            Caption = 'Shortcut Dimension 2 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2));
        }
        field(14; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
        field(15; "Bank Account Ledger Entry No."; Integer)
        {
            Caption = 'Bank Account Ledger Entry No.';
            TableRelation = "Bank Account Ledger Entry";
        }
        field(16; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            TableRelation = if ("Account Type" = const("G/L Account")) "G/L Entry"
            else
            if ("Account Type" = const(Customer)) "Cust. Ledger Entry"
            else
            if ("Account Type" = const(Vendor)) "Vendor Ledger Entry"
            else
            if ("Account Type" = const("Bank Account")) "Bank Account Ledger Entry";
        }
        field(480; "Dimension Set ID"; Integer)
        {
            Caption = 'Dimension Set ID';
            Editable = false;
            TableRelation = "Dimension Set Entry";

            trigger OnLookup()
            begin
                Rec.ShowDimensions();
            end;
        }
    }

    keys
    {
        key(Key1; "Deposit No.", "Line No.")
        {
            Clustered = true;
            SumIndexFields = Amount;
        }
        key(Key2; "Account Type", "Account No.")
        {
        }
        key(Key3; "Document No.", "Posting Date")
        {
        }
        key(Key4; "Bank Account Ledger Entry No.")
        {
        }
    }

    fieldgroups
    {
    }

    var
        DimMgt: Codeunit DimensionManagement;

    procedure ShowDimensions()
    begin
        DimMgt.ShowDimensionSet("Dimension Set ID", StrSubstNo('%1 %2 %3', TableCaption(), "Document No.", "Line No."));
    end;

    procedure ShowAccountCard()
    var
        GLAcc: Record "G/L Account";
        Cust: Record Customer;
        Vend: Record Vendor;
        BankAcc: Record "Bank Account";
    begin
        case "Account Type" of
            "Account Type"::"G/L Account":
                begin
                    GLAcc."No." := "Account No.";
                    PAGE.Run(PAGE::"G/L Account Card", GLAcc);
                end;
            "Account Type"::Customer:
                begin
                    Cust."No." := "Account No.";
                    PAGE.Run(PAGE::"Customer Card", Cust);
                end;
            "Account Type"::Vendor:
                begin
                    Vend."No." := "Account No.";
                    PAGE.Run(PAGE::"Vendor Card", Vend);
                end;
            "Account Type"::"Bank Account":
                begin
                    BankAcc."No." := "Account No.";
                    PAGE.Run(PAGE::"Bank Account Card", BankAcc);
                end;
        end;
    end;

    procedure ShowAccountLedgerEntries()
    var
        GLEntry: Record "G/L Entry";
        CustLedgEntry: Record "Cust. Ledger Entry";
        VendLedgEntry: Record "Vendor Ledger Entry";
        BankAccLedgEntry: Record "Bank Account Ledger Entry";
    begin
        case "Account Type" of
            "Account Type"::"G/L Account":
                begin
                    GLEntry.SetCurrentKey("G/L Account No.", "Posting Date");
                    GLEntry.SetRange("G/L Account No.", "Account No.");
                    if not GLEntry.Get("Entry No.") then
                        if GLEntry.FindLast() then;
                    PAGE.Run(PAGE::"General Ledger Entries", GLEntry);
                end;
            "Account Type"::Customer:
                begin
                    CustLedgEntry.SetCurrentKey("Customer No.", "Posting Date");
                    CustLedgEntry.SetRange("Customer No.", "Account No.");
                    if not CustLedgEntry.Get("Entry No.") then
                        if CustLedgEntry.FindLast() then;
                    PAGE.Run(PAGE::"Customer Ledger Entries", CustLedgEntry);
                end;
            "Account Type"::Vendor:
                begin
                    VendLedgEntry.SetCurrentKey("Vendor No.", "Posting Date");
                    VendLedgEntry.SetRange("Vendor No.", "Account No.");
                    if not VendLedgEntry.Get("Entry No.") then
                        if VendLedgEntry.FindLast() then;
                    PAGE.Run(PAGE::"Vendor Ledger Entries", VendLedgEntry);
                end;
            "Account Type"::"Bank Account":
                begin
                    BankAccLedgEntry.SetCurrentKey("Bank Account No.", "Posting Date");
                    BankAccLedgEntry.SetRange("Bank Account No.", "Account No.");
                    if not BankAccLedgEntry.Get("Entry No.") then
                        if BankAccLedgEntry.FindLast() then;
                    PAGE.Run(PAGE::"Bank Account Ledger Entries", BankAccLedgEntry);
                end;
        end;
    end;
}

