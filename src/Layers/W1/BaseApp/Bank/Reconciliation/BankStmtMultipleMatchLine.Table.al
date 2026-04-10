// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Reconciliation;

using Microsoft.Finance.GeneralLedger.Journal;

/// <summary>
/// Temporary table for managing multiple match scenarios in bank statement reconciliation.
/// Stores information about multiple potential matches for a single bank statement line,
/// enabling users to review and select the most appropriate match from several candidates.
/// Used in complex matching scenarios where automatic algorithms identify multiple valid options.
/// </summary>
/// <remarks>
/// Contains match candidate details including entry numbers, account information, document references,
/// and due dates. Supports the review process for ambiguous matches where user intervention is
/// required to select the correct application. Facilitates one-to-many and many-to-one matching scenarios.
/// </remarks>
table 1249 "Bank Stmt Multiple Match Line"
{
    Caption = 'Bank Stmt Multiple Match Line';
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Sequential line number for organizing multiple match candidates.
        /// Used to group and order match options for a specific reconciliation scenario.
        /// </summary>
        field(1; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        /// <summary>
        /// Ledger entry number of the potential match candidate.
        /// References the specific customer, vendor, or G/L entry that could be matched.
        /// </summary>
        field(2; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        /// <summary>
        /// Type of account for the match candidate.
        /// Specifies whether the match is against G/L Account, Customer, or Vendor entries.
        /// </summary>
        field(4; "Account Type"; Option)
        {
            Caption = 'Account Type';
            OptionCaption = 'G/L Account,Customer,Vendor';
            OptionMembers = "G/L Account",Customer,Vendor;
        }
        /// <summary>
        /// Account number of the potential match candidate.
        /// Identifies the specific G/L account, customer, or vendor for the match.
        /// </summary>
        field(5; "Account No."; Code[20])
        {
            Caption = 'Account No.';
        }
        /// <summary>
        /// Document number associated with the match candidate entry.
        /// Provides reference information for identifying and validating the match.
        /// </summary>
        field(6; "Document No."; Code[20])
        {
            Caption = 'Document No.';
        }
        /// <summary>
        /// Due date of the match candidate entry.
        /// Used for temporal matching analysis and payment timing validation.
        /// </summary>
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

    /// <summary>
    /// Inserts a new multiple match line record from a ledger entry matching buffer.
    /// Populates match candidate information including account details, entry references,
    /// and document information for user review and selection in multiple match scenarios.
    /// </summary>
    /// <param name="TempLedgerEntryMatchingBuffer">Source ledger entry matching buffer containing match candidate data.</param>
    /// <param name="LineNo">Line number for organizing multiple match candidates.</param>
    /// <param name="AccountType">Type of account for the match candidate (G/L Account, Customer, Vendor).</param>
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

