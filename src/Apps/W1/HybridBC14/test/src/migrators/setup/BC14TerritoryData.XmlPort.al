// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14.Tests;

using Microsoft.DataMigration.BC14Reimplementation;

xmlport 148921 "BC14 Territory Data"
{
    Caption = 'BC14 Territory buffer data';
    Direction = Both;
    FieldSeparator = ',';
    RecordSeparator = '<CR><LF>';
    Format = VariableText;
    FormatEvaluate = Xml;

    schema
    {
        textelement(root)
        {
            tableelement(BC14Territory; "BC14 Territory")
            {
                AutoSave = false;
                XmlName = 'BC14Territory';

                textelement(Code) { }
                textelement(Description) { }

                trigger OnBeforeInsertRecord()
                var
                    NewBC14Territory: Record "BC14 Territory";
                begin
                    if CaptionRow then begin
                        CaptionRow := false;
                        currXMLport.Skip();
                        exit;
                    end;

                    NewBC14Territory.Init();
                    NewBC14Territory.Code := CopyStr(Code, 1, MaxStrLen(NewBC14Territory.Code));
                    NewBC14Territory.Description := CopyStr(Description, 1, MaxStrLen(NewBC14Territory.Description));
                    NewBC14Territory.Insert();

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
