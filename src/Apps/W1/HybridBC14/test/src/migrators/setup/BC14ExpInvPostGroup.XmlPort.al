// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14.Tests;

using Microsoft.Inventory.Item;

xmlport 148950 "BC14 Exp InvPostGroup"
{
    Caption = 'Expected Inventory Posting Group data';
    Direction = Import;
    FieldSeparator = ',';
    RecordSeparator = '<CR><LF>';
    Format = VariableText;
    FormatEvaluate = Xml;

    schema
    {
        textelement(root)
        {
            tableelement(InventoryPostingGroup; "Inventory Posting Group")
            {
                AutoSave = false;
                XmlName = 'InventoryPostingGroup';

                textelement(Code) { }
                textelement(Description) { }

                trigger OnBeforeInsertRecord()
                begin
                    if CaptionRow then begin
                        CaptionRow := false;
                        currXMLport.Skip();
                        exit;
                    end;

                    TempInventoryPostingGroup.Init();
                    TempInventoryPostingGroup.Code := CopyStr(Code, 1, MaxStrLen(TempInventoryPostingGroup.Code));
                    TempInventoryPostingGroup.Description := CopyStr(Description, 1, MaxStrLen(TempInventoryPostingGroup.Description));
                    TempInventoryPostingGroup.Insert();

                    currXMLport.Skip();
                end;
            }
        }
    }

    trigger OnPreXmlPort()
    begin
        CaptionRow := true;
        TempInventoryPostingGroup.Reset();
        TempInventoryPostingGroup.DeleteAll();
    end;

    procedure GetExpectedInventoryPostingGroups(var Dest: Record "Inventory Posting Group" temporary)
    begin
        Dest.Reset();
        Dest.DeleteAll();
        if TempInventoryPostingGroup.FindSet() then
            repeat
                Dest := TempInventoryPostingGroup;
                Dest.Insert();
            until TempInventoryPostingGroup.Next() = 0;
    end;

    var
        TempInventoryPostingGroup: Record "Inventory Posting Group" temporary;
        CaptionRow: Boolean;
}
