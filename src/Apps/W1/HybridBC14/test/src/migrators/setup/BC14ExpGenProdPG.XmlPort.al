// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14.Tests;

using Microsoft.Finance.GeneralLedger.Setup;

xmlport 148936 "BC14 Exp GenProdPG"
{
    Caption = 'Expected Gen. Product Posting Group data';
    Direction = Import;
    FieldSeparator = ',';
    RecordSeparator = '<CR><LF>';
    Format = VariableText;
    FormatEvaluate = Xml;

    schema
    {
        textelement(root)
        {
            tableelement(GenProdPostingGroup; "Gen. Product Posting Group")
            {
                AutoSave = false;
                XmlName = 'GenProdPostingGroup';

                textelement(Code) { }
                textelement(Description) { }
                textelement(DefVATProdPostingGroup) { }
                textelement(AutoInsertDefault) { }

                trigger OnBeforeInsertRecord()
                begin
                    if CaptionRow then begin
                        CaptionRow := false;
                        currXMLport.Skip();
                        exit;
                    end;

                    TempGenProdPostingGroup.Init();
                    TempGenProdPostingGroup.Code := CopyStr(Code, 1, MaxStrLen(TempGenProdPostingGroup.Code));
                    TempGenProdPostingGroup.Description := CopyStr(Description, 1, MaxStrLen(TempGenProdPostingGroup.Description));
                    TempGenProdPostingGroup."Def. VAT Prod. Posting Group" := CopyStr(DefVATProdPostingGroup, 1, MaxStrLen(TempGenProdPostingGroup."Def. VAT Prod. Posting Group"));
                    Evaluate(TempGenProdPostingGroup."Auto Insert Default", AutoInsertDefault);
                    TempGenProdPostingGroup.Insert();

                    currXMLport.Skip();
                end;
            }
        }
    }

    trigger OnPreXmlPort()
    begin
        CaptionRow := true;
        TempGenProdPostingGroup.Reset();
        TempGenProdPostingGroup.DeleteAll();
    end;

    procedure GetExpectedGenProdPostingGroups(var Dest: Record "Gen. Product Posting Group" temporary)
    begin
        Dest.Reset();
        Dest.DeleteAll();
        if TempGenProdPostingGroup.FindSet() then
            repeat
                Dest := TempGenProdPostingGroup;
                Dest.Insert();
            until TempGenProdPostingGroup.Next() = 0;
    end;

    var
        TempGenProdPostingGroup: Record "Gen. Product Posting Group" temporary;
        CaptionRow: Boolean;
}
