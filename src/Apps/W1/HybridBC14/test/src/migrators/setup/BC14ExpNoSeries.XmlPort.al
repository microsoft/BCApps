// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14.Tests;

using Microsoft.Foundation.NoSeries;

xmlport 148960 "BC14 Exp NoSeries"
{
    Caption = 'Expected No. Series data';
    Direction = Import;
    FieldSeparator = ',';
    RecordSeparator = '<CR><LF>';
    Format = VariableText;
    FormatEvaluate = Xml;

    schema
    {
        textelement(root)
        {
            tableelement(NoSeries; "No. Series")
            {
                AutoSave = false;
                XmlName = 'NoSeries';

                textelement(Code) { }
                textelement(Description) { }
                textelement(DefaultNos) { }
                textelement(ManualNos) { }
                textelement(DateOrder) { }

                trigger OnBeforeInsertRecord()
                begin
                    if CaptionRow then begin
                        CaptionRow := false;
                        currXMLport.Skip();
                        exit;
                    end;

                    TempNoSeries.Init();
                    TempNoSeries.Code := CopyStr(Code, 1, MaxStrLen(TempNoSeries.Code));
                    TempNoSeries.Description := CopyStr(Description, 1, MaxStrLen(TempNoSeries.Description));
                    Evaluate(TempNoSeries."Default Nos.", DefaultNos);
                    Evaluate(TempNoSeries."Manual Nos.", ManualNos);
                    Evaluate(TempNoSeries."Date Order", DateOrder);
                    TempNoSeries.Insert();

                    currXMLport.Skip();
                end;
            }
        }
    }

    trigger OnPreXmlPort()
    begin
        CaptionRow := true;
        TempNoSeries.Reset();
        TempNoSeries.DeleteAll();
    end;

    procedure GetExpectedNoSeries(var Dest: Record "No. Series" temporary)
    begin
        Dest.Reset();
        Dest.DeleteAll();
        if TempNoSeries.FindSet() then
            repeat
                Dest := TempNoSeries;
                Dest.Insert();
            until TempNoSeries.Next() = 0;
    end;

    var
        TempNoSeries: Record "No. Series" temporary;
        CaptionRow: Boolean;
}
