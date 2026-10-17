// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
codeunit 50116 "Report Filename Company Plh." implements "Report Filename Placeholder"
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
        // The company name is read from Company Information, which every company has. It does
        // not touch the document, so there is no kind of document it cannot be used on.
        exit(true);
    end;

    procedure SpeaksForARunOfManyRecords(): Boolean
    begin
        // The company is the same for every record a run covers, so it names a run of two
        // hundred as truthfully as it names one.
        exit(true);
    end;

    procedure ExampleWithoutDocument(): Text
    begin
        // Always resolves - it needs no document - so the picker never has to fall back here.
        exit('');
    end;

    procedure TryResolve(var Pattern: Record "Report Filename Pattern"; ReportId: Integer; var DocumentRecRef: RecordRef; LanguageCode: Code[10]; var PlaceholderValue: Text): Boolean
    var
        CompanyInformation: Record "Company Information";
    begin
        // The display name, not CompanyName(). They routinely differ, and the display name is
        // the one an administrator recognises as their company.
        if not CompanyInformation.Get() then
            exit(false);

        PlaceholderValue := CompanyInformation.Name;
        exit(PlaceholderValue <> '');
    end;

    var
        // The canonical name is what a saved binding records, so it is language-invariant and
        // locked.
        CanonicalTok: Label 'Your Company Name', Locked = true;
        DisplayLbl: Label 'Your Company Name';
        DescriptionLbl: Label 'Your company''s name, as Company Information holds it';
}
