// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Dimension.Correction;

using Microsoft.Finance.Dimension;

table 2584 "Dim Correction Set Buffer"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Dimension Correction Entry No."; Integer)
        {
            DataClassification = CustomerContent;
            TableRelation = "Dimension Correction"."Entry No.";
        }

        field(2; "Dimension Set ID"; Integer)
        {
            DataClassification = CustomerContent;
            TableRelation = "Dimension Set Entry"."Dimension Set ID";
        }

        field(3; "Target Set ID"; Integer)
        {
            DataClassification = CustomerContent;
            TableRelation = "Dimension Set Entry"."Dimension Set ID";
        }

        field(4; "Multiple Target Set ID"; Boolean)
        {
            DataClassification = CustomerContent;
        }

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

    procedure AddLedgerEntry(EntryNo: Integer)
    var
        LedgerEntries: Text;
    begin
        LedgerEntries := GetSetLedgerEntries();
        LedgerEntries += StrSubstNo(LedgerEntryNoFormatTxt, EntryNo);
        SetLedgerEntries(LedgerEntries);
    end;

    procedure ContainsLedgerEntry(EntryNo: Integer): Boolean
    var
        LedgerEntries: Text;
    begin
        LedgerEntries := GetSetLedgerEntries();
        exit(LedgerEntries.Contains(StrSubstNo(LedgerEntryNoFormatTxt, EntryNo)));
    end;

    procedure SetLedgerEntries(LedgerEntries: Text)
    var
        LedgerEntriesOutStream: OutStream;
    begin
        Rec."Ledger Entries".CreateOutStream(LedgerEntriesOutStream);
        LedgerEntriesOutStream.WriteText(LedgerEntries);
    end;

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
