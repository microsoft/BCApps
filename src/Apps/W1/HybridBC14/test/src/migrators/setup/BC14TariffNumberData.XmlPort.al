// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14.Tests;

using Microsoft.DataMigration.BC14Reimplementation;

xmlport 148929 "BC14 Tariff Number Data"
{
    Caption = 'BC14 Tariff Number buffer data';
    Direction = Both;
    FieldSeparator = ',';
    RecordSeparator = '<CR><LF>';
    Format = VariableText;
    FormatEvaluate = Xml;

    schema
    {
        textelement(root)
        {
            tableelement(BC14TariffNumber; "BC14 Tariff Number")
            {
                AutoSave = false;
                XmlName = 'BC14TariffNumber';

                textelement(No) { }
                textelement(Description) { }
                textelement(SupplementaryUnits) { }

                trigger OnBeforeInsertRecord()
                var
                    NewBC14TariffNumber: Record "BC14 Tariff Number";
                begin
                    if CaptionRow then begin
                        CaptionRow := false;
                        currXMLport.Skip();
                        exit;
                    end;

                    NewBC14TariffNumber.Init();
                    NewBC14TariffNumber."No." := CopyStr(No, 1, MaxStrLen(NewBC14TariffNumber."No."));
                    NewBC14TariffNumber.Description := CopyStr(Description, 1, MaxStrLen(NewBC14TariffNumber.Description));
                    Evaluate(NewBC14TariffNumber."Supplementary Units", SupplementaryUnits);
                    NewBC14TariffNumber.Insert();

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
