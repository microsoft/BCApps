// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14.Tests;

using Microsoft.Finance.VAT.Setup;

xmlport 148940 "BC14 Exp VATProdPG"
{
    Caption = 'Expected VAT Product Posting Group data';
    Direction = Import;
    FieldSeparator = ',';
    RecordSeparator = '<CR><LF>';
    Format = VariableText;
    FormatEvaluate = Xml;

    schema
    {
        textelement(root)
        {
            tableelement(VATProdPostingGroup; "VAT Product Posting Group")
            {
                AutoSave = false;
                XmlName = 'VATProdPostingGroup';

                textelement(Code) { }
                textelement(Description) { }

                trigger OnBeforeInsertRecord()
                begin
                    if CaptionRow then begin
                        CaptionRow := false;
                        currXMLport.Skip();
                        exit;
                    end;

                    TempVATProdPostingGroup.Init();
                    TempVATProdPostingGroup.Code := CopyStr(Code, 1, MaxStrLen(TempVATProdPostingGroup.Code));
                    TempVATProdPostingGroup.Description := CopyStr(Description, 1, MaxStrLen(TempVATProdPostingGroup.Description));
                    TempVATProdPostingGroup.Insert();

                    currXMLport.Skip();
                end;
            }
        }
    }

    trigger OnPreXmlPort()
    begin
        CaptionRow := true;
        TempVATProdPostingGroup.Reset();
        TempVATProdPostingGroup.DeleteAll();
    end;

    procedure GetExpectedVATProdPostingGroups(var Dest: Record "VAT Product Posting Group" temporary)
    begin
        Dest.Reset();
        Dest.DeleteAll();
        if TempVATProdPostingGroup.FindSet() then
            repeat
                Dest := TempVATProdPostingGroup;
                Dest.Insert();
            until TempVATProdPostingGroup.Next() = 0;
    end;

    var
        TempVATProdPostingGroup: Record "VAT Product Posting Group" temporary;
        CaptionRow: Boolean;
}
