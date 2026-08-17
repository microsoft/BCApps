// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14.Tests;

using Microsoft.DataMigration.BC14Reimplementation;

xmlport 148913 "BC14 Ship-to Address Data"
{
    Direction = Both;
    FieldSeparator = ',';
    RecordSeparator = '<CR><LF>';
    Format = VariableText;
    FormatEvaluate = Xml;

    schema
    {
        textelement(root)
        {
            tableelement(BC14ShiptoAddress; "BC14 Ship-to Address")
            {
                AutoSave = false;
                XmlName = 'BC14ShiptoAddress';

                textelement(CustomerNo) { }
                textelement(CodeValue) { }
                textelement(Name) { }
                textelement(Address) { }
                textelement(City) { }
                textelement(PostCode) { }
                textelement(CountryRegionCode) { }

                trigger OnBeforeInsertRecord()
                var
                    NewBC14ShipToAddress: Record "BC14 Ship-to Address";
                begin
                    if CaptionRow then begin
                        CaptionRow := false;
                        currXMLport.Skip();
                        exit;
                    end;

                    NewBC14ShipToAddress.Init();
                    NewBC14ShipToAddress."Customer No." := CopyStr(CustomerNo, 1, MaxStrLen(NewBC14ShipToAddress."Customer No."));
                    NewBC14ShipToAddress.Code := CopyStr(CodeValue, 1, MaxStrLen(NewBC14ShipToAddress.Code));
                    NewBC14ShipToAddress.Name := CopyStr(Name, 1, MaxStrLen(NewBC14ShipToAddress.Name));
                    NewBC14ShipToAddress.Address := CopyStr(Address, 1, MaxStrLen(NewBC14ShipToAddress.Address));
                    NewBC14ShipToAddress.City := CopyStr(City, 1, MaxStrLen(NewBC14ShipToAddress.City));
                    NewBC14ShipToAddress."Post Code" := CopyStr(PostCode, 1, MaxStrLen(NewBC14ShipToAddress."Post Code"));
                    NewBC14ShipToAddress."Country/Region Code" := CopyStr(CountryRegionCode, 1, MaxStrLen(NewBC14ShipToAddress."Country/Region Code"));
                    NewBC14ShipToAddress.Insert();

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
