// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14.Tests;

using Microsoft.DataMigration.BC14Reimplementation;

xmlport 148937 "BC14 VATBusPG Data"
{
    Caption = 'BC14 VAT Bus. Posting Group buffer data';
    Direction = Both;
    FieldSeparator = ',';
    RecordSeparator = '<CR><LF>';
    Format = VariableText;
    FormatEvaluate = Xml;

    schema
    {
        textelement(root)
        {
            tableelement(BC14VATBusPostingGroup; "BC14 VAT Bus. Posting Group")
            {
                AutoSave = false;
                XmlName = 'BC14VATBusPostingGroup';

                textelement(Code) { }
                textelement(Description) { }

                trigger OnBeforeInsertRecord()
                var
                    NewBC14VATBusPostingGroup: Record "BC14 VAT Bus. Posting Group";
                begin
                    if CaptionRow then begin
                        CaptionRow := false;
                        currXMLport.Skip();
                        exit;
                    end;

                    NewBC14VATBusPostingGroup.Init();
                    NewBC14VATBusPostingGroup.Code := CopyStr(Code, 1, MaxStrLen(NewBC14VATBusPostingGroup.Code));
                    NewBC14VATBusPostingGroup.Description := CopyStr(Description, 1, MaxStrLen(NewBC14VATBusPostingGroup.Description));
                    NewBC14VATBusPostingGroup.Insert();

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
