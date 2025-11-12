// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.NoSeries;

codeunit 9500 "Sequence No. Mgt."
{
    SingleInstance = true;
    InherentPermissions = X;
    Permissions = tabledata "Sequence No. Preview State" = rid;

    var
        GlobalPreviewMode: Boolean;
        GlobalPreviewModeID: Integer;
        LastSeqNoChecked: List of [Integer];
        SeqNoBufferFrom: Dictionary of [Integer, Integer];
        SeqNoBufferTo: Dictionary of [Integer, Integer];
        PendingAllocation: Dictionary of [Integer, Integer];
        SeqNameLbl: Label 'TableSeq%1', Comment = '%1 - Table No.', Locked = true;
        PreviewSeqNameLbl: Label 'PreviewTableSeq%1', Comment = '%1 - Table No.', Locked = true;

    /// <summary>
    /// Clears allocations and other internal states
    /// </summary>
    procedure ClearState()
    begin
        ClearAll(); // may not work for SingleInstance codeunits....
        Clear(GlobalPreviewMode);
        Clear(GlobalPreviewModeID);
        Clear(LastSeqNoChecked);
        Clear(SeqNoBufferFrom);
        Clear(SeqNoBufferFrom);
        Clear(SeqNoBufferTo);
        Clear(PendingAllocation);
    end;

    /// <summary>
    /// Allocates sequence numbers for a given table ID.
    /// if the sequence does not exist, it will be created.
    /// </summary>
    /// <param name="TableNo">The ID of the table being checked</param>
    procedure AllocateSeqNoBuffer(TableNo: Integer; NoOfEntries: Integer)
    var
        SignedTableNo: Integer;
        PreviewMode: Boolean;
        RemainingNoOfEntries: Integer;
    begin
        if NoOfEntries < 2 then  // no need reserve 1, as it it still one sql call
            exit;
        ValidateSeqNo(TableNo);
        PreviewMode := IsPreviewMode();  // Only call once to minimize sql calls during preview.
        SignedTableNo := PreviewMode ? -TableNo : TableNo;
        if SeqNoBufferFrom.ContainsKey(SignedTableNo) and SeqNoBufferTo.ContainsKey(SignedTableNo) then  // lefterovers from previous allocation?
            RemainingNoOfEntries := SeqNoBufferTo.Get(SignedTableNo) - SeqNoBufferFrom.Get(SignedTableNo);
        if RemainingNoOfEntries >= NoOfEntries then
            exit; // we have enough already    
        if PendingAllocation.ContainsKey(SignedTableNo) then
            PendingAllocation.Set(SignedTableNo, PendingAllocation.Get(SignedTableNo) + NoOfEntries - RemainingNoOfEntries)
        else
            PendingAllocation.Add(SignedTableNo, NoOfEntries - RemainingNoOfEntries);
    end;

    /// <summary>
    /// Returns the next buffered NumberSequence value for a given table ID.
    /// if the sequence does not exist, it will be created.
    /// </summary>
    /// <param name="TableNo">The ID of the table being checked</param>
    procedure GetNextSeqNo(TableNo: Integer): Integer
    var
        NewSeqNo: Integer;
        FromNo: Integer;
        NoOfEntries: Integer;
        SignedTableNo: Integer;
        PreviewMode: Boolean;
    begin
        PreviewMode := IsPreviewMode();  // Only call once to minimize sql calls during preview.

        // First check if we have pre-allocated entry numbers
        SignedTableNo := PreviewMode ? -TableNo : TableNo;  // we use -tableno for index for preview numbers.
        if PendingAllocation.ContainsKey(SignedTableNo) then
            if not SeqNoBufferFrom.ContainsKey(SignedTableNo) or not SeqNoBufferTo.ContainsKey(SignedTableNo) then begin
                NoOfEntries := PendingAllocation.Get(SignedTableNo);
                PendingAllocation.Remove(SignedTableNo);
                ValidateSeqNo(TableNo);
                NewSeqNo := NumberSequence.Range(GetTableSequenceName(SignedTableNo < 0, TableNo), NoOfEntries);
                if SeqNoBufferFrom.ContainsKey(SignedTableNo) then
                    SeqNoBufferFrom.Set(SignedTableNo, NewSeqNo)
                else
                    SeqNoBufferFrom.Add(SignedTableNo, NewSeqNo);
                if SeqNoBufferTo.ContainsKey(SignedTableNo) then
                    SeqNoBufferTo.Set(SignedTableNo, NewSeqNo + NoOfEntries - 1)
                else
                    SeqNoBufferTo.Add(SignedTableNo, NewSeqNo + NoOfEntries - 1);
            end;
        if SeqNoBufferFrom.ContainsKey(SignedTableNo) and SeqNoBufferTo.ContainsKey(SignedTableNo) then begin
            FromNo := SeqNoBufferFrom.Get(SignedTableNo);
            NewSeqNo := FromNo;
            FromNo += 1;
            if FromNo <= SeqNoBufferTo.Get(SignedTableNo) then
                SeqNoBufferFrom.Set(SignedTableNo, FromNo)
            else begin
                if SeqNoBufferFrom.Remove(SignedTableNo) then;
                if SeqNoBufferTo.Remove(SignedTableNo) then;
            end;
            exit(NewSeqNo);
        end;

        // No pre-allocated numbers - get entry no. from sequence
        ValidateSeqNo(TableNo);
        if TryGetNextNo(PreviewMode, TableNo, NewSeqNo) then
            exit(NewSeqNo);
        ClearLastError();
        CreateNewTableSequence(PreviewMode, TableNo);
        TryGetNextNo(PreviewMode, TableNo, NewSeqNo);
        exit(NewSeqNo);
    end;

    /// <summary>
    /// Returns the current NumberSequence value for a given table ID.
    /// if the sequence does not exist, it will be created.
    /// </summary>
    /// <param name="TableNo">The ID of the table being checked</param>
    procedure GetCurrentSeqNo(TableNo: Integer): Integer
    var
        CurrSeqNo: Integer;
        PreviewMode: Boolean;
    begin
        PreviewMode := IsPreviewMode();  // Only call once to minimize sql calls during preview.
        if TryGetCurrentNo(PreviewMode, TableNo, CurrSeqNo) then
            exit(CurrSeqNo);
        ClearLastError();
        CreateNewTableSequence(PreviewMode, TableNo);
        TryGetCurrentNo(PreviewMode, TableNo, CurrSeqNo);
        exit(CurrSeqNo);
    end;

    /// <summary>
    /// Ensures that the NumberSequence is not behind the last entry in the table.
    /// if the sequence does not exist, it will be created.
    /// The result will be cached for the current transaction. The cache can be cleared by calling ClearSequenceNoCheck.
    /// </summary>
    /// <param name="TableNo">The ID of the table being checked</param>
    procedure ValidateSeqNo(TableNo: Integer)
    var
        LastEntryNo: Integer;
    begin
        if IsPreviewMode() then
            exit;
        if LastSeqNoChecked.Contains(TableNo) then
            exit;

        LastEntryNo := GetLastEntryNoFromTable(TableNo, false);
        if GetCurrentSeqNo(TableNo) < LastEntryNo then
            RebaseSeqNo(TableNo);

        LastSeqNoChecked.Add(TableNo);
    end;

    /// <summary>
    /// Clears the cache that is used by procedure ValidateSeqNo(TableNo).
    /// </summary>
    procedure ClearSequenceNoCheck()
    begin
        Clear(LastSeqNoChecked);
    end;

    [TryFunction]
    local procedure TryGetNextNo(PreviewMode: Boolean; TableNo: Integer; var NewSeqNo: Integer)
    begin
        NewSeqNo := NumberSequence.Next(GetTableSequenceName(PreviewMode, TableNo));
    end;

    [TryFunction]
    local procedure TryGetCurrentNo(PreviewMode: Boolean; TableNo: Integer; var CurrSeqNo: Integer)
    begin
        CurrSeqNo := NumberSequence.Current(GetTableSequenceName(PreviewMode, TableNo));
    end;

    /// <summary>
    /// Restarts or recreates the NumberSequence for the specified Table ID.
    /// </summary>
    /// <param name="TableNo">The ID of the table being checked</param>
    procedure RebaseSeqNo(TableNo: Integer)
    begin
        CreateNewTableSequence(IsPreviewMode(), TableNo);
    end;

    local procedure CreateNewTableSequence(PreviewMode: Boolean; TableNo: Integer)
    var
        StartSeqNo: BigInteger;
        IsPreviewable: Boolean;
    begin
        OnPreviewableLedgerEntry(TableNo, IsPreviewable);
        if PreviewMode and IsPreviewable then
            StartSeqNo := -2000000000
        else
            StartSeqNo := GetLastEntryNoFromTable(TableNo, true) + 1;

        CreateSequence(GetTableSequenceName(PreviewMode and IsPreviewable, TableNo), StartSeqNo);

        if PreviewMode or not IsPreviewable then
            exit;

        // Creating/deleting a number sequence is transactional, so we benefit from creating the preview sequence in a non-preview transaction
        CreateSequence(GetTableSequenceName(true, TableNo), -2000000000);
    end;

    local procedure CreateSequence(SequenceName: Text; StartSeqNo: BigInteger)
    begin
        if NumberSequence.Exists(SequenceName) then
            NumberSequence.Restart(SequenceName, StartSeqNo - 1)  // to avoid the issue with current and next being the same for a new sequence.
        else
            NumberSequence.Insert(SequenceName, StartSeqNo - 1, 1, true);  // to avoid the issue with current and next being the same for a new sequence.
        if NumberSequence.Next(SequenceName) = 1 then;  // do.
    end;

    local procedure GetLastEntryNoFromTable(TableNo: Integer; WithLock: Boolean): BigInteger
    var
        [SecurityFiltering(SecurityFilter::Ignored)]
        RecRef: RecordRef;
        FldRef: FieldRef;
        KeyRef: KeyRef;
        LastEntryNo: BigInteger;
    begin
        RecRef.Open(TableNo);
        if WithLock then
            RecRef.ReadIsolation(IsolationLevel::UpdLock)
        else
            RecRef.ReadIsolation(IsolationLevel::ReadUncommitted);
        KeyRef := RecRef.KeyIndex(1);
        RecRef.SetLoadFields(KeyRef.FieldIndex(KeyRef.FieldCount).Number);
        if RecRef.FindLast() then begin
            FldRef := KeyRef.FieldIndex(KeyRef.FieldCount);
            LastEntryNo := FldRef.Value
        end else
            LastEntryNo := 0;
        exit(LastEntryNo);
    end;

    /// <summary>
    /// Returns the name of the NumberSequence for the specified Table ID.
    /// </summary>
    /// <param name="TableNo">The ID of the table being checked</param>
    procedure GetTableSequenceName(TableNo: Integer): Text
    begin
        exit(GetTableSequenceName(IsPreviewMode(), TableNo));
    end;

    /// <summary>
    /// Returns the name of the NumberSequence for the specified Table ID. We have one sequence for preview and one for non-preview.
    /// </summary>
    /// <param name="PreviewMode">Is true for posting preview</param>
    /// <param name="TableNo">The ID of the table being checked</param>
    procedure GetTableSequenceName(PreviewMode: Boolean; TableNo: Integer): Text
    var
        IsPreviewable: Boolean;
    begin
        if PreviewMode then
            OnPreviewableLedgerEntry(TableNo, IsPreviewable);
        if IsPreviewable then
            exit(StrSubstNo(PreviewSeqNameLbl, TableNo));
        exit(StrSubstNo(SeqNameLbl, TableNo));
    end;

    // An error during preview may mean that the PreviewMode variable doesn't get reset after preview, so we need to rely on transactional consistency
    local procedure IsPreviewMode(): Boolean
    var
        SequenceNoPreviewState: Record "Sequence No. Preview State";
    begin
        if not GlobalPreviewMode then
            exit(false);
        if GlobalPreviewModeID <> 0 then
            if SequenceNoPreviewState.Get(GlobalPreviewModeID) then  // double-check
                exit(true);
        GlobalPreviewMode := false;
        GlobalPreviewModeID := 0;
    end;

    internal procedure StartPreviewMode()
    var
        SequenceNoPreviewState: Record "Sequence No. Preview State";
    begin
        if GlobalPreviewMode then // missing cleanup from previous preview?
            StopPreviewMode();
        SequenceNoPreviewState.ID := 0;
        SequenceNoPreviewState.Insert();
        SequenceNoPreviewState.Consistent(false); // make sure we cannot commit the transaction
        GlobalPreviewMode := true;
        GlobalPreviewModeID := SequenceNoPreviewState.ID;
    end;

    internal procedure StopPreviewMode()
    var
        SequenceNoPreviewState: Record "Sequence No. Preview State";
    begin
        GlobalPreviewMode := false;
        if GlobalPreviewModeID <> 0 then
            if SequenceNoPreviewState.Get(GlobalPreviewModeID) then
                SequenceNoPreviewState.Delete();
        GlobalPreviewModeID := 0;
        SequenceNoPreviewState.Consistent(true); // make sure we can commit the transaction
    end;

    internal procedure SetPreviewMode(NewPreviewMode: Boolean)
    begin
        if NewPreviewMode then
            StartPreviewMode()
        else
            StopPreviewMode();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPreviewableLedgerEntry(TableNo: Integer; var IsPreviewable: Boolean)
    begin
    end;
}
