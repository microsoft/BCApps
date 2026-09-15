// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14.Tests;

using Microsoft.Foundation.UOM;

xmlport 148968 "BC14 Exp Unit of Measure"
{
    Caption = 'Expected Unit of Measure data for BC14 migration tests';
    Direction = Import;
    FieldSeparator = ',';
    RecordSeparator = '<CR><LF>';
    Format = VariableText;
    FormatEvaluate = Xml;

    schema
    {
        textelement(root)
        {
            tableelement(UnitOfMeasure; "Unit of Measure")
            {
                AutoSave = false;
                XmlName = 'UnitOfMeasure';

                textelement(Code) { }
                textelement(Description) { }
                textelement(InternationalStandardCode) { }
                textelement(Symbol) { }

                trigger OnBeforeInsertRecord()
                begin
                    if CaptionRow then begin
                        CaptionRow := false;
                        currXMLport.Skip();
                        exit;
                    end;

                    TempUnitOfMeasure.Init();
                    TempUnitOfMeasure.Code := CopyStr(Code, 1, MaxStrLen(TempUnitOfMeasure.Code));
                    TempUnitOfMeasure.Description := CopyStr(Description, 1, MaxStrLen(TempUnitOfMeasure.Description));
                    TempUnitOfMeasure."International Standard Code" := CopyStr(InternationalStandardCode, 1, MaxStrLen(TempUnitOfMeasure."International Standard Code"));
                    TempUnitOfMeasure.Symbol := CopyStr(Symbol, 1, MaxStrLen(TempUnitOfMeasure.Symbol));
                    TempUnitOfMeasure.Insert();

                    currXMLport.Skip();
                end;
            }
        }
    }

    trigger OnPreXmlPort()
    begin
        CaptionRow := true;
        TempUnitOfMeasure.Reset();
        TempUnitOfMeasure.DeleteAll();
    end;

    procedure GetExpectedUnitsOfMeasure(var DestTempUnitOfMeasure: Record "Unit of Measure" temporary)
    begin
        DestTempUnitOfMeasure.Reset();
        DestTempUnitOfMeasure.DeleteAll();
        if TempUnitOfMeasure.FindSet() then
            repeat
                DestTempUnitOfMeasure := TempUnitOfMeasure;
                DestTempUnitOfMeasure.Insert();
            until TempUnitOfMeasure.Next() = 0;
    end;

    var
        TempUnitOfMeasure: Record "Unit of Measure" temporary;
        CaptionRow: Boolean;
}
