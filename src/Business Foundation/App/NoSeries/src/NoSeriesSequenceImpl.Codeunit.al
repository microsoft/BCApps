// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Foundation.NoSeries;

codeunit 307 "No. Series - Sequence Impl." implements "No. Series - Single"
{
    Access = Internal;
    Permissions = tabledata "No. Series Line" = rimd,
                  tabledata "No. Series" = r;

    procedure PeekNextNo(NoSeriesLine: Record "No. Series Line"; UsageDate: Date): Code[20]
    begin
        exit(GetNextNoInternal(NoSeriesLine, false, UsageDate, false));
    end;

    procedure GetNextNo(NoSeriesLine: Record "No. Series Line"; UsageDate: Date; HideErrorsAndWarnings: Boolean): Code[20]
    begin
        exit(GetNextNoInternal(NoSeriesLine, true, UsageDate, HideErrorsAndWarnings));
    end;

    procedure GetLastNoUsed(NoSeriesLine: Record "No. Series Line"): Code[20]
    var
        LastSeqNoUsed: BigInteger;
    begin
        if not TryGetCurrentSequenceNo(NoSeriesLine, LastSeqNoUsed) then begin
            if not NumberSequence.Exists(NoSeriesLine."Sequence Name") then
                CreateNewSequence(NoSeriesLine);
            TryGetCurrentSequenceNo(NoSeriesLine, LastSeqNoUsed);
        end;
        if LastSeqNoUsed >= NoSeriesLine."Starting Sequence No." then
            exit(GetFormattedNo(NoSeriesLine, LastSeqNoUsed));
        exit(''); // TODO: Recreate the sequence? This means the sequence produced a number less than the starting number.
    end;

    [TryFunction]
    local procedure TryGetCurrentSequenceNo(var NoSeriesLine: Record "No. Series Line"; var LastSeqNoUsed: BigInteger)
    begin
        LastSeqNoUsed := NumberSequence.Current(NoSeriesLine."Sequence Name");
    end;

    local procedure GetNextNoInternal(NoSeriesLine: Record "No. Series Line"; ModifySeries: Boolean; UsageDate: Date; HideErrorsAndWarnings: Boolean): Code[20]
    var
        NoSeriesMgtInternal: Codeunit NoSeriesMgtInternal;
        NewNo: BigInteger;
    begin
        if UsageDate = 0D then
            UsageDate := WorkDate();

        if not TryGetNextSequenceNo(NoSeriesLine, ModifySeries, NewNo) then begin
            if not NumberSequence.Exists(NoSeriesLine."Sequence Name") then
                CreateNewSequence(NoSeriesLine);
            TryGetNextSequenceNo(NoSeriesLine, ModifySeries, NewNo);
        end;

        if not NoSeriesMgtInternal.EnsureLastNoUsedIsWithinValidRange(NoSeriesLine, HideErrorsAndWarnings) then
            exit('');

        if ModifySeries then begin
            NoSeriesLine."Last Date Used" := UsageDate;
            NoSeriesLine.Modify(true); // TODO: Call modify line?
        end;

        exit(GetFormattedNo(NoSeriesLine, NewNo));
    end;

    [TryFunction]
    local procedure TryGetNextSequenceNo(var NoSeriesLine: Record "No. Series Line"; ModifySeries: Boolean; var NewNo: BigInteger)
    begin
        if ModifySeries then begin
            NewNo := NumberSequence.Next(NoSeriesLine."Sequence Name");
            if NewNo < NoSeriesLine."Starting Sequence No." then  // first no. ? // TODO: Recreate the sequence? This means the sequence produced a number less than the starting number.
                NewNo := NumberSequence.Next(NoSeriesLine."Sequence Name");
        end else begin
            NewNo := NumberSequence.Current(NoSeriesLine."Sequence Name"); // TODO: Shouldn't this be PeekNextSequenceNo?
            NewNo += NoSeriesLine."Increment-by No.";
        end;
    end;

    local procedure CreateNewSequence(var NoSeriesLine: Record "No. Series Line")
    var
        DummySeq: BigInteger;
    begin
        if NoSeriesLine."Sequence Name" = '' then
            NoSeriesLine."Sequence Name" := Format(CreateGuid(), 0, 4);

        if NoSeriesLine."Last No. Used" = '' then // TODO: Why do we subtract increment-by no. first but not in second.. second should calculate how far ahead to go?
            NumberSequence.Insert(NoSeriesLine."Sequence Name", NoSeriesLine."Starting Sequence No." - NoSeriesLine."Increment-by No.", NoSeriesLine."Increment-by No.")
        else
            NumberSequence.Insert(NoSeriesLine."Sequence Name", NoSeriesLine."Starting Sequence No.", NoSeriesLine."Increment-by No.");

        if NoSeriesLine."Last No. Used" <> '' then
            // Simulate that a number was used
#pragma warning disable AA0206
            DummySeq := NumberSequence.next(NoSeriesLine."Sequence Name"); // TODO: Why?
#pragma warning restore AA0206
    end;

    local procedure GetFormattedNo(NoSeriesLine: Record "No. Series Line"; Number: BigInteger): Code[20]
    var
        NumberCode: Code[20];
        i: Integer;
        j: Integer;
    begin
        if Number < NoSeriesLine."Starting Sequence No." then
            exit('');
        NumberCode := Format(Number);
        if NoSeriesLine."Starting No." = '' then // TODO: Should starting no. maybe use 'Cust%1Test' instead?
            exit(NumberCode);
        i := StrLen(NoSeriesLine."Starting No.");
        while (i > 1) and not (NoSeriesLine."Starting No."[i] in ['0' .. '9']) do
            i -= 1;
        j := i - StrLen(NumberCode);
        if (j > 0) and (i < MaxStrLen(NoSeriesLine."Starting No.")) then
            exit(CopyStr(NoSeriesLine."Starting No.", 1, j) + NumberCode + CopyStr(NoSeriesLine."Starting No.", i + 1));
        if (j > 0) then
            exit(CopyStr(NoSeriesLine."Starting No.", 1, j) + NumberCode);
        while (i > 1) and (NoSeriesLine."Starting No."[i] in ['0' .. '9']) do
            i -= 1;
        if (i > 0) and (i + StrLen(NumberCode) <= MaxStrLen(NumberCode)) then
            if (i = 1) and (NoSeriesLine."Starting No."[i] in ['0' .. '9']) then
                exit(NumberCode)
            else
                exit(CopyStr(NoSeriesLine."Starting No.", 1, i) + NumberCode);
        exit(NumberCode); // should ideally not be possible, as bigints can produce max 18 digits
    end;
}