// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14.Tests;

using Microsoft.Finance.Dimension;

xmlport 148962 "BC14 Exp Dimension"
{
    Caption = 'Expected Dimension data';
    Direction = Import;
    FieldSeparator = ',';
    RecordSeparator = '<CR><LF>';
    Format = VariableText;
    FormatEvaluate = Xml;

    schema
    {
        textelement(root)
        {
            tableelement(Dimension; Dimension)
            {
                AutoSave = false;
                XmlName = 'Dimension';

                textelement(Code) { }
                textelement(Name) { }
                textelement(CodeCaption) { }
                textelement(FilterCaption) { }
                textelement(Description) { }
                textelement(Blocked) { }
                textelement(ConsolidationCode) { }
                textelement(MapToICDimensionCode) { }

                trigger OnBeforeInsertRecord()
                begin
                    if CaptionRow then begin
                        CaptionRow := false;
                        currXMLport.Skip();
                        exit;
                    end;

                    TempDimension.Init();
                    TempDimension.Code := CopyStr(Code, 1, MaxStrLen(TempDimension.Code));
                    TempDimension.Name := CopyStr(Name, 1, MaxStrLen(TempDimension.Name));
                    TempDimension."Code Caption" := CopyStr(CodeCaption, 1, MaxStrLen(TempDimension."Code Caption"));
                    TempDimension."Filter Caption" := CopyStr(FilterCaption, 1, MaxStrLen(TempDimension."Filter Caption"));
                    TempDimension.Description := CopyStr(Description, 1, MaxStrLen(TempDimension.Description));
                    Evaluate(TempDimension.Blocked, Blocked);
                    TempDimension."Consolidation Code" := CopyStr(ConsolidationCode, 1, MaxStrLen(TempDimension."Consolidation Code"));
                    TempDimension."Map-to IC Dimension Code" := CopyStr(MapToICDimensionCode, 1, MaxStrLen(TempDimension."Map-to IC Dimension Code"));
                    TempDimension.Insert();

                    currXMLport.Skip();
                end;
            }
        }
    }

    trigger OnPreXmlPort()
    begin
        CaptionRow := true;
        TempDimension.Reset();
        TempDimension.DeleteAll();
    end;

    procedure GetExpectedDimensions(var Dest: Record Dimension temporary)
    begin
        Dest.Reset();
        Dest.DeleteAll();
        if TempDimension.FindSet() then
            repeat
                Dest := TempDimension;
                Dest.Insert();
            until TempDimension.Next() = 0;
    end;

    var
        TempDimension: Record Dimension temporary;
        CaptionRow: Boolean;
}
