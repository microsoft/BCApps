// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Foundation.NoSeries;

codeunit 306 "No. Series - Stateless Impl." implements "No. Series - Single"
{
    Access = Internal;
    Permissions = tabledata "No. Series Line" = rimd,
                  tabledata "No. Series" = r;

    var
        NumberLengthErr: Label 'The number %1 cannot be extended to more than 20 characters.', comment = '%1=No.';

    procedure PeekNextNo(NoSeriesLine: Record "No. Series Line"; UsageDate: Date): Code[20]
    begin
        exit(GetNextNoInternal(NoSeriesLine, false, UsageDate, false));
    end;

    procedure GetNextNo(NoSeriesLine: Record "No. Series Line"; UsageDate: Date; HideErrorsAndWarnings: Boolean): Code[20]
    begin
        exit(GetNextNoInternal(NoSeriesLine, true, UsageDate, HideErrorsAndWarnings));
    end;

    local procedure GetNextNoInternal(NoSeriesLine: Record "No. Series Line"; ModifySeries: Boolean; UsageDate: Date; HideErrorsAndWarnings: Boolean): Code[20]
    var
        NoSeriesMgtInternal: Codeunit NoSeriesMgtInternal;
    begin
        if UsageDate = 0D then
            UsageDate := WorkDate();
        if NoSeriesLine."Last No. Used" = '' then begin
            if HideErrorsAndWarnings and (NoSeriesLine."Starting No." = '') then
                exit('');
            NoSeriesLine.TestField("Starting No.");
            NoSeriesLine."Last No. Used" := NoSeriesLine."Starting No.";
        end else
            if NoSeriesLine."Increment-by No." <= 1 then
                NoSeriesLine."Last No. Used" := IncStr(NoSeriesLine."Last No. Used")
            else
                IncrementNoText(NoSeriesLine."Last No. Used", NoSeriesLine."Increment-by No.");

        if not NoSeriesMgtInternal.EnsureLastNoUsedIsWithinValidRange(NoSeriesLine, HideErrorsAndWarnings) then
            exit('');

        if ModifySeries then begin
            NoSeriesLine."Last Date Used" := UsageDate;
            NoSeriesLine.Validate(Open);
            NoSeriesLine.Modify();
        end;

        exit(NoSeriesLine."Last No. Used");
    end;

    procedure GetLastNoUsed(NoSeriesLine: Record "No. Series Line"): Code[20]
    begin
        exit(NoSeriesLine."Last No. Used");
    end;

    local procedure IncrementNoText(var No: Code[20]; IncrementByNo: Decimal)
    var
        BigIntNo: BigInteger;
        BigIntIncByNo: BigInteger;
        StartPos: Integer;
        EndPos: Integer;
        NewNo: Code[20];
    begin
        GetIntegerPos(No, StartPos, EndPos);
        Evaluate(BigIntNo, CopyStr(No, StartPos, EndPos - StartPos + 1));
        BigIntIncByNo := IncrementByNo;
        NewNo := CopyStr(Format(BigIntNo + BigIntIncByNo, 0, 1), 1, MaxStrLen(NewNo));
        ReplaceNoText(No, NewNo, 0, StartPos, EndPos);
    end;

    local procedure GetIntegerPos(No: Code[20]; var StartPos: Integer; var EndPos: Integer)
    var
        IsDigit: Boolean;
        i: Integer;
    begin
        StartPos := 0;
        EndPos := 0;
        if No <> '' then begin
            i := StrLen(No);
            repeat
                IsDigit := No[i] in ['0' .. '9'];
                if IsDigit then begin
                    if EndPos = 0 then
                        EndPos := i;
                    StartPos := i;
                end;
                i := i - 1;
            until (i = 0) or (StartPos <> 0) and not IsDigit;
        end;
    end;

    local procedure ReplaceNoText(var No: Code[20]; NewNo: Code[20]; FixedLength: Integer; StartPos: Integer; EndPos: Integer)
    var
        StartNo: Code[20];
        EndNo: Code[20];
        ZeroNo: Code[20];
        NewLength: Integer;
        OldLength: Integer;
    begin
        if StartPos > 1 then
            StartNo := CopyStr(CopyStr(No, 1, StartPos - 1), 1, MaxStrLen(StartNo));
        if EndPos < StrLen(No) then
            EndNo := CopyStr(CopyStr(No, EndPos + 1), 1, MaxStrLen(EndNo));
        NewLength := StrLen(NewNo);
        OldLength := EndPos - StartPos + 1;
        if FixedLength > OldLength then
            OldLength := FixedLength;
        if OldLength > NewLength then
            ZeroNo := CopyStr(PadStr('', OldLength - NewLength, '0'), 1, MaxStrLen(ZeroNo));
        if StrLen(StartNo) + StrLen(ZeroNo) + StrLen(NewNo) + StrLen(EndNo) > 20 then
            Error(NumberLengthErr, No);
        No := CopyStr(StartNo + ZeroNo + NewNo + EndNo, 1, MaxStrLen(No));
    end;
}