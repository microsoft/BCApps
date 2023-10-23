// remove

// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Foundation.NoSeries;

codeunit 281 NoSeriesMgt
{
    Access = Public; // public due to events
    Permissions = tabledata "No. Series Line" = rimd,
                  tabledata "No. Series" = r;

    var
        CantChangeNoSeriesLineTypeErr: Label 'No. Series Lines must be deleted before changing the %1', Comment = '%1 = No. Series Type';
        NumberLengthErr: Label 'The number %1 cannot be extended to more than 20 characters.', comment = '%1=No.';
        NumberFormatErr: Label 'The number format in %1 must be the same as the number format in %2.', Comment = '%1=No. Series Code,%2=No. Series Code';
        UnincrementableStringErr: Label 'The value in the %1 field must have a number so that we can assign the next number in the series.', Comment = '%1 = New Field Name';
        NoOverFlowErr: Label 'Number series can only use up to 18 digit numbers. %1 has %2 digits.', Comment = '%1 is a string that also contains digits. %2 is a number.';

    internal procedure UpdateNoSeriesLine(var NoSeriesLine: Record "No. Series Line"; NewNo: Code[20]; NewFieldName: Text[100])
    var
        NoSeriesLine2: Record "No. Series Line";
        Length: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateNoSeriesLine(NoSeriesLine, NewNo, NewFieldName, IsHandled);
        if IsHandled then
            exit;

        if NewNo <> '' then begin
            if IncStr(NewNo) = '' then
                Error(UnincrementableStringErr, NewFieldName);
            NoSeriesLine2 := NoSeriesLine;
            if NewNo = GetNoText(NewNo) then
                Length := 0
            else begin
                Length := StrLen(GetNoText(NewNo));
                UpdateLength(NoSeriesLine."Starting No.", Length);
                UpdateLength(NoSeriesLine."Ending No.", Length);
                UpdateLength(NoSeriesLine."Last No. Used", Length);
                UpdateLength(NoSeriesLine."Warning No.", Length);
            end;
            UpdateNo(NoSeriesLine."Starting No.", NewNo, Length);
            UpdateNo(NoSeriesLine."Ending No.", NewNo, Length);
            UpdateNo(NoSeriesLine."Last No. Used", NewNo, Length);
            UpdateNo(NoSeriesLine."Warning No.", NewNo, Length);
            if (NewFieldName <> NoSeriesLine.FieldCaption("Last No. Used")) and
               (NoSeriesLine."Last No. Used" <> NoSeriesLine2."Last No. Used")
            then
                Error(
                  NumberFormatErr,
                  NewFieldName, NoSeriesLine.FieldCaption("Last No. Used"));
        end;
    end;

    // moved from other objects
    internal procedure DrillDown(var NoSeries: Record "No. Series")
    var
        NoSeriesLine: Record "No. Series Line";
    begin
        case NoSeries."No. Series Type" of
            NoSeries."No. Series Type"::Normal:
                begin
                    FindNoSeriesLineToShow(NoSeries, NoSeriesLine);
                    if NoSeriesLine.Find('-') then;
                    NoSeriesLine.SetRange("Starting Date");
                    NoSeriesLine.SetRange(Open);
                    PAGE.RunModal(0, NoSeriesLine);
                end;
            else
                OnAfterNoSeriesDrillDown(NoSeries);
        end;
    end;

    // FindNoSeriesLineToShow is used from baseapp test
    procedure FindNoSeriesLineToShow(var NoSeries: Record "No. Series"; var NoSeriesLine: Record "No. Series Line")
    begin
        SetNoSeriesLineFilter(NoSeriesLine, NoSeries.Code, 0D);

        if NoSeriesLine.FindLast() then
            exit;

        NoSeriesLine.Reset();
        NoSeriesLine.SetRange("Series Code", NoSeries.Code);
    end;

    procedure SetNoSeriesLineFilter(var NoSeriesLine: Record "No. Series Line"; NoSeriesCode: Code[20]; StartDate: Date)
#if not CLEAN24
#pragma warning disable AL0432
    var
        NoSeriesManagement: Codeunit NoSeriesManagement;
#pragma warning restore AL0432
#endif
    begin
        if StartDate = 0D then
            StartDate := WorkDate();

        NoSeriesLine.Reset();
        NoSeriesLine.SetCurrentKey("Series Code", "Starting Date");
        NoSeriesLine.SetRange("Series Code", NoSeriesCode);
        NoSeriesLine.SetRange("Starting Date", 0D, StartDate);
#if not CLEAN24
#pragma warning disable AL0432
        NoSeriesManagement.RaiseObsoleteOnNoSeriesLineFilterOnBeforeFindLast(NoSeriesLine);
#pragma warning restore AL0432
#endif
        if NoSeriesLine.FindLast() then begin
            NoSeriesLine.SetRange("Starting Date", NoSeriesLine."Starting Date");
            NoSeriesLine.SetRange(Open, true);
        end;
    end;


    internal procedure UpdateLine(var NoSeries: Record "No. Series"; var StartDate: Date; var StartNo: Code[20]; var EndNo: Code[20]; var LastNoUsed: Code[20]; var WarningNo: Code[20]; var IncrementByNo: Integer; var LastDateUsed: Date; var AllowGaps: Boolean)
    var
        NoSeriesLine: Record "No. Series Line";
    begin
        case NoSeries."No. Series Type" of
            NoSeries."No. Series Type"::Normal:
                begin
                    FindNoSeriesLineToShow(NoSeries, NoSeriesLine);
                    if not NoSeriesLine.Find('-') then
                        NoSeriesLine.Init();
                    StartDate := NoSeriesLine."Starting Date";
                    StartNo := NoSeriesLine."Starting No.";
                    EndNo := NoSeriesLine."Ending No.";
                    LastNoUsed := GetLastNoUsed(NoSeriesLine);
                    WarningNo := NoSeriesLine."Warning No.";
                    IncrementByNo := NoSeriesLine."Increment-by No.";
                    LastDateUsed := NoSeriesLine."Last Date Used";
                    AllowGaps := NoSeriesLine."Allow Gaps in Nos.";
                end;
            else
                OnNoSeriesUpdateLine(NoSeries, StartDate, StartNo, EndNo, LastNoUsed, WarningNo, IncrementByNo, LastDateUsed, AllowGaps)
        end;
    end;

    internal procedure GetLastNoUsed(NoSeriesLine: Record "No. Series Line"): Code[20] // TODO: Forward to "No. Series".GetLastNoUsed
    var
        NoSeries: Codeunit "No. Series";
    begin
        exit(NoSeries.GetLastNoUsed(NoSeriesLine."Series Code"));
    end;

    internal procedure ShowNoSeriesLines(var NoSeries: Record "No. Series")
    var
        NoSeriesLine: Record "No. Series Line";
    begin
        case NoSeries."No. Series Type" of
            NoSeries."No. Series Type"::Normal:
                begin
                    NoSeriesLine.Reset();
                    NoSeriesLine.SetRange("Series Code", NoSeries.Code);
                    PAGE.RunModal(PAGE::"No. Series Lines", NoSeriesLine);
                end;
            else
                OnShowNoSeriesLines(NoSeries)
        end;
    end;

    internal procedure SetAllowGaps(var NoSeries: Record "No. Series"; AllowGaps: Boolean)
    var
        NoSeriesLine: Record "No. Series Line";
        StartDate: Date;
    begin
        FindNoSeriesLineToShow(NoSeries, NoSeriesLine);
        StartDate := NoSeriesLine."Starting Date";
        NoSeriesLine.SetRange("Allow Gaps in Nos.", not AllowGaps);
        NoSeriesLine.SetFilter("Starting Date", '>=%1', StartDate);
        NoSeriesLine.LockTable();
        if NoSeriesLine.FindSet() then
            repeat
                NoSeriesLine.Validate("Allow Gaps in Nos.", AllowGaps);
                NoSeriesLine.Modify();
            until NoSeriesLine.Next() = 0;
    end;

    // TODO get rid of handled events
    internal procedure ValidateDefaultNos(var NoSeries: Record "No. Series"; xRecNoSeries: Record "No. Series")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
#if not CLEAN24        
#pragma warning disable AL0432
        NoSeries.OnBeforeValidateDefaultNos(NoSeries, IsHandled);
#pragma warning restore AL0432
#endif
        OnBeforeValidateDefaultNos(NoSeries, IsHandled);
        if not IsHandled then
            if (NoSeries."Default Nos." = false) and (xRecNoSeries."Default Nos." <> NoSeries."Default Nos.") and (NoSeries."Manual Nos." = false) then
                NoSeries.Validate("Manual Nos.", true);
    end;

    internal procedure ValidateManualNos(var NoSeries: Record "No. Series"; xRecNoSeries: Record "No. Series")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
#if not CLEAN24
#pragma warning disable AL0432
        NoSeries.OnBeforeValidateManualNos(NoSeries, IsHandled);
#pragma warning restore AL0432
#endif
        OnBeforeValidateManualNos(NoSeries, IsHandled);
        if not IsHandled then
            if (NoSeries."Manual Nos." = false) and (xRecNoSeries."Manual Nos." <> NoSeries."Manual Nos.") and (NoSeries."Default Nos." = false) then
                NoSeries.Validate("Default Nos.", true);
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

    internal procedure UpdateStartingSequenceNo(var NoSeriesLine: Record "No. Series Line")
    begin
        if not NoSeriesLine."Allow Gaps in Nos." then
            exit; // TODO: remove with interface

        if NoSeriesLine."Last No. Used" = '' then
            NoSeriesLine."Starting Sequence No." := ExtractNoFromCode(NoSeriesLine."Starting No.") // TODO: Initialize from old no. series? Should this happen here, owned by this interface?
        else
            NoSeriesLine."Starting Sequence No." := ExtractNoFromCode(NoSeriesLine."Last No. Used");
    end;

    internal procedure RecreateSequence(var NoSeriesLine: Record "No. Series Line")
    begin
        if NoSeriesLine."Last No. Used" = '' then
            NoSeriesLine."Last No. Used" := GetLastNoUsed(NoSeriesLine);
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

    internal procedure ValidateNoSeriesType(var NoSeries: Record "No. Series"; xRecNoSeries: Record "No. Series")
    var
        NoSeriesLine: Record "No. Series Line";
        RecordsFound: Boolean;
    begin
        if NoSeries."No. Series Type" = xRecNoSeries."No. Series Type" then
            exit;

        case xRecNoSeries."No. Series Type" of
            NoSeries."No. Series Type"::Normal:
                begin
                    NoSeriesLine.SetRange("Series Code", NoSeries.Code);
                    RecordsFound := not NoSeriesLine.IsEmpty();
                end;
        end;

        if not RecordsFound then
            exit;

        Error(CantChangeNoSeriesLineTypeErr, NoSeries.FieldCaption("No. Series Type"));
    end;

    internal procedure DeleteNoSeries(var NoSeries: Record "No. Series")
    var
        NoSeriesLine: Record "No. Series Line";
        NoSeriesRelationship: Record "No. Series Relationship";
#if not CLEAN24
#pragma warning disable AL0432
        NoSeriesLineSales: Record "No. Series Line Sales";
        NoSeriesLinePurchase: Record "No. Series Line Purchase";
#pragma warning restore AL0432  
#endif
    begin
        NoSeriesLine.SetRange("Series Code", NoSeries.Code);
        NoSeriesLine.DeleteAll();

#if not CLEAN24
#pragma warning disable AL0432
        NoSeriesLineSales.SetRange("Series Code", NoSeries.Code);
        NoSeriesLineSales.DeleteAll();

        NoSeriesLinePurchase.SetRange("Series Code", NoSeries.Code);
        NoSeriesLinePurchase.DeleteAll();
#pragma warning restore AL0432
#endif

        NoSeriesRelationship.SetRange(Code, NoSeries.Code);
        NoSeriesRelationship.DeleteAll();
        NoSeriesRelationship.SetRange(Code);

        NoSeriesRelationship.SetRange("Series Code", NoSeries.Code);
        NoSeriesRelationship.DeleteAll();
        NoSeriesRelationship.SetRange("Series Code");
    end;

    /*procedure FindNoSeriesLineToShow(var NoSeries: Record "No. Series"; var NoSeriesLine: Record "No. Series Line")
    var
        NoSeriesManagement: Codeunit NoSeriesManagement;
    begin
        NoSeriesManagement.SetNoSeriesLineFilter(NoSeriesLine, NoSeries.Code, 0D);

        if NoSeriesLine.FindLast() then
            exit;

        NoSeriesLine.Reset();
        NoSeriesLine.SetRange("Series Code", NoSeries.Code);
    end;*/

    local procedure GetNoText(No: Code[20]): Code[20]
    var
        StartPos: Integer;
        EndPos: Integer;
    begin
        GetIntegerPos(No, StartPos, EndPos);
        if StartPos <> 0 then
            exit(CopyStr(CopyStr(No, StartPos, EndPos - StartPos + 1), 1, 20));
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

    local procedure UpdateLength(No: Code[20]; var MaxLength: Integer)
    var
        Length: Integer;
    begin
        if No <> '' then begin
            Length := StrLen(DelChr(GetNoText(No), '<', '0'));
            if Length > MaxLength then
                MaxLength := Length;
        end;
    end;

    local procedure UpdateNo(var No: Code[20]; NewNo: Code[20]; Length: Integer)
    var
        StartPos: Integer;
        EndPos: Integer;
        TempNo: Code[20];
    begin
        if No <> '' then
            if Length <> 0 then begin
                No := DelChr(GetNoText(No), '<', '0');
                TempNo := No;
                No := NewNo;
                NewNo := TempNo;
                GetIntegerPos(No, StartPos, EndPos);
                ReplaceNoText(No, NewNo, Length, StartPos, EndPos);
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

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateNoSeriesLine(var NoSeriesLine: Record "No. Series Line"; NewNo: Code[20]; NewFieldName: Text[100]; var IsHandled: Boolean)
    begin
    end;

    [EventSubscriber(ObjectType::Table, Database::"No. Series Line", 'OnAfterDeleteEvent', '', false, false)]
    local procedure OnDeleteNoSeriesLine(var Rec: Record "No. Series Line"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary() then
            exit;

        if Rec."Sequence Name" <> '' then
            if NUMBERSEQUENCE.Exists(Rec."Sequence Name") then
                NUMBERSEQUENCE.Delete(Rec."Sequence Name");
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateManualNos(var NoSeries: Record "No. Series"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateDefaultNos(var NoSeries: Record "No. Series"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterNoSeriesDrillDown(var NoSeries: Record "No. Series")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnNoSeriesUpdateLine(var NoSeries: Record "No. Series"; var StartDate: Date; var StartNo: Code[20]; var EndNo: Code[20]; var LastNoUsed: Code[20]; var WarningNo: Code[20]; var IncrementByNo: Integer; var LastDateUsed: Date; var AllowGaps: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnShowNoSeriesLines(var NoSeries: Record "No. Series")
    begin
    end;

#if not CLEAN24
#pragma warning disable AL0432
    [Obsolete('The No. Series module cannot have a dependency on Sales. Please use XXX instead', '24.0')] // TODO: Fill out XXX
    [Scope('OnPrem')]
    internal procedure SetNoSeriesLineSalesFilter(var NoSeriesLineSales: Record "No. Series Line Sales"; NoSeriesCode: Code[20]; StartDate: Date)
    begin
        OnObsoleteSetNoSeriesLineSalesFilter(NoSeriesLineSales, NoSeriesCode, StartDate);
    end;

    [Obsolete('The No. Series module cannot have a dependency on Purchases. Please use XXX instead', '24.0')]
    [Scope('OnPrem')]
    internal procedure SetNoSeriesLinePurchaseFilter(var NoSeriesLinePurchase: Record "No. Series Line Purchase"; NoSeriesCode: Code[20]; StartDate: Date)
    begin
        OnObsoleteSetNoSeriesLinePurchaseFilter(NoSeriesLinePurchase, NoSeriesCode, StartDate);
    end;

    [Obsolete('The No. Series module cannot have a dependency on Sales. Do not use this event.', '24.0')]
    [IntegrationEvent(false, false)]
    local procedure OnObsoleteSetNoSeriesLineSalesFilter(var NoSeriesLineSales: Record "No. Series Line Sales"; NoSeriesCode: Code[20]; StartDate: Date)
    begin
    end;

    [Obsolete('The No. Series module cannot have a dependency on Purchase. Do not use this event.', '24.0')]
    [IntegrationEvent(false, false)]
    local procedure OnObsoleteSetNoSeriesLinePurchaseFilter(var NoSeriesLinePurchase: Record "No. Series Line Purchase"; NoSeriesCode: Code[20]; StartDate: Date)
    begin
    end;
#pragma warning restore AL0432
#endif
}