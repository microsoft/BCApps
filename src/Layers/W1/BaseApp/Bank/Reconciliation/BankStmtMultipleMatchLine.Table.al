// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Reconciliation;

using Microsoft.Finance.GeneralLedger.Journal;

table 1249 "Bank Stmt Multiple Match Line"
{
    Caption = 'Bank Stmt Multiple Match Line';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(2; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(4; "Account Type"; Option)
        {
            Caption = 'Account Type';
            OptionCaption = 'G/L Account,Customer,Vendor';
            OptionMembers = "G/L Account",Customer,Vendor;
        }
        field(5; "Account No."; Code[20])
        {
            Caption = 'Account No.';
        }
        field(6; "Document No."; Code[20])
        {
            Caption = 'Document No.';
        }
        field(10; "Due Date"; Date)
        {
            Caption = 'Due Date';
        }
    }

    keys
    {
        key(Key1; "Line No.", "Entry No.", "Account Type", "Account No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    procedure InsertLine(TempLedgerEntryMatchingBuffer: Record "Ledger Entry Matching Buffer" temporary; LineNo: Integer; AccountType: Enum "Gen. Journal Account Type")
    begin
        "Line No." := LineNo;
        "Account Type" := AccountType.AsInteger();
        "Account No." := TempLedgerEntryMatchingBuffer."Account No.";
        "Entry No." := TempLedgerEntryMatchingBuffer."Entry No.";
        "Due Date" := TempLedgerEntryMatchingBuffer."Due Date";
        "Document No." := TempLedgerEntryMatchingBuffer."Document No.";
        OnInsertLineOnBeforeInsert(Rec, TempLedgerEntryMatchingBuffer, LineNo, AccountType);
        Insert();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertLineOnBeforeInsert(var BankStmtMultipleMatchLine: Record "Bank Stmt Multiple Match Line"; TempLedgerEntryMatchingBuffer: Record "Ledger Entry Matching Buffer" temporary; LineNo: Integer; AccountType: Enum "Gen. Journal Account Type")
    begin
    end;
}

