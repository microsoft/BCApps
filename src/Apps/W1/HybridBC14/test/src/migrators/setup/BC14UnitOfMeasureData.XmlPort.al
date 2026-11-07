// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14.Tests;

using Microsoft.DataMigration.BC14Reimplementation;

xmlport 148967 "BC14 Unit of Measure Data"
{
    Caption = 'BC14 Unit of Measure buffer data';
    Direction = Both;
    FieldSeparator = ',';
    RecordSeparator = '<CR><LF>';
    Format = VariableText;
    FormatEvaluate = Xml;

    schema
    {
        textelement(root)
        {
            tableelement(BC14UnitOfMeasure; "BC14 Unit of Measure")
            {
                AutoSave = false;
                XmlName = 'BC14UnitOfMeasure';

                textelement(Code) { }
                textelement(Description) { }
                textelement(InternationalStandardCode) { }
                textelement(Symbol) { }

                trigger OnBeforeInsertRecord()
                var
                    NewBC14UnitOfMeasure: Record "BC14 Unit of Measure";
                begin
                    if CaptionRow then begin
                        CaptionRow := false;
                        currXMLport.Skip();
                        exit;
                    end;

                    NewBC14UnitOfMeasure.Init();
                    NewBC14UnitOfMeasure.Code := CopyStr(Code, 1, MaxStrLen(NewBC14UnitOfMeasure.Code));
                    NewBC14UnitOfMeasure.Description := CopyStr(Description, 1, MaxStrLen(NewBC14UnitOfMeasure.Description));
                    NewBC14UnitOfMeasure."International Standard Code" := CopyStr(InternationalStandardCode, 1, MaxStrLen(NewBC14UnitOfMeasure."International Standard Code"));
                    NewBC14UnitOfMeasure.Symbol := CopyStr(Symbol, 1, MaxStrLen(NewBC14UnitOfMeasure.Symbol));
                    NewBC14UnitOfMeasure.Insert();

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
