// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14.Tests;

using Microsoft.Finance.GeneralLedger.Setup;

xmlport 148934 "BC14 Exp GenBusPG"
{
    Caption = 'Expected Gen. Business Posting Group data';
    Direction = Import;
    FieldSeparator = ',';
    RecordSeparator = '<CR><LF>';
    Format = VariableText;
    FormatEvaluate = Xml;

    schema
    {
        textelement(root)
        {
            tableelement(GenBusPostingGroup; "Gen. Business Posting Group")
            {
                AutoSave = false;
                XmlName = 'GenBusPostingGroup';

                textelement(Code) { }
                textelement(Description) { }
                textelement(DefVATBusPostingGroup) { }
                textelement(AutoInsertDefault) { }

                trigger OnBeforeInsertRecord()
                begin
                    if CaptionRow then begin
                        CaptionRow := false;
                        currXMLport.Skip();
                        exit;
                    end;

                    TempGenBusPostingGroup.Init();
                    TempGenBusPostingGroup.Code := CopyStr(Code, 1, MaxStrLen(TempGenBusPostingGroup.Code));
                    TempGenBusPostingGroup.Description := CopyStr(Description, 1, MaxStrLen(TempGenBusPostingGroup.Description));
                    TempGenBusPostingGroup."Def. VAT Bus. Posting Group" := CopyStr(DefVATBusPostingGroup, 1, MaxStrLen(TempGenBusPostingGroup."Def. VAT Bus. Posting Group"));
                    Evaluate(TempGenBusPostingGroup."Auto Insert Default", AutoInsertDefault);
                    TempGenBusPostingGroup.Insert();

                    currXMLport.Skip();
                end;
            }
        }
    }

    trigger OnPreXmlPort()
    begin
        CaptionRow := true;
        TempGenBusPostingGroup.Reset();
        TempGenBusPostingGroup.DeleteAll();
    end;

    procedure GetExpectedGenBusPostingGroups(var Dest: Record "Gen. Business Posting Group" temporary)
    begin
        Dest.Reset();
        Dest.DeleteAll();
        if TempGenBusPostingGroup.FindSet() then
            repeat
                Dest := TempGenBusPostingGroup;
                Dest.Insert();
            until TempGenBusPostingGroup.Next() = 0;
    end;

    var
        TempGenBusPostingGroup: Record "Gen. Business Posting Group" temporary;
        CaptionRow: Boolean;
}
