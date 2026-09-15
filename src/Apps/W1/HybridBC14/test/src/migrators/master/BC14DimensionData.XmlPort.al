// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14.Tests;

using Microsoft.DataMigration.BC14Reimplementation;

xmlport 148961 "BC14 Dimension Data"
{
    Caption = 'BC14 Dimension buffer data';
    Direction = Both;
    FieldSeparator = ',';
    RecordSeparator = '<CR><LF>';
    Format = VariableText;
    FormatEvaluate = Xml;

    schema
    {
        textelement(root)
        {
            tableelement(BC14Dimension; "BC14 Dimension")
            {
                AutoSave = false;
                XmlName = 'BC14Dimension';

                textelement(Code) { }
                textelement(Name) { }
                textelement(CodeCaption) { }
                textelement(FilterCaption) { }
                textelement(Description) { }
                textelement(Blocked) { }
                textelement(ConsolidationCode) { }
                textelement(MapToICDimensionCode) { }

                trigger OnBeforeInsertRecord()
                var
                    NewBC14Dimension: Record "BC14 Dimension";
                begin
                    if CaptionRow then begin
                        CaptionRow := false;
                        currXMLport.Skip();
                        exit;
                    end;

                    NewBC14Dimension.Init();
                    NewBC14Dimension.Code := CopyStr(Code, 1, MaxStrLen(NewBC14Dimension.Code));
                    NewBC14Dimension.Name := CopyStr(Name, 1, MaxStrLen(NewBC14Dimension.Name));
                    NewBC14Dimension."Code Caption" := CopyStr(CodeCaption, 1, MaxStrLen(NewBC14Dimension."Code Caption"));
                    NewBC14Dimension."Filter Caption" := CopyStr(FilterCaption, 1, MaxStrLen(NewBC14Dimension."Filter Caption"));
                    NewBC14Dimension.Description := CopyStr(Description, 1, MaxStrLen(NewBC14Dimension.Description));
                    Evaluate(NewBC14Dimension.Blocked, Blocked);
                    NewBC14Dimension."Consolidation Code" := CopyStr(ConsolidationCode, 1, MaxStrLen(NewBC14Dimension."Consolidation Code"));
                    NewBC14Dimension."Map-to IC Dimension Code" := CopyStr(MapToICDimensionCode, 1, MaxStrLen(NewBC14Dimension."Map-to IC Dimension Code"));
                    NewBC14Dimension.Insert();

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
