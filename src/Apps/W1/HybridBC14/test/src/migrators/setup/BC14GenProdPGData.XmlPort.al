// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14.Tests;

using Microsoft.DataMigration.BC14Reimplementation;

xmlport 148935 "BC14 GenProdPG Data"
{
    Caption = 'BC14 Gen. Prod. Posting Group buffer data';
    Direction = Both;
    FieldSeparator = ',';
    RecordSeparator = '<CR><LF>';
    Format = VariableText;
    FormatEvaluate = Xml;

    schema
    {
        textelement(root)
        {
            tableelement(BC14GenProdPostingGroup; "BC14 Gen. Prod. Posting Group")
            {
                AutoSave = false;
                XmlName = 'BC14GenProdPostingGroup';

                textelement(Code) { }
                textelement(Description) { }
                textelement(DefVATProdPostingGroup) { }
                textelement(AutoInsertDefault) { }

                trigger OnBeforeInsertRecord()
                var
                    NewBC14GenProdPostingGroup: Record "BC14 Gen. Prod. Posting Group";
                begin
                    if CaptionRow then begin
                        CaptionRow := false;
                        currXMLport.Skip();
                        exit;
                    end;

                    NewBC14GenProdPostingGroup.Init();
                    NewBC14GenProdPostingGroup.Code := CopyStr(Code, 1, MaxStrLen(NewBC14GenProdPostingGroup.Code));
                    NewBC14GenProdPostingGroup.Description := CopyStr(Description, 1, MaxStrLen(NewBC14GenProdPostingGroup.Description));
                    NewBC14GenProdPostingGroup."Def. VAT Prod. Posting Group" := CopyStr(DefVATProdPostingGroup, 1, MaxStrLen(NewBC14GenProdPostingGroup."Def. VAT Prod. Posting Group"));
                    Evaluate(NewBC14GenProdPostingGroup."Auto Insert Default", AutoInsertDefault);
                    NewBC14GenProdPostingGroup.Insert();

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
