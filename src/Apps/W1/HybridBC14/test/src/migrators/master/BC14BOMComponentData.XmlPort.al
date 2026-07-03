// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14.Tests;

using Microsoft.DataMigration.BC14Reimplementation;

xmlport 148915 "BC14 BOM Component Data"
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
            tableelement(BC14BOMComponent; "BC14 BOM Component")
            {
                AutoSave = false;
                XmlName = 'BC14BOMComponent';

                textelement(ParentItemNo) { }
                textelement(LineNo) { }
                textelement(TypeValue) { }
                textelement(No) { }
                textelement(Description) { }
                textelement(UoMCode) { }
                textelement(QtyPer) { }

                trigger OnBeforeInsertRecord()
                var
                    NewBC14BOMComponent: Record "BC14 BOM Component";
                begin
                    if CaptionRow then begin
                        CaptionRow := false;
                        currXMLport.Skip();
                        exit;
                    end;

                    NewBC14BOMComponent.Init();
                    NewBC14BOMComponent."Parent Item No." := CopyStr(ParentItemNo, 1, MaxStrLen(NewBC14BOMComponent."Parent Item No."));
                    Evaluate(NewBC14BOMComponent."Line No.", LineNo);
                    Evaluate(NewBC14BOMComponent.Type, TypeValue);
                    NewBC14BOMComponent."No." := CopyStr(No, 1, MaxStrLen(NewBC14BOMComponent."No."));
                    NewBC14BOMComponent.Description := CopyStr(Description, 1, MaxStrLen(NewBC14BOMComponent.Description));
                    NewBC14BOMComponent."Unit of Measure Code" := CopyStr(UoMCode, 1, MaxStrLen(NewBC14BOMComponent."Unit of Measure Code"));
                    Evaluate(NewBC14BOMComponent."Quantity per", QtyPer);
                    NewBC14BOMComponent.Insert();

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
