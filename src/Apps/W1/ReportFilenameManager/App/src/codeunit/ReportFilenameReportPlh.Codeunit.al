// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Reporting.FileNaming;

using System.Globalization;
using System.Reflection;

codeunit 8134 "Report Filename Report Plh." implements "Report Filename Placeholder"
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
        // The caption comes from the running report, not the pattern's Report criterion,
        // so it resolves on any pattern.
        exit(true);
    end;

    procedure SpeaksForARunOfManyRecords(): Boolean
    begin
        exit(true);
    end;

    procedure ExampleWithoutDocument(): Text
    begin
        // Not blank: a pattern with no Report has no caption to show while it is set up, and a
        // blank shape would fail the whole example.
        exit(ShapeLbl);
    end;

    procedure TryResolve(var Pattern: Record "Report Filename Pattern"; ReportId: Integer; var DocumentRecRef: RecordRef; LanguageCode: Code[10]; var PlaceholderValue: Text): Boolean
    var
        LanguageMgt: Codeunit Language;
        PreviousGlobalLanguage: Integer;
    begin
        // Read in the document's language so the name does not depend on who ran the report.
        // Matching the rendered report where that language's translation is not installed is the
        // subject of ask 1.
        PreviousGlobalLanguage := GlobalLanguage();
        GlobalLanguage(LanguageMgt.GetLanguageIdOrDefault(LanguageCode));

        // Isolated in a try function so the session language is restored on every path.
        if not TryReadCaption(ReportId, PlaceholderValue) then
            Clear(PlaceholderValue);

        GlobalLanguage(PreviousGlobalLanguage);
        exit(PlaceholderValue <> '');
    end;

    [TryFunction]
    local procedure TryReadCaption(ReportId: Integer; var PlaceholderValue: Text)
    var
        ReportMetadata: Record "Report Metadata";
    begin
        if ReportMetadata.Get(ReportId) then
            PlaceholderValue := ReportMetadata.Caption;
    end;

    var
        CanonicalTok: Label 'Report Name', Locked = true;
        DisplayLbl: Label 'Report Name';
        DescriptionLbl: Label 'The name of the report that is run';
        ShapeLbl: Label 'Report Name';
}
