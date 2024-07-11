// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Foundation.NoSeries;

codeunit 304 "No. Series - Impl."
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;
    Permissions =
        tabledata "No. Series" = r,
        tabledata "No. Series Line" = rimd;

    var
        CannotAssignManuallyErr: Label 'You may not enter numbers manually. If you want to enter numbers manually, please activate %1 in %2 %3.', Comment = '%1=Manual Nos. setting,%2=No. Series table caption,%3=No. Series Code';
        CannotAssignNewOnDateErr: Label 'You cannot assign new numbers from the number series %1 on %2.', Comment = '%1=No. Series Code,%2=Date';
        CannotAssignNewErr: Label 'You cannot assign new numbers from the number series %1.', Comment = '%1=No. Series Code';
        CannotAssignNewBeforeDateErr: Label 'You cannot assign new numbers from the number series %1 on a date before %2.', Comment = '%1=No. Series Code,%2=Date';
        CannotAssignAutomaticallyErr: Label 'It is not possible to assign numbers automatically. If you want the program to assign numbers automatically, please activate %1 in %2 %3.', Comment = '%1=Default Nos. setting,%2=No. Series table caption,%3=No. Series Code';
        SeriesNotRelatedErr: Label 'The number series %1 is not related to %2.', Comment = '%1=No. Series Code,%2=No. Series Code';
        PostErr: Label 'You have one or more documents that must be posted before you post document no. %1 according to your company''s No. Series setup.', Comment = '%1=Document No.';
        CannotGetNoSeriesLineNoWithEmptyCodeErr: Label 'You cannot get a No. Series Line with empty No. Series Code.';

#if not CLEAN24
#pragma warning disable AL0432
    procedure TestManual(NoSeriesCode: Code[20])
    var
        NoSeries: Record "No. Series";
        NoSeriesManagement: Codeunit NoSeriesManagement;
        IsHandled: Boolean;
    begin
        NoSeriesManagement.OnBeforeTestManual(NoSeriesCode, IsHandled);
        if not IsHandled then
            if NoSeriesCode <> '' then
                TestManualInternal(NoSeriesCode, StrSubstNo(CannotAssignManuallyErr, NoSeries.FieldCaption("Manual Nos."), NoSeries.TableCaption(), NoSeries.Code));
        NoSeriesManagement.OnAfterTestManual(NoSeriesCode);
    end;
#pragma warning restore AL0432
#else
    procedure TestManual(NoSeriesCode: Code[20])
    var
        NoSeries: Record "No. Series";
    begin
        TestManualInternal(NoSeriesCode, StrSubstNo(CannotAssignManuallyErr, NoSeries.FieldCaption("Manual Nos."), NoSeries.TableCaption(), NoSeries.Code));
    end;
#endif

    procedure TestManual(NoSeriesCode: Code[20]; DocumentNo: Code[20])
    begin
        TestManualInternal(NoSeriesCode, StrSubstNo(PostErr, DocumentNo));
    end;

    local procedure TestManualInternal(NoSeriesCode: Code[20]; ErrorText: Text)
    var
        NoSeries: Record "No. Series";
        NoSeriesErrorsImpl: Codeunit "No. Series - Errors Impl.";
    begin
        NoSeries.Get(NoSeriesCode);
        if not NoSeries."Manual Nos." then
            NoSeriesErrorsImpl.Throw(ErrorText, NoSeriesCode, NoSeriesErrorsImpl.OpenNoSeriesLinesAction());
    end;

    procedure IsManual(NoSeriesCode: Code[20]): Boolean
    var
        NoSeries: Record "No. Series";
    begin
        if NoSeriesCode = '' then
            exit(false);
        if not NoSeries.Get(NoSeriesCode) then
            exit(false);
        exit(NoSeries."Manual Nos.");
    end;

    procedure GetLastNoUsed(var NoSeriesLine: Record "No. Series Line"): Code[20]
    begin
        exit(GetImplementation(NoSeriesLine).GetLastNoUsed(NoSeriesLine));
    end;

    procedure GetLastNoUsed(NoSeriesCode: Code[20]): Code[20]
    var
        NoSeriesLine: Record "No. Series Line";
        NoSeriesSingle: Interface "No. Series - Single";
    begin
        if not GetNoSeriesLine(NoSeriesLine, NoSeriesCode, WorkDate(), true) then
            exit('');

        NoSeriesSingle := GetImplementation(NoSeriesLine);

        exit(NoSeriesSingle.GetLastNoUsed(NoSeriesLine));
    end;

    procedure GetNextNo(NoSeriesCode: Code[20]; SeriesDate: Date; HideErrorsAndWarnings: Boolean): Code[20]
    var
        NoSeriesLine: Record "No. Series Line";
    begin
        if not GetNoSeriesLine(NoSeriesLine, NoSeriesCode, SeriesDate, HideErrorsAndWarnings) then
            exit('');

        exit(GetNextNo(NoSeriesLine, SeriesDate, HideErrorsAndWarnings));
    end;

    procedure GetNextNo(var NoSeriesLine: Record "No. Series Line"; UsageDate: Date; HideErrorsAndWarnings: Boolean): Code[20]
    var
#if not CLEAN24
#pragma warning disable AL0432
        NoSeriesManagement: Codeunit NoSeriesManagement;
#pragma warning restore AL0432
#endif
        NoSeriesSingle: Interface "No. Series - Single";
#if not CLEAN24
        Result: Code[20];
        IsHandled: Boolean;
#endif
    begin
        if UsageDate = 0D then
            UsageDate := WorkDate();

#if not CLEAN24
#pragma warning disable AL0432, AA0205
        NoSeriesManagement.RaiseObsoleteOnBeforeGetNextNo(NoSeriesLine, UsageDate, true, Result, IsHandled);
        if IsHandled then
            exit(Result);
        NoSeriesManagement.RaiseObsoleteOnBeforeDoGetNextNo(NoSeriesLine."Series Code", UsageDate, true, HideErrorsAndWarnings);
#pragma warning restore AL0432, AA0205
#endif
        if not ValidateCanGetNextNo(NoSeriesLine, UsageDate, HideErrorsAndWarnings) then
            exit('');

        NoSeriesSingle := GetImplementation(NoSeriesLine);

#if not CLEAN24
#pragma warning disable AL0432, AA0205
        Result := NoSeriesSingle.GetNextNo(NoSeriesLine, UsageDate, HideErrorsAndWarnings);
        if Result <> NoSeriesLine."Last No. Used" then
            NoSeriesLine."Last No. Used" := Result;
        NoSeriesManagement.RaiseObsoleteOnAfterGetNextNo3(NoSeriesLine, true);
        exit(NoSeriesLine."Last No. Used");
#pragma warning restore AL0432, AA0205
#else
        exit(NoSeriesSingle.GetNextNo(NoSeriesLine, UsageDate, HideErrorsAndWarnings))
#endif
    end;

    local procedure GetImplementation(var NoSeriesLine: Record "No. Series Line"): Interface "No. Series - Single"
    begin
        exit(NoSeriesLine.Implementation);
    end;

    [InherentPermissions(PermissionObjectType::TableData, Database::"No. Series Line", 'm')]
    procedure GetNoSeriesLine(var NoSeriesLine: Record "No. Series Line"; NoSeriesCode: Code[20]; UsageDate: Date; HideErrorsAndWarnings: Boolean): Boolean
    var
        NoSeriesRec: Record "No. Series";
        NoSeriesLine2: Record "No. Series Line";
        NoSeries: Codeunit "No. Series";
        NoSeriesErrorsImpl: Codeunit "No. Series - Errors Impl.";
#if not CLEAN24
#pragma warning disable AL0432
        NoSeriesManagement: Codeunit NoSeriesManagement;
#pragma warning restore AL0432
#endif
        LineFound: Boolean;
    begin
        if NoSeriesCode = '' then begin
            if not HideErrorsAndWarnings then
                Error(CannotGetNoSeriesLineNoWithEmptyCodeErr);
            exit(false);
        end;

        if UsageDate = 0D then
            UsageDate := WorkDate();

        // Find the No. Series Line closest to the usage date
        NoSeriesLine2.Reset();
        NoSeriesLine2.SetCurrentKey("Series Code", "Starting Date");
        NoSeriesLine2.SetRange("Series Code", NoSeriesCode);
        NoSeriesLine2.SetRange("Starting Date", 0D, UsageDate);
#if not CLEAN24
#pragma warning disable AL0432
        NoSeriesManagement.RaiseObsoleteOnNoSeriesLineFilterOnBeforeFindLast(NoSeriesLine2);
#pragma warning restore AL0432
#endif
        if NoSeriesLine2.FindLast() then;
        NoSeriesLine.SetCurrentKey("Series Code", "Starting Date");
        NoSeriesLine.CopyFilters(NoSeriesLine2);

        if (NoSeriesLine."Line No." <> 0) and (NoSeriesLine."Series Code" = NoSeriesCode) and (NoSeriesLine."Starting Date" = NoSeriesLine2."Starting Date") then begin
            NoSeriesLine.CopyFilters(NoSeriesLine2);
            NoSeriesLine.SetRange("Line No.", NoSeriesLine."Line No.");
#if not CLEAN24
#pragma warning disable AL0432
            NoSeriesManagement.RaiseObsoleteOnNoSeriesLineFilterOnBeforeFindLast(NoSeriesLine);
#pragma warning restore AL0432
#endif
            LineFound := NoSeriesLine.FindLast();
            if not LineFound then
                NoSeriesLine.SetRange("Line No.");
        end;
#if not CLEAN24
#pragma warning disable AL0432
        if not LineFound then begin
            NoSeriesManagement.RaiseObsoleteOnNoSeriesLineFilterOnBeforeFindLast(NoSeriesLine);
            LineFound := NoSeriesLine.FindLast();
        end;
#pragma warning restore AL0432
#else
        if not LineFound then
            LineFound := NoSeriesLine.FindLast();
#endif

        if LineFound and NoSeries.MayProduceGaps(NoSeriesLine) then begin
            NoSeriesLine.Validate(Open);
            if not NoSeriesLine.Open then
                NoSeriesLine.Modify(true);
        end;

        if LineFound then begin
            // There may be multiple No. Series Lines for the same day, so find the first one.
            NoSeriesLine.SetRange(Open, true);
            NoSeriesLine.SetRange("Starting Date", NoSeriesLine."Starting Date");
            LineFound := NoSeriesLine.FindFirst();
        end;

        if not LineFound then begin
            // Throw an error depending on the reason we couldn't find a date
            if HideErrorsAndWarnings then
                exit(false);

            NoSeriesLine.SetRange("Starting Date");
            if not NoSeriesLine.IsEmpty() then
                NoSeriesErrorsImpl.Throw(StrSubstNo(CannotAssignNewOnDateErr, NoSeriesCode, UsageDate), NoSeriesCode, NoSeriesErrorsImpl.OpenNoSeriesLinesAction());
            NoSeriesErrorsImpl.Throw(StrSubstNo(CannotAssignNewErr, NoSeriesCode), NoSeriesCode, NoSeriesErrorsImpl.OpenNoSeriesLinesAction());
        end;

        // If Date Order is required for this No. Series, make sure the usage date is not before the last date used
        NoSeriesRec.SetLoadFields(Code, "Date Order");
        NoSeriesRec.Get(NoSeriesCode);
        if NoSeriesRec."Date Order" and (UsageDate < NoSeriesLine."Last Date Used") then begin
            if HideErrorsAndWarnings then
                exit(false);
            NoSeriesErrorsImpl.Throw(StrSubstNo(CannotAssignNewBeforeDateErr, NoSeriesRec.Code, NoSeriesLine."Last Date Used"), NoSeriesLine, NoSeriesErrorsImpl.OpenNoSeriesLinesAction());
        end;
        exit(true);
    end;

    procedure PeekNextNo(NoSeriesCode: Code[20]; UsageDate: Date): Code[20]
    var
        NoSeriesLine: Record "No. Series Line";
    begin
        if not GetNoSeriesLine(NoSeriesLine, NoSeriesCode, UsageDate, false) then
            exit('');

        exit(PeekNextNo(NoSeriesLine, UsageDate));
    end;

    procedure PeekNextNo(var NoSeriesLine: Record "No. Series Line"; UsageDate: Date): Code[20]
    var
#if not CLEAN24
#pragma warning disable AL0432
        NoSeriesManagement: Codeunit NoSeriesManagement;
#pragma warning restore AL0432
#endif
        NoSeriesSingle: Interface "No. Series - Single";
#if not CLEAN24
        Result: Code[20];
        HideErrorsAndWarnings: Boolean;
        IsHandled: Boolean;
#endif
    begin
        if UsageDate = 0D then
            UsageDate := WorkDate();

#if not CLEAN24
#pragma warning disable AL0432, AA0205
        NoSeriesManagement.RaiseObsoleteOnBeforeGetNextNo(NoSeriesLine, UsageDate, false, Result, IsHandled);
        if IsHandled then
            exit(Result);
        HideErrorsAndWarnings := false;
        NoSeriesManagement.RaiseObsoleteOnBeforeDoGetNextNo(NoSeriesLine."Series Code", UsageDate, false, HideErrorsAndWarnings);
#pragma warning restore AL0432, AA0205
#endif
        if not ValidateCanGetNextNo(NoSeriesLine, UsageDate, false) then
            exit('');

        NoSeriesSingle := GetImplementation(NoSeriesLine);


#if not CLEAN24
#pragma warning disable AL0432, AA0205
        Result := NoSeriesSingle.PeekNextNo(NoSeriesLine, UsageDate);
        if Result <> NoSeriesLine."Last No. Used" then
            NoSeriesLine."Last No. Used" := Result;
        NoSeriesManagement.RaiseObsoleteOnAfterGetNextNo3(NoSeriesLine, false);
        exit(NoSeriesLine."Last No. Used");
#pragma warning restore AL0432, AA0205
#else
        exit(NoSeriesSingle.PeekNextNo(NoSeriesLine, UsageDate));
#endif
    end;

    procedure HasRelatedSeries(NoSeriesCode: Code[20]): Boolean
    var
        NoSeriesRelationship: Record "No. Series Relationship";
    begin
        NoSeriesRelationship.SetRange(Code, NoSeriesCode);
        exit(not NoSeriesRelationship.IsEmpty());
    end;

    procedure TestAreRelated(DefaultNoSeriesCode: Code[20]; RelatedNoSeriesCode: Code[20])
    var
        NoSeriesErrorsImpl: Codeunit "No. Series - Errors Impl.";
    begin
        if not AreRelated(DefaultNoSeriesCode, RelatedNoSeriesCode) then
            NoSeriesErrorsImpl.Throw(StrSubstNo(SeriesNotRelatedErr, DefaultNoSeriesCode, RelatedNoSeriesCode), DefaultNoSeriesCode, NoSeriesErrorsImpl.OpenNoSeriesRelationshipsAction());
    end;

    procedure OpenNoSeriesRelationships(ErrorInfo: ErrorInfo)
    var
        NoSeriesLines: Record "No. Series Line";
    begin
        NoSeriesLines.SetRange("Series Code", ErrorInfo.CustomDimensions.Get('DefaultNoSeriesCode'));
        Page.Run(Page::"No. Series Relationships", NoSeriesLines);
    end;

    procedure AreRelated(DefaultNoSeriesCode: Code[20]; RelatedNoSeriesCode: Code[20]): Boolean
    var
        NoSeries: Record "No. Series";
        NoSeriesRelationship: Record "No. Series Relationship";
    begin
        if not NoSeries.Get(DefaultNoSeriesCode) then
            exit(false);

        TestAutomatic(NoSeries);

        if DefaultNoSeriesCode = RelatedNoSeriesCode then
            exit(true);

        exit(NoSeriesRelationship.Get(DefaultNoSeriesCode, RelatedNoSeriesCode));
    end;

    procedure IsAutomatic(NoSeriesCode: Code[20]): Boolean
    var
        NoSeries: Record "No. Series";
    begin
        if not NoSeries.Get(NoSeriesCode) then
            exit(false);
        exit(NoSeries."Default Nos.");
    end;

    procedure TestAutomatic(NoSeriesCode: Code[20])
    var
        NoSeries: Record "No. Series";
        NoSeriesErrorsImpl: Codeunit "No. Series - Errors Impl.";
    begin
        if not NoSeries.Get(NoSeriesCode) then
            NoSeriesErrorsImpl.Throw(StrSubstNo(CannotAssignAutomaticallyErr, NoSeries.FieldCaption("Default Nos."), NoSeries.TableCaption(), NoSeriesCode), '', NoSeriesErrorsImpl.OpenNoSeriesAction());

        TestAutomatic(NoSeries);
    end;

    local procedure TestAutomatic(NoSeries: Record "No. Series")
    var
        NoSeriesErrorsImpl: Codeunit "No. Series - Errors Impl.";
    begin
        if not NoSeries."Default Nos." then
            NoSeriesErrorsImpl.Throw(StrSubstNo(CannotAssignAutomaticallyErr, NoSeries.FieldCaption("Default Nos."), NoSeries.TableCaption(), NoSeries.Code), NoSeries.Code, NoSeriesErrorsImpl.OpenNoSeriesAction());
    end;

    procedure LookupRelatedNoSeries(OriginalNoSeriesCode: Code[20]; DefaultHighlightedNoSeriesCode: Code[20]; var NewNoSeriesCode: Code[20]): Boolean
    var
        NoSeries: Record "No. Series";
        NoSeriesRelationship: Record "No. Series Relationship";
#if not CLEAN24
#pragma warning disable AL0432
        NoSeriesManagement: Codeunit NoSeriesManagement;
        IsHandled: Boolean;
        Result: Boolean;
#pragma warning restore AL0432
#endif
    begin
#if not CLEAN24
#pragma warning disable AL0432
        IsHandled := false;
        NoSeriesManagement.RaiseObsoleteOnBeforeSelectSeries(OriginalNoSeriesCode, DefaultHighlightedNoSeriesCode, NewNoSeriesCode, Result, IsHandled);
        if IsHandled then
            exit(Result);

        NoSeriesManagement.RaiseObsoleteOnBeforeFilterSeries(NoSeries, OriginalNoSeriesCode, IsHandled);
        if not IsHandled then begin
#pragma warning restore AL0432
#endif
            NoSeriesRelationship.SetRange(Code, OriginalNoSeriesCode);
            if NoSeriesRelationship.FindSet() then
                repeat
                    NoSeries.Code := NoSeriesRelationship."Series Code";
                    NoSeries.Mark := true;
                until NoSeriesRelationship.Next() = 0;

            // Mark the original series
            NoSeries.Code := OriginalNoSeriesCode;
            NoSeries.Mark := true;
            NoSeries.MarkedOnly := true;
#if not CLEAN24
        end;
#endif

        // If DefaultHighlightedNoSeriesCode is set, make sure we select it by default on the page
        if DefaultHighlightedNoSeriesCode <> '' then
            NoSeries.Code := DefaultHighlightedNoSeriesCode;

#if not CLEAN24
#pragma warning disable AL0432
        NoSeriesManagement.RaiseObsoleteOnSelectSeriesOnBeforePageRunModal(NoSeries.Code, NoSeries);
#pragma warning restore AL0432
#endif
        if Page.RunModal(0, NoSeries) = Action::LookupOK then begin
            NewNoSeriesCode := NoSeries.Code;
            exit(true);
        end;
        exit(false);
    end;

    procedure SelectNoSeries(OriginalNoSeriesCode: Code[20]; RelatedNoSeriesCode: Code[20]): Code[20]
    begin
        if AreRelated(OriginalNoSeriesCode, RelatedNoSeriesCode) then
            exit(RelatedNoSeriesCode);
        exit(OriginalNoSeriesCode);
    end;

    local procedure ValidateCanGetNextNo(var NoSeriesLine: Record "No. Series Line"; SeriesDate: Date; HideErrorsAndWarnings: Boolean): Boolean
    var
        NoSeriesErrorsImpl: Codeunit "No. Series - Errors Impl.";
    begin
        if SeriesDate < NoSeriesLine."Starting Date" then
            if HideErrorsAndWarnings then
                exit(false)
            else
                NoSeriesErrorsImpl.Throw(StrSubstNo(CannotAssignNewBeforeDateErr, NoSeriesLine."Series Code", NoSeriesLine."Starting Date"), NoSeriesLine, NoSeriesErrorsImpl.OpenNoSeriesLinesAction());

        exit(true);
    end;
}