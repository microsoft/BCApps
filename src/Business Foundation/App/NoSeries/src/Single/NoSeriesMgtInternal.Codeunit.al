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
        CannotAssignNumbersGreaterThanErr: Label 'You cannot assign numbers greater than %1 from the number series %2.', Comment = '%1=Last No.,%2=No. Series Code';

    procedure EnsureLastNoUsedIsWithinValidRange(NoSeriesLine: Record "No. Series Line"; NoErrorsOrWarnings: Boolean): Boolean
    begin
        if not NoIsWithinValidRange(NoSeriesLine."Last No. Used", NoSeriesLine."Starting No.", NoSeriesLine."Ending No.") then begin
            if NoErrorsOrWarnings then
                exit(false);
            Error(
              CannotAssignNumbersGreaterThanErr,
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
              CannotAssignNumbersGreaterThanErr,
              NoSeriesLine."Ending No.", NoSeriesLine."Series Code");
        end;
        exit(true);
    end;

#pragma warning disable AA0137 // StartingNo is unused in temp patch
    local procedure NoIsWithinValidRange(CurrentNo: Code[20]; StartingNo: Code[20]; EndingNo: Code[20]): Boolean
    begin
        if (EndingNo = '') then
            exit(true);
        exit(CurrentNo <= EndingNo);

        // if CurrentNo = '' then
        //     exit(false);
        // if (StartingNo <> '') and (CurrentNo < StartingNo) then
        //     exit(false);
        // if (EndingNo <> '') and (CurrentNo > EndingNo) then
        //     exit(false);

        // if StrLen(CurrentNo) < StrLen(StartingNo) then
        //     exit(false);
        // if StrLen(CurrentNo) > StrLen(EndingNo) then
        //     exit(false);

        // exit(true)
    end;
#pragma warning restore AA0137 // StartingNo is unused in temp patch
}