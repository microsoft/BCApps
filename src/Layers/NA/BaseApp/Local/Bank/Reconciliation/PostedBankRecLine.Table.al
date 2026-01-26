// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Reconciliation;

using Microsoft.Bank.BankAccount;
using Microsoft.Bank.Check;
using Microsoft.Bank.Ledger;
using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.Foundation.NoSeries;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;

table 10124 "Posted Bank Rec. Line"
{
    Caption = 'Posted Bank Rec. Line';
    DrillDownPageID = "Posted Bank Rec. Lines";
    LookupPageID = "Posted Bank Rec. Lines";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Bank Account No."; Code[20])
        {
            Caption = 'Bank Account No.';
            TableRelation = "Bank Account";
        }
        field(2; "Statement No."; Code[20])
        {
            Caption = 'Statement No.';
            TableRelation = "Posted Bank Rec. Header"."Statement No." where("Bank Account No." = field("Bank Account No."));
        }
        field(3; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(4; "Record Type"; Option)
        {
            Caption = 'Record Type';
            OptionCaption = 'Check,Deposit,Adjustment';
            OptionMembers = Check,Deposit,Adjustment;
        }
        field(5; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
        field(6; "Document Type"; Enum "Gen. Journal Document Type")
        {
            Caption = 'Document Type';
        }
        field(7; "Document No."; Code[20])
        {
            Caption = 'Document No.';
        }
        field(8; "Account Type"; enum "Gen. Journal Account Type")
        {
            Caption = 'Account Type';
        }
        field(9; "Account No."; Code[20])
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
        field(10; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(11; Amount; Decimal)
        {
            Caption = 'Amount';
        }
        field(12; Cleared; Boolean)
        {
            Caption = 'Cleared';
        }
        field(13; "Cleared Amount"; Decimal)
        {
            Caption = 'Cleared Amount';
        }
        field(14; "Bal. Account Type"; enum "Gen. Journal Account Type")
        {
            Caption = 'Bal. Account Type';
        }
        field(15; "Bal. Account No."; Code[20])
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
        field(16; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            TableRelation = Currency;
        }
        field(17; "Currency Factor"; Decimal)
        {
            Caption = 'Currency Factor';
        }
        field(18; "External Document No."; Code[35])
        {
            Caption = 'External Document No.';
        }
        field(19; "Bank Ledger Entry No."; Integer)
        {
            Caption = 'Bank Ledger Entry No.';
            TableRelation = "Bank Account Ledger Entry"."Entry No.";
        }
        field(20; "Check Ledger Entry No."; Integer)
        {
            Caption = 'Check Ledger Entry No.';
            TableRelation = "Check Ledger Entry"."Entry No.";
        }
        field(21; "Adj. Source Record ID"; Option)
        {
            Caption = 'Adj. Source Record ID';
            OptionCaption = 'Check,Deposit,Adjustment';
            OptionMembers = Check,Deposit,Adjustment;
        }
        field(22; "Adj. Source Document No."; Code[20])
        {
            Caption = 'Adj. Source Document No.';
        }
        field(23; "Adj. No. Series"; Code[20])
        {
            Caption = 'Adj. No. Series';
            TableRelation = "No. Series";
        }
        field(24; "Shortcut Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,2,1';
            Caption = 'Shortcut Dimension 1 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1));
        }
        field(25; "Shortcut Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,2,2';
            Caption = 'Shortcut Dimension 2 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2));
        }
        field(27; Positive; Boolean)
        {
            Caption = 'Positive';
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
        key(Key1; "Bank Account No.", "Statement No.", "Record Type", "Line No.")
        {
            Clustered = true;
        }
        key(Key2; "Bank Account No.", "Statement No.", "Record Type", Cleared)
        {
            SumIndexFields = Amount, "Cleared Amount";
        }
        key(Key3; "Bank Account No.", "Statement No.", "Record Type", Positive)
        {
            SumIndexFields = Amount;
        }
        key(Key4; "Bank Account No.", "Statement No.", "Posting Date", "Document Type", "Document No.", "External Document No.")
        {
        }
        key(Key5; "Bank Account No.", "Statement No.", "Record Type", "Bal. Account Type", "Bal. Account No.", Positive)
        {
            SumIndexFields = Amount;
        }
        key(Key6; "Bank Account No.", "Statement No.", "Record Type", "Account Type", Positive, "Account No.")
        {
            SumIndexFields = Amount;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        BankRecCommentLine.SetRange("Table Name", BankRecCommentLine."Table Name"::"Bank Rec.");
        BankRecCommentLine.SetRange("Bank Account No.", "Bank Account No.");
        BankRecCommentLine.SetRange("No.", "Statement No.");
        BankRecCommentLine.SetRange("Line No.", "Line No.");
        BankRecCommentLine.DeleteAll();
    end;

    var
        BankRecCommentLine: Record "Bank Comment Line";
        DimMgt: Codeunit DimensionManagement;

    procedure CreateDim(DefaultDimSource: List of [Dictionary of [Integer, Code[20]]])
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateDim(Rec, DefaultDimSource, IsHandled);
        if IsHandled then
            exit;

        "Shortcut Dimension 1 Code" := '';
        "Shortcut Dimension 2 Code" := '';
        DimMgt.GetDefaultDimID(DefaultDimSource, '', "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code", 0, 0);

        OnAfterCreateDim(Rec, DefaultDimSource);
    end;

    procedure ShowDimensions()
    begin
        "Dimension Set ID" :=
          DimMgt.EditDimensionSet("Dimension Set ID", StrSubstNo('%1 %2 %3', "Document Type", "Document No.", "Line No."),
            "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");

        OnAfterShowDimensions(Rec);
    end;

    procedure ValidateShortcutDimCode(FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
        DimMgt.ValidateShortcutDimValues(FieldNumber, ShortcutDimCode, "Dimension Set ID");
    end;

    procedure LookupShortcutDimCode(FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
        DimMgt.LookupDimValueCode(FieldNumber, ShortcutDimCode);
        Rec.ValidateShortcutDimCode(FieldNumber, ShortcutDimCode);
    end;

    procedure ShowShortcutDimCode(var ShortcutDimCode: array[8] of Code[20])
    begin
        DimMgt.GetShortcutDimensions(Rec."Dimension Set ID", ShortcutDimCode);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateDim(var PostedBankAccRecLine: Record "Posted Bank Rec. Line"; var DefaultDimSource: List of [Dictionary of [Integer, Code[20]]]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateDim(var PostedBankAccRecLine: Record "Posted Bank Rec. Line"; DefaultDimSource: List of [Dictionary of [Integer, Code[20]]])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterShowDimensions(var PostedBankAccRecLine: Record "Posted Bank Rec. Line")
    begin
    end;
}

