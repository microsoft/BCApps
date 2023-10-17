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
        Text007Err: Label 'You cannot assign numbers greater than %1 from the number series %2.', Comment = '%1=Last No.,%2=No. Series Code';

    procedure EnsureLastNoUsedIsWithinValidRange(NoSeriesLine: Record "No. Series Line"; NoErrorsOrWarnings: Boolean): Boolean
    begin
        if (NoSeriesLine."Ending No." <> '') and
                       (NoSeriesLine."Last No. Used" > NoSeriesLine."Ending No.")
                    then begin
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
}