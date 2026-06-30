// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14.Tests;

using Microsoft.Sales.Customer;

xmlport 148914 "BC14 Exp Ship-to Address"
{
    Direction = Import;
    FieldSeparator = ',';
    RecordSeparator = '<CR><LF>';
    Format = VariableText;
    FormatEvaluate = Xml;

    schema
    {
        textelement(root)
        {
            tableelement(ShipToAddress; "Ship-to Address")
            {
                AutoSave = false;
                XmlName = 'ShipToAddress';

                textelement(CustomerNo) { }
                textelement(CodeValue) { }
                textelement(Name) { }
                textelement(Address) { }
                textelement(City) { }
                textelement(PostCode) { }
                textelement(CountryRegionCode) { }

                trigger OnBeforeInsertRecord()
                begin
                    if CaptionRow then begin
                        CaptionRow := false;
                        currXMLport.Skip();
                        exit;
                    end;

                    TempShipToAddress.Init();
                    TempShipToAddress."Customer No." := CopyStr(CustomerNo, 1, MaxStrLen(TempShipToAddress."Customer No."));
                    TempShipToAddress.Code := CopyStr(CodeValue, 1, MaxStrLen(TempShipToAddress.Code));
                    TempShipToAddress.Name := CopyStr(Name, 1, MaxStrLen(TempShipToAddress.Name));
                    TempShipToAddress.Address := CopyStr(Address, 1, MaxStrLen(TempShipToAddress.Address));
                    TempShipToAddress.City := CopyStr(City, 1, MaxStrLen(TempShipToAddress.City));
                    TempShipToAddress."Post Code" := CopyStr(PostCode, 1, MaxStrLen(TempShipToAddress."Post Code"));
                    TempShipToAddress."Country/Region Code" := CopyStr(CountryRegionCode, 1, MaxStrLen(TempShipToAddress."Country/Region Code"));
                    TempShipToAddress.Insert();

                    currXMLport.Skip();
                end;
            }
        }
    }

    trigger OnPreXmlPort()
    begin
        CaptionRow := true;
        TempShipToAddress.Reset();
        TempShipToAddress.DeleteAll();
    end;

    procedure GetExpectedShipToAddresses(var DestTemp: Record "Ship-to Address" temporary)
    begin
        DestTemp.Reset();
        DestTemp.DeleteAll();
        if TempShipToAddress.FindSet() then
            repeat
                DestTemp := TempShipToAddress;
                DestTemp.Insert();
            until TempShipToAddress.Next() = 0;
    end;

    var
        TempShipToAddress: Record "Ship-to Address" temporary;
        CaptionRow: Boolean;
}
