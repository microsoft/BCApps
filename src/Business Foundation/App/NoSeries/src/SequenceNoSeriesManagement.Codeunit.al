// remove

// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Foundation.NoSeries;

codeunit 284 SequenceNoSeriesManagement implements "No. Series - Single"
{
    Permissions = tabledata "No. Series Line" = rimd,
                  tabledata "No. Series" = r;

    var
        NoOverFlowErr: Label 'Number series can only use up to 18 digit numbers. %1 has %2 digits.', Comment = '%1 is a string that also contains digits. %2 is a number.';

    procedure PeekNextNo(NoSeriesLine: Record "No. Series Line"): Code[20];
    begin
        exit(GetNextSequenceNo(NoSeriesLine, false, WorkDate()));
    end;

    procedure GetNextNo(NoSeriesLine: Record "No. Series Line"; UsageDate: Date): Code[20];
    begin
        exit(GetNextSequenceNo(NoSeriesLine, true, UsageDate));
    end;

    local procedure GetLastNoUsedLocal(NoSeriesLine: Record "No. Series Line"): Code[20];
    begin
        if not NoSeriesLine."Allow Gaps in Nos." or (NoSeriesLine."Sequence Name" = '') then
            exit(NoSeriesLine."Last No. Used");

        exit(GetLastNoUsed(NoSeriesLine));
    end;

    procedure GetLastNoUsed(NoSeriesLine: Record "No. Series Line"): Code[20]
    var
        LastSeqNoUsed: BigInteger;
    begin
        VerifyNoSeriesUsesSequenceNumbers(NoSeriesLine);

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
    internal procedure TryGetCurrentSequenceNo(var NoSeriesLine: Record "No. Series Line"; var LastSeqNoUsed: BigInteger)
    begin
        LastSeqNoUsed := NumberSequence.Current(NoSeriesLine."Sequence Name");
    end;

    local procedure GetNextSequenceNo(NoSeriesLine: Record "No. Series Line"; ModifySeries: Boolean; UsageDate: Date): Code[20]
    var
        // NoSeriesMgtInternal: Codeunit NoSeriesMgtInternal;
        // NoSeriesManagement: Codeunit NoSeriesManagement;
        NewNo: BigInteger;
    begin
        VerifyNoSeriesUsesSequenceNumbers(NoSeriesLine);

        if not TryGetNextSequenceNo(NoSeriesLine, ModifySeries, NewNo) then begin
            if not NumberSequence.Exists(NoSeriesLine."Sequence Name") then
                CreateNewSequence(NoSeriesLine);
            TryGetNextSequenceNo(NoSeriesLine, ModifySeries, NewNo);
        end;

        if ModifySeries then begin
            NoSeriesLine."Last Date Used" := UsageDate;
            NoSeriesLine.Modify(true); // TODO: Call modify line?
        end;
        /*NoSeriesMgtInternal.EnsureLastNoUsedIsWithinValidRange(NoSeriesLine, false);

        if ModifySeries and NoSeriesLine.Open then
            ModifyNoSeriesLine(NoSeriesLine);*/

        // NoSeriesManagement.OnAfterGetNextNo3(NoSeriesLine, ModifySeries);

        exit(GetFormattedNo(NoSeriesLine, NewNo));
    end;

    /*local procedure ModifyNoSeriesLine(var NoSeriesLine: Record "No. Series Line") // TODO: Move
    var
        NoSeriesManagement: Codeunit NoSeriesManagement;
        IsHandled: Boolean;
        LastNoUsed: Code[20];
    begin
        IsHandled := false;
        NoSeriesManagement.OnBeforeModifyNoSeriesLine(NoSeriesLine, IsHandled);
        if IsHandled then
            exit;
        NoSeriesLine.Validate(Open);
        LastNoUsed := NoSeriesLine."Last No. Used";
        if NoSeriesLine."Allow Gaps in Nos." then
            NoSeriesLine."Last No. Used" := '';
        NoSeriesLine.Modify();
        NoSeriesLine."Last No. Used" := LastNoUsed;
    end;*/

    local procedure VerifyNoSeriesUsesSequenceNumbers(NoSeriesLine: Record "No. Series Line")
    begin
        NoSeriesLine.TestField("Allow Gaps in Nos.");
        NoSeriesLine.TestField("Sequence Name");

        // TODO: send a nice error message
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

    internal procedure UpdateStartingSequenceNo(var NoSeriesLine: Record "No. Series Line")
    begin
        if not NoSeriesLine."Allow Gaps in Nos." then
            exit; // TODO: remove with interface

        if NoSeriesLine."Last No. Used" = '' then
            NoSeriesLine."Starting Sequence No." := ExtractNoFromCode(NoSeriesLine."Starting No.") // TODO: Initialize from old no. series? Should this happen here, owned by this interface?
        else
            NoSeriesLine."Starting Sequence No." := ExtractNoFromCode(NoSeriesLine."Last No. Used");
    end;

    internal procedure CreateNewSequence(var NoSeriesLine: Record "No. Series Line")
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

    internal procedure RecreateSequence(var NoSeriesLine: Record "No. Series Line")
    begin
        if NoSeriesLine."Last No. Used" = '' then
            NoSeriesLine."Last No. Used" := GetLastNoUsedLocal(NoSeriesLine);
        DeleteSequence(NoSeriesLine);
        UpdateStartingSequenceNo(NoSeriesLine);
        CreateNewSequence(NoSeriesLine);
        NoSeriesLine."Last No. Used" := '';
    end;

    internal procedure DeleteSequence(var NoSeriesLine: Record "No. Series Line")
    begin
        if NoSeriesLine."Sequence Name" = '' then
            exit;
        if NumberSequence.Exists(NoSeriesLine."Sequence Name") then
            NumberSequence.Delete(NoSeriesLine."Sequence Name");
    end;

    internal procedure ExtractNoFromCode(NumberCode: Code[20]): BigInteger
    var
        i: Integer;
        j: Integer;
        Number: BigInteger;
        NoCodeSnip: Code[20];
    begin
        if NumberCode = '' then
            exit(0);
        i := StrLen(NumberCode);
        while (i > 1) and not (NumberCode[i] in ['0' .. '9']) do
            i -= 1;
        if i = 1 then begin
            if Evaluate(Number, Format(NumberCode[1])) then
                exit(Number);
            exit(0);
        end;
        j := i;
        while (i > 1) and (NumberCode[i] in ['0' .. '9']) do
            i -= 1;
        if (i = 1) and (NumberCode[i] in ['0' .. '9']) then
            i -= 1;
        NoCodeSnip := CopyStr(CopyStr(NumberCode, i + 1, j - i), 1, MaxStrLen(NoCodeSnip));
        if StrLen(NoCodeSnip) > 18 then
            Error(NoOverFlowErr, NumberCode, StrLen(NoCodeSnip));
        Evaluate(Number, NoCodeSnip);
        exit(Number);
    end;

    internal procedure GetFormattedNo(NoSeriesLine: Record "No. Series Line"; Number: BigInteger): Code[20]
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
