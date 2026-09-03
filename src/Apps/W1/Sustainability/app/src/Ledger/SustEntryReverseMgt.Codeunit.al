namespace Microsoft.Sustainability.Ledger;

using Microsoft.Finance.Dimension;
using Microsoft.Sustainability.Account;
using System.Telemetry;
using System.Utilities;

codeunit 6243 "Sust. Entry Reverse Mgt."
{
    Permissions = tabledata "Sustainability Ledger Entry" = rim;

    var
        AlreadyReversedErr: Label 'Entry No. %1 has already been reversed.', Comment = '%1 = Entry No.';
        DocumentEntryErr: Label 'Entry No. %1 was posted from a document and cannot be reversed from here. Use a corrective document instead.', Comment = '%1 = Entry No.';
        ConfirmReverseQst: Label 'Do you want to reverse the selected sustainability ledger entry?';
        ConfirmReverseMultipleQst: Label 'Do you want to reverse %1 sustainability ledger entries?', Comment = '%1 = Count';
        SustainabilityTelemetryFeatureLbl: Label 'Sustainability', Locked = true;
        LedgerEntryReversedTelemetryLbl: Label 'Sustainability Ledger Entry Reversed', Locked = true;

    procedure ReverseEntry(var SustLedgEntry: Record "Sustainability Ledger Entry")
    var
        NewSustLedgEntry: Record "Sustainability Ledger Entry";
        FeatureTelemetry: Codeunit "Feature Telemetry";
    begin
        ValidateEntryForReversal(SustLedgEntry);

        CreateReversalEntry(SustLedgEntry, NewSustLedgEntry);
        UpdateOriginalEntry(SustLedgEntry, NewSustLedgEntry."Entry No.");

        FeatureTelemetry.LogUsage('0000V2Q', SustainabilityTelemetryFeatureLbl, LedgerEntryReversedTelemetryLbl);

        OnAfterReverseEntry(SustLedgEntry, NewSustLedgEntry);
    end;

    procedure ReverseEntries(var SustLedgEntry: Record "Sustainability Ledger Entry"): Integer
    var
        SustLedgEntryToReverse: Record "Sustainability Ledger Entry";
        ConfirmManagement: Codeunit "Confirm Management";
        EntryCount: Integer;
        ConfirmQuestion: Text;
    begin
        EntryCount := SustLedgEntry.Count();

        if EntryCount = 0 then
            exit(0);

        if EntryCount = 1 then
            ConfirmQuestion := ConfirmReverseQst
        else
            ConfirmQuestion := StrSubstNo(ConfirmReverseMultipleQst, EntryCount);

        if not ConfirmManagement.GetResponseOrDefault(ConfirmQuestion, false) then
            exit(0);

        // Validate all entries first (all-or-nothing)
        SustLedgEntryToReverse.Copy(SustLedgEntry);
        SustLedgEntryToReverse.SetLoadFields("Entry No.", Reversed, "Journal Template Name", "Account No.", "Dimension Set ID");
        if SustLedgEntryToReverse.FindSet() then
            repeat
                ValidateEntryForReversal(SustLedgEntryToReverse);
            until SustLedgEntryToReverse.Next() = 0;

        // Reverse all entries
        if SustLedgEntry.FindSet(true) then
            repeat
                ReverseEntry(SustLedgEntry);
            until SustLedgEntry.Next() = 0;

        exit(EntryCount);
    end;

    procedure ReverseEntriesForGLEntry(GLEntryNo: Integer)
    var
        SustainabilityLedgEntry: Record "Sustainability Ledger Entry";
    begin
        if GLEntryNo = 0 then
            exit;

        SustainabilityLedgEntry.SetRange("G/L Entry No.", GLEntryNo);
        SustainabilityLedgEntry.SetRange(Reversed, false);
        if SustainabilityLedgEntry.FindSet(true) then
            repeat
                ReverseEntry(SustainabilityLedgEntry);
            until SustainabilityLedgEntry.Next() = 0;
    end;

    local procedure ValidateEntryForReversal(SustLedgEntry: Record "Sustainability Ledger Entry")
    var
        SustainabilityAccount: Record "Sustainability Account";
        DimMgt: Codeunit DimensionManagement;
        TableID: array[10] of Integer;
        No: array[10] of Code[20];
    begin
        if SustLedgEntry.Reversed then
            Error(AlreadyReversedErr, SustLedgEntry."Entry No.");

        if SustLedgEntry."Journal Template Name" = '' then
            Error(DocumentEntryErr, SustLedgEntry."Entry No.");

        // Keep the reversal consistent with posting. The checks below mirror those that
        // "Sustainability Jnl.-Check" runs during posting, so we cannot reverse into a state
        // that posting itself would reject (e.g. a now-blocked account, an account that no
        // longer allows direct posting, or a blocked dimension combination).
        // IMPORTANT: if you add or change checks/side-effects in "Sustainability Post Mgt" or
        // "Sustainability Jnl.-Check", revisit this codeunit so posting and reversal stay in sync.
        SustainabilityAccount.Get(SustLedgEntry."Account No.");
        SustainabilityAccount.CheckAccountReadyForPosting();
        SustainabilityAccount.TestField("Direct Posting");

        if not DimMgt.CheckDimIDComb(SustLedgEntry."Dimension Set ID") then
            Error(DimMgt.GetDimCombErr());

        TableID[1] := Database::"Sustainability Account";
        No[1] := SustLedgEntry."Account No.";
        if not DimMgt.CheckDimValuePosting(TableID, No, SustLedgEntry."Dimension Set ID") then
            Error(DimMgt.GetDimValuePostingErr());
    end;

    local procedure CreateReversalEntry(OriginalEntry: Record "Sustainability Ledger Entry"; var NewEntry: Record "Sustainability Ledger Entry")
    begin
        NewEntry.Init();
        NewEntry.TransferFields(OriginalEntry, false);
        // AutoIncrement assigns the Entry No. on Insert (matches Sustainability Post Mgt and G/L reversal engine-assigned numbering).
        NewEntry."Entry No." := 0;
        // Post the reversal on the original entry's posting date so emissions net to zero within the same period (matches G/L Reverse).
        NewEntry."Posting Date" := OriginalEntry."Posting Date";
        NewEntry."Document No." := OriginalEntry."Document No.";
        NewEntry.Validate("User ID", CopyStr(UserId(), 1, MaxStrLen(NewEntry."User ID")));

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

        OnBeforeInsertReversalSustainabilityLedgerEntry(NewEntry, OriginalEntry);
        NewEntry.Insert(true);
    end;

    local procedure UpdateOriginalEntry(var OriginalEntry: Record "Sustainability Ledger Entry"; ReversalEntryNo: Integer)
    begin
        OriginalEntry.Reversed := true;
        OriginalEntry."Reversed by Entry No." := ReversalEntryNo;
        OriginalEntry.Modify(true);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertReversalSustainabilityLedgerEntry(var SustainabilityLedgerEntry: Record "Sustainability Ledger Entry"; OriginalSustainabilityLedgerEntry: Record "Sustainability Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterReverseEntry(OriginalSustainabilityLedgerEntry: Record "Sustainability Ledger Entry"; ReversalSustainabilityLedgerEntry: Record "Sustainability Ledger Entry")
    begin
    end;
}
