// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14.Tests;

using Microsoft.Finance.VAT.Setup;

xmlport 148938 "BC14 Exp VATBusPG"
{
    Caption = 'Expected VAT Business Posting Group data';
    Direction = Import;
    FieldSeparator = ',';
    RecordSeparator = '<CR><LF>';
    Format = VariableText;
    FormatEvaluate = Xml;

    schema
    {
        textelement(root)
        {
            tableelement(VATBusPostingGroup; "VAT Business Posting Group")
            {
                AutoSave = false;
                XmlName = 'VATBusPostingGroup';

                textelement(Code) { }
                textelement(Description) { }

                trigger OnBeforeInsertRecord()
                begin
                    if CaptionRow then begin
                        CaptionRow := false;
                        currXMLport.Skip();
                        exit;
                    end;

                    TempVATBusPostingGroup.Init();
                    TempVATBusPostingGroup.Code := CopyStr(Code, 1, MaxStrLen(TempVATBusPostingGroup.Code));
                    TempVATBusPostingGroup.Description := CopyStr(Description, 1, MaxStrLen(TempVATBusPostingGroup.Description));
                    TempVATBusPostingGroup.Insert();

                    currXMLport.Skip();
                end;
            }
        }
    }

    trigger OnPreXmlPort()
    begin
        CaptionRow := true;
        TempVATBusPostingGroup.Reset();
        TempVATBusPostingGroup.DeleteAll();
    end;

    procedure GetExpectedVATBusPostingGroups(var Dest: Record "VAT Business Posting Group" temporary)
    begin
        Dest.Reset();
        Dest.DeleteAll();
        if TempVATBusPostingGroup.FindSet() then
            repeat
                Dest := TempVATBusPostingGroup;
                Dest.Insert();
            until TempVATBusPostingGroup.Next() = 0;
    end;

    var
        TempVATBusPostingGroup: Record "VAT Business Posting Group" temporary;
        CaptionRow: Boolean;
}
