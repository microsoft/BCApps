// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
codeunit 50117 "Report Filename Created Plh." implements "Report Filename Placeholder"
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
        // The date the file is produced is a property of the run, not of the document, so it
        // resolves whatever the pattern names - or nothing at all.
        exit(true);
    end;

    procedure SpeaksForARunOfManyRecords(): Boolean
    begin
        // One run is produced at one moment, whatever it covered.
        exit(true);
    end;

    procedure ExampleWithoutDocument(): Text
    begin
        // Always resolves - it needs no document - so the picker never has to fall back here.
        exit('');
    end;

    procedure TryResolve(var Pattern: Record "Report Filename Pattern"; ReportId: Integer; var DocumentRecRef: RecordRef; LanguageCode: Code[10]; var PlaceholderValue: Text): Boolean
    var
        ReportFilenameMgt: Codeunit "Report Filename Mgt.";
    begin
        // Rendered through the pattern's own date format, which is a validated list rather than
        // a regional setting: a date in a file name is an identifier, so it has to sort and to
        // mean the same thing to everybody who receives the file.
        PlaceholderValue := ReportFilenameMgt.FormatPatternDate(Today(), Pattern."Date Format");
        exit(PlaceholderValue <> '');
    end;

    var
        CanonicalTok: Label 'Report Run Date', Locked = true;
        DisplayLbl: Label 'Report Run Date';
        DescriptionLbl: Label 'The date the report was run';
}
