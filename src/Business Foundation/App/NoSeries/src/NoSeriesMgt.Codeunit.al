// remove

// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Foundation.NoSeries;

codeunit 281 NoSeriesMgt
{
    Permissions = tabledata "No. Series Line" = rimd,
                  tabledata "No. Series" = r;

    var
        CannotAssignAutomaticallyErr: Label 'It is not possible to assign numbers automatically. If you want the program to assign numbers automatically, please activate %1 in %2 %3.', Comment = '%1=Default Nos. setting,%2=No. Series table caption,%3=No. Series Code';
        CannotAssignNewOnDateErr: Label 'You cannot assign new numbers from the number series %1 on %2.', Comment = '%1=No. Series Code,%2=Date';
        CannotAssignNewErr: Label 'You cannot assign new numbers from the number series %1.', Comment = '%1=No. Series Code';
        CannotAssignNewBeforeDateErr: Label 'You cannot assign new numbers from the number series %1 on a date before %2.', Comment = '%1=No. Series Code,%2=Date';
        CannotAssignGreaterErr: Label 'You cannot assign numbers greater than %1 from the number series %2.', Comment = '%1=Last No.,%2=No. Series Code';

    procedure StatfulGetNextNo(NoSeriesCode: Code[20])
    begin
        // TODO: 
    end;

    procedure StateLessGetNextNo(NoSeriesCode: Code[20]; SeriesDate: Date): Code[20]
    begin
        exit(StateLessGetNextNo(NoSeriesCode, SeriesDate, false));
    end;

    procedure InitSeries(DefaultNoSeriesCode: Code[20]; OldNoSeriesCode: Code[20]; NewDate: Date; var NewNo: Code[20]; var NewNoSeriesCode: Code[20])
    var
        NoSeries: Record "No. Series";
        NoSeriesManagement: Codeunit NoSeriesManagement;
    begin
        if NewNo = '' then begin
            NoSeries.Get(DefaultNoSeriesCode);
            if not NoSeries."Default Nos." then
                Error(
                  CannotAssignAutomaticallyErr,
                  NoSeries.FieldCaption("Default Nos."), NoSeries.TableCaption(), NoSeries.Code);
            if OldNoSeriesCode <> '' then begin
                FilterSeries(NoSeries, DefaultNoSeriesCode);
                NoSeries.SetRange(code, OldNoSeriesCode);
                if not NoSeries.FindFirst() then
                    NoSeries.Get(DefaultNoSeriesCode);
            end;
            NewNo := StateLessGetNextNo(NoSeries.Code, NewDate, true);
            NewNoSeriesCode := NoSeries.Code;
        end else
            NoSeriesManagement.TestManual(DefaultNoSeriesCode);
    end;

    local procedure FilterSeries(var NoSeries: Record "No. Series"; NoSeriesCode: Code[20])
    var
        NoSeriesRelationship: Record "No. Series Relationship";
    // IsHandled: Boolean;
    begin
        /*IsHandled := false;
        OnBeforeFilterSeries(GlobalNoSeries, GlobalNoSeriesCode, IsHandled);
        if IsHandled then
            exit;*/

        NoSeries.Reset();
        NoSeriesRelationship.SetRange(Code, NoSeriesCode);
        if NoSeriesRelationship.FindSet() then
            repeat
                NoSeries.Code := NoSeriesRelationship."Series Code";
                NoSeries.Mark := true;
            until NoSeriesRelationship.Next() = 0;
        if NoSeries.Get(NoSeriesCode) then
            NoSeries.Mark := true;
        NoSeries.MarkedOnly := true;
    end;

    procedure StateLessGetNextNo(NoSeriesCode: Code[20]; SeriesDate: Date; HideErrorsAndWarnings: Boolean): Code[20]
    var
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
        NoSeriesManagement: Codeunit NoSeriesManagement;
        NoSeriesInterface: Interface "No. Series - Single";
        UpdateLastUsedDate: Boolean;
    begin
        if SeriesDate = 0D then
            SeriesDate := WorkDate();
        NoSeries.Get(NoSeriesCode);
        // Find the latest No. Series Line that is still valid
        NoSeriesManagement.SetNoSeriesLineFilter(NoSeriesLine, NoSeriesCode, SeriesDate);
        if not NoSeriesLine.FindFirst() then begin
            if HideErrorsAndWarnings then
                exit('');
            NoSeriesLine.SetRange("Starting Date");
            if not NoSeriesLine.IsEmpty() then
                Error(
                  CannotAssignNewOnDateErr,
                  NoSeriesCode, SeriesDate);
            Error(
              CannotAssignNewErr,
              NoSeriesCode);
        end;

        if NoSeries."Date Order" and (SeriesDate < NoSeriesLine."Last Date Used") then begin
            if HideErrorsAndWarnings then
                exit('');
            Error(
              CannotAssignNewBeforeDateErr,
              NoSeries.Code, NoSeriesLine."Last Date Used");
        end;
        // TODO: Update last used date!!!

        if NoSeriesLine."Allow Gaps in Nos." then begin
            NoSeriesInterface := Enum::"No. Series Implementation"::Sequence;
            NoSeriesLine."Last No. Used" := NoSeriesInterface.GetNextNo(NoSeriesLine, SeriesDate);
        end else
            if NoSeriesLine."Last No. Used" = '' then begin
                if HideErrorsAndWarnings and (NoSeriesLine."Starting No." = '') then
                    exit('');
                NoSeriesLine.TestField("Starting No.");
                NoSeriesLine."Last No. Used" := NoSeriesLine."Starting No.";
            end else
                if NoSeriesLine."Increment-by No." <= 1 then
                    NoSeriesLine."Last No. Used" := IncStr(NoSeriesLine."Last No. Used")
                else
                    NoSeriesManagement.IncrementNoText(NoSeriesLine."Last No. Used", NoSeriesLine."Increment-by No.");

        // Ensure number is within the valid range
        if (NoSeriesLine."Ending No." <> '') and
           (NoSeriesLine."Last No. Used" > NoSeriesLine."Ending No.")
        then begin
            if HideErrorsAndWarnings then
                exit('');
            Error(
              CannotAssignGreaterErr,
              NoSeriesLine."Ending No.", NoSeriesCode);
        end;

        if (NoSeriesLine."Ending No." <> '') and
           (NoSeriesLine."Warning No." <> '') and
           (NoSeriesLine."Last No. Used" >= NoSeriesLine."Warning No.")
        then begin
            if HideErrorsAndWarnings then
                exit('');
            Message(
              CannotAssignGreaterErr,
              NoSeriesLine."Ending No.", NoSeriesCode);
        end;

        // TODO: Make sure certain fields are up to date
        if NoSeriesLine.Open and (not NoSeriesLine."Allow Gaps in Nos." or UpdateLastUsedDate) then
            NoSeriesManagement.ModifyNoSeriesLine(NoSeriesLine);

        NoSeriesManagement.OnAfterGetNextNo3(NoSeriesLine, true);

        exit(NoSeriesLine."Last No. Used");
    end;
}