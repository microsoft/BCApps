// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Reporting.FileNaming;

using Microsoft.Foundation.Company;

codeunit 8131 "Report Filename Company Plh." implements "Report Filename Placeholder"
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
    var
        CompanyInformation: Record "Company Information";
    begin
        // Company Information's name, the one reports print, rather than CompanyName(): it can be
        // edited and longer (100 characters against 30), so the two can differ.
        if not CompanyInformation.Get() then
            exit(false);

        PlaceholderValue := CompanyInformation.Name;
        exit(PlaceholderValue <> '');
    end;

    var
        CanonicalTok: Label 'Your Company Name', Locked = true;
        DisplayLbl: Label 'Your Company Name';
        DescriptionLbl: Label 'Your company''s name, as Company Information holds it';
}
