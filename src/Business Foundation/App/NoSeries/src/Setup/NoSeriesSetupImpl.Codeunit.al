// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Foundation.NoSeries;

codeunit 305 "No. Series - Setup Impl."
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        NumberFormatErr: Label 'The number format in %1 must be the same as the number format in %2.', Comment = '%1=No. Series Code,%2=No. Series Code';
        UnIncrementableStringErr: Label 'The value in the %1 field must have a number so that we can assign the next number in the series.', Comment = '%1 = New Field Name';
        NumberLengthErr: Label 'The number %1 cannot be extended to more than 20 characters.', Comment = '%1=No.';

    procedure SetImplementation(var NoSeries: Record "No. Series"; Implementation: Enum "No. Series Implementation")
    var
        NoSeriesLine: Record "No. Series Line";
    begin
        NoSeriesLine.SetRange("Series Code", NoSeries.Code);
        NoSeriesLine.SetRange(Open, true);
        NoSeriesLine.ModifyAll(Implementation, Implementation, true);
    end;

    procedure DrillDown(var NoSeries: Record "No. Series")
    var
        NoSeriesLine: Record "No. Series Line";
    begin
        SetNoSeriesCurrentLineFilters(NoSeries, NoSeriesLine, true);
        Page.RunModal(0, NoSeriesLine);
    end;

    procedure UpdateLine(var NoSeriesRec: Record "No. Series"; var StartDate: Date; var StartNo: Code[20]; var EndNo: Code[20]; var LastNoUsed: Code[20]; var WarningNo: Code[20]; var IncrementByNo: Integer; var LastDateUsed: Date; var Implementation: Enum "No. Series Implementation")
    var
        NoSeriesLine: Record "No. Series Line";
        NoSeries: Codeunit "No. Series";
#if not CLEAN24
#pragma warning disable AL0432
        NoSeriesManagement: Codeunit NoSeriesManagement;
        IsHandled: Boolean;
#pragma warning restore AL0432        
#endif
    begin
#if not CLEAN24
#pragma warning disable AL0432
        NoSeriesManagement.OnBeforeUpdateLine(NoSeriesRec, StartDate, StartNo, EndNo, LastNoUsed, WarningNo, IncrementByNo, LastDateUsed, Implementation, IsHandled);
        if IsHandled then
            exit;
#pragma warning restore AL0432        
#endif
        SetNoSeriesCurrentLineFilters(NoSeriesRec, NoSeriesLine, false);

        StartDate := NoSeriesLine."Starting Date";
        StartNo := NoSeriesLine."Starting No.";
        EndNo := NoSeriesLine."Ending No.";
        LastNoUsed := NoSeries.GetLastNoUsed(NoSeriesLine."Series Code");
        WarningNo := NoSeriesLine."Warning No.";
        IncrementByNo := NoSeriesLine."Increment-by No.";
        LastDateUsed := NoSeriesLine."Last Date Used";
        Implementation := NoSeriesLine.Implementation;
    end;

    procedure ShowNoSeriesWithWarningsOnly(var NoSeries: Record "No. Series")
    var
        NoSeriesLine: Record "No. Series Line";
        NoSeriesCodeunit: Codeunit "No. Series";
        LastNoUsedForLine: Code[20];
    begin
        if NoSeries.FindSet() then
            repeat
                NoSeriesLine.SetRange("Series Code", NoSeries.Code);
                if NoSeriesLine.FindSet() then
                    repeat
                        if (NoSeriesLine."Warning No." <> '') and NoSeriesLine.Open then begin
                            LastNoUsedForLine := NoSeriesCodeunit.GetLastNoUsed(NoSeriesLine);
                            if (LastNoUsedForLine <> '') and (LastNoUsedForLine >= NoSeriesLine."Warning No.") then begin
                                NoSeries.Mark(true);
                                break;
                            end;
                        end;
                    until NoSeriesLine.Next() = 0
                else
                    NoSeries.Mark(true);
            until NoSeries.Next() = 0;
        NoSeries.MarkedOnly(true);
    end;

    local procedure SetNoSeriesCurrentLineFilters(var NoSeriesRec: Record "No. Series"; var NoSeriesLine: Record "No. Series Line"; ResetForDrillDown: Boolean)
    var
        NoSeries: Codeunit "No. Series";
#if not CLEAN24
#pragma warning disable AL0432
        NoSeriesManagement: Codeunit NoSeriesManagement;
#pragma warning restore AL0432
#endif
    begin
        NoSeriesLine.Reset();
        NoSeriesLine.SetCurrentKey("Series Code", "Starting Date");
        NoSeriesLine.SetRange("Series Code", NoSeriesRec.Code);
        NoSeriesLine.SetRange("Starting Date", 0D, WorkDate());
#if not CLEAN24
#pragma warning disable AL0432
        NoSeriesManagement.RaiseObsoleteOnNoSeriesLineFilterOnBeforeFindLast(NoSeriesLine);
#pragma warning restore AL0432
#endif
        if NoSeriesLine.FindLast() then begin
            NoSeriesLine.SetRange("Starting Date", NoSeriesLine."Starting Date");
            NoSeriesLine.SetRange(Open, true);
        end;

        if not NoSeriesLine.FindLast() then begin
            NoSeriesLine.Reset();
            NoSeriesLine.SetRange("Series Code", NoSeriesRec.Code);
        end;

        if not NoSeriesLine.FindFirst() then begin
            NoSeriesLine.Init();
            NoSeriesLine."Series Code" := NoSeriesRec.Code;
        end;

        if ResetForDrillDown then begin
            NoSeriesLine.SetRange("Starting Date");
            NoSeriesLine.SetRange(Open);
        end;

        NoSeries.OnAfterSetNoSeriesCurrentLineFilters(NoSeriesRec, NoSeriesLine, ResetForDrillDown);
    end;

    procedure MayProduceGaps(NoSeriesLine: Record "No. Series Line"): Boolean
    var
        NoSeriesSingle: Interface "No. Series - Single";
    begin
        NoSeriesSingle := NoSeriesLine.Implementation;
        exit(NoSeriesSingle.MayProduceGaps());
    end;

    procedure CalculateOpen(NoSeriesLine: Record "No. Series Line"): Boolean
    var
        NoSeries: Codeunit "No. Series";
        LastNoUsed, NextNo : Code[20];
    begin
        if NoSeriesLine."Ending No." = '' then
            exit(true);

        LastNoUsed := NoSeries.GetLastNoUsed(NoSeriesLine);

        if LastNoUsed = '' then
            exit(true);

        if LastNoUsed >= NoSeriesLine."Ending No." then
            exit(false);

        if StrLen(LastNoUsed) > StrLen(NoSeriesLine."Ending No.") then
            exit(false);

        if NoSeriesLine."Increment-by No." <> 1 then begin
            NextNo := IncrementNoText(LastNoUsed, NoSeriesLine."Increment-by No.");
            if NextNo > NoSeriesLine."Ending No." then
                exit(false);
            if StrLen(NextNo) > StrLen(NoSeriesLine."Ending No.") then
                exit(false);
        end;
        exit(true);
    end;

    procedure ValidateDefaultNos(var NoSeries: Record "No. Series"; xRecNoSeries: Record "No. Series")
#if not CLEAN24
#pragma warning disable AL0432
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        NoSeries.OnBeforeValidateDefaultNos(NoSeries, IsHandled);
        if not IsHandled then
#pragma warning restore AL0432
#else
    begin
#endif
            if (NoSeries."Default Nos." = false) and (xRecNoSeries."Default Nos." <> NoSeries."Default Nos.") and (NoSeries."Manual Nos." = false) then
                NoSeries.Validate("Manual Nos.", true);
    end;

    procedure ValidateManualNos(var NoSeries: Record "No. Series"; xRecNoSeries: Record "No. Series")
#if not CLEAN24
#pragma warning disable AL0432
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        NoSeries.OnBeforeValidateManualNos(NoSeries, IsHandled);
        if not IsHandled then
#else
    begin
#pragma warning restore AL0432
#endif
            if (NoSeries."Manual Nos." = false) and (xRecNoSeries."Manual Nos." <> NoSeries."Manual Nos.") and (NoSeries."Default Nos." = false) then
                NoSeries.Validate("Default Nos.", true);
    end;

    procedure IncrementNoText(No: Code[20]; Increment: Integer): Code[20]
    var
        BigIntNo: BigInteger;
        BigIntIncByNo: BigInteger;
        StartPos: Integer;
        EndPos: Integer;
        NewNo: Code[20];
    begin
        GetIntegerPos(No, StartPos, EndPos);
        Evaluate(BigIntNo, CopyStr(No, StartPos, EndPos - StartPos + 1));
        BigIntIncByNo := Increment;
        NewNo := CopyStr(Format(BigIntNo + BigIntIncByNo, 0, 1), 1, MaxStrLen(NewNo));
        ReplaceNoText(No, NewNo, 0, StartPos, EndPos);
        exit(No);
    end;

    procedure UpdateNoSeriesLine(var NoSeriesLine: Record "No. Series Line"; NewNo: Code[20]; NewFieldCaption: Text[100])
    var
        NoSeriesLine2: Record "No. Series Line";
#if not CLEAN24
#pragma warning disable AL0432
        NoSeriesManagement: Codeunit NoSeriesManagement;
#pragma warning restore AL0432
#endif
        NoSeriesErrorsImpl: Codeunit "No. Series - Errors Impl.";
#if not CLEAN24
#pragma warning disable AL0432
        IsHandled: Boolean;
#pragma warning restore AL0432
#endif
        Length: Integer;
    begin
#if not CLEAN24
#pragma warning disable AL0432
        IsHandled := false;
        NoSeriesManagement.RaiseObsoleteOnBeforeUpdateNoSeriesLine(NoSeriesLine, NewNo, NewFieldCaption, IsHandled);
        if IsHandled then
            exit;
#pragma warning restore AL0432
#endif
        if NewNo <> '' then begin
            if IncStr(NewNo) = '' then
                NoSeriesErrorsImpl.Throw(StrSubstNo(UnIncrementableStringErr, NewFieldCaption), NoSeriesLine, NoSeriesErrorsImpl.OpenNoSeriesLinesAction());
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
            if (NewFieldCaption <> NoSeriesLine.FieldCaption("Last No. Used")) and
               (NoSeriesLine."Last No. Used" <> NoSeriesLine2."Last No. Used")
            then
                NoSeriesErrorsImpl.Throw(StrSubstNo(NumberFormatErr, NewFieldCaption, NoSeriesLine.FieldCaption("Last No. Used")), NoSeriesLine, NoSeriesErrorsImpl.OpenNoSeriesLinesAction());
        end;
    end;

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

    procedure DeleteNoSeries(var NoSeries: Record "No. Series")
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

    [EventSubscriber(ObjectType::Table, Database::"No. Series Line", 'OnAfterDeleteEvent', '', false, false)]
    local procedure OnDeleteNoSeriesLine(var Rec: Record "No. Series Line"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary() then
            exit;

        if Rec."Sequence Name" <> '' then
            if NumberSequence.Exists(Rec."Sequence Name") then
                NumberSequence.Delete(Rec."Sequence Name");
    end;
}