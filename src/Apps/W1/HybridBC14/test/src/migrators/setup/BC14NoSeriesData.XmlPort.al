// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14.Tests;

using Microsoft.DataMigration.BC14Reimplementation;

xmlport 148959 "BC14 NoSeries Data"
{
    Caption = 'BC14 No. Series buffer data';
    Direction = Both;
    FieldSeparator = ',';
    RecordSeparator = '<CR><LF>';
    Format = VariableText;
    FormatEvaluate = Xml;

    schema
    {
        textelement(root)
        {
            tableelement(BC14NoSeries; "BC14 No. Series")
            {
                AutoSave = false;
                XmlName = 'BC14NoSeries';

                textelement(Code) { }
                textelement(Description) { }
                textelement(DefaultNos) { }
                textelement(ManualNos) { }
                textelement(DateOrder) { }

                trigger OnBeforeInsertRecord()
                var
                    NewBC14NoSeries: Record "BC14 No. Series";
                begin
                    if CaptionRow then begin
                        CaptionRow := false;
                        currXMLport.Skip();
                        exit;
                    end;

                    NewBC14NoSeries.Init();
                    NewBC14NoSeries.Code := CopyStr(Code, 1, MaxStrLen(NewBC14NoSeries.Code));
                    NewBC14NoSeries.Description := CopyStr(Description, 1, MaxStrLen(NewBC14NoSeries.Description));
                    Evaluate(NewBC14NoSeries."Default Nos.", DefaultNos);
                    Evaluate(NewBC14NoSeries."Manual Nos.", ManualNos);
                    Evaluate(NewBC14NoSeries."Date Order", DateOrder);
                    NewBC14NoSeries.Insert();

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
