// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14.Tests;

using Microsoft.Inventory.Intrastat;

xmlport 148930 "BC14 Exp Tariff Number Data"
{
    Caption = 'Expected Tariff Number data for BC14 migration tests';
    Direction = Import;
    FieldSeparator = ',';
    RecordSeparator = '<CR><LF>';
    Format = VariableText;
    FormatEvaluate = Xml;

    schema
    {
        textelement(root)
        {
            tableelement(TariffNumber; "Tariff Number")
            {
                AutoSave = false;
                XmlName = 'TariffNumber';

                textelement(No) { }
                textelement(Description) { }
                textelement(SupplementaryUnits) { }

                trigger OnBeforeInsertRecord()
                begin
                    if CaptionRow then begin
                        CaptionRow := false;
                        currXMLport.Skip();
                        exit;
                    end;

                    TempTariffNumber.Init();
                    TempTariffNumber."No." := CopyStr(No, 1, MaxStrLen(TempTariffNumber."No."));
                    TempTariffNumber.Description := CopyStr(Description, 1, MaxStrLen(TempTariffNumber.Description));
                    Evaluate(TempTariffNumber."Supplementary Units", SupplementaryUnits);
                    TempTariffNumber.Insert();

                    currXMLport.Skip();
                end;
            }
        }
    }

    trigger OnPreXmlPort()
    begin
        CaptionRow := true;
        TempTariffNumber.Reset();
        TempTariffNumber.DeleteAll();
    end;

    procedure GetExpectedTariffNumbers(var DestTempTariffNumber: Record "Tariff Number" temporary)
    begin
        DestTempTariffNumber.Reset();
        DestTempTariffNumber.DeleteAll();
        if TempTariffNumber.FindSet() then
            repeat
                DestTempTariffNumber := TempTariffNumber;
                DestTempTariffNumber.Insert();
            until TempTariffNumber.Next() = 0;
    end;

    var
        TempTariffNumber: Record "Tariff Number" temporary;
        CaptionRow: Boolean;
}
