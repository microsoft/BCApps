// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Foundation.NoSeries;

codeunit 304 "No. Series - Impl."
{
    Access = Internal;
    permissions = tabledata "No. Series Line" = rm;
    InherentPermissions = X;
    InherentEntitlements = X;

    var
        CannotAssignNewOnDateErr: Label 'You cannot assign new numbers from the number series %1 on %2.', Comment = '%1=No. Series Code,%2=Date';
        CannotAssignNewErr: Label 'You cannot assign new numbers from the number series %1.', Comment = '%1=No. Series Code';
        CannotAssignNewBeforeDateErr: Label 'You cannot assign new numbers from the number series %1 on a date before %2.', Comment = '%1=No. Series Code,%2=Date';
        NumberLengthErr: Label 'The number %1 cannot be extended to more than 20 characters.', comment = '%1=No.';


    procedure PeekNextNo(NoSeriesCode: Code[20]; UsageDate: Date): Code[20]
    var
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
    begin
        GetNoSeriesLine(NoSeriesLine, NoSeries, UsageDate, false);
        exit(PeekNextNo(NoSeriesLine));
    end;

    procedure PeekNextNo(var NoSeriesLine: Record "No. Series Line") NextNo: Code[20]
    begin
        // init interface
        // call impl. 

        // impl.temp fix
        if NoSeriesLine."Last No. Used" = '' then begin
            NoSeriesLine.TestField("Starting No.");
            exit(NoSeriesLine."Starting No.")
        end else
            NextNo := NoSeriesLine."Last No. Used";

        if NoSeriesLine."Increment-by No." <= 1 then
            exit(IncStr(NextNo));

        IncrementNoText(NextNo, NoSeriesLine."Increment-by No.");
        exit(NextNo);
    end;


    [InherentPermissions(PermissionObjectType::TableData, Database::"No. Series Line", 'rm', InherentPermissionsScope::Both)]
    procedure GetNextNo(var NoSeriesLine: Record "No. Series Line"; LastDateUsed: Date): Code[20]
    begin
        // init interface
        // call impl. 

        // impl.temp fix
        NoSeriesLine."Last No. Used" := PeekNextNo(NoSeriesLine);
        NoSeriesLine."Last Date Used" := LastDateUsed;
        NoSeriesLine.Modify(true);
        exit(NoSeriesLine."Last No. Used");
    end;

    procedure GetNextNo(NoSeriesCode: code[20]; UsageDate: Date): Code[20]
    begin
        exit(GetNextNo(NoSeriesCode, UsageDate, false))
    end;

    procedure GetNextNo(NoSeriesCode: code[20]; UsageDate: Date; HideErrorsAndWarnings: Boolean): Code[20]
    var
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
    begin
        NoSeries.Get(NoSeriesCode);
        if GetNoSeriesLine(NoSeriesLine, NoSeries, UsageDate, HideErrorsAndWarnings) then
            exit(GetNextNo(NoSeriesLine, UsageDate));
    end;

    procedure GetNoSeriesLine(var NoSeriesLine: Record "No. Series Line"; NoSeries: Record "No. Series"): Boolean
    begin
        exit(FindNoSeriesLineWithCheck(NoSeriesLine, NoSeries, WorkDate()));
    end;

    procedure GetNoSeriesLine(var NoSeriesLine: Record "No. Series Line"; NoSeries: Record "No. Series"; UsageDate: Date): Boolean
    begin
        exit(FindNoSeriesLineWithCheck(NoSeriesLine, NoSeries, UsageDate));
    end;

    procedure GetNoSeriesLine(var NoSeriesLine: Record "No. Series Line"; NoSeries: Record "No. Series"; UsageDate: Date; HideErrorsAndWarnings: Boolean): Boolean
    begin
        if HideErrorsAndWarnings then
            exit(FindNoSeriesLine(NoSeriesLine, NoSeries.Code, UsageDate));
        //else
        exit(FindNoSeriesLineWithCheck(NoSeriesLine, NoSeries, UsageDate));
    end;

    procedure FindNoSeriesLineWithCheck(var NoSeriesLine: Record "No. Series Line"; NoSeries: Record "No. Series"; UsageDate: Date): Boolean
    begin
        if not FindNoSeriesLine(NoSeriesLine, NoSeries.Code, UsageDate) then
            GetFindNoSeriesLineError(NoSeriesLine, NoSeries, UsageDate);

        CheckDateOrder(NoSeriesLine, NoSeries, UsageDate);
        exit(true)
    end;

    local procedure FindNoSeriesLine(var NoSeriesLine: Record "No. Series Line"; NoSeriesCode: Code[20]; UsageDate: Date): Boolean
    begin
        NoSeriesLine.SetCurrentKey("Series Code", "Starting Date");
        NoSeriesLine.SetRange("Series Code", NoSeriesCode);
        NoSeriesLine.SetRange("Starting Date", 0D, UsageDate);
        NoSeriesLine.SetRange(Open, true);
        exit(NoSeriesLine.FindLast())
    end;

    local procedure CheckDateOrder(var NoSeriesLine: Record "No. Series Line"; NoSeries: Record "No. Series"; UsageDate: Date)
    begin
        if NoSeries."Date Order" and (UsageDate < NoSeriesLine."Last Date Used") then
            Error(
                CannotAssignNewBeforeDateErr,
                NoSeries.Code, NoSeriesLine."Last Date Used");
    end;

    local procedure GetFindNoSeriesLineError(var NoSeriesLine: Record "No. Series Line"; NoSeries: Record "No. Series"; UsageDate: Date)
    begin
        NoSeriesLine.SetRange("Starting Date");
        NoSeriesLine.SetRange(Open);
        if not NoSeriesLine.IsEmpty() then
            Error(
              CannotAssignNewOnDateErr,
              NoSeries.Code, UsageDate);
        Error(
            CannotAssignNewErr,
            NoSeries.Code);
    end;

    procedure GetLastNoUsed(var NoSeriesLine: Record "No. Series Line"): Code[20] // TODO: Change to NoSeriesCode?
    begin
    end;

    /// <summary>
    /// Verifies that the number series is set to manual.
    /// This function allows manual numbers for blank No. Series Codes.
    /// </summary>
    /// <param name="NoSeriesCode"></param>
    procedure TestManual(NoSeriesCode: Code[20])
    begin

    end;

    procedure AreNoSeriesRelated(DefaultNoSeriesCode: Code[20]; RelatedNoSeriesCode: Code[20]): Boolean
    begin

    end;

    procedure SelectRelatedNoSeries(OriginalNoSeriesCode: Code[20]; var NewNoSeriesCode: Code[20]): Boolean
    begin
        NewNoSeriesCode := 'dummy';
    end;

    // temp: see if we can get rid of this code... 
    procedure IncrementNoText(var No: Code[20]; IncrementByNo: Decimal)
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