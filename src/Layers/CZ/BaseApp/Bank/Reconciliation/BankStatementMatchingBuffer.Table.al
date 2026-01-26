// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Reconciliation;

using Microsoft.Finance.GeneralLedger.Journal;

/// <summary>
/// Temporary buffer table for storing and ranking potential matches during automatic bank reconciliation.
/// This table accumulates candidate ledger entries that could potentially match with bank statement lines,
/// along with scoring information, quality metrics, and matching criteria details. Used internally by
/// matching algorithms to evaluate, rank, and select the best matches based on configurable rules and
/// thresholds before applying final matching decisions.
/// </summary>
/// <remarks>
/// Key features include match quality scoring, detailed criteria tracking (amounts, dates, document numbers),
/// one-to-many relationship handling, related party matching status, and comprehensive match details for
/// audit and review purposes. The buffer enables sophisticated ranking algorithms that consider multiple
/// matching factors simultaneously, supporting both exact and fuzzy matching scenarios with weighted scoring.
/// Used exclusively during matching processes and cleared after each matching operation completion.
/// </remarks>
table 1250 "Bank Statement Matching Buffer"
{
    Caption = 'Bank Statement Matching Buffer';
    ReplicateData = false;
    TableType = Temporary;
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Bank statement line number being evaluated for matching.
        /// References the source statement line for which potential matches are being identified.
        /// </summary>
        field(1; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        /// <summary>
        /// Ledger entry number of the potential match candidate.
        /// References the bank account, customer, vendor, or GL entry that could match the statement line.
        /// </summary>
        field(2; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        /// <summary>
        /// Match quality score indicating the strength of the potential match.
        /// Higher scores represent better matches based on multiple matching criteria and algorithms.
        /// </summary>
        field(3; Quality; Integer)
        {
            Caption = 'Quality';
        }
        /// <summary>
        /// Type of account for the potential match candidate.
        /// Determines whether the match is against a customer, vendor, bank account, or GL account entry.
        /// </summary>
        field(4; "Account Type"; Enum "Gen. Journal Account Type")
        {
            Caption = 'Account Type';
        }
        /// <summary>
        /// Account number of the potential match candidate.
        /// Identifies the specific customer, vendor, bank account, or GL account for the match.
        /// </summary>
        field(5; "Account No."; Code[20])
        {
            Caption = 'Account No.';
        }
        /// <summary>
        /// Indicates if this match represents a one-to-many relationship scenario.
        /// True when one statement line could potentially match multiple ledger entries.
        /// </summary>
        field(10; "One to Many Match"; Boolean)
        {
            Caption = 'One to Many Match';
        }
        /// <summary>
        /// Number of related entries in a one-to-many or many-to-one matching scenario.
        /// Used for aggregating multiple entries that collectively match a single statement line.
        /// </summary>
        field(11; "No. of Entries"; Integer)
        {
            Caption = 'No. of Entries';
        }
        /// <summary>
        /// Total remaining amount across multiple entries in complex matching scenarios.
        /// Calculated sum for one-to-many matches to compare against statement line amount.
        /// </summary>
        field(12; "Total Remaining Amount"; Decimal)
        {
            Caption = 'Total Remaining Amount';
        }
        /// <summary>
        /// Status of related party matching for the potential match candidate.
        /// Indicates whether customer/vendor information matches the statement line party details.
        /// </summary>
        field(13; "Related Party Matched"; Option)
        {
            Caption = 'Related Party Matched';
            OptionCaption = 'Not Considered,Fully,Partially,No';
            OptionMembers = "Not Considered",Fully,Partially,No;
        }
        /// <summary>
        /// Detailed description of matching criteria that contributed to the match score.
        /// Provides audit trail and explanation of why this candidate was identified as a potential match.
        /// </summary>
        field(14; "Match Details"; Text[250])
        {
            Caption = 'Match Details';
        }
        /// <summary>
        /// Score contribution from document number matching algorithms.
        /// Measures how well the statement line document reference matches the ledger entry document number.
        /// </summary>
        field(15; "Doc. No. Score"; Integer)
        {
            Caption = 'Document No. Score';
        }
        /// <summary>
        /// Score contribution from external document number matching algorithms.
        /// Measures how well the statement line reference matches the ledger entry external document number.
        /// </summary>
        field(16; "Ext. Doc. No. Score"; Integer)
        {
            Caption = 'External Document No. Score';
        }
        /// <summary>
        /// Score contribution from description and narrative text matching algorithms.
        /// Measures similarity between statement line description and ledger entry description.
        /// </summary>
        field(17; "Description Score"; Integer)
        {
            Caption = 'Description Score';
        }
        /// <summary>
        /// Amount difference between statement line and potential match candidate.
        /// Used to evaluate amount-based matching tolerance and precision.
        /// </summary>
        field(18; "Amount Difference"; Decimal)
        {
            Caption = 'Amount Matches';
        }
        /// <summary>
        /// Date difference in days between statement line and potential match candidate.
        /// Used to evaluate date-based matching tolerance and temporal proximity.
        /// </summary>
        field(19; "Date Difference"; Integer)
        {
            Caption = 'Date Matches';
        }
#if not CLEANSCHEMA25
        field(30000; "Letter Type"; Option)
        {
            Caption = 'Letter Type';
            DataClassification = SystemMetadata;
            OptionCaption = 'Sales,Purchase';
            OptionMembers = Sales,Purchase;
            ObsoleteState = Removed;
            ObsoleteReason = 'Replaced by Advance Payments Localization for Czech.';
            ObsoleteTag = '25.0';
        }
        field(31001; "Letter No."; Code[20])
        {
            Caption = 'Letter No.';
            DataClassification = SystemMetadata;
            ObsoleteState = Removed;
            ObsoleteReason = 'Replaced by Advance Payments Localization for Czech.';
            ObsoleteTag = '25.0';
        }
#endif
        /// <summary>
        /// Score for exact document number matches without fuzzy logic.
        /// Higher weight given to precise document number correspondences.
        /// </summary>
        field(20; "Doc. No. Exact Score"; Integer)
        {
            Caption = 'Doc. No. Exact Score';
        }
        /// <summary>
        /// Score for exact external document number matches without fuzzy logic.
        /// Higher weight given to precise external document number correspondences.
        /// </summary>
        field(21; "Ext. Doc. No. Exact Score"; Integer)
        {
            Caption = 'Ext. Doc. No. Exact Score';
        }
        /// <summary>
        /// Score for exact description matches without fuzzy logic.
        /// Higher weight given to precise description text correspondences.
        /// </summary>
        field(22; "Description Exact Score"; Integer)
        {
            Caption = 'Description Exact Score';
        }
    }

    keys
    {
        key(Key1; "Line No.", "Entry No.", "Account Type", "Account No.")
        {
            Clustered = true;
        }
        key(Key2; Quality, "No. of Entries")
        {
        }
    }

    fieldgroups
    {
    }

    /// <summary>
    /// Adds or updates a match candidate entry in the temporary buffer for ranking and evaluation.
    /// Creates new buffer entries for potential matches or updates existing entries with improved quality scores.
    /// Used during the matching process to accumulate and rank all possible match candidates.
    /// </summary>
    /// <param name="LineNo">Bank statement line number being matched.</param>
    /// <param name="EntryNo">Ledger entry number of the potential match candidate.</param>
    /// <param name="NewQuality">Quality score for this match candidate based on matching algorithms.</param>
    /// <param name="AccountType">Type of account for the match candidate (Customer, Vendor, Bank Account, etc.).</param>
    /// <param name="AccountNo">Account number of the match candidate.</param>
    procedure AddMatchCandidate(LineNo: Integer; EntryNo: Integer; NewQuality: Integer; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20])
    var
        BankStatementMatchingBuffer: Record "Bank Statement Matching Buffer";
    begin
        BankStatementMatchingBuffer.Init();
        BankStatementMatchingBuffer."Line No." := LineNo;
        BankStatementMatchingBuffer."Entry No." := EntryNo;
        BankStatementMatchingBuffer."Account No." := AccountNo;
        BankStatementMatchingBuffer."Account Type" := AccountType;
        BankStatementMatchingBuffer.Quality := NewQuality;
        OnAddMatchCandidateOnAfterAssignBankStatementMatchingBufferValues(Rec, BankStatementMatchingBuffer);
        if Get(LineNo, EntryNo, AccountType, AccountNo) then begin
            Rec := BankStatementMatchingBuffer;
            Modify();
        end else begin
            Rec := BankStatementMatchingBuffer;
            Insert();
        end;
    end;

    /// <summary>
    /// Inserts or updates a one-to-many matching rule for scenarios where multiple ledger entries match a single statement line.
    /// Manages complex matching relationships by aggregating multiple entries under a common account and calculating
    /// collective remaining amounts and quality scores for the one-to-many matching evaluation.
    /// </summary>
    /// <param name="TempLedgerEntryMatchingBuffer">Source ledger entry data for the one-to-many relationship.</param>
    /// <param name="LineNo">Bank statement line number participating in the one-to-many match.</param>
    /// <param name="RelatedPartyMatched">Status of related party matching for this relationship.</param>
    /// <param name="AccountType">Type of account involved in the one-to-many relationship.</param>
    /// <param name="RemainingAmount">Remaining amount contribution from this entry to the total match amount.</param>
    procedure InsertOrUpdateOneToManyRule(TempLedgerEntryMatchingBuffer: Record "Ledger Entry Matching Buffer" temporary; LineNo: Integer; RelatedPartyMatched: Option; AccountType: Enum "Gen. Journal Account Type"; RemainingAmount: Decimal)
    begin
        Init();
        SetRange("Line No.", LineNo);
        SetRange("Account Type", AccountType);
        SetRange("Account No.", TempLedgerEntryMatchingBuffer."Account No.");
        SetRange("Entry No.", -1);
        SetRange("One to Many Match", true);

        if not FindFirst() then begin
            "Line No." := LineNo;
            "Account Type" := AccountType;
            "Account No." := TempLedgerEntryMatchingBuffer."Account No.";
            "Entry No." := -1;
            "One to Many Match" := true;
            "No. of Entries" := 1;
            "Related Party Matched" := RelatedPartyMatched;
            OnInsertOrUpdateOneToManyRuleOnBeforeInsert(Rec, TempLedgerEntryMatchingBuffer);
            Insert();
        end else
            "No. of Entries" += 1;

        "Total Remaining Amount" += RemainingAmount;
        Modify(true);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAddMatchCandidateOnAfterAssignBankStatementMatchingBufferValues(var BankStatementMatchingBuffer: Record "Bank Statement Matching Buffer"; var BankStatementMatchingBuffer2: Record "Bank Statement Matching Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertOrUpdateOneToManyRuleOnBeforeInsert(var BankStatementMatchingBuffer: Record "Bank Statement Matching Buffer"; TempLedgerEntryMatchingBuffer: Record "Ledger Entry Matching Buffer" temporary)
    begin
    end;
}
