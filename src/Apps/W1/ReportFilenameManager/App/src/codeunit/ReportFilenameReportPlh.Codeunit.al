// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
codeunit 50119 "Report Filename Report Plh." implements "Report Filename Placeholder"
{
    Access = Internal;

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
        // The caption comes from the report that is running, which TryResolve receives as a
        // parameter - not from the pattern's own criterion, which is zero on a pattern that
        // applies to every report. So this resolves even on a pattern that names no report
        // and no document, and it is offered everywhere.
        exit(true);
    end;

    procedure SpeaksForARunOfManyRecords(): Boolean
    begin
        // One report produced the run, whatever it covered.
        exit(true);
    end;

    procedure ExampleWithoutDocument(): Text
    begin
        // This needs no document, but it does need a report - and a pattern need not name one.
        // A pattern that applies to every report about a kind of record has Report blank, and
        // there is then no caption to read while it is being set up, even though one resolves
        // perfectly well the moment a report runs.
        //
        // Returning nothing here said the opposite, and the card believed it: a blank shape
        // fails the whole example, and the card then reported that a placeholder named something that
        // no longer exists - which was not true of any placeholder in the pattern, and sent whoever
        // read it looking for a deleted field.
        //
        // The shape is the value's own name, which is what this design already shows for a text
        // field: what lands there is a report's caption, and which report it is depends on the
        // report that runs.
        exit(ShapeLbl);
    end;

    procedure TryResolve(var Pattern: Record "Report Filename Pattern"; ReportId: Integer; var DocumentRecRef: RecordRef; LanguageCode: Code[10]; var PlaceholderValue: Text): Boolean
    var
        LanguageMgt: Codeunit Language;
        PreviousGlobalLanguage: Integer;
    begin
        // A report caption is translated, so reading it in the session's language would name
        // the same document differently depending on who rendered it - the defect this design
        // exists to remove. It is read in the document's language, which is the language
        // Business Central renders the document's contents in when that language's translation is
        // installed. When it is not, the two part (measured 8 October): the report renders in the
        // printing user's language, while this read falls back elsewhere (English in one
        // environment, Danish in another), and no method says whether a translation is installed.
        // Left as Business Central's own read until Microsoft meets ask 1.
        PreviousGlobalLanguage := GlobalLanguage();
        GlobalLanguage(LanguageMgt.GetLanguageIdOrDefault(LanguageCode));

        // The read is isolated so that the language is put back on every path. Leaving the
        // session in the document's language would change every caption the user sees next,
        // and this procedure is not itself a try function despite its name.
        if not TryReadCaption(ReportId, PlaceholderValue) then
            Clear(PlaceholderValue);

        GlobalLanguage(PreviousGlobalLanguage);
        exit(PlaceholderValue <> '');
    end;

    /// <summary>
    /// The caption of the report actually running - not the pattern's criterion, which is zero
    /// on a pattern that applies to every report.
    /// </summary>
    [TryFunction]
    local procedure TryReadCaption(ReportId: Integer; var PlaceholderValue: Text)
    var
        ReportMetadata: Record "Report Metadata";
    begin
        if ReportMetadata.Get(ReportId) then
            PlaceholderValue := ReportMetadata.Caption;
    end;

    var
        // Report Name, as the Report Inbox and Report Selections caption the same value.
        CanonicalTok: Label 'Report Name', Locked = true;
        DisplayLbl: Label 'Report Name';
        DescriptionLbl: Label 'The name of the report that is run';
        ShapeLbl: Label 'Report Name';
}
