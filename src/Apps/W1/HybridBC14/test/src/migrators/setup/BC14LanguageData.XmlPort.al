// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14.Tests;

using Microsoft.DataMigration.BC14Reimplementation;

xmlport 148919 "BC14 Language Data"
{
    Caption = 'BC14 Language buffer data';
    Direction = Both;
    FieldSeparator = ',';
    RecordSeparator = '<CR><LF>';
    Format = VariableText;
    FormatEvaluate = Xml;

    schema
    {
        textelement(root)
        {
            tableelement(BC14Language; "BC14 Language")
            {
                AutoSave = false;
                XmlName = 'BC14Language';

                textelement(Code) { }
                textelement(Name) { }
                textelement(WindowsLanguageID) { }

                trigger OnBeforeInsertRecord()
                var
                    NewBC14Language: Record "BC14 Language";
                begin
                    if CaptionRow then begin
                        CaptionRow := false;
                        currXMLport.Skip();
                        exit;
                    end;

                    NewBC14Language.Init();
                    NewBC14Language.Code := CopyStr(Code, 1, MaxStrLen(NewBC14Language.Code));
                    NewBC14Language.Name := CopyStr(Name, 1, MaxStrLen(NewBC14Language.Name));
                    Evaluate(NewBC14Language."Windows Language ID", WindowsLanguageID);
                    NewBC14Language.Insert();

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
