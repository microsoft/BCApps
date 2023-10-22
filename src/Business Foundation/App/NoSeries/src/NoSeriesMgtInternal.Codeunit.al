// remove

// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Foundation.NoSeries;

codeunit 282 NoSeriesMgtInternal
{
    Access = Internal;
    SingleInstance = true; // TODO: ... this is to check if a warning was already sent....
    Permissions = tabledata "No. Series Line" = rimd,
#if not CLEAN24
#pragma warning disable AL0432
                  tabledata "No. Series Line Sales" = rimd,
                  tabledata "No. Series Line Purchase" = rimd,
#pragma warning restore AL0432
#endif
                  tabledata "No. Series" = r;

    var
        LastWarningNoSeriesCode: Code[20];
        Text004Err: Label 'You cannot assign new numbers from the number series %1 on %2.', Comment = '%1=No. Series Code,%2=Date';
        Text005Err: Label 'You cannot assign new numbers from the number series %1.', Comment = '%1=No. Series Code';
        Text006Err: Label 'You cannot assign new numbers from the number series %1 on a date before %2.', Comment = '%1=No. Series Code,%2=Date';
        Text007Err: Label 'You cannot assign numbers greater than %1 from the number series %2.', Comment = '%1=Last No.,%2=No. Series Code';

    procedure EnsureLastNoUsedIsWithinValidRange(NoSeriesLine: Record "No. Series Line"; NoErrorsOrWarnings: Boolean): Boolean
    begin
        //
        // Todo. this check is not good enough. it uses Str > Str but B0001 is greater than A9999 and that makes it fail. The issue happens when a No. is given that doesn't match the lines pattern and happens to be > than the ending number.
        // If you give it something with a < than the ending number it does not fail.
        //ex: Given ending No. INV12345 -> A99999 does not fail but X00001 would.
        // This function should check the pattern as well.
        //

        // number is > than start
        // number is < than end
        // length is => start
        // length is <= end

        if not NoIsWithinValidRange(NoSeriesLine."Last No. Used", NoSeriesLine."Starting No.", NoSeriesLine."Ending No.") then begin
            if NoErrorsOrWarnings then
                exit(false);
            Error(
              Text007Err,
              NoSeriesLine."Ending No.", NoSeriesLine."Series Code");
        end;

        if (NoSeriesLine."Ending No." <> '') and
           (NoSeriesLine."Warning No." <> '') and
           (NoSeriesLine."Last No. Used" >= NoSeriesLine."Warning No.") and
           (NoSeriesLine."Series Code" <> LastWarningNoSeriesCode)
        // and (TryNoSeriesCode = '')
        then begin
            if NoErrorsOrWarnings then
                exit(false);
            LastWarningNoSeriesCode := NoSeriesLine."Series Code";
            Message(
              Text007Err,
              NoSeriesLine."Ending No.", NoSeriesLine."Series Code");
        end;
        exit(true);
    end;

    local procedure NoIsWithinValidRange(CurrentNo: Code[20]; StartingNo: Code[20]; EndingNo: Code[20]): Boolean
    begin
        if CurrentNo = '' then
            exit(false);
        if (StartingNo <> '') and (CurrentNo < StartingNo) then
            exit(false);
        if (EndingNo <> '') and (CurrentNo > EndingNo) then
            exit(false);

        if StrLen(CurrentNo) < StrLen(StartingNo) then
            exit(false);
        if StrLen(CurrentNo) > StrLen(EndingNo) then
            exit(false);

        exit(true)
    end;

    procedure FindNoSeriesLine(NoSeriesCode: Code[20]; SeriesDate: Date; ModifySeries: Boolean; NoErrorsOrWarnings: Boolean; var NoSeriesLine: Record "No. Series Line"): Boolean
    var
        NoSeries: Record "No. Series";
        NoSeriesMgt: Codeunit NoSeriesMgt;
        UpdateLastUsedDate: Boolean;
    begin
        if SeriesDate = 0D then
            SeriesDate := WorkDate();

        NoSeries.Get(NoSeriesCode);
        NoSeriesMgt.SetNoSeriesLineFilter(NoSeriesLine, NoSeriesCode, SeriesDate);
        if not NoSeriesLine.FindFirst() then begin
            if NoErrorsOrWarnings then
                exit(false);
            NoSeriesLine.SetRange("Starting Date");
            if not NoSeriesLine.IsEmpty() then
                Error(
                  Text004Err,
                  NoSeriesCode, SeriesDate);
            Error(
              Text005Err,
              NoSeriesCode);
        end;
        UpdateLastUsedDate := NoSeriesLine."Last Date Used" <> SeriesDate;
        if ModifySeries and (not NoSeriesLine."Allow Gaps in Nos." or UpdateLastUsedDate) then begin
            NoSeriesLine.LockTable();
            NoSeriesLine.Find();
        end;

        if NoSeries."Date Order" and (SeriesDate < NoSeriesLine."Last Date Used") then begin
            if NoErrorsOrWarnings then
                exit(false);
            Error(
              Text006Err,
              NoSeries.Code, NoSeriesLine."Last Date Used");
        end;
        exit(true);
    end;
}