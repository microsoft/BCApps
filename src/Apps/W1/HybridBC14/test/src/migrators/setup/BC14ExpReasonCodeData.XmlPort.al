// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14.Tests;

using Microsoft.Foundation.AuditCodes;

xmlport 148926 "BC14 Exp Reason Code Data"
{
    Caption = 'Expected Reason Code data for BC14 migration tests';
    Direction = Import;
    FieldSeparator = ',';
    RecordSeparator = '<CR><LF>';
    Format = VariableText;
    FormatEvaluate = Xml;

    schema
    {
        textelement(root)
        {
            tableelement(ReasonCode; "Reason Code")
            {
                AutoSave = false;
                XmlName = 'ReasonCode';

                textelement(Code) { }
                textelement(Description) { }

                trigger OnBeforeInsertRecord()
                begin
                    if CaptionRow then begin
                        CaptionRow := false;
                        currXMLport.Skip();
                        exit;
                    end;

                    TempReasonCode.Init();
                    TempReasonCode.Code := CopyStr(Code, 1, MaxStrLen(TempReasonCode.Code));
                    TempReasonCode.Description := CopyStr(Description, 1, MaxStrLen(TempReasonCode.Description));
                    TempReasonCode.Insert();

                    currXMLport.Skip();
                end;
            }
        }
    }

    trigger OnPreXmlPort()
    begin
        CaptionRow := true;
        TempReasonCode.Reset();
        TempReasonCode.DeleteAll();
    end;

    procedure GetExpectedReasonCodes(var DestTempReasonCode: Record "Reason Code" temporary)
    begin
        DestTempReasonCode.Reset();
        DestTempReasonCode.DeleteAll();
        if TempReasonCode.FindSet() then
            repeat
                DestTempReasonCode := TempReasonCode;
                DestTempReasonCode.Insert();
            until TempReasonCode.Next() = 0;
    end;

    var
        TempReasonCode: Record "Reason Code" temporary;
        CaptionRow: Boolean;
}
