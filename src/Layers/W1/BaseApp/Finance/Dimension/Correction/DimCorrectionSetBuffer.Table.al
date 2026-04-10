// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Dimension.Correction;

using Microsoft.Finance.Dimension;

/// <summary>
/// Temporary buffer table for managing dimension set transformations during dimension correction processing.
/// Stores mappings between original and target dimension set IDs with ledger entry tracking.
/// </summary>
table 2584 "Dim Correction Set Buffer"
{
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Reference to the parent dimension correction entry.
        /// </summary>
        field(1; "Dimension Correction Entry No."; Integer)
        {
            DataClassification = CustomerContent;
            TableRelation = "Dimension Correction"."Entry No.";
        }

        /// <summary>
        /// Original dimension set ID to be corrected.
        /// </summary>
        field(2; "Dimension Set ID"; Integer)
        {
            DataClassification = CustomerContent;
            TableRelation = "Dimension Set Entry"."Dimension Set ID";
        }

        /// <summary>
        /// Target dimension set ID after correction is applied.
        /// </summary>
        field(3; "Target Set ID"; Integer)
        {
            DataClassification = CustomerContent;
            TableRelation = "Dimension Set Entry"."Dimension Set ID";
        }

        /// <summary>
        /// Indicates whether multiple target set IDs are required for this dimension set.
        /// </summary>
        field(4; "Multiple Target Set ID"; Boolean)
        {
            DataClassification = CustomerContent;
        }

        /// <summary>
        /// BLOB field containing serialized ledger entry numbers affected by this dimension set correction.
        /// </summary>
        field(5; "Ledger Entries"; Blob)
        {
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(Key1; "Dimension Correction Entry No.", "Dimension Set ID")
        {
            Clustered = true;
        }

        key(Key2; "Dimension Correction Entry No.", "Target Set ID")
        {
        }
        key(Key3; "Dimension Correction Entry No.", "Multiple Target Set ID")
        {
        }
    }

    /// <summary>
    /// Adds a ledger entry number to the list of entries affected by this dimension set correction.
    /// </summary>
    /// <param name="EntryNo">Ledger entry number to add to the affected entries list</param>
    procedure AddLedgerEntry(EntryNo: Integer)
    var
        LedgerEntries: Text;
    begin
        LedgerEntries := GetSetLedgerEntries();
        LedgerEntries += StrSubstNo(LedgerEntryNoFormatTxt, EntryNo);
        SetLedgerEntries(LedgerEntries);
    end;

    /// <summary>
    /// Checks whether a specific ledger entry number is included in the affected entries list.
    /// </summary>
    /// <param name="EntryNo">Ledger entry number to check for inclusion</param>
    /// <returns>True if the entry number is in the affected entries list, false otherwise</returns>
    procedure ContainsLedgerEntry(EntryNo: Integer): Boolean
    var
        LedgerEntries: Text;
    begin
        LedgerEntries := GetSetLedgerEntries();
        exit(LedgerEntries.Contains(StrSubstNo(LedgerEntryNoFormatTxt, EntryNo)));
    end;

    /// <summary>
    /// Sets the list of affected ledger entry numbers in the BLOB field.
    /// </summary>
    /// <param name="LedgerEntries">Formatted text containing ledger entry numbers</param>
    procedure SetLedgerEntries(LedgerEntries: Text)
    var
        LedgerEntriesOutStream: OutStream;
    begin
        Rec."Ledger Entries".CreateOutStream(LedgerEntriesOutStream);
        LedgerEntriesOutStream.WriteText(LedgerEntries);
    end;

    /// <summary>
    /// Retrieves the list of affected ledger entry numbers from the BLOB field.
    /// </summary>
    /// <returns>Formatted text containing ledger entry numbers</returns>
    procedure GetSetLedgerEntries(): Text;
    var
        LedgerEntriesInStream: InStream;
        LedgerEntries: Text;
    begin
        Rec.CalcFields("Ledger Entries");
        Rec."Ledger Entries".CreateInStream(LedgerEntriesInStream);
        LedgerEntriesInStream.ReadText(LedgerEntries);
        exit(LedgerEntries);
    end;

    var
        LedgerEntryNoFormatTxt: Label ';%1;', Locked = true, Comment = '%1 Entry No.';
}
