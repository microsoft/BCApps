// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
codeunit 50118 "Report Filename User Plh." implements "Report Filename Placeholder"
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
        // Who ran the report is a property of the session. No document is read.
        exit(true);
    end;

    procedure SpeaksForARunOfManyRecords(): Boolean
    begin
        // One person produced the run, whatever it covered.
        exit(true);
    end;

    procedure ExampleWithoutDocument(): Text
    begin
        // Always resolves - it needs no document - so the picker never has to fall back here.
        exit('');
    end;

    procedure TryResolve(var Pattern: Record "Report Filename Pattern"; ReportId: Integer; var DocumentRecRef: RecordRef; LanguageCode: Code[10]; var PlaceholderValue: Text): Boolean
    begin
        // The only placeholder in the design whose value depends on who ran the report, which is
        // what an administrator is asking for when they choose it.
        PlaceholderValue := UserId();
        exit(PlaceholderValue <> '');
    end;

    var
        // Not User ID: posted invoices, issued reminders and many other tables have a User ID field
        // - who posted or issued the document - and both values are wanted in a name.
        CanonicalTok: Label 'Report Run By', Locked = true;
        DisplayLbl: Label 'Report Run By';
        DescriptionLbl: Label 'The user who ran the report';
}
