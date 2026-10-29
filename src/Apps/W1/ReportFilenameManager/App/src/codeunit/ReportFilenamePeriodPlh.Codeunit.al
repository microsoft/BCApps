// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Reporting.FileNaming;

using Microsoft.Finance.FinancialReports;

codeunit 8141 "Report Filename Period Plh." implements "Report Filename Placeholder"
{
    Access = Internal;

    // The period a financial report (report 25) was run for. It is a variable of the running
    // report, not a field: Report Filename Fin. Rep. Sub. captures it and Report Filename Context
    // hands it over. The capture mirrors report 25's default-date and Period Ending rules, so a
    // change to those rules must be followed there.

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
        // Other reports take a period as a filter, named by that filter's own placeholder.
        exit(TableNo = Database::"Financial Report");
    end;

    procedure SpeaksForARunOfManyRecords(): Boolean
    begin
        exit(true);
    end;

    procedure ExampleWithoutDocument(): Text
    begin
        // Never reached: TryResolve answers the picker itself.
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

        // An unopened reference means the picker is asking for an example; a real run always
        // passes the financial report, so sample dates never reach a real file name.
        if DocumentRecRef.Number() = 0 then begin
            PlaceholderValue := Joined(Pattern,
                ReportFilenameMgt.FormatSampleDate(Pattern."Date Format"), ReportFilenameMgt.FormatSampleDate(Pattern."Date Format", true));
            exit(PlaceholderValue <> '');
        end;

        // No captured period (Test Pattern, or a list or open-ended period): decline the pattern
        // rather than leave a gap in the name.
        if not ReportFilenameContext.TryGetNamingPeriod(DocumentRecRef, FirstDate, LastDate) then
            exit(false);

        // No first date is report 25's "Period Ending": only the last date is shown.
        if FirstDate = 0D then
            PlaceholderValue := ReportFilenameMgt.FormatPatternDate(LastDate, Pattern."Date Format")
        else
            PlaceholderValue := Joined(Pattern,
                ReportFilenameMgt.FormatPatternDate(FirstDate, Pattern."Date Format"), ReportFilenameMgt.FormatPatternDate(LastDate, Pattern."Date Format"));
        exit(PlaceholderValue <> '');
    end;

    /// <summary>
    /// Joins the ends as a filter placeholder writes a range, or returns one date when both ends
    /// format the same (a January period in Year Month format).
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
