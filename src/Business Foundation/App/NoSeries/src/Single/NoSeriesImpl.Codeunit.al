// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Foundation.NoSeries;

codeunit 304 "No. Series - Impl."
{
    Access = Internal;
    permissions = tabledata "No. Series Line" = rimd,
                  tabledata "No. Series" = r;
    InherentPermissions = X;
    InherentEntitlements = X;

    var
        CannotAssignManuallyErr: Label 'You may not enter numbers manually. If you want to enter numbers manually, please activate %1 in %2 %3.', comment = '%1=Manual Nos. setting,%2=No. Series table caption,%3=No. Series Code';
        CannotAssignNewOnDateErr: Label 'You cannot assign new numbers from the number series %1 on %2.', Comment = '%1=No. Series Code,%2=Date';
        CannotAssignNewErr: Label 'You cannot assign new numbers from the number series %1.', Comment = '%1=No. Series Code';
        CannotAssignNewBeforeDateErr: Label 'You cannot assign new numbers from the number series %1 on a date before %2.', Comment = '%1=No. Series Code,%2=Date';
        CannotAssignAutomaticallyErr: Label 'It is not possible to assign numbers automatically. If you want the program to assign numbers automatically, please activate %1 in %2 %3.', Comment = '%1=Default Nos. setting,%2=No. Series table caption,%3=No. Series Code';
        SeriesNotRelatedErr: Label 'The number series %1 is not related to %2.', Comment = '%1=No. Series Code,%2=No. Series Code';
        PostErr: Label 'You have one or more documents that must be posted before you post document no. %1 according to your company''s No. Series setup.', Comment = '%1=Document No.';

    procedure TestManual(NoSeriesCode: Code[20])
    var
        NoSeries: Record "No. Series";
    begin
        if NoSeriesCode = '' then
            exit;
        NoSeries.Get(NoSeriesCode);
        if not NoSeries."Manual Nos." then
            Error(CannotAssignManuallyErr, NoSeries.FieldCaption("Manual Nos."), NoSeries.TableCaption(), NoSeries.Code);
    end;

    procedure TestManual(NoSeriesCode: Code[20]; DocumentNo: Code[20])
    var
        NoSeries: Record "No. Series";
    begin
        if NoSeriesCode = '' then
            exit;
        NoSeries.Get(NoSeriesCode);
        if not NoSeries."Manual Nos." then
            Error(Posterr, DocumentNo);
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
        NoSeriesLine."Series Code" := NoSeriesCode;
        exit(GetNextNo(NoSeriesLine, SeriesDate, HideErrorsAndWarnings));
    end;

    procedure GetNextNo(var NoSeriesLine: Record "No. Series Line"; SeriesDate: Date; HideErrorsAndWarnings: Boolean): Code[20]
    var
        NoSeriesSingle: Interface "No. Series - Single";
    begin
        if not GetNoSeriesLine(NoSeriesLine, NoSeriesLine."Series Code", SeriesDate, HideErrorsAndWarnings) then
            exit('');

        NoSeriesSingle := GetImplementation(NoSeriesLine);

        exit(NoSeriesSingle.GetNextNo(NoSeriesLine, SeriesDate, HideErrorsAndWarnings));
    end;

    local procedure GetImplementation(var NoSeriesLine: Record "No. Series Line"): Interface "No. Series - Single"
    begin
        if NoSeriesLine."Allow Gaps in Nos." then // TODO: Enum needs to be specified on the table and retrieved from there
            exit(Enum::"No. Series Implementation"::Sequence);
        exit(Enum::"No. Series Implementation"::Normal);
    end;

    procedure GetNoSeriesLine(var NoSeriesLine: Record "No. Series Line"; NoSeriesCode: Code[20]; UsageDate: Date; HideErrorsAndWarnings: Boolean): Boolean
    var
        NoSeries: Record "No. Series";
    begin
        if UsageDate = 0D then
            UsageDate := WorkDate();

        // Find the No. Series Line closest to the usage date
        NoSeriesLine.Reset();
        NoSeriesLine.SetCurrentKey("Series Code", "Starting Date");
        NoSeriesLine.SetRange("Series Code", NoSeriesCode);
        NoSeriesLine.SetRange("Starting Date", 0D, UsageDate);
        NoSeriesLine.SetRange(Open, true);
        if NoSeriesLine.FindLast() then begin
            // There may be multiple No. Series Lines for the same day, so find the first one.
            NoSeriesLine.SetRange("Starting Date", NoSeriesLine."Starting Date");
            NoSeriesLine.FindFirst();
        end else begin
            // Throw an error depending on the reason we couldn't find a date
            if HideErrorsAndWarnings then
                exit(false);
            NoSeriesLine.SetRange("Starting Date");
            NoSeriesLine.SetRange(Open);
            if not NoSeriesLine.IsEmpty() then
                Error(
                  CannotAssignNewOnDateErr,
                  NoSeriesCode, UsageDate);
            Error(
                CannotAssignNewErr,
                NoSeriesCode);
        end;

        // If Date Order is required for this No. Series, make sure the usage date is not before the last date used
        NoSeries.Get(NoSeriesCode);
        if NoSeries."Date Order" and (UsageDate < NoSeriesLine."Last Date Used") then begin
            if HideErrorsAndWarnings then
                exit(false);
            Error(
              CannotAssignNewBeforeDateErr,
              NoSeries.Code, NoSeriesLine."Last Date Used");
        end;
        exit(true);
    end;

    procedure PeekNextNo(NoSeriesCode: Code[20]; UsageDate: Date): Code[20]
    var
        NoSeriesLine: Record "No. Series Line";
    begin
        NoSeriesLine."Series Code" := NoSeriesCode;
        exit(PeekNextNo(NoSeriesLine, UsageDate));
    end;

    procedure PeekNextNo(var NoSeriesLine: Record "No. Series Line"; UsageDate: Date): Code[20]
    var
        NoSeriesSingle: Interface "No. Series - Single";
    begin
        if UsageDate = 0D then
            UsageDate := WorkDate();
        if not GetNoSeriesLine(NoSeriesLine, NoSeriesLine."Series Code", UsageDate, false) then
            exit('');

        NoSeriesSingle := GetImplementation(NoSeriesLine);

        exit(NoSeriesSingle.PeekNextNo(NoSeriesLine, UsageDate));
    end;

    procedure TestAreNoSeriesRelated(DefaultNoSeriesCode: Code[20]; RelatedNoSeriesCode: Code[20])
    begin
        if not AreNoSeriesRelated(DefaultNoSeriesCode, RelatedNoSeriesCode) then
            Error(SeriesNotRelatedErr, DefaultNoSeriesCode, RelatedNoSeriesCode);
    end;

    procedure AreNoSeriesRelated(DefaultNoSeriesCode: Code[20]; RelatedNoSeriesCode: Code[20]): Boolean
    var
        NoSeries: Record "No. Series";
        NoSeriesRelationship: Record "No. Series Relationship";
    begin
        // TODO: call TestIsAutomaticNoSeries instead
        if not NoSeries.Get(DefaultNoSeriesCode) then
            exit(false);

        if not NoSeries."Default Nos." then
            Error(
              CannotAssignAutomaticallyErr,
              NoSeries.FieldCaption("Default Nos."), NoSeries.TableCaption(), NoSeries.Code);

        if DefaultNoSeriesCode = RelatedNoSeriesCode then
            exit(true);

        exit(NoSeriesRelationship.Get(DefaultNoSeriesCode, RelatedNoSeriesCode));
    end;


    procedure IsAutomaticNoSeries(NoSeriesCode: Code[20]): Boolean
    var
        NoSeries: Record "No. Series";
    begin
        if not NoSeries.Get(NoSeriesCode) then
            exit(false);
        exit(NoSeries."Default Nos.");
    end;

    procedure TestIsAutomaticNoSeries(NoSeriesCode: Code[20])
    var
        NoSeries: Record "No. Series";
    begin
        if not IsAutomaticNoSeries(NoSeriesCode) then
            Error(CannotAssignAutomaticallyErr, NoSeries.FieldCaption("Default Nos."), NoSeries.TableCaption(), NoSeries.Code);
    end;

    procedure SelectRelatedNoSeries(OriginalNoSeriesCode: Code[20]; DefaultHighlightedNoSeriesCode: Code[20]; var NewNoSeriesCode: Code[20]): Boolean
    var
        NoSeries: Record "No. Series";
        NoSeriesRelationship: Record "No. Series Relationship";
    begin
        // Mark all related series
        NoSeriesRelationship.SetRange(Code, OriginalNoSeriesCode);
        if NoSeriesRelationship.FindSet() then
            repeat
                NoSeries.Code := NoSeriesRelationship."Series Code";
                NoSeries.Mark := true;
            until NoSeriesRelationship.Next() = 0;

        // Mark the original series
        NoSeries.Code := OriginalNoSeriesCode;
        NoSeries.Mark := true;

        // If DefaultHighlightedNoSeriesCode is set, make sure we select it by default on the page
        if DefaultHighlightedNoSeriesCode <> '' then
            NoSeries.Code := DefaultHighlightedNoSeriesCode;

        if Page.RunModal(0, NoSeries) = Action::LookupOK then begin
            NewNoSeriesCode := NoSeries.Code;
            exit(true);
        end;
        exit(false);
    end;
}