// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14.Tests;

using System.Globalization;

xmlport 148920 "BC14 Exp Language Data"
{
    Caption = 'Expected Language data for BC14 migration tests';
    Direction = Import;
    FieldSeparator = ',';
    RecordSeparator = '<CR><LF>';
    Format = VariableText;
    FormatEvaluate = Xml;

    schema
    {
        textelement(root)
        {
            tableelement(Language; Language)
            {
                AutoSave = false;
                XmlName = 'Language';

                textelement(Code) { }
                textelement(Name) { }
                textelement(WindowsLanguageID) { }

                trigger OnBeforeInsertRecord()
                begin
                    if CaptionRow then begin
                        CaptionRow := false;
                        currXMLport.Skip();
                        exit;
                    end;

                    TempLanguage.Init();
                    TempLanguage.Code := CopyStr(Code, 1, MaxStrLen(TempLanguage.Code));
                    TempLanguage.Name := CopyStr(Name, 1, MaxStrLen(TempLanguage.Name));
                    Evaluate(TempLanguage."Windows Language ID", WindowsLanguageID);
                    TempLanguage.Insert();

                    currXMLport.Skip();
                end;
            }
        }
    }

    trigger OnPreXmlPort()
    begin
        CaptionRow := true;
        TempLanguage.Reset();
        TempLanguage.DeleteAll();
    end;

    procedure GetExpectedLanguages(var DestTempLanguage: Record Language temporary)
    begin
        DestTempLanguage.Reset();
        DestTempLanguage.DeleteAll();
        if TempLanguage.FindSet() then
            repeat
                DestTempLanguage := TempLanguage;
                DestTempLanguage.Insert();
            until TempLanguage.Next() = 0;
    end;

    var
        TempLanguage: Record Language temporary;
        CaptionRow: Boolean;
}
