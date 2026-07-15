namespace Microsoft.Sustainability.Ledger;

using Microsoft.Sustainability.Setup;

codeunit 6230 "Sust. Entry Reverse Mgt."
{
    Permissions = tabledata "Sustainability Ledger Entry" = rimd;

    var
        AlreadyReversedErr: Label 'Entry No. %1 has already been reversed.', Comment = '%1 = Entry No.';
        DocumentEntryErr: Label 'Entry No. %1 was posted from a document and cannot be reversed from here. Use a corrective document instead.', Comment = '%1 = Entry No.';
        ConfirmReverseQst: Label 'Do you want to reverse the selected sustainability ledger entry?';
        ConfirmReverseMultipleQst: Label 'Do you want to reverse %1 sustainability ledger entries?', Comment = '%1 = Count';

    procedure ReverseEntry(var SustLedgEntry: Record "Sustainability Ledger Entry")
    var
        NewSustLedgEntry: Record "Sustainability Ledger Entry";
        NextEntryNo: Integer;
    begin
        ValidateEntryForReversal(SustLedgEntry);

        NextEntryNo := GetNextEntryNo();

        CreateReversalEntry(SustLedgEntry, NewSustLedgEntry, NextEntryNo);
        UpdateOriginalEntry(SustLedgEntry, NextEntryNo);
    end;

    procedure ReverseEntryFromGL(var SustLedgEntry: Record "Sustainability Ledger Entry")
    var
        NewSustLedgEntry: Record "Sustainability Ledger Entry";
        NextEntryNo: Integer;
    begin
        if SustLedgEntry.Reversed then
            exit;

        NextEntryNo := GetNextEntryNo();

        CreateReversalEntry(SustLedgEntry, NewSustLedgEntry, NextEntryNo);
        UpdateOriginalEntry(SustLedgEntry, NextEntryNo);
    end;

    procedure ReverseEntries(var SustLedgEntry: Record "Sustainability Ledger Entry"): Integer
    var
        TempSustLedgEntry: Record "Sustainability Ledger Entry";
        EntryCount: Integer;
    begin
        EntryCount := SustLedgEntry.Count();

        if EntryCount = 0 then
            exit(0);

        if EntryCount = 1 then begin
            if not Confirm(ConfirmReverseQst) then
                exit(0);
        end else
            if not Confirm(ConfirmReverseMultipleQst, false, EntryCount) then
                exit(0);

        // Validate all entries first (all-or-nothing)
        TempSustLedgEntry.Copy(SustLedgEntry);
        TempSustLedgEntry.SetLoadFields("Entry No.", Reversed, "Journal Template Name");
        if TempSustLedgEntry.FindSet() then
            repeat
                ValidateEntryForReversal(TempSustLedgEntry);
            until TempSustLedgEntry.Next() = 0;

        // Reverse all entries
        if SustLedgEntry.FindSet(true) then
            repeat
                ReverseEntry(SustLedgEntry);
            until SustLedgEntry.Next() = 0;

        exit(EntryCount);
    end;

    local procedure ValidateEntryForReversal(SustLedgEntry: Record "Sustainability Ledger Entry")
    begin
        if SustLedgEntry.Reversed then
            Error(AlreadyReversedErr, SustLedgEntry."Entry No.");

        if SustLedgEntry."Journal Template Name" = '' then
            Error(DocumentEntryErr, SustLedgEntry."Entry No.");
    end;

    local procedure CreateReversalEntry(OriginalEntry: Record "Sustainability Ledger Entry"; var NewEntry: Record "Sustainability Ledger Entry"; NewEntryNo: Integer)
    begin
        NewEntry.Init();
        NewEntry.TransferFields(OriginalEntry, false);
        NewEntry."Entry No." := NewEntryNo;
        NewEntry."Posting Date" := WorkDate();
        NewEntry."Document No." := OriginalEntry."Document No.";

        // Negate emission values
        NewEntry."Emission CO2" := -OriginalEntry."Emission CO2";
        NewEntry."Emission CH4" := -OriginalEntry."Emission CH4";
        NewEntry."Emission N2O" := -OriginalEntry."Emission N2O";
        NewEntry."CO2e Emission" := -OriginalEntry."CO2e Emission";
        NewEntry."Carbon Fee" := -OriginalEntry."Carbon Fee";

        // Negate water & waste values
        NewEntry."Water Intensity" := -OriginalEntry."Water Intensity";
        NewEntry."Discharged Into Water" := -OriginalEntry."Discharged Into Water";
        NewEntry."Waste Intensity" := -OriginalEntry."Waste Intensity";
        NewEntry."Energy Consumption" := -OriginalEntry."Energy Consumption";

        // Set reversal tracking fields
        NewEntry.Reversed := true;
        NewEntry."Reversed Entry No." := OriginalEntry."Entry No.";
        NewEntry."Reversed by Entry No." := 0;

        NewEntry.Insert(true);
    end;

    local procedure UpdateOriginalEntry(var OriginalEntry: Record "Sustainability Ledger Entry"; ReversalEntryNo: Integer)
    begin
        OriginalEntry.Reversed := true;
        OriginalEntry."Reversed by Entry No." := ReversalEntryNo;
        OriginalEntry.Modify(true);
    end;

    local procedure GetNextEntryNo(): Integer
    var
        SustLedgEntry: Record "Sustainability Ledger Entry";
    begin
        SustLedgEntry.SetCurrentKey("Entry No.");
        if SustLedgEntry.FindLast() then
            exit(SustLedgEntry."Entry No." + 1)
        else
            exit(1);
    end;
}
