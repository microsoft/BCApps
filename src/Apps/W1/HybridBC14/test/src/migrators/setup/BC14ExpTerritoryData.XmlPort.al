// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14.Tests;

using Microsoft.Inventory.Intrastat;

xmlport 148922 "BC14 Exp Territory Data"
{
    Caption = 'Expected Territory data for BC14 migration tests';
    Direction = Import;
    FieldSeparator = ',';
    RecordSeparator = '<CR><LF>';
    Format = VariableText;
    FormatEvaluate = Xml;

    schema
    {
        textelement(root)
        {
            tableelement(Territory; Territory)
            {
                AutoSave = false;
                XmlName = 'Territory';

                textelement(Code) { }

                trigger OnBeforeInsertRecord()
                begin
                    if CaptionRow then begin
                        CaptionRow := false;
                        currXMLport.Skip();
                        exit;
                    end;

                    TempTerritory.Init();
                    TempTerritory.Code := CopyStr(Code, 1, MaxStrLen(TempTerritory.Code));
                    TempTerritory.Insert();

                    currXMLport.Skip();
                end;
            }
        }
    }

    trigger OnPreXmlPort()
    begin
        CaptionRow := true;
        TempTerritory.Reset();
        TempTerritory.DeleteAll();
    end;

    procedure GetExpectedTerritories(var DestTempTerritory: Record Territory temporary)
    begin
        DestTempTerritory.Reset();
        DestTempTerritory.DeleteAll();
        if TempTerritory.FindSet() then
            repeat
                DestTempTerritory := TempTerritory;
                DestTempTerritory.Insert();
            until TempTerritory.Next() = 0;
    end;

    var
        TempTerritory: Record Territory temporary;
        CaptionRow: Boolean;
}
