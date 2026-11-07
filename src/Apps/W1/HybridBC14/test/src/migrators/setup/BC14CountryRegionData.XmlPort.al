// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14.Tests;

using Microsoft.DataMigration.BC14Reimplementation;

xmlport 148917 "BC14 Country/Region Data"
{
    Caption = 'BC14 Country/Region buffer data';
    Direction = Both;
    FieldSeparator = ',';
    RecordSeparator = '<CR><LF>';
    Format = VariableText;
    FormatEvaluate = Xml;

    schema
    {
        textelement(root)
        {
            tableelement(BC14CountryRegion; "BC14 Country/Region")
            {
                AutoSave = false;
                XmlName = 'BC14CountryRegion';

                textelement(Code) { }
                textelement(Name) { }
                textelement(ISOCode) { }
                textelement(ISONumericCode) { }
                textelement(EUCountryRegionCode) { }
                textelement(IntrastatCode) { }
                textelement(AddressFormat) { }
                textelement(ContactAddressFormat) { }
                textelement(VATScheme) { }
                textelement(CountyName) { }

                trigger OnBeforeInsertRecord()
                var
                    NewBC14CountryRegion: Record "BC14 Country/Region";
                begin
                    if CaptionRow then begin
                        CaptionRow := false;
                        currXMLport.Skip();
                        exit;
                    end;

                    NewBC14CountryRegion.Init();
                    NewBC14CountryRegion.Code := CopyStr(Code, 1, MaxStrLen(NewBC14CountryRegion.Code));
                    NewBC14CountryRegion.Name := CopyStr(Name, 1, MaxStrLen(NewBC14CountryRegion.Name));
                    NewBC14CountryRegion."ISO Code" := CopyStr(ISOCode, 1, MaxStrLen(NewBC14CountryRegion."ISO Code"));
                    NewBC14CountryRegion."ISO Numeric Code" := CopyStr(ISONumericCode, 1, MaxStrLen(NewBC14CountryRegion."ISO Numeric Code"));
                    NewBC14CountryRegion."EU Country/Region Code" := CopyStr(EUCountryRegionCode, 1, MaxStrLen(NewBC14CountryRegion."EU Country/Region Code"));
                    NewBC14CountryRegion."Intrastat Code" := CopyStr(IntrastatCode, 1, MaxStrLen(NewBC14CountryRegion."Intrastat Code"));
                    Evaluate(NewBC14CountryRegion."Address Format", AddressFormat);
                    Evaluate(NewBC14CountryRegion."Contact Address Format", ContactAddressFormat);
                    NewBC14CountryRegion."VAT Scheme" := CopyStr(VATScheme, 1, MaxStrLen(NewBC14CountryRegion."VAT Scheme"));
                    NewBC14CountryRegion."County Name" := CopyStr(CountyName, 1, MaxStrLen(NewBC14CountryRegion."County Name"));
                    NewBC14CountryRegion.Insert();

                    currXMLport.Skip();
                end;
            }
        }
    }

    trigger OnPreXmlPort()
    begin
        CaptionRow := true;
    end;

    var
        CaptionRow: Boolean;
}
