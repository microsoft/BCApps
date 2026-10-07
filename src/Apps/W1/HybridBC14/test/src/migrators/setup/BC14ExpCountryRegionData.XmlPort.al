// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14.Tests;

using Microsoft.Foundation.Address;

xmlport 148918 "BC14 Exp Country/Region Data"
{
    Caption = 'Expected Country/Region data for BC14 migration tests';
    Direction = Import;
    FieldSeparator = ',';
    RecordSeparator = '<CR><LF>';
    Format = VariableText;
    FormatEvaluate = Xml;

    schema
    {
        textelement(root)
        {
            tableelement(CountryRegion; "Country/Region")
            {
                AutoSave = false;
                XmlName = 'CountryRegion';

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
                begin
                    if CaptionRow then begin
                        CaptionRow := false;
                        currXMLport.Skip();
                        exit;
                    end;

                    TempCountryRegion.Init();
                    TempCountryRegion.Code := CopyStr(Code, 1, MaxStrLen(TempCountryRegion.Code));
                    TempCountryRegion.Name := CopyStr(Name, 1, MaxStrLen(TempCountryRegion.Name));
                    TempCountryRegion."ISO Code" := CopyStr(ISOCode, 1, MaxStrLen(TempCountryRegion."ISO Code"));
                    TempCountryRegion."ISO Numeric Code" := CopyStr(ISONumericCode, 1, MaxStrLen(TempCountryRegion."ISO Numeric Code"));
                    TempCountryRegion."EU Country/Region Code" := CopyStr(EUCountryRegionCode, 1, MaxStrLen(TempCountryRegion."EU Country/Region Code"));
                    TempCountryRegion."Intrastat Code" := CopyStr(IntrastatCode, 1, MaxStrLen(TempCountryRegion."Intrastat Code"));
                    Evaluate(TempCountryRegion."Address Format", AddressFormat);
                    Evaluate(TempCountryRegion."Contact Address Format", ContactAddressFormat);
                    TempCountryRegion."VAT Scheme" := CopyStr(VATScheme, 1, MaxStrLen(TempCountryRegion."VAT Scheme"));
                    TempCountryRegion."County Name" := CopyStr(CountyName, 1, MaxStrLen(TempCountryRegion."County Name"));
                    TempCountryRegion.Insert();

                    currXMLport.Skip();
                end;
            }
        }
    }

    trigger OnPreXmlPort()
    begin
        CaptionRow := true;
        TempCountryRegion.Reset();
        TempCountryRegion.DeleteAll();
    end;

    procedure GetExpectedCountryRegions(var DestTempCountryRegion: Record "Country/Region" temporary)
    begin
        DestTempCountryRegion.Reset();
        DestTempCountryRegion.DeleteAll();
        if TempCountryRegion.FindSet() then
            repeat
                DestTempCountryRegion := TempCountryRegion;
                DestTempCountryRegion.Insert();
            until TempCountryRegion.Next() = 0;
    end;

    var
        TempCountryRegion: Record "Country/Region" temporary;
        CaptionRow: Boolean;
}
