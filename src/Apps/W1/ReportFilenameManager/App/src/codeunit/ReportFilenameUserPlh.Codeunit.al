// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Reporting.FileNaming;

codeunit 8133 "Report Filename User Plh." implements "Report Filename Placeholder"
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
        exit(true);
    end;

    procedure SpeaksForARunOfManyRecords(): Boolean
    begin
        exit(true);
    end;

    procedure ExampleWithoutDocument(): Text
    begin
        exit('');
    end;

    procedure TryResolve(var Pattern: Record "Report Filename Pattern"; ReportId: Integer; var DocumentRecRef: RecordRef; LanguageCode: Code[10]; var PlaceholderValue: Text): Boolean
    begin
        PlaceholderValue := UserId();
        exit(PlaceholderValue <> '');
    end;

    var
        CanonicalTok: Label 'Report Run By', Locked = true;
        DisplayLbl: Label 'Report Run By';
        DescriptionLbl: Label 'The user who ran the report';
}
