// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14.Tests;

using Microsoft.DataMigration.BC14Reimplementation;

xmlport 148947 "BC14 ItemCategory Data"
{
    Caption = 'BC14 Item Category buffer data';
    Direction = Both;
    FieldSeparator = ',';
    RecordSeparator = '<CR><LF>';
    Format = VariableText;
    FormatEvaluate = Xml;

    schema
    {
        textelement(root)
        {
            tableelement(BC14ItemCategory; "BC14 Item Category")
            {
                AutoSave = false;
                XmlName = 'BC14ItemCategory';

                textelement(Code) { }
                textelement(Description) { }
                textelement(ParentCategory) { }
                textelement(PresentationOrder) { }
                textelement(Indentation) { }

                trigger OnBeforeInsertRecord()
                var
                    NewBC14ItemCategory: Record "BC14 Item Category";
                begin
                    if CaptionRow then begin
                        CaptionRow := false;
                        currXMLport.Skip();
                        exit;
                    end;

                    NewBC14ItemCategory.Init();
                    NewBC14ItemCategory.Code := CopyStr(Code, 1, MaxStrLen(NewBC14ItemCategory.Code));
                    NewBC14ItemCategory.Description := CopyStr(Description, 1, MaxStrLen(NewBC14ItemCategory.Description));
                    NewBC14ItemCategory."Parent Category" := CopyStr(ParentCategory, 1, MaxStrLen(NewBC14ItemCategory."Parent Category"));
                    Evaluate(NewBC14ItemCategory."Presentation Order", PresentationOrder);
                    Evaluate(NewBC14ItemCategory.Indentation, Indentation);
                    NewBC14ItemCategory.Insert();

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
