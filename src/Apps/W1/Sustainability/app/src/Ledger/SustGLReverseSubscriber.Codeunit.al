namespace Microsoft.Sustainability.Ledger;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Posting;
using Microsoft.Finance.GeneralLedger.Reversal;

codeunit 6244 "Sust. GL Reverse Subscriber"
{
    Permissions = tabledata "Sustainability Ledger Entry" = rimd;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Reverse", 'OnReverseGLEntryOnAfterInsertGLEntry', '', false, false)]
    local procedure ReverseSustLedgerEntriesOnReverseGLEntry(var GLEntry: Record "G/L Entry"; GenJnlLine: Record "Gen. Journal Line"; GLEntry2: Record "G/L Entry"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line")
    var
        SustLedgEntry: Record "Sustainability Ledger Entry";
        SustLedgEntryToReverse: Record "Sustainability Ledger Entry";
        SustEntryReverseMgt: Codeunit "Sust. Entry Reverse Mgt.";
        EntryNos: List of [Integer];
        EntryNo: Integer;
    begin
        // GLEntry2 is the original G/L entry being reversed. Sustainability Ledger Entries are linked to it
        // through the shared Document No. and Posting Date (see Sust. Gen. Journal Subscriber posting logic).
        // The event fires once per reversed G/L entry, so a document may be processed more than once;
        // the Reversed filter and the guard below keep this idempotent.
        SustLedgEntry.SetLoadFields("Entry No.");
        SustLedgEntry.SetRange("Document No.", GLEntry2."Document No.");
        SustLedgEntry.SetRange("Posting Date", GLEntry2."Posting Date");
        SustLedgEntry.SetRange(Reversed, false);
        SustLedgEntry.SetFilter("Journal Template Name", '<>%1', '');
        if SustLedgEntry.FindSet() then
            repeat
                EntryNos.Add(SustLedgEntry."Entry No.");
            until SustLedgEntry.Next() = 0;

        foreach EntryNo in EntryNos do
            if SustLedgEntryToReverse.Get(EntryNo) then
                if not SustLedgEntryToReverse.Reversed then
                    SustEntryReverseMgt.ReverseEntry(SustLedgEntryToReverse);
    end;
}
