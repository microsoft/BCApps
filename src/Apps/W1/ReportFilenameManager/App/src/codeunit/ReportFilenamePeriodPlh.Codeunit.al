// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
codeunit 50126 "Report Filename Period Plh." implements "Report Filename Placeholder"
{
    Access = Internal;

    // The period a financial report was run for - the dates typed on report 25's request page,
    // the period the overview passed in, or the one a schedule's date formulas work out. Raised by
    // the user on 15 September, over a Balance Sheet printed for 01-01-26..31-12-26.
    //
    // Computed rather than a field, because the period is not held on any record: it is a
    // variable of the running report. Report Filename Fin. Rep. Sub. captures it as the request
    // page closes, or as a schedule starts, and Report Filename Context hands it over for the one
    // name it belongs to. Named Period after report 25's own words for it - "Period", and "Period
    // Ending" where the report shows only the last date.
    //
    // The capture follows report 25's own rules for its default dates and for Period Ending, so a
    // change to those rules in report 25 has to be followed in Report Filename Fin. Rep. Sub.

    procedure CanonicalName(): Text
    begin
        exit(CanonicalTok);
    end;

    procedure DisplayName(): Text
    begin
        exit(DisplayLbl);
    end;

    procedure Description(): Text
    begin
        exit(DescriptionLbl);
    end;

    procedure IsTableSupported(TableNo: Integer): Boolean
    begin
        // Only a financial report has a period of its own. Every other report that runs for a
        // period takes it as a filter, and is named from it by that filter's own placeholder.
        exit(TableNo = Database::"Financial Report");
    end;

    procedure SpeaksForARunOfManyRecords(): Boolean
    begin
        // A run has one period, however much it covers.
        exit(true);
    end;

    procedure ExampleWithoutDocument(): Text
    begin
        // Never reached: TryResolve answers the picker itself, in the pattern's own date format.
        exit('');
    end;

    procedure TryResolve(var Pattern: Record "Report Filename Pattern"; ReportId: Integer; var DocumentRecRef: RecordRef; LanguageCode: Code[10]; var PlaceholderValue: Text): Boolean
    var
        ReportFilenameContext: Codeunit "Report Filename Context";
        ReportFilenameMgt: Codeunit "Report Filename Mgt.";
        FirstDate: Date;
        LastDate: Date;
    begin
        PlaceholderValue := '';

        // An unopened reference is how Available Placeholders and the example on the card ask what
        // the value looks like (Filename Placeholder Mgt.ComputedExample). A real run always hands
        // over the financial report it names, so this branch can never put sample dates into a
        // real file name.
        if DocumentRecRef.Number() = 0 then begin
            PlaceholderValue := Joined(Pattern,
                ReportFilenameMgt.FormatSampleDate(Pattern."Date Format"), ReportFilenameMgt.FormatSampleDate(Pattern."Date Format", true));
            exit(PlaceholderValue <> '');
        end;

        // No period captured for this financial report - Test Pattern, or a run whose period is a
        // list or open at one end - declines, and the pattern with it, as the filter placeholders
        // do: a name with a gap where the period should be is worse than Business Central's own.
        if not ReportFilenameContext.TryGetNamingPeriod(DocumentRecRef, FirstDate, LastDate) then
            exit(false);

        // No first date is report 25's "Period Ending": the report shows the last date alone,
        // so the name does too.
        if FirstDate = 0D then
            PlaceholderValue := ReportFilenameMgt.FormatPatternDate(LastDate, Pattern."Date Format")
        else
            PlaceholderValue := Joined(Pattern,
                ReportFilenameMgt.FormatPatternDate(FirstDate, Pattern."Date Format"), ReportFilenameMgt.FormatPatternDate(LastDate, Pattern."Date Format"));
        exit(PlaceholderValue <> '');
    end;

    /// <summary>
    /// A period written as a filter placeholder writes a range: the two ends joined by the
    /// pattern's Separator, Range Word and Separator, or one date when both ends read the same in
    /// the pattern's date format - a January period in Year Month format is one month, not
    /// "2026-01-to-2026-01".
    /// </summary>
    local procedure Joined(var Pattern: Record "Report Filename Pattern"; FirstText: Text; LastText: Text): Text
    var
        ReportFilenameMgt: Codeunit "Report Filename Mgt.";
    begin
        if (FirstText = '') or (LastText = '') then
            exit('');
        if FirstText = LastText then
            exit(FirstText);
        exit(FirstText + ReportFilenameMgt.RangeJoinOf(Pattern) + LastText);
    end;

    var
        CanonicalTok: Label 'Period', Locked = true;
        DisplayLbl: Label 'Period';
        DescriptionLbl: Label 'The period the financial report was run for, as its request page or schedule set it';
}
