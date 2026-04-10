// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Address;

using Microsoft.Finance.VAT.Registration;
using Microsoft.Foundation.Company;
using System.Globalization;
using System.Reflection;
using System.Utilities;

table 9 "Country/Region"
{
    Caption = 'Country/Region';
    LookupPageID = "Countries/Regions";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
            ToolTip = 'Specifies the country/region of the address.';
            NotBlank = true;
        }
        field(2; Name; Text[50])
        {
            Caption = 'Name';
            ToolTip = 'Specifies the country/region of the address.';
        }
        field(4; "ISO Code"; Code[2])
        {
            Caption = 'ISO Code';
            ToolTip = 'Specifies a two-letter country code defined in ISO 3166-1.';
            DataClassification = CustomerContent;

            trigger OnValidate()
            var
                Regex: Codeunit Regex;
            begin
                if "ISO Code" = '' then
                    exit;
                if StrLen("ISO Code") < MaxStrLen("ISO Code") then
                    Error(ISOCodeLengthErr, StrLen("ISO Code"), MaxStrLen("ISO Code"), "ISO Code");
                if not Regex.IsMatch("ISO Code", '^[a-zA-Z]*$') then
                    FieldError("ISO Code", ASCIILetterErr);
            end;
        }
        field(5; "ISO Numeric Code"; Code[3])
        {
            Caption = 'ISO Numeric Code';
            ToolTip = 'Specifies a three-digit code number defined in ISO 3166-1.';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                if "ISO Numeric Code" = '' then
                    exit;
                if StrLen("ISO Numeric Code") < MaxStrLen("ISO Numeric Code") then
                    Error(ISOCodeLengthErr, StrLen("ISO Numeric Code"), MaxStrLen("ISO Numeric Code"), "ISO Numeric Code");
                if not TypeHelper.IsNumeric("ISO Numeric Code") then
                    FieldError("ISO Numeric Code", NumericErr);
            end;
        }
        field(6; "EU Country/Region Code"; Code[10])
        {
            Caption = 'EU Country/Region Code';
            ToolTip = 'Specifies the EU code for the country/region you are doing business with.';
        }
        field(7; "Intrastat Code"; Code[10])
        {
            Caption = 'Intrastat Code';
            ToolTip = 'Specifies an INTRASTAT code for the country/region you are trading with.';
        }
        field(8; "Address Format"; Enum "Country/Region Address Format")
        {
            Caption = 'Address Format';
            ToolTip = 'Specifies the format of the address that is displayed on external-facing documents. You link an address format to a country/region code so that external-facing documents based on cards or documents with that country/region code use the specified address format. NOTE: If the County field is filled in, then the county will be printed above the country/region unless you select the City+County+Post Code option.';
            InitValue = "City+Post Code";

            trigger OnValidate()
            begin
                if xRec."Address Format" <> "Address Format" then begin
                    if "Address Format" = "Address Format"::Custom then
                        InitAddressFormat();
                    if xRec."Address Format" = xRec."Address Format"::Custom then
                        ClearCustomAddressFormat();
                end;
            end;
        }
        field(9; "Contact Address Format"; Option)
        {
            Caption = 'Contact Address Format';
            ToolTip = 'Specifies where you want the contact name to appear in mailing addresses.';
            InitValue = "After Company Name";
            OptionCaption = 'First,After Company Name,Last';
            OptionMembers = First,"After Company Name",Last;
        }
        field(10; "VAT Scheme"; Code[10])
        {
            Caption = 'VAT Scheme';
            ToolTip = 'Specifies the national body that issues the VAT registration number for the country/region in connection with electronic document sending.';
        }
        field(11; "Last Modified Date Time"; DateTime)
        {
            Caption = 'Last Modified Date Time';
            Editable = false;
        }
        field(12; "County Name"; Text[30])
        {
            Caption = 'County Name';
            ToolTip = 'Specifies the name of the county.';
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
        key(Key2; "EU Country/Region Code")
        {
        }
        key(Key3; "Intrastat Code")
        {
        }
        key(Key4; Name)
        {
        }
    }

    fieldgroups
    {
        fieldgroup(Brick; "Code", Name, "VAT Scheme")
        {
        }
        fieldgroup(DropDown; "Code", Name)
        {
        }
    }

    trigger OnDelete()
    var
        VATRegNoFormat: Record "VAT Registration No. Format";
        CountryRegionTranslation: Record "Country/Region Translation";
    begin
        VATRegNoFormat.SetRange("Country/Region Code", Code);
        VATRegNoFormat.DeleteAll();

        CountryRegionTranslation.SetRange("Country/Region Code", Rec.Code);
        if not CountryRegionTranslation.IsEmpty() then
            CountryRegionTranslation.DeleteAll(true);
    end;

    trigger OnInsert()
    begin
        "Last Modified Date Time" := CurrentDateTime;
    end;

    trigger OnModify()
    begin
        "Last Modified Date Time" := CurrentDateTime;
    end;

    trigger OnRename()
    begin
        "Last Modified Date Time" := CurrentDateTime;
    end;

    var
        TypeHelper: Codeunit "Type Helper";

        CountryRegionNotFilledErr: Label 'You must specify a country or region.';
        ISOCodeLengthErr: Label 'The length of the string is %1, but it must be equal to %2 characters. Value: %3.', Comment = '%1, %2 - numbers, %3 - actual value';
        ASCIILetterErr: Label 'must contain ASCII letters only';
        NumericErr: Label 'must contain numbers only';

    procedure IsEUCountry(CountryRegionCode: Code[10]): Boolean
    var
        CountryRegion: Record "Country/Region";
    begin
        if CountryRegionCode = '' then
            Error(CountryRegionNotFilledErr);

        if not CountryRegion.Get(CountryRegionCode) then
            Error(CountryRegionNotFilledErr);

        exit(CountryRegion."EU Country/Region Code" <> '');
    end;

    procedure TranslateName(LanguageCode: Code[10])
    var
        CountryRegionTranslation: Record "Country/Region Translation";
    begin
        if LanguageCode = '' then
            exit;
        if CountryRegionTranslation.Get(Code, LanguageCode) then
            Rec.Name := CountryRegionTranslation.Name;
    end;

    procedure GetTranslatedName(LanguageID: Integer): Text[50]
    var
        Language: Codeunit Language;
        LanguageCode: Code[10];
    begin
        LanguageCode := Language.GetLanguageCode(LanguageID);
        exit(GetTranslatedName(LanguageCode));
    end;

    procedure GetTranslatedName(LanguageCode: Code[10]): Text[50]
    var
        CountryRegionTranslation: Record "Country/Region Translation";
    begin
        if CountryRegionTranslation.Get(Code, LanguageCode) then
            exit(CountryRegionTranslation.Name);
        exit(Name);
    end;

    procedure GetNameInCurrentLanguage(): Text[50]
    var
        Language: Codeunit Language;
    begin
        exit(GetTranslatedName(Language.GetUserLanguageCode()));
    end;

    procedure CreateAddressFormat(CountryCode: Code[10]; LinePosition: Integer; FieldID: Integer): Integer
    var
        CustomAddressFormat: Record "Custom Address Format";
    begin
        CustomAddressFormat.Init();
        CustomAddressFormat."Country/Region Code" := Code;
        CustomAddressFormat."Field ID" := FieldID;
        CustomAddressFormat."Line Position" := LinePosition - 1;
        CustomAddressFormat.Insert();

        if FieldID <> 0 then
            CreateAddressFormatLine(CountryCode, 1, FieldID, CustomAddressFormat."Line No.");

        CustomAddressFormat.BuildAddressFormat();
        CustomAddressFormat.Modify();

        exit(CustomAddressFormat."Line No.");
    end;

    procedure CreateAddressFormatLine(CountryCode: Code[10]; FieldPosition: Integer; FieldID: Integer; LineNo: Integer)
    var
        CustomAddressFormatLine: Record "Custom Address Format Line";
    begin
        CustomAddressFormatLine.Init();
        CustomAddressFormatLine."Country/Region Code" := CountryCode;
        CustomAddressFormatLine."Line No." := LineNo;
        CustomAddressFormatLine."Field Position" := FieldPosition - 1;
        CustomAddressFormatLine.Validate("Field ID", FieldID);
        CustomAddressFormatLine.Insert();
    end;

    procedure InitAddressFormat()
    var
        CompanyInformation: Record "Company Information";
        CustomAddressFormat: Record "Custom Address Format";
        LineNo: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInitAddressFormat(Rec, IsHandled);
        if IsHandled then
            exit;

        CreateAddressFormat(Code, 1, CompanyInformation.FieldNo(Name));
        CreateAddressFormat(Code, 2, CompanyInformation.FieldNo("Name 2"));
        CreateAddressFormat(Code, 3, CompanyInformation.FieldNo("Contact Person"));
        CreateAddressFormat(Code, 4, CompanyInformation.FieldNo(Address));
        CreateAddressFormat(Code, 5, CompanyInformation.FieldNo("Address 2"));
        case xRec."Address Format" of
            xRec."Address Format"::"City+Post Code":
                begin
                    LineNo := CreateAddressFormat(Code, 6, 0);
                    CreateAddressFormatLine(Code, 1, CompanyInformation.FieldNo(City), LineNo);
                    CreateAddressFormatLine(Code, 2, CompanyInformation.FieldNo("Post Code"), LineNo);
                end;
            xRec."Address Format"::"Post Code+City",
            xRec."Address Format"::"Blank Line+Post Code+City":
                begin
                    LineNo := CreateAddressFormat(Code, 6, 0);
                    CreateAddressFormatLine(Code, 1, CompanyInformation.FieldNo("Post Code"), LineNo);
                    CreateAddressFormatLine(Code, 2, CompanyInformation.FieldNo(City), LineNo);
                end;
            xRec."Address Format"::"City+County+Post Code":
                begin
                    LineNo := CreateAddressFormat(Code, 6, 0);
                    CreateAddressFormatLine(Code, 1, CompanyInformation.FieldNo(City), LineNo);
                    CreateAddressFormatLine(Code, 2, CompanyInformation.FieldNo(County), LineNo);
                    CreateAddressFormatLine(Code, 3, CompanyInformation.FieldNo("Post Code"), LineNo);
                end;
        end;
        CreateAddressFormat(Rec.Code, 7, CompanyInformation.FieldNo("Country/Region Code"));

        if LineNo <> 0 then begin
            CustomAddressFormat.Get(Code, LineNo);
            CustomAddressFormat.BuildAddressFormat();
            CustomAddressFormat.Modify();
        end;
    end;

    local procedure ClearCustomAddressFormat()
    var
        CustomAddressFormat: Record "Custom Address Format";
    begin
        CustomAddressFormat.SetRange("Country/Region Code", Code);
        CustomAddressFormat.DeleteAll(true);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitAddressFormat(var CountryRegion: Record "Country/Region"; var IsHandled: Boolean)
    begin
    end;
}
