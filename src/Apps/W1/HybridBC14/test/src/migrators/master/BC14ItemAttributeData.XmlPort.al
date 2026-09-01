// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14.Tests;

using Microsoft.DataMigration.BC14Reimplementation;

xmlport 148957 "BC14 ItemAttribute Data"
{
    Caption = 'BC14 Item Attribute buffer data';
    Direction = Both;
    FieldSeparator = ',';
    RecordSeparator = '<CR><LF>';
    Format = VariableText;
    FormatEvaluate = Xml;

    schema
    {
        textelement(root)
        {
            tableelement(BC14ItemAttribute; "BC14 Item Attribute")
            {
                AutoSave = false;
                XmlName = 'BC14ItemAttribute';

                textelement(ID) { }
                textelement(Name) { }
                textelement(Type) { }
                textelement(UnitOfMeasure) { }
                textelement(Blocked) { }

                trigger OnBeforeInsertRecord()
                var
                    NewBC14ItemAttribute: Record "BC14 Item Attribute";
                begin
                    if CaptionRow then begin
                        CaptionRow := false;
                        currXMLport.Skip();
                        exit;
                    end;

                    NewBC14ItemAttribute.Init();
                    Evaluate(NewBC14ItemAttribute.ID, ID);
                    NewBC14ItemAttribute.Name := CopyStr(Name, 1, MaxStrLen(NewBC14ItemAttribute.Name));
                    Evaluate(NewBC14ItemAttribute.Type, Type);
                    NewBC14ItemAttribute."Unit of Measure" := CopyStr(UnitOfMeasure, 1, MaxStrLen(NewBC14ItemAttribute."Unit of Measure"));
                    Evaluate(NewBC14ItemAttribute.Blocked, Blocked);
                    NewBC14ItemAttribute.Insert();

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
