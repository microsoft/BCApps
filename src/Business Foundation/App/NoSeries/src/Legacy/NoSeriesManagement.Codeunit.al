#if not CLEAN24
#pragma warning disable AL0432
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Foundation.NoSeries;

codeunit 396 NoSeriesManagement
{
    InherentEntitlements = X;
    InherentPermissions = X;
    ObsoleteReason = 'Please use the "No. Series" and "No. Series - Batch" codeunits instead';
    ObsoleteState = Pending;
    ObsoleteTag = '24.0';
    Permissions = tabledata "No. Series Line" = rimd,
                  tabledata "No. Series Line Sales" = r,
                  tabledata "No. Series Line Purchase" = r,
                  tabledata "No. Series" = r;

    trigger OnRun()
    begin
        TryNo := GetNextNo(TryNoSeriesCode, TrySeriesDate, false);
    end;

    var
        GlobalNoSeries: Record "No. Series";
        LastNoSeriesLine: Record "No. Series Line";
        GlobalNoSeriesCode: Code[20];
        WarningNoSeriesCode: Code[20];
        TryNoSeriesCode: Code[20];
        TrySeriesDate: Date;
        TryNo: Code[20];
        UpdateLastUsedDate: Boolean;
        CannotAssignManuallyErr: Label 'You may not enter numbers manually. If you want to enter numbers manually, please activate %1 in %2 %3.', Comment = '%1=Manual Nos. setting,%2=No. Series table caption,%3=No. Series Code';
        CannotAssignAutomaticallyErr: Label 'It is not possible to assign numbers automatically. If you want the program to assign numbers automatically, please activate %1 in %2 %3.', Comment = '%1=Default Nos. setting,%2=No. Series table caption,%3=No. Series Code';
        CannotAssignNewOnDateErr: Label 'You cannot assign new numbers from the number series %1 on %2.', Comment = '%1=No. Series Code,%2=Date';
        CannotAssignNewErr: Label 'You cannot assign new numbers from the number series %1.', Comment = '%1=No. Series Code';
        CannotAssignNewBeforeDateErr: Label 'You cannot assign new numbers from the number series %1 on a date before %2.', Comment = '%1=No. Series Code,%2=Date';
        CannotAssignGreaterErr: Label 'You cannot assign numbers greater than %1 from the number series %2.', Comment = '%1=Last No.,%2=No. Series Code';
        NumberFormatErr: Label 'The number format in %1 must be the same as the number format in %2.', Comment = '%1=No. Series Code,%2=No. Series Code';
        NumberLengthErr: Label 'The number %1 cannot be extended to more than 20 characters.', Comment = '%1=No.';
        PostErr: Label 'You have one or more documents that must be posted before you post document no. %1 according to your company''s No. Series setup.', Comment = '%1=Document No.';
        UnincrementableStringErr: Label 'The value in the %1 field must have a number so that we can assign the next number in the series.', Comment = '%1 = New Field Name';

    [Obsolete('Please use method TestManual(NoSeriesCode: Code[20]) in codeunit "No. Series" instead.', '24.0')]
    procedure TestManual(DefaultNoSeriesCode: Code[20])
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTestManual(DefaultNoSeriesCode, IsHandled);
        if not IsHandled then
            if DefaultNoSeriesCode <> '' then begin
                GlobalNoSeries.Get(DefaultNoSeriesCode);
                if not GlobalNoSeries."Manual Nos." then
                    Error(CannotAssignManuallyErr, GlobalNoSeries.FieldCaption("Manual Nos."), GlobalNoSeries.TableCaption(), GlobalNoSeries.Code);
            end;
        OnAfterTestManual(DefaultNoSeriesCode);
    end;

    [Obsolete('Please use method IsManual(NoSeriesCode: Code[20]) in codeunit "No. Series" instead.', '24.0')]
    procedure ManualNoAllowed(DefaultNoSeriesCode: Code[20]): Boolean
    begin
        GlobalNoSeries.Get(DefaultNoSeriesCode);
        exit(GlobalNoSeries."Manual Nos.");
    end;

    [Obsolete('Please use method TestManual(NoSeriesCode: Code[20]; DocumentNo: Code[20]) in codeunit "No. Series" instead.', '24.0')]
    procedure TestManualWithDocumentNo(DefaultNoSeriesCode: Code[20]; DocumentNo: Code[20])
    begin
        if DefaultNoSeriesCode <> '' then begin
            GlobalNoSeries.Get(DefaultNoSeriesCode);
            if not GlobalNoSeries."Manual Nos." then
                Error(PostErr, DocumentNo);
        end;
    end;

    [Obsolete('This method is used for compatibility with extension usages of the old OnBeforeInitSeries event. Now the new No. Series is used. InitSeries no longer exist, instead a No. Series is selected and the next number is retrieved.', '24.0')]
    procedure RaiseObsoleteOnBeforeInitSeries(var DefaultNoSeriesCode: Code[20]; OldNoSeriesCode: Code[20]; NewDate: Date; var NewNo: Code[20]; var NewNoSeriesCode: Code[20]; var IsHandled: Boolean)
    begin
        OnBeforeInitSeries(DefaultNoSeriesCode, OldNoSeriesCode, NewDate, NewNo, NewNoSeriesCode, GlobalNoSeries, IsHandled, GlobalNoSeriesCode);
    end;

    [Obsolete('This method is used for compatibility with extension usages of the old OnAfterInitSeries event. Now the new No. Series is used. InitSeries no longer exist, instead a No. Series is selected and the next number is retrieved.', '24.0')]
    procedure RaiseObsoleteOnAfterInitSeries(NoSeriesCode: Code[20]; DefaultNoSeriesCode: Code[20]; NewDate: Date; var NewNo: Code[20])
    var
        NoSeries: Record "No. Series";
    begin
        if NoSeries.Get(NoSeriesCode) then;
        OnAfterInitSeries(NoSeries, DefaultNoSeriesCode, NewDate, NewNo);
    end;

    [Obsolete('Please use AreRelated in the "No. Series" codeunit instead', '24.0')]
    procedure InitSeries(DefaultNoSeriesCode: Code[20]; OldNoSeriesCode: Code[20]; NewDate: Date; var NewNo: Code[20]; var NewNoSeriesCode: Code[20])
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInitSeries(DefaultNoSeriesCode, OldNoSeriesCode, NewDate, NewNo, NewNoSeriesCode, GlobalNoSeries, IsHandled, GlobalNoSeriesCode);
        if IsHandled then
            exit;

        if NewNo = '' then begin
            GlobalNoSeries.Get(DefaultNoSeriesCode);
            if not GlobalNoSeries."Default Nos." then
                Error(CannotAssignAutomaticallyErr, GlobalNoSeries.FieldCaption("Default Nos."), GlobalNoSeries.TableCaption(), GlobalNoSeries.Code);
            if OldNoSeriesCode <> '' then begin
                GlobalNoSeriesCode := DefaultNoSeriesCode;
                FilterSeries();
                GlobalNoSeries.Code := OldNoSeriesCode;
                if not GlobalNoSeries.Find() then
                    GlobalNoSeries.Get(DefaultNoSeriesCode);
            end;
            NewNo := GetNextNo(GlobalNoSeries.Code, NewDate, true);
            NewNoSeriesCode := GlobalNoSeries.Code;
        end else
            TestManual(DefaultNoSeriesCode);
        OnAfterInitSeries(GlobalNoSeries, DefaultNoSeriesCode, NewDate, NewNo);
    end;

    [Obsolete('Please use the "No. Series" codeunit instead', '24.0')]
    procedure SetDefaultSeries(var NewNoSeriesCode: Code[20]; NoSeriesCode: Code[20])
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetDefaultSeries(NewNoSeriesCode, NoSeriesCode, IsHandled);
        if IsHandled then
            exit;

        if NoSeriesCode <> '' then begin
            GlobalNoSeries.Get(NoSeriesCode);
            if GlobalNoSeries."Default Nos." then
                NewNoSeriesCode := GlobalNoSeries.Code;
        end;
    end;

    // NewNoSeriesCode specifies the default number series to highlight in the page
    // If this one is not specified then OldNoSeriesCode is used instead as default highlight
    // Otherwise DefaultNoSeriesCode is used if it exist
    // All related no series to DefaultNoSeriesCode are also available for selection
    [Obsolete('Use method LookupRelatedNoSeries in codeunit "No. Series instead.', '24.0')]
    procedure SelectSeries(DefaultNoSeriesCode: Code[20]; OldNoSeriesCode: Code[20]; var NewNoSeriesCode: Code[20]): Boolean
    var
        IsHandled: Boolean;
        Result: Boolean;
    begin
        IsHandled := false;
        OnBeforeSelectSeries(DefaultNoSeriesCode, OldNoSeriesCode, NewNoSeriesCode, Result, IsHandled);
        if IsHandled then
            exit(Result);

        GlobalNoSeriesCode := DefaultNoSeriesCode;
        FilterSeries();
        if NewNoSeriesCode = '' then begin
            if OldNoSeriesCode <> '' then
                GlobalNoSeries.Code := OldNoSeriesCode;
        end else
            GlobalNoSeries.Code := NewNoSeriesCode;
        OnSelectSeriesOnBeforePageRunModal(DefaultNoSeriesCode, GlobalNoSeries);
        if Page.RunModal(0, GlobalNoSeries) = Action::LookupOK then begin
            NewNoSeriesCode := GlobalNoSeries.Code;
            exit(true);
        end;
    end;

    [Obsolete('This is a temporary method for compatibility only.', '24.0')]
    internal procedure RaiseObsoleteOnBeforeSelectSeries(var DefaultNoSeriesCode: Code[20]; OldNoSeriesCode: Code[20]; var NewNoSeriesCode: Code[20]; var Result: Boolean; var IsHandled: Boolean)
    begin
        OnBeforeSelectSeries(DefaultNoSeriesCode, OldNoSeriesCode, NewNoSeriesCode, Result, IsHandled);
    end;

    [Obsolete('This is a temporary method for compatibility only.', '24.0')]
    internal procedure RaiseObsoleteOnSelectSeriesOnBeforePageRunModal(var DefaultNoSeriesCode: Code[20]; var NoSeries: Record "No. Series")
    begin
        OnSelectSeriesOnBeforePageRunModal(DefaultNoSeriesCode, NoSeries);
    end;

    [Obsolete('Use method LookupRelatedNoSeries in codeunit "No. Series" instead.', '24.0')]
    procedure LookupSeries(DefaultNoSeriesCode: Code[20]; var NewNoSeriesCode: Code[20]): Boolean
    begin
        exit(SelectSeries(DefaultNoSeriesCode, NewNoSeriesCode, NewNoSeriesCode));
    end;

    [Obsolete('Use method TestAreRelated in codeunit "No. Series" instead.', '24.0')]
    procedure TestSeries(DefaultNoSeriesCode: Code[20]; NewNoSeriesCode: Code[20])
    begin
        GlobalNoSeriesCode := DefaultNoSeriesCode;
        FilterSeries();
        GlobalNoSeries.Code := NewNoSeriesCode;
#pragma warning disable AA0175
        GlobalNoSeries.Find();
#pragma warning restore AA0175
    end;

    [Obsolete('Use method GetNextNo in codeunit "No. Series" instead.', '24.0')]
    procedure SetSeries(var NewNo: Code[20])
    var
        NoSeriesCode2: Code[20];
    begin
        NoSeriesCode2 := GlobalNoSeries.Code;
        FilterSeries();
        GlobalNoSeries.Code := NoSeriesCode2;
        GlobalNoSeries.Find();
        NewNo := GetNextNo(GlobalNoSeries.Code, 0D, true);
    end;

    [Obsolete('This method will be removed. There is no replacement.', '24.0')]
    procedure FilterSeries()
    var
        NoSeriesRelationship: Record "No. Series Relationship";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeFilterSeries(GlobalNoSeries, GlobalNoSeriesCode, IsHandled);
        if IsHandled then
            exit;

        GlobalNoSeries.Reset();
        NoSeriesRelationship.SetRange(Code, GlobalNoSeriesCode);
        if NoSeriesRelationship.FindSet() then
            repeat
                GlobalNoSeries.Code := NoSeriesRelationship."Series Code";
                GlobalNoSeries.Mark := true;
            until NoSeriesRelationship.Next() = 0;
        if GlobalNoSeries.Get(GlobalNoSeriesCode) then
            GlobalNoSeries.Mark := true;
        GlobalNoSeries.MarkedOnly := true;
    end;

    [Obsolete('This is a temporary method for compatibility only.', '24.0')]
    internal procedure RaiseObsoleteOnBeforeFilterSeries(var NoSeries: Record "No. Series"; NoSeriesCode: Code[20]; IsHandled: Boolean);
    begin
        OnBeforeFilterSeries(NoSeries, NoSeriesCode, IsHandled);
    end;

#pragma warning disable AS0072
    [Obsolete('Please use method GetNextNo(Code[20]; Date) or PeekNextNo(Code[20]; UsageDate) in the codeunit "No. Series" or "No. Series - Batch" instead. GetNextNo(Code[20]; Date; Boolean) does not have the same behavior. Make sure to use the correct parameters.', '24.0')]
    procedure GetNextNo(NoSeriesCode: Code[20]; SeriesDate: Date; ModifySeries: Boolean) Result: Code[20]
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetNextNo(NoSeriesCode, SeriesDate, ModifySeries, Result, IsHandled, LastNoSeriesLine);
        if IsHandled then
            exit(Result);

        exit(DoGetNextNo(NoSeriesCode, SeriesDate, ModifySeries, false));
    end;
#pragma warning restore AS0072

    /// <summary>
    /// This method is added for compatibility only.It raises the obsolete OnBeforeGetNextNo event. 
    /// </summary>
    /// <remarks>
    /// There's a bit of a symantic change with this event. You can no longer change things like ModifySeries, UsageDate, SeriesCode using this event
    /// Also, the line record passed is no longer the line from the previous call as that data is not kept anymore in regular scenarios.
    /// </remarks>
    /// <param name="NoSeriesLine">The "Series Code" field is taken from this line on input. If handled, then the actual line used is returned in this parameter.</param>
    /// <param name="UsageDate">The date on which to get a number.</param>
    /// <param name="ModifySeries">Specifies whether the line should be modified.</param>
    /// <param name="Result">The new number from the specified series.</param>
    /// <param name="IsHandled">Specifies whether a subscriber handled the event.</param>
    [Obsolete('This is a temporary method for compatibility only. Please use the "No. Series" codeunit instead', '24.0')]
    internal procedure RaiseObsoleteOnBeforeGetNextNo(var NoSeriesLine: Record "No. Series Line"; UsageDate: Date; ModifySeries: Boolean; var Result: Code[20]; var IsHandled: Boolean)
    var
        NoSeriesLine2: Record "No. Series Line";
    begin
        NoSeriesLine2.Copy(NoSeriesLine);
        OnBeforeGetNextNo(NoSeriesLine2."Series Code", UsageDate, ModifySeries, Result, IsHandled, NoSeriesLine);
        if IsHandled then
            NoSeriesLine.Copy(NoSeriesLine2);
    end;

    [Obsolete('Use DoGetNextNo() instead', '21.0')]
    procedure GetNextNo3(NoSeriesCode: Code[20]; SeriesDate: Date; ModifySeries: Boolean; NoErrorsOrWarnings: Boolean): Code[20]
    begin
        exit(DoGetNextNo(NoSeriesCode, SeriesDate, ModifySeries, NoErrorsOrWarnings));
    end;

    /// <summary>
    /// Gets the next number in a number series.
    /// If ModifySeries is set to true, the number series is incremented when getting the next number.
    /// </summary>
    /// <remark>If you set ModifySeries to false you should manually increment the number series to ensure consistency.</remark>
    /// <param name="NoSeriesCode">The identifier of the number series.</param>
    /// <param name="SeriesDate">The date of the number series. The default date is WorkDate.</param>
    /// <param name="ModifySeries">
    /// Set to true to increment the number series when getting the next number.
    /// Set to false if you want to manually increment the number series.
    /// </param>
    /// <param name="NoErrorsOrWarnings">Set to true to disable errors and warnings.</param>
    /// <returns>The next number in the number series.</returns>
    procedure DoGetNextNo(NoSeriesCode: Code[20]; SeriesDate: Date; ModifySeries: Boolean; NoErrorsOrWarnings: Boolean): Code[20]
    var
        NoSeriesLine: Record "No. Series Line";
        CurrNoSeriesLine: Record "No. Series Line";
    begin
        OnBeforeDoGetNextNo(NoSeriesCode, SeriesDate, ModifySeries, NoErrorsOrWarnings);
        if SeriesDate = 0D then
            SeriesDate := WorkDate();

        FindNoSeriesLine(CurrNoSeriesLine, NoSeriesCode, SeriesDate);
        if ModifySeries or (LastNoSeriesLine."Series Code" = '') or (LastNoSeriesLine."Series Code" <> NoSeriesCode) or ((LastNoSeriesLine."Line No." <> CurrNoSeriesLine."Line No.") and (LastNoSeriesLine."Series Code" = NoSeriesCode)) then begin
            GlobalNoSeries.Get(NoSeriesCode);
            if not FindNoSeriesLine(NoSeriesLine, NoSeriesCode, SeriesDate) then begin
                if NoErrorsOrWarnings then
                    exit('');
                NoSeriesLine.SetRange("Starting Date");
                if not NoSeriesLine.IsEmpty() then
                    Error(CannotAssignNewOnDateErr, NoSeriesCode, SeriesDate);
                Error(CannotAssignNewErr, NoSeriesCode);
            end;
            UpdateLastUsedDate := NoSeriesLine."Last Date Used" <> SeriesDate;
            if ModifySeries and (not (NoSeriesLine.Implementation = "No. Series Implementation"::Sequence) or UpdateLastUsedDate) then begin
                NoSeriesLine.LockTable();
                NoSeriesLine.Find();
            end;
        end else
            NoSeriesLine := LastNoSeriesLine;

        if GlobalNoSeries."Date Order" and (SeriesDate < NoSeriesLine."Last Date Used") then begin
            if NoErrorsOrWarnings then
                exit('');
            Error(CannotAssignNewBeforeDateErr, GlobalNoSeries.Code, NoSeriesLine."Last Date Used");
        end;

        NoSeriesLine."Last Date Used" := SeriesDate;
        if (NoSeriesLine.Implementation = "No. Series Implementation"::Sequence) and (LastNoSeriesLine."Series Code" = '') then
            NoSeriesLine."Last No. Used" := NoSeriesLine.GetNextSequenceNo(ModifySeries)
        else
            if NoSeriesLine."Last No. Used" = '' then begin
                if NoErrorsOrWarnings and (NoSeriesLine."Starting No." = '') then
                    exit('');
                NoSeriesLine.TestField("Starting No.");
                NoSeriesLine."Last No. Used" := NoSeriesLine."Starting No.";
            end else
                if NoSeriesLine."Increment-by No." <= 1 then
                    NoSeriesLine."Last No. Used" := IncStr(NoSeriesLine."Last No. Used")
                else
                    IncrementNoText(NoSeriesLine."Last No. Used", NoSeriesLine."Increment-by No.");

        // Ensure number is within the valid range
        if (NoSeriesLine."Ending No." <> '') and
           (NoSeriesLine."Last No. Used" > NoSeriesLine."Ending No.")
        then begin
            if NoErrorsOrWarnings then
                exit('');
            Error(CannotAssignGreaterErr, NoSeriesLine."Ending No.", NoSeriesCode);
        end;

        if (NoSeriesLine."Ending No." <> '') and
           (NoSeriesLine."Warning No." <> '') and
           (NoSeriesLine."Last No. Used" >= NoSeriesLine."Warning No.") and
           (NoSeriesCode <> WarningNoSeriesCode) and
           (TryNoSeriesCode = '')
        then begin
            if NoErrorsOrWarnings then
                exit('');
            WarningNoSeriesCode := NoSeriesCode;
            Message(CannotAssignGreaterErr, NoSeriesLine."Ending No.", NoSeriesCode);
        end;

        if ModifySeries and NoSeriesLine.Open and (not (NoSeriesLine.Implementation = "No. Series Implementation"::Sequence) or UpdateLastUsedDate) then
            ModifyNoSeriesLine(NoSeriesLine);
        if not ModifySeries then
            LastNoSeriesLine := NoSeriesLine;

        OnAfterGetNextNo3(NoSeriesLine, ModifySeries);
        exit(NoSeriesLine."Last No. Used");
    end;

    procedure FindNoSeriesLine(var NoSeriesLineResult: Record "No. Series Line"; NoSeriesCode: Code[20]; SeriesDate: Date): Boolean
    begin
        SetNoSeriesLineFilter(NoSeriesLineResult, NoSeriesCode, SeriesDate);
        exit(NoSeriesLineResult.FindFirst());
    end;

    procedure IsCurrentNoSeriesLine(NoSeriesLineIn: Record "No. Series Line"): Boolean
    begin
        exit((NoSeriesLineIn."Series Code" = LastNoSeriesLine."Series Code") and (NoSeriesLineIn."Line No." = LastNoSeriesLine."Line No."));
    end;

    internal procedure ModifyNoSeriesLine(var NoSeriesLine: Record "No. Series Line")
    var
        IsHandled: Boolean;
        LastNoUsed: Code[20];
    begin
        IsHandled := false;
        OnBeforeModifyNoSeriesLine(NoSeriesLine, IsHandled);
        if IsHandled then
            exit;
        NoSeriesLine.Validate(Open);
        LastNoUsed := NoSeriesLine."Last No. Used";
        if NoSeriesLine.Implementation = "No. Series Implementation"::Sequence then
            NoSeriesLine."Last No. Used" := '';
        NoSeriesLine.Modify();
        NoSeriesLine."Last No. Used" := LastNoUsed;
    end;

    [Obsolete('Use PeekNextNo from codeunit "No. Series" instead.', '24.0')]
    procedure TryGetNextNo(NoSeriesCode: Code[20]; SeriesDate: Date): Code[20]
    var
        NoSeriesManagement: Codeunit NoSeriesManagement;
    begin
        NoSeriesManagement.SetParametersBeforeRun(NoSeriesCode, SeriesDate);
        if NoSeriesManagement.Run() then
            exit(NoSeriesManagement.GetNextNoAfterRun());
    end;

    [Obsolete('Use SetParametersBeforeRun() instead', '21.0')]
    procedure GetNextNo1(NoSeriesCode: Code[20]; SeriesDate: Date)
    begin
        SetParametersBeforeRun(NoSeriesCode, SeriesDate);
    end;

    procedure SetParametersBeforeRun(NoSeriesCode: Code[20]; SeriesDate: Date)
    begin
        TryNoSeriesCode := NoSeriesCode;
        TrySeriesDate := SeriesDate;
        OnAfterSetParametersBeforeRun(TryNoSeriesCode, TrySeriesDate, WarningNoSeriesCode);
    end;

    [Obsolete('Use GetNextNoAfterRun() instead', '21.0')]
    procedure GetNextNo2(): Code[20]
    begin
        exit(GetNextNoAfterRun());
    end;

    procedure GetNextNoAfterRun(): Code[20]
    begin
        exit(TryNo);
    end;

    [Obsolete('Use the SaveState method in the No. Series - Batch codeunit instead.', '24.0')]
    procedure SaveNoSeries()
    var
        NoSeries: Codeunit "No. Series";
        NoSeriesSequenceImpl: Codeunit "No. Series - Sequence Impl.";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSaveNoSeries(LastNoSeriesLine, IsHandled);
        if not IsHandled then
            if LastNoSeriesLine."Series Code" <> '' then begin
                if (LastNoSeriesLine.Implementation = "No. Series Implementation"::Sequence) then
                    if (LastNoSeriesLine."Last No. Used" <> '') and (LastNoSeriesLine."Last No. Used" > NoSeries.GetLastNoUsed(LastNoSeriesLine)) then
                        RestartSequence(LastNoSeriesLine, NoSeriesSequenceImpl.ExtractNoFromCode(LastNoSeriesLine."Last No. Used", LastNoSeriesLine."Series Code"));
                if not (LastNoSeriesLine.Implementation = "No. Series Implementation"::Sequence) or UpdateLastUsedDate then
                    ModifyNoSeriesLine(LastNoSeriesLine);
            end;
        OnAfterSaveNoSeries(LastNoSeriesLine);
    end;

    internal procedure RestartSequence(var NoSeriesLine: Record "No. Series Line"; NewStartingNo: BigInteger)
    begin
        NoSeriesLine.TestField(Implementation, NoSeriesLine.Implementation::Sequence);
        NoSeriesLine.TestField("Sequence Name");
        NoSeriesLine."Starting Sequence No." := NewStartingNo;
        if NoSeriesLine."Last No. Used" = '' then
            NumberSequence.Restart(NoSeriesLine."Sequence Name", NoSeriesLine."Starting Sequence No." - NoSeriesLine."Increment-by No.")
        else begin
            NumberSequence.Restart(NoSeriesLine."Sequence Name", NoSeriesLine."Starting Sequence No.");
            if NumberSequence.Next(NoSeriesLine."Sequence Name") = 0 then;  // Simulate that a number was used
        end;
    end;

    procedure ClearNoSeriesLine()
    begin
        Clear(LastNoSeriesLine);
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

    internal procedure FindNoSeriesLineToShow(var NoSeries: Record "No. Series"; var NoSeriesLine: Record "No. Series Line")
    begin
        SetNoSeriesLineFilter(NoSeriesLine, NoSeries.Code, 0D);

        if NoSeriesLine.FindLast() then
            exit;

        NoSeriesLine.Reset();
        NoSeriesLine.SetRange("Series Code", NoSeries.Code);
    end;

    [Obsolete('Please use the method GetNoSeriesLine on the "No. Series" and "No. Series - Batch" codeunits instead', '24.0')]
    procedure SetNoSeriesLineFilter(var NoSeriesLine: Record "No. Series Line"; NoSeriesCode: Code[20]; StartDate: Date)
    begin
        if StartDate = 0D then
            StartDate := WorkDate();

        NoSeriesLine.Reset();
        NoSeriesLine.SetCurrentKey("Series Code", "Starting Date");
        NoSeriesLine.SetRange("Series Code", NoSeriesCode);
        NoSeriesLine.SetRange("Starting Date", 0D, StartDate);
        RaiseObsoleteOnNoSeriesLineFilterOnBeforeFindLast(NoSeriesLine);
        if NoSeriesLine.FindLast() then begin
            NoSeriesLine.SetRange("Starting Date", NoSeriesLine."Starting Date");
            NoSeriesLine.SetRange(Open, true);
        end;
    end;

    internal procedure RaiseObsoleteOnNoSeriesLineFilterOnBeforeFindLast(var NoSeriesLine: Record "No. Series Line")
    begin
        OnNoSeriesLineFilterOnBeforeFindLast(NoSeriesLine);
    end;

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

    [Obsolete('Please use the method from "No. Series - Setup" instead.', '24.0')]
    procedure UpdateNoSeriesLine(var NoSeriesLine: Record "No. Series Line"; NewNo: Code[20]; NewFieldName: Text[100])
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
                Error(NumberFormatErr, NewFieldName, NoSeriesLine.FieldCaption("Last No. Used"));
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

    [Obsolete('The No. Series Line Sales table is obsolete. Please use the No. Series Line table instead.', '24.0')]
    [Scope('OnPrem')]
    procedure SetNoSeriesLineSalesFilter(var NoSeriesLineSales: Record "No. Series Line Sales"; NoSeriesCode: Code[20]; StartDate: Date)
    begin
        OnObsoleteSetNoSeriesLineSalesFilter(NoSeriesLineSales, NoSeriesCode, StartDate);
    end;

    [Obsolete('The No. Series Line Purchase table is obsolete. Please use the No. Series Line table instead.', '24.0')]
    [Scope('OnPrem')]
    procedure SetNoSeriesLinePurchaseFilter(var NoSeriesLinePurchase: Record "No. Series Line Purchase"; NoSeriesCode: Code[20]; StartDate: Date)
    begin
        OnObsoleteSetNoSeriesLinePurchaseFilter(NoSeriesLinePurchase, NoSeriesCode, StartDate);
    end;

    [Obsolete('The No. Series Line Sales table is obsolete. Please use the No. Series Line table instead.', '24.0')]
    [Scope('OnPrem')]
    procedure UpdateNoSeriesLineSales(var NoSeriesLineSales: Record "No. Series Line Sales"; NewNo: Code[20]; NewFieldName: Text[30])
    var
        NoSeriesLineSales2: Record "No. Series Line Sales";
        Length: Integer;
    begin
        if NewNo <> '' then begin
            if IncStr(NewNo) = '' then
                Error(UnincrementableStringErr, NewFieldName);
            NoSeriesLineSales2 := NoSeriesLineSales;
            if NewNo = GetNoText(NewNo) then
                Length := 0
            else begin
                Length := StrLen(GetNoText(NewNo));
                UpdateLength(NoSeriesLineSales."Starting No.", Length);
                UpdateLength(NoSeriesLineSales."Ending No.", Length);
                UpdateLength(NoSeriesLineSales."Last No. Used", Length);
                UpdateLength(NoSeriesLineSales."Warning No.", Length);
            end;
            UpdateNo(NoSeriesLineSales."Starting No.", NewNo, Length);
            UpdateNo(NoSeriesLineSales."Ending No.", NewNo, Length);
            UpdateNo(NoSeriesLineSales."Last No. Used", NewNo, Length);
            UpdateNo(NoSeriesLineSales."Warning No.", NewNo, Length);
            if (NewFieldName <> NoSeriesLineSales.FieldCaption("Last No. Used")) and
               (NoSeriesLineSales."Last No. Used" <> NoSeriesLineSales2."Last No. Used")
            then
                Error(
                  NumberFormatErr,
                  NewFieldName, NoSeriesLineSales.FieldCaption("Last No. Used"));
        end;
    end;

    [Obsolete('The No. Series Line Purchase table is obsolete. Please use the No. Series Line table instead.', '24.0')]
    [Scope('OnPrem')]
    procedure UpdateNoSeriesLinePurchase(var NoSeriesLinePurchase: Record "No. Series Line Purchase"; NewNo: Code[20]; NewFieldName: Text[30])
    var
        NoSeriesLinePurchase2: Record "No. Series Line Purchase";
        Length: Integer;
    begin
        if NewNo <> '' then begin
            if IncStr(NewNo) = '' then
                Error(UnincrementableStringErr, NewFieldName);
            NoSeriesLinePurchase2 := NoSeriesLinePurchase;
            if NewNo = GetNoText(NewNo) then
                Length := 0
            else begin
                Length := StrLen(GetNoText(NewNo));
                UpdateLength(NoSeriesLinePurchase."Starting No.", Length);
                UpdateLength(NoSeriesLinePurchase."Ending No.", Length);
                UpdateLength(NoSeriesLinePurchase."Last No. Used", Length);
                UpdateLength(NoSeriesLinePurchase."Warning No.", Length);
            end;
            UpdateNo(NoSeriesLinePurchase."Starting No.", NewNo, Length);
            UpdateNo(NoSeriesLinePurchase."Ending No.", NewNo, Length);
            UpdateNo(NoSeriesLinePurchase."Last No. Used", NewNo, Length);
            UpdateNo(NoSeriesLinePurchase."Warning No.", NewNo, Length);
            if (NewFieldName <> NoSeriesLinePurchase.FieldCaption("Last No. Used")) and
               (NoSeriesLinePurchase."Last No. Used" <> NoSeriesLinePurchase2."Last No. Used")
            then
                Error(
                  NumberFormatErr,
                  NewFieldName, NoSeriesLinePurchase.FieldCaption("Last No. Used"));
        end;
    end;

    [Obsolete('Call TestField on the "No. Series" record, "Date Order" field directly.', '24.0')]
    [Scope('OnPrem')]
    procedure TestDateOrder(NoSeriesCode: Code[20])
    begin
        GlobalNoSeries.Get(NoSeriesCode);
        GlobalNoSeries.TestField("Date Order");
    end;

    [Obsolete('The No. Series module cannot have dependencies to Sales. Please use the method in codeunit "IT - Report Management" instead', '24.0')]
    procedure CheckSalesDocNoGaps(MaxDate: Date)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckSalesDocNoGaps(MaxDate, IsHandled);
        if IsHandled then
            exit;

        OnObsoleteCheckSalesDocNoGaps(MaxDate);
    end;

    [Obsolete('The No. Series module cannot have dependencies to Purchases. Please use the method in codeunit "IT - Report Management" instead', '24.0')]
    procedure CheckPurchDocNoGaps(MaxDate: Date)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckPurchDocNoGaps(MaxDate, IsHandled);
        if IsHandled then
            exit;

        OnObsoleteCheckPurchDocNoGaps(MaxDate);
    end;

    [Obsolete('The No. Series module cannot have dependencies to Sales. Please use the method in codeunit "IT - Report Management" instead', '24.0')]
    [IntegrationEvent(false, false)]
    local procedure OnObsoleteCheckSalesDocNoGaps(MaxDate: Date)
    begin
    end;

    [Obsolete('The No. Series module cannot have dependencies to Purchases. Please use the method in codeunit "IT - Report Management" instead', '24.0')]
    [IntegrationEvent(false, false)]
    local procedure OnObsoleteCheckPurchDocNoGaps(MaxDate: Date)
    begin
    end;

    [Obsolete('The No. Series module cannot have dependencies to Sales. Please use the event in codeunit "IT - Report Management" instead', '24.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckPurchDocNoGaps(MaxDate: Date; var IsHandled: Boolean)
    begin
    end;

    [Obsolete('The No. Series module cannot have dependencies to Purchases. Please use the event in codeunit "IT - Report Management" instead', '24.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckSalesDocNoGaps(MaxDate: Date; var IsHandled: Boolean)
    begin
    end;

    [Obsolete('Use method LookupRelatedNoSeries in codeunit "No. Series" instead.', '24.0')]
    procedure GetNoSeriesWithCheck(NewNoSeriesCode: Code[20]; SelectNoSeriesAllowed: Boolean; CurrentNoSeriesCode: Code[20]): Code[20]
    begin
        if not SelectNoSeriesAllowed then
            exit(NewNoSeriesCode);

        GlobalNoSeries.Get(NewNoSeriesCode);
        if GlobalNoSeries."Default Nos." then
            exit(NewNoSeriesCode);

        if SeriesHasRelations(NewNoSeriesCode) then
            if SelectSeries(NewNoSeriesCode, '', CurrentNoSeriesCode) then
                exit(CurrentNoSeriesCode);
        exit(NewNoSeriesCode);
    end;

    [Obsolete('Use method HasRelatedSeries in codeunit "No. Series" instead.', '24.0')]
    procedure SeriesHasRelations(DefaultNoSeriesCode: Code[20]): Boolean
    var
        NoSeriesRelationship: Record "No. Series Relationship";
    begin
        NoSeriesRelationship.Reset();
        NoSeriesRelationship.SetRange(Code, DefaultNoSeriesCode);
        exit(not NoSeriesRelationship.IsEmpty);
    end;

    [Scope('OnPrem')]
    procedure ReverseGetNextNo(NoSeriesCode: Code[20]; SeriesDate: Date; ModifySeries: Boolean): Code[20] // Backwards compatibility for apac
    var
        NoSeriesLine: Record "No. Series Line";
    begin
        if SeriesDate = 0D then
            SeriesDate := WorkDate();

        if ModifySeries or (LastNoSeriesLine."Series Code" = '') then begin
            if ModifySeries then
                NoSeriesLine.LockTable();
            GlobalNoSeries.Get(NoSeriesCode);
            if not FindNoSeriesLine(NoSeriesLine, NoSeriesCode, SeriesDate) then begin
                NoSeriesLine.SetRange("Starting Date");
                if NoSeriesLine.Find('-') then
                    Error(CannotAssignNewOnDateErr, NoSeriesCode, SeriesDate);
                Error(CannotAssignNewErr, NoSeriesCode);
            end;
        end else
            NoSeriesLine := LastNoSeriesLine;
        NoSeriesLine.TestField(Implementation, "No. Series Implementation"::Normal);

        if GlobalNoSeries."Date Order" and (SeriesDate < NoSeriesLine."Last Date Used") then
            Error(CannotAssignNewBeforeDateErr, GlobalNoSeries.Code, NoSeriesLine."Last Date Used");
        NoSeriesLine."Last Date Used" := SeriesDate;
        if NoSeriesLine."Last No. Used" = '' then begin
            NoSeriesLine.TestField("Starting No.");
            NoSeriesLine."Last No. Used" := NoSeriesLine."Starting No.";
        end else
            IncrementNoText(NoSeriesLine."Last No. Used", -NoSeriesLine."Increment-by No.");
        if (NoSeriesLine."Ending No." <> '') and
           (NoSeriesLine."Last No. Used" > NoSeriesLine."Ending No.")
        then
            Error(CannotAssignGreaterErr, NoSeriesLine."Ending No.", NoSeriesCode);
        if (NoSeriesLine."Ending No." <> '') and
           (NoSeriesLine."Warning No." <> '') and
           (NoSeriesLine."Last No. Used" >= NoSeriesLine."Warning No.") and
           (NoSeriesCode <> WarningNoSeriesCode) and
           (TryNoSeriesCode = '')
        then begin
            WarningNoSeriesCode := NoSeriesCode;
            Message(CannotAssignGreaterErr, NoSeriesLine."Ending No.", NoSeriesCode);
        end;
        NoSeriesLine.Validate(Open);

        if ModifySeries then
            NoSeriesLine.Modify()
        else
            LastNoSeriesLine := NoSeriesLine;
        exit(NoSeriesLine."Last No. Used");
    end;

    [Obsolete('This is a temporary method for compatibility only. Please use the "No. Series" codeunit instead', '24.0')]
    internal procedure RaiseObsoleteOnAfterGetNextNo3(var NoSeriesLine: Record "No. Series Line"; ModifySeries: Boolean)
    begin
        OnAfterGetNextNo3(NoSeriesLine, ModifySeries);
    end;

    [Obsolete('This event is obsolete. Please use the extensibility options provided by the No. Series module.', '24.0')]
    [IntegrationEvent(false, false)]
    internal procedure OnAfterGetNextNo3(var NoSeriesLine: Record "No. Series Line"; ModifySeries: Boolean)
    begin
    end;

    [Obsolete('This event is no longer used. Please use the No. Series Batch codeunit instead.', '24.0')]
    // Symbol usage indicates no subscribers
    [IntegrationEvent(false, false)]
    local procedure OnAfterSaveNoSeries(var NoSeriesLine: Record "No. Series Line")
    begin
    end;

    [Obsolete('The No. Series Line Sales table is obsolete. Please use the No. Series Line table instead.', '24.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterSaveNoSeriesSales(var NoSeriesLineSales: Record "No. Series Line Sales")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetParametersBeforeRun(var TryNoSeriesCode: Code[20]; var TrySeriesDate: Date; var WarningNoSeriesCode: Code[20])
    begin
    end;

    [Obsolete('The No. Series Line Purchase table is obsolete. Please use the No. Series Line table instead.', '24.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterSaveNoSeriesPurchase(var NoSeriesLinePurchase: Record "No. Series Line Purchase")
    begin
    end;

    [Obsolete('This event will be removed. There is no replacement. Please use the extensibility options provided by the No. Series module.', '24.0')]
    [IntegrationEvent(false, false)]
    internal procedure OnAfterTestManual(DefaultNoSeriesCode: Code[20])
    begin
    end;

    [Obsolete('This event is obsolete. Please use the extensibility options provided by the No. Series module.', '24.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetNextNo(var NoSeriesCode: Code[20]; var SeriesDate: Date; var ModifySeries: Boolean; var Result: Code[20]; var IsHandled: Boolean; var NoSeriesLine: Record "No. Series Line")
    begin
    end;

    [Obsolete('This is a temporary method for compatibility only. Please use the "No. Series" codeunit instead', '24.0')]
    internal procedure RaiseObsoleteOnBeforeDoGetNextNo(var NoSeriesCode: Code[20]; var SeriesDate: Date; ModifySeries: Boolean; var NoErrorsOrWarnings: Boolean)
    begin
        OnBeforeDoGetNextNo(NoSeriesCode, SeriesDate, ModifySeries, NoErrorsOrWarnings);
    end;

    [Obsolete('This event is obsolete. Please use the extensibility options provided by the No. Series module.', '24.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeDoGetNextNo(var NoSeriesCode: Code[20]; var SeriesDate: Date; var ModifySeries: Boolean; var NoErrorsOrWarnings: Boolean)
    begin
    end;

    [Obsolete('This is a temporary method for compatibility only. Please use the "No. Series" codeunit instead', '24.0')]
    internal procedure RaiseObsoleteOnBeforeModifyNoSeriesLine(var NoSeriesLine: Record "No. Series Line"; var IsHandled: Boolean)
    begin
        OnBeforeModifyNoSeriesLine(NoSeriesLine, IsHandled);
    end;

    [IntegrationEvent(false, false)]
    internal procedure OnBeforeModifyNoSeriesLine(var NoSeriesLine: Record "No. Series Line"; var IsHandled: Boolean)
    begin
    end;

    [Obsolete('This is a temporary method for compatibility only. Please use the "No. Series" codeunit instead', '24.0')]
    internal procedure RaiseObsoleteOnBeforeUpdateNoSeriesLine(var NoSeriesLine: Record "No. Series Line"; NewNo: Code[20]; NewFieldName: Text[100]; var IsHandled: Boolean)
    begin
        OnBeforeUpdateNoSeriesLine(NoSeriesLine, NewNo, NewFieldName, IsHandled);
    end;

    [Obsolete('This event is obsolete. Please use the extensibility options provided by the No. Series module.', '24.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateNoSeriesLine(var NoSeriesLine: Record "No. Series Line"; NewNo: Code[20]; NewFieldName: Text[100]; var IsHandled: Boolean)
    begin
    end;

    procedure ClearStateAndGetNextNo(NoSeriesCode: Code[20]): Code[20]
    begin
        Clear(LastNoSeriesLine);
        Clear(TryNoSeriesCode);
        Clear(GlobalNoSeries);

        exit(GetNextNo(NoSeriesCode, WorkDate(), false));
    end;

    [Obsolete('Please use OnAfterSetNoSeriesCurrentLineFilters in the No. Series module instead.', '24.0')]
    [IntegrationEvent(false, false)]
    local procedure OnNoSeriesLineFilterOnBeforeFindLast(var NoSeriesLine: Record "No. Series Line")
    begin
    end;

    [Obsolete('This event will be removed. There is no replacement. Please use the No. Series module instead.', '24.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterInitSeries(var NoSeries: Record "No. Series"; DefaultNoSeriesCode: Code[20]; NewDate: Date; var NewNo: Code[20])
    begin
    end;

    [Obsolete('This event will be removed. There is no replacement. Please use the No. Series module instead.', '24.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeFilterSeries(var NoSeries: Record "No. Series"; NoSeriesCode: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [Obsolete('This event will be removed. There is no replacement. Please use the No. Series module instead.', '24.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitSeries(var DefaultNoSeriesCode: Code[20]; OldNoSeriesCode: Code[20]; NewDate: Date; var NewNo: Code[20]; var NewNoSeriesCode: Code[20]; var NoSeries: Record "No. Series"; var IsHandled: Boolean; var NoSeriesCode: Code[20])
    begin
    end;

    [Obsolete('This event will be removed. Please use the Page trigger events instead.', '24.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeSelectSeries(var DefaultNoSeriesCode: Code[20]; OldNoSeriesCode: Code[20]; var NewNoSeriesCode: Code[20]; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [Obsolete('This event will be removed. Please use the Page trigger events instead.', '24.0')]
    [IntegrationEvent(false, false)]
    local procedure OnSelectSeriesOnBeforePageRunModal(DefaultNoSeriesCode: Code[20]; var NoSeries: Record "No. Series")
    begin
    end;

    [Obsolete('This event is no longer used. Please use the No. Series Batch codeunit instead.', '24.0')]
    // Symbol usage indicates no subscribers
    [IntegrationEvent(false, false)]
    local procedure OnBeforeSaveNoSeries(var NoSeriesLine: Record "No. Series Line"; var IsHandled: Boolean)
    begin
    end;

    [Obsolete('This event will be removed. There is no replacement. Please use the No. Series module instead.', '24.0')]
    [IntegrationEvent(false, false)]
    internal procedure OnBeforeTestManual(var DefaultNoSeriesCode: Code[20]; var IsHandled: Boolean);
    begin
    end;

    [Obsolete('This event will be removed. There is no replacement. Please use the No. Series module instead.', '24.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetDefaultSeries(var NewNoSeriesCode: Code[20]; var NoSeriesCode: Code[20]; var IsHandled: Boolean);
    begin
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

    [Obsolete('Temporary event for backwards compatibility. Do not use this event.', '24.0')]
    [IntegrationEvent(false, false)]
    internal procedure OnBeforeUpdateLine(var NoSeries: Record "No. Series"; var StartDate: Date; var StartNo: Code[20]; var EndNo: Code[20]; var LastNoUsed: Code[20]; var WarningNo: Code[20]; var IncrementByNo: Integer; var LastDateUsed: Date; var Implementation: Enum "No. Series Implementation"; var IsHandled: Boolean);
    begin
    end;
}
#pragma warning restore AL0432
#endif