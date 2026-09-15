// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14.Tests;

using Microsoft.DataMigration.BC14Reimplementation;

xmlport 148923 "BC14 Source Code Data"
{
    Caption = 'BC14 Source Code buffer data';
    Direction = Both;
    FieldSeparator = ',';
    RecordSeparator = '<CR><LF>';
    Format = VariableText;
    FormatEvaluate = Xml;

    schema
    {
        textelement(root)
        {
            tableelement(BC14SourceCode; "BC14 Source Code")
            {
                AutoSave = false;
                XmlName = 'BC14SourceCode';

                textelement(Code) { }
                textelement(Description) { }

                trigger OnBeforeInsertRecord()
                var
                    NewBC14SourceCode: Record "BC14 Source Code";
                begin
                    if CaptionRow then begin
                        CaptionRow := false;
                        currXMLport.Skip();
                        exit;
                    end;

                    NewBC14SourceCode.Init();
                    NewBC14SourceCode.Code := CopyStr(Code, 1, MaxStrLen(NewBC14SourceCode.Code));
                    NewBC14SourceCode.Description := CopyStr(Description, 1, MaxStrLen(NewBC14SourceCode.Description));
                    NewBC14SourceCode.Insert();

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
