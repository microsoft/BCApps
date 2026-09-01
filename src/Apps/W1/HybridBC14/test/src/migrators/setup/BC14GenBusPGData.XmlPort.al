// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14.Tests;

using Microsoft.DataMigration.BC14Reimplementation;

xmlport 148933 "BC14 GenBusPG Data"
{
    Caption = 'BC14 Gen. Bus. Posting Group buffer data';
    Direction = Both;
    FieldSeparator = ',';
    RecordSeparator = '<CR><LF>';
    Format = VariableText;
    FormatEvaluate = Xml;

    schema
    {
        textelement(root)
        {
            tableelement(BC14GenBusPostingGroup; "BC14 Gen. Bus. Posting Group")
            {
                AutoSave = false;
                XmlName = 'BC14GenBusPostingGroup';

                textelement(Code) { }
                textelement(Description) { }
                textelement(DefVATBusPostingGroup) { }
                textelement(AutoInsertDefault) { }

                trigger OnBeforeInsertRecord()
                var
                    NewBC14GenBusPostingGroup: Record "BC14 Gen. Bus. Posting Group";
                begin
                    if CaptionRow then begin
                        CaptionRow := false;
                        currXMLport.Skip();
                        exit;
                    end;

                    NewBC14GenBusPostingGroup.Init();
                    NewBC14GenBusPostingGroup.Code := CopyStr(Code, 1, MaxStrLen(NewBC14GenBusPostingGroup.Code));
                    NewBC14GenBusPostingGroup.Description := CopyStr(Description, 1, MaxStrLen(NewBC14GenBusPostingGroup.Description));
                    NewBC14GenBusPostingGroup."Def. VAT Bus. Posting Group" := CopyStr(DefVATBusPostingGroup, 1, MaxStrLen(NewBC14GenBusPostingGroup."Def. VAT Bus. Posting Group"));
                    Evaluate(NewBC14GenBusPostingGroup."Auto Insert Default", AutoInsertDefault);
                    NewBC14GenBusPostingGroup.Insert();

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
