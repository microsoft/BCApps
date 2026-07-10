// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14.Tests;

using Microsoft.Foundation.AuditCodes;

xmlport 148924 "BC14 Exp Source Code Data"
{
    Caption = 'Expected Source Code data for BC14 migration tests';
    Direction = Import;
    FieldSeparator = ',';
    RecordSeparator = '<CR><LF>';
    Format = VariableText;
    FormatEvaluate = Xml;

    schema
    {
        textelement(root)
        {
            tableelement(SourceCode; "Source Code")
            {
                AutoSave = false;
                XmlName = 'SourceCode';

                textelement(Code) { }
                textelement(Description) { }

                trigger OnBeforeInsertRecord()
                begin
                    if CaptionRow then begin
                        CaptionRow := false;
                        currXMLport.Skip();
                        exit;
                    end;

                    TempSourceCode.Init();
                    TempSourceCode.Code := CopyStr(Code, 1, MaxStrLen(TempSourceCode.Code));
                    TempSourceCode.Description := CopyStr(Description, 1, MaxStrLen(TempSourceCode.Description));
                    TempSourceCode.Insert();

                    currXMLport.Skip();
                end;
            }
        }
    }

    trigger OnPreXmlPort()
    begin
        CaptionRow := true;
        TempSourceCode.Reset();
        TempSourceCode.DeleteAll();
    end;

    procedure GetExpectedSourceCodes(var DestTempSourceCode: Record "Source Code" temporary)
    begin
        DestTempSourceCode.Reset();
        DestTempSourceCode.DeleteAll();
        if TempSourceCode.FindSet() then
            repeat
                DestTempSourceCode := TempSourceCode;
                DestTempSourceCode.Insert();
            until TempSourceCode.Next() = 0;
    end;

    var
        TempSourceCode: Record "Source Code" temporary;
        CaptionRow: Boolean;
}
