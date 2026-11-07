// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14.Tests;

using Microsoft.DataMigration.BC14Reimplementation;

xmlport 148939 "BC14 VATProdPG Data"
{
    Caption = 'BC14 VAT Prod. Posting Group buffer data';
    Direction = Both;
    FieldSeparator = ',';
    RecordSeparator = '<CR><LF>';
    Format = VariableText;
    FormatEvaluate = Xml;

    schema
    {
        textelement(root)
        {
            tableelement(BC14VATProdPostingGroup; "BC14 VAT Prod. Posting Group")
            {
                AutoSave = false;
                XmlName = 'BC14VATProdPostingGroup';

                textelement(Code) { }
                textelement(Description) { }

                trigger OnBeforeInsertRecord()
                var
                    NewBC14VATProdPostingGroup: Record "BC14 VAT Prod. Posting Group";
                begin
                    if CaptionRow then begin
                        CaptionRow := false;
                        currXMLport.Skip();
                        exit;
                    end;

                    NewBC14VATProdPostingGroup.Init();
                    NewBC14VATProdPostingGroup.Code := CopyStr(Code, 1, MaxStrLen(NewBC14VATProdPostingGroup.Code));
                    NewBC14VATProdPostingGroup.Description := CopyStr(Description, 1, MaxStrLen(NewBC14VATProdPostingGroup.Description));
                    NewBC14VATProdPostingGroup.Insert();

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
