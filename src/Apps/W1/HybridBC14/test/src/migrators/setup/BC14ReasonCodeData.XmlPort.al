// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14.Tests;

using Microsoft.DataMigration.BC14Reimplementation;

xmlport 148925 "BC14 Reason Code Data"
{
    Caption = 'BC14 Reason Code buffer data';
    Direction = Both;
    FieldSeparator = ',';
    RecordSeparator = '<CR><LF>';
    Format = VariableText;
    FormatEvaluate = Xml;

    schema
    {
        textelement(root)
        {
            tableelement(BC14ReasonCode; "BC14 Reason Code")
            {
                AutoSave = false;
                XmlName = 'BC14ReasonCode';

                textelement(Code) { }
                textelement(Description) { }

                trigger OnBeforeInsertRecord()
                var
                    NewBC14ReasonCode: Record "BC14 Reason Code";
                begin
                    if CaptionRow then begin
                        CaptionRow := false;
                        currXMLport.Skip();
                        exit;
                    end;

                    NewBC14ReasonCode.Init();
                    NewBC14ReasonCode.Code := CopyStr(Code, 1, MaxStrLen(NewBC14ReasonCode.Code));
                    NewBC14ReasonCode.Description := CopyStr(Description, 1, MaxStrLen(NewBC14ReasonCode.Description));
                    NewBC14ReasonCode.Insert();

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
